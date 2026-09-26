local NS = SkillTreeAutoLoad
local L = NS.L
local Menus, Data = NS.Menus, NS.Data

T.boot()
MOCK.tick(15)
T.readyTree({ [1] = 1, [2] = 1 }, 100, 0, { [1] = 1 })

local function rowNames()
  local out = {}
  for i = 1, 10 do
    local btn = _G["STAL_Row" .. i .. "ActivateBtn"]
    if btn and btn:GetParent():IsShown() then out[#out + 1] = btn:GetParent().nameText:GetText() end
  end
  return table.concat(out, "|")
end

T.section("menus: the popups speak the player's language")
T.eq("OK", StaticPopupDialogs.STAL_INPUT_TEXT.button1, L.POPUP_OK)
T.eq("Cancel", StaticPopupDialogs.STAL_INPUT_TEXT.button2, L.POPUP_CANCEL)
T.eq("Yes", StaticPopupDialogs.STAL_CONFIRM.button1, L.POPUP_YES)
T.eq("No", StaticPopupDialogs.STAL_CONFIRM.button2, L.POPUP_NO)
T.eq("the update popup", StaticPopupDialogs.STAL_UPDATE_LINK.text, L.POPUP_UPDATE)

T.section("menus: panel menu")
Menus.ShowPanelMenu(STAL_PanelMenuBtn)
local items = T.menu(1)
T.eq("four entries", #items, 4)
T.eq("new save first", items[1].text, L.MENU_NEW_SAVE)
T.menuPick(1, L.MENU_NEW_SAVE)
T.eq("a name is asked", T.lastPopup().a, L.PROMPT_NEW_SAVE)
T.acceptPopup(T.lastPopup(), "  |cffff0000Mon|r build|x  ")
local id, save = T.saveNamed("Mon build x")
T.check("colours and bars are cleaned from the name", save ~= nil)
T.eq("the tree as it is now is saved", save and save.nodeRanks[2], 1)
T.eq("the list shows it at once", rowNames(), "Mon build x")

local before = #T.saveIds()
T.menuPick(1, L.MENU_NEW_SAVE)
T.acceptPopup(T.lastPopup(), " |cffffffff|r ")
T.eq("an empty name is refused", #T.saveIds(), before)
T.eq("and said", T.printed(L.MSG_INVALID_NAME), 1)

T.menuPick(1, L.MENU_NEW_GROUP)
T.acceptPopup(T.lastPopup(), "Mes builds")
local groupId = Data.GetSortedGroupIds()[1]
T.eq("a group is created", groupId and Data.GetGroup(groupId).name, "Mes builds")

T.menuPick(1, L.MENU_COMPACT)
T.eq("compact mode from the menu", Data.IsCompact(), true)
Menus.ShowPanelMenu(STAL_PanelMenuBtn)
T.eq("the toggle shows its state", T.menu(1)[3].checked, true)
T.menuPick(1, L.MENU_COMPACT)
T.eq("and back", Data.IsCompact(), false)
T.menuPick(1, L.MENU_PREVIEW_CAMERA)
T.eq("the preview camera from the menu", Data.IsPreviewCamera(), false)
T.menuPick(1, L.MENU_PREVIEW_CAMERA)

T.section("menus: save menu")
Menus.ShowSaveMenu(id, STAL_Row1MenuBtn)
T.menuPick(1, L.MENU_RENAME)
T.eq("renaming offers the current name", T.lastPopup().data.default, "Mon build x")
T.acceptPopup(T.lastPopup(), "Renomme")
T.eq("renamed", Data.GetSave(id).name, "Renomme")

local moves = T.menu(2, "MOVE")
T.eq("the move submenu starts with no group", moves[1].text, L.UNGROUPED)
T.menuPick(2, "Mes builds", "MOVE")
T.eq("moved into the group", Data.GetSave(id).groupId, groupId)

PE.setRanks({ [1] = 1, [2] = 2, [3] = 1 })
T.menuPick(1, L.MENU_UPDATE)
T.eq("updating takes the tree as it is now", Data.GetSave(id).nodeRanks[3], 1)
PE.setRanks({ [1] = 1 })
T.menuPick(1, L.MENU_UPDATE)
T.eq("a smaller tree is not taken without asking", Data.GetSave(id).nodeRanks[3], 1)
T.eq("the player is warned", T.printed(string.format(L.MSG_UPDATE_SHRINKS, 1, 3)), 1)
T.eq("and asked to confirm", T.lastPopup().a, string.format(L.CONFIRM_SHRINK_SAVE, "Renomme", 1, 3))
T.acceptPopup(T.lastPopup())
T.eq("confirmed, the save shrinks", Data.GetSave(id).nodeRanks[3], nil)

T.section("menus: group menu")
Menus.ShowGroupMenu(groupId, STAL_Row1MenuBtn)
T.menuPick(1, L.MENU_RENAME_GROUP)
T.eq("renaming a group offers its name", T.lastPopup().data.default, "Mes builds")
T.acceptPopup(T.lastPopup(), "Builds")
T.eq("group renamed", Data.GetGroup(groupId).name, "Builds")
T.menuPick(1, L.MENU_DELETE_GROUP)
T.eq("deleting asks first, naming where the saves go",
  T.lastPopup().a, string.format(L.CONFIRM_DELETE_GROUP, "Builds", L.UNGROUPED))
T.acceptPopup(T.lastPopup())
T.eq("the group is gone", Data.GetGroup(groupId), nil)
T.eq("its save is kept, without a group", Data.GetSave(id).groupId, nil)

Menus.ShowSaveMenu(id, STAL_Row1MenuBtn)
T.menuPick(1, L.MENU_DELETE)
T.eq("deleting a save asks first", T.lastPopup().a, string.format(L.CONFIRM_DELETE_SAVE, "Renomme"))
T.acceptPopup(T.lastPopup())
T.eq("then deletes it", Data.GetSave(id), nil)
T.eq("and the list follows", rowNames(), "")

local popups = #MOCK.popups
Menus.ShowUpdateLink()
T.eq("no newer version, no update popup", #MOCK.popups, popups)
T.eq("nothing in all this reloads the interface", MOCK.reloads, 0)
