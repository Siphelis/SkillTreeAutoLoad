local NS = SkillTreeAutoLoad
local L = NS.L
local number = EbonAPI.Format.number

SkillTreeAutoLoadAccountDB = {
  saves = {
    id1 = { name = "Cheap", nodeRanks = { [1] = 1, [3] = 1 } },
    id2 = { name = "Dear", groupId = "g1", nodeRanks = { [1] = 1, [2] = 3, [3] = 2, [4] = 1 } },
    id3 = { name = "Done", nodeRanks = { [1] = 1 } },
  },
  groups = { g1 = { name = "Groupe", order = 1 } },
  nextId = 5,
}

T.boot()
MOCK.tick(15)
T.readyTree({ [1] = 1 }, 100, 10, { [1] = 1 })

local function row(i)
  local btn = _G["STAL_Row" .. i .. "ActivateBtn"]
  return btn and btn:GetParent()
end

local function headers()
  local out = {}
  for _, child in ipairs(row(1):GetParent()._children) do
    if child.text and child.bg and not child.nameText and child:IsShown() then out[#out + 1] = child.text:GetText() end
  end
  return table.concat(out, "|")
end

T.section("panel: one row per save, grouped, with what it costs")
T.check("the panel is shown beside the tree", STAL_Panel:IsShown())
T.eq("groups first, then the saves with no group", headers(), "Groupe|" .. L.UNGROUPED)
T.eq("row 1 is the grouped save", row(1).nameText:GetText(), "Dear")
T.eq("then by name", row(2).nameText:GetText(), "Cheap")
T.eq("and the last", row(3).nameText:GetText(), "Done")
T.eq("a save shows the nodes it misses and their cost", row(1).costText:GetText(), string.format(L.ROW_COST, 3, number(230)))
T.eq("too dear: Activate is off", row(1).activateBtn:IsEnabled(), 0)
T.eq("affordable: Activate is on", row(2).activateBtn:IsEnabled(), 1)
T.eq("a save already in the tree says so", T.plain(row(3).costText:GetText()), L.ROW_ACTIVE)
T.eq("and cannot be activated", row(3).activateBtn:IsEnabled(), 0)
T.eq("the activate button speaks the client's language", row(1).activateBtn:GetText(), L.BTN_ACTIVATE)

T.section("panel: refreshes follow the tree, one per frame, never when hidden")
local refreshes = 0
local refresh = NS.UI.RefreshList
NS.UI.RefreshList = function(...) refreshes = refreshes + 1 return refresh(...) end
refreshAccessibility()
refreshAccessibility()
refreshAccessibility()
MOCK.tick(1)
T.eq("three tree updates in a frame, one refresh", refreshes, 1)
MOCK.setTexts = 0
refresh()
T.eq("a refresh with nothing changed writes no text", MOCK.setTexts, 0)
T.closeTree()
refreshAccessibility()
MOCK.tick(2)
T.eq("no refresh while the tree is closed", refreshes, 1)
T.openTree()
NS.UI.RefreshList = refresh

PE.setAshes(300)
PE.changed()
T.eq("more ashes switch Activate on", row(1).activateBtn:IsEnabled(), 1)
PE.setAshes(100)
PE.changed()

T.section("panel: Activate")
row(2).activateBtn:Click()
T.eq("the save goes into the tree", PE.ranks[3], 1)
T.eq("the player is told what it cost", T.printed(string.format(L.MSG_APPLIED, "Cheap", 1, number(15))), 1)
T.eq("the row turns active", T.plain(row(2).costText:GetText()), L.ROW_ACTIVE)
T.eq("the balance shown drops by the cost", NS.Core.GetAvailableSoulAshes(), 85)
row(3).activateBtn:Click()
T.eq("activating a save already in the tree says so", T.printed(string.format(L.MSG_ALREADY_ACTIVE, "Done")), 1)

T.section("panel: progressive mode")
row(1).onBtn:Click()
T.eq("the save becomes progressive", NS.Data.GetSave("id2").progressive, true)
T.eq("the row shows what can be bought now", row(1).costText:GetText(), string.format(L.ROW_NEXT_STEP, 2, number(75)))
T.eq("and Activate is on", row(1).activateBtn:IsEnabled(), 1)
row(1).activateBtn:Click()
T.eq("activating buys the affordable part", PE.ranks[2], 2)
T.eq("of both branches", PE.ranks[3], 2)
T.eq("the player is told what is left", T.printed(string.format(L.MSG_APPLIED_PARTIAL, "Dear", 2, number(75), 1)), 1)
row(1).offBtn:Click()
T.eq("progressive off again", NS.Data.GetSave("id2").progressive, nil)

T.section("panel: header buttons")
STAL_CollapseBtn:Click()
T.eq("collapse hides the list", STAL_PanelScroll:IsShown(), false)
T.eq("the button offers to expand", STAL_CollapseBtn:GetText(), L.BTN_EXPAND)
STAL_CollapseBtn:Click()
T.eq("expand shows it again", STAL_PanelScroll:IsShown(), true)
STAL_SideBtn:Click()
T.eq("the side button moves the panel left", NS.Data.GetPanelSide(), "LEFT")
T.eq("and the journal moves right to make room", CollectionsJournal:GetAttribute("UIPanelLayout-xoffset"), 15 + 275 + 6)
STAL_SideBtn:Click()
T.eq("back to the right", CollectionsJournal:GetAttribute("UIPanelLayout-xoffset"), 15)
NS.UI.SetCompact(true)
T.eq("compact mode puts the panel inside the tree", STAL_Panel:GetParent(), skillTreeFrame)
NS.UI.SetCompact(false)
T.eq("and back outside", STAL_Panel:GetParent(), UIParent)

T.section("panel: update notice")
T.eq("no newer version, no button", STAL_UpdateBtn:IsShown(), false)
MOCK.channel("EA1:E:V:1.1/1:S=9.9.9", "Nova")
T.eq("a newer version heard on the channel shows the button", STAL_UpdateBtn:IsShown(), true)
STAL_UpdateBtn:Click()
T.eq("which opens the link popup", T.lastPopup() and T.lastPopup().which, "STAL_UPDATE_LINK")
T.eq("with the version", T.lastPopup().a, "9.9.9")

T.section("panel: tooltip")
row(1):GetScript("OnEnter")(row(1))
T.eq("the tooltip names the save", MOCK.tooltip[1], "Dear")
local found = false
for _, line in ipairs(MOCK.tooltip) do
  if line == L.TOOLTIP_MODE_STRICT then found = true end
end
T.check("and says which mode it is in", found)
row(1):GetScript("OnLeave")(row(1))

T.section("panel: empty list")
for _, id in ipairs(T.saveIds()) do NS.Data.DeleteSave(id) end
NS.UI.RefreshList()
T.eq("an empty group still shows its header", headers(), "Groupe")
NS.Data.DeleteGroup("g1")
NS.UI.RefreshList()
local empty
for _, region in ipairs(STAL_PanelScroll._regions) do
  if region:GetText() == L.EMPTY_LIST then empty = region end
end
T.check("with no save the panel explains what to do", empty and empty:IsShown())
T.eq("rows are hidden", row(1):IsShown(), false)
T.eq("nothing reloads the interface", MOCK.reloads, 0)
