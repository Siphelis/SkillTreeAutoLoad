local ADDON_NAME = ...
local NS = SkillTreeAutoLoad
local L = NS.L
local COLOR = NS.COLOR
local Colorize = NS.Colorize

local Update = {}
NS.Update = Update

Update.URL = "https://github.com/Siphelis/SkillTreeAutoLoad/releases/latest"

local CHANNEL = "stalversion"
local TAG = "STAL1:V:"
local START_DELAY = 10
local JOIN_RETRY = 60
local TICK = 1
local SESSION_GAP = 600
local REPLY_MIN, REPLY_MAX = 2, 8
local REPLY_COOLDOWN = 30

local ownText, own, isRelease
local newSession, started, joined
local startAt, nextJoinAt
local replyAt, lastReplyAt
local notified
local ticker, sinceTick = nil, 0

local function Parse(text)
    if type(text) ~= "string" or #text > 20 then return nil end

    local major, minor, patch, build = text:match("^(%d+)%.(%d+)%.(%d+)(.*)$")
    if not major or (build ~= "" and not build:match("^%-%d+$")) then return nil end

    return { tonumber(major), tonumber(minor), tonumber(patch) }, build == ""
end

local function Compare(a, b)
    for i = 1, 3 do
        if a[i] ~= b[i] then return (a[i] < b[i]) and -1 or 1 end
    end
    return 0
end

local function ChannelId()
    local id = GetChannelName(CHANNEL)
    return (type(id) == "number" and id > 0) and id or nil
end

local function Announce()
    local id = ChannelId()
    if not (id and isRelease) then return false end
    return (pcall(SendChatMessage, TAG .. ownText, "CHANNEL", nil, id))
end

function Update.GetAvailable()
    if not own then return nil end

    local latest = NS.Data.GetUpdateState().latest
    local parsed = Parse(latest)
    if parsed and Compare(parsed, own) > 0 then return latest, ownText end
end

local function Notify()
    local version = Update.GetAvailable()
    if not version or notified == version then return end

    notified = version
    NS.Log(Colorize(COLOR.HIGHLIGHT, string.format(L.MSG_UPDATE_AVAILABLE, version, ownText))
        .. " " .. Update.URL)
    NS.UI.RefreshUpdateNotice()
end

local function OnVersion(text, now)
    local theirs, release = Parse(text)
    if not (theirs and release) then return end

    local order = Compare(theirs, own)
    if order >= 0 then
        replyAt = nil
        lastReplyAt = now
        if order == 0 then return end

        local state = NS.Data.GetUpdateState()
        local known = Parse(state.latest)
        if not known or Compare(theirs, known) > 0 then state.latest = text end
        Notify()
    elseif isRelease and not replyAt then
        replyAt = now + REPLY_MIN + math.random() * (REPLY_MAX - REPLY_MIN)
        if lastReplyAt then replyAt = math.max(replyAt, lastReplyAt + REPLY_COOLDOWN) end
        ticker:Show()
    end
end

local function OnEvent(_, _, message, sender, _, channelString, _, _, _, _, channelName)
    local name = channelName or channelString
    if type(name) ~= "string" or not name:lower():find(CHANNEL, 1, true) then return end
    if sender == UnitName("player") or type(message) ~= "string" then return end

    local text = message:match(TAG .. "([%d%.%-]+)")
    if text then OnVersion(text, GetTime()) end
end

local function OnUpdate(self, elapsed)
    sinceTick = sinceTick + elapsed
    if sinceTick < TICK then return end
    sinceTick = 0

    local now = GetTime()
    if now < startAt then return end

    if not started then
        started = true
        if newSession then Notify() end
    end

    if not joined then
        if ChannelId() then
            joined = true
            if newSession then Announce() end
        elseif now >= (nextJoinAt or 0) then
            nextJoinAt = now + JOIN_RETRY
            pcall(JoinChannelByName, CHANNEL)
        end
    end

    if replyAt and now >= replyAt then
        replyAt = nil
        lastReplyAt = now
        Announce()
    end

    if joined and not replyAt then self:Hide() end
end

function Update.Init()
    if ticker then return end

    ownText = GetAddOnMetadata(ADDON_NAME, "Version")
    own, isRelease = Parse(ownText)
    if not own then return end

    local state = NS.Data.GetUpdateState()
    local known = Parse(state.latest)
    if not known or Compare(known, own) <= 0 then state.latest = nil end

    local stamp = time()
    newSession = type(state.sessionAt) ~= "number" or stamp - state.sessionAt >= SESSION_GAP
    if newSession then state.sessionAt = stamp else notified = Update.GetAvailable() end

    startAt = GetTime() + START_DELAY
    ticker = CreateFrame("Frame")
    ticker:RegisterEvent("CHAT_MSG_CHANNEL")
    ticker:SetScript("OnEvent", OnEvent)
    ticker:SetScript("OnUpdate", OnUpdate)
end
