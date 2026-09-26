local NS = SkillTreeAutoLoad
local L = NS.L
local expected = ({ esMX = "esES" })[MOCK.locale] or MOCK.locale

local function head(fmt)
  return (fmt:match("^(.-)%%") or fmt)
end

T.section("boot: EbonAPI then STAL, in the client's order")
T.boot()
T.check("STAL registered with EbonAPI", NS.api ~= nil)
T.eq("the shared language follows the client", EbonAPI:GetLanguage(), expected)
T.eq("no startup step failed", T.printed(head(L.MSG_INIT_FAILED)), 0)
T.eq("EbonAPI was accepted", T.printed(L.MSG_NO_EBONAPI), 0)
T.eq("ProjectEbonhold was found", T.printed(L.MSG_NO_PROJECTEBONHOLD), 0)
T.eq("the server bridge is hooked", T.printed(L.MSG_NO_SENDTOSERVER), 0)
T.eq("no false 'Activate unavailable' at login", T.printed(L.MSG_ACTIVATE_UNAVAILABLE), 0)
T.eq("nothing reloads the interface", MOCK.reloads, 0)

T.section("prewarm: the tree is built behind the loading screen, once, without opening anything")
T.eq("not built at login", PE.builds, 0)
MOCK.tick(15)
T.eq("built once after the delay", PE.builds, 1)
T.eq("the journal stays closed", CollectionsJournal:IsShown(), false)
T.eq("the panel is not built by the prewarm", _G.STAL_Panel, nil)
T.check("the loadout was asked", PE.requests >= 1, PE.requests)

T.section("opening and closing the tree")
T.openTree()
T.eq("opening does not build the tree a second time", PE.builds, 1)
T.check("the panel appears beside the tree", _G.STAL_Panel and STAL_Panel:IsShown())
T.closeTree()
T.eq("closing the tree hides the panel", STAL_Panel:IsShown(), false)
MOCK.fire("PLAYER_ENTERING_WORLD")
MOCK.tick(15)
T.eq("a zone change does not prewarm again", PE.builds, 1)

T.section("locales: four tables, same keys, same placeholders")
local register = EbonAPI.Locale.register
local savedL = NS.L
local tables = {}
EbonAPI.Locale.register = function(_, t)
  for code, entries in pairs(t) do tables[code] = entries end
  return {}
end
for _, code in ipairs({ "enUS", "frFR", "deDE", "esES" }) do
  assert(loadfile(STAL_SRC .. "locales/" .. code .. ".lua"))("SkillTreeAutoLoad")
end
EbonAPI.Locale.register = register
NS.L = savedL

local function specs(text)
  local out = {}
  for spec in text:gmatch("%%[-+ #0-9.]*[%a%%]") do
    if spec ~= "%%" then out[#out + 1] = spec end
  end
  return table.concat(out, " ")
end

local base = tables.enUS
for _, code in ipairs({ "frFR", "deDE", "esES" }) do
  local other = tables[code]
  local missing, extra, mismatched = {}, {}, {}
  for key, text in pairs(base) do
    if other[key] == nil then
      missing[#missing + 1] = key
    elseif specs(other[key]) ~= specs(text) then
      mismatched[#mismatched + 1] = key
    end
  end
  for key in pairs(other) do
    if base[key] == nil then extra[#extra + 1] = key end
  end
  T.eq(code .. " translates every key", table.concat(missing, ","), "")
  T.eq(code .. " has no key the base lacks", table.concat(extra, ","), "")
  T.eq(code .. " keeps every placeholder", table.concat(mismatched, ","), "")
end
T.eq("the texts in use are the client's language", L.BTN_ACTIVATE, tables[expected].BTN_ACTIVATE)
