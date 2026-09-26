local NS = SkillTreeAutoLoad
local L = NS.L
local Core

T.boot()
MOCK.tick(15)
Core = NS.Core
T.openTree()

T.section("activate before the server spoke: the balance is unknown")
PE.setRanks({ [1] = 1 })
PE.setAshes(1000)
local cost, err = Core.ApplyBuild({ [1] = 1, [2] = 1 })
T.eq("nothing is applied", cost, nil)
T.eq("the reason is the unknown balance", err, L.ERR_READ_BALANCE)
T.eq("and the tree was not touched", PE.imports, 0)

T.section("reading the tree")
PE.setRanks({ [1] = 1, [2] = 2 })
Core.InvalidateSnapshot()
local snap = Core.GetTreeSnapshot()
T.eq("a finished node", snap[1], 1)
T.eq("a node in progress", snap[2], 2)
T.eq("an empty node is absent", snap[3], nil)
local stamp = Core.GetSnapshotStamp()
Core.InvalidateSnapshot()
T.eq("an unchanged tree gives back the same table", Core.GetTreeSnapshot() == snap, true)
T.eq("and the same stamp", Core.GetSnapshotStamp(), stamp)
PE.setRanks({ [1] = 1, [2] = 3 })
T.eq("within the short cache, the old reading is kept", Core.GetTreeSnapshot()[2], 2)
MOCK.tick(3)
T.eq("after it, the tree is read again", Core.GetTreeSnapshot()[2], 3)
T.eq("a change moves the stamp", Core.GetSnapshotStamp(), stamp + 1)

PE.ranks[2000] = 42
PE.display(2000)
Core.InvalidateSnapshot()
T.eq("an infinite node is read from its badge", Core.GetTreeSnapshot()[2000], 42)
T.eq("but never captured into a save", Core.CaptureTreeState()[2000], nil)
T.eq("a capture keeps the rest", Core.CaptureTreeState()[2], 3)

local btn3 = skillTreeNode3
local function readAs(text, state)
  btn3.rankText:SetText(text)
  btn3.state = state or "available"
  Core.InvalidateSnapshot()
  return Core.GetTreeSnapshot()[3] or 0
end
T.eq("'1/2' reads 1", readAs("1/2"), 1)
T.eq("'12/20' reads 12", readAs("12/20"), 12)
T.eq("trailing text is not a rank", readAs("2/2x"), 0)
T.eq("an empty text on an active node reads its full rank", readAs("", "active"), 2)
T.eq("a locked node reads 0 whatever it shows", readAs("1/2", "locked"), 0)
PE.display(3)

T.section("reading the balance shown by the tree")
PE.setAshes(1234567)
T.eq("thousands separators", Core.GetAvailableSoulAshes(), 1234567)
PE.setAshes(4926218920)
T.eq("billions", Core.GetAvailableSoulAshes(), 4926218920)
skillTreeFrame.pointsText:SetText("Soul Ashes: -5")
T.eq("a negative balance", Core.GetAvailableSoulAshes(), -5)
skillTreeFrame.pointsText:SetText("")
T.eq("no text, no balance", Core.GetAvailableSoulAshes(), nil)

T.section("cost of a save")
local total, pending = Core.ComputeActivationPlan({ [1] = 1, [2] = 3, [3] = 1, [999] = 4 }, { [1] = 1 })
T.eq("the ranks still missing are paid", total, 20 + 30 + 40 + 15)
T.eq("nodes still missing", pending, 2)
local function infiniteCost(rank)
  return math.min(100000000, math.max(1, math.ceil(1000 * 1.15 ^ (rank - 1) - 0.000001)))
end
total = Core.ComputeActivationPlan({ [2000] = 44 }, { [2000] = 42 })
T.eq("an infinite node grows by 15 % per rank", total, infiniteCost(43) + infiniteCost(44))
total = Core.ComputeActivationPlan({ [2000] = 201 }, { [2000] = 200 })
T.eq("and caps at 100 million per rank", total, 100000000)

T.section("activate: the import is fed the union of server, tree and save")
T.readyTree({ [1] = 1 }, 1000, 10, { [1] = 1, [5] = 2 })
PE.setRanks({ [1] = 1 })
cost, err = Core.ApplyBuild({ [1] = 1, [2] = 3, [3] = 2 })
T.eq("the save is applied", err, nil)
T.eq("its cost is what was missing", cost, 20 + 30 + 40 + 15 + 25)
T.eq("through the tree's own import", PE.imports, 1)
T.eq("the save's nodes are in the tree", PE.ranks[2], 3)
T.eq("the server's node is kept even though neither the tree nor the save showed it", PE.ranks[5], 2)
local set = PE.balanceSets[#PE.balanceSets]
T.eq("the balance shown is recomputed from the server's", set and set[1], 1000 - (20 + 30 + 40 + 15 + 25))
T.eq("committed ashes are passed through", set and set[2], 10)
T.eq("the tree shows it", Core.GetAvailableSoulAshes(), 1000 - 130)

T.section("activate: what can go wrong")
PE.setRanks({ [1] = 1, [5] = 2 })
PE.setAshes(1000)
PE.refuseImport = true
cost, err = Core.ApplyBuild({ [1] = 1, [3] = 1 })
T.eq("an import the tree refuses is reported", err, L.ERR_MISMATCH)
PE.refuseImport = nil
PE.setAshes(3)
cost, err = Core.ApplyBuild({ [1] = 1, [2] = 3, [3] = 2 })
T.eq("more ranks than ashes is refused before importing, server nodes counted",
  err, string.format(L.ERR_IMPORT_REFUSED, 1 + 2 + 3 + 2, "3"))
PE.setAshes(1000)
local keptUtils = utils
utils = nil
cost, err = Core.ApplyBuild({ [1] = 1, [3] = 1 })
T.eq("no encoder, no import", err, L.ERR_ENCODE)
utils = keptUtils
local keptButton = _G.skillTreeImportButton
skillTreeImportButton = nil
cost, err = Core.ApplyBuild({ [1] = 1, [3] = 1 })
T.eq("no import button, a clear reason", err, L.ERR_NO_IMPORT_BUTTON)
skillTreeImportButton = keptButton

PE.loadout(7, 5, 10, { [1] = 1 })
PE.setRanks({ [1] = 1 })
cost, err = Core.ApplyBuild({ [1] = 1, [3] = 1 })
T.eq("a server balance too small for the tree still applies", err, nil)
T.eq("the balance is set to zero rather than below", PE.balanceSets[#PE.balanceSets][1], 0)
T.eq("and the player is told", T.printed(string.format(L.MSG_NEGATIVE_BALANCE, "5", "15")), 1)
T.eq("nothing reloads the interface", MOCK.reloads, 0)
