--[=[
    Universal Client Script Framework
    Tương thích: PC & Mobile (Chạy trực tiếp trên Client Roblox)
]=]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

-------------------------------------------------------------------------------
-- 1. SAFE GUI CONTAINER RESOLUTION
-------------------------------------------------------------------------------
local function getSafeGuiContainer()
	local success, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)
	if success and coreGui then
		return coreGui
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local parentContainer = getSafeGuiContainer()

-- Dọn dẹp giao diện cũ nếu script được nạp lại
if parentContainer:FindFirstChild("UniversalClientHub") then
	parentContainer.UniversalClientHub:Destroy()
end

-------------------------------------------------------------------------------
-- 2. CONFIGURATION & STATE
-------------------------------------------------------------------------------
local Config = {
	ToggleKey = Enum.KeyCode.RightShift,
	DefaultWalkSpeed = 16,
	BoostedWalkSpeed = 40,
	DefaultJumpPower = 50,
	BoostedJumpPower = 120
}

local State = {
	IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled,
	Visible = true,
	Toggles = {
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
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UniversalClientHub"
screenGui.ResetOnSpawn = false

-- Sử dụng protectgui nếu môi trường hỗ trợ
if gethui then
	screenGui.Parent = gethui()
else
	screenGui.Parent = parentContainer
end

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 310, 0, 350)
mainFrame.Position = UDim2.new(0.5, -155, 0.5, -175)
mainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

local topbar = Instance.new("Frame")
topbar.Size = UDim2.new(1, 0, 0, 36)
topbar.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
topbar.BorderSizePixel = 0
topbar.Parent = mainFrame

local topbarCorner = Instance.new("UICorner")
topbarCorner.CornerRadius = UDim.new(0, 8)
topbarCorner.Parent = topbar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Client Hub (PC / Mobile)"
title.TextColor3 = Color3.fromRGB(240, 240, 240)
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

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -16, 1, -48)
scrollFrame.Position = UDim2.new(0, 8, 0, 42)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 3
scrollFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = scrollFrame

-------------------------------------------------------------------------------
-- 4. MOBILE FLOATING BUTTON & DRAGGING
-------------------------------------------------------------------------------
local mobileBtn = Instance.new("TextButton")
mobileBtn.Name = "MobileToggle"
mobileBtn.Size = UDim2.new(0, 48, 0, 48)
mobileBtn.Position = UDim2.new(0, 15, 0.35, 0)
mobileBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
mobileBtn.Text = "HUB"
mobileBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
mobileBtn.Font = Enum.Font.SourceSansBold
mobileBtn.TextSize = 13
mobileBtn.Visible = State.IsMobile
mobileBtn.Parent = screenGui

local mobileCorner = Instance.new("UICorner")
mobileCorner.CornerRadius = UDim.new(0.5, 0)
mobileCorner.Parent = mobileBtn

local function makeDraggable(frame, handle)
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

makeDraggable(mainFrame, topbar)
makeDraggable(mobileBtn, mobileBtn)

-------------------------------------------------------------------------------
-- 5. LOGIC FEATURES
-------------------------------------------------------------------------------
local function applyPhysics()
	local char = LocalPlayer.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	hum.WalkSpeed = State.Toggles.SpeedWalk and Config.BoostedWalkSpeed or Config.DefaultWalkSpeed

	if hum.UseJumpPower then
		hum.JumpPower = State.Toggles.HighJump and Config.BoostedJumpPower or Config.DefaultJumpPower
	else
		hum.JumpHeight = State.Toggles.HighJump and (Config.BoostedJumpPower / 2.5) or (Config.DefaultJumpPower / 2.5)
	end
end

local function toggleNoclip(active)
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

local function toggleFullBright(active)
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
-- 6. UI TOGGLE BUILDER
-------------------------------------------------------------------------------
local function createToggle(nameText, stateKey, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 36)
	btn.BackgroundColor3 = State.Toggles[stateKey] and Color3.fromRGB(40, 130, 65) or Color3.fromRGB(38, 38, 46)
	btn.Text = nameText .. " : " .. (State.Toggles[stateKey] and "ON" or "OFF")
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.SourceSans
	btn.TextSize = 14
	btn.Parent = scrollFrame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = btn

	btn.MouseButton1Click:Connect(function()
		State.Toggles[stateKey] = not State.Toggles[stateKey]
		local isON = State.Toggles[stateKey]
		btn.BackgroundColor3 = isON and Color3.fromRGB(40, 130, 65) or Color3.fromRGB(38, 38, 46)
		btn.Text = nameText .. " : " .. (isON and "ON" or "OFF")
		callback(isON)
	end)
end

createToggle("Tăng tốc (Speed Walk)", "SpeedWalk", function() applyPhysics() end)
createToggle("Nhảy cao (High Jump)", "HighJump", function() applyPhysics() end)
createToggle("Đi xuyên tường (Noclip)", "Noclip", function(v) toggleNoclip(v) end)
createToggle("Tăng độ sáng (Full Bright)", "FullBright", function(v) toggleFullBright(v) end)

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end)

-------------------------------------------------------------------------------
-- 7. EVENT CONNECTIONS
-------------------------------------------------------------------------------
local function toggleVisibility()
	State.Visible = not State.Visible
	mainFrame.Visible = State.Visible
end

closeBtn.MouseButton1Click:Connect(toggleVisibility)
mobileBtn.MouseButton1Click:Connect(toggleVisibility)

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Config.ToggleKey then
		toggleVisibility()
	end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
	char:WaitForChild("Humanoid", 5)
	applyPhysics()
end)