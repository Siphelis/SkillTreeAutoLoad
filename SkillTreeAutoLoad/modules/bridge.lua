local NS = SkillTreeAutoLoad
local L = NS.L

local Bridge = {}
NS.Bridge = Bridge

local ADDON_PREFIX = "AAM0x9"
local OP_SEND_LOADOUTS = 3
local CHUNK_TIMEOUT = 15

local loadoutId, loadoutName
local serverSpendable, serverCommitted
local serverNodes = {}
local inflight = {}

local function ParseLoadouts(body)
    local globalPart, loadoutsPart = body:match("([^_]+)_?(.*)")
    if not globalPart then return end

    local selectedId = tonumber(globalPart:match("^(%d+),"))

    -- Le solde annonce par le serveur est la seule base de verite : on le garde
    -- tel quel, sans jamais le recalculer ni l'accumuler.
    local spendable, committed = globalPart:match("^%d+,(%d+),(%d+)")
    if spendable then
        serverSpendable = tonumber(spendable)
        serverCommitted = tonumber(committed)
    end

    if not loadoutsPart or loadoutsPart == "" then return end

    local chosen

    for loadoutString in loadoutsPart:gmatch("([^;]+)") do
        local parts = {}
        for part in loadoutString:gmatch("([^,]+)") do parts[#parts + 1] = part end

        if #parts >= 3 then
            local id = tonumber(parts[1])
            if not chosen then chosen = parts end
            if id and id == selectedId then
                chosen = parts
                break
            end
        end
    end

    if not chosen then return end

    loadoutId = tonumber(chosen[1])
    loadoutName = chosen[2]

    serverNodes = {}
    for i = 4, #chosen do
        local nodeId, rank = chosen[i]:match("(%d+):(%d+)")
        nodeId = tonumber(nodeId)
        rank = tonumber(rank)
        if nodeId and rank and rank > 0 then
            serverNodes[nodeId] = rank
        end
    end
end

local function PurgeStaleChunks(now)
    for mid, rec in pairs(inflight) do
        if now - rec.started > CHUNK_TIMEOUT then inflight[mid] = nil end
    end
end

local function OnAddonMessage(prefix, payload)
    if prefix ~= ADDON_PREFIX or type(payload) ~= "string" then return end

    local evtStr, rest = payload:match("^(%d+)\t(.*)$")
    if tonumber(evtStr) ~= OP_SEND_LOADOUTS then return end

    local mid, idx, tot, slice =
        rest:match("^@(%x%x%x%x)\t(%x%x%x)/(%x%x%x)\t(.*)$")

    if not mid then
        ParseLoadouts(rest)
        return
    end

    local now = GetTime()
    PurgeStaleChunks(now)

    local rec = inflight[mid]
    if not rec then
        rec = { total = tonumber(tot, 16), got = 0, parts = {}, started = now }
        inflight[mid] = rec
    end

    local i = tonumber(idx, 16)
    if i and not rec.parts[i] then
        rec.parts[i] = slice
        rec.got = rec.got + 1
    end

    if rec.got == rec.total then
        inflight[mid] = nil
        ParseLoadouts(table.concat(rec.parts, "", 1, rec.total))
    end
end

local function RestorePayload(body)
    local nodes = body:sub(4)

    local present = {}
    for nodeId in nodes:gmatch("(%d+):%d+") do
        present[tonumber(nodeId)] = true
    end

    local additions = {}
    for nodeId, rank in pairs(serverNodes) do
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

function Bridge.HasLoadoutIdentity()
    return loadoutId ~= nil and loadoutName ~= nil and loadoutName ~= ""
end

function Bridge.GetServerNodes()
    return serverNodes
end

function Bridge.GetServerBalance()
    return serverSpendable, serverCommitted
end

function Bridge.Init()
    if not (ProjectEbonhold and ProjectEbonhold.sendToServer and ProjectEbonhold.CS) then
        NS.LogError(L.MSG_NO_SENDTOSERVER)
        return
    end

    local listener = CreateFrame("Frame")
    listener:RegisterEvent("CHAT_MSG_ADDON")
    listener:SetScript("OnEvent", function(_, _, prefix, payload)
        OnAddonMessage(prefix, payload)
    end)

    local opcode = ProjectEbonhold.CS.REQUEST_LOADOUT_UPDATE
    local originalSend = ProjectEbonhold.sendToServer

    ProjectEbonhold.sendToServer = function(id, body)
        if id == opcode and type(body) == "string" and body:sub(1, 3) == "0||" then
            if Bridge.HasLoadoutIdentity() then
                body = (RestorePayload(body))
            else
                NS.LogWarn(L.MSG_NO_LOADOUT_ID)
            end
        end
        return originalSend(id, body)
    end

    -- Le serveur ne re-annonce pas le solde apres une validation reussie : on le
    -- lui redemande, exactement ce que provoque un reload.
    local onApplyResult = ProjectEbonhold.SkillTree
        and ProjectEbonhold.SkillTree.OnApplyChangesResult
    if onApplyResult and ProjectEbonhold.RequestLoadoutFromServer then
        ProjectEbonhold.SkillTree.OnApplyChangesResult = function(spellId, success)
            onApplyResult(spellId, success)
            if success then ProjectEbonhold.RequestLoadoutFromServer() end
        end
    end
end
