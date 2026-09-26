local NS = SkillTreeAutoLoad
local RELEASE = not MOCK.version:find("-", 1, true)
local ONE = RELEASE and 1 or 0

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

T.section("versions: EbonAPI announces them once the common channel is joined (" .. MOCK.version .. ")")
T.boot({ enterWorld = false })
T.eq("STAL's channel letter is S", NS.api:ChannelLetter(), "S")
T.eq("the common channel is joined", EbonAPI.Channel.isJoined(), true)
MOCK.tick(20)
T.eq("one version line went out", #said(), 1)
T.eq("it carries our version, never for a work build", #saidStal(), ONE)
T.eq("with the installed version", saidStal()[1], RELEASE and MOCK.version or nil)
T.check("EbonAPI's own version rides along", said()[1] and said()[1]:find("E=" .. EbonAPI.version, 1, true) ~= nil, said()[1])
MOCK.tick(30)
T.eq("no old channel was joined", MOCK.channels.stalversion, nil)
T.eq("the addon keeps no update state of its own", SkillTreeAutoLoadAccountDB.update, nil)

T.section("versions: hearing a newer one")
MOCK.chat = {}
MOCK.channel("EA1:E:V:1.1/1:S=2.0.0", "Nova")
T.eq("the newer version is known", (NS.Update.GetAvailable()), "2.0.0")
T.eq("the player is told once, with the link", T.printed(NS.Update.URL), 1)
MOCK.channel("EA1:E:V:2.1/1:S=2.0.0", "Nova")
T.eq("hearing it again says nothing more", T.printed(NS.Update.URL), 1)
MOCK.channel("EA1:E:V:3.1/1:S=1.9.5", "Olde")
T.eq("an older newer version does not replace it", (NS.Update.GetAvailable()), "2.0.0")
MOCK.channel("EA1:E:V:4.1/1:S=2.1.0", "Fresh")
T.eq("a newer one does", (NS.Update.GetAvailable()), "2.1.0")
MOCK.tick(20)
T.eq("none of it made us speak", #said(), 0)

T.section("versions: hearing an older one gets one reply, late and rate-limited")
MOCK.tick(400)
MOCK.chat = {}
MOCK.channel("EA1:E:V:5.1/1:S=1.8.0", "Olda")
MOCK.tick(10)
T.eq("nothing yet", #said(), 0)
MOCK.tick(90)
T.eq("then our version goes out once, never from a work build", #saidStal(), ONE)
T.eq("it is ours", saidStal()[1], RELEASE and MOCK.version or nil)

MOCK.chat = {}
MOCK.channel("EA1:E:V:6.1/1:S=1.8.0", "Olda")
MOCK.tick(150)
T.eq("a second old version within thirty seconds waits", #said(), 0)
MOCK.tick(200)
T.eq("and is answered after the cooldown, once", #saidStal(), ONE)

MOCK.chat = {}
MOCK.channel("EA1:E:V:7.1/1:S=1.8.0", "Olda")
MOCK.channel("EA1:E:V:8.1/1:S=1.9.0,E=" .. EbonAPI.version, "Peer")
MOCK.tick(400)
T.eq("a peer answering first cancels our reply", #said(), 0)

T.section("versions: what comes off the channel is never trusted blindly")
MOCK.chat = {}
local before = NS.Update.GetAvailable()
for _, junk in ipairs({ "abc", "", "S=9.9", "S=" .. string.rep("9", 30), "S=9.9.9-2", "S=1.9.0-3" }) do
  MOCK.channel("EA1:E:V:9.1/1:" .. junk, "Stranger")
end
MOCK.channel("EA1:E:W:9.1/1:S=2.5.0", "Stranger")
MOCK.channel("EA1:S:V:9.1/1:S=2.5.0", "Stranger")
MOCK.channel("STAL1:V:2.5.0", "Stranger", "stalversion")
T.eq("none of it counted", (NS.Update.GetAvailable()), before)
MOCK.tick(400)
T.eq("and none of it made us speak", #said(), 0)
T.eq("no test table is shipped", NS.Update.__test, nil)
