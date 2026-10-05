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

local Module = Component.new({ Tag = "MatchmakingStage"})

----Other scripts

----Configs

--============================================--
--            REQUEST-HANDLERS
--============================================--


--============================================--
--             CUSTOM LIFECYCLE
--============================================--

function Module:ClearTouchEvents()
	if(self.conns.Touched) then
		self.conns.Touched:Disconnect()
		self.conns.Touched = nil
	end
	if(self.conns.TouchEnded) then
		self.conns.TouchEnded:Disconnect()
		self.conns.TouchEnded = nil
	end
end

function Module:SetupTouchEvents()
	local stagePart :Part = self.Instance
	local gameState = workspace:GetAttribute("GameState") or Enums.GameStateType.Idle
	self:ClearTouchEvents()
	
	if(gameState ~= Enums.GameStateType.Idle) then
		return
	end
	
	self.onList = {}
	workspace:SetAttribute("PlayersOnBoard", #self.onList)
	
	self.conns.Touched = stagePart.Touched:Connect(function(part:BasePart)
		
		if(part.Name == "HumanoidRootPart") then
			local char = part.Parent
			local plr:Player = Players:GetPlayerFromCharacter(char)
			local found = table.find(self.onList, char)
			
			if(not found) then
				table.insert(self.onList, char)
				plr:SetAttribute("InMatch", true)
				workspace:SetAttribute("PlayersOnBoard", #self.onList)
			end
		end
	end)
	
	self.conns.TouchEnded = stagePart.TouchEnded:Connect(function(part:BasePart)
		
		if(part.Name == "HumanoidRootPart") then
			local char = part.Parent
			local plr:Player = Players:GetPlayerFromCharacter(char)
			local found = table.find(self.onList, char)
			
			if(found) then
				table.remove(self.onList, found)
				plr:SetAttribute("InMatch", false)
				workspace:SetAttribute("PlayersOnBoard", #self.onList)
			end
		end
	end)
end

function Module:SetupEvents()
	self:SetupTouchEvents()
	
	self.conns.GameState = workspace:GetAttributeChangedSignal("GameState"):Connect(function()
		local gameState = workspace:GetAttribute("GameState") or Enums.GameStateType.Idle
		
		if(gameState == Enums.GameStateType.Idle) then
			self:SetupTouchEvents()
		else
			self:ClearTouchEvents()
		end
	end)
end

function Module:Init()
	self.conns = {}
	
end

function Module:Ref() 

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