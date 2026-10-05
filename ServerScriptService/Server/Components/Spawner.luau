local CS = game:GetService("CollectionService")
local RS = game:GetService("ReplicatedStorage")
local HS = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Packages = RS.Packages

local Component = require(Packages.Component)


local Assets = RS.Assets.SpawnItems


local Spawner = Component.new({Tag = "Spawner"})


------- Config
local MAX_RETRIES = 50
local minItemsGap = 5 -- minItemsGap
local groundClearence = 0.5
local sizeMultiplier = 1.1 -- sizeMultiplier
local defaultSpawnDelayTime = NumberRange.new(1, 4)
local defaultLimits = {
	Landmine = 5,
	Dash = 5,
	SpeedBoost = 5,
	Collectible = 5,
}
------- Config



type spawnItemType = {
	obj :Instance,
	pos :Vector3,
	typ :string,
}

-- "Idle"    = not started / stopped
-- "Running" = timer active (or waiting for a free slot)
-- "Paused"  = frozen, remaining delay preserved
type SpawnerState = "Idle" | "Running" | "Paused"

----Global spawn-items
local globalSpawnedItems = {}


----------- Calculations ------------------


-- Cache restricted areas outside the loop for performance
local restrictedAreas = CS:GetTagged("RestrictedArea")
local CollectionService = game:GetService("CollectionService")

-- Configuration (adjust as needed)
local MAX_RETRIES = 50
local rng = Random.new()

-- Safe removal: table.remove(t, nil) removes the LAST element, so always check find() first
local function RemoveValue(t: {any}, value: any)
	local idx = table.find(t, value)
	if idx then
		table.remove(t, idx)
	end
end

local function GetRandomPos(spawner: BasePart, targetModel: Instance, spawnedObjects: {Instance})
	-- 1. Pre-calculate Spawner Bounds
	local sPos, sSize = spawner.Position, spawner.Size
	local minX, maxX = sPos.X - sSize.X/2, sPos.X + sSize.X/2
	local minZ, maxZ = sPos.Z - sSize.Z/2, sPos.Z + sSize.Z/2

	-- 2. Get Target Size
	local tSize = (targetModel:IsA("Model")) and targetModel:GetExtentsSize() or targetModel.Size

	-- 3. Collision Setup
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	-- Exclude the spawner itself and existing spawned objects from collision check 
	-- (We handle spawnedObjects separately via distance check, or add them here)
	overlapParams.FilterDescendantsInstances = {spawner, targetModel} 

	local restrictedAreas = CollectionService:GetTagged("RestrictedArea")
	local finalPos = nil
	local attempts = 0

	repeat
		attempts += 1

		-- Generate a candidate position
		-- Note: We subtract tSize/2 from the range to ensure the edges of the object stay inside the spawner
		local candidatePos = Vector3.new(
			rng:NextNumber(minX + tSize.X/2, maxX - tSize.X/2),
			sPos.Y - sSize.Y/2 + tSize.Y/2 + (groundClearence or 0),
			rng:NextNumber(minZ + tSize.Z/2, maxZ - tSize.Z/2)
		)

		local isInvalid = false

		-- CHECK 1: Distance from existing objects
		for _, itm in ipairs(spawnedObjects) do
			if not itm or (itm:IsA("Model") and not itm.PrimaryPart) then continue end
			local otherPos = itm:IsA("Model") and itm:GetPivot().Position or itm.Position

			if (candidatePos - otherPos).Magnitude < (minItemsGap or 5) then
				isInvalid = true
				break
			end
		end

		-- CHECK 2: Collision with environment (Static obstacles)
		if not isInvalid then
			local checkBounds = tSize * (sizeMultiplier or 1.1)
			local collisions = workspace:GetPartBoundsInBox(CFrame.new(candidatePos), checkBounds, overlapParams)
			if #collisions > 0 then
				isInvalid = true
			end
		end

		-- CHECK 3: Restricted Areas
		if not isInvalid then
			for _, area in ipairs(restrictedAreas) do
				--if CF:PosLiesInArea(area, candidatePos) then
				--	isInvalid = true
				--	break
				--end
			end
		end

		-- SUCCESS: If we passed all checks
		if not isInvalid then
			finalPos = candidatePos
		end

	until finalPos ~= nil or attempts >= MAX_RETRIES

	-- Fallback: If no perfect spot found, return the last candidate generated 
	-- to ensure the script never returns nil/breaks.
	return finalPos or Vector3.new(rng:NextNumber(minX, maxX), sPos.Y, rng:NextNumber(minZ, maxZ))
