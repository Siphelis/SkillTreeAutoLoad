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

local ROW_WIDTH = PANEL_WIDTH - 12 - SCROLL_MARGIN_RIGHT - 4

local TEXT_ON_ACTIVE = Colorize(COLOR.SUCCESS, L.BTN_ON)
local TEXT_ON_DIM = Colorize(COLOR.DIM, L.BTN_ON)
local TEXT_OFF_ACTIVE = Colorize(COLOR.HIGHLIGHT, L.BTN_OFF)
local TEXT_OFF_DIM = Colorize(COLOR.DIM, L.BTN_OFF)
local TEXT_READ_FAILED = Colorize(COLOR.ERROR, L.ROW_READ_FAILED)
local TEXT_ACTIVE = Colorize(COLOR.SUCCESS, L.ROW_ACTIVE)
local NO_NODES = {}

local panel, scroll, scrollChild, emptyText
local sideBtn, collapseBtn, menuBtn, updateBtn, grain, fade
local headerPool, rowPool = {}, {}
local panelShown = false
local watched, refreshDriver, refreshQueued = false, nil, false

local ApplyLevels

local layout = { y = 0, headers = 0, rows = 0, snapshot = nil, available = nil }

local tooltipRow

local savePlans = {}

local function GetSavePlan(saveId, save, snapshot)
    local stamp = NS.Core.GetSnapshotStamp()
    local plan = savePlans[saveId]
    if plan and plan.stamp == stamp then return plan end

    plan = plan or {}
    plan.totalCost, plan.pendingNodes = NS.Core.ComputeActivationPlan(save.nodeRanks, snapshot)
    plan.ownedCost, plan.saveCost, plan.ownedNodes, plan.totalNodes =
        NS.Plan.ComputeProgress(save.nodeRanks, snapshot)

    plan.stamp = plan.totalCost and stamp or nil
    plan.progStamp = nil
    savePlans[saveId] = plan
    return plan
end

local function GetProgressivePlan(plan, save, snapshot, available)
    if plan.stamp and plan.progStamp == plan.stamp and plan.progBudget == available then
        return plan.chosen, plan.spent, plan.count, plan.blocked
    end

    local chosen, spent, count, blocked =
        NS.Plan.ComputeProgressive(save.nodeRanks, snapshot, available)
    if chosen then
        plan.chosen, plan.spent, plan.count, plan.blocked = chosen, spent, count, blocked
        plan.progStamp, plan.progBudget = plan.stamp, available
    end
    return chosen, spent, count, blocked
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

local function GetTreeWindow()
    local window, parent = skillTreeFrame, skillTreeFrame:GetParent()
    while parent and parent ~= UIParent do
        window, parent = parent, parent:GetParent()
    end
    return window
end

local TOOLTIP_GAP = 4

local function ScreenLeft(frame)
    return frame:GetLeft() * frame:GetEffectiveScale()
end

local function ScreenRight(frame)
    return frame:GetRight() * frame:GetEffectiveScale()
end

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

local function PlaceRowTooltip(row, stacked)
    local outer = NS.Data.IsCompact() and GetTreeWindow() or panel
    if not (outer:GetLeft() and row:GetLeft() and row:GetBottom() and panel:GetLeft()) then
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

    if tooltipRow == row then return end
    tooltipRow = row

    local snapshot = NS.Core.GetTreeSnapshot()

    local missing = snapshot and NS.Plan.ComputeMissing(save.nodeRanks, snapshot)
    NS.View.Preview(row.saveId, missing, row.affordable)

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

    if GameTooltip.SetBackdropColor then
        GameTooltip:SetBackdropColor(0, 0, 0, 1)
    end
end

local function HideRowTooltip(self)
    local row = self and (self.row or self)
    if row and row:IsMouseOver() then return end

    tooltipRow = nil
    GameTooltip:Hide()
    if GameTooltip.SetMinimumWidth then GameTooltip:SetMinimumWidth(0) end
    NS.Overlay.Hide()
    NS.View.Release()
