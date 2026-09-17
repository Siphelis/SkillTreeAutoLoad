local NS = SkillTreeAutoLoad
local Log = NS.Log
local FormatCost = NS.FormatCost
local L = NS.L
local COLOR = NS.COLOR
local Colorize = NS.Colorize

local UI = {}
NS.UI = UI

local PANEL_WIDTH = 275
local PANEL_GAP = 6
local TAB_WIDTH = 40
local TAB_HEIGHT = 36
local GLASS_ALPHA = 0.55
local GLASS_GRAIN_ALPHA = 0.25
local GLASS_FADE_WIDTH = 16
local ROW_HEIGHT = 54
local ROW_SPACING = 3
local GROUP_HEADER_HEIGHT = 22
local SCROLL_MARGIN_RIGHT = 30
local SCROLL_MARGIN_BOTTOM = 14
local TOGGLE_WIDTH = 26
local TOGGLE_HEIGHT = 16
local TOGGLE_LABEL_WIDTH = 62

-- La ligne est ancree par ses deux bords, sa largeur n'existe donc qu'une fois le
-- panneau dispose. La jauge, elle, doit connaitre sa largeur des le premier dessin :
-- on la derive des constantes plutot que de lire une geometrie pas encore calculee.
local ROW_WIDTH = PANEL_WIDTH - 12 - SCROLL_MARGIN_RIGHT - 4

local panel, scroll, scrollChild, emptyText
local sideBtn, collapseBtn, menuBtn, updateBtn, grain, fade
local headerPool, rowPool = {}, {}

-- Definie plus bas, pres de la disposition du panneau : RefreshList l'appelle pour
-- ranger les lignes qu'il vient de creer.
local ApplyLevels

local layout = { y = 0, headers = 0, rows = 0, snapshot = nil, available = nil }

-- Ligne dont l'infobulle est posee : passer d'une ligne a l'un de ses boutons ne doit
-- rien reconstruire. Remise a nil des que la liste change.
local tooltipRow

-- Cout et avancement d'une save ne dependent que de l'arbre. Tant que sa lecture n'a pas
-- change, on les relit ici plutot que de reparcourir ses 800 noeuds — pour chaque ligne,
-- a chaque clic du joueur dans l'arbre, qui bouge le solde et redessine la liste.
local savePlans = {}

local function GetSavePlan(saveId, save, snapshot)
    local stamp = NS.Core.GetSnapshotStamp()
    local plan = savePlans[saveId]
    if plan and plan.stamp == stamp then return plan end

    plan = plan or {}
    plan.totalCost, plan.pendingNodes = NS.Core.ComputeActivationPlan(save.nodeRanks, snapshot)
    plan.ownedCost, plan.saveCost, plan.ownedNodes, plan.totalNodes =
        NS.Plan.ComputeProgress(save.nodeRanks, snapshot)

    -- Un arbre illisible ne se met pas en cache : la prochaine lecture doit reessayer.
    plan.stamp = plan.totalCost and stamp or nil
    savePlans[saveId] = plan
    return plan
end

local function ActivateSave(saveId)
    local save = NS.Data.GetSave(saveId)
    if not save then return end

    NS.Core.InvalidateSnapshot()
    local snapshot = NS.Core.GetTreeSnapshot()
    local _, pendingNodes = NS.Core.ComputeActivationPlan(save.nodeRanks, snapshot)
    if not pendingNodes then
        NS.LogError(L.MSG_READ_FAILED)
        return
    end
    if pendingNodes == 0 then
        Log(string.format(L.MSG_ALREADY_ACTIVE, save.name))
        return
    end

    -- Le plan progressif est recalcule au clic, jamais repris de la liste : entre le
    -- dernier rafraichissement et maintenant, le solde a pu bouger.
    local targets, touched, partial = save.nodeRanks, pendingNodes, false

    if save.progressive then
        local available = NS.Core.GetAvailableSoulAshes() or 0
        local chosen, _, count =
            NS.Plan.ComputeProgressive(save.nodeRanks, snapshot, available)

        if not chosen then
            NS.LogError(string.format(L.MSG_ACTIVATION_FAILED, L.ERR_NO_GRAPH))
            return
        end
        if count == 0 then
            NS.LogWarn(string.format(L.MSG_NOTHING_AFFORDABLE, save.name))
            return
        end

        targets, touched, partial = chosen, count, count < pendingNodes
    end

    local cost, err = NS.Core.ApplyBuild(targets)
    if not cost then
        NS.LogError(string.format(L.MSG_ACTIVATION_FAILED, tostring(err)))
        UI.RefreshList()
        return
    end

    if partial then
        Log(Colorize(COLOR.SUCCESS, string.format(L.MSG_APPLIED_PARTIAL,
            save.name, touched, FormatCost(cost), pendingNodes - touched)))
    else
        Log(Colorize(COLOR.SUCCESS, string.format(L.MSG_APPLIED,
            save.name, touched, FormatCost(cost))))
    end
    UI.RefreshList()
end

