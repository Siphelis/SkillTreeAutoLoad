local ADDON_NAME = ...
local NS = SkillTreeAutoLoad

-- Un demarrage qui leve ne doit pas emporter les etapes suivantes ni se resumer
-- a une erreur Lua anonyme : on nomme l'etape fautive et on continue.
local function Step(name, fn)
    local ok, err = pcall(fn)
    if not ok then
        NS.LogError(string.format(NS.L.MSG_INIT_FAILED, name, tostring(err)))
    end
    return ok
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name == ADDON_NAME then Step("Data", NS.Data.Init) end
        return
    end

    Step("Data", NS.Data.Init)
    -- Avant le controle d'Ebonhold : une version plus recente est peut-etre justement
    -- celle qui le retrouve.
    Step("Update", NS.Update.Init)
    if not _G.skillTreeFrame then
        NS.LogError(NS.L.MSG_NO_PROJECTEBONHOLD)
        return
    end
    Step("Bridge", NS.Bridge.Init)
    Step("UI", NS.UI.Init)
end)
