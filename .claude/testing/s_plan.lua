local NS = SkillTreeAutoLoad
T.boot({ enterWorld = false })
local Plan = NS.Plan

local function show(set)
  local keys = {}
  for id in pairs(set or {}) do keys[#keys + 1] = id end
  table.sort(keys)
  local parts = {}
  for _, id in ipairs(keys) do parts[#parts + 1] = id .. "=" .. tostring(set[id]) end
  return table.concat(parts, ",")
end

T.section("plan: what is missing, what is owned")
local missing, count = Plan.ComputeMissing({ [1] = 1, [2] = 3, [3] = 1 }, { [1] = 1, [2] = 1 })
T.eq("the missing nodes and their target ranks", show(missing), "2=3,3=1")
T.eq("their count", count, 2)
local owned, total, ownedNodes, totalNodes = Plan.ComputeProgress({ [1] = 1, [2] = 3, [999] = 1 }, { [1] = 1, [2] = 1 })
T.eq("owned cost", owned, 10 + 20)
T.eq("total cost", total, 10 + 20 + 30 + 40)
T.eq("finished nodes", ownedNodes, 1)
T.eq("nodes of the save the tree knows", totalNodes, 2)

T.section("plan: progressive mode opens a node once its parents are full, cheapest first")
local target = { [1] = 1, [2] = 3, [3] = 2, [4] = 1 }
local chosen, spent, picked, blocked = Plan.ComputeProgressive(target, {}, 45)
T.eq("with 45 ashes: the root, then the cheaper branch, then the other", show(chosen), "1=1,2=1,3=1")
T.eq("45 spent", spent, 45)
T.eq("three nodes touched", picked, 3)
T.eq("the next rank would cost 25", blocked, 25)
local again = Plan.ComputeProgressive(target, {}, 45)
T.eq("the same question gives the same answer", show(again), "1=1,2=1,3=1")

chosen, spent, picked, blocked = Plan.ComputeProgressive(target, {}, 1000)
T.eq("with enough ashes, the whole save", show(chosen), "1=1,2=3,3=2,4=1")
T.eq("for its full cost", spent, 10 + 20 + 30 + 40 + 15 + 25 + 100)
T.eq("nothing blocks", blocked, nil)
T.eq("four nodes", picked, 4)

chosen, spent = Plan.ComputeProgressive({ [2] = 3, [3] = 2, [4] = 1 }, { [1] = 1, [2] = 3 }, 1000)
T.eq("what the tree already has is not bought again", show(chosen), "3=2,4=1")
T.eq("only the rest is paid", spent, 15 + 25 + 100)

chosen, spent = Plan.ComputeProgressive({ [1] = 5 }, {}, 1000)
T.eq("a target above the node's ranks stops at its last rank", show(chosen), "1=1")

chosen, spent, picked, blocked = Plan.ComputeProgressive({ [6] = 1 }, {}, 1000)
T.eq("a node with no way in is never picked", picked, 0)
T.eq("and blocks nothing", blocked, nil)

chosen, spent, picked, blocked = Plan.ComputeProgressive({ [1] = 1 }, {}, 0)
T.eq("with no ashes nothing is picked", picked, 0)
T.eq("and the first rank's cost is what blocks", blocked, 10)

T.section("plan: largest connected group, for framing a scattered save")
local group = Plan.LargestGroup({ [1] = 1, [2] = 1, [5] = 1 })
T.eq("the two linked nodes win over the lone one", show(group), "1=1,2=1")
