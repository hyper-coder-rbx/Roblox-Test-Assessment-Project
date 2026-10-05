local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

local Packages = RS:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local mPlayer = game.Players.LocalPlayer
local Mouse = mPlayer:GetMouse()

local UIController = Knit.CreateController({
	Name = "UIController",
	uiScreens = {}, --Would contains instances of all screens "ScreenGui" modules (ModuleScripts).
})

-------->>> Variables
------------------------------------------------------------->  Private Methods  <------------------------------------------------------

------------------------------------------------------------->  Public Methods  <------------------------------------------------------
--# Subscribe the UI module with UIController. (A central place of all UI screens)
function UIController:SubsUI(screenTyp, module, multi:boolean?)
	if(not self.uiScreens[screenTyp]) then
		self.uiScreens[screenTyp] = module
	else
		local preModule = self.uiScreens[screenTyp]
		if(multi) and (typeof(self.uiScreens[screenTyp]) ~= "table") then
			self.uiScreens[screenTyp] = {}
			table.insert(self.uiScreens[screenTyp], preModule)
		end

		if(multi) then
			table.insert(self.uiScreens[screenTyp], module)

		else
			return false
		end

	end

	return  true
end


function UIController:ToggleScreen(screenTyp :string, visible :boolean, ...)
	if(self.uiScreens[screenTyp]) then
		if(typeof(self.uiScreens[screenTyp]) == `table`) then
			for i, module in pairs(self.uiScreens[screenTyp]) do
				module:Toggle(visible, ...)
			end
		else
			self.uiScreens[screenTyp]:Toggle(visible, ...)
		end
	end
end

function UIController:GetGui(screenTyp :string, waitTime:number)
	if(self.uiScreens[screenTyp]) then
		return self.uiScreens[screenTyp]
	else
		if(waitTime) then
			local timer = 0
			repeat task.wait()
				timer += task.wait()
			until self.uiScreens[screenTyp] or timer > waitTime
			return self.uiScreens[screenTyp] or nil
		else
			return nil
		end
	end
end


function UIController:ToggleMouseIcon(enable:boolean?)
	UIS.MouseIconEnabled = (enable == true)
end

function UIController:UpdateMouseIcon(iconId:string?)
	UIS.MouseIcon = iconId or ""
end


function UIController:KnitInit()
	
end

function UIController:KnitStart()
	
end

return UIController