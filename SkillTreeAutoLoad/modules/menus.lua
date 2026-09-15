local NS = SkillTreeAutoLoad
local L = NS.L
local COLOR = NS.COLOR
local Colorize = NS.Colorize

local Menus = {}
NS.Menus = Menus

-- Un nom se lit dans une liste : on retire les bords, les codes couleur colles
-- depuis un chat et les caracteres de controle, puis on refuse ce qui n'en laisse
-- rien. Sans ce filtre, une saisie faite d'espaces cree une ligne invisible que
-- le joueur ne peut plus ni retrouver ni renommer.
local function CleanName(raw)
    if type(raw) ~= "string" then return nil end

    local name = raw:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    name = name:gsub("[%c|]", " "):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return nil end

    return name
end

local function CountNodes(nodeRanks)
    local count = 0
    for _ in pairs(nodeRanks or {}) do count = count + 1 end
    return count
end

StaticPopupDialogs["STAL_INPUT_TEXT"] = {
    text = "%s",
    button1 = L.POPUP_OK,
    button2 = L.POPUP_CANCEL,
    hasEditBox = true,
    maxLetters = 40,
    OnShow = function(self)
        local data = self.data
        self.editBox:SetText((data and data.default) or "")
        self.editBox:HighlightText()
    end,
    OnAccept = function(self)
        local data = self.data
        if data and data.onAccept then data.onAccept(self.editBox:GetText()) end
        self:Hide()
    end,
    EditBoxOnEnterPressed = function(self)
        local dialog = self:GetParent()
        if dialog.data and dialog.data.onAccept then
            dialog.data.onAccept(self:GetText())
        end
        dialog:Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["STAL_CONFIRM"] = {
    text = "%s",
    button1 = L.POPUP_YES,
    button2 = L.POPUP_NO,
    OnAccept = function(self)
        local data = self.data
        if data and data.onAccept then data.onAccept() end
        self:Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

function Menus.PromptText(prompt, default, onAccept)
    StaticPopup_Show("STAL_INPUT_TEXT", prompt, nil,
        { default = default, onAccept = onAccept })
end

function Menus.Confirm(text, onAccept)
    StaticPopup_Show("STAL_CONFIRM", text, nil, { onAccept = onAccept })
end

local dropdown = CreateFrame("Frame", "STAL_ActionMenu", UIParent, "UIDropDownMenuTemplate")

local function AddButton(level, text, func, hasArrow, menuList)
    local info = UIDropDownMenu_CreateInfo()
    info.text = text
    info.notCheckable = true
    info.func = func
    info.hasArrow = hasArrow
    info.menuList = menuList
    UIDropDownMenu_AddButton(info, level)
end

local function AddToggle(level, text, checked, func)
    local info = UIDropDownMenu_CreateInfo()
    info.text = text
    info.checked = checked
    info.func = func
    UIDropDownMenu_AddButton(info, level)
end

local function OpenMenu(anchor)
    ToggleDropDownMenu(1, nil, dropdown, anchor, 0, 0)

    local list = _G["DropDownList1"]
    if not (list and list:IsShown()) then return end

    -- La liste s'ouvre loin de l'arbre, sauf en mode compact : le panneau est alors
    -- dans la fenetre, et c'est vers l'interieur, par-dessus le panneau, qu'elle
    -- reste dans la fenetre.
    list:ClearAllPoints()
    if NS.Data.IsCompact() or NS.Data.GetPanelSide() == "LEFT" then
        list:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, 0)
    else
        list:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 0)
    end
end

function Menus.ShowPanelMenu(anchor)
    UIDropDownMenu_Initialize(dropdown, function(_, level)
        level = level or 1

        AddButton(level, L.MENU_NEW_SAVE, function()
            Menus.PromptText(L.PROMPT_NEW_SAVE, nil, function(raw)
                local name = CleanName(raw)
                if not name then
                    NS.LogWarn(L.MSG_INVALID_NAME)
                    return
                end

                local nodeRanks, err = NS.Core.CaptureTreeState()
                if not nodeRanks then
                    NS.LogError(string.format(L.MSG_CAPTURE_FAILED, tostring(err)))
                    return
                end

                NS.Data.CreateSave(name, nil, nodeRanks)
                NS.Data.Persist()
            end)
        end)

        AddButton(level, L.MENU_NEW_GROUP, function()
            Menus.PromptText(L.PROMPT_NEW_GROUP, nil, function(raw)
                local name = CleanName(raw)
                if not name then
                    NS.LogWarn(L.MSG_INVALID_NAME)
                    return
                end
                NS.Data.CreateGroup(name)
                NS.Data.Persist()
            end)
        end)

        AddToggle(level, L.MENU_COMPACT, NS.Data.IsCompact(), function()
            NS.UI.SetCompact(not NS.Data.IsCompact())
        end)

        AddToggle(level, L.MENU_PREVIEW_CAMERA, NS.Data.IsPreviewCamera(), function()
            NS.Data.SetPreviewCamera(not NS.Data.IsPreviewCamera())
        end)
    end, "MENU")

    OpenMenu(anchor)
