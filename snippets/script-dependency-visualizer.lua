--[[
    Script Dependency Visualizer
    
    A Roblox Studio plugin that visualizes ModuleScript require() chains,
    detects circular dependencies, and finds unused modules.
    
    Features:
    - Dependency tree visualization
    - Circular dependency detection
    - Unused module finder
    - Click to navigate to scripts
    - Color-coded severity
    
    Installation:
    1. Copy this file
    2. In Roblox Studio, go to Plugins tab -> Plugins folder
    3. Paste as a .lua file OR use Build plugin from file
    4. Or paste into a Script in ServerScriptService, run once to create plugin
]]

local PluginUtil = require(script.Parent.Parent.PluginUtil) -- if using plugin template

-- Services
local Selection = game:GetService("Selection")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local HttpService = game:GetService("HttpService")

-- Plugin setup
local toolbar = plugin:CreateToolbar("Script Tools")
local button = toolbar:CreateButton(
    "Dependency Visualizer",
    "Visualize script dependencies and find issues",
    "rbxassetid://4458901886" -- graph icon
)

local widgetInfo = DockWidgetPluginGuiInfo.new(
    Enum.InitialDockState.Right,
    false,  -- enabled
    false,  -- overrideEnabled
    400,    -- width
    500,    -- height
    250,    -- minWidth
    200     -- minHeight
)

local widget = plugin:CreateDockWidgetPluginGui("ScriptDependencyVisualizer", widgetInfo)
widget.Title = "Dependency Visualizer"

button.Click:Connect(function()
    widget.Enabled = not widget.Enabled
end)

-- UI Components
local function createUI()
    local main = Instance.new("Frame")
    main.Size = UDim2.new(1, 0, 1, 0)
    main.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    main.BorderSizePixel = 0
    main.Parent = widget
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    header.BorderSizePixel = 0
    header.Parent = main
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -110, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Script Dependencies"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Parent = header
    
    local scanBtn = Instance.new("TextButton")
    scanBtn.Size = UDim2.new(0, 80, 0, 30)
    scanBtn.Position = UDim2.new(1, -90, 0.5, -15)
    scanBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    scanBtn.Text = "Scan"
    scanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    scanBtn.Font = Enum.Font.GothamSemibold
    scanBtn.TextSize = 14
    scanBtn.Parent = header
    
    -- Stats bar
    local statsBar = Instance.new("Frame")
    statsBar.Size = UDim2.new(1, 0, 0, 30)
    statsBar.Position = UDim2.new(0, 0, 0, 50)
    statsBar.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    statsBar.BorderSizePixel = 0
    statsBar.Parent = main
    
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Name = "StatsLabel"
    statsLabel.Size = UDim2.new(1, -20, 1, 0)
    statsLabel.Position = UDim2.new(0, 10, 0, 0)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Text = "Click Scan to analyze dependencies"
    statsLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    statsLabel.TextXAlignment = Enum.TextXAlignment.Left
    statsLabel.Font = Enum.Font.Gotham
    statsLabel.TextSize = 12
    statsLabel.Parent = statsBar
    
    -- Tab bar
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, 0, 0, 32)
    tabBar.Position = UDim2.new(0, 0, 0, 80)
    tabBar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    tabBar.BorderSizePixel = 0
    tabBar.Parent = main
    
    local tabs = {}
    local tabNames = {"Tree", "Circular", "Unused"}
    for i, name in ipairs(tabNames) do
        local tab = Instance.new("TextButton")
        tab.Name = name
        tab.Size = UDim2.new(1/3, -2, 1, -4)
        tab.Position = UDim2.new((i-1)/3, 1, 0, 2)
        tab.BackgroundColor3 = i == 1 and Color3.fromRGB(0, 120, 215) or Color3.fromRGB(50, 50, 55)
        tab.Text = name
        tab.TextColor3 = Color3.fromRGB(255, 255, 255)
        tab.Font = Enum.Font.GothamSemibold
        tab.TextSize = 13
        tab.Parent = tabBar
        tabs[name] = tab
    end
    
    -- Content area (scrolling frame)
    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -10, 1, -120)
    content.Position = UDim2.new(0, 5, 0, 115)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 6
    content.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.Parent = main
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 2)
    layout.Parent = content
    
    return {
        main = main,
        scanBtn = scanBtn,
        statsLabel = statsLabel,
        tabs = tabs,
        content = content,
        layout = layout
    }
