local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local EarthSplitter = {}

--==================================================
-- Configuration
--==================================================
local MoveConfig = {
	Distance = 45,               
	Duration = 0.75,             

	BallColor = Color3.fromRGB(170, 0, 255), 
	BallSize = Vector3.new(7, 7, 7),

	DebrisSpacing = 2,           
	DebrisOffset = 5,            
	DebrisLingerTime = 2,        
	DebrisSinkDuration = 1.5,    

	DebrisScaleStart = 0.3,      
	DebrisScaleEnd = 1.6,        
}

local vfxDebris = workspace.Terrain:FindFirstChild("VFX") or workspace.Terrain

--==================================================
-- Private Execution Functions
--==================================================

function EarthSplitter:_spawnEnergyBall(startCFrame: CFrame): (Instance, boolean)
	local customBallTemplate = script:FindFirstChildWhichIsA("Model") or script:FindFirstChildWhichIsA("BasePart")

	local ball
	local isModel = false

	if customBallTemplate then
		ball = customBallTemplate:Clone()
		isModel = ball:IsA("Model")

		if isModel then
			ball:PivotTo(startCFrame)
		else
			ball.CFrame = startCFrame
		end
	else
		ball = Instance.new("Part")
		ball.Name = "EnergyTearBall"
		ball.Shape = Enum.PartType.Ball
		ball.Size = MoveConfig.BallSize
		ball.Color = MoveConfig.BallColor
		ball.Material = Enum.Material.Neon

		ball.Anchored = true
		ball.CanCollide = false
		ball.CanQuery = false
		ball.CFrame = startCFrame

		local light = Instance.new("PointLight")
		light.Color = MoveConfig.BallColor
		light.Brightness = 3
		light.Range = 15
		light.Parent = ball
	end

	ball.Parent = vfxDebris
	return ball, isModel
end

-- OPTIMIZATION: raycastParams is now passed by reference to avoid recreating it per rock
function EarthSplitter:_createSingleDebris(originPos: Vector3, scaleMultiplier: number, raycastParams: RaycastParams): BasePart?
	-- Increased the downward cast to -60 to ensure we find the ground even if the ball is elevated on a bridge
	local rayResult = workspace:Raycast(originPos + Vector3.new(0, 5, 0), Vector3.new(0, -10, 0), raycastParams)

	-- FIX: If raycast misses (off the edge of the map), return nil so we don't spawn floating rocks
	if not rayResult then
		return nil
	end

	local targetPos = rayResult.Position
	local floorColor = rayResult.Instance.Color
	local floorMaterial = rayResult.Instance.Material

	local rock = Instance.new("Part")
	rock.Name = "TearDebris"

	local targetSize = Vector3.new(math.random(2, 4), math.random(2, 4), math.random(2, 4)) * scaleMultiplier
	rock.Size = targetSize

	rock.Anchored = true
	rock.CanCollide = false
	rock.Color = floorColor
	rock.Material = floorMaterial

	local randomRotation = CFrame.Angles(
		math.rad(math.random(-65, 65)),
		math.rad(math.random(0, 360)),
		math.rad(math.random(-65, 65))
	)

	local finalCFrame = CFrame.new(targetPos) * randomRotation

	rock.CFrame = finalCFrame * CFrame.new(0, -targetSize.Y, 0)
	rock.Parent = vfxDebris

	TS:Create(rock, TweenInfo.new(0.2, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
		CFrame = finalCFrame
	}):Play()

	return rock
end

function EarthSplitter:_spawnDebrisPair(centerCFrame: CFrame, scaleMultiplier: number, raycastParams: RaycastParams): table
	local newDebris = {}

	local leftOrigin = centerCFrame.Position + (-centerCFrame.RightVector * MoveConfig.DebrisOffset)
	local rightOrigin = centerCFrame.Position + (centerCFrame.RightVector * MoveConfig.DebrisOffset)

	local leftRock = self:_createSingleDebris(leftOrigin, scaleMultiplier, raycastParams)
	local rightRock = self:_createSingleDebris(rightOrigin, scaleMultiplier, raycastParams)

	if leftRock then table.insert(newDebris, leftRock) end
	if rightRock then table.insert(newDebris, rightRock) end

	return newDebris
end

function EarthSplitter:_cleanupBall(ball: Instance, isModel: boolean)
	if not ball or not ball.Parent then return end

	if isModel then
		local currentScale = ball:GetScale() 
		local scaleValue = Instance.new("NumberValue")
		scaleValue.Value = currentScale

		local scaleConnection = scaleValue.Changed:Connect(function(val)
			ball:ScaleTo(math.max(val, 0.001))
		end)

		local shrinkTween = TS:Create(scaleValue, TweenInfo.new(0.15), {Value = 0.001})
		shrinkTween.Completed:Connect(function()
			scaleConnection:Disconnect()
			scaleValue:Destroy()
			ball:Destroy()
		end)
		shrinkTween:Play()
	else
		local shrinkTween = TS:Create(ball, TweenInfo.new(0.15), {Size = Vector3.new(0.001, 0.001, 0.001)})
		shrinkTween.Completed:Connect(function()
			ball:Destroy()
		end)
		shrinkTween:Play()
	end