end

local function GetRandomItem(itemsList, spawningLimits, mySpawnedItems)
	local list = table.clone(itemsList)

	--Filter items that reached max-limit from the "list"
	for i, typeList in pairs(mySpawnedItems) do
		if(#typeList >= spawningLimits[i]) then
			RemoveValue(list, i)
		end
	end

	--Get random item from remaining list
	if(#list < 1) then
		return nil
	end

	return list[math.random(1, #list)]
end
----------- Calculations ------------------




------------------------------------------------------------------
-- Lifecycle
------------------------------------------------------------------
function Spawner:Construct()

	self.MySpawnedItems = {}
	self.SpawnedObjects = {}
	self.SpawningLimits = table.clone(defaultLimits)
	self.DelayBetweenSpawns = defaultSpawnDelayTime :: NumberRange
	self.SpawnableItems = {"Landmine", "Dash", "SpeedBoost", "Collectible"}

	--Timer state
	self._state = "Idle" :: SpawnerState
	self._timer = nil :: thread?       -- active task.delay handle (nil = nothing scheduled)
	self._fireAt = 0                   -- os.clock() when the active timer fires
	self._pausedRemaining = nil :: number? -- seconds left when paused

	--Calculations
	self.MaxItemsAllowed = self.Instance:GetAttribute("MaxItemsAllowed")
	if(not self.MaxItemsAllowed) then
		self.MaxItemsAllowed = 0
		for i, v in pairs(self.SpawningLimits) do
			self.MaxItemsAllowed += v
		end
	end

	--Init MySpawnedItems
	for i, v in pairs(self.SpawnableItems) do
		self.MySpawnedItems[v] = {}
	end
end


-- Non-blocking now: just kicks off the timer chain and returns.
-- Set attribute "AutoStart" = false on the spawner part to start it manually later.
function Spawner:Start()
	if self.Instance:GetAttribute("AutoStart") == false then
		return
	end
	self:StartSpawning()
end


-- Component lifecycle: spawner removed/destroyed -> kill timer
function Spawner:Stop()
	self:StopSpawning()
end


------------------------------------------------------------------
-- Runtime controls (call these from your game logic)
------------------------------------------------------------------

-- Idle -> Running (or Paused -> Running). No-op if already running.
function Spawner:StartSpawning()
	warn("Spawner:StartSpawning", self._state)
	if self._state == "Running" then return end

	if self._state == "Paused" then
		self:ResumeSpawning()
		return
	end

	self._state = "Running"
	self:_Schedule(0)
end

-- Hard stop: cancels timer, forgets remaining delay. Spawned items stay.
function Spawner:StopSpawning()
	warn("Spawner:StopSpawning", self._state)
	self._state = "Idle"
	self._pausedRemaining = nil
	self:_CancelTimer()
end

-- Freeze: keeps the remaining delay so Resume continues where it left off.
function Spawner:PauseSpawning()
	if self._state ~= "Running" then return end
	self._state = "Paused"

	if self._timer then
		self._pausedRemaining = math.max(self._fireAt - os.clock(), 0)
		self:_CancelTimer()
	end
end

function Spawner:ResumeSpawning()
	if self._state ~= "Paused" then return end
	self._state = "Running"

	local remaining = self._pausedRemaining
	self._pausedRemaining = nil

	if remaining then
		self:_Schedule(remaining)
	elseif #self.SpawnedObjects < self.MaxItemsAllowed then
		--Was waiting for a free slot while paused, a slot may have opened since
		self:_Schedule(self:_GetDelay())
	end
end

function Spawner:IsSpawning(): boolean
	return self._state == "Running"
end

function Spawner:GetState(): SpawnerState
	return self._state
end

-- Destroys everything this spawner made. Pass true to restart the timer afterwards.
function Spawner:ClearAllSpawns(restart: boolean?)
	self:StopSpawning()

	--Clone: Destroying handler mutates SpawnedObjects while we iterate
	for _, v in ipairs(table.clone(self.SpawnedObjects)) do
		v:Destroy()
	end

	if restart then
		self:StartSpawning()
	end
end


------------------------------------------------------------------
-- Timer internals (task.delay + task.cancel, no polling)
------------------------------------------------------------------
function Spawner:_GetDelay(): number
	local d = self.DelayBetweenSpawns
	if typeof(d) == "NumberRange" then
		return rng:NextNumber(d.Min, d.Max) -- math.random would floor floats
	end
	return d
end

function Spawner:_CancelTimer()
	if self._timer then
		task.cancel(self._timer)
		self._timer = nil
	end
end

-- Only ONE timer can exist at a time, scheduling replaces any pending one
function Spawner:_Schedule(delay: number)
	self:_CancelTimer()

	self._fireAt = os.clock() + delay
	self._timer = task.delay(delay, function()
		self._timer = nil -- clear first so Stop/Pause inside _Tick never cancels the running thread
		self:_Tick()
	end)
end

function Spawner:_Tick()
	if self._state ~= "Running" then return end
	if #self.SpawnedObjects >= self.MaxItemsAllowed then return end -- wait for _OnItemRemoved

	local spawned = self:SpawnItem()

	-- Chain next spawn only if there's room. Otherwise sleep (zero cost)
	-- until an item is removed -> _OnItemRemoved wakes us up.
	if spawned and #self.SpawnedObjects < self.MaxItemsAllowed then
		self:_Schedule(self:_GetDelay())
	end
end

-- A slot opened up: restart the chain if it went to sleep
function Spawner:_OnItemRemoved()
	if self._state == "Running" and not self._timer then
		self:_Schedule(self:_GetDelay())
	end
end


------------------------------------------------------------------
-- Spawning
------------------------------------------------------------------
function Spawner:SpawnItem()
	--Get random itemType to spawn
	local itemType = GetRandomItem(self.SpawnableItems, self.SpawningLimits, self.MySpawnedItems)

	if(not itemType) then return nil end

	--Fetch respective model
	local itemModel = Assets:FindFirstChild(itemType)
	if(not itemModel) then
		warn(("[Spawner] Missing asset '%s' in SpawnItems"):format(itemType))
		return nil
	end

	--Get random pos inside the spawner
	local ramPos = GetRandomPos(self.Instance, itemModel, self.SpawnedObjects)

	--unique spawnId
	local spawnId = HS:GenerateGUID(false)

	--Clone new item and setup
	local NewModel :Model = itemModel:Clone()
	NewModel.Parent = self.Instance
	NewModel:PivotTo(CFrame.new(ramPos))
	NewModel.Name = NewModel.Name.."_Cloned"

	NewModel:SetAttribute("SpawnId", spawnId)

	local spawnedItem :spawnItemType = {}
	spawnedItem.pos = ramPos
	spawnedItem.obj = NewModel
	spawnedItem.typ = itemType

	--Removing event
	NewModel.Destroying:Connect(function()
		RemoveValue(globalSpawnedItems, spawnedItem)
		RemoveValue(self.SpawnedObjects, NewModel)
		RemoveValue(self.MySpawnedItems[itemType], spawnedItem) -- was searching self.MySpawnedItems (wrong table)

		self:_OnItemRemoved()
	end)

	table.insert(globalSpawnedItems, spawnedItem) --Update global table
	table.insert(self.SpawnedObjects, NewModel) --Update own spawned model objects
	table.insert(self.MySpawnedItems[itemType], spawnedItem) --Update MySpawnedItems table

	--_G.Warn("Item Spawned, type:", spawnedItem)
	return NewModel
end

return Spawner