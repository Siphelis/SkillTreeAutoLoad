local NS = SkillTreeAutoLoad
local Data

local function dump(value)
  if type(value) ~= "table" then return tostring(value) end
  local keys = {}
  for k in pairs(value) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
  local parts = {}
  for _, k in ipairs(keys) do parts[#parts + 1] = tostring(k) .. "=" .. dump(value[k]) end
  return "{" .. table.concat(parts, ",") .. "}"
end

SkillTreeAutoLoadAccountDB = {
  saves = {
    idA = { name = "Alpha", nodeRanks = { [1] = 1, [2] = 40, [3] = 0, [4] = 1.5, x = 2 }, progressive = false },
    idBad = { nodeRanks = {} },
    idB = { name = "Beta", groupId = "g1", nodeRanks = { [1] = 1 }, progressive = true },
  },
  groups = { g1 = { name = "Groupe" }, gBad = { order = 1 } },
  nextId = 10,
}
SkillTreeAutoLoadDB = {
  groups = { old1 = { name = "Groupe", order = 1 }, old2 = { name = "Ancien", order = 2 } },
  saves = {
    s1 = { name = "Beta", groupId = "old1", nodeRanks = { [1] = 1 } },
    s2 = { name = "Alpha", nodeRanks = { [5] = 2 } },
    s3 = { name = "Gamma", groupId = "old2", nodeRanks = { [2] = 1 } },
  },
  settings = { panelSide = "LEFT" },
}
local legacyBefore = dump(SkillTreeAutoLoadDB)

T.section("data: saves read from disk are repaired")
T.boot({ enterWorld = false })
Data = NS.Data
local db = SkillTreeAutoLoadAccountDB
T.eq("a save without a name is dropped", db.saves.idBad, nil)
T.eq("a group without a name is dropped", db.groups.gBad, nil)
T.eq("a group without an order gets one", db.groups.g1.order, 0)
T.eq("a rank above the cap is capped", db.saves.idA.nodeRanks[2], 32)
T.eq("a zero rank is removed", db.saves.idA.nodeRanks[3], nil)
T.eq("a fractional rank is removed", db.saves.idA.nodeRanks[4], nil)
T.eq("a key that is not a node id is removed", db.saves.idA.nodeRanks.x, nil)
T.eq("the repair is said once, with its count", T.printed(string.format(NS.L.MSG_RANKS_FIXED, 4)), 1)
T.eq("progressive false is stored as absent", db.saves.idA.progressive, nil)
T.eq("progressive true is kept", db.saves.idB.progressive, true)

T.section("data: the character's old saves move to the account, once")
T.eq("the character is marked as imported", db.imported["Tester-Ebonhold"], true)
local _, twin = T.saveNamed("Alpha (Tester)")
T.check("a same-named save with other ranks is kept under a new name", twin ~= nil)
T.eq("with its ranks", twin and twin.nodeRanks[5], 2)
local gammaId, gamma = T.saveNamed("Gamma")
T.check("a new save is imported", gamma ~= nil)
T.eq("into a group created from the old one", gamma and Data.GetGroup(gamma.groupId).name, "Ancien")
local betas = 0
for _, save in pairs(db.saves) do if save.name == "Beta" then betas = betas + 1 end end
T.eq("an identical save is merged, not duplicated", betas, 1)
T.eq("the group with the same name is reused", Data.GetSortedGroupIds()[1], "g1")
T.eq("the result is said", T.printed("Tester"), 1)
T.eq("the side of the panel is adopted from the character", Data.GetPanelSide(), "LEFT")
T.eq("the old base is only read, never written", dump(SkillTreeAutoLoadDB), legacyBefore)
local count = #T.saveIds()
Data.Init()
T.eq("starting again imports nothing more", #T.saveIds(), count)

T.section("data: groups and saves")
local zeta = Data.CreateGroup("Zeta")
local groups = Data.GetSortedGroupIds()
T.eq("a new group goes last", groups[#groups], zeta)
local unnamed = Data.CreateSave(nil, nil, nil)
T.eq("a save without a name gets the default one", Data.GetSave(unnamed).name, NS.L.DEFAULT_SAVE_NAME)
T.eq("and empty ranks", next(Data.GetSave(unnamed).nodeRanks), nil)
local ungrouped = Data.GetSortedSaveIdsInGroup(nil)
local names = {}
for i, id in ipairs(ungrouped) do names[i] = Data.GetSave(id).name end
T.eq("ungrouped saves are sorted by name", table.concat(names, "|"), "Alpha|Alpha (Tester)|" .. NS.L.DEFAULT_SAVE_NAME)
T.eq("renaming re-sorts", Data.RenameSave(unnamed, "Aaa") and Data.GetSave(Data.GetSortedSaveIdsInGroup(nil)[1]).name, "Aaa")
T.eq("moving a save to a group", Data.MoveSaveToGroup(unnamed, zeta) and Data.GetSortedSaveIdsInGroup(zeta)[1], unnamed)
T.eq("renaming a group", Data.RenameGroup(zeta, "Zeta 2") and Data.GetGroup(zeta).name, "Zeta 2")
T.eq("deleting a group", Data.DeleteGroup(zeta), true)
T.eq("sends its saves back to no group", Data.GetSave(unnamed).groupId, nil)
T.eq("updating a save's content", Data.UpdateSaveContent(unnamed, { [1] = 1 }) and Data.GetSave(unnamed).nodeRanks[1], 1)
T.eq("progressive on", Data.SetSaveProgressive(unnamed, true) and Data.GetSave(unnamed).progressive, true)
T.eq("progressive off", Data.SetSaveProgressive(unnamed, false) and Data.GetSave(unnamed).progressive, nil)
T.eq("deleting a save", Data.DeleteSave(unnamed) and Data.GetSave(unnamed), nil)
T.eq("an unknown save cannot be renamed", Data.RenameSave("nope", "x"), false)
T.eq("an unknown group cannot be deleted", Data.DeleteGroup("nope"), false)
T.check("the gamma save is untouched by all this", Data.GetSave(gammaId) ~= nil)

T.section("data: settings")
Data.SetPanelSide("anything")
T.eq("an unknown side means right", Data.GetPanelSide(), "RIGHT")
Data.SetCompact(true)
T.eq("compact mode", Data.IsCompact(), true)
Data.SetPanelCollapsed(true)
T.eq("collapsed panel", Data.IsPanelCollapsed(), true)
Data.SetPreviewCamera(false)
T.eq("the preview camera can be turned off", Data.IsPreviewCamera(), false)
Data.SetPreviewCamera(true)
T.eq("and on again", Data.IsPreviewCamera(), true)
T.eq("nothing reloads the interface", MOCK.reloads, 0)
