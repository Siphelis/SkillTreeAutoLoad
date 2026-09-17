local NS = SkillTreeAutoLoad

local View = {}
NS.View = View

-- Tout ce qui deplace ou zoome la vue de l'arbre passe par ici : le decalage du mode
-- compact et l'apercu d'une save se disputeraient sinon la meme vue, chacun prenant
-- les mouvements de l'autre pour un recentrage d'Ebonhold.

-- L'apercu descend sous le zoom minimum d'Ebonhold (0.5) : le joueur connait l'arbre, ce
-- qu'il cherche est ou la save le touche. L'arbre entier tient vers 0.16 ; ce plancher
-- ne sert qu'a un arbre qui grandirait assez pour ne plus tenir du tout.
local SAFETY_MIN_ZOOM = 0.1

local HOVER_DELAY = 0.3
local TRANSITION = 0.25
local FRAME_MARGIN = 24
local ARROW_SIZE = 28
local ARROW_INSET = 6

local ARROW_TEXTURES = {
    LEFT = "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up",
    RIGHT = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up",
    TOP = "Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up",
    BOTTOM = "Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up",
}

-- Le compteur se pose du cote interieur de la fleche, jamais contre le bord.
local COUNT_ANCHORS = {
    LEFT = { "LEFT", "RIGHT", 2, 0 },
    RIGHT = { "RIGHT", "LEFT", -2, 0 },
    TOP = { "TOP", "BOTTOM", 0, -2 },
    BOTTOM = { "BOTTOM", "TOP", 0, 2 },
}

local panel, driver
local covered, coveredSide = 0, "RIGHT"
local viewShift, draggingTree, driving = 0, false, false

-- Ancrage de la vue tel qu'Ebonhold le pose (coin haut-gauche et bas-droit sur l'arbre),
-- et le recul que l'apercu applique a son coin haut-gauche. Nil si l'ancrage n'a pas la
-- forme attendue : l'apercu renonce alors a centrer un arbre plus petit que la vue.
local base
local padX, padY = 0, 0

-- Apercu. `origin` est la vue du joueur avant le premier apercu, rendue quand la souris
-- quitte le panneau ; `target` la save cadree ; `pending` celle qui attend son delai.
local origin, target, pending, anim
local hovering, warnedKey = false, nil
local arrows = {}

local function Clamp(value, low, high)
    if value < low then return low end
    if value > high then return high end
    return value
end

-- Mode diagnostic, eteint par defaut et bascule par /staldiag : il suit un apercu de bout
-- en bout, du nombre de noeuds trouves jusqu'au defilement reellement applique.
local debugging = false

local function Diag(text, ...)
    if not debugging then return end
    NS.Log("|cff33ccff[diag]|r " .. string.format(text, ...))
end

local function TreeVisible()
    return _G.skillTreeScroll and _G.skillTreeCanvas and skillTreeScroll:IsVisible()
end

local function CaptureBase(view)
    if view:GetNumPoints() ~= 2 then return nil end

    local anchors = {}
    for i = 1, 2 do
        local point, relativeTo, relativePoint, x, y = view:GetPoint(i)
        anchors[point] = {
            relativeTo = relativeTo or view:GetParent(),
            relativePoint = relativePoint, x = x, y = y,
        }
    end

    local topLeft, bottomRight = anchors.TOPLEFT, anchors.BOTTOMRIGHT
    if not (topLeft and bottomRight and topLeft.relativeTo == bottomRight.relativeTo
        and topLeft.relativePoint == "TOPLEFT" and bottomRight.relativePoint == "BOTTOMRIGHT") then
        return nil
    end

    return {
        frame = topLeft.relativeTo,
        left = topLeft.x, top = topLeft.y, right = bottomRight.x, bottom = bottomRight.y,
    }
end