-- La fenetre qui porte l'arbre : son ancetre juste sous UIParent. Depuis que l'arbre
-- est un onglet de CollectionsJournal, ses bords ne sont plus ceux de la fenetre, et
-- c'est contre la fenetre que le panneau doit se poser.
local function GetTreeWindow()
    local window, parent = skillTreeFrame, skillTreeFrame:GetParent()
    while parent and parent ~= UIParent do
        window, parent = parent, parent:GetParent()
    end
    return window
end

local TOOLTIP_GAP = 4

-- Bords en pixels d'ecran : l'infobulle, le panneau et la fenetre n'ont pas forcement la
-- meme echelle.
local function ScreenLeft(frame)
    return frame:GetLeft() * frame:GetEffectiveScale()
end

local function ScreenRight(frame)
    return frame:GetRight() * frame:GetEffectiveScale()
end

-- Alignee sur le haut de la ligne, l'infobulle se colle au bord `edge` du cote voulu.
-- Les decalages de SetPoint se comptent a l'echelle de l'infobulle.
local function AnchorTooltip(row, towardRight, edge)
    local scale = GameTooltip:GetEffectiveScale()
    GameTooltip:ClearAllPoints()
    if towardRight then
        GameTooltip:SetPoint("TOPLEFT", row, "TOPRIGHT",
            (ScreenRight(edge) - ScreenRight(row)) / scale + TOOLTIP_GAP, 0)
    else
        GameTooltip:SetPoint("TOPRIGHT", row, "TOPLEFT",
            (ScreenLeft(edge) - ScreenLeft(row)) / scale - TOOLTIP_GAP, 0)
    end
end

-- Panneau a gauche, l'infobulle n'a nulle part ou aller de cote : dehors, la fenetre
-- colle au bord de l'ecran ; dedans, elle recouvrirait l'arbre. Elle se pose donc sous
-- la ligne, dans la colonne du panneau dont elle a pris la largeur, ou au-dessus quand
-- l'ecran manque de place en bas.
local function StackTooltip(row)
    local scale = GameTooltip:GetEffectiveScale()
    local rowScale = row:GetEffectiveScale()
    local needed = (GameTooltip:GetHeight() + TOOLTIP_GAP) * scale
    local below = row:GetBottom() * rowScale
    local above = UIParent:GetHeight() * UIParent:GetEffectiveScale() - row:GetTop() * rowScale
    local x = (ScreenLeft(panel) - ScreenLeft(row)) / scale

    GameTooltip:ClearAllPoints()
    if below >= needed or below >= above then
        GameTooltip:SetPoint("TOPLEFT", row, "BOTTOMLEFT", x, -TOOLTIP_GAP)
    else
        GameTooltip:SetPoint("BOTTOMLEFT", row, "TOPLEFT", x, TOOLTIP_GAP)
    end
end

-- Panneau a droite, l'infobulle part vers l'exterieur, loin de l'arbre qu'elle
-- recouvrirait. En mode compact, l'exterieur commence au bord de la fenetre, le panneau
-- etant dedans. Elle ne revient cote arbre, contre le bord interieur du panneau, que si
-- l'ecran n'a pas la place de la loger dehors : l'infobulle est bornee a l'ecran, et le
-- client la ramenerait sinon par-dessus le panneau lui-meme.
local function PlaceRowTooltip(row, stacked)
    local outer = NS.Data.IsCompact() and GetTreeWindow() or panel
    if not (outer:GetLeft() and row:GetLeft() and row:GetBottom() and panel:GetLeft()) then
        -- Geometrie pas encore calculee : une ancre simple plutot qu'une infobulle sans
        -- aucun point, que le client n'afficherait nulle part.
        GameTooltip:ClearAllPoints()
        GameTooltip:SetPoint("TOPLEFT", row, "TOPRIGHT", TOOLTIP_GAP, 0)
        return
    end

    if stacked then
        StackTooltip(row)
        return
    end

    local towardRight = NS.Data.GetPanelSide() == "RIGHT"
    local needed = (GameTooltip:GetWidth() + TOOLTIP_GAP) * GameTooltip:GetEffectiveScale()
    local room
    if towardRight then
        room = UIParent:GetWidth() * UIParent:GetEffectiveScale() - ScreenRight(outer)
    else
        room = ScreenLeft(outer)
    end

    if room >= needed then
        AnchorTooltip(row, towardRight, outer)
    else
        AnchorTooltip(row, not towardRight, panel)
    end
end

