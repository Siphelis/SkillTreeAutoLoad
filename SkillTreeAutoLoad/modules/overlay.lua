local NS = SkillTreeAutoLoad

local Overlay = {}
NS.Overlay = Overlay

local MARK_TEXTURE = "Interface\\Buttons\\UI-ActionButton-Border"
local MARK_INSET = 8
local MARK_LEVEL = 5

-- Taille minimale d'une marque a l'ecran, en unites de la vue. L'apercu dezoome jusqu'a
-- l'arbre entier, ou un noeud ne fait plus que quelques pixels : la marque, elle, doit
-- rester une pastille lisible, faute de quoi la vue d'ensemble ne montre plus rien.
local MARK_MIN_SIZE = 12

-- Lu par le panneau en mode compact, qui doit passer au-dessus des marques.
Overlay.MARK_LEVEL = MARK_LEVEL

local marks = {}
local shown = {}

-- Le marqueur est cree comme enfant du bouton de noeud, jamais comme frere. Il suit
-- donc le deplacement, le zoom du canevas et l'estompage de la recherche de
-- ProjectEbonhold — qui baisse l'alpha du bouton, ce qui se propage aux enfants —
-- sans une seule ligne de synchronisation.
local function GetMark(nodeId)
    local mark = marks[nodeId]
    if mark then return mark end

    local button = _G["skillTreeNode" .. nodeId]
    if not button then return nil end

    mark = CreateFrame("Frame", nil, button)
    mark.button = button
    mark:SetFrameLevel(button:GetFrameLevel() + MARK_LEVEL)
    mark:Hide()

    mark.texture = mark:CreateTexture(nil, "OVERLAY")
    mark.texture:SetAllPoints(mark)
    mark.texture:SetTexture(MARK_TEXTURE)
    mark.texture:SetBlendMode("ADD")

    marks[nodeId] = mark
    return mark
end

local function CurrentZoom()
    local canvas = _G.skillTreeCanvas
    return canvas and canvas:GetScale() or 1
end

-- La marque deborde du bouton de MARK_INSET au zoom du joueur, et de ce qu'il faut
-- pour garder MARK_MIN_SIZE a l'ecran quand le canevas rapetisse.
local function PlaceMark(mark, zoom)
    local button = mark.button
    local inset = math.max(MARK_INSET, (MARK_MIN_SIZE / zoom - button:GetWidth()) / 2)

    mark:ClearAllPoints()
    mark:SetPoint("TOPLEFT", button, "TOPLEFT", -inset, inset)
    mark:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", inset, -inset)
end

local function Mark(nodeId, r, g, b, alpha)
    local mark = GetMark(nodeId)
    if not mark then return end

    PlaceMark(mark, CurrentZoom())
    mark.texture:SetVertexColor(r, g, b)
    mark.texture:SetAlpha(alpha)
    mark:Show()

    shown[#shown + 1] = mark
end

function Overlay.Hide()
    for i = 1, #shown do
        shown[i]:Hide()
        shown[i] = nil
    end
end

-- Appele par l'apercu a chaque changement de zoom.
function Overlay.Rescale()
    local zoom = CurrentZoom()
    for i = 1, #shown do PlaceMark(shown[i], zoom) end
end

-- `missing` est tout ce que la save ajouterait, `affordable` ce que le clic prendrait
-- maintenant — un sous-ensemble du premier. Deux marques donc : vert pour ce qui part
-- tout de suite, ambre pour le reste, a la meme intensite. Sur l'arbre entier vu de
-- loin, un ambre attenue disparaissait, et c'est justement l'ampleur de ce qui reste a
-- prendre que la vue d'ensemble doit montrer. En mode complet `affordable` vaut nil :
-- il n'y a rien a departager, une seule couleur suffit.
function Overlay.Show(missing, affordable)
    Overlay.Hide()
    if not missing then return end

    for nodeId in pairs(missing) do
        if not affordable then
            Mark(nodeId, 1, 0.82, 0, 0.85)
        elseif affordable[nodeId] then
            Mark(nodeId, 0.3, 1, 0.3, 1)
        else
            Mark(nodeId, 1, 0.65, 0.1, 1)
        end
    end
end
