local NS = SkillTreeAutoLoad
local L = NS.L

local Core = {}
NS.Core = Core

local byte = string.byte
local wipe = wipe or function(t) for k in pairs(t) do t[k] = nil end end

local nodeDefsById, spellCountById
local nodeButtons = {}
local warnedMultiChoice = false
local buttonsReady = false
local snapshotCache, snapshotTime, snapshotCount
local snapshotDirty = true
local snapshotStamp = 0
local scratch = {}

local function GetNodeDefs()
    if nodeDefsById then return nodeDefsById end
    if not (TalentDatabase and TalentDatabase[0] and TalentDatabase[0].nodes) then
        return nil
    end
    nodeDefsById, spellCountById = {}, {}
    for _, node in ipairs(TalentDatabase[0].nodes) do
        nodeDefsById[node.id] = node
        spellCountById[node.id] = node.spells and #node.spells or 0
    end
    return nodeDefsById
end

function Core.GetNodeDefs()
    return GetNodeDefs()
end

local function GetNodeButton(nodeId)
    local btn = nodeButtons[nodeId]
    if btn then return btn end
    btn = _G["skillTreeNode" .. nodeId]
    if btn then nodeButtons[nodeId] = btn end
    return btn
end

local function TreeButtonsReady(defs)
    if buttonsReady then return true end
    for nodeId in pairs(defs) do
        if GetNodeButton(nodeId) then
            buttonsReady = true
            return true
        end
    end
    return false
end

local function WarnMultiChoice()
    if warnedMultiChoice then return end
    warnedMultiChoice = true
    NS.LogWarn(L.MSG_MULTICHOICE)
end

local function ReadNodeRank(node)
    if node.isMultipleChoice then
        WarnMultiChoice()
        return 0
    end

    local btn = GetNodeButton(node.id)
    if not btn or btn.state == "locked" then return 0 end

    if node.infinite then
        local badge = btn.stackBadge
        if not (badge and badge:IsShown()) then return 0 end
        return tonumber(badge.count:GetText()) or 0
    end

    local text = btn.rankText and btn.rankText:GetText()
    local b = text and byte(text, 1)
    if b and b >= 48 and b <= 57 then
        local value, i = 0, 1
        repeat
            value = value * 10 + (b - 48)
            i = i + 1
            b = byte(text, i)
        until not (b and b >= 48 and b <= 57)

        if b == 47 then
            i = i + 1
            b = byte(text, i)
            if b and b >= 48 and b <= 57 then
                repeat
                    i = i + 1
                    b = byte(text, i)
                until not (b and b >= 48 and b <= 57)
                if not b then return value end
            end
        end
    end

    return (btn.state == "active") and spellCountById[node.id] or 0
end

function Core.InvalidateSnapshot()
    snapshotDirty = true
end

function Core.GetTreeSnapshot()
    if snapshotCache and not snapshotDirty and (GetTime() - snapshotTime) < NS.SNAPSHOT_TTL then
        return snapshotCache
    end

    local defs = GetNodeDefs()
    if not defs then return nil, L.ERR_NO_DATABASE end
    if not _G.skillTreeFrame then return nil, L.ERR_TREE_NOT_READY end
    if not TreeButtonsReady(defs) then return nil, L.ERR_TREE_NOT_READY end

    wipe(scratch)
    local count = 0
    for nodeId, node in pairs(defs) do
        local rank = ReadNodeRank(node)
        if rank > 0 then
            scratch[nodeId] = rank
            count = count + 1
        end
    end

    snapshotTime, snapshotDirty = GetTime(), false

    if snapshotCache and count == snapshotCount then
        local same = true
        for nodeId, rank in pairs(scratch) do
            if snapshotCache[nodeId] ~= rank then
                same = false
                break
            end
        end
        if same then return snapshotCache end
    end

    snapshotCache, snapshotCount = scratch, count
    scratch = {}
    snapshotStamp = snapshotStamp + 1
    return snapshotCache