end

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

    header:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
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

    row.progLabel = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.progLabel:SetWidth(TOGGLE_LABEL_WIDTH)
    row.progLabel:SetJustifyH("LEFT")
    row.progLabel:SetPoint("RIGHT", row.onBtn, "LEFT", -4, 0)
    row.progLabel:SetText(L.ROW_PROGRESSIVE)

    row:SetPoint("RIGHT", scrollChild, "RIGHT", -2, 0)
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
    local width
    if fraction and fraction > 0 then
        if fraction > 1 then fraction = 1 end
        width = ROW_WIDTH * fraction
        if width < 1 then width = 1 end
    end

    if row.fillLast == width then return end
    row.fillLast = width

    if width then
        row.fill:SetWidth(width)
        row.fill:Show()
    else
        row.fill:Hide()
    end
end

local function SetRowMode(row, progressive)
    if row.modeLast == progressive then return end
    row.modeLast = progressive
    row.onBtn:SetText(progressive and TEXT_ON_ACTIVE or TEXT_ON_DIM)
    row.offBtn:SetText(progressive and TEXT_OFF_DIM or TEXT_OFF_ACTIVE)
end

local function SetRowCost(row, text)
    if row.costLast == text then return end
    row.costLast = text
    row.costText:SetText(text)
end

local function PlaceFrame(frame, x, y)
    if frame.yLast ~= y then
        frame.yLast = y
        frame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", x, y)
    end
    if not frame.shown then
        frame.shown = true
        frame:Show()
    end
end

local function HideFrom(pool, first)
    for i = first, #pool do
        local frame = pool[i]
        if frame.shown then
            frame.shown = false
            frame:Hide()
        end
    end
end

local function LayoutSaveRow(saveId)
    local save = NS.Data.GetSave(saveId)
    if not save then return end

    layout.rows = layout.rows + 1
    local row = AcquireRow(layout.rows)
    row.saveId = saveId
    PlaceFrame(row, 2, layout.y)

    local dark = NS.Data.IsCompact()
    if row.bgLast ~= dark then
        row.bgLast = dark
        if dark then
            row.bg:SetTexture(0, 0, 0, 0.35)
        else
            row.bg:SetTexture(1, 1, 1, 0.04)
        end
    end

    if row.nameLast ~= save.name then
        row.nameLast = save.name
        row.nameText:SetText(save.name)
    end

    local progressive = save.progressive == true
    SetRowMode(row, progressive)

    local plan = layout.snapshot and GetSavePlan(saveId, save, layout.snapshot)
    local totalCost, pendingNodes = plan and plan.totalCost, plan and plan.pendingNodes

    row.affordable = nil

    local canActivate = false

    if not totalCost then
        SetRowCost(row, TEXT_READ_FAILED)
        SetRowFill(row, 0)
    elseif pendingNodes == 0 then
        SetRowCost(row, TEXT_ACTIVE)
        SetRowFill(row, 1)
    else
        local ownedCost, saveCost = plan.ownedCost, plan.saveCost
        SetRowFill(row, (ownedCost and saveCost and saveCost > 0) and (ownedCost / saveCost) or 0)

        if progressive then
            local available = layout.available or 0
            local chosen, spent, count, blocked =
                GetProgressivePlan(plan, save, layout.snapshot, available)

            if chosen and count > 0 then
                row.affordable = chosen
                SetRowCost(row, string.format(L.ROW_NEXT_STEP, count, FormatCost(spent)))
                canActivate = true
            else
                row.affordable = chosen or NO_NODES
                local short = blocked and (blocked - available)
                if short and short > 0 then
                    SetRowCost(row, Colorize(COLOR.WARN,
                        string.format(L.ROW_BLOCKED, FormatCost(short))))
                else
                    SetRowCost(row, string.format(L.ROW_COST, pendingNodes, FormatCost(totalCost)))
                end
            end
        else
            SetRowCost(row, string.format(L.ROW_COST, pendingNodes, FormatCost(totalCost)))
            canActivate = (layout.available ~= nil) and (layout.available >= totalCost)
        end
    end

    if row.enabledLast ~= canActivate then
        row.enabledLast = canActivate
        if canActivate then
            row.activateBtn:Enable()
        else
            row.activateBtn:Disable()
        end
    end

    layout.y = layout.y - (ROW_HEIGHT + ROW_SPACING)
