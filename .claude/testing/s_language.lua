local NS = SkillTreeAutoLoad
local L = NS.L

SkillTreeAutoLoadAccountDB = {
  saves = { id1 = { name = "Build", nodeRanks = { [1] = 1, [2] = 1 } } },
  groups = {},
  nextId = 5,
}

T.boot()
MOCK.tick(15)
T.readyTree({ [1] = 1 }, 100, 0, { [1] = 1 })
MOCK.channel("EA1:E:V:1.1/1:S=9.9.9", "Nova")

local row = STAL_Row1ActivateBtn:GetParent()

local function emptyText()
  for _, region in ipairs(STAL_PanelScroll._regions) do
    if region._template == "GameFontDisableSmall" then return region:GetText() end
  end
end

local function header()
  for _, child in ipairs(row:GetParent()._children) do
    if child.text and child.bg and not child.nameText and child:IsShown() then return child.text:GetText() end
  end
end

local function zoomLabel()
  skillTreeScroll:GetScript("OnMouseWheel")(skillTreeScroll, 1)
  MOCK.tick(1)
  return skillTreeFrame.zoomText:GetText()
end

local function expectAll(language)
  T.eq(language .. ": Activate", row.activateBtn:GetText(), L.BTN_ACTIVATE)
  T.eq(language .. ": the progressive label", row.progLabel:GetText(), L.ROW_PROGRESSIVE)
  T.eq(language .. ": the ON switch", T.plain(row.onBtn:GetText()), L.BTN_ON)
  T.eq(language .. ": the OFF switch", T.plain(row.offBtn:GetText()), L.BTN_OFF)
  T.eq(language .. ": the cost line", row.costText:GetText(), string.format(L.ROW_COST, 1, "20"))
  T.eq(language .. ": the group header", header(), L.UNGROUPED)
  T.eq(language .. ": the empty list help", emptyText(), L.EMPTY_LIST)
  T.eq(language .. ": the update button", T.plain(STAL_UpdateBtn:GetText()), L.BTN_UPDATE)
  T.eq(language .. ": popup buttons", StaticPopupDialogs.STAL_INPUT_TEXT.button2, L.POPUP_CANCEL)
  T.eq(language .. ": the confirm popup", StaticPopupDialogs.STAL_CONFIRM.button1, L.POPUP_YES)
  T.eq(language .. ": the update link text", StaticPopupDialogs.STAL_UPDATE_LINK.text, L.POPUP_UPDATE)
  local zoom = zoomLabel()
  T.eq(language .. ": the zoom level", zoom, string.format(L.LABEL_ZOOM, math.floor(skillTreeCanvas:GetScale() * 100 + 0.5)))
end

T.section("language: the client's, at start")
T.eq("French to begin with", L.BTN_ACTIVATE, "Activer")
expectAll("frFR")

T.section("language: another addon switches it, no reload")
local sameTable = L
EbonAPI:SetLanguage("enUS")
T.eq("STAL's table is refilled in place", NS.L == sameTable, true)
T.eq("now in English", L.BTN_ACTIVATE, "Activate")
expectAll("enUS")
NS.Menus.ShowPanelMenu(STAL_PanelMenuBtn)
T.eq("menus open in the new language", T.menu(1)[1].text, "New save")

NS.Data.CreateSave("Second", nil, { [1] = 1 })
NS.UI.RefreshList()
T.eq("a row created afterwards is in the new language too", STAL_Row2ActivateBtn:GetText(), "Activate")

EbonAPI:SetLanguage("deDE")
T.eq("German", L.BTN_ACTIVATE, "Aktivieren")
T.eq("existing rows follow", STAL_Row2ActivateBtn:GetText(), "Aktivieren")
expectAll("deDE")

EbonAPI:SetLanguage("frFR")
expectAll("frFR again")
T.eq("the choice is kept for every addon", EbonAPI.DB.shared().account.language, "frFR")
T.eq("nothing reloads the interface", MOCK.reloads, 0)
