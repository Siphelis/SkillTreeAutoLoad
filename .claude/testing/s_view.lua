local NS = SkillTreeAutoLoad
local L = NS.L
T.boot()
MOCK.tick(15)
T.openTree()
local View = NS.View

local function wheel(delta)
  skillTreeScroll:GetScript("OnMouseWheel")(skillTreeScroll, delta)
end

local function scale()
  return skillTreeCanvas:GetScale()
end

local function reset()
  skillTreeCanvas:SetScale(1)
  skillTreeCanvas:SetSize(3000, 2000)
end

local function label()
  return skillTreeFrame.zoomText and skillTreeFrame.zoomText:GetText()
end

T.section("view: the wheel zooms by steps, toward the cursor")
wheel(1)
MOCK.tick(1)
T.check("one notch zooms in", scale() > 1.05 and scale() < 1.25, scale())
T.eq("the tree's own zoom is not used", PE.nativeWheel, 0)
T.eq("the level is shown", label(), string.format(L.LABEL_ZOOM, math.floor(scale() * 100 + 0.5)))
MOCK.tick(11)
T.eq("and fades after a second", label(), "")

reset()
wheel(1) wheel(1) wheel(1)
MOCK.tick(1)
local together = scale()
reset()
for _ = 1, 3 do
  wheel(1)
  MOCK.tick(1)
end
T.eq("three notches in one frame land where three separate ones do", together, scale())

wheel(-60)
MOCK.tick(1)
T.eq("the floor is 10 %", scale(), 0.10)
T.eq("below 50 % node icons are hidden", skillTreeNode1.icon:IsShown(), false)
T.eq("with their rank text", skillTreeNode1.rankText:IsShown(), false)
wheel(60)
MOCK.tick(1)
T.eq("the ceiling is 250 %", scale(), 2.50)
T.eq("icons come back", skillTreeNode1.icon:IsShown(), true)
T.eq("the canvas keeps its size on screen", math.floor(skillTreeCanvas:GetWidth() * scale() + 0.5), 3000)

T.section("view: hovering a save frames its missing nodes, leaving puts the tree back")
reset()
skillTreeScroll:SetHorizontalScroll(0)
skillTreeScroll:SetVerticalScroll(0)
MOCK.tick(12)
View.Preview("far", { [5] = 2 }, nil)
MOCK.tick(2)
T.eq("nothing moves before the hover delay", skillTreeScroll:GetHorizontalScroll(), 0)
MOCK.tick(10)
T.check("then the view travels to the node", skillTreeScroll:GetHorizontalScroll() > 1000, skillTreeScroll:GetHorizontalScroll())
local box
for _, child in ipairs(skillTreeCanvas._children) do
  local region = child._regions and child._regions[1]
  if region and region._texture == "Interface\\Buttons\\UI-ActionButton-Border" then box = child end
end
T.check("and marks it", box and box:IsShown())
View.Release()
MOCK.tick(10)
T.eq("leaving brings the view back", skillTreeScroll:GetHorizontalScroll(), 0)
T.eq("at the zoom it had", scale(), 1)

NS.Data.SetPreviewCamera(false)
View.Preview("far", { [5] = 2 }, nil)
MOCK.tick(10)
T.eq("with the camera off the view does not move", skillTreeScroll:GetHorizontalScroll(), 0)
T.check("but the marks still appear", box and box:IsShown())
View.Release()
NS.Data.SetPreviewCamera(true)

T.closeTree()
View.Preview("far", { [5] = 2 }, nil)
MOCK.tick(10)
T.eq("with the tree closed, nothing moves", skillTreeScroll:GetHorizontalScroll(), 0)
View.Cancel()
T.openTree()

T.section("view: an error in our zoom gives the wheel back to the tree")
local setScale = skillTreeCanvas.SetScale
skillTreeCanvas.SetScale = function() error("boom") end
wheel(1)
MOCK.tick(1)
skillTreeCanvas.SetScale = nil
T.eq("the player is told once", T.printed((L.MSG_ZOOM_FAILED:match("^(.-)%%"))), 1)
T.check("the message names the error", T.printed("boom") >= 1)
wheel(1)
T.eq("the tree's own zoom answers again", PE.nativeWheel, 1)
T.check("SetScale was restored for the rest of the run", skillTreeCanvas.SetScale == setScale)
T.eq("nothing reloads the interface", MOCK.reloads, 0)
