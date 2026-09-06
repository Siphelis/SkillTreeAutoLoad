local ADDON_NAME = ...
local NS = SkillTreeAutoLoad

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name == ADDON_NAME then NS.Data.Init() end
        return
    end

    NS.Data.Init()
    if not _G.skillTreeFrame then
        NS.LogError(NS.L.MSG_NO_PROJECTEBONHOLD)
        return
    end
    NS.Bridge.Init()
    NS.UI.Init()
end)
