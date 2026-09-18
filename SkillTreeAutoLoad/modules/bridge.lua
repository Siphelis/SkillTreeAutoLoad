local NS = SkillTreeAutoLoad
local L = NS.L

local Bridge = {}
NS.Bridge = Bridge

local ADDON_PREFIX = "AAM0x9"
local CHUNK_TIMEOUT = 15
local MAX_CHUNKS = 64
local MAX_SOUL_ASHES = 1000000000

local LOADOUT_FIRST_TRY = 2
local LOADOUT_RETRY = 5
local LOADOUT_MAX_TRIES = 12

local loadoutId, loadoutName
local serverSpendable, serverCommitted

local serverNodes

local inflight = {}
local installed = false
local warnedForeign = false
local opLoadouts, opBalance

local function IsOwnClient(dist, sender)
    if dist and dist ~= "WHISPER" then return false end
    if sender and sender ~= UnitName("player") then
        if not warnedForeign then
            warnedForeign = true
            NS.LogWarn(string.format(L.MSG_FOREIGN_PAYLOAD, tostring(sender)))
        end
        return false
    end
    return true
end

local function StoreBalance(spendable, committed)
    local s, c = tonumber(spendable), tonumber(committed)
    if not (s and c) or s < 0 or c < 0 or s > MAX_SOUL_ASHES or c > MAX_SOUL_ASHES then
        NS.LogWarn(string.format(L.MSG_BAD_BALANCE,
            tostring(spendable), tostring(committed)))
        return false
    end

    serverSpendable, serverCommitted = s, c
    return true
end

