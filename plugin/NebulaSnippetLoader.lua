local plugin = plugin or getfenv().plugin

local HttpService = game:GetService("HttpService")

local POLL_INTERVAL = 5
local DISCORD_API = "https://discord.com/api/v10"
local lastSeenMessageId = nil
local pollThread = nil
local isPolling = false

local pluginId = "NebulaRobloxAssistant"

local function getSetting(key, default)
	local s = plugin:GetSetting(pluginId .. "." .. key)
	if s == nil then return default end
	return s
end

local function setSetting(key, value)
	plugin:SetSetting(pluginId .. "." .. key, value)
end

local SETTINGS = {
	BotToken = getSetting("BotToken", ""),
	ChannelId = getSetting("ChannelId", ""),
	AutoRefresh = getSetting("AutoRefresh", true),
}

-- ===== UI =====
local toolbar = plugin:CreateToolbar("Nebula AI")
local toggleButton = toolbar:CreateButton(
	"Open Nebula",
	"Toggle the Nebula snippet panel",
	"rbxassetid://4458901886"
)

local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Right,
	false,
	false,
	320,
	400,
	260,
	200
)

local widget = plugin:CreateDockWidgetPluginGui("NebulaWidget", widgetInfo)
widget.Title = "Nebula AI"

toggleButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = widget

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Padding = UDim.new(0, 8)
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.Parent = mainFrame

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 8)
padding.PaddingBottom = UDim.new(0, 8)
padding.PaddingLeft = UDim.new(0, 8)
padding.PaddingRight = UDim.new(0, 8)
padding.Parent = mainFrame

-- Status
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Not connected"
statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
statusLabel.TextSize = 12
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.LayoutOrder = 1
statusLabel.Parent = mainFrame

-- Snippet count
local logLabel = Instance.new("TextLabel")
logLabel.Size = UDim2.new(1, 0, 0, 16)
logLabel.BackgroundTransparency = 1
logLabel.Text = "Snippets received: 0"
logLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
logLabel.TextSize = 11
logLabel.TextXAlignment = Enum.TextXAlignment.Left
logLabel.LayoutOrder = 2
logLabel.Parent = mainFrame

-- Settings section
local settingsFrame = Instance.new("Frame")
settingsFrame.Size = UDim2.new(1, 0, 0, 120)
settingsFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
settingsFrame.LayoutOrder = 3
settingsFrame.Parent = mainFrame

Instance.new("UICorner", settingsFrame).CornerRadius = UDim.new(0, 4)

local settingsPadding = Instance.new("UIPadding")
settingsPadding.PaddingTop = UDim.new(0, 6)
settingsPadding.PaddingBottom = UDim.new(0, 6)
settingsPadding.PaddingLeft = UDim.new(0, 8)
settingsPadding.PaddingRight = UDim.new(0, 8)
settingsPadding.Parent = settingsFrame

local settingsLayout = Instance.new("UIListLayout")
settingsLayout.Padding = UDim.new(0, 4)
settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
settingsLayout.Parent = settingsFrame

local function createSettingRow(label, default, order, isPassword)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 24)
	row.BackgroundTransparency = 1
	row.LayoutOrder = order
	row.Parent = settingsFrame

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0, 70, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = label
	lbl.TextColor3 = Color3.fromRGB(180, 180, 180)
	lbl.TextSize = 11
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, -74, 1, 0)
	box.Position = UDim2.new(0, 74, 0, 0)
	box.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	box.TextColor3 = Color3.fromRGB(220, 220, 220)
	box.TextSize = 11
	box.Text = default
	box.PlaceholderText = label .. "..."
	box.ClearTextOnFocus = false
	box.Parent = row

	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 3)

	if isPassword then
		box.TextTransparency = 0.3
	end

	return box
end

local tokenBox = createSettingRow("Bot Token", SETTINGS.BotToken, 1, true)
local channelBox = createSettingRow("Channel ID", SETTINGS.ChannelId, 2, false)

-- Auto-refresh toggle
local toggleRow = Instance.new("Frame")
toggleRow.Size = UDim2.new(1, 0, 0, 22)
toggleRow.BackgroundTransparency = 1
toggleRow.LayoutOrder = 4
toggleRow.Parent = settingsFrame

