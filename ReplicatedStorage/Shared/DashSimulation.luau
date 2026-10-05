--[[
	DashSimulation  (ModuleScript, put in ReplicatedStorage)

	Server Authority safe dash.
	Require + Initialize it from BOTH a server Script and a LocalScript
	(same loader pattern as your other simulation modules).

	Rules this module follows (do the same in any other simulation code):
	  - All logic runs inside RunService:BindToSimulation, on client AND server
	  - Input comes from InputAction:GetState() (polled), never from .Pressed / UserInputService
	  - Time comes from time(), never os.clock / tick / task.wait / task.delay
	  - Dash state lives in attributes on the HumanoidRootPart (survives rollback + resimulation)
	  - No Instance creation per dash (no constraints), only simulation-access property writes
	  - Visuals / animation / sounds are NOT here, render them from the attributes in RenderStepped

	Attributes written on HumanoidRootPart:
		DashHeld, DashStart, DashDirX, DashDirZ, DashEndSpeed, DashReadyAt
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CD = require(script.Parent.Constants)
local IASManager = require(script.Parent.IASManager)

local DashSimulation = {}

------- Config
local ACTION_NAME = "Dash"  -- InputAction (Type = Bool). Searched anywhere under the Player, folder layout doesn't matter
local DISTANCE = 25         -- studs travelled
local DURATION = 0.5        -- seconds
local COOLDOWN = CD.Abilities.Dash.Cooldown        -- seconds, counted from dash end
local RAMP_IN = 0.12        -- fraction of the dash spent easing up to peak speed (softer start = smaller rollback artifacts)
local STEP_FREQUENCY = Enum.StepFrequency.Hz60 -- if this line errors in your Studio build, delete the argument in BindToSimulation
------- Config


-- Hook for your own rules (stun, ragdoll, attacking, stamina...). Must be deterministic: only read simulation state.
local function canDash(humanoid: Humanoid, root: BasePart): boolean
	return true
end


-- Speed shape over normalized time a (0..1): smooth ramp-in, then quadratic ease-out
local function shape(a: number): number
	local ramp = math.clamp(a / RAMP_IN, 0, 1)
	ramp = ramp * ramp * (3 - 2 * ramp) -- smoothstep
	return ramp * (1 - a) ^ 2
end

-- Mean of shape() over [0,1], computed once, so total travel == DISTANCE
local SHAPE_MEAN: number = (function()
	local steps = 200
	local sum = 0
	for i = 0, steps - 1 do
		sum += shape((i + 0.5) / steps)
	end
	return sum / steps
end)()


-- InputAction lookup (cached, InputAction instances are stable so this is rollback-safe)
local actionCache: { [Player]: InputAction } = {}

local function onDashStarted(char)
	
	local trail :Trail = char.HumanoidRootPart:FindFirstChild("DashTrail")
	local sfx :Sound = char.HumanoidRootPart:FindFirstChild("DashSFX")
	if not trail then
		trail = script.DashTrail:Clone()
		trail.Parent = char.HumanoidRootPart
	end
	if not sfx then
		sfx = script.DashSFX:Clone()
		sfx.Parent = char.HumanoidRootPart
	end
	
	sfx:Play()
	
	trail.Attachment0 = char.Head.NeckRigAttachment
	trail.Attachment1 = char.HumanoidRootPart.RootRigAttachment
	trail.Enabled = true
end

local function onDashEnded(char)

	local trail :Trail = char.HumanoidRootPart:FindFirstChild("DashTrail")
	if trail then
		trail.Enabled = false
	end

end

local function getDashAction(player: Player): InputAction?
	local cached = actionCache[player]
	if cached and cached.Parent then
		return cached
	end

	local ic = IASManager.getContext("MatchContexts", player)
	if(not ic) then
		return nil
	end
	
	
	local found = ic:GetAction("Dash")
	
	if found and found:IsA("InputAction") then
		actionCache[player] = found
		return found
	end
	
	return nil
end

script.Event.Event:Connect(function(start, ...)
	if(start) then
		onDashStarted(...)
	else
		onDashEnded(...)
	end
end)

local function stepPlayer(player: Player)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root or humanoid.Health <= 0 then return end

	local now = time() -- synchronized + rewinds on resimulation

	-- 1) Input edge detection. Last state is stored in an attribute so rollback restores it.
	local action = getDashAction(player)
	local held = action ~= nil and action:GetState() == true
	local wasHeld = root:GetAttribute("DashHeld") == true
	if held ~= wasHeld then
		root:SetAttribute("DashHeld", held)
	end

	local dashStart = root:GetAttribute("DashStart") :: number?
	local dashing = dashStart ~= nil and (now - dashStart) < DURATION

	-- 2) Start
	if held and not wasHeld and not dashing then
		local readyAt = (root:GetAttribute("DashReadyAt") :: number?) or 0

		if now >= readyAt and canDash(humanoid, root) then
			local moveDir = humanoid.MoveDirection
			local dir = Vector3.new(moveDir.X, 0, moveDir.Z)
			local moving = dir.Magnitude > 0.1

			if not moving then
				local look = root.CFrame.LookVector
				dir = Vector3.new(look.X, 0, look.Z)
			end

			if dir.Magnitude > 0.01 then
				dir = dir.Unit

				root:SetAttribute("DashStart", now)
				root:SetAttribute("DashDirX", dir.X)
				root:SetAttribute("DashDirZ", dir.Z)
				-- Hand-off speed: end the dash at walk speed if the player is still running (no stop -> re-accelerate hitch)
				root:SetAttribute("DashEndSpeed", moving and humanoid.WalkSpeed or 0)
				root:SetAttribute("DashReadyAt", now + DURATION + COOLDOWN)

				humanoid.AutoRotate = false
				root.CFrame = CFrame.lookAt(root.Position, root.Position + dir)

				--warn("Dash Started")
				script.Event:Fire(true, character)
				dashStart = now
				dashing = true
			end
		end
	end

	-- 3) Apply / finish
	if dashing then
		local dirX = root:GetAttribute("DashDirX") :: number
		local dirZ = root:GetAttribute("DashDirZ") :: number
		local endSpeed = root:GetAttribute("DashEndSpeed") :: number

		-- speed(a) = endSpeed + extraPeak * shape(a), mean speed == DISTANCE / DURATION
		local extraPeak = math.max(DISTANCE / DURATION - endSpeed, 0) / SHAPE_MEAN
		local alpha = (now - dashStart) / DURATION
		local speed = endSpeed + extraPeak * shape(alpha)

		-- Only XZ is driven, Y untouched so gravity / jumping still behave
		local vel = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = Vector3.new(dirX * speed, vel.Y, dirZ * speed)

	elseif dashStart ~= nil then
		--warn("Dash Ended")
		script.Event:Fire(false, character)
		root:SetAttribute("DashStart", nil)
		humanoid.AutoRotate = true
	end
end


function DashSimulation.Initialize()
	Players.PlayerRemoving:Connect(function(player)
		actionCache[player] = nil
	end)

	-- Default priority (2000) on purpose: lower priorities were reported to desync Humanoid.MoveDirection
	RunService:BindToSimulation(function(deltaTime: number)
		if RunService:IsServer() then
			for _, player in Players:GetPlayers() do
				stepPlayer(player)
			end
		else
			-- Clients don't receive other players' inputs, so only the local player is simulated here.
			-- Other players' dashes arrive as authoritative server state.
			local localPlayer = Players.LocalPlayer
			if localPlayer then
				stepPlayer(localPlayer)
			end
		end
	end, STEP_FREQUENCY)
end

return DashSimulation