local function ShowRowTooltip(self)
    local row = self.row or self
    local save = row.saveId and NS.Data.GetSave(row.saveId)
    if not save then return end

    -- Deja pose pour cette ligne : la souris n'a fait que passer sur l'un de ses boutons.
    if tooltipRow == row then return end
    tooltipRow = row

    local snapshot = NS.Core.GetTreeSnapshot()

    -- Ce que la save ajouterait ne sert qu'ici, au survol : le calculer pour chaque
    -- ligne a chaque rafraichissement revenait a preparer une table par save pour
    -- celle, au plus, que le joueur allait survoler. `affordable` vient de la ligne,
    -- lui : c'est le plan que son texte annonce, il doit rester celui-la.
    -- L'apercu decide quand poser les cadres : pendant qu'il deplace la vue, ils
    -- couteraient un redimensionnement par palier de zoom, des centaines a la fois.
    local missing = snapshot and NS.Plan.ComputeMissing(save.nodeRanks, snapshot)
    NS.View.Preview(row.saveId, missing, row.affordable)

    -- Posee apres Show : c'est Show qui donne sa taille a l'infobulle, et il faut la
    -- connaitre pour savoir ou elle loge.
    --
    -- Empilee sous la ligne (panneau a gauche), elle prend la largeur du panneau et toutes
    -- ses lignes passent a la ligne : trop large, elle deborderait sur l'arbre. La largeur
    -- minimale est remise a zero dans tous les autres cas, GameTooltip servant a toute
    -- l'interface.
    local stacked = NS.Data.GetPanelSide() == "LEFT"
    GameTooltip:SetOwner(row, "ANCHOR_NONE")
    if GameTooltip.SetMinimumWidth then
        GameTooltip:SetMinimumWidth(stacked
            and (panel:GetWidth() * panel:GetEffectiveScale() / GameTooltip:GetEffectiveScale())
            or 0)
    end
    GameTooltip:SetText(save.name, 1, 1, 1, 1, stacked)

    local plan = GetSavePlan(row.saveId, save, snapshot)
    local totalCost, pendingNodes = plan.totalCost, plan.pendingNodes
    if not totalCost then
        GameTooltip:AddLine(L.TOOLTIP_READ_FAILED, 1, 0.3, 0.3, stacked)
    elseif pendingNodes == 0 then
        GameTooltip:AddLine(L.ROW_ACTIVE, 0.25, 1, 0.25, stacked)
    else
        if plan.ownedCost then
            GameTooltip:AddLine(string.format(L.TOOLTIP_PROGRESS, plan.ownedNodes, plan.totalNodes,
                FormatCost(plan.ownedCost), FormatCost(plan.saveCost)), 0.8, 0.8, 0.8, stacked)
        end

        GameTooltip:AddLine(string.format(L.TOOLTIP_COST, FormatCost(totalCost)), 1, 0.82, 0, stacked)

        local available = NS.Core.GetAvailableSoulAshes()
        if available and available < totalCost then
            GameTooltip:AddLine(string.format(L.TOOLTIP_MISSING, FormatCost(totalCost - available)),
                1, 0.3, 0.3, stacked)
        end

        -- La legende n'a de sens qu'en progressif : c'est le seul cas ou l'arbre
        -- porte deux couleurs.
        if row.affordable then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L.TOOLTIP_LEGEND_NOW, 0.3, 1, 0.3, stacked)
            GameTooltip:AddLine(L.TOOLTIP_LEGEND_LATER, 1, 0.65, 0.1, stacked)
        end
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(save.progressive and L.TOOLTIP_MODE_PROGRESSIVE or L.TOOLTIP_MODE_STRICT,
        0.6, 0.6, 0.6, true)

    GameTooltip:Show()
    PlaceRowTooltip(row, stacked)

    -- Le client habille GameTooltip d'un fond translucide : pose par-dessus la liste
    -- des saves, le texte devient illisible. On repose l'opacite apres Show, pas
    -- avant : c'est Show qui declenche l'habillage qu'il faut recouvrir.
    if GameTooltip.SetBackdropColor then
        GameTooltip:SetBackdropColor(0, 0, 0, 1)
    end
end

local function HideRowTooltip(self)
    -- Glisser de la ligne a l'un de ses boutons, ou l'inverse, n'est pas un depart : tout
    -- defaire puis tout refaire a chaque mouvement dans la ligne coutait, sur une grosse
    -- save, des milliers d'appels et une transition relancee.
    local row = self and (self.row or self)
    if row and row:IsMouseOver() then return end

    tooltipRow = nil
    GameTooltip:Hide()
    if GameTooltip.SetMinimumWidth then GameTooltip:SetMinimumWidth(0) end
    NS.Overlay.Hide()
    NS.View.Release()
end

-- Le mode se bascule en pleine partie : pas de Persist ici, donc pas de ReloadUI.
local function SetRowProgressive(row, enabled)
    if not row.saveId then return end
    if not NS.Data.SetSaveProgressive(row.saveId, enabled) then return end

    UI.RefreshList()
    ShowRowTooltip(row)
end

local function OnProgressiveOnClick(self)
    SetRowProgressive(self.row, true)
end

local function OnProgressiveOffClick(self)
    SetRowProgressive(self.row, false)
end

local function OnHeaderClick(self)
    if self.groupId then NS.Menus.ShowGroupMenu(self.groupId, self) end
end

local function OnActivateClick(self)
    ActivateSave(self.row.saveId)

    -- L'arbre vient de changer sous la souris : marques, infobulle et apercu suivent.
    if self:IsMouseOver() then ShowRowTooltip(self) end
end