end

local function LayoutGroup(groupId, groupName, saveIds)
    layout.headers = layout.headers + 1
    local header = AcquireHeader(layout.headers)
    header.groupId = groupId
    if header.nameLast ~= groupName then
        header.nameLast = groupName
        header.text:SetText(groupName)
    end
    PlaceFrame(header, 0, layout.y)

    layout.y = layout.y - (GROUP_HEADER_HEIGHT + ROW_SPACING)

    for i = 1, #saveIds do
        LayoutSaveRow(saveIds[i])
    end
end

function UI.RefreshList()
    if not scrollChild then return end

    tooltipRow = nil

    if NS.Data.IsPanelCollapsed() then return end

    layout.y = -2
    layout.headers = 0
    layout.rows = 0
    layout.snapshot = NS.Core.GetTreeSnapshot()
    layout.available = NS.Core.GetAvailableSoulAshes()

    local groupIds = NS.Data.GetSortedGroupIds()
    for i = 1, #groupIds do
        local groupId = groupIds[i]
        LayoutGroup(groupId, NS.Data.GetGroup(groupId).name,
            NS.Data.GetSortedSaveIdsInGroup(groupId))
    end

    local ungrouped = NS.Data.GetSortedSaveIdsInGroup(nil)
    if #ungrouped > 0 then
        LayoutGroup(nil, L.UNGROUPED, ungrouped)
    end

    HideFrom(headerPool, layout.headers + 1)
    HideFrom(rowPool, layout.rows + 1)

    local height = -layout.y
    if height < 1 then height = 1 end
    if layout.heightLast ~= height then
        layout.heightLast = height
        scrollChild:SetHeight(height)
    end

    local empty = layout.headers == 0
    if layout.emptyLast ~= empty then
        layout.emptyLast = empty
        if empty then emptyText:Show() else emptyText:Hide() end
    end

    ApplyLevels()
end

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

local leveledBase, leveledHeaders, leveledRows = nil, 0, 0

local function LevelChildren(level, ...)
    for i = 1, select("#", ...) do
        local child = select(i, ...)
        child:SetFrameLevel(level)
    end
end

local function LevelRow(row, base)
    row:SetFrameLevel(base + 2)
    row.menuBtn:SetFrameLevel(base + 3)
    row.activateBtn:SetFrameLevel(base + 3)
    row.onBtn:SetFrameLevel(base + 3)
    row.offBtn:SetFrameLevel(base + 3)
end

ApplyLevels = function(force)
    if not panel then return end

    local base
    if NS.Data.IsCompact() and _G.skillTreeCanvas then
        base = skillTreeCanvas:GetFrameLevel() + 1 + NS.Overlay.MARK_LEVEL + 1
    else
        base = panel:GetParent():GetFrameLevel() + 1
    end

    if force or base ~= leveledBase then
        leveledBase, leveledHeaders, leveledRows = base, 0, 0

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
            LevelChildren(base + 3, bar:GetChildren())
        end
    end

    for i = leveledHeaders + 1, #headerPool do headerPool[i]:SetFrameLevel(base + 2) end
    for i = leveledRows + 1, #rowPool do LevelRow(rowPool[i], base) end
    leveledHeaders, leveledRows = #headerPool, #rowPool
end

