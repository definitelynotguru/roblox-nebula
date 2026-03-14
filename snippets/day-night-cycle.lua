-- Day/Night Cycle System
-- Configurable cycle with smooth lighting transitions, sky colors, and player GUI
-- Place in ServerScriptService as a Script

-- ========== CONFIGURATION ==========
local Config = {
	-- Full day cycle duration in seconds (default: 10 minutes)
	CycleDuration = 600,

	-- Starting time (0-24, where 0 = midnight, 12 = noon)
	StartTime = 8,

	-- Time speed multiplier (1 = normal, 2 = 2x faster)
	SpeedMultiplier = 1,

	-- Lighting settings per period
	Periods = {
		Night = {
			Time = 0,
			SkyTop = Color3.fromRGB(10, 10, 30),
			SkyBottom = Color3.fromRGB(5, 5, 15),
			SkyHorizon = Color3.fromRGB(15, 15, 40),
			Brightness = 0.1,
			Ambient = Color3.fromRGB(20, 20, 40),
			OutdoorAmbient = Color3.fromRGB(15, 15, 35),
			ShadowSoftness = 0.8,
			FogEnd = 500,
			FogColor = Color3.fromRGB(10, 10, 25),
		},
		Dawn = {
			Time = 5,
			SkyTop = Color3.fromRGB(80, 100, 160),
			SkyBottom = Color3.fromRGB(200, 150, 100),
			SkyHorizon = Color3.fromRGB(255, 180, 120),
			Brightness = 0.5,
			Ambient = Color3.fromRGB(80, 60, 50),
			OutdoorAmbient = Color3.fromRGB(120, 90, 70),
			ShadowSoftness = 0.5,
			FogEnd = 1500,
			FogColor = Color3.fromRGB(180, 140, 100),
		},
		Sunrise = {
			Time = 6.5,
			SkyTop = Color3.fromRGB(100, 140, 200),
			SkyBottom = Color3.fromRGB(255, 200, 150),
			SkyHorizon = Color3.fromRGB(255, 220, 180),
			Brightness = 1.5,
			Ambient = Color3.fromRGB(120, 100, 80),
			OutdoorAmbient = Color3.fromRGB(180, 150, 120),
			ShadowSoftness = 0.3,
			FogEnd = 3000,
			FogColor = Color3.fromRGB(220, 200, 180),
		},
		Day = {
			Time = 9,
			SkyTop = Color3.fromRGB(100, 160, 255),
			SkyBottom = Color3.fromRGB(180, 210, 255),
			SkyHorizon = Color3.fromRGB(200, 220, 255),
			Brightness = 2.0,
			Ambient = Color3.fromRGB(150, 150, 150),
			OutdoorAmbient = Color3.fromRGB(200, 200, 200),
			ShadowSoftness = 0.2,
			FogEnd = 5000,
			FogColor = Color3.fromRGB(200, 220, 240),
		},
		Noon = {
			Time = 12,
			SkyTop = Color3.fromRGB(80, 140, 255),
			SkyBottom = Color3.fromRGB(160, 200, 255),
			SkyHorizon = Color3.fromRGB(180, 210, 255),
			Brightness = 2.5,
			Ambient = Color3.fromRGB(180, 180, 180),
			OutdoorAmbient = Color3.fromRGB(220, 220, 220),
			ShadowSoftness = 0.1,
			FogEnd = 8000,
			FogColor = Color3.fromRGB(190, 210, 240),
		},
		Sunset = {
			Time = 17.5,
			SkyTop = Color3.fromRGB(80, 80, 150),
			SkyBottom = Color3.fromRGB(220, 120, 80),
			SkyHorizon = Color3.fromRGB(255, 150, 80),
			Brightness = 1.2,
			Ambient = Color3.fromRGB(100, 70, 50),
			OutdoorAmbient = Color3.fromRGB(160, 100, 70),
			ShadowSoftness = 0.4,
			FogEnd = 2000,
			FogColor = Color3.fromRGB(200, 130, 80),
		},
		Dusk = {
			Time = 19,
			SkyTop = Color3.fromRGB(40, 40, 80),
			SkyBottom = Color3.fromRGB(100, 60, 80),
			SkyHorizon = Color3.fromRGB(150, 80, 100),
			Brightness = 0.3,
			Ambient = Color3.fromRGB(40, 30, 50),
			OutdoorAmbient = Color3.fromRGB(60, 40, 60),
			ShadowSoftness = 0.7,
			FogEnd = 800,
			FogColor = Color3.fromRGB(60, 40, 60),
		},
	},
}