end

function Menus.ShowSaveMenu(saveId, anchor)
    if not NS.Data.GetSave(saveId) then return end

    UIDropDownMenu_Initialize(dropdown, function(_, level, menuList)
        level = level or 1

        if level == 1 then
            AddButton(level, L.MENU_RENAME, function()
                local save = NS.Data.GetSave(saveId)
                Menus.PromptText(L.PROMPT_RENAME, save and save.name, function(raw)
                    local newName = CleanName(raw)
                    if not newName then
                        NS.LogWarn(L.MSG_INVALID_NAME)
                        return
                    end
                    if NS.Data.RenameSave(saveId, newName) then NS.Data.Persist() end
                end)
            end)

            AddButton(level, L.MENU_MOVE, nil, true, "MOVE")

            AddButton(level, L.MENU_UPDATE, function()
                local save = NS.Data.GetSave(saveId)
                if not save then return end

                local nodeRanks, err = NS.Core.CaptureTreeState()
                if not nodeRanks then
                    NS.LogError(string.format(L.MSG_UPDATE_FAILED, tostring(err)))
                    return
                end

                local function apply()
                    if NS.Data.UpdateSaveContent(saveId, nodeRanks) then
                        NS.Data.Persist()
                    end
                end

                -- Une save ne retrecit pas par accident. Le ReloadUI qui suit
                -- grave le resultat sur le disque : si la capture contient moins
                -- que ce qu'elle remplace, c'est au joueur de le confirmer.
                local newCount = CountNodes(nodeRanks)
                local oldCount = CountNodes(save.nodeRanks)
                if newCount < oldCount then
                    NS.LogWarn(string.format(L.MSG_UPDATE_SHRINKS, newCount, oldCount))
                    Menus.Confirm(string.format(L.CONFIRM_SHRINK_SAVE,
                        save.name, newCount, oldCount), apply)
                else
                    apply()
                end
            end)

            AddButton(level, Colorize(COLOR.ERROR, L.MENU_DELETE), function()
                local save = NS.Data.GetSave(saveId)
                Menus.Confirm(string.format(L.CONFIRM_DELETE_SAVE, save and save.name or saveId), function()
                    if NS.Data.DeleteSave(saveId) then NS.Data.Persist() end
                end)
            end)

        elseif level == 2 and menuList == "MOVE" then
            local function moveTo(groupId)
                return function()
                    CloseDropDownMenus()
                    if NS.Data.MoveSaveToGroup(saveId, groupId) then
                        NS.Data.Persist()
                    end
                end
            end

            AddButton(level, L.UNGROUPED, moveTo(nil))
            for _, groupId in ipairs(NS.Data.GetSortedGroupIds()) do
                AddButton(level, NS.Data.GetGroup(groupId).name, moveTo(groupId))
            end
        end
    end, "MENU")

    OpenMenu(anchor)
end

function Menus.ShowGroupMenu(groupId, anchor)
    if not NS.Data.GetGroup(groupId) then return end

    UIDropDownMenu_Initialize(dropdown, function(_, level)
        level = level or 1

        AddButton(level, L.MENU_RENAME_GROUP, function()
            local group = NS.Data.GetGroup(groupId)
            Menus.PromptText(L.PROMPT_RENAME_GROUP, group and group.name, function(raw)
                local newName = CleanName(raw)
                if not newName then
                    NS.LogWarn(L.MSG_INVALID_NAME)
                    return
                end
                if NS.Data.RenameGroup(groupId, newName) then NS.Data.Persist() end
            end)
        end)

        AddButton(level, Colorize(COLOR.ERROR, L.MENU_DELETE_GROUP), function()
            local group = NS.Data.GetGroup(groupId)
            Menus.Confirm(string.format(L.CONFIRM_DELETE_GROUP,
                group and group.name or groupId, L.UNGROUPED), function()
                if NS.Data.DeleteGroup(groupId) then NS.Data.Persist() end
            end)
        end)
    end, "MENU")

    OpenMenu(anchor)
end
