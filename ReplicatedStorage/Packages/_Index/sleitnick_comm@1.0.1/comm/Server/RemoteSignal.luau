-- RemoteSignal
-- Stephen Leitnick
-- December 20, 2021

local Players = game:GetService("Players")

local Signal = require(script.Parent.Parent.Parent.Signal)
local Types = require(script.Parent.Parent.Types)


--[=[
	@class RemoteSignal
	@server
	Created via `ServerComm:CreateSignal()`.
]=]
local RemoteSignal = {}
RemoteSignal.__index = RemoteSignal

--[=[
	@within RemoteSignal
	@interface Connection
	.Disconnect () -> nil
	.Connected boolean

	Represents a connection.
]=]

function RemoteSignal.new(
	parent: Instance,
	name: string,
	unreliable: boolean?,
	extra :{expectedArgs:{any}?, limits:Types.SignalLimits?}?,
	inboundMiddleware: Types.ServerMiddleware?,
	outboundMiddleware: Types.ServerMiddleware?
)
	local self = setmetatable({}, RemoteSignal)
	self._re = if unreliable == true then Instance.new("UnreliableRemoteEvent") else Instance.new("RemoteEvent")
	self._re.Name = name
	self._re.Parent = parent
	self._history = {}
	
	if(extra) then
		print("Event is secured")
		self._secured = true
		local expectedArgs = extra.expectedArgs
		local limits :Types.SignalLimits = extra.limits or {}
		
		--Defaults
		limits.AllowMissingArgs = limits.AllowMissingArgs or false
		limits.BrustTolerance = limits.BrustTolerance or 10
		limits.PunishThreshold = limits.PunishThreshold or 20

		-- Per-player stats
		local history = self._history
		
		self._signal = Signal.new()
		self._re.OnServerEvent:Connect(function(player, ...)
			local args = {...}
			local argCount = #args
			
			history[player] = history[player] or {
				windowStart = 0,
				burst = 0,
				total = 0,
			}

			---------------------------------------
			-- 1. Secure argument validation
			---------------------------------------
			if expectedArgs and type(expectedArgs) == "table" then
				--print("has expected args:", expectedArgs)
				local expectedCount = #expectedArgs

				if not limits.AllowMissingArgs and argCount ~= expectedCount then
					print("[SecurityBreach] Missing arguments")
					return -- soft fail
				end

				if argCount > expectedCount then
					print("[SecurityBreach] Argument count exceeds expected limit.")
					return -- too many args → safe ignore
				end

				for i = 1, math.min(argCount, expectedCount) do
					local expected = expectedArgs[i]
					local value = args[i]
					local actualType = typeof(value)

					if actualType ~= expected then
						-- Special case: Instance class check
						if actualType == "Instance" and value:IsA(expected) then
							continue
						end
						print("[SecurityBreach] Invalid argument type at index " .. i .. ": expected " .. expected .. ", got " .. actualType .. ".")
						return -- bad type → ignore only
					end
				end
			end

			---------------------------------------
			-- 2. Anti-spam & exploit detector
			---------------------------------------
			do
				local now = os.clock()
				local h = history[player]

				-- If 1 second has passed, reset the window
				if (now - h.windowStart) >= 1 then
					h.windowStart = now
					h.burst = 0
				end

				h.burst += 1

				-- Check limits
				if h.burst > limits.BrustTolerance then
					print("Burst limit exceeded for " .. player.Name .. ": " .. h.burst .. " per second.")

					if h.burst > limits.PunishThreshold then
						print("Kicking " .. player.Name .. " for spamming.")
						player:Kick("Malicious RemoteEvent attempt detected. Don't try again or you will be banned.")
						return
					end

					return -- Ignore event execution
				end
			end
			
			self._signal:Fire(player, table.unpack(args))
		end)
	else
		self._secured = false
	end
	
	if outboundMiddleware and #outboundMiddleware > 0 then
		self._hasOutbound = true
		self._outbound = outboundMiddleware
	else
		self._hasOutbound = false
	end
	
	
	if inboundMiddleware and #inboundMiddleware > 0 then
		self._directConnect = false
		self._signal = Signal.new()
		self._re.OnServerEvent:Connect(function(player, ...)
			local args = table.pack(...)
			for _, middlewareFunc in inboundMiddleware do
				local middlewareResult = table.pack(middlewareFunc(player, args))
				if not middlewareResult[1] then
					return
				end
				args.n = #args
			end
			self._signal:Fire(player, table.unpack(args, 1, args.n))
		end)
	else
		self._directConnect = true
	end
	return self