local function PickLoadout(loadoutsPart, selectedId)
    local exact, fallback

    for loadoutString in loadoutsPart:gmatch("([^;]+)") do
        local parts = {}
        for part in loadoutString:gmatch("([^,]+)") do parts[#parts + 1] = part end

        if #parts >= 3 then
            local id = tonumber(parts[1])
            if id then
                if selectedId and id == selectedId then
                    exact = parts
                    break
                elseif id == 0 and not fallback then
                    fallback = parts
                end
            end
        end
    end

    return exact or fallback
end

local function ReadNodes(chosen)
    local defs = NS.Core.GetNodeDefs()
    local nodes, dropped = {}, 0

    for i = 4, #chosen do
        local nodeId, rank = chosen[i]:match("(%d+):(%d+)")
        nodeId, rank = tonumber(nodeId), tonumber(rank)
        if nodeId and rank and rank > 0 then
            if defs and not defs[nodeId] then
                dropped = dropped + 1
            else
                nodes[nodeId] = rank
            end
        end
    end

    if dropped > 0 then NS.LogWarn(string.format(L.MSG_UNKNOWN_NODES, dropped)) end
    return nodes
end

local function ForgetIdentity()
    loadoutId, loadoutName = nil, nil
    serverNodes = {}
end

local function ParseLoadouts(body)
    if type(body) ~= "string" or body == "" then return end

    local globalPart, loadoutsPart = body:match("([^_]+)_?(.*)")
    if not globalPart then return end

    local spendable, committed = globalPart:match("^%d+,(%d+),(%d+)")
    if spendable then StoreBalance(spendable, committed) end

    local selectedId = tonumber(globalPart:match("^(%d+),"))

    if not loadoutsPart or loadoutsPart == "" then
        ForgetIdentity()
        return
    end

    local chosen = PickLoadout(loadoutsPart, selectedId)
    if not chosen then
        ForgetIdentity()
        NS.LogWarn(L.MSG_NO_LOADOUT_MATCH)
        return
    end

    local id, name = tonumber(chosen[1]), chosen[2]

    if not id or type(name) ~= "string" or name == "" or name:find("|", 1, true) then
        ForgetIdentity()
        NS.LogWarn(string.format(L.MSG_BAD_LOADOUT_IDENTITY, tostring(chosen[2])))
        return
    end

    loadoutId, loadoutName = id, name
    serverNodes = ReadNodes(chosen)
end

local function PurgeStaleChunks(now)
    for mid, rec in pairs(inflight) do
        if now - rec.started > CHUNK_TIMEOUT then inflight[mid] = nil end
    end
end

local function CollectChunk(mid, idx, tot, slice)
    local total, i = tonumber(tot, 16), tonumber(idx, 16)

    if not (total and i) or total < 1 or total > MAX_CHUNKS or i < 1 or i > total then
        NS.LogWarn(string.format(L.MSG_BAD_CHUNK, tostring(idx), tostring(tot)))
        return nil
    end

    local now = GetTime()
    PurgeStaleChunks(now)

    local rec = inflight[mid]
    if not rec or rec.total ~= total then
        rec = { total = total, got = 0, parts = {}, started = now }
        inflight[mid] = rec
    end

    if not rec.parts[i] then
        rec.parts[i] = slice
        rec.got = rec.got + 1
    end

    if rec.got < rec.total then return nil end
    inflight[mid] = nil

    for k = 1, rec.total do
        if rec.parts[k] == nil then
            NS.LogWarn(L.MSG_INCOMPLETE_MESSAGE)
            return nil
        end
    end

    return table.concat(rec.parts, "", 1, rec.total)
end

local function OnAddonMessage(prefix, payload, dist, sender)
    if prefix ~= ADDON_PREFIX or type(payload) ~= "string" then return end
    if not IsOwnClient(dist, sender) then return end

    local evtStr, rest = payload:match("^(%d+)\t(.*)$")
    if not evtStr then return end

    local evt = tonumber(evtStr)

    if opBalance and evt == opBalance then
        local spendable, committed = rest:match("(%d+),(%d+)")
        if spendable then StoreBalance(spendable, committed) end
        return
    end

    if evt ~= opLoadouts then return end

    local mid, idx, tot, slice =
        rest:match("^@(%x%x%x%x)\t(%x%x%x)/(%x%x%x)\t(.*)$")

    if not mid then
        ParseLoadouts(rest)
        return
    end

    local body = CollectChunk(mid, idx, tot, slice)
    if body then ParseLoadouts(body) end
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

local function TickLoadoutRequest(self, elapsed)
    if serverNodes then
        self:Hide()
        return
    end

    self.due = self.due - elapsed
    if self.due > 0 then return end

    if self.left <= 0 then
        self:Hide()
        return
    end

    self.left = self.left - 1
    self.due = LOADOUT_RETRY

    local request = ProjectEbonhold and ProjectEbonhold.RequestLoadoutFromServer
    if request then pcall(request) end
end

local function StartLoadoutRequest()
    if not (ProjectEbonhold and ProjectEbonhold.RequestLoadoutFromServer) then return end

    local driver = CreateFrame("Frame")
    driver.due, driver.left = LOADOUT_FIRST_TRY, LOADOUT_MAX_TRIES
    driver:SetScript("OnUpdate", TickLoadoutRequest)
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

function Bridge.Init()
    if installed then return end

    if not (ProjectEbonhold and ProjectEbonhold.sendToServer and ProjectEbonhold.CS) then
        NS.LogError(L.MSG_NO_SENDTOSERVER)
        return
    end

    local SS = ProjectEbonhold.SS
    opLoadouts = SS and SS.SEND_LOADOUTS
    opBalance = SS and SS.SEND_PLAYER_UPDATED_COMMITTED_SOUL_POINTS
    if not opLoadouts then
        NS.LogError(L.MSG_NO_OPCODE)
        return
    end

    local listener = CreateFrame("Frame")
    listener:RegisterEvent("CHAT_MSG_ADDON")
    listener:SetScript("OnEvent", function(_, _, prefix, payload, dist, sender)
        local ok, err = pcall(OnAddonMessage, prefix, payload, dist, sender)
        if not ok then NS.LogError(string.format(L.MSG_BRIDGE_ERROR, tostring(err))) end
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

    local onApplyResult = ProjectEbonhold.SkillTree
        and ProjectEbonhold.SkillTree.OnApplyChangesResult
    if onApplyResult and ProjectEbonhold.RequestLoadoutFromServer then
        ProjectEbonhold.SkillTree.OnApplyChangesResult = function(spellId, success)
            onApplyResult(spellId, success)
            if success then ProjectEbonhold.RequestLoadoutFromServer() end
        end
    end

    StartLoadoutRequest()

    installed = true
end

Bridge.__test = {
    Tick = TickLoadoutRequest,
    Start = StartLoadoutRequest,
    Delays = function() return LOADOUT_FIRST_TRY, LOADOUT_RETRY, LOADOUT_MAX_TRIES end,
    SetServerNodes = function(nodes) serverNodes = nodes end,
}