end

function Core.GetSnapshotStamp()
    return snapshotStamp
end

function Core.CaptureTreeState()
    Core.InvalidateSnapshot()
    local snapshot, err = Core.GetTreeSnapshot()
    if not snapshot then return nil, err end

    local defs = GetNodeDefs()
    local copy = {}
    for nodeId, rank in pairs(snapshot) do
        if not defs[nodeId].infinite then copy[nodeId] = rank end
    end
    return copy
end

local function ParseSoulAshes(text)
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")

    local sign, numberPart = text:match("(%-?)([%d][%d%s,%.]*)%s*$")
    if not numberPart then return nil end

    local digits = numberPart:gsub("%D", "")
    if digits == "" then return nil end

    local value = tonumber(digits)
    if not value then return nil end

    return (sign == "-") and -value or value
end

local ashesText, ashesValue

function Core.GetAvailableSoulAshes()
    local frame = _G.skillTreeFrame
    local fs = frame and frame.pointsText
    if not fs then return nil end

    local text = fs:GetText()
    if type(text) ~= "string" or text == "" then return nil end

    if text ~= ashesText then
        ashesText, ashesValue = text, ParseSoulAshes(text)
    end
    return ashesValue
end

local INFINITE_RANK_COST_CAP = 100000000

local function RankCost(node, rank)
    local costs = node.soulPointsCosts or {}
    if not node.infinite then return costs[rank] or 0 end

    local base = math.max(costs[1] or 1, 1)
    local cost = math.ceil(base * (node.infiniteGrowth or 1.15) ^ (rank - 1) - 0.000001)
    if cost >= INFINITE_RANK_COST_CAP then return INFINITE_RANK_COST_CAP end
    return math.max(cost, 1)
end

function Core.ComputeActivationPlan(saveNodeRanks, snapshot)
    local defs = GetNodeDefs()
    if not defs then return nil end

    snapshot = snapshot or Core.GetTreeSnapshot()
    if not snapshot then return nil end

    local totalCost, pendingNodes = 0, 0

    for nodeId, targetRank in pairs(saveNodeRanks or {}) do
        local node = defs[nodeId]
        if node then
            local currentRank = snapshot[nodeId] or 0
            if currentRank < targetRank then
                for rankIdx = currentRank + 1, targetRank do
                    totalCost = totalCost + RankCost(node, rankIdx)
                end
                pendingNodes = pendingNodes + 1
            end
        end
    end

    return totalCost, pendingNodes
end

function Core.GetEffectiveSpendable()
    local spendable = NS.Bridge.GetServerBalance()
    if not spendable then return nil, L.ERR_READ_BALANCE end

    local committedNodes = NS.Bridge.GetServerNodes()
    if not committedNodes then return nil, L.ERR_NO_SERVER_NODES end

    local snapshot = Core.GetTreeSnapshot()
    if not snapshot then return nil, L.ERR_READ_TREE end

    local pendingCost = Core.ComputeActivationPlan(snapshot, committedNodes)
    if not pendingCost then return nil, L.ERR_READ_TREE end

    for nodeId, committedRank in pairs(committedNodes) do
        if (snapshot[nodeId] or 0) < committedRank then
            NS.LogWarn(L.MSG_PENDING_REMOVAL)
            break
        end
    end

    local effective = spendable - pendingCost
    if effective < 0 then
        NS.LogWarn(string.format(L.MSG_NEGATIVE_BALANCE,
            NS.FormatCost(spendable), NS.FormatCost(pendingCost)))
        effective = 0
    end

    return effective
end