local toggleLabel = Instance.new("TextLabel")
toggleLabel.Size = UDim2.new(0, 80, 1, 0)
toggleLabel.BackgroundTransparency = 1
toggleLabel.Text = "Auto-refresh"
toggleLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
toggleLabel.TextSize = 11
toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
toggleLabel.Parent = toggleRow

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 40, 0, 20)
toggleBtn.Position = UDim2.new(0, 80, 0, 1)
toggleBtn.BackgroundColor3 = SETTINGS.AutoRefresh and Color3.fromRGB(80, 160, 80) or Color3.fromRGB(100, 100, 100)
toggleBtn.Text = SETTINGS.AutoRefresh and "ON" or "OFF"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 11
toggleBtn.Parent = toggleRow

Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 3)

toggleBtn.MouseButton1Click:Connect(function()
	SETTINGS.AutoRefresh = not SETTINGS.AutoRefresh
	toggleBtn.Text = SETTINGS.AutoRefresh and "ON" or "OFF"
	toggleBtn.BackgroundColor3 = SETTINGS.AutoRefresh and Color3.fromRGB(80, 160, 80) or Color3.fromRGB(100, 100, 100)
	setSetting("AutoRefresh", SETTINGS.AutoRefresh)
	if SETTINGS.AutoRefresh then
		startPolling()
	else
		stopPolling()
	end
end)

-- Save button
local saveBtn = Instance.new("TextButton")
saveBtn.Size = UDim2.new(1, 0, 0, 26)
saveBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 180)
saveBtn.Text = "Save Settings"
saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveBtn.TextSize = 12
saveBtn.LayoutOrder = 5
saveBtn.Parent = settingsFrame

Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 4)

saveBtn.MouseButton1Click:Connect(function()
	SETTINGS.BotToken = tokenBox.Text
	SETTINGS.ChannelId = channelBox.Text
	setSetting("BotToken", SETTINGS.BotToken)
	setSetting("ChannelId", SETTINGS.ChannelId)
	statusLabel.Text = "Status: Settings saved"
	task.delay(2, function()
		if statusLabel.Text == "Status: Settings saved" then
			statusLabel.Text = isPolling and "Status: Monitoring..." or "Status: Ready (start polling)"
		end
	end)
	if SETTINGS.AutoRefresh and SETTINGS.BotToken ~= "" and SETTINGS.ChannelId ~= "" then
		lastSeenMessageId = nil
		startPolling()
	end
end)

-- Snippet history list
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, 0, 1, -230)
scrollFrame.Position = UDim2.new(0, 0, 0, 230)
scrollFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 4
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.LayoutOrder = 6
scrollFrame.Parent = mainFrame

Instance.new("UICorner", scrollFrame).CornerRadius = UDim.new(0, 4)

local snippetLayout = Instance.new("UIListLayout")
snippetLayout.Padding = UDim.new(0, 4)
snippetLayout.SortOrder = Enum.SortOrder.LayoutOrder
snippetLayout.Parent = scrollFrame

local snippetPadding = Instance.new("UIPadding")
snippetPadding.PaddingTop = UDim.new(0, 4)
snippetPadding.PaddingBottom = UDim.new(0, 4)
snippetPadding.PaddingLeft = UDim.new(0, 4)
snippetPadding.PaddingRight = UDim.new(0, 4)
snippetPadding.Parent = scrollFrame

local snippetCount = 0

-- ===== Core Logic =====

local function decodeJsonSafe(str)
	local ok, result = pcall(function()
		return HttpService:JSONDecode(str)
	end)
	if ok then return result end
	return nil
end

local function parseSnippetPayload(content)
	local jsonStr = content:match("```json\n(.+)\n```")
	if not jsonStr then
		jsonStr = content:match("```json(.+)```")
	end
	if not jsonStr then return nil end

	local data = decodeJsonSafe(jsonStr)
	if not data then return nil end
	if data.type ~= "roblox_snippet" then return nil end
	if not data.code then return nil end

	return data
end

local function insertSnippet(snippet)
	local scriptType = "ModuleScript"
	if snippet.script_type == "LocalScript" then
		scriptType = "LocalScript"
	elseif snippet.script_type == "Script" then
		scriptType = "Script"
	end

	local newScript = Instance.new(scriptType)
	newScript.Name = snippet.title or "NebulaSnippet"
	newScript.Source = snippet.code

	local sel = game:GetService("Selection"):Get()
	if #sel > 0 then
		newScript.Parent = sel[1]
	else
		newScript.Parent = workspace
	end

	game:GetService("Selection"):Set({newScript})
	plugin:OpenScript(newScript)

	return newScript
end

