local RS = game:GetService("ReplicatedStorage")
local RnS = game:GetService("RunService")

local Knit = require(RS.Packages.Knit)
local Component = require(RS.Packages.Component)

local myPlr = game.Players.LocalPlayer

local Enums = require(RS.Shared.Enums)



-- Other scripts
local MatchService = Knit.GetService("MatchService")
local UIController = Knit.GetController("UIController")

--==================================================
-- Components Setup
--==================================================

local MatchEndUI = Component.new({
	Tag = "MatchEndUI",
	Ancestors = {myPlr}
})


type uiType = {
	Base: Frame,
	WinnerName: TextLabel,
	XPTxt: TextLabel,
}

local UI: uiType = {}

-- Private State


--==================================================
-- Private Functions
--==================================================

local function updateResultTxts(winnerName, xp)
	if(not winnerName) then
		UI.WinnerName.Text = "Creator"
		UI.XPTxt.Text = "XP:inf"
		return
	end
	
	UI.WinnerName.Text = winnerName .. " Won!!"
	UI.XPTxt.Text = "XP:" .. xp
end

--==================================================
-- Public Functions
--==================================================

function MatchEndUI:Toggle(visible: boolean?)
	if not UI.Base then return end
	if visible == nil then visible = not UI.Base.Visible end
	
	UI.Base.Visible = visible
end

function MatchEndUI:Init()
	self.conns = {}
end

function MatchEndUI:Ref()
	UI.Base = self.Instance
	
	UI.WinnerName = UI.Base.WinnerName
	UI.XPTxt = UI.Base.XPTxt
end

function MatchEndUI:Events()
	
	--workspace:GetAttributeChangedSignal("GameState"):Connect(function()
	--	local gameState = workspace:GetAttribute("GameState") or Enums.GameStateType.Idle
		
	--	if(gameState ~= Enums.GameStateType.Outro) then
	--		self:Toggle(false)
	--	end
	--end)
	
	MatchService.MatchResult:Connect(function(...)
		updateResultTxts(...)
		self:Toggle(true)
		
		--sfx
		local sfx = script.winner:Clone()
		sfx.Parent = UI.Base
		sfx:Play()
		game.Debris:AddItem(sfx, sfx.TimeLength)
		
		--close after 5s
		task.delay(5, function()
			self:Toggle(false)
		end)
	end)
end


function MatchEndUI:Construct()
	self:Ref()
	self.active = UIController:SubsUI("MatchEndUI", self)
end

function MatchEndUI:Start()
	if not self.active then return end
	self:Init()
	self:Events()
	self:Toggle(false)
end

return MatchEndUI