-- La vue ne defile pas en negatif : le client ramene la position a zero. Pour centrer un
-- arbre plus petit qu'elle, on recule donc son coin haut-gauche d'autant ; le cadre se
-- retrecit, mais l'arbre qu'il montre tient dedans.
local function SetPadding(x, y)
    if not base or (x == padX and y == padY) then return end
    padX, padY = x, y
    skillTreeScroll:SetPoint("TOPLEFT", base.frame, "TOPLEFT", base.left + x, base.top - y)
end

-- Taille et haut de la vue sans le recul de l'apercu : c'est dans ce repere que le
-- cadrage raisonne, quel que soit le recul du moment.
local function ViewSize()
    if not base then return skillTreeScroll:GetWidth(), skillTreeScroll:GetHeight() end
    return base.frame:GetWidth() - base.left + base.right,
        base.frame:GetHeight() + base.top - base.bottom
end

local function ViewTop()
    if not base then return skillTreeScroll:GetTop() end
    local frameTop = base.frame:GetTop()
    return frameTop and (frameTop + base.top)
end

-- Ce que rien ne couvre dans la vue, en unites de la vue et y vers le bas : ni le
-- panneau en mode compact, ni la barre de progression qu'Ebonhold pose en haut.
local function FreeRect()
    local width, height = ViewSize()
    local left, right = 0, width
    if coveredSide == "LEFT" then left = covered else right = width - covered end

    local top = 0
    local bar = skillTreeFrame.progressBar
    local viewTop = ViewTop()
    if bar and bar:IsShown() and bar:GetBottom() and viewTop then
        top = math.max(0, viewTop - bar:GetBottom())
    end

    return left, top, right, height
end

-- Decalage du mode compact ---------------------------------------------------------

-- Ebonhold centre sur toute la largeur : a la premiere ouverture sur les noeuds de
-- depart, a chaque cran de zoom sur le milieu du canevas. En mode compact, la vue doit
-- se centrer sur ce que le panneau laisse libre. `viewShift` est le decalage que la
-- vue porte deja ; un recentrage d'Ebonhold le remet a zero.
local function WantedShift()
    if covered == 0 then return 0 end
    -- Le contenu glisse vers le cote degage, de la moitie de la largeur couverte.
    return (coveredSide == "LEFT") and -covered / 2 or covered / 2
end

-- Renvoie le deplacement reellement obtenu : aux bords du canevas, la vue bute.
local function MoveHorizontally(delta)
    local view = _G.skillTreeScroll
    if not view or delta == 0 then return 0 end

    local current = view:GetHorizontalScroll()
    local wanted = Clamp(current + delta, 0, view:GetHorizontalScrollRange())

    driving = true
    view:SetHorizontalScroll(wanted)
    driving = false

    return wanted - current
end

local function SyncShift()
    viewShift = viewShift + MoveHorizontally(WantedShift() - viewShift)
end

-- Pilotage de la vue ----------------------------------------------------------------

-- Le zoom d'Ebonhold est prive et borne a 0.5. On refait donc son geste nous-memes :
-- l'echelle du canevas, et sa taille compensee d'autant, pour que la vue garde de quoi
-- defiler. Son zoom interne ne bouge jamais ; c'est pourquoi la fin de l'apercu remet
-- l'echelle ET la taille exactes d'origine, et que l'apercu ne passe jamais par sa
-- molette : les deux zooms ne doivent pas se contredire.
local function SetZoom(zoom)
    local canvas = skillTreeCanvas
    local current = canvas:GetScale()
    if math.abs(zoom - current) < 0.0001 then return end

    local width, height = canvas:GetWidth() * current, canvas:GetHeight() * current
    canvas:SetScale(zoom)
    canvas:SetSize(width / zoom, height / zoom)

    NS.Overlay.Rescale()
end

-- Le point du canevas qui occupe le centre de la zone libre. Le recul decale le canevas
-- d'autant vers la droite et le bas.
local function ViewCenter()
    local view, zoom = skillTreeScroll, skillTreeCanvas:GetScale()
    local left, top, right, bottom = FreeRect()
    return (view:GetHorizontalScroll() - padX + (left + right) / 2) / zoom,
        (view:GetVerticalScroll() - padY + (top + bottom) / 2) / zoom
