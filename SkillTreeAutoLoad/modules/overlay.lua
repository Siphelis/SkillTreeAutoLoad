local NS = SkillTreeAutoLoad

local Overlay = {}
NS.Overlay = Overlay

local MARK_TEXTURE = "Interface\\Buttons\\UI-ActionButton-Border"
local MARK_INSET = 8
local MARK_LEVEL = 5

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
    mark:SetPoint("TOPLEFT", button, "TOPLEFT", -MARK_INSET, MARK_INSET)
    mark:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", MARK_INSET, -MARK_INSET)
    mark:SetFrameLevel(button:GetFrameLevel() + MARK_LEVEL)
    mark:Hide()

    mark.texture = mark:CreateTexture(nil, "OVERLAY")
    mark.texture:SetAllPoints(mark)
    mark.texture:SetTexture(MARK_TEXTURE)
    mark.texture:SetBlendMode("ADD")

    marks[nodeId] = mark
    return mark
end

local function Mark(nodeId, r, g, b, alpha)
    local mark = GetMark(nodeId)
    if not mark then return end

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

-- `missing` est tout ce que la save ajouterait, `affordable` ce que le clic prendrait
-- maintenant — un sous-ensemble du premier. Deux marques donc : vert vif pour ce qui
-- part tout de suite, ambre eteint pour le reste. En mode complet `affordable` vaut
-- nil : il n'y a rien a departager, une seule couleur suffit.
function Overlay.Show(missing, affordable)
    Overlay.Hide()
    if not missing then return end

    for nodeId in pairs(missing) do
        if not affordable then
            Mark(nodeId, 1, 0.82, 0, 0.85)
        elseif affordable[nodeId] then
            Mark(nodeId, 0.3, 1, 0.3, 1)
        else
            Mark(nodeId, 1, 0.65, 0.1, 0.4)
        end
    end
end
