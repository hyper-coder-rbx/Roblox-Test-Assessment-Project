-- Server Combat Component
local SS = game:GetService("ServerStorage")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Packages = RS.Packages
local Component = require(Packages.Component)
local Knit = require(Packages.Knit)

local Shared = RS.Shared
local Enums = require(RS.Shared.Enums)

local GameConfigs = SS.Configs

local Module = Component.new({ Tag = "LobbyDisplayGui"})

----Other scripts

----Configs

--============================================--
--            REQUEST-HANDLERS
--============================================--


--============================================--
--             CUSTOM LIFECYCLE
--============================================--

function Module:SetupEvents()
	self.conns.PlayersOnBoardconn = workspace:GetAttributeChangedSignal("PlayersOnBoard"):Connect(function()
		local gameState = workspace:GetAttribute("GameState") or Enums.GameStateType.Idle
		
		if(gameState == Enums.GameStateType.Idle) then
			self.PlayersCountTxt.Text = "Players OnBoard: " .. workspace:GetAttribute("PlayersOnBoard") or 0
		else
			self.PlayersCountTxt.Text = "Players In-Match: " .. workspace:GetAttribute("PlayersOnBoard") or 0
		end
	end)
	

	self.conns.GameTimerconn = workspace:GetAttributeChangedSignal("GameTimer"):Connect(function()
		local gameState = workspace:GetAttribute("GameState") or Enums.GameStateType.Idle
		local timer = workspace:GetAttribute("GameTimer") or GameConfigs.GameTime.Value
		local playerOnBoard = workspace:GetAttribute("PlayersOnBoard") or 0

		if(gameState == Enums.GameStateType.Idle) then
			self.StatusTxt.Text = "Match"
			
			if(playerOnBoard < GameConfigs.MinPlayers.Value) then
				self.TimerTxt.Text = "Min Players Required: " .. GameConfigs.MinPlayers.Value
			else
				self.TimerTxt.Text = "Starting in: " .. timer
			end
			
		elseif(gameState == Enums.GameStateType.Outro) then
			self.StatusTxt.Text = "Match: Finished!"
			self.TimerTxt.Text = "Returning to base..."
			
		else
			self.StatusTxt.Text = "Match: In-Progress"
			self.TimerTxt.Text = "Match Timer: " .. timer
		end
	end)
end

function Module:Init()
	self.conns = {}
	
	self.StatusTxt.Text = "Match"
	self.TimerTxt.Text = "Min Players Required: " .. GameConfigs.MinPlayers.Value
	self.PlayersCountTxt.Text = "Players OnBoard: " .. workspace:GetAttribute("PlayersOnBoard") or 0
end

function Module:Ref() 
	self.Bg = self.Instance.Frame
	
	self.PlayersCountTxt = self.Bg.PlayersCount
	self.TimerTxt = self.Bg.Timer
	self.StatusTxt = self.Bg.Status
end

--============================================--
--                 LIFECYCLE
--============================================--

function Module:Construct()
	self:Ref()
	self:Init()
	self.active = true
end

function Module:Start()
	if not self.active then return end

	self:SetupEvents()
end

function Module:Stop()
	self.active = false

	for _, conn in pairs(self.conns) do
		if conn then conn:Disconnect() end
	end
	self.conns = {}

end


return Module