end

-- Position de defilement qui amene le point (cx, cy) du canevas au centre de la zone
-- libre, avant tout recul. Negative quand l'arbre, tres dezoome, est plus petit que la
-- vue : c'est le recul du coin haut-gauche qui rattrape ce que le client refuse.
local function ScrollTarget(cx, cy, zoom)
    local left, top, right, bottom = FreeRect()
    return cx * zoom - (left + right) / 2, cy * zoom - (top + bottom) / 2
end

-- Le recul, lui, est pose par l'appelant : le changer a chaque image redimensionne la
-- vue, ce qui coute aussi cher qu'un changement d'echelle.
local function PlaceView(cx, cy)
    local view = skillTreeScroll
    local scrollX, scrollY = ScrollTarget(cx, cy, skillTreeCanvas:GetScale())

    driving = true
    view:SetHorizontalScroll(Clamp(scrollX + padX, 0, math.max(0, view:GetHorizontalScrollRange())))
    view:SetVerticalScroll(Clamp(scrollY + padY, 0, math.max(0, view:GetVerticalScrollRange())))
    driving = false
end

-- Rectangle d'un noeud sur le canevas, y vers le bas. Ebonhold ancre chaque bouton par
-- son coin haut-gauche sur le canevas : le decalage de l'ancre est sa position. Elle ne
-- bouge plus une fois l'arbre construit — le zoom met le canevas a l'echelle, pas ses
-- noeuds — et un cadrage en relit des centaines : on la retient.
local nodeRects = {}

local function NodeRect(nodeId)
    local rect = nodeRects[nodeId]
    if rect then return rect[1], rect[2], rect[3], rect[4] end

    local button = _G["skillTreeNode" .. nodeId]
    if not button then return nil end

    local _, _, _, x, y = button:GetPoint(1)
    if not x then return nil end

    rect = { x, -y, x + button:GetWidth(), -y + button:GetHeight() }
    nodeRects[nodeId] = rect
    return rect[1], rect[2], rect[3], rect[4]
end

local function Bounds(set)
    local minX, minY, maxX, maxY
    for nodeId in pairs(set) do
        local left, top, right, bottom = NodeRect(nodeId)
        if left then
            if not minX then
                minX, minY, maxX, maxY = left, top, right, bottom
            else
                minX, minY = math.min(minX, left), math.min(minY, top)
                maxX, maxY = math.max(maxX, right), math.max(maxY, bottom)
            end
        end
    end
    return minX, minY, maxX, maxY
end

local function FitZoom(minX, minY, maxX, maxY)
    local left, top, right, bottom = FreeRect()
    local width = right - left - 2 * FRAME_MARGIN
    local height = bottom - top - 2 * FRAME_MARGIN
    return math.min(width / math.max(maxX - minX, 1), height / math.max(maxY - minY, 1))
end

-- Le cadrage vise toute la save. Si elle ne tient pas meme au plancher de securite, il
-- se rabat sur ce qui compte : ce que le clic prendrait en mode progressif, sinon la
-- branche la plus fournie. Il ne zoome jamais plus pres que le joueur.
local function ComputeFraming(missing, affordable)
    local minX, minY, maxX, maxY = Bounds(missing)
    if not minX then
        Diag("aucun noeud restant n'a de bouton dans l'arbre : rien a cadrer")
        return nil
    end

    local fit = FitZoom(minX, minY, maxX, maxY)
    if fit < SAFETY_MIN_ZOOM then
        local focusMinX, focusMinY, focusMaxX, focusMaxY
        if affordable and next(affordable) then
            focusMinX, focusMinY, focusMaxX, focusMaxY = Bounds(affordable)
        end
        if not focusMinX then
            focusMinX, focusMinY, focusMaxX, focusMaxY = Bounds(NS.Plan.LargestGroup(missing))
        end
        if focusMinX then
            minX, minY, maxX, maxY = focusMinX, focusMinY, focusMaxX, focusMaxY
            fit = FitZoom(minX, minY, maxX, maxY)
        end
    end

    local zoom = math.max(SAFETY_MIN_ZOOM, math.min(origin.zoom, fit))

    Diag("rectangle %.0f,%.0f -> %.0f,%.0f (%.0f x %.0f) | tient a %.2f | zoom joueur %.2f | zoom retenu %.2f",
        minX, minY, maxX, maxY, maxX - minX, maxY - minY, fit, origin.zoom, zoom)

    return zoom, (minX + maxX) / 2, (minY + maxY) / 2
