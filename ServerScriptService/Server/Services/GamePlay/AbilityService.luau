
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


local AbilityService = Knit.CreateService {
	Name = "AbilityService",

	Client = {

	},
}

-- Constants
local LeaderstatService
-- Variables

---------------------------------------------------------------------


---------------------------------------------------------------------
function AbilityService:OnLootCollected(plr:Player, itemType:string)

	--print("On Loot Collectdd:", plr, itemType)
	LeaderstatService:AddLootCount(plr)

	if(itemType == Enums.LootTypes.Landmine) then
		local count = plr:GetAttribute("LandmineCount") or 0
		warn("Player got landmine:", count, plr)
		plr:SetAttribute("LandmineCount", count + 1)

	elseif(itemType == Enums.LootTypes.DashZeroCooldown) then
		--Zero the dash cooldown
		plr:SetAttribute("DashUsageTime", time() - 1)

	elseif(itemType == Enums.LootTypes.SpeedBoost) then
		local char = plr.Character
		char.Humanoid.WalkSpeed += CD.Abilities.SpeedBoost.Increment

		--sfx
		local sfx = script.SpeedBoostSFX:Clone()
		sfx.Parent = plr.Character.HumanoidRootPart
		sfx:Play()
		Debris:AddItem(sfx, sfx.TimeLength)
		

		task.delay(CD.Abilities.SpeedBoost.Duration, function()
			if(char) then
				char.Humanoid.WalkSpeed -= CD.Abilities.SpeedBoost.Increment
			end
		end)

	end
end

---------------------------------------------------------------------

---------------------------------------------------------------------

function AbilityService:KnitInit()

end

function AbilityService:KnitStart()
	LeaderstatService = Knit.GetService("LeaderstatService")
end

return AbilityService
