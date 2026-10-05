
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local Signal = require(RS.Packages.Signal)
local Knit = require(RS.Packages.Knit)
local Timer = require(RS.Packages.Timer)

local Enums = require(RS.Shared.Enums)

--Configs
local GameConfigs = SS.Configs


--Workspace
local SpawnLocations = workspace.Scriptables.Maps.Arena.SpawnLocations


local SpawnService = Knit.CreateService {
	Name = "SpawnService",

	Client = {

	},
}

-- Constants
local DefaultWalkSpeed = 24

-- Variables

---------------------------------------------------------------------
local function getFreeSpawnLocation()

	local spawnLocations = SpawnLocations:GetChildren()

	local function getRndm()
		local rndm = math.random(1, #spawnLocations)
		local name = "Spawn"..rndm

		local spawnLocation :SpawnLocation = SpawnLocations:FindFirstChild(name)
		return spawnLocation
	end

	local found = getRndm()
	if(not found:GetAttribute("OccupiedBy")) then
		return found
	end

	return getFreeSpawnLocation()
end

---------------------------------------------------------------------
function SpawnService:RepositionPlayer(plr:Player, autoHandle:boolean)

	if(plr:GetAttribute("InMatch")) then

		local spawnLocation :SpawnLocation = getFreeSpawnLocation()

		plr.RespawnLocation = spawnLocation
		--plr.TeamColor = spawnLocation.TeamColor

		warn(`Assigned: {spawnLocation}, plr: {plr.Character}`)
		plr.Character:PivotTo(spawnLocation.CFrame)
		spawnLocation:SetAttribute("OccupiedBy", plr.UserId)

		task.delay(1, function()
			spawnLocation:SetAttribute("OccupiedBy", nil)
		end)

	else

		--if true, it means he was in match.
		if(plr.RespawnLocation) then
			plr.RespawnLocation = nil

			--Sent back to lobby
			plr:LoadCharacterAsync()

		end
		
		--plr.Character:PivotTo()
	end

end

---------------------------------------------------------------------

---------------------------------------------------------------------

function SpawnService:KnitInit()

end

function SpawnService:KnitStart()

end

return SpawnService
