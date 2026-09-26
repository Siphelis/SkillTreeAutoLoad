local NS = SkillTreeAutoLoad
T.boot()
MOCK.tick(15)
T.openTree()
local Overlay = NS.Overlay

local MARK = "Interface\\Buttons\\UI-ActionButton-Border"

local function container()
  for _, child in ipairs(skillTreeCanvas._children) do
    local region = child._regions and child._regions[1]
    if region and region._texture == MARK then return child end
  end
end

local function markOf(nodeId)
  local node = PE.nodes[nodeId]
  local box = container()
  for _, mark in ipairs(box and box._regions or {}) do
    local _, _, _, x, y = mark:GetPoint(1)
    if x == node.x + 18 and y == -node.y - 18 then return mark end
  end
end

local function tint(mark)
  local v = mark and mark._vertex
  return v and string.format("%.2f,%.2f,%.2f", v[1], v[2], v[3])
end

T.section("overlay: one mark per missing node, coloured by what can be paid now")
local skipped = Overlay.Show({ [1] = 1, [2] = 3, [6] = 1 }, { [1] = 1 })
T.eq("the node without a button in the tree is counted, not drawn", skipped, 1)
T.check("the marks live in one container on the canvas", container() ~= nil)
T.eq("which is shown", container():IsShown(), true)
T.eq("an affordable node is green", tint(markOf(1)), "0.30,1.00,0.30")
T.eq("the others are amber", tint(markOf(2)), "1.00,0.65,0.10")
Overlay.Show({ [1] = 1 }, nil)
T.eq("without a plan every mark is gold", tint(markOf(1)), "1.00,0.82,0.00")
T.eq("a node no longer missing loses its mark", markOf(2):IsShown(), false)
T.eq("the other keeps it", markOf(1):IsShown(), true)
local regions = #container()._regions
Overlay.Show({ [1] = 1, [2] = 3 }, nil)
T.eq("a mark is reused, never created twice", #container()._regions, regions)

T.section("overlay: marks stay readable when the tree is zoomed far out")
local base = select(1, markOf(1):GetSize())
skillTreeCanvas:SetScale(0.1)
Overlay.Rescale()
T.eq("at 10 % a mark grows to stay 12 pixels on screen", select(1, markOf(1):GetSize()), 12 / 0.1)
skillTreeCanvas:SetScale(1)
Overlay.Rescale()
T.eq("at 100 % it is back to its size", select(1, markOf(1):GetSize()), base)

Overlay.Hide()
T.eq("hiding is one call on the container", container():IsShown(), false)
