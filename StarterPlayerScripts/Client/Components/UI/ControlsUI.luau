local RS = game:GetService("ReplicatedStorage")
local RnS = game:GetService("RunService")

local Knit = require(RS.Packages.Knit)
local Component = require(RS.Packages.Component)

local myPlr = game.Players.LocalPlayer

local Enums = require(RS.Shared.Enums)
local IASManager = require(RS.Shared.IASManager)
local DashSimulation = require(RS.Shared.DashSimulation)



-- Other scripts
local UIController = Knit.GetController("UIController")

--==================================================
-- Components Setup
--==================================================

local ControlsUI = Component.new({
	Tag = "ControlsUI",
	Ancestors = {myPlr}
})


type uiType = {
	Base: Frame,
	LandmineButton: TextButton,
	DashButton: TextButton,
	SpeedTxt: TextLabel,
}

local UI: uiType = {}

-- Private State


--==================================================
-- Private Functions
--==================================================
function UpdateLandmineTxt()

	local landmineCount = myPlr:GetAttribute("LandmineCount") or 0
	
	UI.LandmineButton.Text = "Landmine: "..landmineCount
	UI.LandmineButton.BackgroundColor3 = landmineCount > 0 and Color3.fromRGB(255, 37, 41) or Color3.fromRGB(111, 0, 0)
	UI.LandmineButton.AutoButtonColor = landmineCount > 0
	UI.LandmineButton.Active = landmineCount > 0
end

function UpdateSpeedTxt()
	if(not myPlr.Character or not myPlr.Character:FindFirstChild("Humanoid")) then
		UI.SpeedTxt.Text = ""
		return
	end
	
	UI.SpeedTxt.Text = "" .. myPlr.Character.Humanoid.WalkSpeed
end


--==================================================
-- Public Functions
--==================================================

function ControlsUI:Toggle(visible: boolean?)
	if not UI.Base then return end
	if visible == nil then visible = not UI.Base.Visible end
	
	UI.Base.Visible = visible
end

function ControlsUI:Init()
	self.conns = {}
end

function ControlsUI:Ref()
	UI.Base = self.Instance
	
	UI.LandmineButton = UI.Base.LandmineButton
	UI.DashButton = UI.Base.DashButton
	UI.SpeedTxt = UI.Base.SpeedTxt
end

function ControlsUI:Events()
	local ic = IASManager.getContext("MatchContexts")
	
	ic:OnEnableChanged():Connect(function()
		if(ic:IsActive()) then
			self:Toggle(true)
		else
			self:Toggle(false)
		end
	end)
	
	
	UpdateLandmineTxt()
	myPlr:GetAttributeChangedSignal("LandmineCount"):Connect(function()
		UpdateLandmineTxt()
	end)
	
	UpdateSpeedTxt()
	myPlr.CharacterAdded:Connect(function(char:Model)
		UpdateSpeedTxt()
		
		char:WaitForChild("Humanoid"):GetPropertyChangedSignal("WalkSpeed"):Connect(function()
			UpdateSpeedTxt()
		end)
	end)
end


function ControlsUI:Construct()
	self:Ref()
	self.active = UIController:SubsUI("ControlsUI", self)
end

function ControlsUI:Start()
	if not self.active then return end
	self:Init()
	self:Events()
	self:Toggle(false)
end

return ControlsUI