local function OnRowMenuClick(self)
    NS.Menus.ShowSaveMenu(self.row.saveId, self)
end

local function AcquireHeader(index)
    local header = headerPool[index]
    if header then return header end

    header = CreateFrame("Button", nil, scrollChild)
    header:SetHeight(GROUP_HEADER_HEIGHT)
    header:RegisterForClicks("RightButtonUp")

    header.bg = header:CreateTexture(nil, "BACKGROUND")
    header.bg:SetAllPoints(header)
    header.bg:SetTexture(0.2, 0.16, 0.05, 0.65)

    header.text = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header.text:SetPoint("LEFT", header, "LEFT", 4, 0)

    header:SetScript("OnClick", OnHeaderClick)

    headerPool[index] = header
    return header
end

local function AcquireRow(index)
    local row = rowPool[index]
    if row then return row end

    row = CreateFrame("Button", nil, scrollChild)
    row:SetHeight(ROW_HEIGHT)

    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints(row)

    -- L'avancement remplit le fond de la ligne plutot que d'occuper une barre a lui :
    -- il ne coute aucune hauteur, et sur une liste longue il se lit sans etre lu.
    row.fill = row:CreateTexture(nil, "BORDER")
    row.fill:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    row.fill:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    row.fill:SetTexture(0.25, 0.75, 0.35, 0.16)
    row.fill:Hide()

    row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.nameText:SetPoint("TOPLEFT", row, "TOPLEFT", 6, -4)
    row.nameText:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.nameText:SetJustifyH("LEFT")

    row.costText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.costText:SetPoint("TOPLEFT", row.nameText, "BOTTOMLEFT", 0, -2)
    row.costText:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.costText:SetJustifyH("LEFT")

    row.menuBtn = CreateFrame("Button", "STAL_Row" .. index .. "MenuBtn", row, "UIPanelButtonTemplate2")
    row.menuBtn:SetSize(24, 16)
    row.menuBtn:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -4, 5)
    row.menuBtn:SetText(L.BTN_MENU)
    row.menuBtn.row = row
    row.menuBtn:SetScript("OnClick", OnRowMenuClick)

    row.activateBtn = CreateFrame("Button", "STAL_Row" .. index .. "ActivateBtn", row, "UIPanelButtonTemplate2")
    row.activateBtn:SetSize(62, 16)
    row.activateBtn:SetPoint("RIGHT", row.menuBtn, "LEFT", -2, 0)
    row.activateBtn:SetText(L.BTN_ACTIVATE)
    row.activateBtn.row = row
    row.activateBtn:SetScript("OnClick", OnActivateClick)

    row.onBtn = CreateFrame("Button", "STAL_Row" .. index .. "OnBtn", row, "UIPanelButtonTemplate2")
    row.onBtn:SetSize(TOGGLE_WIDTH, TOGGLE_HEIGHT)
    row.onBtn:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 6 + TOGGLE_LABEL_WIDTH + 4, 5)
    row.onBtn.row = row
    row.onBtn:SetScript("OnClick", OnProgressiveOnClick)

    row.offBtn = CreateFrame("Button", "STAL_Row" .. index .. "OffBtn", row, "UIPanelButtonTemplate2")
    row.offBtn:SetSize(TOGGLE_WIDTH, TOGGLE_HEIGHT)
    row.offBtn:SetPoint("LEFT", row.onBtn, "RIGHT", 1, 0)
    row.offBtn.row = row
    row.offBtn:SetScript("OnClick", OnProgressiveOffClick)

    -- Largeur figee et ancrage par la droite : le libelle se centre sur la bascule et
    -- se coupe au lieu de la pousser dans le bouton Activer quand la langue est longue.
    row.progLabel = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.progLabel:SetWidth(TOGGLE_LABEL_WIDTH)
    row.progLabel:SetJustifyH("LEFT")
    row.progLabel:SetPoint("RIGHT", row.onBtn, "LEFT", -4, 0)
    row.progLabel:SetText(L.ROW_PROGRESSIVE)

    row:SetScript("OnEnter", ShowRowTooltip)
    row:SetScript("OnLeave", HideRowTooltip)
    row.activateBtn:SetScript("OnEnter", ShowRowTooltip)
    row.activateBtn:SetScript("OnLeave", HideRowTooltip)
    row.menuBtn:SetScript("OnEnter", ShowRowTooltip)
    row.menuBtn:SetScript("OnLeave", HideRowTooltip)
    row.onBtn:SetScript("OnEnter", ShowRowTooltip)
    row.onBtn:SetScript("OnLeave", HideRowTooltip)
    row.offBtn:SetScript("OnEnter", ShowRowTooltip)
    row.offBtn:SetScript("OnLeave", HideRowTooltip)

    rowPool[index] = row
    return row
end

local function SetRowFill(row, fraction)
    if not fraction or fraction <= 0 then
        row.fill:Hide()
        return
    end

    if fraction > 1 then fraction = 1 end
    row.fill:SetWidth(math.max(1, ROW_WIDTH * fraction))
    row.fill:Show()
end

