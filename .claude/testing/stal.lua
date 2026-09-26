local MOCK = _G.MOCK
local passed, failed = 0, 0

local function check(name, ok, detail)
  if ok then passed = passed + 1; print("  PASS  " .. name)
  else failed = failed + 1; print("  FAIL  " .. name .. (detail and ("  -> " .. tostring(detail)) or "")) end
end
local function eq(name, got, want) check(name .. " (" .. tostring(got) .. ")", got == want, "wanted " .. tostring(want)) end

local NS = SkillTreeAutoLoad
NS.UI = { RefreshUpdateNotice = function() end }
local RELEASE = not MOCK.version:find("-", 1, true)
local ONE = RELEASE and 1 or 0
print("version under test: " .. MOCK.version .. (RELEASE and " (release)" or " (work build)"))

local function said()
  local out = {}
  for _, line in ipairs(MOCK.chat) do
    local body = line.text:match("^EA1:E:V:%d+%.%d+/%d+:(.*)$")
    if body then out[#out + 1] = body end
  end
  return out
end

local function saidStal()
  local out = {}
  for _, body in ipairs(said()) do
    local v = body:match("S=([^,]+)")
    if v then out[#out + 1] = v end
  end
  return out
end

local function printed(text)
  local n = 0
  for _, m in ipairs(MOCK.printed) do if m:find(text, 1, true) then n = n + 1 end end
  return n
end

print("\nboot: EbonAPI announces the versions once the common channel is joined")
EbonAPIDB = nil
SkillTreeAutoLoadAccountDB = nil
MOCK.fire("ADDON_LOADED", "EbonAPI")
MOCK.fire("PLAYER_LOGIN")
NS.Data.Init()
NS.Update.Init()

check("STAL registered with EbonAPI", NS.api ~= nil)
eq("its letter is S", NS.api:ChannelLetter(), "S")
eq("the common channel is joined", EbonAPI.Channel.isJoined(), true)
MOCK.tick(20)
eq("one version line went out", #said(), 1)
eq("it carries our version, never for a work build", #saidStal(), ONE)
eq("with the installed version", saidStal()[1], RELEASE and MOCK.version or nil)
check("EbonAPI's own version rides along", said()[1] and said()[1]:find("E=" .. EbonAPI.version, 1, true) ~= nil, said()[1])
eq("nothing was said in French about an update", printed("disponible"), 0)
MOCK.tick(30)
eq("no old channel was joined", MOCK.channels.stalversion, nil)
eq("the common one is kept", EbonAPI.Channel.isJoined(), true)
eq("the addon keeps no update state of its own", SkillTreeAutoLoadAccountDB.update, nil)

print("\nhearing a newer version")
MOCK.chat = {}
MOCK.channel("EA1:E:V:1.1/1:S=2.0.0", "Nova")
eq("the newer version is known", (NS.Update.GetAvailable()), "2.0.0")
eq("the player is told once, with the link", printed(NS.Update.URL), 1)
eq("it is kept by EbonAPI", EbonAPIDB.addons.EbonAPI.account.versions.SkillTreeAutoLoad, "2.0.0")
MOCK.channel("EA1:E:V:2.1/1:S=2.0.0", "Nova")
eq("hearing it again says nothing more", printed(NS.Update.URL), 1)
MOCK.channel("EA1:E:V:3.1/1:S=1.9.5", "Olde")
eq("an older newer version does not replace it", (NS.Update.GetAvailable()), "2.0.0")
MOCK.channel("EA1:E:V:4.1/1:S=2.1.0", "Fresh")
eq("a newer one does", (NS.Update.GetAvailable()), "2.1.0")
MOCK.tick(20)
eq("none of it made us speak", #said(), 0)

print("\nhearing an older version: one reply, after a random delay, with a cooldown")
MOCK.tick(400)
MOCK.chat = {}
MOCK.channel("EA1:E:V:5.1/1:S=1.8.0", "Olda")
MOCK.tick(10)
eq("nothing yet", #said(), 0)
MOCK.tick(90)
eq("then our version goes out once, never from a work build", #saidStal(), ONE)
eq("it is ours", saidStal()[1], RELEASE and MOCK.version or nil)

MOCK.chat = {}
MOCK.channel("EA1:E:V:6.1/1:S=1.8.0", "Olda")
MOCK.tick(150)
eq("a second old version within thirty seconds waits", #said(), 0)
MOCK.tick(200)
eq("and is answered after the cooldown, once", #saidStal(), ONE)

MOCK.chat = {}
MOCK.channel("EA1:E:V:7.1/1:S=1.8.0", "Olda")
MOCK.channel("EA1:E:V:8.1/1:S=1.9.0,E=" .. EbonAPI.version, "Peer")
MOCK.tick(400)
eq("a peer answering first cancels our reply", #said(), 0)

print("\nwhat comes off the channel is never trusted")
MOCK.chat = {}
local before = NS.Update.GetAvailable()
for _, junk in ipairs({ "abc", "", "S=9.9", "S=" .. string.rep("9", 30), "S=9.9.9-2", "S=1.9.0-3" }) do
  MOCK.channel("EA1:E:V:9.1/1:" .. junk, "Stranger")
end
MOCK.channel("EA1:E:W:9.1/1:S=2.5.0", "Stranger")
MOCK.channel("EA1:S:V:9.1/1:S=2.5.0", "Stranger")
MOCK.channel("STAL1:V:2.5.0", "Stranger", "stalversion")
eq("none of it counted", (NS.Update.GetAvailable()), before)
MOCK.tick(400)
eq("and none of it made us speak", #said(), 0)
eq("no test table is shipped", NS.Update.__test, nil)

print("\nActivate at login: only what ProjectEbonhold defines at load is checked")
local skillTree = ProjectEbonhold.SkillTree
utils = nil
eq("without utils, Activate is announced unavailable", NS.Core.CanActivate(), false)
utils = { EncodeVarInt = function() return {} end, Base64Encode = function() return "" end }
eq("without the balance setter either", NS.Core.CanActivate(), false)
skillTree.UpdateTotalSoulPoints = function() end
_G.skillTreeImportButton = nil
StaticPopupDialogs["SKILLTREE_IMPORT_CODE"] = nil
eq("the import button and its popup do not exist yet at login, and that is not a failure", NS.Core.CanActivate(), true)
utils = nil
skillTree.UpdateTotalSoulPoints = nil

print("\nbridge: the loadout comes from EbonAPI, the payload hook stays here")
local sentPE, requested = {}, 0
ProjectEbonhold.CS.REQUEST_LOADOUT_UPDATE = 77
ProjectEbonhold.sendToServer = function(id, body) sentPE[#sentPE + 1] = id .. "|" .. body end
ProjectEbonhold.RequestLoadoutFromServer = function() requested = requested + 1 end
ProjectEbonhold.SkillTree = { OnApplyChangesResult = function() end }
NS.Core = { GetNodeDefs = function() return { [101] = {}, [102] = {} } end }
NS.Bridge.Init()
eq("no identity before the server speaks", NS.Bridge.HasLoadoutIdentity(), false)
eq("no nodes either", NS.Bridge.GetServerNodes(), nil)
MOCK.tick(10)
eq("nothing asked during the first second", requested, 0)
MOCK.tick(15)
eq("the loadout is asked after two seconds", requested, 1)
MOCK.tick(60)
eq("then every five seconds", requested, 2)
MOCK.server(3, "7,1600,400_7,Mon build,0,101:2,102:1,999:3")
eq("the identity is known", NS.Bridge.HasLoadoutIdentity(), true)
local nodes = NS.Bridge.GetServerNodes()
eq("known nodes are kept", nodes[101], 2)
eq("unknown nodes are dropped", nodes[999], nil)
eq("and said once", printed(string.format(NS.L.MSG_UNKNOWN_NODES, 1)), 1)
local spendable, committed = NS.Bridge.GetServerBalance()
eq("the balance rides along", spendable, 1600)
eq("committed too", committed, 400)
MOCK.tick(100)
eq("the request stops once the loadout is known", requested, 2)
ProjectEbonhold.sendToServer(77, "0||101:2")
eq("an Apply Changes payload is completed with the server's nodes", sentPE[#sentPE], "77|7|Mon build|101:2,102:1")
ProjectEbonhold.sendToServer(77, "0||101:2,102:1")
eq("nothing is added twice", sentPE[#sentPE], "77|7|Mon build|101:2,102:1")
ProjectEbonhold.sendToServer(12, "0||x")
eq("other opcodes pass untouched", sentPE[#sentPE], "12|0||x")
ProjectEbonhold.SkillTree.OnApplyChangesResult(1, true)
eq("a confirmed apply asks the loadout again", requested, 3)
MOCK.server(15, "1700,500")
eq("the balance follows opcode 15 as well", (NS.Bridge.GetServerBalance()), 1700)
MOCK.server(15, "1368305,4926218920")
eq("a committed balance of several billions reaches STAL", select(2, NS.Bridge.GetServerBalance()), 4926218920)
MOCK.server(3, "5,100,20_")
eq("an empty loadout list forgets the identity", NS.Bridge.HasLoadoutIdentity(), false)
eq("but nodes are an empty table, not unknown", next(NS.Bridge.GetServerNodes()), nil)
MOCK.server(3, "5,100,20_9,Autre,0,1:1")
eq("a list without a match says so", printed(NS.L.MSG_NO_LOADOUT_MATCH), 1)
eq("no test table is shipped either", NS.Bridge.__test, nil)

print(string.format("\n%d passed, %d failed", passed, failed))
return failed
