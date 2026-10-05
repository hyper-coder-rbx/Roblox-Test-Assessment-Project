local Enums = {}


Enums.GameStateType = {
	--No match active, all players on lobby, matchmaking
	Idle = "Idle",
	
	--Match started, waiting periods during match (Initial, Intermission)
	Waiting = "Waiting",
	
	--Match started, players fighting
	MatchRunning = "MatchRunning",
	
	--Match finished, Result screen, returning players to lobby
	Outro = "Outro",
}
table.freeze(Enums.GameStateType)


Enums.LootTypes = {
	Landmine = "Landmine",
	DashZeroCooldown = "DashZeroCooldown",
	SpeedBoost = "SpeedBoost",
}
table.freeze(Enums.LootTypes)

---->>>>>

return Enums