-- ========== SERVICES ==========
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- ========== STATE ==========
local currentTime = Config.StartTime
local isPaused = false

-- ========== UTILITY FUNCTIONS ==========
local function lerp(a, b, t)
	return a + (b - a) * t
end

local function lerpColor3(c1, c2, t)
	return Color3.new(
		lerp(c1.R, c2.R, t),
		lerp(c1.G, c2.G, t),
		lerp(c1.B, c2.B, t)
	)
end

-- Get sorted period list
local function getSortedPeriods()
	local periods = {}
	for name, data in pairs(Config.Periods) do
		table.insert(periods, { name = name, time = data.time, data = data })
	end
	table.sort(periods, function(a, b) return a.time < b.time end)
	return periods
end

local sortedPeriods = getSortedPeriods()

-- Find the two periods that surround the current time
local function getInterpolatingPeriods(timeOfDay)
	local periods = sortedPeriods
	local count = #periods

	-- Handle wrap-around (e.g., time 23 is between Dusk and Night)
	for i = 1, count do
		local curr = periods[i]
		local nextP = periods[i % count + 1]

		local currTime = curr.time
		local nextTime = nextP.time

		-- Handle wrap-around for next time
		if nextTime <= currTime then
			nextTime = nextTime + 24
		end

		local checkTime = timeOfDay
		if checkTime < currTime then
			checkTime = checkTime + 24
		end

		if checkTime >= currTime and checkTime < nextTime then
			local duration = nextTime - currTime
			local progress = (checkTime - currTime) / duration
			return curr.data, nextP.data, progress
		end
	end

	-- Fallback to first period
	return periods[1].data, periods[1].data, 0
end

-- ========== LIGHTING UPDATE ==========
local function updateLighting(timeOfDay)
	local from, to, progress = getInterpolatingPeriods(timeOfDay)

	-- Interpolate sky colors
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if sky then
		local skyTop = lerpColor3(from.SkyTop, to.SkyTop, progress)
		local skyBottom = lerpColor3(from.SkyBottom, to.SkyBottom, progress)
		local skyHorizon = lerpColor3(from.SkyHorizon, to.SkyHorizon, progress)

		-- Update Atmosphere if present
		local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
		if atmosphere then
			atmosphere.Color = skyHorizon
			atmosphere.Decay = lerpColor3(from.FogColor, to.FogColor, progress)
			atmosphere.Density = lerp(0.3, 0.1, progress)
		end
	end

	-- Update ClockTime (moves the sun/moon)
	Lighting.ClockTime = timeOfDay

	-- Interpolate brightness
	Lighting.Brightness = lerp(from.Brightness, to.Brightness, progress)

	-- Interpolate ambient colors
	Lighting.Ambient = lerpColor3(from.Ambient, to.Ambient, progress)
	Lighting.OutdoorAmbient = lerpColor3(from.OutdoorAmbient, to.OutdoorAmbient, progress)

	-- Interpolate shadow softness
	Lighting.ShadowSoftness = lerp(from.ShadowSoftness, to.ShadowSoftness, progress)

	-- Interpolate fog
	Lighting.FogEnd = lerp(from.FogEnd, to.FogEnd, progress)
	Lighting.FogColor = lerpColor3(from.FogColor, to.FogColor, progress)
end

