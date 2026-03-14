--[[
    D20 Dice Rolling System
    =======================
    Press R to roll a d20. Animated dice appears at top of screen.
    
    SETUP:
    1. Create a LocalScript inside StarterPlayerScripts
    2. Paste this entire script in
    3. Play and press R!
    
    No other assets needed. Everything is created procedurally.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ROLL_KEY = Enum.KeyCode.R
local ROLL_COOLDOWN = 1.5
local DICE_SIZE = 120
local ANIMATION_DURATION = 1.8
local CYCLE_START_FAST = 0.03
local CYCLE_END_SLOW = 0.4

local lastRoll = 0
local isRolling = false

---------------------------------------------------------------------------
-- COLOR PALETTE
---------------------------------------------------------------------------
local COLORS = {
	bg = Color3.fromRGB(30, 30, 40),
	border = Color3.fromRGB(80, 80, 100),
	text = Color3.fromRGB(240, 240, 255),
	subtext = Color3.fromRGB(160, 160, 180),
	bgGradTop = Color3.fromRGB(40, 40, 55),
	bgGradBot = Color3.fromRGB(20, 20, 30),
	nat20 = Color3.fromRGB(50, 220, 120),
	nat1 = Color3.fromRGB(220, 50, 50),
	rollGradTop = Color3.fromRGB(60, 60, 80),
	rollGradBot = Color3.fromRGB(35, 35, 50),
}

---------------------------------------------------------------------------
-- CREATE SCREEN GUI
---------------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "D20RollGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 100
screenGui.Parent = playerGui

---------------------------------------------------------------------------
-- MAIN CONTAINER (top center)
---------------------------------------------------------------------------
local container = Instance.new("Frame")
container.Name = "Container"
container.AnchorPoint = Vector2.new(0.5, 0)
container.Position = UDim2.new(0.5, 0, 0, -200)
container.Size = UDim2.new(0, 220, 0, 210)
container.BackgroundColor3 = COLORS.bg
container.BackgroundTransparency = 0.1
container.BorderSizePixel = 0
container.Parent = screenGui

local containerCorner = Instance.new("UICorner")
containerCorner.CornerRadius = UDim.new(0, 16)
containerCorner.Parent = container

local containerStroke = Instance.new("UIStroke")
containerStroke.Name = "Stroke"
containerStroke.Color = COLORS.border
containerStroke.Thickness = 2
containerStroke.Transparency = 0.3
containerStroke.Parent = container

local containerGrad = Instance.new("UIGradient")
containerGrad.Color = ColorSequence.new(COLORS.bgGradTop, COLORS.bgGradBot)
containerGrad.Rotation = 90
containerGrad.Parent = container

-- subtle shadow
local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
shadow.Size = UDim2.new(1, 20, 1, 20)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://5554236805"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.6
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(23, 23, 277, 277)
shadow.ZIndex = 0
shadow.Parent = container

---------------------------------------------------------------------------
-- TITLE LABEL
---------------------------------------------------------------------------
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0, 28)
titleLabel.Position = UDim2.new(0, 0, 0, 8)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "D20 ROLL"
titleLabel.TextColor3 = COLORS.subtext
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Center
titleLabel.Parent = container

---------------------------------------------------------------------------
-- DICE CONTAINER
---------------------------------------------------------------------------
local diceFrame = Instance.new("Frame")
diceFrame.Name = "Dice"
diceFrame.AnchorPoint = Vector2.new(0.5, 0)
diceFrame.Position = UDim2.new(0.5, 0, 0, 40)
diceFrame.Size = UDim2.new(0, DICE_SIZE, 0, DICE_SIZE)
diceFrame.BackgroundColor3 = COLORS.rollGradTop
diceFrame.BorderSizePixel = 0
diceFrame.Parent = container

local diceCorner = Instance.new("UICorner")
diceCorner.CornerRadius = UDim.new(0, 20)
diceCorner.Parent = diceFrame

local diceStroke = Instance.new("UIStroke")
diceStroke.Name = "Stroke"
diceStroke.Color = COLORS.border
diceStroke.Thickness = 3
diceStroke.Transparency = 0.2
diceStroke.Parent = diceFrame

local diceGrad = Instance.new("UIGradient")
diceGrad.Color = ColorSequence.new(COLORS.rollGradTop, COLORS.rollGradBot)
diceGrad.Rotation = 45
diceGrad.Parent = diceFrame

-- subtle inner highlight
local highlight = Instance.new("Frame")
highlight.Name = "Highlight"
highlight.Size = UDim2.new(0.85, 0, 0.3, 0)
highlight.Position = UDim2.new(0.075, 0, 0.05, 0)
highlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
highlight.BackgroundTransparency = 0.85
highlight.BorderSizePixel = 0
highlight.Parent = diceFrame

local hlCorner = Instance.new("UICorner")
hlCorner.CornerRadius = UDim.new(0, 12)
hlCorner.Parent = highlight

---------------------------------------------------------------------------
-- NUMBER LABEL (inside dice)
---------------------------------------------------------------------------
local numberLabel = Instance.new("TextLabel")
numberLabel.Name = "Number"
numberLabel.Size = UDim2.new(1, 0, 1, 0)
numberLabel.BackgroundTransparency = 1
numberLabel.Text = "?"
numberLabel.TextColor3 = COLORS.text
numberLabel.TextSize = 52
numberLabel.Font = Enum.Font.GothamBlack
numberLabel.TextXAlignment = Enum.TextXAlignment.Center
numberLabel.TextYAlignment = Enum.TextYAlignment.Center
numberLabel.Parent = diceFrame

---------------------------------------------------------------------------
-- RESULT LABEL (below dice)
---------------------------------------------------------------------------
local resultLabel = Instance.new("TextLabel")
resultLabel.Name = "Result"
resultLabel.Size = UDim2.new(1, -20, 0, 24)
resultLabel.Position = UDim2.new(0, 10, 1, -38)
resultLabel.BackgroundTransparency = 1
resultLabel.Text = "Press R to roll"
resultLabel.TextColor3 = COLORS.subtext
resultLabel.TextSize = 14
resultLabel.Font = Enum.Font.GothamMedium
resultLabel.TextXAlignment = Enum.TextXAlignment.Center
resultLabel.Parent = container

---------------------------------------------------------------------------
-- HELPERS
---------------------------------------------------------------------------

local function getModifierText(result)
	if result == 20 then return "NATURAL 20!"
	elseif result == 1 then return "CRITICAL MISS!"
	elseif result >= 15 then return "Great roll!"
	elseif result >= 10 then return "Decent"
	elseif result >= 5 then return "Could be better"
	else return "Ouch"
	end
end

local function getResultColor(result)
	if result == 20 then return COLORS.nat20
	elseif result == 1 then return COLORS.nat1
	else return COLORS.text
	end
end

local function tween(obj, props, duration, style, dir)
	local t = TweenService:Create(obj, TweenInfo.new(duration, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

---------------------------------------------------------------------------
-- SHOW / HIDE ANIMATIONS
---------------------------------------------------------------------------

local function showUI()
	container.Position = UDim2.new(0.5, 0, 0, -200)
	tween(container, {Position = UDim2.new(0.5, 0, 0, 20)}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

local function hideUI()
	tween(container, {Position = UDim2.new(0.5, 0, 0, -200)}, 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
end

---------------------------------------------------------------------------
-- MAIN ROLL ANIMATION
---------------------------------------------------------------------------

local function rollDice()
	if isRolling then return end
	if tick() - lastRoll < ROLL_COOLDOWN then return end

	isRolling = true
	lastRoll = tick()

	-- Reset appearance
	numberLabel.TextColor3 = COLORS.text
	diceStroke.Color = COLORS.border
	containerStroke.Color = COLORS.border

	-- Slide in
	showUI()
	task.wait(0.35)

	-- Final result
	local finalResult = math.random(1, 20)

	-- Phase 1: Fast cycling (0.6s)
	local elapsed = 0
	local fastDuration = 0.6
	while elapsed < fastDuration do
		local n = math.random(1, 20)
		numberLabel.Text = tostring(n)

		-- quick tumble rotation
		diceFrame.Rotation = math.random(-25, 25)

		task.wait(CYCLE_START_FAST)
		elapsed = elapsed + CYCLE_START_FAST
	end

	-- Phase 2: Slow down with easing (0.8s)
	local slowDuration = ANIMATION_DURATION - fastDuration - 0.4
	local steps = 12
	for i = 1, steps do
		local t = i / steps
		-- ease out: start fast, end slow
		local interval = CYCLE_START_FAST + (CYCLE_END_SLOW - CYCLE_START_FAST) * (t * t)

		local n
		if i == steps then
			n = finalResult
		else
			n = math.random(1, 20)
			-- Bias toward final result in last few steps for drama
			if i > steps - 3 and math.random() < 0.4 then
				n = finalResult
			end
		end
		numberLabel.Text = tostring(n)

		-- rotation settles
		local angle = math.random(-15, 15) * (1 - t)
		diceFrame.Rotation = angle

		task.wait(interval)
	end

	-- Phase 3: Settle + reveal
	tween(diceFrame, {Rotation = 0}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	-- Scale punch
	local origSize = UDim2.new(0, DICE_SIZE, 0, DICE_SIZE)
	local punchSize = UDim2.new(0, DICE_SIZE + 16, 0, DICE_SIZE + 16)
	diceFrame.Size = punchSize
	tween(diceFrame, {Size = origSize}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	-- Color reveal
	local resultColor = getResultColor(finalResult)
	tween(numberLabel, {TextColor3 = resultColor}, 0.3)
	tween(diceStroke, {Color = resultColor, Transparency = 0}, 0.3)
	tween(containerStroke, {Color = resultColor, Transparency = 0.5}, 0.3)

	-- Result text
	resultLabel.Text = getModifierText(finalResult)
	tween(resultLabel, {TextColor3 = resultColor}, 0.3)

	task.wait(2.5)

	-- Fade out
	hideUI()

	task.wait(0.5)
	isRolling = false
end

---------------------------------------------------------------------------
-- INPUT HANDLING
---------------------------------------------------------------------------

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == ROLL_KEY then
		rollDice()
	end
end)

---------------------------------------------------------------------------
-- TOUCH SUPPORT (tap top of screen)
---------------------------------------------------------------------------
local touchButton = Instance.new("TextButton")
touchButton.Name = "TouchRoll"
touchButton.Size = UDim2.new(0, 60, 0, 60)
touchButton.Position = UDim2.new(1, -75, 0, 15)
touchButton.AnchorPoint = Vector2.new(0, 0)
touchButton.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
touchButton.BackgroundTransparency = 0.3
touchButton.Text = "D20"
touchButton.TextColor3 = COLORS.text
touchButton.TextSize = 16
touchButton.Font = Enum.Font.GothamBold
touchButton.BorderSizePixel = 0
touchButton.ZIndex = 10
touchButton.Parent = screenGui

local touchCorner = Instance.new("UICorner")
touchCorner.CornerRadius = UDim.new(0, 12)
touchCorner.Parent = touchButton

local touchStroke = Instance.new("UIStroke")
touchStroke.Color = COLORS.border
	ouchStroke.Thickness = 1.5
	ouchStroke.Transparency = 0.5
	touchStroke.Parent = touchButton

touchButton.MouseButton1Click:Connect(rollDice)

---------------------------------------------------------------------------
-- INIT
---------------------------------------------------------------------------
print("[D20 System] Loaded. Press R to roll!")