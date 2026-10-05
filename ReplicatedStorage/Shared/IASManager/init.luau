--[[
Works for local player only for now. 

TODO: Need to think of a way to make it work for multiple players (on server).
]]

type ActionTemplate = typeof(script.ActionTemplate)

local function getPlayer(obj:Instance?)
	obj = obj or game.Players.LocalPlayer --nil in case of server
	if(not obj) then
		return nil
	end
	
	local plr = obj:IsA("Player") and obj or obj:FindFirstAncestorOfClass("Player") or game.Players.LocalPlayer
	return plr
end

local function setProps(ins:Instance, props:{any})

	for k, v in pairs(props) do
		if(ins[k] ~= nil) then
			ins[k] = v
		end
	end
	
end

local function getEmptyAction()
	return script.ActionTemplate:Clone()
end

local function getCustomInputs()
	return script.CustomInputs:Clone()
end


local IC = {}
IC.__index = IC

function IC.new(context:InputContext) : typeof(IC)
	
	local self = setmetatable({}, IC)
	
	self.context = context
	
	return self
end

function IC:IsActive() : boolean
	local context:InputContext = self.context
	
	return context.Enabled
end

function IC:Toggle(enable:boolean?) : boolean
	local context:InputContext = self.context
	
	if(enable == nil) then
		enable = not context.Enabled
	end
	
	context.Enabled = enable
	return context.Enabled
end

function IC:Set(props:{}) :boolean
	local context:InputContext = self.context
	
	setProps(context, props)
	
	return true
end

function IC:OnEnableChanged() : RBXScriptSignal?
	local context:InputContext = self.context
	
	return context:GetPropertyChangedSignal("Enabled")
end

function IC:GetAction(aName:string, queryOnly:boolean?) : ActionTemplate?
	local context:InputContext = self.context
	
	local iAction = context:FindFirstChild(aName)
	
	if(not iAction and not queryOnly) then
		iAction = getEmptyAction()
		iAction.Name = aName
		iAction.Parent = context
	end
	
	return iAction or nil
end

function IC:Destroy(aName:string)
	local context:InputContext = self.context

	self:Toggle(false)
	context:Destroy()
	self = nil
end

type ContextModuleType = typeof(IC)



local IASManager = {}
local activeICs :{[Player] : {[string] : ContextModuleType}} = {}


local function tryResolvePlayer(obj:Instance?)
	local plr = getPlayer(obj)
	if(not plr) then
		return nil
	end

	if(not activeICs[plr]) then
		activeICs[plr] = {}
	end
	
	return plr
end

function IASManager.new(contextName:string, parent:Instance?) : ContextModuleType
	local plr :Player = tryResolvePlayer(parent)
	if(not plr) then
		warn("parent must be a player or a descendant of a player object.", parent)
		return false
	end
	
	--Create new InputContext object under player
	local correctParent = parent do
		if(parent:IsA("Player")) then
			correctParent = parent:FindFirstChild("CustomInputs") --parent:WaitForChild("CustomInputs", 2) ~Simulation don't allow waitfochild
			if(not correctParent) then
				correctParent = getCustomInputs()
				correctParent.Parent = plr
			end
		end
	end
	local context = correctParent:FindFirstChild(contextName) or Instance.new("InputContext")
	context.Name = contextName
	context.Parent = correctParent
	
	--register as ic module now
	local ic = IASManager.register(context)
	
	return ic
end

function IASManager.setupDefault(plr:Player?) : boolean
	local plr = tryResolvePlayer(plr)
	if(not plr) then
		warn("player object not found to setup")
		return false
	end

	--Clone default input contexts
	local customInputs = plr:FindFirstChild("CustomInputs") or getCustomInputs()
	customInputs.Parent = plr
	
	--Register all to IASManager
	for i, c in pairs(customInputs:GetChildren()) do
		if(c:IsA("InputContext")) then
			IASManager.register(c)
		end
	end
	
	return true
end

function IASManager.register(context:InputContext) : ContextModuleType
	local plr = tryResolvePlayer(context)
	if(not plr) then
		warn("parent must be a player or a descendant of a player object.", context)
		return false
	end
	
	local existing = activeICs[plr][context.Name]
	if(existing) then
		warn("Same name input context is already present:", existing.context)
		return false
	end
	
	local name = context.Name
	local ic = IC.new(context)

	activeICs[plr][name] = ic
	context:GetPropertyChangedSignal("Name"):Connect(function()
		--try to check if it was renamed in explorer
		local newName = context.Name
		if(newName == name) then
			return
		end
		--check if newName already occupied or not
		if(activeICs[plr][newName]) then
			warn(`Error: context's new name voilates the unique name rule. Reverting to previous name: {name}`)
			context.Name = name
			return
		end
		
		--approve and update in cache
		activeICs[plr][name] = nil
		
		name = context.Name
		activeICs[plr][context.Name] = ic
	end)

	return ic
end

function IASManager.getContext(contextName:string, parent:Player|Instance?, queryOnly:boolean?) : ContextModuleType
	local plr = tryResolvePlayer(parent)
	if(not plr) then
		warn("player object not found for context", contextName)
		return false
	end

	local ic = activeICs[plr][contextName]

	if not ic then
		-- Fallback: Check if it already exists in the player's CustomInputs folder
		local customInputs = plr:FindFirstChild("CustomInputs")
		if customInputs then
			local existingContext = customInputs:FindFirstChild(contextName)
			if existingContext then
				-- Context exists in Explorer but isn't cached yet. Register it.
				ic = IASManager.register(existingContext)
			end
		end

		-- If still not found, and we are NOT just querying, create a brand new one
		if not ic and not queryOnly then
			ic = IASManager.new(contextName, parent)
		end
	end

	return ic or nil
end

function IASManager.setContextProps(contextName:string, props:{any}, parent:Player|Instance?) : boolean
	local ic = IASManager.getContext(contextName, parent, true)
	
	if(ic) then
		ic:Set(props)
		
		return true
	end
	
	return false
end

function IASManager.toggleContext(contextName:string, enable:boolean?, parent:Player|Instance?) : boolean
	local ic = IASManager.getContext(contextName, parent, true)

	if(ic) then
		return ic:Toggle(enable)
	end
	
	return false
end

function IASManager.getAction(contextName:string, actionName:string, parent:Player|Instance?) : ActionTemplate | nil
	local ic = IASManager.getContext(contextName, parent)
	
	if(ic) then
		local iAction = ic:GetAction(actionName)
		
		return iAction
	end
	
	return nil
end

function IASManager.unregister(contextName:string, plr:Player?) : boolean
	plr = tryResolvePlayer(plr)
	if(not plr) then
		warn("player object not found for context", contextName)
		return false
	end

	activeICs[plr][contextName] = nil
	return true
end

function IASManager.destroyContext(contextName:string, plr:Player?) : boolean
	plr = tryResolvePlayer(plr)
	if(not plr) then
		warn("player object not found for context", contextName)
		return false
	end

	local ic = activeICs[plr][contextName]
	if(ic) then
		ic:Destroy()
	end
	
	activeICs[plr][contextName] = nil
	return true
end

function IASManager.clearPlayer(plr:Player?) : boolean
	plr = tryResolvePlayer(plr)
	if(not plr) then
		return false
	end
	
	for i, v in pairs(activeICs[plr]) do
		v:Destroy()
	end
	
	activeICs[plr] = nil
	return true
end



if game.RunService:IsServer() then
	game.Players.PlayerRemoving:Connect(function(plr)
		IASManager.clearPlayer(plr)
	end)
end

return IASManager
