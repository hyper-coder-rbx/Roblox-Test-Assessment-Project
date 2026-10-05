
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local Signal = require(RS.Packages.Signal)
local Knit = require(RS.Packages.Knit)

local CD = require(RS.Shared.Constants)
local Enums = require(RS.Shared.Enums)
local IASManager = require(RS.Shared.IASManager)
local DashSimulation = require(RS.Shared.DashSimulation)

local Dash = require(script.Dash)

--RS

--Workspace



local ControlsService = Knit.CreateService {
	Name = "ControlsService",

	Client = {

	},
}

-- Constants
local SpawnService
local LeaderstatService

-- Variables

---------------------------------------------------------------------
local function setupPlayerInputs(plr:Player)

	local ic = IASManager.getContext("MatchContexts", plr)
	
	if(ic) then
		local landmineAction = ic:GetAction("Landmine")
		
		landmineAction.Pressed:Connect(function()
			if(not plr:GetAttribute("InMatch")) then return end
			if(not plr.Character) then return end
			
			local landmineCount = plr:GetAttribute("LandmineCount") or 0
			if(landmineCount <= 0) then return end
			
			warn("Drop Landmine", plr)
			
			plr:SetAttribute("LandmineCount", landmineCount - 1)
			
			--Spawn landmine model, component will auto-start
			local landmine = SS.Assets.Elements.Landmine:Clone()
			landmine:PivotTo(plr.Character:GetPivot())
			landmine:SetAttribute("Owner", plr)
			landmine.Parent = workspace.Terrain.VFX
			
		end)
		
		
		--local dashAction = ic:GetAction("Dash")
		
		--dashAction.Pressed:Connect(function()
		--	if(not plr:GetAttribute("InMatch")) then return end
		--	local now  = time()
		--	local dashUsageTime = plr:GetAttribute("DashUsageTime") or 0
			
		--	if(now - dashUsageTime < 0) then return end
			
		--	plr:SetAttribute("DashUsageTime", now + CD.Abilities.Dash.Cooldown)
			
		--	local char = plr.Character
		--	Dash.Perform(char)
			
		--	warn("Dash requested", plr)
		--end)'
	end
end

---------------------------------------------------------------------
function ControlsService:OnPlayerAdded(player:Player)
	IASManager.setupDefault(player)

	setupPlayerInputs(player)
end

---------------------------------------------------------------------

function ControlsService:OnPlayerRemoving(player: Player)

end

---------------------------------------------------------------------

function ControlsService:KnitInit()
	DashSimulation.Initialize()
	
	Players.PlayerAdded:Connect(function(...)
		self:OnPlayerAdded(...)
	end)
	Players.PlayerRemoving:Connect(function(...)
		self:OnPlayerRemoving(...)
	end)

	workspace:GetAttributeChangedSignal("GameState"):Connect(function()
		local gameState = workspace:GetAttribute("GameState") or Enums.GameStateType.Idle

		if(gameState == Enums.GameStateType.MatchRunning) then
			
			print("ON match controls for players")
			for _, plr in Players:GetPlayers() do
				if(plr:GetAttribute("InMatch")) then
					local ic = IASManager.getContext("MatchContexts", plr)
					if(ic) then
						ic:Toggle(true)
					end
				end
			end

		else

			print("Off match controls for players")
			for _, plr in Players:GetPlayers() do
				local ic = IASManager.getContext("MatchContexts", plr)
				if(ic) then
					ic:Toggle(false)
				end
			end
		end
	end)
end

function ControlsService:KnitStart()
	SpawnService = Knit.GetService("SpawnService")
	LeaderstatService = Knit.GetService("LeaderstatService")
end

return ControlsService
