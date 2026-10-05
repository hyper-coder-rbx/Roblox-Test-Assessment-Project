
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local SSS = game:GetService("ServerScriptService")

local Signal = require(RS.Packages.Signal)
local Knit = require(RS.Packages.Knit)
local Timer = require(RS.Packages.Timer)

local Enums = require(RS.Shared.Enums)


local SpawnerComp = require(SSS.Server.Components.Spawner)

--Configs
local GameConfigs = SS.Configs


--Workspace



local MatchService = Knit.CreateService {
	Name = "MatchService",

	Client = {
		MatchResult = Knit.CreateSignal(),
	},
}

-- Constants
local SpawnService
local LeaderstatService

-- Variables
local GameTimerClass = Timer.new(1)
local OnTimerFinishFnCallback = nil

---------------------------------------------------------------------

---------------------------------------------------------------------
function OnTimerUpdate()

	local val = workspace:GetAttribute("GameTimer") or 0

	if(val > 0) then
		workspace:SetAttribute("GameTimer", val - 1)
	else
		GameTimerClass:Stop()
		if(OnTimerFinishFnCallback) then
			OnTimerFinishFnCallback()
		end
	end
end


---------------------------------------------------------------------
--      OnBoarding
---------------------------------------------------------------------
function StartOnBoardingTimer()
	local gameState = workspace:GetAttribute("GameState")
	if(gameState ~= Enums.GameStateType.Idle) then return end
	
	if(GameTimerClass:IsRunning()) then return end
	
	workspace:SetAttribute("GameTimer", GameConfigs.StartTime.Value)
	OnTimerFinishFnCallback = OnBoardingTimerFinished
	GameTimerClass:StartNow()
end

function OnBoardingTimerFinished()
	workspace:SetAttribute("GameState", Enums.GameStateType.Waiting)

	task.wait(1)

	StartMatch()
end


---------------------------------------------------------------------
--      Match
---------------------------------------------------------------------
function InitMatch()
	workspace:SetAttribute("GameState", Enums.GameStateType.Idle)
	workspace:SetAttribute("GameTimer", GameConfigs.StartTime.Value)
	
end

function StartMatch()
	workspace:SetAttribute("GameState", Enums.GameStateType.MatchRunning)

	--Reposition all players (Who are onBoard)
	for i, plr in pairs(Players:GetPlayers()) do
		if(plr:GetAttribute("InMatch")) then
			SpawnService:RepositionPlayer(plr)
		end
	end

	--Start match timer
	workspace:SetAttribute("GameTimer", GameConfigs.GameTime.Value)
	OnTimerFinishFnCallback = OnMatchTimerFinished
	GameTimerClass:StartNow()
	
	--Start spawning items on arena
	for i, spawner in pairs(SpawnerComp:GetAll()) do
		spawner:StartSpawning()
	end
end

function OnMatchTimerFinished()
	workspace:SetAttribute("GameState", Enums.GameStateType.Outro)

	--Calcualte winner
	local winner, xp = LeaderstatService:CalculateWinner()
	if(winner) then
		MatchService.Client.MatchResult:FireAll(winner.Name, xp)
	end

	--Reposition all to lobby
	for i, plr in pairs(Players:GetPlayers()) do
		plr:SetAttribute("InMatch", nil)
		SpawnService:RepositionPlayer(plr)
	end

	--Stop/Clear spawning items on arena
	for i, spawner in pairs(SpawnerComp:GetAll()) do
		spawner:ClearAllSpawns()
	end
	
	workspace.Terrain.VFX:ClearAllChildren()
	
	task.wait(1)
	InitMatch()
end

---------------------------------------------------------------------

---------------------------------------------------------------------

function MatchService:KnitInit()
	self.conns = {}

	GameTimerClass.Tick:Connect(OnTimerUpdate)

	self.conns.PlayersOnBoardconn = workspace:GetAttributeChangedSignal("PlayersOnBoard"):Connect(function()
		local gameState = workspace:GetAttribute("GameState") or Enums.GameStateType.Idle
		local playersOnBoard = workspace:GetAttribute("PlayersOnBoard") or 0

		if(gameState == Enums.GameStateType.Idle) then

			if(playersOnBoard < GameConfigs.MinPlayers.Value) then
				GameTimerClass:Stop()
				workspace:SetAttribute("GameTimer", GameConfigs.StartTime.Value)
			else
				StartOnBoardingTimer()
			end
			
		elseif(gameState == Enums.GameStateType.MatchRunning) then
			
			local timerRemaining = workspace:GetAttribute("GameTimer")
			if(timerRemaining > 0) then
				
				if(playersOnBoard <= 1) then
					GameTimerClass:Stop()
					OnMatchTimerFinished()
				end
			end
		end
	end)
end

function MatchService:KnitStart()
	SpawnService = Knit.GetService("SpawnService")
	LeaderstatService = Knit.GetService("LeaderstatService")
end

return MatchService
