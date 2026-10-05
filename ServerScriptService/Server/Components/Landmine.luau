
local CS = game:GetService("CollectionService")
local RS = game:GetService("ReplicatedStorage")
local HS = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Packages = RS.Packages

local Knit = require(Packages.Knit)
local Component = require(Packages.Component)

local CD = require(RS.Shared.Constants)


local Landmine = Component.new({Tag = "Landmine"})


------- Config
local LeaderstatService = Knit.GetService("LeaderstatService")
local EffectsService = Knit.GetService("EffectsService")


----------- Calculations ------------------


----------- Calculations ------------------




------------------------------------------------------------------
-- Lifecycle
------------------------------------------------------------------
function Landmine:Construct()
	self.OwnerPlr = self.Instance:GetAttribute("Owner"):Get()
	if(not self.OwnerPlr) then
		return
	end
	
	self.conns = {}
	self.active = true
end

function Landmine:Start()
	if(not self.active) then return end
	
	local trigger :Part = self.Instance
	
	self.conns.TouchedConn = trigger.Touched:Connect(function(hit)
		if(not self.active) then return end
		if(hit.Name ~= "HumanoidRootPart") then return end
		
		local char = hit.Parent
		local hum = char:FindFirstChild("Humanoid")
		--print("landmine Trigger:", hit, (not char or not hum or char == self.OwnerPlr.Character))
		if(not char or not hum or char == self.OwnerPlr.Character) then return end
		
		--Only damage one humanoid
		hum:TakeDamage(CD.Abilities.Landmine.Damage)
		

		--Leaderstats
		LeaderstatService:AddKillDeath(self.OwnerPlr, char)
		--EffectsService:BroadcastEffect("Hit3", trigger.CFrame)

		--Show effect
		local exp = Instance.new("Explosion")
		exp.DestroyJointRadiusPercent = 0
		exp.Position = trigger.Position
		exp.Parent = workspace
		
		char:BreakJoints()
		
		--SFX
		local sfx = script.LandmineSFX:Clone()
		sfx.Parent = char.Head
		sfx:Play()
		game.Debris:AddItem(sfx, sfx.TimeLength)
		
		self:Destroy()
	end)
end

function Landmine:Destroy()
	self.active = false
	
	if(self.conns) then
		for _, conn in self.conns do
			conn:Disconnect()
		end
	end
	
	self.Instance:Destroy()
end


return Landmine