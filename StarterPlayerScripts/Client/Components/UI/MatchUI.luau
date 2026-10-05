local RS = game:GetService("ReplicatedStorage")
local RnS = game:GetService("RunService")

local Knit = require(RS.Packages.Knit)
local Component = require(RS.Packages.Component)

local myPlr = game.Players.LocalPlayer

local Enums = require(RS.Shared.Enums)



-- Other scripts
local UIController = Knit.GetController("UIController")

--==================================================
-- Components Setup
--==================================================

local MatchUI = Component.new({
	Tag = "MatchUI",
	Ancestors = {myPlr}
})


type uiType = {
	Base: Frame,
	MatchTimer: TextLabel,
}

local UI: uiType = {}

-- Private State


--==================================================
-- Private Functions
--==================================================

local function updateTimerTxt()
	local matchTime = workspace:GetAttribute("GameTimer") or 0
	local min = math.floor(matchTime / 60)
	local sec = matchTime % 60

	local timerString = string.format("%02d:%02d", min, sec)

	if(min < 1) then
		timerString = string.format("%02d", sec)
	end

	UI.MatchTimer.Text = "Timer:" .. timerString
end
--==================================================
-- Public Functions
--==================================================

function MatchUI:Toggle(visible: boolean?)
	if not UI.Base then return end
	if visible == nil then visible = not UI.Base.Visible end
	
	UI.Base.Visible = visible
end

function MatchUI:Init()
	self.conns = {}
end

function MatchUI:Ref()
	UI.Base = self.Instance
	
	UI.MatchTimer = UI.Base.MatchTimer
end

function MatchUI:Events()
	
	workspace:GetAttributeChangedSignal("GameState"):Connect(function()
		local gameState = workspace:GetAttribute("GameState") or Enums.GameStateType.Idle
		updateTimerTxt()
		
		if(gameState == Enums.GameStateType.MatchRunning and myPlr:GetAttribute("InMatch")) then
			self:Toggle(true)
		else
			self:Toggle(false)
		end
	end)
	
	
	workspace:GetAttributeChangedSignal("GameTimer"):Connect(function()
		updateTimerTxt()
	end)
end


function MatchUI:Construct()
	self:Ref()
	self.active = UIController:SubsUI("MatchUI", self)
end

function MatchUI:Start()
	if not self.active then return end
	self:Init()
	self:Events()
	self:Toggle(false)
end

return MatchUI