local function SetRowMode(row, progressive)
    row.onBtn:SetText(Colorize(progressive and COLOR.SUCCESS or COLOR.DIM, L.BTN_ON))
    row.offBtn:SetText(Colorize(progressive and COLOR.DIM or COLOR.HIGHLIGHT, L.BTN_OFF))
end

local function LayoutSaveRow(saveId)
    local save = NS.Data.GetSave(saveId)
    if not save then return end

    layout.rows = layout.rows + 1
    local row = AcquireRow(layout.rows)
    row.saveId = saveId
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 2, layout.y)
    row:SetPoint("RIGHT", scrollChild, "RIGHT", -2, 0)
    row:Show()

    -- Sur le verre du mode compact, les icones de l'arbre passent sous le texte : le
    -- fond de ligne se fonce pour qu'il reste lisible.
    if NS.Data.IsCompact() then
        row.bg:SetTexture(0, 0, 0, 0.35)
    else
        row.bg:SetTexture(1, 1, 1, 0.04)
    end

    row.nameText:SetText(save.name)

    local progressive = save.progressive == true
    SetRowMode(row, progressive)

    local plan = layout.snapshot and GetSavePlan(saveId, save, layout.snapshot)
    local totalCost, pendingNodes = plan and plan.totalCost, plan and plan.pendingNodes

    -- Le plan que l'overlay peindra en vert au survol. Reste nil en mode complet :
    -- rien a departager, une seule couleur sur l'arbre.
    row.affordable = nil

    local canActivate = false

    if not totalCost then
        row.costText:SetText(Colorize(COLOR.ERROR, L.ROW_READ_FAILED))
        SetRowFill(row, 0)
    elseif pendingNodes == 0 then
        row.costText:SetText(Colorize(COLOR.SUCCESS, L.ROW_ACTIVE))
        SetRowFill(row, 1)
    else
        local ownedCost, saveCost = plan.ownedCost, plan.saveCost
        SetRowFill(row, (ownedCost and saveCost and saveCost > 0) and (ownedCost / saveCost) or 0)

        if progressive then
            local chosen, spent, count, blocked =
                NS.Plan.ComputeProgressive(save.nodeRanks, layout.snapshot, layout.available or 0)

            if chosen and count > 0 then
                row.affordable = chosen
                row.costText:SetText(string.format(L.ROW_NEXT_STEP, count, FormatCost(spent)))
                canActivate = true
            else
                row.affordable = chosen or {}
                -- Le seul chiffre utile quand rien n'est payable : le prix du prochain
                -- rang ouvert, pas le total de la save.
                local short = blocked and (blocked - (layout.available or 0))
                if short and short > 0 then
                    row.costText:SetText(Colorize(COLOR.WARN,
                        string.format(L.ROW_BLOCKED, FormatCost(short))))
                else
                    row.costText:SetText(string.format(L.ROW_COST, pendingNodes, FormatCost(totalCost)))
                end
            end
        else
            row.costText:SetText(string.format(L.ROW_COST, pendingNodes, FormatCost(totalCost)))
            canActivate = (layout.available ~= nil) and (layout.available >= totalCost)
        end
    end

    if canActivate then
        row.activateBtn:Enable()
    else
        row.activateBtn:Disable()
    end

    layout.y = layout.y - (ROW_HEIGHT + ROW_SPACING)
end

-- La liste des saves du groupe est passee plutot que redemandee : l'appelant doit
-- deja la connaitre pour savoir s'il y a un groupe a dessiner, et chaque demande
-- rebalaye puis retrie toutes les saves de la base.
local function LayoutGroup(groupId, groupName, saveIds)
    layout.headers = layout.headers + 1
    local header = AcquireHeader(layout.headers)
    header.groupId = groupId
    header.text:SetText(groupName)
    header:ClearAllPoints()
    header:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, layout.y)
    header:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
    header:Show()

    layout.y = layout.y - (GROUP_HEADER_HEIGHT + ROW_SPACING)

    for _, saveId in ipairs(saveIds) do
        LayoutSaveRow(saveId)
    end
end

function UI.RefreshList()
    if not scrollChild then return end

    -- Le contenu des lignes va changer : l'infobulle deja posee ne vaut plus.
    tooltipRow = nil

    -- Replie, la liste n'est pas a l'ecran : on la redessinera au deploiement.
    if NS.Data.IsPanelCollapsed() then return end

    layout.y = -2
    layout.headers = 0
    layout.rows = 0
    layout.snapshot = NS.Core.GetTreeSnapshot()
    layout.available = NS.Core.GetAvailableSoulAshes()

    for _, groupId in ipairs(NS.Data.GetSortedGroupIds()) do
        LayoutGroup(groupId, NS.Data.GetGroup(groupId).name,
            NS.Data.GetSortedSaveIdsInGroup(groupId))
    end

    local ungrouped = NS.Data.GetSortedSaveIdsInGroup(nil)
    if #ungrouped > 0 then
        LayoutGroup(nil, L.UNGROUPED, ungrouped)
    end

    for i = layout.headers + 1, #headerPool do headerPool[i]:Hide() end
    for i = layout.rows + 1, #rowPool do rowPool[i]:Hide() end

    scrollChild:SetHeight(math.max(-layout.y, 1))

    if layout.headers == 0 then emptyText:Show() else emptyText:Hide() end

    ApplyLevels()
