local NS = SkillTreeAutoLoad
local L = NS.L

local Core = {}
NS.Core = Core

local nodeDefsById
local nodeButtons = {}
local warnedMultiChoice = false
local snapshotCache, snapshotTime

local function GetNodeDefs()
    if nodeDefsById then return nodeDefsById end
    if not (TalentDatabase and TalentDatabase[0] and TalentDatabase[0].nodes) then
        return nil
    end
    nodeDefsById = {}
    for _, node in ipairs(TalentDatabase[0].nodes) do
        nodeDefsById[node.id] = node
    end
    return nodeDefsById
end

local function GetNodeButton(nodeId)
    local btn = nodeButtons[nodeId]
    if btn then return btn end
    btn = _G["skillTreeNode" .. nodeId]
    if btn then nodeButtons[nodeId] = btn end
    return btn
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

    local text = btn.rankText and btn.rankText:GetText()
    local current = text and tonumber(text:match("^(%d+)/%d+$"))
    if current then return current end

    return (btn.state == "active") and #(node.spells or {}) or 0
end

function Core.InvalidateSnapshot()
    snapshotCache = nil
end

function Core.GetTreeSnapshot()
    if snapshotCache and (GetTime() - snapshotTime) < NS.SNAPSHOT_TTL then
        return snapshotCache
    end

    local defs = GetNodeDefs()
    if not defs then return nil, L.ERR_NO_DATABASE end
    if not _G.skillTreeFrame then return nil, L.ERR_TREE_NOT_READY end

    local snapshot = {}
    for nodeId, node in pairs(defs) do
        local rank = ReadNodeRank(node)
        if rank > 0 then snapshot[nodeId] = rank end
    end

    snapshotCache, snapshotTime = snapshot, GetTime()
    return snapshot
end

function Core.CaptureTreeState()
    Core.InvalidateSnapshot()
    local snapshot, err = Core.GetTreeSnapshot()
    if not snapshot then return nil, err end

    local copy = {}
    for nodeId, rank in pairs(snapshot) do copy[nodeId] = rank end
    return copy
end

function Core.GetAvailableSoulAshes()
    local frame = _G.skillTreeFrame
    local fs = frame and frame.pointsText
    if not fs then return nil end

    local text = fs:GetText()
    if not text or text == "" then return nil end

    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")

    local numberPart = text:match("([%d][%d%s,%.]*)%s*$")
    if not numberPart then return nil end

    local digits = numberPart:gsub("%D", "")
    if digits == "" then return nil end
    return tonumber(digits)
end

function Core.ComputeActivationPlan(saveNodeRanks, snapshot)
    local defs = GetNodeDefs()
    if not defs then return nil end

    snapshot = snapshot or Core.GetTreeSnapshot()
    if not snapshot then return nil end

    local totalCost = 0
    local actions = {}

    for nodeId, targetRank in pairs(saveNodeRanks or {}) do
        local node = defs[nodeId]
        if node then
            local currentRank = snapshot[nodeId] or 0
            if currentRank < targetRank then
                local costs = node.soulPointsCosts or {}
                local nodeCost = 0
                for rankIdx = currentRank + 1, targetRank do
                    nodeCost = nodeCost + (costs[rankIdx] or 0)
                end
                totalCost = totalCost + nodeCost
                actions[#actions + 1] = {
                    nodeId = nodeId,
                    toRank = targetRank,
                    cost = nodeCost,
                }
            end
        end
    end

    table.sort(actions, function(a, b) return a.nodeId < b.nodeId end)
    return totalCost, actions
end

-- La reserve ne se memorise pas : on la recalcule depuis la base annoncee par le
-- serveur, moins le cout de ce qui est a l'ecran en plus. Un clic manuel modifie
-- l'arbre, donc modifie le resultat, sans que l'addon ait a le surveiller.
function Core.GetEffectiveSpendable()
    local spendable = NS.Bridge.GetServerBalance()
    if not spendable then return nil end

    local snapshot = Core.GetTreeSnapshot()
    if not snapshot then return nil end

    local pendingCost =
        Core.ComputeActivationPlan(snapshot, NS.Bridge.GetServerNodes())
    if not pendingCost then return nil end

    return spendable - pendingCost
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

local function RunNativeImport(code)
    local button = _G.skillTreeImportButton
    local onClick = button and button:GetScript("OnClick")
    if not onClick then return false, L.ERR_NO_IMPORT_BUTTON end

    onClick(button)

    if StaticPopup_FindVisible then
        local dialog = StaticPopup_FindVisible("SKILLTREE_IMPORT_CODE")
        if dialog then dialog:Hide() end
    end

    local popup = StaticPopupDialogs["SKILLTREE_IMPORT_CODE"]
    if not (popup and popup.OnAccept) then return false, L.ERR_NO_IMPORT_POPUP end

    popup.OnAccept({ editBox = { GetText = function() return code end } })
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

    Core.InvalidateSnapshot()

    local before = Core.GetTreeSnapshot()
    if not before then return nil, L.ERR_READ_TREE end

    local cost = Core.ComputeActivationPlan(saveNodeRanks, before)
    if not cost then return nil, L.ERR_READ_TREE end

    local _, serverCommitted = NS.Bridge.GetServerBalance()
    if not serverCommitted then return nil, L.ERR_READ_BALANCE end

    local target = {}
    MergeInto(target, NS.Bridge.GetServerNodes())
    MergeInto(target, before)
    MergeInto(target, saveNodeRanks)

    local code = EncodeBuildCode(target)
    if not code then return nil, L.ERR_ENCODE end

    local ok, err = RunNativeImport(code)
    if not ok then return nil, err end

    Core.InvalidateSnapshot()
    local after = Core.GetTreeSnapshot()
    if not after then return nil, L.ERR_REREAD_TREE end

    local _, remaining = Core.ComputeActivationPlan(target, after)
    if not remaining or #remaining > 0 then
        return nil, L.ERR_MISMATCH
    end

    -- Le chemin d'import de ProjectEbonhold ne debite pas la reserve, contrairement
    -- au clic. On repose donc la valeur, recalculee en absolu : l'affichage de PE et
    -- son blocage des clics redeviennent justes, sans derive possible.
    local effective = Core.GetEffectiveSpendable()
    if effective then setSoulAshes(effective, serverCommitted) end

    return cost
end
