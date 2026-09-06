local NS = SkillTreeAutoLoad
local Log = NS.Log
local FormatCost = NS.FormatCost
local L = NS.L
local COLOR = NS.COLOR
local Colorize = NS.Colorize

local UI = {}
NS.UI = UI

local PANEL_WIDTH = 230
local ROW_HEIGHT = 54
local ROW_SPACING = 3
local GROUP_HEADER_HEIGHT = 22
local SCROLL_MARGIN_RIGHT = 30
local SCROLL_MARGIN_BOTTOM = 14

local panel, scrollChild, emptyText
local headerPool, rowPool = {}, {}

local layout = { y = 0, headers = 0, rows = 0, snapshot = nil, available = nil }

local function ActivateSave(saveId)
    local save = NS.Data.GetSave(saveId)
    if not save then return end

    NS.Core.InvalidateSnapshot()
    local totalCost, actions = NS.Core.ComputeActivationPlan(save.nodeRanks)
    if not actions then
        NS.LogError(L.MSG_READ_FAILED)
        return
    end
    if #actions == 0 then
        Log(string.format(L.MSG_ALREADY_ACTIVE, save.name))
        return
    end

    local cost, err = NS.Core.ApplyBuild(save.nodeRanks)
    if not cost then
        NS.LogError(string.format(L.MSG_ACTIVATION_FAILED, tostring(err)))
        UI.RefreshList()
        return
    end

    Log(Colorize(COLOR.SUCCESS, string.format(L.MSG_APPLIED, save.name, #actions, FormatCost(cost))))
    UI.RefreshList()
end

local function ShowRowTooltip(self)
    local row = self.row or self
    local save = row.saveId and NS.Data.GetSave(row.saveId)
    if not save then return end

    local anchor = (NS.Data.GetPanelSide() == "LEFT") and "ANCHOR_RIGHT" or "ANCHOR_LEFT"
    GameTooltip:SetOwner(row, anchor)
    GameTooltip:SetText(save.name, 1, 1, 1)

    local totalCost, actions = NS.Core.ComputeActivationPlan(save.nodeRanks)
    if not totalCost then
        GameTooltip:AddLine(L.TOOLTIP_READ_FAILED, 1, 0.3, 0.3)
    elseif #actions == 0 then
        GameTooltip:AddLine(L.ROW_ACTIVE, 0.25, 1, 0.25)
    else
        GameTooltip:AddLine(string.format(L.TOOLTIP_COST, FormatCost(totalCost)), 1, 0.82, 0)

        local available = NS.Core.GetAvailableSoulAshes()
        if available and available < totalCost then
            GameTooltip:AddLine(string.format(L.TOOLTIP_MISSING, FormatCost(totalCost - available)),
                1, 0.3, 0.3)
        end
    end

    GameTooltip:Show()
end

local function HideRowTooltip()
    GameTooltip:Hide()
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

    row:SetScript("OnEnter", ShowRowTooltip)
    row:SetScript("OnLeave", HideRowTooltip)
    row.activateBtn:SetScript("OnEnter", ShowRowTooltip)
    row.activateBtn:SetScript("OnLeave", HideRowTooltip)
    row.menuBtn:SetScript("OnEnter", ShowRowTooltip)
    row.menuBtn:SetScript("OnLeave", HideRowTooltip)

    rowPool[index] = row
    return row
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

    local totalCost, actions
    if layout.snapshot then
        totalCost, actions = NS.Core.ComputeActivationPlan(save.nodeRanks, layout.snapshot)
    end

    local canActivate = false
    if not totalCost then
        row.costText:SetText(Colorize(COLOR.ERROR, L.ROW_READ_FAILED))
    elseif #actions == 0 then
        row.costText:SetText(Colorize(COLOR.SUCCESS, L.ROW_ACTIVE))
    else
        row.costText:SetText(string.format(L.ROW_COST, #actions, FormatCost(totalCost)))
        canActivate = (layout.available ~= nil) and (layout.available >= totalCost)
    end

    if canActivate then
        row.activateBtn:Enable()
    else
        row.activateBtn:Disable()
    end

    layout.y = layout.y - (ROW_HEIGHT + ROW_SPACING)
end

local function LayoutGroup(groupId, groupName)
    layout.headers = layout.headers + 1
    local header = AcquireHeader(layout.headers)
    header.groupId = groupId
    header.text:SetText(groupName)
    header:ClearAllPoints()
    header:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, layout.y)
    header:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
    header:Show()

    layout.y = layout.y - (GROUP_HEADER_HEIGHT + ROW_SPACING)

    for _, saveId in ipairs(NS.Data.GetSortedSaveIdsInGroup(groupId)) do
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
        LayoutGroup(groupId, NS.Data.GetGroup(groupId).name)
    end

    if #NS.Data.GetSortedSaveIdsInGroup(nil) > 0 then
        LayoutGroup(nil, L.UNGROUPED)
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
        sinceCheck = 0

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

    if panel then panel:Hide() end
end

function UI.Init()
    if not _G.skillTreeFrame then return end

    skillTreeFrame:HookScript("OnShow", ShowPanel)
    skillTreeFrame:HookScript("OnHide", HidePanel)

    if skillTreeFrame:IsShown() then ShowPanel() end
end
