local NS = SkillTreeAutoLoad
local Log = NS.Log
local FormatCost = NS.FormatCost
local L = NS.L
local COLOR = NS.COLOR
local Colorize = NS.Colorize

local UI = {}
NS.UI = UI

local PANEL_WIDTH = 275
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

local panel, scrollChild, emptyText
local headerPool, rowPool = {}, {}

local layout = { y = 0, headers = 0, rows = 0, snapshot = nil, available = nil }

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

local function ShowRowTooltip(self)
    local row = self.row or self
    local save = row.saveId and NS.Data.GetSave(row.saveId)
    if not save then return end

    local snapshot = NS.Core.GetTreeSnapshot()

    -- Ce que la save ajouterait ne sert qu'ici, au survol : le calculer pour chaque
    -- ligne a chaque rafraichissement revenait a preparer une table par save pour
    -- celle, au plus, que le joueur allait survoler. `affordable` vient de la ligne,
    -- lui : c'est le plan que son texte annonce, il doit rester celui-la.
    NS.Overlay.Show(snapshot and NS.Plan.ComputeMissing(save.nodeRanks, snapshot),
        row.affordable)

    local anchor = (NS.Data.GetPanelSide() == "LEFT") and "ANCHOR_RIGHT" or "ANCHOR_LEFT"
    GameTooltip:SetOwner(row, anchor)
    GameTooltip:SetText(save.name, 1, 1, 1)

    local totalCost, pendingNodes = NS.Core.ComputeActivationPlan(save.nodeRanks, snapshot)
    if not totalCost then
        GameTooltip:AddLine(L.TOOLTIP_READ_FAILED, 1, 0.3, 0.3)
    elseif pendingNodes == 0 then
        GameTooltip:AddLine(L.ROW_ACTIVE, 0.25, 1, 0.25)
    else
        local ownedCost, saveCost, ownedNodes, totalNodes =
            NS.Plan.ComputeProgress(save.nodeRanks, snapshot)
        if ownedCost then
            GameTooltip:AddLine(string.format(L.TOOLTIP_PROGRESS, ownedNodes, totalNodes,
                FormatCost(ownedCost), FormatCost(saveCost)), 0.8, 0.8, 0.8)
        end

        GameTooltip:AddLine(string.format(L.TOOLTIP_COST, FormatCost(totalCost)), 1, 0.82, 0)

        local available = NS.Core.GetAvailableSoulAshes()
        if available and available < totalCost then
            GameTooltip:AddLine(string.format(L.TOOLTIP_MISSING, FormatCost(totalCost - available)),
                1, 0.3, 0.3)
        end

        -- La legende n'a de sens qu'en progressif : c'est le seul cas ou l'arbre
        -- porte deux couleurs.
        if row.affordable then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L.TOOLTIP_LEGEND_NOW, 0.3, 1, 0.3)
            GameTooltip:AddLine(L.TOOLTIP_LEGEND_LATER, 1, 0.65, 0.1)
        end
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(save.progressive and L.TOOLTIP_MODE_PROGRESSIVE or L.TOOLTIP_MODE_STRICT,
        0.6, 0.6, 0.6, true)

    GameTooltip:Show()

    -- Le client habille GameTooltip d'un fond translucide : pose par-dessus la liste
    -- des saves, le texte devient illisible. On repose l'opacite apres Show, pas
    -- avant : c'est Show qui declenche l'habillage qu'il faut recouvrir.
    if GameTooltip.SetBackdropColor then
        GameTooltip:SetBackdropColor(0, 0, 0, 1)
    end
end

local function HideRowTooltip()
    GameTooltip:Hide()
    NS.Overlay.Hide()
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
    row.bg:SetTexture(1, 1, 1, 0.04)

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

    row.nameText:SetText(save.name)

    local progressive = save.progressive == true
    SetRowMode(row, progressive)

    local totalCost, pendingNodes
    if layout.snapshot then
        totalCost, pendingNodes = NS.Core.ComputeActivationPlan(save.nodeRanks, layout.snapshot)
    end

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
        local ownedCost, saveCost = NS.Plan.ComputeProgress(save.nodeRanks, layout.snapshot)
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
end

local function PositionPanel()
    if not (panel and _G.skillTreeFrame) then return end
    panel:ClearAllPoints()
    if NS.Data.GetPanelSide() == "LEFT" then
        panel:SetPoint("TOPRIGHT", skillTreeFrame, "TOPLEFT", -6, 0)
        panel:SetPoint("BOTTOMRIGHT", skillTreeFrame, "BOTTOMLEFT", -6, 0)
    else
        panel:SetPoint("TOPLEFT", skillTreeFrame, "TOPRIGHT", 6, 0)
        panel:SetPoint("BOTTOMLEFT", skillTreeFrame, "BOTTOMRIGHT", 6, 0)
    end
end

local function CreateHeaderButtons()
    local sideBtn = CreateFrame("Button", "STAL_SideBtn", panel, "UIPanelButtonTemplate2")
    sideBtn:SetSize(28, 20)
    sideBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 6, -8)
    sideBtn:SetText(L.BTN_SIDE)
    sideBtn:SetScript("OnClick", function()
        NS.Data.SetPanelSide((NS.Data.GetPanelSide() == "RIGHT") and "LEFT" or "RIGHT")
        PositionPanel()
    end)

    local menuBtn = CreateFrame("Button", "STAL_PanelMenuBtn", panel, "UIPanelButtonTemplate2")
    menuBtn:SetSize(28, 20)
    menuBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -6, -8)
    menuBtn:SetText(L.BTN_PANEL_MENU)
    menuBtn:SetScript("OnClick", function(self)
        NS.Menus.ShowPanelMenu(self)
    end)
end

local function CreateScrollArea()
    local scroll = CreateFrame("ScrollFrame", "STAL_PanelScroll", panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -34)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -SCROLL_MARGIN_RIGHT, SCROLL_MARGIN_BOTTOM)

    scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetWidth(PANEL_WIDTH - 12 - SCROLL_MARGIN_RIGHT)
    scrollChild:SetHeight(1)
    scroll:SetScrollChild(scrollChild)

    emptyText = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    emptyText:SetPoint("TOP", scroll, "TOP", 0, -10)
    emptyText:SetWidth(PANEL_WIDTH - 30)
    emptyText:SetText(L.EMPTY_LIST)
end

local function BuildPanel()
    if panel or not _G.skillTreeFrame then return end

    panel = CreateFrame("Frame", "STAL_Panel", UIParent)
    panel:SetWidth(PANEL_WIDTH)
    panel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    panel:SetBackdropColor(0, 0, 0, 0.85)
    panel:SetFrameStrata("MEDIUM")

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

    PositionPanel()
end

local function ShowPanel()
    BuildPanel()
    if not panel then return end
    panel:Show()
    NS.Core.InvalidateSnapshot()
    UI.RefreshList()
end

local function HidePanel()
    NS.Overlay.Hide()
    if panel then panel:Hide() end
end

function UI.Init()
    if not _G.skillTreeFrame then return end

    skillTreeFrame:HookScript("OnShow", ShowPanel)
    skillTreeFrame:HookScript("OnHide", HidePanel)

    if skillTreeFrame:IsShown() then ShowPanel() end
end