local DIALOG_BACKDROP = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
}

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

    SetWindowShift(window, (not compact and side == "LEFT") and (width + PANEL_GAP) or 0)

    local host = compact and skillTreeFrame or UIParent
    if panel:GetParent() ~= host then panel:SetParent(host) end
    panel:SetFrameStrata(compact and skillTreeFrame:GetFrameStrata() or "DIALOG")

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

    ApplyLevels(true)

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

    collapseBtn = CreateFrame("Button", "STAL_CollapseBtn", panel, "UIPanelButtonTemplate2")
    collapseBtn:SetSize(28, 20)
    collapseBtn:SetScript("OnClick", function()
        NS.Data.SetPanelCollapsed(not NS.Data.IsPanelCollapsed())
        ApplyLayout()
        UI.RefreshList()
    end)

    menuBtn = CreateFrame("Button", "STAL_PanelMenuBtn", panel, "UIPanelButtonTemplate2")
    menuBtn:SetSize(28, 20)
    menuBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -6, -8)
    menuBtn:SetText(L.BTN_PANEL_MENU)
    menuBtn:SetScript("OnClick", function(self)
        NS.Menus.ShowPanelMenu(self)
    end)

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

    if watched then return end

    local lastAshes, sinceCheck = nil, 0
    panel:SetScript("OnUpdate", function(_, elapsed)
        sinceCheck = sinceCheck + elapsed
        if sinceCheck < NS.ASHES_POLL_INTERVAL then return end

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

local PREWARM_DELAY = 1

local prewarming, prewarmDone, prewarmDriver

local function FirePrewarm()
    prewarmDone = true

    local onShow = skillTreeFrame:GetScript("OnShow")
    if not onShow then return end

    prewarming = true
    local ok, err = pcall(onShow, skillTreeFrame)
    prewarming = false

    if not ok then NS.LogError(string.format(L.MSG_INIT_FAILED, "Prewarm", tostring(err))) end
end

local function TickPrewarm(self, elapsed)
    if elapsed > 0.1 then elapsed = 0.1 end
    self.timer = self.timer + elapsed
    if self.timer < PREWARM_DELAY then return end

    self:Hide()

    if CollectionsJournal and CollectionsJournal:IsVisible() then
        prewarmDone = true
        return
    end

    FirePrewarm()
end

function UI.IsPrewarming()
    return prewarming == true
end

function UI.Prewarm()
    if prewarmDone or prewarming then return end
    if not _G.skillTreeFrame then return end

    if _G.skillTreeNode1 then
        prewarmDone = true
        return
    end

    if not prewarmDriver then
        prewarmDriver = CreateFrame("Frame")
        prewarmDriver:SetScript("OnUpdate", TickPrewarm)
    end

    prewarmDriver.timer = 0
    prewarmDriver:Show()
end

local function ShowPanel()
    if prewarming then return end

    BuildPanel()
    if not panel then return end

    ApplyLayout()
    panel:Show()
    panelShown = true
    NS.Core.InvalidateSnapshot()
    UI.RefreshList()
end

local function HidePanel()
    if prewarming then return end

    NS.Overlay.Hide()
    tooltipRow = nil
    panelShown = false
    if panel then panel:Hide() end

    NS.View.Cancel()

    SetWindowShift(GetTreeWindow(), 0)
end

local function FlushRefresh(self)
    self:Hide()
    refreshQueued = false
    NS.Core.InvalidateSnapshot()
    if panelShown then UI.RefreshList() end
end

local function QueueRefresh()
    if refreshQueued or not panelShown then return end
    refreshQueued = true
    refreshDriver:Show()
end

local function InstallWatch()
    if type(_G.refreshAccessibility) ~= "function" then return end

    refreshDriver = CreateFrame("Frame")
    refreshDriver:Hide()
    refreshDriver:SetScript("OnUpdate", FlushRefresh)
    hooksecurefunc("refreshAccessibility", QueueRefresh)
    watched = true
end

function UI.Init()
    if not _G.skillTreeFrame then return end

    InstallWatch()
    skillTreeFrame:HookScript("OnShow", ShowPanel)
    skillTreeFrame:HookScript("OnHide", HidePanel)
    NS.View.Init()

    if skillTreeFrame:IsVisible() then ShowPanel() end
end

UI.__test = {
    Tick = TickPrewarm,
    Fire = FirePrewarm,
    Driver = function() return prewarmDriver end,
    State = function() return prewarming, prewarmDone end,
    Reset = function()
        prewarming, prewarmDone = nil, nil
        if prewarmDriver then prewarmDriver:Hide() end
    end,
    Delays = function() return PREWARM_DELAY end,
    Watch = function() return watched, refreshQueued, refreshDriver end,
    Queue = QueueRefresh,
    Pools = function() return headerPool, rowPool end,
}