end

-- CollectionsJournal est range par le gestionnaire de panneaux de Blizzard, colle au
-- bord gauche de l'ecran : a gauche, le panneau n'a jamais la place. Deplacer la
-- fenetre a la main ne tiendrait pas, le gestionnaire la replace a chaque panneau
-- ouvert ou ferme. On lui demande donc de la ranger plus a droite, par l'xoffset de
-- sa mise en page, et on rend la valeur d'origine des que l'arbre se ferme : les
-- autres onglets partagent la fenetre.
local xOffsetBase

local function SetWindowShift(window, shift)
    if not window:GetAttribute("UIPanelLayout-defined") then return end

    local current = window:GetAttribute("UIPanelLayout-xoffset") or 0
    xOffsetBase = xOffsetBase or current

    local wanted = xOffsetBase + shift
    if shift == 0 then xOffsetBase = nil end
    if current == wanted then return end

    window:SetAttribute("UIPanelLayout-xoffset", wanted)
    if window:IsShown() then UpdateUIPanelPositions(window) end
end

-- Hors mode compact, le panneau est seul dans sa strate : rien a arbitrer. En mode
-- compact, il vit dans l'arbre et doit s'intercaler entre ses couches : au-dessus des
-- noeuds et de nos marques (noeud + MARK_LEVEL), sous les boutons de choix qu'Ebonhold
-- ouvre autour d'un noeud (noeud + 10) et sous la barre de progression (arbre + 15).
-- Restent quatre niveaux pour un contenu qui en empile cinq a l'etat naturel : ils sont
-- donc poses a la main, chaque bouton toujours au-dessus de ce qui le porte, sans quoi
-- il ne recevrait plus les clics.
ApplyLevels = function()
    if not panel then return end

    local base
    if NS.Data.IsCompact() and _G.skillTreeCanvas then
        -- Les noeuds sont les enfants directs du canevas.
        base = skillTreeCanvas:GetFrameLevel() + 1 + NS.Overlay.MARK_LEVEL + 1
    else
        base = panel:GetParent():GetFrameLevel() + 1
    end

    panel:SetFrameLevel(base)
    sideBtn:SetFrameLevel(base + 1)
    collapseBtn:SetFrameLevel(base + 1)
    menuBtn:SetFrameLevel(base + 1)
    updateBtn:SetFrameLevel(base + 1)
    scroll:SetFrameLevel(base + 1)
    scrollChild:SetFrameLevel(base + 1)

    local bar = _G[scroll:GetName() .. "ScrollBar"]
    if bar then
        bar:SetFrameLevel(base + 2)
        for _, child in ipairs({ bar:GetChildren() }) do child:SetFrameLevel(base + 3) end
    end

    for _, header in ipairs(headerPool) do header:SetFrameLevel(base + 2) end
    for _, row in ipairs(rowPool) do
        row:SetFrameLevel(base + 2)
        row.menuBtn:SetFrameLevel(base + 3)
        row.activateBtn:SetFrameLevel(base + 3)
        row.onBtn:SetFrameLevel(base + 3)
        row.offBtn:SetFrameLevel(base + 3)
    end
end

local DIALOG_BACKDROP = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
}

-- La bordure de dialogue a des coins de 32 : sur une languette de 40, ils se chevauchent.
local TAB_BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

local GLASS_BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    tile = true, tileSize = 16,
}

-- Un addon ne peut pas flouter ce qui est dessine dessous : le verre du mode compact est
-- un voile noir, un grain etire par-dessus, et un fondu sur le bord qui touche l'arbre.
local function ApplyLook(compact, collapsed, side)
    if compact then
        panel:SetBackdrop(GLASS_BACKDROP)
        panel:SetBackdropColor(0, 0, 0, GLASS_ALPHA)
        grain:Show()
    else
        panel:SetBackdrop(collapsed and TAB_BACKDROP or DIALOG_BACKDROP)
        panel:SetBackdropColor(0, 0, 0, 0.85)
        grain:Hide()
    end

    -- Le fondu deborde du panneau vers l'arbre : il adoucit la coupure sans agrandir la
    -- zone qui capte la souris.
    if compact and not collapsed then
        local inner = (side == "LEFT") and "RIGHT" or "LEFT"
        fade:ClearAllPoints()
        fade:SetPoint("TOP" .. side, panel, "TOP" .. inner)
        fade:SetPoint("BOTTOM" .. side, panel, "BOTTOM" .. inner)
        fade:SetWidth(GLASS_FADE_WIDTH)
        if side == "LEFT" then
            fade:SetGradientAlpha("HORIZONTAL", 0, 0, 0, GLASS_ALPHA, 0, 0, 0, 0)
        else
            fade:SetGradientAlpha("HORIZONTAL", 0, 0, 0, 0, 0, 0, 0, GLASS_ALPHA)
        end
        fade:Show()
    else
        fade:Hide()
    end
