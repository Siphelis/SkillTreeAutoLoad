local T = { passed = 0, failed = 0, verbose = false }
_G.T = T

function T.section(name)
  if T.verbose then print("\n" .. name) end
  T.current = name
end

function T.check(name, ok, detail)
  if ok then
    T.passed = T.passed + 1
    if T.verbose then print("  PASS  " .. name) end
  else
    T.failed = T.failed + 1
    print("  FAIL  [" .. tostring(T.current) .. "] " .. name .. (detail ~= nil and ("  -> " .. tostring(detail)) or ""))
  end
  return ok
end

function T.eq(name, got, want)
  return T.check(name .. " (" .. tostring(got) .. ")", got == want, "wanted " .. tostring(want))
end

function T.printed(fragment)
  local n = 0
  for _, line in ipairs(MOCK.printed) do
    if string.find(line, fragment, 1, true) then n = n + 1 end
  end
  return n
end

function T.plain(text)
  if type(text) ~= "string" then return text end
  return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

local W = getmetatable(UIParent).__index
W.SetGradientAlpha = function() end
W.SetBlendMode = function() end
W.IsVisible = function(self)
  local w = self
  while w do
    if not w._shown then return false end
    w = w._parent
  end
  return true
end

MOCK.setTexts = 0
local rawSetText = W.SetText
W.SetText = function(self, v)
  MOCK.setTexts = MOCK.setTexts + 1
  return rawSetText(self, v)
end

MOCK.reloads = 0
ReloadUI = function() MOCK.reloads = MOCK.reloads + 1 end
UpdateUIPanelPositions = function() end

