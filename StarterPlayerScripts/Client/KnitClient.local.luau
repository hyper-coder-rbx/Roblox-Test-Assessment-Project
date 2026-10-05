local Knit=require(game.ReplicatedStorage:WaitForChild("Packages").Knit)

--Add Controllers
Knit.AddControllersDeep(script.Parent.Controllers)

--Start Knit Controllers
Knit.Start():andThen(function()
	print("Client started!")
end)

--Add Components
--require(game.ReplicatedStorage.Shared.Modules.CombatCore)

for _,component in pairs(script.Parent.Components:GetDescendants()) do
	if (not component:IsA("ModuleScript")) then continue end
	require(component)
end

script.Parent.Components.DescendantAdded:Connect(function(component)
	if (not component:IsA("ModuleScript")) then return end
	require(component)
end)