end

local function ApplyLayout()
    if not (panel and _G.skillTreeFrame) then return end

    local compact = NS.Data.IsCompact()
    local collapsed = NS.Data.IsPanelCollapsed()
    local side = NS.Data.GetPanelSide()
    local window = GetTreeWindow()
    local width = collapsed and TAB_WIDTH or PANEL_WIDTH

    -- Dedans, le panneau ne deborde plus : la fenetre n'a pas a s'ecarter.
    SetWindowShift(window, (not compact and side == "LEFT") and (width + PANEL_GAP) or 0)

    -- En mode compact, le panneau est un enfant de l'arbre : il s'intercale entre ses
    -- couches et le suit quand la fenetre passe au premier plan. Dehors, il reste en
    -- DIALOG : sur un ecran trop etroit, le clamp le fait mordre sur la fenetre, qui est
    -- en HIGH et se remet au premier plan de sa strate des qu'on la clique.
    local host = compact and skillTreeFrame or UIParent
    if panel:GetParent() ~= host then panel:SetParent(host) end
    panel:SetFrameStrata(compact and skillTreeFrame:GetFrameStrata() or "DIALOG")

    -- Dehors, le panneau touche la fenetre par son flanc oppose. Dedans, il se cale sur
    -- le bord de la vue de l'arbre, qui s'arrete au-dessus de la barre du bas — la vue
    -- telle qu'Ebonhold la pose : l'apercu en fait reculer le coin haut-gauche, et le
    -- panneau ne doit pas le suivre.
    local anchor, panelEdge, anchorEdge, x, topY, bottomY
    if compact then
        panelEdge, anchorEdge = side, side
        local frame, insetLeft, insetTop, insetRight, insetBottom = NS.View.GetViewInsets()
        if frame then
            anchor, topY, bottomY = frame, insetTop, insetBottom
            x = (side == "LEFT") and insetLeft or insetRight
        else
            anchor, x, topY, bottomY = _G.skillTreeScroll or skillTreeFrame, 0, 0, 0
        end
    else
        anchor, anchorEdge = window, side
        panelEdge = (side == "LEFT") and "RIGHT" or "LEFT"
        x, topY, bottomY = (side == "LEFT") and -PANEL_GAP or PANEL_GAP, 0, 0
    end

    panel:ClearAllPoints()
    panel:SetWidth(width)
    panel:SetPoint("TOP" .. panelEdge, anchor, "TOP" .. anchorEdge, x, topY)
    if collapsed then
        panel:SetHeight(TAB_HEIGHT)
    else
        panel:SetPoint("BOTTOM" .. panelEdge, anchor, "BOTTOM" .. anchorEdge, x, bottomY)
    end

    ApplyLook(compact, collapsed, side)

    -- Replie, le panneau n'est plus qu'une languette : seul le bouton qui le rouvre reste.
    collapseBtn:ClearAllPoints()
    collapseBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", collapsed and 6 or 36, -8)
    collapseBtn:SetText(collapsed and L.BTN_EXPAND or L.BTN_COLLAPSE)
    if collapsed then
        sideBtn:Hide()
        menuBtn:Hide()
        scroll:Hide()
    else
        sideBtn:Show()
        menuBtn:Show()
        scroll:Show()
    end
    UI.RefreshUpdateNotice()

    ApplyLevels()

    -- En mode compact deplie, la vue se centre sur ce que le panneau laisse libre.
    NS.View.SetCovered(side, (compact and not collapsed) and PANEL_WIDTH or 0)
end

function UI.SetCompact(enabled)
    NS.Data.SetCompact(enabled)
    ApplyLayout()
    UI.RefreshList()
end

