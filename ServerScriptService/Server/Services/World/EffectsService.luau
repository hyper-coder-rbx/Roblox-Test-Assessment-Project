
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local Signal = require(RS.Packages.Signal)
local Knit = require(RS.Packages.Knit)
local Timer = require(RS.Packages.Timer)

local CD = require(RS.Shared.Constants)
local Enums = require(RS.Shared.Enums)

--Configs
local GameConfigs = SS.Configs


--Workspace



local EffectsService = Knit.CreateService {
	Name = "EffectsService",

	Client = {
		SpawnEffect = Knit.CreateSignal(),
	},
}

-- Constants

-- Variables

---------------------------------------------------------------------

---------------------------------------------------------------------

---------------------------------------------------------------------
function EffectsService:BroadcastEffect(...)
	self.Client.SpawnEffect:FireAll(...)
end

---------------------------------------------------------------------

function EffectsService:KnitInit()
	
end

function EffectsService:KnitStart()
	
end

return EffectsService