end

-- Fleches sur les bords -------------------------------------------------------------

local function HideArrows()
    for _, arrow in pairs(arrows) do arrow:Hide() end
end

local function GetArrow(side)
    local arrow = arrows[side]
    if arrow then return arrow end

    arrow = CreateFrame("Frame", nil, skillTreeFrame)
    arrow:SetSize(ARROW_SIZE, ARROW_SIZE)

    arrow.icon = arrow:CreateTexture(nil, "ARTWORK")
    arrow.icon:SetAllPoints(arrow)
    arrow.icon:SetTexture(ARROW_TEXTURES[side])

    local anchor = COUNT_ANCHORS[side]
    arrow.count = arrow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    arrow.count:SetPoint(anchor[1], arrow, anchor[2], anchor[3], anchor[4])

    arrows[side] = arrow
    return arrow
end

-- Une fleche par bord de la zone libre derriere lequel des noeuds de la save restent
-- caches, avec leur nombre. Un noeud en diagonale compte pour le bord qu'il depasse le
-- plus. La fleche glisse le long de son bord, a hauteur moyenne des noeuds qu'elle
-- annonce : elle pointe vers eux, pas seulement dans leur direction.
local function ShowArrows(missing)
    HideArrows()
    if not (missing and TreeVisible()) then return end

    local view, zoom = skillTreeScroll, skillTreeCanvas:GetScale()
    local scrollX, scrollY = view:GetHorizontalScroll(), view:GetVerticalScroll()
    local left, top, right, bottom = FreeRect()

    local counts, sums = {}, {}
    for nodeId in pairs(missing) do
        local nodeLeft, nodeTop, nodeRight, nodeBottom = NodeRect(nodeId)
        if nodeLeft then
            local x = (nodeLeft + nodeRight) / 2 * zoom - scrollX + padX
            local y = (nodeTop + nodeBottom) / 2 * zoom - scrollY + padY
            local dx = (x < left) and (left - x) or ((x > right) and (x - right) or 0)
            local dy = (y < top) and (top - y) or ((y > bottom) and (y - bottom) or 0)

            if dx > 0 or dy > 0 then
                local side, along
                if dx >= dy then
                    side, along = (x < left) and "LEFT" or "RIGHT", y
                else
                    side, along = (y < top) and "TOP" or "BOTTOM", x
                end
                counts[side] = (counts[side] or 0) + 1
                sums[side] = (sums[side] or 0) + along
            end
        end
    end

    -- Meme etage que le panneau compact : au-dessus des noeuds et de nos marques.
    local level = skillTreeCanvas:GetFrameLevel() + 1 + NS.Overlay.MARK_LEVEL + 1
    local edge = ARROW_INSET + ARROW_SIZE / 2

    for side, count in pairs(counts) do
        local along = sums[side] / count
        local x, y
        if side == "LEFT" or side == "RIGHT" then
            x = (side == "LEFT") and (left + edge) or (right - edge)
            y = Clamp(along, top + edge, bottom - edge)
        else
            x = Clamp(along, left + edge, right - edge)
            y = (side == "TOP") and (top + edge) or (bottom - edge)
        end

        -- Posee dans le repere de la vue sans recul : le coin haut-gauche de la vue, lui,
        -- a pu reculer.
        local arrow = GetArrow(side)
        arrow:ClearAllPoints()
        if base then
            arrow:SetPoint("CENTER", base.frame, "TOPLEFT", base.left + x, base.top - y)
        else
            arrow:SetPoint("CENTER", view, "TOPLEFT", x, -y)
        end
        arrow:SetFrameLevel(level)
        arrow.count:SetText(count)
        arrow:Show()
    end