end

local ui = createUI()

-- Dependency Analysis Logic
local function getAllScripts()
    local scripts = {}
    
    local function scan(container)
        for _, item in ipairs(container:GetDescendants()) do
            if item:IsA("LocalScript") or item:IsA("ServerScript") or item:IsA("ModuleScript") then
                table.insert(scripts, item)
            end
        end
    end
    
    -- Scan common locations
    for _, location in ipairs({
        game.Workspace,
        game.ReplicatedStorage,
        game.ReplicatedFirst,
        game.ServerScriptService,
        game.ServerStorage,
        game.StarterPlayer,
        game.StarterGui,
        game.StarterPack,
        game.SoundService,
        game.Chat,
        game.Lighting
    }) do
        scan(location)
    end
    
    return scripts
end

local function findRequireCalls(source)
    -- Find all require() calls in script source
    local requires = {}
    
    -- Pattern: require(path.to.module) or require(script.Parent.ModuleName)
    -- Also handles: require(game.ReplicatedStorage.SomeModule)
    
    local function tryGetSource()
        if source:IsA("LocalScript") or source:IsA("ServerScript") or source:IsA("ModuleScript") then
            local ok, src = pcall(function() return source.Source end)
            if ok then return src end
        end
        return nil
    end
    
    local src = tryGetSource()
    if not src then return requires end
    
    -- Match require statements with various path formats
    -- require(script.Parent.Module)
    -- require(game.ReplicatedStorage.Modules.SomeModule)
    -- require(something)
    
    -- This pattern catches most require() calls
    for path in src:gmatch("require%s*%([^)]*([%w_.]+)[^)]*%)") do
        if not path:match("^math%.") and not path:match("^string%.") then
            table.insert(requires, path)
        end
    end
    
    -- Also match require with path objects like: require(script.Parent:WaitForChild("Module"))
    for name in src:gmatch("WaitForChild%s*%(%"([^%"]+)%"%)") do
        -- Only count if it's in a require context
        local startPos = src:find(name, 1, true)
        if startPos then
            local before = src:sub(math.max(1, startPos - 80), startPos)
            if before:match("require%s*%([^)]*$") then
                table.insert(requires, name)
            end
        end
    end
    
    return requires
end

local function resolvePath(currentScript, pathStr)
    -- Try to resolve a require path to an actual script instance
    
    -- Handle script.Parent.Module style paths
    if pathStr:match("^script") then
        -- Relative path from script
        local parts = {}
        local current = currentScript
        
        for part in pathStr:gmatch("([%w_]+)") do
            if part == "script" then
                -- stay at current
            elseif part == "Parent" then
                current = current and current.Parent
            else
                current = current and current:FindFirstChild(part)
            end
            if not current then break end
        end
        
        return current
    end
    
    -- Handle game.Path.To.Module style paths
    if pathStr:match("^game") then
        local parts = {}
        for part in pathStr:gmatch("([%w_]+)") do
            if part ~= "game" then
                table.insert(parts, part)
            end
        end
        
        local current = game
        for _, part in ipairs(parts) do
            current = current:FindFirstChild(part)
            if not current then return nil end
        end
        
        return current
    end
    
    -- Just a name - search nearby
    local function searchNearby(container)
        local found = container:FindFirstChild(pathStr)
        if found then return found end
        
        -- Search children that are folders
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Folder") then
                found = searchNearby(child)
                if found then return found end
            end
        end
        
        return nil
    end
    
    -- Search in common module locations
    local locations = {
        game.ReplicatedStorage,
        game.ReplicatedFirst,
        game.ServerStorage,
        game.ServerScriptService
    }
    
    for _, loc in ipairs(locations) do
        local found = searchNearby(loc)
        if found then return found end
    end
    
    return nil
end

local function buildDependencyGraph()
    local scripts = getAllScripts()
    local graph = {}  -- script -> {dependencies}
    local reverseGraph = {}  -- script -> {dependents}
    local scriptByPath = {}  -- path string -> script
    
    -- Index all scripts by their path
    for _, script in ipairs(scripts) do
        local path = script:GetFullName()
        scriptByPath[path] = script
        graph[script] = {}
        reverseGraph[script] = {}
    end
    
    -- Build dependency edges
    for _, script in ipairs(scripts) do
        local requires = findRequireCalls(script)
        
        for _, pathStr in ipairs(requires) do
            local target = resolvePath(script, pathStr)
            
            if target and (target:IsA("ModuleScript") or target:IsA("LocalScript") or target:IsA("ServerScript")) then
                if graph[target] == nil then
                    graph[target] = {}
                    reverseGraph[target] = {}
                end
                
                table.insert(graph[script], target)
                table.insert(reverseGraph[target], script)
            end
        end
    end
    
    return scripts, graph, reverseGraph, scriptByPath
end

local function detectCircularDependencies(graph)
    local cycles = {}
    local visited = {}
    local inStack = {}
    local path = {}
    
    local function dfs(node)
        visited[node] = true
        inStack[node] = true
        table.insert(path, node)
        
        for _, dep in ipairs(graph[node] or {}) do
            if not visited[dep] then
                dfs(dep)
            elseif inStack[dep] then
                -- Found a cycle
                local cycleStart = 1
                for i, n in ipairs(path) do
                    if n == dep then
                        cycleStart = i
                        break
                    end
                end
                
                local cycle = {}
                for i = cycleStart, #path do
                    table.insert(cycle, path[i])
                end
                table.insert(cycle, dep) -- close the cycle
                table.insert(cycles, cycle)
            end
        end
        
        table.remove(path)
        inStack[node] = false
    end
    
    for node in pairs(graph) do
        if not visited[node] then
            dfs(node)
        end
    end
    
    return cycles
end

local function findUnusedModules(scripts, reverseGraph)
    local unused = {}
    
    for _, script in ipairs(scripts) do
        if script:IsA("ModuleScript") then
            local dependents = reverseGraph[script] or {}
            if #dependents == 0 then
                table.insert(unused, script)
            end
        end
    end
    
    return unused
end

-- UI Rendering
local function createTreeEntry(script, indent, hasIssues)
    local entry = Instance.new("Frame")
    entry.Size = UDim2.new(1, -10, 0, 28)
    entry.BackgroundColor3 = hasIssues and Color3.fromRGB(60, 40, 40) or Color3.fromRGB(45, 45, 50)
    entry.BorderSizePixel = 0
    
    local indentFrame = Instance.new("Frame")
    indentFrame.Size = UDim2.new(0, indent * 20, 1, 0)
    indentFrame.BackgroundTransparency = 1
    indentFrame.Parent = entry
    
    -- Type indicator
    local typeIndicator = Instance.new("Frame")
    typeIndicator.Size = UDim2.new(0, 4, 0.6, 0)
    typeIndicator.Position = UDim2.new(0, indent * 20 + 5, 0.2, 0)
    typeIndicator.BorderSizePixel = 0
    
    if script:IsA("ModuleScript") then
        typeIndicator.BackgroundColor3 = Color3.fromRGB(100, 180, 255) -- blue
    elseif script:IsA("LocalScript") then
        typeIndicator.BackgroundColor3 = Color3.fromRGB(255, 180, 100) -- orange
    else
        typeIndicator.BackgroundColor3 = Color3.fromRGB(100, 255, 130) -- green
    end
    
    typeIndicator.Parent = entry
    
    -- Script name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -indent * 20 - 30, 1, 0)
    nameLabel.Position = UDim2.new(0, indent * 20 + 15, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = script.Name
    nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextSize = 13
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = entry
    
    -- Click to select
    local clickZone = Instance.new("TextButton")
    clickZone.Size = UDim2.new(1, 0, 1, 0)
    clickZone.BackgroundTransparency = 1
    clickZone.Text = ""
    clickZone.Parent = entry
    
    clickZone.MouseButton1Click:Connect(function()
        Selection:Set({script})
    end)
    
    clickZone.MouseEnter:Connect(function()
        entry.BackgroundColor3 = hasIssues and Color3.fromRGB(80, 50, 50) or Color3.fromRGB(55, 55, 60)
    end)
    
    clickZone.MouseLeave:Connect(function()
        entry.BackgroundColor3 = hasIssues and Color3.fromRGB(60, 40, 40) or Color3.fromRGB(45, 45, 50)
    end)
    
    return entry
end

local function createIssueEntry(script, issueType, details)
    local entry = Instance.new("Frame")
    entry.Size = UDim2.new(1, -10, 0, 50)
    entry.BackgroundColor3 = Color3.fromRGB(60, 40, 40)
    entry.BorderSizePixel = 0
    
    -- Icon
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 30, 0, 30)
    icon.Position = UDim2.new(0, 8, 0, 5)
    icon.BackgroundTransparency = 1
    icon.Text = issueType == "circular" and "⚠" or "?"
    icon.TextColor3 = issueType == "circular" and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(180, 180, 100)
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 20
    icon.Parent = entry
    
    -- Script name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -50, 0, 20)
    nameLabel.Position = UDim2.new(0, 40, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = script.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Font = Enum.Font.GothamSemibold
    nameLabel.TextSize = 13
    nameLabel.Parent = entry
    
    -- Details
    local detailLabel = Instance.new("TextLabel")
    detailLabel.Size = UDim2.new(1, -50, 0, 20)
    detailLabel.Position = UDim2.new(0, 40, 0, 25)
    detailLabel.BackgroundTransparency = 1
    detailLabel.Text = details
    detailLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    detailLabel.TextXAlignment = Enum.TextXAlignment.Left
    detailLabel.Font = Enum.Font.Gotham
    detailLabel.TextSize = 11
    detailLabel.TextTruncate = Enum.TextTruncate.AtEnd
    detailLabel.Parent = entry
    
    -- Click to select
    local clickZone = Instance.new("TextButton")
    clickZone.Size = UDim2.new(1, 0, 1, 0)
    clickZone.BackgroundTransparency = 1
    clickZone.Text = ""
    clickZone.Parent = entry
    
    clickZone.MouseButton1Click:Connect(function()
        Selection:Set({script})
    end)
    
    return entry
end

-- Tab management
local currentTab = "Tree"
local scanResults = nil

local function setActiveTab(tabName)
    currentTab = tabName
    
    for name, tab in pairs(ui.tabs) do
        tab.BackgroundColor3 = name == tabName and Color3.fromRGB(0, 120, 215) or Color3.fromRGB(50, 50, 55)
    end
    
    if scanResults then
        renderResults()
    end
end

for name, tab in pairs(ui.tabs) do
    tab.MouseButton1Click:Connect(function()
        setActiveTab(name)
    end)
end

function renderResults()
    -- Clear content
    for _, child in ipairs(ui.content:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
    
    local scripts = scanResults.scripts
    local graph = scanResults.graph
    local reverseGraph = scanResults.reverseGraph
    local cycles = scanResults.cycles
    local unused = scanResults.unused
    
    local order = 0
    
    if currentTab == "Tree" then
        -- Show dependency tree
        -- First, find root scripts (not depended on by anything, or entry points)
        local roots = {}
        local shown = {}
        
        -- Show ModuleScripts first, then ServerScripts, then LocalScripts
        for _, script in ipairs(scripts) do
            if script:IsA("ModuleScript") then
                local dependents = reverseGraph[script] or {}
                if #dependents == 0 then
                    table.insert(roots, script)
                end
            end
        end
        
        local function showScript(script, indent)
            if shown[script] then return end
            shown[script] = true
            
            local deps = graph[script] or {}
            local hasCircular = false
            for _, cycle in ipairs(cycles) do
                for _, s in ipairs(cycle) do
                    if s == script then hasCircular = true end
                end
            end
            
            order = order + 1
            local entry = createTreeEntry(script, indent, hasCircular)
            entry.LayoutOrder = order
            entry.Parent = ui.content
            
            for _, dep in ipairs(deps) do
                showScript(dep, indent + 1)
            end
        end
        
        -- Show roots first
        for _, root in ipairs(roots) do
            showScript(root, 0)
        end
        
        -- Then show scripts that are part of cycles but not yet shown
        for _, script in ipairs(scripts) do
            if not shown[script] then
                showScript(script, 0)
            end
        end
        
    elseif currentTab == "Circular" then
        if #cycles == 0 then
            local msg = Instance.new("TextLabel")
            msg.Size = UDim2.new(1, -20, 0, 100)
            msg.Position = UDim2.new(0, 10, 0, 20)
            msg.BackgroundTransparency = 1
            msg.Text = "✓ No circular dependencies found!"
            msg.TextColor3 = Color3.fromRGB(100, 220, 100)
            msg.Font = Enum.Font.GothamSemibold
            msg.TextSize = 14
            msg.TextWrapped = true
            msg.Parent = ui.content
        else
            for i, cycle in ipairs(cycles) do
                order = order + 1
                local cycleFrame = Instance.new("Frame")
                cycleFrame.Size = UDim2.new(1, -10, 0, 30 + #cycle * 24)
                cycleFrame.BackgroundColor3 = Color3.fromRGB(50, 35, 35)
                cycleFrame.BorderSizePixel = 0
                cycleFrame.LayoutOrder = order
                cycleFrame.Parent = ui.content
                
                local header = Instance.new("TextLabel")
                header.Size = UDim2.new(1, -10, 0, 24)
                header.Position = UDim2.new(0, 5, 0, 3)
                header.BackgroundTransparency = 1
                header.Text = "⚠ Cycle " .. i
                header.TextColor3 = Color3.fromRGB(255, 100, 100)
                header.TextXAlignment = Enum.TextXAlignment.Left
                header.Font = Enum.Font.GothamBold
                header.TextSize = 13
                header.Parent = cycleFrame
                
                for j, script in ipairs(cycle) do
                    order = order + 1
                    local entry = createTreeEntry(script, 1, true)
                    entry.Size = UDim2.new(1, -10, 0, 24)
                    entry.LayoutOrder = order
                    entry.Parent = ui.content
                    
                    if j < #cycle then
                        local arrow = Instance.new("TextLabel")
                        arrow.Size = UDim2.new(0, 20, 0, 20)
                        arrow.Position = UDim2.new(0, 25, 0, 2)
                        arrow.BackgroundTransparency = 1
                        arrow.Text = "↓"
                        arrow.TextColor3 = Color3.fromRGB(255, 80, 80)
                        arrow.Font = Enum.Font.GothamBold
                        arrow.TextSize = 14
                        arrow.Parent = entry
                    end
                end
            end
        end
        
    elseif currentTab == "Unused" then
        if #unused == 0 then
            local msg = Instance.new("TextLabel")
            msg.Size = UDim2.new(1, -20, 0, 100)
            msg.Position = UDim2.new(0, 10, 0, 20)
            msg.BackgroundTransparency = 1
            msg.Text = "✓ All modules are being used!"
            msg.TextColor3 = Color3.fromRGB(100, 220, 100)
            msg.Font = Enum.Font.GothamSemibold
            msg.TextSize = 14
            msg.TextWrapped = true
            msg.Parent = ui.content
        else
            for _, script in ipairs(unused) do
                order = order + 1
                local entry = createIssueEntry(script, "unused", "Not required by any script - potential dead code")
                entry.LayoutOrder = order
                entry.Parent = ui.content
            end
        end
    end
    
    -- Update canvas size
    task.defer(function()
        local totalHeight = 0
        for _, child in ipairs(ui.content:GetChildren()) do
            if child:IsA("Frame") then
                totalHeight = totalHeight + child.AbsoluteSize.Y + 2
            end
        end
        ui.content.CanvasSize = UDim2.new(0, 0, 0, math.max(totalHeight, 10))
    end)
end

local function runScan()
    ui.statsLabel.Text = "Scanning..."
    
    -- Clear content
    for _, child in ipairs(ui.content:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
    
    -- Use task.defer to avoid freezing UI
    task.defer(function()
        local scripts, graph, reverseGraph, scriptByPath = buildDependencyGraph()
        local cycles = detectCircularDependencies(graph)
        local unused = findUnusedModules(scripts, reverseGraph)
        
        -- Count by type
        local moduleCount = 0
        local serverCount = 0
        local localCount = 0
        
        for _, s in ipairs(scripts) do
            if s:IsA("ModuleScript") then moduleCount = moduleCount + 1
            elseif s:IsA("ServerScript") then serverCount = serverCount + 1
            elseif s:IsA("LocalScript") then localCount = localCount + 1
            end
        end
        
        scanResults = {
            scripts = scripts,
            graph = graph,
            reverseGraph = reverseGraph,
            scriptByPath = scriptByPath,
            cycles = cycles,
            unused = unused
        }
        
        local statusText = string.format(
            "Scripts: %d (%d Module, %d Server, %d Local) | Issues: %d circular, %d unused",
            #scripts, moduleCount, serverCount, localCount, #cycles, #unused
        )
        ui.statsLabel.Text = statusText
        
        renderResults()
    end)
end

ui.scanBtn.MouseButton1Click:Connect(runScan)

-- Cleanup on plugin close
widget:BindToClose(function()
    widget.Enabled = false
end)

print("[Script Dependency Visualizer] Plugin loaded. Click the toolbar button to open.")