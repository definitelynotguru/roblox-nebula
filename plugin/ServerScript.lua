--[[
    Nebula AI Assistant for Roblox Studio
    Plugin script - place this in a folder named NebulaAI in your Studio plugins directory
]]

local Selection = game:GetService("Selection")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local HttpService = game:GetService("HttpService")

local plugin = plugin or getfenv().plugin

-----------------------------------------------------
-- Settings
-----------------------------------------------------
local SETTING_API_URL = "NebulaAI_ApiUrl"
local SETTING_API_KEY = "NebulaAI_ApiKey"

local function getApiUrl()
    return plugin:GetSetting(SETTING_API_URL) or ""
end

local function setApiUrl(url)
    plugin:SetSetting(SETTING_API_URL, url)
end

local function getApiKey()
    return plugin:GetSetting(SETTING_API_KEY) or ""
end

local function setApiKey(key)
    plugin:SetSetting(SETTING_API_KEY, key)
end

-----------------------------------------------------
-- Theme
-----------------------------------------------------
local THEME = {
    Background = Color3.fromRGB(30, 30, 30),
    Surface = Color3.fromRGB(40, 40, 40),
    InputBg = Color3.fromRGB(50, 50, 50),
    Text = Color3.fromRGB(220, 220, 220),
    TextDim = Color3.fromRGB(150, 150, 150),
    Accent = Color3.fromRGB(0, 162, 255),
    AccentHover = Color3.fromRGB(30, 180, 255),
    Success = Color3.fromRGB(0, 200, 100),
    Error = Color3.fromRGB(255, 80, 80),
    UserBubble = Color3.fromRGB(0, 100, 180),
    AiBubble = Color3.fromRGB(50, 50, 55),
    Border = Color3.fromRGB(60, 60, 60),
}

-----------------------------------------------------
-- Plugin UI Setup
-----------------------------------------------------
local toolbar = plugin:CreateToolbar("Nebula AI")
local toggleButton = toolbar:CreateButton(
    "NebulaChat",
    "Open AI Assistant",
    "rbxassetid://10734950109"
)

local widgetInfo = DockWidgetPluginGuiInfo.new(
    Enum.InitialDockState.Right,
    false,  -- initial enabled
    false,  -- override enabled
    380,    -- default width
    500,    -- default height
    250,    -- min width
    300     -- min height
)

local widget = plugin:CreateDockWidgetPluginGui("NebulaAI_Chat", widgetInfo)
widget.Title = "Nebula AI"

toggleButton.Click:Connect(function()
    widget.Enabled = not widget.Enabled
end)

-----------------------------------------------------
-- Helper: Create UI elements
-----------------------------------------------------
local function createInstance(className, props, children)
    local inst = Instance.new(className)
    for key, value in pairs(props or {}) do
        if key ~= "Parent" then
            pcall(function()
                inst[key] = value
            end)
        end
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    if props and props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

-----------------------------------------------------
-- Main Frame
-----------------------------------------------------
local mainFrame = createInstance("Frame", {
    Parent = widget,
    BackgroundColor3 = THEME.Background,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 1, 0),
})

-----------------------------------------------------
-- Header
-----------------------------------------------------
local header = createInstance("Frame", {
    Parent = mainFrame,
    BackgroundColor3 = THEME.Surface,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 40),
})

local headerTitle = createInstance("TextLabel", {
    Parent = header,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 0),
    Size = UDim2.new(1, -60, 1, 0),
    Font = Enum.Font.GothamBold,
    Text = "Nebula AI",
    TextColor3 = THEME.Accent,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
})

local settingsButton = createInstance("TextButton", {
    Parent = header,
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -36, 0, 4),
    Size = UDim2.new(0, 32, 0, 32),
    Font = Enum.Font.GothamBold,
    Text = "[S]",
    TextColor3 = THEME.TextDim,
    TextSize = 16,
})

local divider = createInstance("Frame", {
    Parent = header,
    BackgroundColor3 = THEME.Border,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 1, -1),
    Size = UDim2.new(1, 0, 0, 1),
})

-----------------------------------------------------
-- Chat Container (scrollable)
-----------------------------------------------------
local chatScroll = createInstance("ScrollingFrame", {
    Parent = mainFrame,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 0, 40),
    Size = UDim2.new(1, 0, 1, -110),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollBarThickness = 6,
    ScrollBarImageColor3 = THEME.Border,
    BorderSizePixel = 0,
    ClipsDescendants = true,
})

local chatLayout = createInstance("UIListLayout", {
    Parent = chatScroll,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 8),
})