end

-- Apercu ------------------------------------------------------------------------------

local function Smooth(t)
    return t * t * (3 - 2 * t)
end

-- Les cadres ne vivent que sur une vue posee. Les garder pendant la transition obligeait
-- a les redimensionner a chaque palier de zoom, des centaines a la fois, en plus du
-- replacement de l'arbre : c'est ce cumul qui hachait le retour a la vue d'origine.
local function ShowMarks()
    if not (target and target.missing) then return end

    local skipped = NS.Overlay.Show(target.missing, target.affordable)
    ShowArrows(target.missing)

    local view = skillTreeScroll
    Diag("pose : zoom %.2f | defilement %.0f,%.0f | recul %.0f,%.0f | sans bouton %d",
        skillTreeCanvas:GetScale(), view:GetHorizontalScroll(), view:GetVerticalScroll(),
        padX, padY, skipped or 0)

    -- Une seule fois par save : sinon chaque survol repeterait le message.
    if skipped and skipped > 0 and warnedKey ~= target.key then
        warnedKey = target.key
        NS.LogWarn(string.format(NS.L.MSG_NODES_NOT_IN_TREE, skipped))
    end
end

local function StartAnimation(zoom, cx, cy, restore)
    local fromZoom = skillTreeCanvas:GetScale()
    local fromX, fromY = ViewCenter()

    -- Changer l'echelle replace les ~3000 elements de l'arbre : une seule fois par
    -- transition, et du cote ou elle se voit le moins. En s'eloignant, tout de suite ; en
    -- se rapprochant, a l'arrivee. Le trajet se fait donc toujours a la plus petite des
    -- deux echelles, la ou le mouvement est le plus lisible.
    local zoomedOut = zoom < fromZoom
    if zoomedOut then SetZoom(zoom) end

    -- Recul pose une fois pour toute la transition, au plus large des deux besoins.
    local panZoom = zoomedOut and zoom or fromZoom
    local startX, startY = ScrollTarget(fromX, fromY, panZoom)
    local endX, endY = ScrollTarget(cx, cy, panZoom)
    SetPadding(math.max(0, -startX, -endX), math.max(0, -startY, -endY))

    anim = {
        startedAt = GetTime(), restore = restore, zoomedOut = zoomedOut,
        fromX = fromX, fromY = fromY, toZoom = zoom, toX = cx, toY = cy,
    }

    Diag("transition zoom %.2f -> %.2f | centre %.0f,%.0f -> %.0f,%.0f | defilement %.0f -> %.0f | recul %.0f,%.0f",
        fromZoom, zoom, fromX, fromY, cx, cy, startX, endX, padX, padY)

    HideArrows()
    NS.Overlay.Hide()
    driver:Show()
end

local function StartRestore()
    local left, top, right, bottom = FreeRect()
    StartAnimation(origin.zoom,
        (origin.scrollX + (left + right) / 2) / origin.zoom,
        (origin.scrollY + (top + bottom) / 2) / origin.zoom, true)
end

-- La fin du retour pose la vue exacte du joueur, et non un centre recalcule : c'est ce
-- qui garde juste le decalage du mode compact qu'elle portait, et le canevas tel
-- qu'Ebonhold l'avait dimensionne pour son propre zoom.
local function FinishRestore()
    local canvas = skillTreeCanvas
    canvas:SetScale(origin.zoom)
    canvas:SetSize(origin.width, origin.height)
    NS.Overlay.Rescale()
    SetPadding(0, 0)

    local view = skillTreeScroll
    driving = true
    view:SetHorizontalScroll(origin.scrollX)
    view:SetVerticalScroll(origin.scrollY)
    driving = false

    origin, target = nil, nil
