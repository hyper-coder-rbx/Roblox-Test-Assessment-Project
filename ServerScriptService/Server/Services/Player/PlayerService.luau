
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local Signal = require(RS.Packages.Signal)
local Knit = require(RS.Packages.Knit)

local Enums = require(RS.Shared.Enums)

--RS

--Workspace



local PlayerService = Knit.CreateService {
	Name = "PlayerService",
	
	Client = {
		
	},
}

-- Constants
local SpawnService
local LeaderstatService

-- Variables

---------------------------------------------------------------------
local function updateCollisionGroup(char:Model)
	
	local function update(part:BasePart)
		part.CollisionGroup = "Player"
	end
	
	for i, v in pairs(char:GetDescendants()) do
		if(v:IsA("BasePart")) then
			update(v)
		end
	end
	
	char.ChildAdded:Connect(function(v)
		if(v:IsA("BasePart")) then
			update(v)
		end
	end)
end

local function onPlayerDied(plr:Player)
	plr:SetAttribute("LandmineCount", 0)
	
	--local attacker = plr:GetAttribute("AttackerName")
	--if(not attacker) then
	--	return
	--end
	
	--plr:SetAttribute("AttackerName", nil)
	
	--local attackerPlr = Players:FindFirstChild(attacker)
	--if(not attackerPlr) then
	--	return
	--end
	
	--LeaderstatService:AddKillDeath(attackerPlr, plr)
	
end

---------------------------------------------------------------------
function PlayerService:OnPlayerAdded(player:Player)
	
	local function onCharAdded(char:Model)
		if(not char) then
			return
		end
		
		task.spawn(function()
			updateCollisionGroup(char)
		end)
		
		char.Humanoid.Died:Connect(function()
			onPlayerDied(player)
		end)
		
		SpawnService:RepositionPlayer(player)
	end
	
	onCharAdded(player.Character)
	player.CharacterAdded:Connect(onCharAdded)
end

---------------------------------------------------------------------

function PlayerService:OnPlayerRemoving(player: Player)
	
	local playersInMatch = 0
	
	for i, plr in pairs(Players:GetPlayers()) do
		playersInMatch += plr:GetAttribute("InMatch") and 1 or 0
	end
	
	workspace:SetAttribute("PlayersOnBoard", playersInMatch)
end

---------------------------------------------------------------------

function PlayerService:KnitInit()
	Players.PlayerAdded:Connect(function(...)
		self:OnPlayerAdded(...)
	end)
	Players.PlayerRemoving:Connect(function(...)
		self:OnPlayerRemoving(...)
	end)
end

function PlayerService:KnitStart()
	SpawnService = Knit.GetService("SpawnService")
	LeaderstatService = Knit.GetService("LeaderstatService")
end

return PlayerService