local function addSnippetToLog(snippet)
	snippetCount = snippetCount + 1
	logLabel.Text = "Snippets received: " .. snippetCount

	local entry = Instance.new("Frame")
	entry.Size = UDim2.new(1, -8, 0, 48)
	entry.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	entry.LayoutOrder = snippetCount
	entry.Parent = scrollFrame

	Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 3)

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.new(1, 0, 0, 16)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = (snippet.script_type or "?") .. ": " .. (snippet.title or "Untitled")
	titleLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
	titleLbl.TextSize = 11
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Parent = entry

	local descLbl = Instance.new("TextLabel")
	descLbl.Size = UDim2.new(1, 0, 0, 14)
	descLbl.Position = UDim2.new(0, 0, 0, 18)
	descLbl.BackgroundTransparency = 1
	descLbl.Text = (snippet.description or ""):sub(1, 60) .. "..."
	descLbl.TextColor3 = Color3.fromRGB(140, 140, 140)
	descLbl.TextSize = 10
	descLbl.TextXAlignment = Enum.TextXAlignment.Left
	descLbl.Parent = entry

	local tagsLbl = Instance.new("TextLabel")
	tagsLbl.Size = UDim2.new(1, 0, 0, 12)
	tagsLbl.Position = UDim2.new(0, 0, 0, 34)
	tagsLbl.BackgroundTransparency = 1
	if snippet.tags then
		tagsLbl.Text = table.concat(snippet.tags, ", ")
	else
		tagsLbl.Text = ""
	end
	tagsLbl.TextColor3 = Color3.fromRGB(100, 140, 180)
	tagsLbl.TextSize = 9
	tagsLbl.TextXAlignment = Enum.TextXAlignment.Left
	tagsLbl.Parent = entry

	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, snippetLayout.AbsoluteContentSize.Y + 8)
	scrollFrame.CanvasPosition = Vector2.new(0, scrollFrame.AbsoluteCanvasSize.Y)
end

local function pollDiscord()
	if SETTINGS.BotToken == "" or SETTINGS.ChannelId == "" then
		return
	end

	local url = DISCORD_API .. "/channels/" .. SETTINGS.ChannelId .. "/messages?limit=10"
	if lastSeenMessageId then
		url = url .. "&after=" .. lastSeenMessageId
	end

	local success, response = pcall(function()
		return HttpService:RequestAsync({
			Url = url,
			Method = "GET",
			Headers = {
				["Authorization"] = "Bot " .. SETTINGS.BotToken,
				["Content-Type"] = "application/json",
			},
		})
	end)

	if not success then
		statusLabel.Text = "Status: Request failed"
		return
	end

	if response.StatusCode == 401 then
		statusLabel.Text = "Status: Invalid bot token"
		stopPolling()
		return
	elseif response.StatusCode == 403 then
		statusLabel.Text = "Status: No access to channel"
		stopPolling()
		return
	elseif response.StatusCode ~= 200 then
		statusLabel.Text = "Status: HTTP " .. tostring(response.StatusCode)
		return
	end

	local messages = decodeJsonSafe(response.Body)
	if not messages or #messages == 0 then return end

	for i = #messages, 1, -1 do
		local msg = messages[i]
		if msg.content and msg.content ~= "" then
			local snippet = parseSnippetPayload(msg.content)
			if snippet then
				local ok = pcall(insertSnippet, snippet)
				if ok then
					addSnippetToLog(snippet)
					statusLabel.Text = "Status: Inserted " .. (snippet.title or "snippet")
				else
					statusLabel.Text = "Status: Insert failed"
				end
			end
		end
	end

	lastSeenMessageId = messages[1].id
	statusLabel.Text = "Status: Monitoring..."
end

function startPolling()
	if isPolling then return end
	if SETTINGS.BotToken == "" or SETTINGS.ChannelId == "" then
		statusLabel.Text = "Status: Configure token & channel first"
		return
	end

	isPolling = true
	statusLabel.Text = "Status: Monitoring..."

	pollThread = task.spawn(function()
		while isPolling do
			pollDiscord()
			task.wait(POLL_INTERVAL)
		end
	end)
end

function stopPolling()
	isPolling = false
	if pollThread then
		task.cancel(pollThread)
	pollThread = nil
	end
	statusLabel.Text = "Status: Paused"
end

-- Init
if SETTINGS.AutoRefresh and SETTINGS.BotToken ~= "" and SETTINGS.ChannelId ~= "" then
	startPolling()
else
	statusLabel.Text = "Status: Configure settings to start"
end

widget.Title = "Nebula AI - Ready"