end

function EarthSplitter:_sinkAndDestroyDebris(debrisList: table)
	local sinkTweenInfo = TweenInfo.new(MoveConfig.DebrisSinkDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	for _, rock in ipairs(debrisList) do
		if rock and rock.Parent then
			local sinkTarget = rock.CFrame * CFrame.new(0, -rock.Size.Y - 5, 0)
			local sinkTween = TS:Create(rock, sinkTweenInfo, {
				CFrame = sinkTarget,
				Transparency = 1 
			})

			sinkTween:Play()
			Debris:AddItem(rock, MoveConfig.DebrisSinkDuration + 0.1)
		end
	end
end

--==================================================
-- Public Trigger
--==================================================

function EarthSplitter:PerformMove(startCFrame: CFrame, scaleDebrisOverTime: boolean?)
	local ball, isModel = self:_spawnEnergyBall(startCFrame)
	local totalDistance = MoveConfig.Distance
	local duration = MoveConfig.Duration
	local debrisList = {}

	local spawnedDebrisCount = 0
	local expectedTotalSpawns = math.floor(totalDistance / MoveConfig.DebrisSpacing)

	-- 1. Create a single shared RaycastParams object for maximum performance
	local sharedRayParams = RaycastParams.new()
	local excludes = {vfxDebris}
	local charFolder = workspace:FindFirstChild("Scriptables") and workspace.Scriptables:FindFirstChild("Characters")
	if charFolder then table.insert(excludes, charFolder) end
	sharedRayParams.ExcludeInstances = excludes
	sharedRayParams.FilterType = Enum.RaycastFilterType.Exclude

	-- 2. Detect the baseline Ground Y at the start position
	local startRay = workspace:Raycast(startCFrame.Position + Vector3.new(0, 5, 0), Vector3.new(0, -15, 0), sharedRayParams)
	local startGroundY = startRay and startRay.Position.Y or startCFrame.Position.Y

	local currentY = startCFrame.Y
	local elapsed = 0
	local connection

	connection = RunService.Heartbeat:Connect(function(dt)
		if not ball or not ball.Parent then
			if connection then connection:Disconnect() end
			return
		end

		elapsed += dt
		local alpha = math.clamp(elapsed / duration, 0, 1)

		local currentDist = totalDistance * alpha
		local flatCFrame = startCFrame * CFrame.new(0, 0, -currentDist)

		-- 3. Check the ground height directly beneath the ball's current horizontal position
		local checkRay = workspace:Raycast(flatCFrame.Position + Vector3.new(0, 5, 0), Vector3.new(0, -10, 0), sharedRayParams)
		local groundY = checkRay and checkRay.Position.Y or startGroundY

		-- 4. Calculate terrain elevation (Ignores dips/pits below baseline entirely)
		local elevation = math.max(0, groundY - startGroundY)
		local targetY = startCFrame.Y + elevation

		-- 5. Smoothly glide the ball up stairs/bridges so it doesn't snap instantly
		currentY = currentY + (targetY - currentY) * math.min(1, dt * 15)

		-- Reconstruct the CFrame with the new elevated Y
		local currentCFrame = flatCFrame - Vector3.new(0, flatCFrame.Y, 0) + Vector3.new(0, currentY, 0)

		if isModel then
			ball:PivotTo(currentCFrame)
		else
			ball.CFrame = currentCFrame
		end

		-- Spawn Debris 
		local expectedSpawns = math.floor(currentDist / MoveConfig.DebrisSpacing)
		while spawnedDebrisCount < expectedSpawns do
			spawnedDebrisCount += 1

			local progress = expectedTotalSpawns > 1 and ((spawnedDebrisCount - 1) / (expectedTotalSpawns - 1)) or 1
			local scaleMult = 1

			if scaleDebrisOverTime then
				scaleMult = MoveConfig.DebrisScaleStart + ((MoveConfig.DebrisScaleEnd - MoveConfig.DebrisScaleStart) * progress)
			end

			-- Spawn exact checkpoints along the calculated 3D path
			local spawnCF = startCFrame * CFrame.new(0, 0, -spawnedDebrisCount * MoveConfig.DebrisSpacing)

			-- Pass the sharedRayParams to avoid memory reallocation
			local spawnedRocks = self:_spawnDebrisPair(spawnCF, scaleMult, sharedRayParams)

			for _, rock in ipairs(spawnedRocks) do
				table.insert(debrisList, rock)
			end
		end

		-- Execution completion condition
		if alpha >= 1 then
			connection:Disconnect()
			self:_cleanupBall(ball, isModel)

			task.delay(MoveConfig.DebrisLingerTime, function()
				self:_sinkAndDestroyDebris(debrisList)
			end)
		end
	end)
end

return EarthSplitter