local function CreateHeaderButtons()
    sideBtn = CreateFrame("Button", "STAL_SideBtn", panel, "UIPanelButtonTemplate2")
    sideBtn:SetSize(28, 20)
    sideBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 6, -8)
    sideBtn:SetText(L.BTN_SIDE)
    sideBtn:SetScript("OnClick", function()
        NS.Data.SetPanelSide((NS.Data.GetPanelSide() == "RIGHT") and "LEFT" or "RIGHT")
        ApplyLayout()
    end)

    -- Sa place et son libelle dependent de l'etat replie : ApplyLayout les pose.
    collapseBtn = CreateFrame("Button", "STAL_CollapseBtn", panel, "UIPanelButtonTemplate2")
    collapseBtn:SetSize(28, 20)
    collapseBtn:SetScript("OnClick", function()
        NS.Data.SetPanelCollapsed(not NS.Data.IsPanelCollapsed())
        ApplyLayout()
        -- La liste ne se redessine pas tant qu'elle est repliee : elle se rattrape ici.
        UI.RefreshList()
    end)

    menuBtn = CreateFrame("Button", "STAL_PanelMenuBtn", panel, "UIPanelButtonTemplate2")
    menuBtn:SetSize(28, 20)
    menuBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -6, -8)
    menuBtn:SetText(L.BTN_PANEL_MENU)
    menuBtn:SetScript("OnClick", function(self)
        NS.Menus.ShowPanelMenu(self)
    end)

    -- Occupe l'espace libre du bandeau, entre les boutons de gauche et le menu.
    updateBtn = CreateFrame("Button", "STAL_UpdateBtn", panel)
    updateBtn:SetHeight(20)
    updateBtn:SetPoint("LEFT", collapseBtn, "RIGHT", 6, 0)
    updateBtn:SetPoint("RIGHT", menuBtn, "LEFT", -6, 0)
    updateBtn:SetNormalFontObject(GameFontNormalSmall)
    updateBtn:SetText(Colorize(COLOR.WARN, L.BTN_UPDATE))
    updateBtn:Hide()
    updateBtn:SetScript("OnClick", function()
        NS.Menus.ShowUpdateLink()
    end)
    updateBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(string.format(L.TOOLTIP_UPDATE, NS.Update.GetAvailable() or ""),
            1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    updateBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

function UI.RefreshUpdateNotice()
    if not updateBtn then return end

    if NS.Update.GetAvailable() and not NS.Data.IsPanelCollapsed() then
        updateBtn:Show()
    else
        updateBtn:Hide()
    end
end

local function CreateScrollArea()
    scroll = CreateFrame("ScrollFrame", "STAL_PanelScroll", panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -34)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -SCROLL_MARGIN_RIGHT, SCROLL_MARGIN_BOTTOM)

    scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetWidth(PANEL_WIDTH - 12 - SCROLL_MARGIN_RIGHT)
    scrollChild:SetHeight(1)
    scroll:SetScrollChild(scrollChild)

    -- Porte par la zone de defilement, pas par le panneau : il disparait avec elle
    -- quand le panneau se replie.
    emptyText = scroll:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    emptyText:SetPoint("TOP", scroll, "TOP", 0, -10)
    emptyText:SetWidth(PANEL_WIDTH - 30)
    emptyText:SetText(L.EMPTY_LIST)
end

local function BuildPanel()
    if panel or not _G.skillTreeFrame then return end

    panel = CreateFrame("Frame", "STAL_Panel", UIParent)
    panel:SetClampedToScreen(true)
    NS.View.Attach(panel)

    -- Le panneau capte la souris sur toute sa surface, molette comprise : en mode
    -- compact, un clic entre deux lignes ou un tour de molette n'atteint pas l'arbre.
    panel:EnableMouse(true)
    panel:EnableMouseWheel(true)
    panel:SetScript("OnMouseWheel", function() end)

    grain = panel:CreateTexture(nil, "BORDER")
    grain:SetAllPoints(panel)
    grain:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    grain:SetAlpha(GLASS_GRAIN_ALPHA)

    fade = panel:CreateTexture(nil, "BACKGROUND")
    fade:SetTexture("Interface\\Buttons\\WHITE8X8")

    CreateHeaderButtons()
    CreateScrollArea()

    local lastAshes, sinceCheck = nil, 0
    panel:SetScript("OnUpdate", function(_, elapsed)
        sinceCheck = sinceCheck + elapsed
        if sinceCheck < NS.ASHES_POLL_INTERVAL then return end

        -- On retire l'intervalle au lieu de remettre a zero : le rythme reste
        -- celui annonce, quelle que soit la duree d'une frame. Au-dela d'un tour
        -- de retard, on repart de zero plutot que de rattraper en rafale.
        sinceCheck = sinceCheck - NS.ASHES_POLL_INTERVAL
        if sinceCheck > NS.ASHES_POLL_INTERVAL then sinceCheck = 0 end

        local ashes = NS.Core.GetAvailableSoulAshes()
        if ashes ~= lastAshes then
            lastAshes = ashes
            NS.Core.InvalidateSnapshot()
            UI.RefreshList()
        end
    end)
end

local function ShowPanel()
    BuildPanel()
    if not panel then return end

    -- A chaque ouverture et pas seulement a la creation : la fenetre a ete rendue a sa
    -- place a la fermeture de l'arbre, et ses niveaux ont pu bouger depuis.
    ApplyLayout()
    panel:Show()
    NS.Core.InvalidateSnapshot()
    UI.RefreshList()
end

local function HidePanel()
    NS.Overlay.Hide()
    tooltipRow = nil
    if panel then panel:Hide() end

    NS.View.Cancel()

    -- Changer d'onglet cache l'arbre sans fermer la fenetre : les autres onglets la
    -- retrouvent a sa place.
    SetWindowShift(GetTreeWindow(), 0)
end

function UI.Init()
    if not _G.skillTreeFrame then return end

    skillTreeFrame:HookScript("OnShow", ShowPanel)
    skillTreeFrame:HookScript("OnHide", HidePanel)
    NS.View.Init()

    -- IsVisible et non IsShown : l'onglet de l'arbre reste "montre" fenetre fermee.
    if skillTreeFrame:IsVisible() then ShowPanel() end
end