-- ========== GUI CREATION ==========
local function createPlayerGUI(player)
	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DayNightGUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "TimeFrame"
	frame.Size = UDim2.new(0, 200, 0, 60)
	frame.Position = UDim2.new(0, 10, 0, 10)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 0
	parent = screenGui

	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

	local timeLabel = Instance.new("TextLabel")
	timeLabel.Name = "TimeLabel"
	timeLabel.Size = UDim2.new(1, -20, 0, 28)
	timeLabel.Position = UDim2.new(0, 10, 0, 5)
	timeLabel.BackgroundTransparency = 1
	timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	timeLabel.TextSize = 20
	timeLabel.Font = Enum.Font.GothamBold
	timeLabel.TextXAlignment = Enum.TextXAlignment.Left
	timeLabel.Parent = frame

	local periodLabel = Instance.new("TextLabel")
	periodLabel.Name = "PeriodLabel"
	periodLabel.Size = UDim2.new(1, -20, 0, 20)
	periodLabel.Position = UDim2.new(0, 10, 0, 33)
	periodLabel.BackgroundTransparency = 1
	periodLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
	periodLabel.TextSize = 14
	periodLabel.Font = Enum.Font.Gotham
	periodLabel.TextXAlignment = Enum.TextXAlignment.Left
	periodLabel.Parent = frame

	return screenGui
end

-- ========== UPDATE GUI ==========
local function getTimeString(timeOfDay)
	hours = math.floor(timeOfDay)
	minutes = math.floor((timeOfDay - hours) * 60)
	local ampm = hours >= 12 and "PM" or "AM"
	displayHour = hours % 12
	if displayHour == 0 then displayHour = 12 end
	return string.format("%d:%02d %s", displayHour, minutes, ampm)
end

local function getPeriodName(timeOfDay)
	local from, to, progress = getInterpolatingPeriods(timeOfDay)
	if progress < 0.5 then
		return from.name
	else
		return to.name
	end
end

local function updateGUI(player, timeOfDay)
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end

	local gui = playerGui:FindFirstChild("DayNightGUI")
	if not gui then return end

	local frame = gui:FindFirstChild("TimeFrame")
	if not frame then return end

	local timeLabel = frame:FindFirstChild("TimeLabel")
	local periodLabel = frame:FindFirstChild("PeriodLabel")

	if timeLabel then
		timeLabel.Text = getTimeString(timeOfDay)
	end

	if periodLabel then
		periodLabel.Text = getPeriodName(timeOfDay) .. " (Day " .. math.floor(timeOfDay / 24 + 1) .. ")"
	end
end

-- ========== PLAYER HANDLING ==========
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(1)
		createPlayerGUI(player)
	end)
end)

-- Create GUI for existing players
for _, player in pairs(Players:GetPlayers()) do
	task.spawn(function()
		if player.Character then
			createPlayerGUI(player)
		end
	end)
end

-- ========== MAIN LOOP ==========
local lastUpdate = tick()

RunService.Heartbeat:Connect(function()
	if isPaused then return end

	local now = tick()
	deltaTime = now - lastUpdate
	lastUpdate = now

	-- Advance time (24 hours = CycleDuration seconds)
	hoursPerSecond = 24 / Config.CycleDuration
	currentTime = currentTime + (hoursPerSecond * deltaTime * Config.SpeedMultiplier)

	-- Wrap around at 24 hours
	if currentTime >= 24 then
		currentTime = currentTime - 24
	end

	-- Update lighting
	updateLighting(currentTime)

	-- Update all player GUIs
	for _, player in pairs(Players:GetPlayers()) do
		updateGUI(player, currentTime)
	end
end)

-- ========== PUBLIC API ==========
_G.DayNightCycle = {
	-- Get current time (0-24)
	GetTime = function()
		return currentTime
	end,

	-- Set time to specific hour
	SetTime = function(hour)
		currentTime = hour % 24
	end,

	-- Pause the cycle
	Pause = function()
		isPaused = true
	end,

	-- Resume the cycle
	Resume = function()
		isPaused = false
		lastUpdate = tick()
	end,

	-- Set cycle duration (seconds for full 24h)
	SetDuration = function(seconds)
		Config.CycleDuration = seconds
	end,

	-- Get current period name
	GetPeriod = function()
		return getPeriodName(currentTime)
	end,

	-- Set speed multiplier
	SetSpeed = function(multiplier)
		Config.SpeedMultiplier = multiplier
	end,
}

print("[DayNightCycle] System initialized. Use _G.DayNightCycle to control.")