local chatPadding = createInstance("UIPadding", {
    Parent = chatScroll,
    PaddingLeft = UDim.new(0, 10),
    PaddingRight = UDim.new(0, 10),
    PaddingTop = UDim.new(0, 10),
    PaddingBottom = UDim.new(0, 10),
})

-----------------------------------------------------
-- Input Area
-----------------------------------------------------
local inputArea = createInstance("Frame", {
    Parent = mainFrame,
    BackgroundColor3 = THEME.Surface,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 1, -70),
    Size = UDim2.new(1, 0, 0, 70),
})

local inputDivider = createInstance("Frame", {
    Parent = inputArea,
    BackgroundColor3 = THEME.Border,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 1),
})

local inputBox = createInstance("TextBox", {
    Parent = inputArea,
    BackgroundColor3 = THEME.InputBg,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 10, 0, 8),
    Size = UDim2.new(1, -80, 0, 36),
    Font = Enum.Font.Gotham,
    PlaceholderText = "Ask about your game...",
    PlaceholderColor3 = THEME.TextDim,
    Text = "",
    TextColor3 = THEME.Text,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
    MultiLine = false,
})

local inputCorner = createInstance("UICorner", {
    Parent = inputBox,
    CornerRadius = UDim.new(0, 6),
})

local sendButton = createInstance("TextButton", {
    Parent = inputArea,
    BackgroundColor3 = THEME.Accent,
    BorderSizePixel = 0,
    Position = UDim2.new(1, -60, 0, 8),
    Size = UDim2.new(0, 50, 0, 36),
    Font = Enum.Font.GothamBold,
    Text = "Send",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 14,
})

local sendCorner = createInstance("UICorner", {
    Parent = sendButton,
    CornerRadius = UDim.new(0, 6),
})

local statusLabel = createInstance("TextLabel", {
    Parent = inputArea,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 10, 0, 48),
    Size = UDim2.new(1, -20, 0, 16),
    Font = Enum.Font.Gotham,
    Text = "",
    TextColor3 = THEME.TextDim,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
})

-----------------------------------------------------
-- Settings Panel
-----------------------------------------------------
local settingsPanel = createInstance("Frame", {
    Parent = mainFrame,
    BackgroundColor3 = THEME.Background,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 1, 0),
    Visible = false,
    ZIndex = 10,
})

local settingsHeader = createInstance("TextLabel", {
    Parent = settingsPanel,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 12),
    Size = UDim2.new(1, -24, 0, 24),
    Font = Enum.Font.GothamBold,
    Text = "Settings",
    TextColor3 = THEME.Accent,
    TextSize = 18,
    TextXAlignment = Enum.TextXAlignment.Left,
})

local apiLabel = createInstance("TextLabel", {
    Parent = settingsPanel,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 50),
    Size = UDim2.new(1, -24, 0, 16),
    Font = Enum.Font.Gotham,
    Text = "Backend URL",
    TextColor3 = THEME.TextDim,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
})

local apiInput = createInstance("TextBox", {
    Parent = settingsPanel,
    BackgroundColor3 = THEME.InputBg,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 12, 0, 70),
    Size = UDim2.new(1, -24, 0, 32),
    Font = Enum.Font.Gotham,
    PlaceholderText = "https://your-tunnel-url.com",
    PlaceholderColor3 = THEME.TextDim,
    Text = getApiUrl(),
    TextColor3 = THEME.Text,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
})

local apiInputCorner = createInstance("UICorner", {
    Parent = apiInput,
    CornerRadius = UDim.new(0, 6),
})

local keyLabel = createInstance("TextLabel", {
    Parent = settingsPanel,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 112),
    Size = UDim2.new(1, -24, 0, 16),
    Font = Enum.Font.Gotham,
    Text = "API Key (optional)",
    TextColor3 = THEME.TextDim,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
})

local keyInput = createInstance("TextBox", {
    Parent = settingsPanel,
    BackgroundColor3 = THEME.InputBg,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 12, 0, 132),
    Size = UDim2.new(1, -24, 0, 32),
    Font = Enum.Font.Gotham,
    PlaceholderText = "Leave blank if not configured",
    PlaceholderColor3 = THEME.TextDim,
    Text = getApiKey(),
    TextColor3 = THEME.Text,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
})

local keyInputCorner = createInstance("UICorner", {
    Parent = keyInput,
    CornerRadius = UDim.new(0, 6),
})

local saveSettingsBtn = createInstance("TextButton", {
    Parent = settingsPanel,
    BackgroundColor3 = THEME.Success,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 12, 0, 180),
    Size = UDim2.new(1, -24, 0, 36),
    Font = Enum.Font.GothamBold,
    Text = "Save & Close",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 14,
})