local function EncodeBuildCode(nodeRanks)
    if not (utils and utils.EncodeVarInt and utils.Base64Encode) then return nil end

    local list = {}
    for nodeId, rank in pairs(nodeRanks or {}) do
        if rank > 0 then list[#list + 1] = { id = nodeId, rank = rank } end
    end
    if #list == 0 then return nil end
    table.sort(list, function(a, b) return a.id < b.id end)

    local buffer = {}

    local function appendVarInt(value)
        local bytes = utils.EncodeVarInt(value)
        for i = 1, #bytes do buffer[#buffer + 1] = bytes[i] end
    end

    appendVarInt(#list)
    for i = 1, #list do
        appendVarInt(list[i].id)
        buffer[#buffer + 1] = list[i].rank
    end

    return utils.Base64Encode(buffer)
end

local function CountKnownRanks(defs, nodeRanks)
    local total = 0
    for nodeId, rank in pairs(nodeRanks or {}) do
        if defs[nodeId] then total = total + rank end
    end
    return total
end

local function RunNativeImport(code)
    local button = _G.skillTreeImportButton
    local onClick = button and button:GetScript("OnClick")
    if not onClick then return false, L.ERR_NO_IMPORT_BUTTON end

    local ok, err = pcall(onClick, button)
    if not ok then return false, tostring(err) end

    if StaticPopup_FindVisible then
        local dialog = StaticPopup_FindVisible("SKILLTREE_IMPORT_CODE")
        if dialog then dialog:Hide() end
    end

    local popup = StaticPopupDialogs["SKILLTREE_IMPORT_CODE"]
    if not (popup and popup.OnAccept) then return false, L.ERR_NO_IMPORT_POPUP end

    ok, err = pcall(popup.OnAccept, { editBox = { GetText = function() return code end } })
    if not ok then return false, tostring(err) end

    return true
end

local function MergeInto(target, source)
    for nodeId, rank in pairs(source or {}) do
        if rank > 0 and (not target[nodeId] or rank > target[nodeId]) then
            target[nodeId] = rank
        end
    end
    return target
end

function Core.ApplyBuild(saveNodeRanks)
    local setSoulAshes = ProjectEbonhold and ProjectEbonhold.SkillTree
        and ProjectEbonhold.SkillTree.UpdateTotalSoulPoints
    if not setSoulAshes then return nil, L.ERR_NO_SETTER end

    local defs = GetNodeDefs()
    if not defs then return nil, L.ERR_NO_DATABASE end

    Core.InvalidateSnapshot()

    local before = Core.GetTreeSnapshot()
    if not before then return nil, L.ERR_READ_TREE end

    local cost = Core.ComputeActivationPlan(saveNodeRanks, before)
    if not cost then return nil, L.ERR_READ_TREE end

    local _, serverCommitted = NS.Bridge.GetServerBalance()
    if not serverCommitted then return nil, L.ERR_READ_BALANCE end

    local committedNodes = NS.Bridge.GetServerNodes()
    if not committedNodes then return nil, L.ERR_NO_SERVER_NODES end

    local target = {}
    MergeInto(target, committedNodes)
    MergeInto(target, before)
    MergeInto(target, saveNodeRanks)

    local available = Core.GetAvailableSoulAshes()
    local rankTotal = CountKnownRanks(defs, target)
    if available and rankTotal > available then
        return nil, string.format(L.ERR_IMPORT_REFUSED, rankTotal, NS.FormatCost(available))
    end

    local code = EncodeBuildCode(target)
    if not code then return nil, L.ERR_ENCODE end

    local ok, err = RunNativeImport(code)
    if not ok then return nil, err end

    Core.InvalidateSnapshot()
    local after = Core.GetTreeSnapshot()
    if not after then return nil, L.ERR_REREAD_TREE end

    local _, remaining = Core.ComputeActivationPlan(target, after)
    if not remaining or remaining > 0 then
        return nil, L.ERR_MISMATCH
    end

    local effective, balanceErr = Core.GetEffectiveSpendable()
    if effective then
        setSoulAshes(effective, serverCommitted)
    else
        NS.LogWarn(string.format(L.MSG_ACTIVATION_FAILED, tostring(balanceErr)))
    end

    return cost
end