end

local function FrameTarget()
    if debugging then
        local total, framed = 0, 0
        for nodeId in pairs(target.missing) do
            total = total + 1
            if NodeRect(nodeId) then framed = framed + 1 end
        end
        Diag("save %s : %d noeud(s) restant(s), %d avec bouton", tostring(target.key), total, framed)
    end

    if not origin then
        local view, canvas = skillTreeScroll, skillTreeCanvas
        origin = {
            zoom = canvas:GetScale(),
            width = canvas:GetWidth(),
            height = canvas:GetHeight(),
            scrollX = view:GetHorizontalScroll(),
            scrollY = view:GetVerticalScroll(),
        }
    end

    local zoom, cx, cy = ComputeFraming(target.missing, target.affordable)
    if not zoom then
        -- Aucun des noeuds restants n'existe dans l'arbre affiche : il n'y a rien a
        -- cadrer, et c'est ShowMarks qui le dira au joueur.
        ShowMarks()
        return
    end

    local fromX, fromY = ViewCenter()
    local current = skillTreeCanvas:GetScale()
    if math.abs(zoom - current) < 0.001
        and math.abs(cx - fromX) * zoom < 1 and math.abs(cy - fromY) * zoom < 1 then
        anim = nil
        Diag("vue deja en place, aucun mouvement")
        ShowMarks()
        return
    end

    StartAnimation(zoom, cx, cy, false)
end

local function OnUpdate()
    local now = GetTime()

    if pending and now >= pending.due then
        -- Le delai a expire hors de toute save : la souris ne faisait que passer.
        if hovering and TreeVisible() then
            target = pending
            FrameTarget()
        end
        pending = nil
    end

    if anim then
        local progress = math.min(1, (now - anim.startedAt) / TRANSITION)
        local eased = Smooth(progress)

        -- Le zoom qui rapproche attendait l'arrivee : c'est ici qu'il se pose, avec le
        -- recul que la nouvelle echelle demande. Un retour, lui, se termine par
        -- FinishRestore, qui repose l'echelle, la taille et la vue exactes du joueur.
        if progress >= 1 and not anim.zoomedOut and not anim.restore then
            SetZoom(anim.toZoom)
            local endX, endY = ScrollTarget(anim.toX, anim.toY, anim.toZoom)
            SetPadding(math.max(0, -endX), math.max(0, -endY))
        end

        PlaceView(anim.fromX + (anim.toX - anim.fromX) * eased,
            anim.fromY + (anim.toY - anim.fromY) * eased)

        if progress >= 1 then
            local restore = anim.restore
            anim = nil
            if restore then
                FinishRestore()
            elseif hovering and target then
                ShowMarks()
            end
        end
    end

    -- Passer d'une save a l'autre, ou par l'interligne, laisse la souris sur le
    -- panneau : l'apercu tient. Il ne rend la vue qu'une fois le panneau quitte.
    if origin and not hovering and not (anim and anim.restore)
        and not (panel and panel:IsMouseOver()) then
        StartRestore()
    end

    if not (pending or anim or origin) then driver:Hide() end
end

-- API ---------------------------------------------------------------------------------