local saveCorner = createInstance("UICorner", {
    Parent = saveSettingsBtn,
    CornerRadius = UDim.new(0, 6),
})

-----------------------------------------------------
-- State
-----------------------------------------------------
local conversationHistory = {}
local isWaiting = false
local messageCount = 0

-----------------------------------------------------
-- Get selected instance context
-----------------------------------------------------
local function getSelectionContext()
    local selected = Selection:Get()
    if #selected == 0 then return nil end

    local inst = selected[1]
    local context = {
        selected = {
            Name = inst.Name,
            ClassName = inst.ClassName,
            Parent = inst.Parent and inst.Parent:GetFullName() or nil,
        },
        hierarchy = {},
    }

    -- Add position/size for BaseParts
    if inst:IsA("BasePart") then
        local p = inst.Position
        context.selected.Position = string.format("%.1f, %.1f, %.1f", p.X, p.Y, p.Z)
        local s = inst.Size
        context.selected.Size = string.format("%.1f, %.1f, %.1f", s.X, s.Y, s.Z)
    end

    -- If it's a Script or LocalScript, include the source
    if inst:IsA("LuaSourceContainer") then
        context.script = inst.Source
    end

    -- Top-level hierarchy of parent
    local parent = inst.Parent
    if parent then
        for _, child in ipairs(parent:GetChildren()) do
            if child ~= inst then
                table.insert(context.hierarchy, {
                    Name = child.Name,
                    ClassName = child.ClassName,
                })
            end
        end
    end

    return context
end

-----------------------------------------------------
-- Add message bubble to chat
-----------------------------------------------------
local function addMessageBubble(role, text, script)
    messageCount += 1

    local isUser = role == "user"
    local bubbleColor = isUser and THEME.UserBubble or THEME.AiBubble
    local align = isUser and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left

    -- Container frame
    local bubbleFrame = createInstance("Frame", {
        Parent = chatScroll,
        BackgroundColor3 = bubbleColor,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(0.85, 0, 0, 0),
        LayoutOrder = messageCount,
    })

    local bubbleCorner = createInstance("UICorner", {
        Parent = bubbleFrame,
        CornerRadius = UDim.new(0, 8),
    })

    -- Label
    local roleLabel = createInstance("TextLabel", {
        Parent = bubbleFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 6),
        Size = UDim2.new(1, -20, 0, 14),
        Font = Enum.Font.GothamBold,
        Text = isUser and "You" or "Nebula",
        TextColor3 = THEME.TextDim,
        TextSize = 11,
        TextXAlignment = align,
        TextYAlignment = Enum.TextYAlignment.Top,
    })

    local textLabel = createInstance("TextLabel", {
        Parent = bubbleFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 22),
        Size = UDim2.new(1, -20, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.Gotham,
        Text = text,
        TextColor3 = THEME.Text,
        TextSize = 13,
        TextXAlignment = align,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
    })

    -- Insert script button (only for AI messages with code)
    if script and not isUser then
        local scriptPreview = createInstance("TextLabel", {
            Parent = bubbleFrame,
            BackgroundColor3 = Color3.fromRGB(25, 25, 25),
            BorderSizePixel = 0,
            Position = UDim2.new(0, 8, 0, 0),
            Size = UDim2.new(1, -16, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = Enum.Font.Code,
            Text = string.sub(script, 1, 300) .. (string.len(script) > 300 and "..." or ""),
            TextColor3 = Color3.fromRGB(180, 220, 180),
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            Visible = false, -- shown after layout calculation
        })

        local previewCorner = createInstance("UICorner", {
            Parent = scriptPreview,
            CornerRadius = UDim.new(0, 4),
        })

        local previewPad = createInstance("UIPadding", {
            Parent = scriptPreview,
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            PaddingTop = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 6),
        })

        local insertBtn = createInstance("TextButton", {
            Parent = bubbleFrame,
            BackgroundColor3 = THEME.Success,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 8, 0, 0),
            Size = UDim2.new(1, -16, 0, 32),
            Font = Enum.Font.GothamBold,
            Text = "Insert Script",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 13,
            LayoutOrder = 100,
        })

        local insertCorner = createInstance("UICorner", {
            Parent = insertBtn,
            CornerRadius = UDim.new(0, 6),
        })

        local savedScript = script

        insertBtn.MouseButton1Click:Connect(function()
            ChangeHistoryService:SetWaypoint("Nebula AI: Insert Script")

            local selected = Selection:Get()
            local target

            if #selected > 0 and selected[1]:IsA("LuaSourceContainer") then
                -- Replace source of selected script
                target = selected[1]
                target.Source = savedScript
            else
                -- Create new Script in Workspace or under selected instance
                local newScript = Instance.new("Script")
                newScript.Name = "NebulaScript"
                newScript.Source = savedScript

                if #selected > 0 then
                    newScript.Parent = selected[1]
                else
                    newScript.Parent = workspace
                end

                target = newScript
                Selection:Set({newScript})
            end

            ChangeHistoryService:SetWaypoint("Nebula AI: Inserted Script")
            statusLabel.Text = "Script inserted!"
            task.delay(3, function()
                if statusLabel.Text == "Script inserted!" then
                    statusLabel.Text = ""
                end
            end)
        end)
    end

    -- Layout for bubble children
    local bubbleLayout = createInstance("UIListLayout", {
        Parent = bubbleFrame,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
    })

    local bubblePad = createInstance("UIPadding", {
        Parent = bubbleFrame,
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 8),
    })

    -- Auto-scroll to bottom
    task.defer(function()
        chatScroll.CanvasPosition = Vector2.new(0, chatScroll.AbsoluteCanvasSize.Y)
    end)
