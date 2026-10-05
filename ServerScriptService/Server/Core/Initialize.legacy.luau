local Knit = require(game.ReplicatedStorage.Packages.Knit)

Knit.AddServicesDeep(script.Parent.Parent.Services)

Knit.Start():andThen(function()
	print("Server started!")
	--TODO: Make this require good
	--require(game.ReplicatedStorage.Shared.Modules.CombatCore)

	for _,component in pairs(script.Parent.Parent.Components:GetDescendants()) do
		if (not component:IsA("ModuleScript")) then continue end;
		require(component)
	end

end)