function View.Init()
    local view = _G.skillTreeScroll
    if not view then return end

    -- Lu ici, au chargement, tant que rien n'a encore touche a l'ancrage de la vue.
    base = CaptureBase(view)

    driver = CreateFrame("Frame")
    driver:Hide()
    driver:SetScript("OnUpdate", OnUpdate)

    -- Le glisser d'Ebonhold passe lui aussi par SetHorizontalScroll : tant qu'un bouton
    -- est enfonce sur l'arbre, ce n'est pas un recentrage.
    view:HookScript("OnMouseDown", function() draggingTree = true end)
    view:HookScript("OnMouseUp", function() draggingTree = false end)

    hooksecurefunc(view, "SetHorizontalScroll", function()
        if driving or draggingTree then return end

        -- Ebonhold vient de recentrer : un cran de molette du joueur pendant le retour
        -- d'un apercu, par exemple. Son zoom et la taille du canevas sont de nouveau les
        -- siens ; rendre l'ancienne vue les contredirait, l'apercu s'efface donc sans
        -- toucher a rien.
        if origin then
            origin, target, pending, anim = nil, nil, nil, nil
            HideArrows()
            NS.Overlay.Rescale()
            SetPadding(0, 0)
        end

        viewShift = 0
        SyncShift()
    end)
end

function View.Attach(frame)
    panel = frame
end

-- Outil de mise au point, pas une fonctionnalite : il ne coute rien tant qu'il est
-- eteint, et il n'a pas vocation a rester dans une version publiee.
SLASH_STALDIAG1 = "/staldiag"
SlashCmdList["STALDIAG"] = function()
    debugging = not debugging
    NS.Log("diagnostic de l'apercu : " .. (debugging and "actif" or "eteint"))
end

-- Ancrage de la vue tel qu'Ebonhold le pose, sans le recul de l'apercu : le panneau
-- compact s'y cale, et ne doit pas suivre le coin haut-gauche quand il recule. Nil si
-- l'ancrage n'a pas la forme attendue.
function View.GetViewInsets()
    if not base then return nil end
    return base.frame, base.left, base.top, base.right, base.bottom
end

-- Largeur de vue que le panneau recouvre, et de quel cote ; zero hors mode compact.
function View.SetCovered(side, width)
    if side ~= coveredSide or width ~= covered then
        -- Un apercu cadre pour l'ancienne zone libre n'a plus de sens : la vue du joueur
        -- est rendue d'un coup, avant de recaler le decalage.
        if origin then
            anim, pending = nil, nil
            HideArrows()
            FinishRestore()
        end
        coveredSide, covered = side, width
    end
    SyncShift()
end

-- Survol d'une save. `key` distingue une nouvelle save, qui attend son delai, d'un
-- rafraichissement de celle deja cadree (activation, bascule du mode), suivi aussitot.
function View.Preview(key, missing, affordable)
    hovering = true
    HideArrows()

    if not (driver and TreeVisible() and missing and next(missing)) then
        pending = nil
        NS.Overlay.Hide()
        return
    end

    local entry = { key = key, missing = missing, affordable = affordable }

    -- Sans cadrage, rien a attendre : les cadres se posent sur la vue telle quelle.
    if not NS.Data.IsPreviewCamera() then
        target, pending = entry, nil
        ShowMarks()
        return
    end

    if origin and target and target.key == key then
        target, pending = entry, nil
        FrameTarget()
    else
        -- Les cadres de la save precedente n'ont plus lieu d'etre, et ceux de la nouvelle
        -- attendent que la vue soit posee : les afficher pendant la transition revenait a
        -- les redimensionner a chaque palier de zoom.
        NS.Overlay.Hide()
        -- Glisser de la ligne a l'un de ses boutons ne relance pas le delai.
        entry.due = (pending and pending.key == key) and pending.due or (GetTime() + HOVER_DELAY)
        pending = entry
    end

    driver:Show()
end

function View.Release()
    hovering = false
    HideArrows()
end

-- L'arbre se ferme : la vue du joueur revient d'un coup, sans transition invisible.
function View.Cancel()
    draggingTree, hovering, pending, anim = false, false, nil, nil
    HideArrows()

    if origin and _G.skillTreeScroll and _G.skillTreeCanvas then FinishRestore() end
    origin, target = nil, nil

    if driver then driver:Hide() end
end
