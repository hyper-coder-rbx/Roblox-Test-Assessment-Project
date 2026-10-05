local RS = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TS = game:GetService("TweenService")

local Knit = require(RS.Packages.Knit)

local CD = require(RS.Shared.Constants)
local Enums = require(RS.Shared.Enums)
local EarthSplitter = require(script.EarthSplitter)




local EffectController = {}

--============================================--
--             HELPER-METHODS
--============================================--

local function _getHitEffectCF2(aPos:Vector3, vPos:Vector3, upperBody:boolean)
	local offset = (upperBody) and Vector3.new(0, 1, 0) or Vector3.new(0, 0, 0)

	local effectPosition =  aPos:Lerp(vPos, 0.5) + offset

	local lookAtTarget = Vector3.new(vPos.X, effectPosition.Y, vPos.Z)

	return CFrame.lookAt(effectPosition, lookAtTarget)
end

local function _getHitEffectCF(aPos, vPos, upperBody :boolean)
	local attackerPos = aPos
	local victimPos = vPos

	local midPoint = victimPos + ((attackerPos - victimPos) * 0.5)
	local effectPosition = midPoint + (upperBody and Vector3.new(0, 1, 0) or Vector3.zero)

	local lookAtTarget = Vector3.new(victimPos.X, effectPosition.Y, victimPos.Z)

	return CFrame.lookAt(effectPosition, lookAtTarget)
end

local function _getVFX(name:string, cf:CFrame)
	local vfx = script.Effects:FindFirstChild(name)
	if not vfx then
		return nil
	end

	vfx = vfx:Clone()

	if(cf) then
		if(vfx:IsA("Attachment")) then
			vfx.WorldCFrame = cf
		elseif(vfx:IsA("BasePart")) then
			vfx:PivotTo(cf)
		end
	end

	return vfx, workspace.Terrain.VFX
end

--============================================--
--             EXECUTOR METHODS
--============================================--

function _emitEffect(effect:Instance, vfxScaleType:string?, timescale:number?)
	timescale = timescale or 1
	vfxScaleType = vfxScaleType or ""

	local particleFolder = effect:FindFirstChild("Particles") or effect
	local maxUptime = 0

	if particleFolder then
		for _, pe in pairs(particleFolder:GetDescendants()) do
			if pe:IsA("ParticleEmitter") then
				local emitCount = pe:GetAttribute("EmitCount") or 1
				local _delay = pe:GetAttribute("EmitDelay") or 0
				local customColor = pe:GetAttribute(vfxScaleType)

				if customColor then
					pe.Color = ColorSequence.new(customColor)
				end

				--TODO: implement it later
				--if scaleMultiplier ~= 1 then
				--	local newKeypoints = {}
				--	for _, kp in ipairs(pe.Size.Keypoints) do
				--		local newSize = math.max(0, kp.Value * scaleMultiplier)
				--		local newEnvelope = math.max(0, kp.Envelope * scaleMultiplier)
				--		table.insert(newKeypoints, NumberSequenceKeypoint.new(kp.Time, newSize, newEnvelope))
				--	end
				--	pe.Size = NumberSequence.new(newKeypoints)
				--end

				local totalLife = _delay + pe.Lifetime.Max
				if totalLife > maxUptime then
					maxUptime = totalLife
				end

				if _delay > 0 then
					task.delay(_delay, function()
						if pe and pe.Parent then
							pe:Emit(emitCount)
							pe.TimeScale *= timescale
						end
					end)
				else
					pe:Emit(emitCount)
					pe.TimeScale *= timescale
				end
				
			elseif pe:IsA("Light") then
				pe.Enabled = true
			end
		end
	end

	Debris:AddItem(effect, maxUptime + 0.5)
end

function EffectController:Play(vName:string, vCF:CFrame)
	--print("Playing VFX", vName, vCF)
	local vfx :Attachment, parent = _getVFX(vName, vCF)
	if not vfx then
		warn(`ERROR - VFX not found: {vName}`)
		return
	end

	vfx.Parent = parent

	--Play VFX
	_emitEffect(vfx)

end


--============================================--
--             GENERAL-EFFECTS
--============================================--

function EffectController:TrailsEffect(char:Model, enable:boolean)
	local onCount = char:GetAttribute("TrailsOnCount") or 0
	
	if(enable == true) then
		onCount += 1
	else
		onCount = math.max(onCount - 1, 0)
		char:SetAttribute("TrailsOnCount", onCount)
		if(onCount > 0) then
			return
		end
	end
	
	local trails = char.Trails
	local highlight = char:FindFirstChildOfClass("Highlight")

	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0.25
	highlight.Enabled = (enable == true)

	for i, t in pairs(trails:GetChildren()) do
		t.Enabled = (enable == true)
	end

end

function EffectController:SpawnLandingSmash(cf:CFrame)
	local name = "LandingSmash"
	local vfx :Attachment, parent = _getVFX(name, cf)

	if not vfx then
		warn(`ERROR - VFX not found: {name}`)
		return
	end

	task.spawn( function()

		vfx.Parent = parent
		_emitEffect(vfx)
	end)
end

--============================================--
--             ABILITIES
--============================================--

function EffectController:AbilityEffect(char:Model, actionSide:string, abilityID:string)

	--Get VFX position
	local aPos = char.PrimaryPart.Position + char.PrimaryPart.CFrame.LookVector * 1
	local vPos = aPos + char.PrimaryPart.CFrame.LookVector
	local vfxCf = CFrame.lookAt(aPos, vPos)
	
	if(abilityID == CD.AnimationMod.Abilities.A_A.UID) then
		EarthSplitter:PerformMove(vfxCf, true)
		
	elseif(abilityID == CD.AnimationMod.Abilities.A_B.UID) then
		local name = "HeavyHit"
		local vfx :Part|Attachment, defaultParent = _getVFX(name, vfxCf)

		if not vfx then
			warn(`ERROR - VFX not found: {name}`)
			return
		end
		
		--Play VFX
		task.spawn( function()
			vfx.Parent = defaultParent
			_emitEffect(vfx)
		end)
		
	elseif(abilityID == CD.AnimationMod.Abilities.A_C.UID) then
		local name = "SkitBrust"
		local vfx :Part|Attachment, defaultParent = _getVFX(name, vfxCf)
		
		if not vfx then
			warn(`ERROR - VFX not found: {name}`)
			return
		end
		
		--Play VFX
		task.spawn( function()
			local endAtt :Attachment= vfx.EndAtt
			endAtt.WorldCFrame = vfxCf
			
			local info = TweenInfo.new(0.5)
			local tween = TS:Create(vfx.Particles, info, {WorldCFrame = vfxCf * CFrame.new(0, 0, -15)})
			
			tween.Completed:Once(function()
				for i, v in pairs(vfx.Particles:GetChildren()) do
					if(v:IsA("Beam")) then
						v.Enabled = false
					end
				end
				_emitEffect(vfx)
				
			end)
			
			vfx.Parent = defaultParent
			
			tween:Play()
		end)
	end
	
end


return EffectController