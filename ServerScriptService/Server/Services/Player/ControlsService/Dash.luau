--!strict
--[[
	Dash.lua (ModuleScript, require from a LocalScript)

	Dash.Perform(character, options?) -> boolean   (false = dash was blocked)
	Dash.Cancel(character)
	Dash.IsDashing(character) -> boolean

	options:
		Distance  : number?   studs travelled        (default 25)
		Duration  : number?   seconds                (default 0.25)
		Direction : Vector3?  world direction        (default: MoveDirection, else facing)
]]

local RunService = game:GetService("RunService")

local Dash = {}

export type DashOptions = {
	Distance: number?,
	Duration: number?,
	Direction: Vector3?,
}

local DEFAULT_DISTANCE = 50
local DEFAULT_DURATION = .75

-- character -> finish function (also acts as "is dashing" flag)
local active: { [Model]: () -> () } = {}

function Dash.IsDashing(character: Model): boolean
	return active[character] ~= nil
end

function Dash.Cancel(character: Model)
	local finish = active[character]
	if finish then
		finish()
	end
end

function Dash.Perform(character: Model, options: DashOptions?): boolean
	if active[character] then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root or humanoid.Health <= 0 then
		return false
	end

	local distance = (options and options.Distance) or DEFAULT_DISTANCE
	local duration = (options and options.Duration) or DEFAULT_DURATION

	-- Direction: explicit > input direction > facing direction (always flattened to XZ)
	local dir: Vector3 = (options and options.Direction) or humanoid.MoveDirection
	dir = Vector3.new(dir.X, 0, dir.Z)
	if dir.Magnitude < 0.01 then
		local look = root.CFrame.LookVector
		dir = Vector3.new(look.X, 0, look.Z)
		if dir.Magnitude < 0.01 then
			return false
		end
	end
	dir = dir.Unit

	-- Face dash direction, stop humanoid from rotating us mid-dash
	local prevAutoRotate = humanoid.AutoRotate
	humanoid.AutoRotate = false
	root.CFrame = CFrame.lookAt(root.Position, root.Position + dir)

	-- Plane mode = only XZ is controlled, gravity still works (no floating on air dashes)
	local attachment = Instance.new("Attachment")
	attachment.Name = "DashAttachment"
	attachment.Parent = root

	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "DashVelocity"
	velocity.Attachment0 = attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	velocity.PrimaryTangentAxis = Vector3.xAxis
	velocity.SecondaryTangentAxis = Vector3.zAxis
	velocity.MaxForce = math.huge

	-- Speed falls linearly from peak to 0 => ease-out motion.
	-- Area under the curve = peak * duration / 2 = distance
	local peakSpeed = 2 * distance / duration
	velocity.PlaneVelocity = Vector2.new(dir.X * peakSpeed, dir.Z * peakSpeed)
	velocity.Parent = root

	local connection: RBXScriptConnection? = nil
	local startTime = os.clock()

	local function finish()
		if not active[character] then
			return
		end
		active[character] = nil

		if connection then
			connection:Disconnect()
			connection = nil
		end
		velocity:Destroy()
		attachment:Destroy()

		if humanoid.Parent then
			humanoid.AutoRotate = prevAutoRotate
		end
	end

	active[character] = finish

	-- PreSimulation = runs right before physics step, so velocity is applied same frame (no 1-frame lag)
	connection = RunService.PreSimulation:Connect(function()
		local alpha = (os.clock() - startTime) / duration
		if alpha >= 1 or not root.Parent or humanoid.Health <= 0 then
			finish()
			return
		end

		local speed = peakSpeed * (1 - alpha)
		velocity.PlaneVelocity = Vector2.new(dir.X * speed, dir.Z * speed)
	end)

	return true
end

return Dash