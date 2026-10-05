local RS = game:GetService("ReplicatedStorage")
local StarterGUI = game:GetService("StarterGui")

local Knit = require(RS.Packages.Knit)

local mPlr = game.Players.LocalPlayer

local Enums = require(RS.Shared.Enums)
local IASManager = require(RS.Shared.IASManager)


local PlayerController = Knit.CreateController { 
	Name = "PlayerController" 
}

local function Toggle_Reset_Call_Back(Enable)
	local function Async()
		local success = pcall(function() 
			StarterGUI:SetCore("ResetButtonCallback", Enable) 
		end)

		if(success)then
			return true
		end
		return false
	end

	while Async() == false do
		task.wait(1)
	end
end

function PlayerController:KnitInit()
	local PlayerService = Knit.GetService("PlayerService")

	task.spawn(function()
		Toggle_Reset_Call_Back(false)
	end)
	
end

return PlayerController