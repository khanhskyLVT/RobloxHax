--[=[
    Universal Third-Party Script Hub
    Tương thích: PC & Mobile (Chạy trên mọi trải nghiệm Roblox)
]=]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

-------------------------------------------------------------------------------
-- 1. PROTECTED GUI RESOLUTION
-------------------------------------------------------------------------------
local function getUIContainer()
	local success, result = pcall(function()
		if gethui then
			return gethui()
		end
		return game:GetService("CoreGui")
	end)

	if success and result then
		return result
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local targetContainer = getUIContainer()

-- Xóa phiên bản cũ nếu đã chạy trước đó
if targetContainer:FindFirstChild("UniversalHubGUI") then
	targetContainer.UniversalHubGUI:Destroy()
end

-------------------------------------------------------------------------------
-- 2. CONFIGURATION & STATE
-------------------------------------------------------------------------------
local Config = {
	ToggleKey = Enum.KeyCode.RightShift,
	DefaultSpeed = 16,
	BoostSpeed = 45,
	DefaultJump = 50,
	BoostJump = 120
}

local State = {
	IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled,
	Visible = true,
	Features = {
		SpeedWalk = false,
		HighJump = false,
		Noclip = false,
		FullBright = false
	},
	Connections = {}
}

-------------------------------------------------------------------------------
-- 3. UI CONSTRUCTION
-------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "UniversalHubGUI"
gui.ResetOnSpawn = false
gui.Parent = targetContainer

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 300, 0, 340)
main.Position = UDim2.new(0.5, -150, 0.5, -170)
main.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
main.BorderSizePixel = 0
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = main

local topbar = Instance.new("Frame")
topbar.Size = UDim2.new(1, 0, 0, 36)
topbar.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
topbar.BorderSizePixel = 0
topbar.Parent = main

local topbarCorner = Instance.new("UICorner")
topbarCorner.CornerRadius = UDim.new(0, 8)
topbarCorner.Parent = topbar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Universal Client Hub"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.SourceSansBold
title.TextSize = 15
title.Parent = topbar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -36, 0, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 16
closeBtn.Parent = topbar

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -16, 1, -48)
scroll.Position = UDim2.new(0, 8, 0, 42)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.Parent = main

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 6)
layout.Parent = scroll

-------------------------------------------------------------------------------
-- 4. MOBILE TOGGLE & DRAGGING LOGIC
-------------------------------------------------------------------------------
local mobileToggle = Instance.new("TextButton")
mobileToggle.Name = "MobileToggle"
mobileToggle.Size = UDim2.new(0, 48, 0, 48)
mobileToggle.Position = UDim2.new(0, 15, 0.35, 0)
mobileToggle.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
mobileToggle.Text = "HUB"
mobileToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
mobileToggle.Font = Enum.Font.SourceSansBold
mobileToggle.TextSize = 13
mobileToggle.Visible = State.IsMobile
mobileToggle.Parent = gui

local mobileCorner = Instance.new("UICorner")
mobileCorner.CornerRadius = UDim.new(0.5, 0)
mobileCorner.Parent = mobileToggle

local function setupDrag(frame, handle)
	local dragging, dragStart, startPos
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

setupDrag(main, topbar)
setupDrag(mobileToggle, mobileToggle)

-------------------------------------------------------------------------------
-- 5. CORE LOGIC FEATURES
-------------------------------------------------------------------------------
local function applyPhysics()
	local char = LocalPlayer.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	hum.WalkSpeed = State.Features.SpeedWalk and Config.BoostSpeed or Config.DefaultSpeed

	if hum.UseJumpPower then
		hum.JumpPower = State.Features.HighJump and Config.BoostJump or Config.DefaultJump
	else
		hum.JumpHeight = State.Features.HighJump and (Config.BoostJump / 2.5) or (Config.DefaultJump / 2.5)
	end
end

local function applyNoclip(active)
	if State.Connections.Noclip then
		State.Connections.Noclip:Disconnect()
		State.Connections.Noclip = nil
	end

	if active then
		State.Connections.Noclip = RunService.Stepped:Connect(function()
			local char = LocalPlayer.Character
			if char then
				for _, part in ipairs(char:GetDescendants()) do
					if part:IsA("BasePart") and part.CanCollide then
						part.CanCollide = false
					end
				end
			end
		end)
	end
end

local function applyFullBright(active)
	if active then
		Lighting.Ambient = Color3.new(1, 1, 1)
		Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
		Lighting.Brightness = 2
	else
		Lighting.Ambient = Color3.fromRGB(128, 128, 128)
		Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
		Lighting.Brightness = 1
	end
end

-------------------------------------------------------------------------------
-- 6. UI TOGGLES CREATION
-------------------------------------------------------------------------------
local function addToggle(nameText, key, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 36)
	btn.BackgroundColor3 = State.Features[key] and Color3.fromRGB(40, 130, 65) or Color3.fromRGB(38, 38, 46)
	btn.Text = nameText .. " : " .. (State.Features[key] and "ON" or "OFF")
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.SourceSans
	btn.TextSize = 14
	btn.Parent = scroll

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = btn

	btn.MouseButton1Click:Connect(function()
		State.Features[key] = not State.Features[key]
		local isON = State.Features[key]
		btn.BackgroundColor3 = isON and Color3.fromRGB(40, 130, 65) or Color3.fromRGB(38, 38, 46)
		btn.Text = nameText .. " : " .. (isON and "ON" or "OFF")
		callback(isON)
	end)
end

addToggle("Tăng tốc (Speed Walk)", "SpeedWalk", function() applyPhysics() end)
addToggle("Nhảy cao (High Jump)", "HighJump", function() applyPhysics() end)
addToggle("Đi xuyên tường (Noclip)", "Noclip", function(v) applyNoclip(v) end)
addToggle("Tăng độ sáng (Full Bright)", "FullBright", function(v) applyFullBright(v) end)

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
end)

-------------------------------------------------------------------------------
-- 7. VISIBILITY CONTROLS
-------------------------------------------------------------------------------
local function toggleUI()
	State.Visible = not State.Visible
	main.Visible = State.Visible
end

closeBtn.MouseButton1Click:Connect(toggleUI)
mobileToggle.MouseButton1Click:Connect(toggleUI)

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Config.ToggleKey then
		toggleUI()
	end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
	char:WaitForChild("Humanoid", 5)
	applyPhysics()
end)