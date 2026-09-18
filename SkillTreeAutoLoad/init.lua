SkillTreeAutoLoad = SkillTreeAutoLoad or {}
local NS = SkillTreeAutoLoad

NS.SNAPSHOT_TTL = 0.2
NS.ASHES_POLL_INTERVAL = 0.5

NS.COLOR = {
    PREFIX = "|cff33ccff",
    ERROR = "|cffff4444",
    WARN = "|cffff9900",
    SUCCESS = "|cff40ff40",
    HIGHLIGHT = "|cffffd200",
    DIM = "|cff808080",
    RESET = "|r",
}

local COLOR = NS.COLOR

function NS.Colorize(color, text)
    return color .. tostring(text) .. COLOR.RESET
end

function NS.Log(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(
            NS.Colorize(COLOR.PREFIX, "[SkillTreeAutoLoad]") .. " " .. tostring(msg))
    end
end

function NS.LogError(msg)
    NS.Log(NS.Colorize(COLOR.ERROR, msg))
end

function NS.LogWarn(msg)
    NS.Log(NS.Colorize(COLOR.WARN, msg))
end

local floor = math.floor
local costText, costTextCount = {}, 0
local COST_TEXT_CAP = 4096

function NS.FormatCost(n)
    n = floor(tonumber(n) or 0)
    local s = costText[n]
    if s then return s end

    local out = tostring(n):reverse():gsub("(%d%d%d)", "%1 "):reverse()
    s = (out:gsub("^%s+", ""))

    if costTextCount >= COST_TEXT_CAP then
        for k in pairs(costText) do costText[k] = nil end
        costTextCount = 0
    end
    costText[n] = s
    costTextCount = costTextCount + 1
    return s
end
