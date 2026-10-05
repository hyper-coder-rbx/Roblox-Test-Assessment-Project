
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



local LeaderstatService = Knit.CreateService {
	Name = "LeaderstatService",

	Client = {
	},
}

-- Constants
local SpawnService

-- Variables

---------------------------------------------------------------------

---------------------------------------------------------------------
local function setupMatchLeaderstats(player:Player)
	clearMatchStats(player)

	local leaderstats = Instance.new("Folder")

	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local kills = Instance.new("IntValue")
	kills.Name = "Kills"
	kills.Parent = leaderstats

	local loot = Instance.new("IntValue")
	loot.Name = "Loot"
	loot.Parent = leaderstats

end

function clearMatchStats(player:Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if(leaderstats) then
		leaderstats:Destroy()
	end
end

---------------------------------------------------------------------
function LeaderstatService:AddKillDeath(attackerPlr:Player, victimChar:Model)

	local lStats = attackerPlr:FindFirstChild("leaderstats")
	if(lStats) then
		local obj = lStats:FindFirstChild("Kills")
		if(obj) then
			obj.Value += 1
		end
	end

end

function LeaderstatService:AddLootCount(plr:Player)

	local lStats = plr:FindFirstChild("leaderstats")
	if(lStats) then
		local obj = lStats:FindFirstChild("Loot")
		if(obj) then
			obj.Value += 1
		end
	end

end

function LeaderstatService:CalculateWinner()
	
	local function getTotalXp(plr:Player)
		local leaderstats = plr:FindFirstChild("leaderstats")
		if(not leaderstats) then
			return 0
		end
		
		local kills = leaderstats:FindFirstChild("Kills").Value
		local loot = leaderstats:FindFirstChild("Loot").Value
		
		local totalXp = (kills * CD.XP_Rates.Kill) + (loot * CD.XP_Rates.Loot)
		
		return totalXp
	end
	
	local winnerXp, winnerPlr = 0, nil
	for i, plr in pairs(Players:GetPlayers()) do
		if(plr:GetAttribute("InMatch")) then
			--TODO: Calculate winner
			local totalXp = getTotalXp(plr)
			
			if(totalXp > winnerXp) then
				winnerXp = totalXp
				winnerPlr = plr
			end
		end
	end
	
	
	if(not winnerPlr) then
		return nil
	end
	
	
	return winnerPlr, winnerXp	
end

---------------------------------------------------------------------

function LeaderstatService:KnitInit()
	self.conns = {}

	self.conns.GameState = workspace:GetAttributeChangedSignal("GameState"):Connect(function()
		local gameState = workspace:GetAttribute("GameState") or Enums.GameStateType.Idle

		if(gameState == Enums.GameStateType.MatchRunning) then

			for i, plr in pairs(Players:GetPlayers()) do

				if(plr:GetAttribute("InMatch")) then
					setupMatchLeaderstats(plr)
				end

			end
		else

			for i, plr in pairs(Players:GetPlayers()) do
				clearMatchStats(plr)
			end
		end
	end)
end

function LeaderstatService:KnitStart()
	SpawnService = Knit.GetService("SpawnService")
end

return LeaderstatService
