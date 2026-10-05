local Constants = {}

--===========================********************** Objects & Elements ******************============================
Constants.SFXs = {
}
table.freeze(Constants.SFXs)

--===========================********************** Game Play ******************============================
Constants.XP_Rates = {
	Kill = 5,
	Loot = 5,
	Win = 50,
	Loose = 10,
}

Constants.Abilities = {
	Dash = {
		Cooldown = 5,
	},
	SpeedBoost = {
		Increment = 5,
		Duration = 5,
	},
	Landmine = {
		Damage = 100,
	}
}
--===========================********************** Items Data ******************============================



return Constants