end

-----------------------------------------------------
-- Send message to backend
-----------------------------------------------------
local function sendMessage()
    local message = inputBox.Text
    if message == "" or isWaiting then return end

    local apiUrl = getApiUrl()
    if apiUrl == "" then
        statusLabel.Text = "Set backend URL in settings first"
        settingsPanel.Visible = true
        return
    end

    isWaiting = true
    inputBox.Text = ""
    statusLabel.Text = "Thinking..."
    sendButton.BackgroundColor3 = THEME.TextDim

    -- Add user bubble
    addMessageBubble("user", message, nil)

    -- Build request
    local requestBody = {
        message = message,
        context = getSelectionContext(),
        history = conversationHistory,
    }

    local headers = {
        ["Content-Type"] = "application/json",
    }

    local apiKey = getApiKey()
    if apiKey ~= "" then
        headers["Authorization"] = "Bearer " .. apiKey
    end

    local success, response = pcall(function()
        return HttpService:PostAsync(
            apiUrl .. "/api/chat",
            HttpService:JSONEncode(requestBody),
            Enum.HttpContentType.ApplicationJson,
            headers
        )
    end)

    if not success then
        statusLabel.Text = "Connection failed. Check URL and tunnel."
        addMessageBubble("assistant", "Could not connect to the backend. Make sure:\n1. Backend is running (npm start)\n2. Tunnel is active\n3. URL is correct in settings", nil)
        isWaiting = false
        sendButton.BackgroundColor3 = THEME.Accent
        return
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(response)
    end)

    if not ok or data.error then
        statusLabel.Text = "Error from backend"
        addMessageBubble("assistant", data and data.error or "Unknown error", nil)
        isWaiting = false
        sendButton.BackgroundColor3 = THEME.Accent
        return
    end

    -- Add AI response
    addMessageBubble("assistant", data.reply, data.script)

    -- Update history
    table.insert(conversationHistory, { role = "user", content = message })
    table.insert(conversationHistory, { role = "assistant", content = data.reply })

    -- Keep history manageable (last 20 messages)
    if #conversationHistory > 20 then
        conversationHistory = table.move(conversationHistory, #conversationHistory - 19, #conversationHistory, 1, {})
    end

    statusLabel.Text = ""
    isWaiting = false
    sendButton.BackgroundColor3 = THEME.Accent
end

-----------------------------------------------------
-- Connect events
-----------------------------------------------------
sendButton.MouseButton1Click:Connect(sendMessage)

inputBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        sendMessage()
    end
end)

sendButton.MouseEnter:Connect(function()
    if not isWaiting then
        sendButton.BackgroundColor3 = THEME.AccentHover
    end
end)

sendButton.MouseLeave:Connect(function()
    if not isWaiting then
        sendButton.BackgroundColor3 = THEME.Accent
    end
end)

-- Settings toggle
settingsButton.MouseButton1Click:Connect(function()
    settingsPanel.Visible = not settingsPanel.Visible
end)

saveSettingsBtn.MouseButton1Click:Connect(function()
    setApiUrl(apiInput.Text)
    setApiKey(keyInput.Text)
    settingsPanel.Visible = false
    statusLabel.Text = "Settings saved"
    task.delay(2, function()
        if statusLabel.Text == "Settings saved" then
            statusLabel.Text = ""
        end
    end)
end)

-- Welcome message
addMessageBubble("assistant", "Welcome to Nebula AI!\n\nTo get started:\n1. Click the [S] button to open settings\n2. Enter your backend URL (from localtunnel/ngrok)\n3. Select objects in your game and ask me anything!\n\nTry: \"Make this part spin\" or \"Create a leaderboard script\"", nil)