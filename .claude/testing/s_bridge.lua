local NS = SkillTreeAutoLoad
local L = NS.L

T.section("bridge: the loadout comes from EbonAPI, the payload hook stays in STAL")
T.boot({ enterWorld = false })
local asked = PE.requests
T.eq("no identity before the server speaks", NS.Bridge.HasLoadoutIdentity(), false)
T.eq("no nodes either", NS.Bridge.GetServerNodes(), nil)
MOCK.tick(10)
T.eq("nothing asked during the first second", PE.requests - asked, 0)
MOCK.tick(15)
T.eq("the loadout is asked after two seconds", PE.requests - asked, 1)
MOCK.tick(60)
T.eq("then every five seconds", PE.requests - asked, 2)

PE.loadout(7, 1600, 400, { [1] = 1, [2] = 2, [999] = 3 }, "Mon build")
T.eq("the identity is known", NS.Bridge.HasLoadoutIdentity(), true)
local nodes = NS.Bridge.GetServerNodes()
T.eq("known nodes are kept", nodes[2], 2)
T.eq("unknown nodes are dropped", nodes[999], nil)
T.eq("and said once", T.printed(string.format(L.MSG_UNKNOWN_NODES, 1)), 1)
local spendable, committed = NS.Bridge.GetServerBalance()
T.eq("the balance rides along", spendable, 1600)
T.eq("committed too", committed, 400)
MOCK.tick(100)
T.eq("the request stops once the loadout is known", PE.requests - asked, 2)

T.section("bridge: Apply Changes is completed with what the server already holds")
ProjectEbonhold.sendToServer(28, "0||1:1")
T.eq("the server's nodes are added, never removed", PE.sent[#PE.sent].body, "7|Mon build|1:1,2:2")
ProjectEbonhold.sendToServer(28, "0||1:1,2:2")
T.eq("nothing is added twice", PE.sent[#PE.sent].body, "7|Mon build|1:1,2:2")
ProjectEbonhold.sendToServer(12, "0||x")
T.eq("other opcodes pass untouched", PE.sent[#PE.sent].body, "0||x")
ProjectEbonhold.SkillTree.OnApplyChangesResult(1, true)
T.eq("a confirmed apply asks the loadout again", PE.requests - asked, 3)
ProjectEbonhold.SkillTree.OnApplyChangesResult(1, false)
T.eq("a refused one does not", PE.requests - asked, 3)

T.section("bridge: balance")
MOCK.server(15, "1700,500")
T.eq("the balance follows opcode 15 as well", (NS.Bridge.GetServerBalance()), 1700)
MOCK.server(15, "1368305,4926218920")
T.eq("a committed balance of several billions reaches STAL", select(2, NS.Bridge.GetServerBalance()), 4926218920)
MOCK.fire("CHAT_MSG_ADDON", "AAM0x9", "15\t1,1", "GUILD", "Intrus")
T.eq("another player cannot change it", select(2, NS.Bridge.GetServerBalance()), 4926218920)

T.section("bridge: loadout lists")
MOCK.server(3, "5,100,20,6_")
T.eq("an empty loadout list forgets the identity", NS.Bridge.HasLoadoutIdentity(), false)
T.eq("but nodes are an empty table, not unknown", next(NS.Bridge.GetServerNodes()), nil)
MOCK.server(3, "5,100,20,6_9,Autre,0,1:1")
T.eq("a list without a match says so", T.printed(L.MSG_NO_LOADOUT_MATCH), 1)
MOCK.server(3, "5,100,20,6_0,Defaut,0,1:1")
T.eq("the loadout 0 stands in when nothing matches exactly", NS.Bridge.HasLoadoutIdentity(), true)
T.eq("no test table is shipped", NS.Bridge.__test, nil)

T.section("Activate at login: only what ProjectEbonhold defines at load is checked")
local skillTree = ProjectEbonhold.SkillTree
local keptUtils, keptSetter = utils, skillTree.UpdateTotalSoulPoints
utils = nil
T.eq("without utils, Activate is announced unavailable", NS.Core.CanActivate(), false)
utils = keptUtils
skillTree.UpdateTotalSoulPoints = nil
T.eq("without the balance setter either", NS.Core.CanActivate(), false)
skillTree.UpdateTotalSoulPoints = keptSetter
T.eq("at login the import button does not exist yet", _G.skillTreeImportButton, nil)
T.eq("nor its popup", StaticPopupDialogs.SKILLTREE_IMPORT_CODE, nil)
T.eq("and that is not a failure", NS.Core.CanActivate(), true)