end

--[=[
	@return boolean
	Returns `true` if the underlying RemoteSignal is bound to an
	UnreliableRemoteEvent object.
]=]
function RemoteSignal:IsUnreliable(): boolean
	return self._re:IsA("UnreliableRemoteEvent")
end

--[=[
	@param fn (player: Player, ...: any) -> nil -- The function to connect
	@return Connection
	Connect a function to the signal. Anytime a matching ClientRemoteSignal
	on a client fires, the connected function will be invoked with the
	arguments passed by the client.
]=]
function RemoteSignal:Connect(fn)
	if self._secured then
		return self._signal:Connect(fn)
	elseif self._directConnect then
		return self._re.OnServerEvent:Connect(fn)
	else
		return self._signal:Connect(fn)
	end
end

function RemoteSignal:_processOutboundMiddleware(player: Player?, ...: any)
	if not self._hasOutbound then
		return ...
	end
	local args = table.pack(...)
	for _, middlewareFunc in self._outbound do
		local middlewareResult = table.pack(middlewareFunc(player, args))
		if not middlewareResult[1] then
			return table.unpack(middlewareResult, 2, middlewareResult.n)
		end
		args.n = #args
	end
	return table.unpack(args, 1, args.n)
end

--[=[
	@param player Player -- The target client
	@param ... any -- Arguments passed to the client
	Fires the signal at the specified client with any arguments.

	:::note Outbound Middleware
	All arguments pass through any outbound middleware (if any)
	before being sent to the clients.
	:::
]=]
function RemoteSignal:Fire(player: Player, ...: any)
	self._re:FireClient(player, self:_processOutboundMiddleware(player, ...))
end

--[=[
	@param ... any
	Fires the signal at _all_ clients with any arguments.

	:::note Outbound Middleware
	All arguments pass through any outbound middleware (if any)
	before being sent to the clients.
	:::
]=]
function RemoteSignal:FireAll(...: any)
	self._re:FireAllClients(self:_processOutboundMiddleware(nil, ...))
end

--[=[
	@param ignorePlayer Player -- The client to ignore
	@param ... any -- Arguments passed to the other clients
	Fires the signal to all clients _except_ the specified
	client.

	:::note Outbound Middleware
	All arguments pass through any outbound middleware (if any)
	before being sent to the clients.
	:::
]=]
function RemoteSignal:FireExcept(ignorePlayer: Player, ...: any)
	self:FireFilter(function(plr)
		return plr ~= ignorePlayer
	end, ...)
end

--[=[
	@param predicate (player: Player, argsFromFire: ...) -> boolean
	@param ... any -- Arguments to pass to the clients (and to the predicate)
	Fires the signal at any clients that pass the `predicate`
	function test. This can be used to fire signals with much
	more control logic.

	:::note Outbound Middleware
	All arguments pass through any outbound middleware (if any)
	before being sent to the clients.
	:::

	:::caution Predicate Before Middleware
	The arguments sent to the predicate are sent _before_ getting
	transformed by any middleware.
	:::

	```lua
	-- Fire signal to players of the same team:
	remoteSignal:FireFilter(function(player)
		return player.Team.Name == "Best Team"
	end)
	```
]=]
function RemoteSignal:FireFilter(predicate: (Player, ...any) -> boolean, ...: any)
	for _, player in Players:GetPlayers() do
		if predicate(player, ...) then
			self._re:FireClient(player, self:_processOutboundMiddleware(nil, ...))
		end
	end
end

--[=[
	Fires a signal at the clients within the `players` table. This is
	useful when signals need to fire for a specific set of players.

	For more complex firing, see `FireFilter`.

	:::note Outbound Middleware
	All arguments pass through any outbound middleware (if any)
	before being sent to the clients.
	:::

	```lua
	local players = {somePlayer1, somePlayer2, somePlayer3}
	remoteSignal:FireFor(players, "Hello, players!")
	```
]=]
function RemoteSignal:FireFor(players: { Player }, ...: any)
	for _, player in players do
		self._re:FireClient(player, self:_processOutboundMiddleware(nil, ...))
	end
end

--[=[
	Destroys the RemoteSignal object.
]=]
function RemoteSignal:Destroy()
	self._re:Destroy()
	if self._signal then
		self._signal:Destroy()
	end
end

return RemoteSignal
