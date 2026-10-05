local RS = game:GetService("ReplicatedStorage")
local StarterGUI = game:GetService("StarterGui")

local Knit = require(RS.Packages.Knit)

local mPlr = game.Players.LocalPlayer

local Enums = require(RS.Shared.Enums)
local IASManager = require(RS.Shared.IASManager)
local EffectController = require(RS.Shared.EffectController)


local EffectsController = Knit.CreateController { 
	Name = "EffectsController" 
}



function EffectsController:KnitInit()
	local EffectsService = Knit.GetService("EffectsService")

	EffectsService.SpawnEffect:Connect(function(...)
		EffectController:Play(...)
	end)
end

return EffectsController