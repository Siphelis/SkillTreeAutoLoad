local NS = SkillTreeAutoLoad
local L = NS.L

local Bridge = {}
NS.Bridge = Bridge

local LOADOUT_FIRST_TRY = 2
local LOADOUT_RETRY = 5
local LOADOUT_MAX_TRIES = 12

local loadoutId, loadoutName
local serverSpendable, serverCommitted
local serverNodes
local installed = false
local due, left

local function ReadNodes(nodes)
    local defs = NS.Core.GetNodeDefs()
    local out, dropped = {}, 0

    for nodeId, rank in pairs(nodes) do
        if defs and not defs[nodeId] then
            dropped = dropped + 1
        else
            out[nodeId] = rank
        end
    end

    if dropped > 0 then NS.LogWarn(string.format(L.MSG_UNKNOWN_NODES, dropped)) end
    return out
end

local function OnLoadout(_, loadout)
    if loadout.id and loadout.name then
        loadoutId, loadoutName = loadout.id, loadout.name
        serverNodes = ReadNodes(loadout.nodes)
    else
        loadoutId, loadoutName = nil, nil
        serverNodes = {}
        if loadout.count > 0 then NS.LogWarn(L.MSG_NO_LOADOUT_MATCH) end
    end

    NS.api:Untick("loadout")
end

local function OnAsh(_, ash)
    serverSpendable, serverCommitted = ash.spendable, ash.committed
end

local function RestorePayload(body)
    local nodes = body:sub(4)

    local present = {}
    for nodeId in nodes:gmatch("(%d+):%d+") do
        present[tonumber(nodeId)] = true
    end

    local additions = {}
    for nodeId, rank in pairs(serverNodes or {}) do
        if not present[nodeId] then
            additions[#additions + 1] = nodeId .. ":" .. rank
        end
    end

    if #additions > 0 then
        local extra = table.concat(additions, ",")
        nodes = (nodes == "") and extra or (nodes .. "," .. extra)
    end

    return loadoutId .. "|" .. loadoutName .. "|" .. nodes, #additions
end

local function TickLoadoutRequest()
    if serverNodes then
        NS.api:Untick("loadout")
        return
    end

    due = due - 1
    if due > 0 then return end

    if left <= 0 then
        NS.api:Untick("loadout")
        return
    end

    left = left - 1
    due = LOADOUT_RETRY
    EbonAPI.Ebonhold.RequestLoadout()
end

local function StartLoadoutRequest()
    if serverNodes or not EbonAPI.Ebonhold.CanRequestLoadout() then return end

    due, left = LOADOUT_FIRST_TRY, LOADOUT_MAX_TRIES
    NS.api:Tick("loadout", 1, TickLoadoutRequest)
end

function Bridge.HasLoadoutIdentity()
    return loadoutId ~= nil and loadoutName ~= nil and loadoutName ~= ""
        and serverNodes ~= nil
end

function Bridge.GetServerNodes()
    return serverNodes
end

function Bridge.GetServerBalance()
    return serverSpendable, serverCommitted
end

local function CompletePayload(original, id, body, opcode)
    if id == opcode and type(body) == "string" and body:sub(1, 3) == "0||" then
        if Bridge.HasLoadoutIdentity() then
            body = (RestorePayload(body))
        else
            NS.LogWarn(L.MSG_NO_LOADOUT_ID)
        end
    end
    return original(id, body)
end

function Bridge.Init()
    if installed then return end

    local Ebonhold = EbonAPI.Ebonhold
    local opcode = Ebonhold.OpcodeCS("REQUEST_LOADOUT_UPDATE")

    local hooked = opcode ~= nil and Ebonhold.Hook(nil, "sendToServer", function(original, id, body)
        return CompletePayload(original, id, body, opcode)
    end)

    if not hooked then
        NS.LogError(L.MSG_NO_SENDTOSERVER)
        return
    end

    if Ebonhold.CanRequestLoadout() then
        Ebonhold.Hook("SkillTree", "OnApplyChangesResult", function(original, spellId, success)
            original(spellId, success)
            if success then Ebonhold.RequestLoadout() end
        end)
    end

    NS.api:On("SERVER_LOADOUT", OnLoadout)
    NS.api:On("SERVER_ASH", OnAsh)

    StartLoadoutRequest()

    installed = true
end