MOCK.popups = {}
StaticPopup_Show = function(which, a, b, data)
  local entry = { which = which, a = a, b = b, data = data }
  MOCK.popups[#MOCK.popups + 1] = entry
  return entry
end
StaticPopup_FindVisible = function() return nil end

function T.lastPopup(which)
  for i = #MOCK.popups, 1, -1 do
    if not which or MOCK.popups[i].which == which then return MOCK.popups[i] end
  end
end

function T.acceptPopup(entry, text)
  local dialog = StaticPopupDialogs[entry.which]
  dialog.OnAccept({ data = entry.data, Hide = function() end,
    editBox = { GetText = function() return text end } })
end

MOCK.menuButtons = {}
UIDropDownMenu_Initialize = function(_, fn) MOCK.menuInit = fn end
UIDropDownMenu_AddButton = function(info) MOCK.menuButtons[#MOCK.menuButtons + 1] = info end

function T.menu(level, menuList)
  MOCK.menuButtons = {}
  MOCK.menuInit(nil, level, menuList)
  local out = {}
  for i, info in ipairs(MOCK.menuButtons) do out[i] = info end
  return out
end

function T.menuPick(level, text, menuList)
  for _, info in ipairs(T.menu(level, menuList)) do
    if T.plain(info.text) == text then
      if info.func then info.func() end
      return info
    end
  end
end

MOCK.tooltip = {}
GameTooltip.SetText = function(self, text)
  MOCK.tooltip = { text }
  self._text = text
end
GameTooltip.AddLine = function(_, text) MOCK.tooltip[#MOCK.tooltip + 1] = text end

local function FormatThousands(n)
  local s = string.format("%.0f", math.floor(tonumber(n) or 0))
  while true do
    local replaced
    s, replaced = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
    if replaced == 0 then break end
  end
  return s
end

local NODES = {
  { id = 1, x = 100, y = 100, spells = { 101 }, soulPointsCosts = { 10 }, isStart = true },
  { id = 2, x = 200, y = 60, spells = { 201, 202, 203 }, soulPointsCosts = { 20, 30, 40 } },
  { id = 3, x = 200, y = 140, spells = { 301, 302 }, soulPointsCosts = { 15, 25 } },
  { id = 4, x = 300, y = 100, spells = { 401 }, soulPointsCosts = { 100 } },
  { id = 5, x = 2600, y = 1800, spells = { 501, 502 }, soulPointsCosts = { 5, 5 }, isStart = true },
  { id = 6, x = 0, y = 0, spells = { 601 }, soulPointsCosts = { 7 }, noButton = true },
  { id = 2000, x = 500, y = 500, spells = { 9001 }, soulPointsCosts = { 1000 },
    infinite = true, infiniteGrowth = 1.15, isStart = true, permanent = true },
}

local byId = {}
for _, node in ipairs(NODES) do byId[node.id] = node end

TalentDatabase = { [0] = { nodes = NODES, links = { { 1, 2 }, { 1, 3 }, { 2, 4 }, { 3, 4 } } } }

local PE = { ranks = {}, builds = 0, requests = 0, refreshes = 0, imports = 0, sent = {}, balanceSets = {} }
_G.PE = PE
PE.nodes = byId

CollectionsJournal = CreateFrame("Frame", "CollectionsJournal", UIParent)
CollectionsJournal:SetAttribute("UIPanelLayout-defined", true)
CollectionsJournal:SetAttribute("UIPanelLayout-xoffset", 15)
CollectionsJournal._shown = false

skillTreeFrame = CreateFrame("Frame", "skillTreeFrame", CollectionsJournal)
skillTreeFrame:SetSize(1100, 600)
skillTreeFrame.pointsText = skillTreeFrame:CreateFontString(nil, "OVERLAY")

skillTreeScroll = CreateFrame("ScrollFrame", "skillTreeScroll", skillTreeFrame)
skillTreeScroll:SetPoint("TOPLEFT", skillTreeFrame, "TOPLEFT", 10, -15)
skillTreeScroll:SetPoint("BOTTOMRIGHT", skillTreeFrame, "BOTTOMRIGHT", -10, 50)
skillTreeScroll:SetSize(1080, 535)
skillTreeScroll._rect = { 10, 1090, 585, 50 }

skillTreeCanvas = CreateFrame("Frame", "skillTreeCanvas", skillTreeScroll)
skillTreeCanvas:SetSize(3000, 2000)
skillTreeScroll:SetScrollChild(skillTreeCanvas)

function skillTreeScroll:GetHorizontalScrollRange()
  return math.max(0, skillTreeCanvas:GetWidth() * skillTreeCanvas:GetScale() - self:GetWidth())
end

function skillTreeScroll:GetVerticalScrollRange()
  return math.max(0, skillTreeCanvas:GetHeight() * skillTreeCanvas:GetScale() - self:GetHeight())
end

PE.nativeWheel = 0
skillTreeScroll:SetScript("OnMouseWheel", function() PE.nativeWheel = PE.nativeWheel + 1 end)

function PE.setAshes(n)
  skillTreeFrame.pointsText:SetText("|cffFFD700Soul Ashes: |r|cffFFFFFF" .. FormatThousands(n) .. "|r")
end

function PE.display(nodeId)
  local btn = _G["skillTreeNode" .. nodeId]
  if not btn then return end
  local node = byId[nodeId]
  local rank = PE.ranks[nodeId] or 0
  if node.infinite then
    btn.rankText:SetText("")
    btn.stackBadge.count:SetText(tostring(rank))
    if rank > 0 then btn.stackBadge:Show() else btn.stackBadge:Hide() end
    btn.state = "available"
  else
    btn.rankText:SetText(rank .. "/" .. #node.spells)
    btn.state = (rank >= #node.spells) and "active" or "available"
  end
end

function PE.displayAll()
  for _, node in ipairs(NODES) do PE.display(node.id) end
end

function PE.setRanks(ranks)
  PE.ranks = {}
  for id, rank in pairs(ranks) do PE.ranks[id] = rank end
  PE.displayAll()
end

local function Decode(code)
  local values = {}
  for v in string.gmatch(code, "[^,]+") do values[#values + 1] = tonumber(v) end
  local ranks = {}
  for i = 1, values[1] or 0 do ranks[values[2 * i]] = values[2 * i + 1] end
  return ranks
end

local function CreateButtons()
  for _, node in ipairs(NODES) do
    if not node.noButton then
      local btn = CreateFrame("Button", "skillTreeNode" .. node.id, skillTreeCanvas)
      btn:SetSize(36, 36)
      btn:SetPoint("TOPLEFT", skillTreeCanvas, "TOPLEFT", node.x, -node.y)
      btn.icon = btn:CreateTexture(nil, "ARTWORK")
      btn.rankText = btn:CreateFontString(nil, "OVERLAY")
      if node.infinite then
        btn.stackBadge = CreateFrame("Frame", nil, btn)
        btn.stackBadge.count = btn.stackBadge:CreateFontString(nil, "OVERLAY")
      end
    end
  end

  local importBtn = CreateFrame("Button", "skillTreeImportButton", skillTreeFrame, "UIPanelButtonTemplate")
  importBtn:Hide()
  importBtn:SetScript("OnClick", function()
    StaticPopupDialogs["SKILLTREE_IMPORT_CODE"] = {
      OnAccept = function(self)
        PE.imports = PE.imports + 1
        PE.lastCode = self.editBox:GetText()
        if PE.refuseImport then return end
        PE.setRanks(Decode(PE.lastCode))
        refreshAccessibility()
      end,
    }
    StaticPopup_Show("SKILLTREE_IMPORT_CODE")
  end)
end

local function InitTree()
  if PE.built then return end
  PE.built = true
  PE.builds = PE.builds + 1
  ProjectEbonhold.RequestLoadoutFromServer()
  CreateButtons()
  PE.displayAll()
end

function refreshAccessibility()
  PE.refreshes = PE.refreshes + 1
end

skillTreeFrame:SetScript("OnShow", function()
  InitTree()
  refreshAccessibility()
end)

utils = {
  EncodeVarInt = function(v) return { v } end,
  Base64Encode = function(buffer) return table.concat(buffer, ",") end,
}

ProjectEbonhold = {
  CS = { REQUEST_LOADOUT_UPDATE = 28, REQUEST_LOADOUTS = 5 },
  SS = { SEND_LOADOUTS = 3 },
  sendToServer = function(id, body) PE.sent[#PE.sent + 1] = { id = id, body = body } end,
  RequestLoadoutFromServer = function() PE.requests = PE.requests + 1 end,
  SkillTree = {
    OnApplyChangesResult = function() end,
    UpdateTotalSoulPoints = function(spendable, committed)
      PE.balanceSets[#PE.balanceSets + 1] = { spendable, committed }
      PE.setAshes(spendable)
    end,
  },
  FormatThousands = FormatThousands,
}

function PE.loadout(selected, spendable, committed, nodes, name)
  local parts = {}
  for id, rank in pairs(nodes or {}) do parts[#parts + 1] = id .. ":" .. rank end
  table.sort(parts)
  local body = selected .. "," .. spendable .. "," .. committed .. ",6_" .. selected .. ","
    .. (name or "Default") .. "," .. spendable
  if #parts > 0 then body = body .. "," .. table.concat(parts, ",") end
  MOCK.server(3, body)
end

function T.boot(opts)
  opts = opts or {}
  MOCK.fire("ADDON_LOADED", "EbonAPI")
  MOCK.fire("ADDON_LOADED", "SkillTreeAutoLoad")
  MOCK.fire("PLAYER_LOGIN")
  if opts.enterWorld ~= false then MOCK.fire("PLAYER_ENTERING_WORLD") end
end

function T.openTree()
  CollectionsJournal:Show()
end

function T.closeTree()
  CollectionsJournal:Hide()
  local onHide = skillTreeFrame:GetScript("OnHide")
  if onHide then onHide(skillTreeFrame) end
end

function T.readyTree(ranks, spendable, committed, serverNodes)
  T.openTree()
  PE.setRanks(ranks or {})
  PE.setAshes(spendable or 0)
  PE.loadout(7, spendable or 0, committed or 0, serverNodes or ranks or {})
  refreshAccessibility()
  MOCK.tick(2)
end

function PE.changed()
  refreshAccessibility()
  MOCK.tick(1)
end

function T.saveIds()
  local ids = {}
  for id in pairs(SkillTreeAutoLoadAccountDB.saves) do ids[#ids + 1] = id end
  table.sort(ids)
  return ids
end

function T.saveNamed(name)
  for id, save in pairs(SkillTreeAutoLoadAccountDB.saves) do
    if save.name == name then return id, save end
  end
end
