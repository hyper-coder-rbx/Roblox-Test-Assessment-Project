local CS = game:GetService("CollectionService")
local RS = game:GetService("ReplicatedStorage")
local HS = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Packages = RS.Packages

local Knit = require(Packages.Knit)
local Component = require(Packages.Component)

local EC = require(RS.Shared.EffectController)

local Assets = RS.Assets.SpawnItems


local SpawnItem = Component.new({Tag = "SpawnItem"})


------- Config
local AbilityService = Knit.GetService("AbilityService")
local EffectsService = Knit.GetService("EffectsService")


----------- Calculations ------------------


----------- Calculations ------------------




------------------------------------------------------------------
-- Lifecycle
------------------------------------------------------------------
function SpawnItem:Construct()
	self.ItemType = self.Instance:GetAttribute("ItemType")
	if(not self.ItemType) then
		return
	end
	
	self.conns = {}
	self.active = true
end

function SpawnItem:Start()
	if(not self.active) then return end
	
	local trigger :Part = self.Instance
	
	self.conns.TouchedConn = trigger.Touched:Connect(function(hit)
		if(not self.active) then return end
		if(hit.Name ~= "HumanoidRootPart") then return end
		
		local char = hit.Parent
		local hum = char:FindFirstChild("Humanoid")
		if(not char or not hum) then return end
		
		local plr = game.Players:GetPlayerFromCharacter(char)
		if(not plr) then return end
		
		self.active = false
		
		AbilityService:OnLootCollected(plr, self.ItemType)
		EffectsService:BroadcastEffect("Hit1", trigger.CFrame)
		
		self:Destroy()
	end)
end

function SpawnItem:Destroy()
	self.active = false
	
	if(self.conns) then
		for _, conn in self.conns do
			conn:Disconnect()
		end
	end
	
	self.Instance:Destroy()
end


return SpawnItem