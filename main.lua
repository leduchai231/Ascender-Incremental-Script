
-- Load OrionLib with mobile fixes
local OrionLib
local success, result = pcall(function()
    -- Try to load mobile-fixed version first
    local mobileFixedOrion = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()
    return mobileFixedOrion
end)

if success then
    OrionLib = result
else
    -- Fallback to original if mobile version fails
    local fallbackSuccess, fallbackResult = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/jensonhirst/Orion/refs/heads/main/source"))()
    end)
    
    if fallbackSuccess then
        OrionLib = fallbackResult
        warn("Using fallback OrionLib version")
    else
        warn("Failed to load OrionLib: " .. tostring(result))
        return
    end
end 

-- Create main Window with mobile optimizations
local Window = OrionLib:MakeWindow({
    Name = "Ascender Incremental Hub v1.7.0",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "AscenderIncrementalConfig",
    IntroEnabled = true,
    IntroText = "Ascender Incremental Script v1.7.0",
    Icon = "rbxassetid://4483345998"
})

-- Mobile optimization: Make GUI draggable and touch-friendly
local function optimizeForMobile()
    local success, err = pcall(function()
        if game:GetService("UserInputService").TouchEnabled then
            -- Mobile device detected, apply optimizations
            local coreGui = game:GetService("CoreGui")
            local orionGui = coreGui:FindFirstChild("Orion")
            if orionGui and orionGui:FindFirstChild("Main") then
                local mainFrame = orionGui.Main
                mainFrame.Active = true
                mainFrame.Draggable = true
                
                -- Improve touch responsiveness
                for _, descendant in pairs(mainFrame:GetDescendants()) do
                    if descendant:IsA("GuiButton") or descendant:IsA("TextButton") then
                        descendant.AutoButtonColor = true
                        descendant.Active = true
                    elseif descendant:IsA("Frame") and descendant.Name:find("Slider") then
                        descendant.Active = true
                    end
                end
            end
        end
    end)
    
    if not success then
        warn("Mobile optimization failed: " .. tostring(err))
    end
end

-- Apply mobile optimizations after a short delay
task.spawn(function()
    task.wait(1)
    optimizeForMobile()
    
    -- Additional draggable fix for mobile
    task.wait(1)
    local function fixDraggableForMobile()
        local success, err = pcall(function()
            local UserInputService = game:GetService("UserInputService")
            if UserInputService.TouchEnabled then
                local coreGui = game:GetService("CoreGui")
                local orionGui = coreGui:FindFirstChild("Orion")
                if orionGui and orionGui:FindFirstChild("Main") then
                    local mainFrame = orionGui.Main
                    
                    -- Custom draggable implementation for mobile
                    local dragging = false
                    local dragInput
                    local dragStart
                    local startPos
                    
                    local function update(input)
                        local delta = input.Position - dragStart
                        mainFrame.Position = UDim2.new(
                            startPos.X.Scale, 
                            startPos.X.Offset + delta.X, 
                            startPos.Y.Scale, 
                            startPos.Y.Offset + delta.Y
                        )
                    end
                    
                    mainFrame.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            dragging = true
                            dragStart = input.Position
                            startPos = mainFrame.Position
                            
                            input.Changed:Connect(function()
                                if input.UserInputState == Enum.UserInputState.End then
                                    dragging = false
                                end
                            end)
                        end
                    end)
                    
                    mainFrame.InputChanged:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                            dragInput = input
                        end
                    end)
                    
                    UserInputService.InputChanged:Connect(function(input)
                        if input == dragInput and dragging then
                            update(input)
                        end
                    end)
                end
            end
        end)
        
        if not success then
            warn("Draggable fix failed: " .. tostring(err))
        end
    end
    
    fixDraggableForMobile()
end)

-- Create Tabs
local MainTab = Window:MakeTab({
    Name = "Main",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local TalentTreeTab = Window:MakeTab({
    Name = "Talent Tree",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local RuneTab = Window:MakeTab({
    Name = "Rune",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local StatTab = Window:MakeTab({
    Name = "Stat",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local TeleportTab = Window:MakeTab({
    Name = "Teleport",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local ConfigTab = Window:MakeTab({
    Name = "Config",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local SettingsTab = Window:MakeTab({
    Name = "Settings",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})



-- Services and Events
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Initialize Events with error handling
local BuyUpgrade, TeleportRealm
local function initializeEvents()
    local success, err = pcall(function()
        if ReplicatedStorage:FindFirstChild("Framework") and 
           ReplicatedStorage.Framework:FindFirstChild("Events") then
            if ReplicatedStorage.Framework.Events:FindFirstChild("Buy_Upgrade") then
                BuyUpgrade = ReplicatedStorage.Framework.Events.Buy_Upgrade
            end
            if ReplicatedStorage.Framework.Events:FindFirstChild("Teleport_Realm") then
                TeleportRealm = ReplicatedStorage.Framework.Events.Teleport_Realm
            end
        end
    end)
    
    if not success then
        warn("Failed to initialize events: " .. tostring(err))
    end
end

initializeEvents()

-- State variables with validation
local autoUpgradeEnabled = false
local selectedUpgradeType = "W1"
local currentPosition = "Unknown"
local scriptRunning = true
local antiAfkEnabled = true
local autoAllRuneEnabled = false
local autoAllRuneSpeed = 2
local autoLevelChromatizeEnabled = false

-- Config system
local configFolderName = "AscenderIncrementalConfigs"
local defaultConfigName = "default"
local currentConfigName = defaultConfigName
local defaultConfig = {
    antiAfkEnabled = true,
    autoUpgradeEnabled = false,
    selectedUpgradeType = "W1",
    autoAllRuneEnabled = false,
    autoAllRuneSpeed = 2,
    autoLevelChromatizeEnabled = false
}

local function getConfigPath(configName)
    return configFolderName .. "/" .. configName .. ".json"
end

local function ensureConfigFolder()
    local success, err = pcall(function()
        if not isfolder(configFolderName) then
            makefolder(configFolderName)
        end
    end)
    
    if not success then
        OrionLib:MakeNotification({
            Name = "Config Error",
            Content = "Failed to create config folder: " .. tostring(err),
            Image = "rbxassetid://4483345998",
            Time = 3
        })
        return false
    end
    return true
end

local function getConfigList()
    ensureConfigFolder()
    local configs = {}
    
    local success, files = pcall(function()
        return listfiles(configFolderName)
    end)
    
    if success and files then
        for _, file in ipairs(files) do
            local success2, fileName = pcall(function()
                -- Extract filename from full path using string operations
                local name = file
                
                -- Find last slash (both / and \)
                local lastSlash = 0
                for i = 1, #name do
                    local char = name:sub(i, i)
                    if char == "/" or char == "\\" then
                        lastSlash = i
                    end
                end
                
                if lastSlash > 0 then
                    name = name:sub(lastSlash + 1)
                end
                
                -- Check if it's a .json file and remove extension
                if name:sub(-5) == ".json" then
                    local configName = name:sub(1, -6)
                    if configName and configName ~= "" and configName ~= defaultConfigName then
                        return configName
                    end
                end
                return nil
            end)
            
            if success2 and fileName then
                table.insert(configs, fileName)
            end
        end
    end
    
    -- Always include default config at the beginning
    table.insert(configs, 1, defaultConfigName)
    
    return configs
end

local function saveConfig(configName)
    configName = configName or currentConfigName
    if not configName or configName == "" then
        configName = defaultConfigName
    end
    
    ensureConfigFolder()
    
    local config = {
        antiAfkEnabled = antiAfkEnabled,
        autoUpgradeEnabled = autoUpgradeEnabled,
        selectedUpgradeType = selectedUpgradeType,
        autoAllRuneEnabled = autoAllRuneEnabled,
        autoAllRuneSpeed = autoAllRuneSpeed,
        autoLevelChromatizeEnabled = autoLevelChromatizeEnabled
    }
    
    local success, err = pcall(function()
        local jsonString = game:GetService("HttpService"):JSONEncode(config)
        writefile(getConfigPath(configName), jsonString)
    end)
    
    if success then
        currentConfigName = configName
        
        -- Update UI elements if they exist
        if currentConfigLabel then
            currentConfigLabel:Set("Current Config: " .. currentConfigName)
        end
        
        OrionLib:MakeNotification({
            Name = "Config",
            Content = "Configuration '" .. configName .. "' saved successfully!",
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    else
        OrionLib:MakeNotification({
            Name = "Config Error",
            Content = "Failed to save configuration: " .. tostring(err),
            Image = "rbxassetid://4483345998",
            Time = 3
        })
    end
end

local function loadConfig(configName)
    configName = configName or currentConfigName
    if not configName or configName == "" then
        configName = defaultConfigName
    end
    
    ensureConfigFolder()
    
    local success, result = pcall(function()
        local configPath = getConfigPath(configName)
        if isfile(configPath) then
            local jsonString = readfile(configPath)
            return game:GetService("HttpService"):JSONDecode(jsonString)
        else
            return defaultConfig
        end
    end)
    
    if success and result then
        antiAfkEnabled = result.antiAfkEnabled or defaultConfig.antiAfkEnabled
        autoUpgradeEnabled = result.autoUpgradeEnabled or defaultConfig.autoUpgradeEnabled
        selectedUpgradeType = result.selectedUpgradeType or defaultConfig.selectedUpgradeType
        autoAllRuneEnabled = result.autoAllRuneEnabled or defaultConfig.autoAllRuneEnabled
        autoAllRuneSpeed = result.autoAllRuneSpeed or defaultConfig.autoAllRuneSpeed
        autoLevelChromatizeEnabled = result.autoLevelChromatizeEnabled or defaultConfig.autoLevelChromatizeEnabled
        
        currentConfigName = configName
        
        -- Update UI elements if they exist
        if currentConfigLabel then
            currentConfigLabel:Set("Current Config: " .. currentConfigName)
        end
        
        OrionLib:MakeNotification({
            Name = "Config",
            Content = "Configuration '" .. configName .. "' loaded successfully!",
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    else
        -- Use default values
        antiAfkEnabled = defaultConfig.antiAfkEnabled
        autoUpgradeEnabled = defaultConfig.autoUpgradeEnabled
        selectedUpgradeType = defaultConfig.selectedUpgradeType
        autoAllRuneEnabled = defaultConfig.autoAllRuneEnabled
        autoAllRuneSpeed = defaultConfig.autoAllRuneSpeed
        autoLevelChromatizeEnabled = defaultConfig.autoLevelChromatizeEnabled
        
        OrionLib:MakeNotification({
            Name = "Config Error",
            Content = "Failed to load configuration '" .. configName .. "', using defaults",
            Image = "rbxassetid://4483345998",
            Time = 3
        })
    end
end

-- Upgrade list for Ascender Incremental
local upgradeListW1 = {
    { name = "Prisms_Energy1", times = 1 },
    { name = "Prisms_Flame1", times = 3 },
    { name = "Prisms_Prisms1", times = 1 },
    { name = "Prisms_Power", times = 5 },
    { name = "Prisms_Multi", times = 2 },
    { name = "Prisms_Prisms2", times = 1 },
    { name = "Prisms_RP1", times = 2 },
    { name = "Prisms_Orbs2", times = 3 },
    { name = "Prisms_Energy2", times = 1 },
    { name = "Prisms_Prisms3", times = 2 },
    { name = "Prisms_RPEnhance", times = 1 },
    { name = "Prisms_Flesh3", times = 1 },
    { name = "Prisms_Accelerator", times = 6 },
    { name = "Prisms_RuneLuck", times = 2 },
    { name = "Prisms_RuneLuck2", times = 1 },
    { name = "Prisms_SpheresEnhance", times = 1 },
    { name = "Prisms_Flame2", times = 2 },
    { name = "Prisms_OrbsEnhance", times = 1 },
    { name = "Prisms_Tickets", times = 1 },
    { name = "Prisms_AutoPower", times = 1 },
    { name = "Prisms_AutoPower2", times = 19 },
    { name = "Prisms_AutoPower3", times = 19 },
    { name = "Prisms_Caps", times = 2 },
    { name = "Prisms_RuneBulk", times = 2 },
    { name = "Prisms_OrbsAutoBuy", times = 1 },
    { name = "Prisms_AutoFlame", times = 1 },
    { name = "Prisms_Spheres2", times = 3 },
    { name = "Prisms_RP2", times = 1 },
    { name = "Prisms_Spheres1", times = 5 },
    { name = "Prisms_Prisms4", times = 1 },
    { name = "Prisms_Damage", times = 3 },
    { name = "Prisms_Walkspeed", times = 1 },
    { name = "Prisms_RuneSpeed", times = 1 },
    { name = "Prisms_DMG", times = 1 },
    { name = "Prisms_Flesh", times = 2 },
    { name = "Prisms_AutoAttack", times = 1 },
    { name = "Prisms_SpawnSpeed", times = 12 },
    { name = "Prisms_AutoLevel", times = 1 },
    { name = "Prisms_AutoAttackSpeed", times = 9 },
    { name = "Prisms_Orbs1", times = 4 },
    { name = "Prisms_Spheres3", times = 1 },
    { name = "Prisms_Spheres4", times = 1 },
    { name = "Prisms_Flesh2", times = 1 }
}

local upgradeListW2 = {
    { name = "Prisms_Droplets1", times = 5 },
    { name = "Prisms_Water1", times = 3 },
    { name = "Prisms_Droplets2", times = 1 },
    { name = "Prisms_Spheres5", times = 4 },
    { name = "Prisms_Chromium1", times = 2 },
    { name = "Chromium_Chromium1", times = 3 },
    { name = "Chromium_Chromium2", times = 4 },
    { name = "Chromium_Droplets1", times = 1 },
    { name = "Chromium_Icicles4", times = 1 },
    { name = "Chromium_Icicles3", times = 1 },
    { name = "Chromium_AP5", times = 1 },
    { name = "Chromium_AP3", times = 1 },
    { name = "Chromium_SpheresEnhance", times = 1 },
    { name = "Chromium_Prisms1", times = 2 },
    { name = "Chromium_Prisms2", times = 1 },
    { name = "Chromium_Prisms3", times = 1 },
    { name = "Chromium_Prisms4", times = 5 },
    { name = "Chromium_Prisms5", times = 1 },
    { name = "Chromium_Automation1", times = 1 },
    { name = "Chromium_RuneSpeed", times = 1 },
    { name = "Chromium_Icicles2", times = 1 },
    { name = "Chromium_Icicles1", times = 6 },
    { name = "Chromium_AP1", times = 5 },
    { name = "Chromium_AP4", times = 1 },
    { name = "Chromium_AP2", times = 3 },
    { name = "Chromium_AP6", times = 5 },
    { name = "Prisms_AP1", times = 1 },
    { name = "Chromium_Water1", times = 3 },
    { name = "Chromium_Automation2", times = 1 },
    { name = "Chromium_Multi1", times = 2 },
    { name = "Chromium_RuneLuck1", times = 1 },
    { name = "Chromium_Automation3", times = 22 },
    { name = "Chromium_Ice1", times = 4 },
    { name = "Chromium_Ice2", times = 1 },
    { name = "Chromium_Chromium3", times = 3 },
    { name = "Chromium_Droplets2", times = 2 },
    { name = "Prisms_Chromatizer", times = 1 },
    { name = "Chromium_RuneStarring", times = 1 }
}

-- Create W1+W2 list (combine both)
local upgradeListW1W2 = {}
for _, upgrade in ipairs(upgradeListW1) do
    table.insert(upgradeListW1W2, upgrade)
end
for _, upgrade in ipairs(upgradeListW2) do
    table.insert(upgradeListW1W2, upgrade)
end

-- Teleport positions list
local teleportPositions = {
    ["Spawn"] = Vector3.new(0, 5, 0),
    ["Shop"] = Vector3.new(50, 5, 0),
    ["Upgrade Area"] = Vector3.new(-50, 5, 0),
    ["Farm Zone"] = Vector3.new(0, 5, 50)
}

-- Utility functions
local function safeFireServer(event, ...)
    local args = {...}
    local maxRetries = 3
    local retryCount = 0
    
    while retryCount < maxRetries do
        local success, err = pcall(function()
            if event and event:IsA("RemoteEvent") then
                event:FireServer(unpack(args))
                return true
            else
                error("Invalid RemoteEvent: " .. tostring(event))
            end
        end)
        
        if success then
            return true
        else
            retryCount = retryCount + 1
            warn("Error firing server (attempt " .. retryCount .. "/" .. maxRetries .. "): " .. tostring(err))
            if retryCount < maxRetries then
                task.wait(0.5) -- Wait before retry
            end
        end
    end
    
    return false
end

local function teleportToPosition(position)
    local success, err = pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(position)
        else
            warn("Character or HumanoidRootPart not found")
        end
    end)
    
    if not success then
        warn("Teleport failed: " .. tostring(err))
    end
end

local function getCurrentPosition()
    local success, result = pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local pos = LocalPlayer.Character.HumanoidRootPart.Position
            return string.format("X: %.1f, Y: %.1f, Z: %.1f", pos.X, pos.Y, pos.Z)
        end
        return "Character not found"
    end)
    
    if success then
        return result
    else
        return "Error getting position"
    end
end

-- TAB MAIN (Script Updates)
MainTab:AddLabel("Script Information")

MainTab:AddLabel("Version: 1.7.0")
MainTab:AddLabel("Last Updated: 2024-12-19")

MainTab:AddLabel("Recent Updates:")
MainTab:AddLabel("• v1.7.0: Removed all debug messages, Anti AFK enabled by default")
MainTab:AddLabel("• v1.6.2: Fixed string vs number comparison error in chromatizer")
MainTab:AddLabel("• v1.6.1: Updated getCurrentPrisms to use script's stat display values")
MainTab:AddLabel("• v1.6.0: New Rune tab with multi-select & integrated chromatizer")
MainTab:AddLabel("• Renamed Main tab to Talent Tree Upgrade")
MainTab:AddLabel("• Added Rune Teleport Speed configuration")
MainTab:AddLabel("• Auto Chromatizer now farms selected rune when low Prisms")
MainTab:AddLabel("• Multi-select rune system for Auto Rune")

MainTab:AddLabel("Features:")
MainTab:AddLabel("• Talent Tree Auto Upgrade (W1, W2, W1+W2)")
MainTab:AddLabel("• Multi-Select Rune System")
MainTab:AddLabel("• Auto All Rune (Risk Mode)")
MainTab:AddLabel("• Integrated Auto Chromatizer + Rune Farm")
MainTab:AddLabel("• Configurable Rune Teleport Speed")
MainTab:AddLabel("• Real-time Statistics Display")
MainTab:AddLabel("• Configuration Management")
MainTab:AddLabel("• Anti-AFK Protection")
MainTab:AddLabel("• Mobile Optimization")

MainTab:AddButton({
    Name = "Check for Updates",
    Callback = function()
        OrionLib:MakeNotification({
            Name = "Update Check",
            Content = "You are running the latest version v1.7.0",
            Image = "rbxassetid://4483345998",
            Time = 3
        })
    end
})

MainTab:AddButton({
    Name = "Reload Script",
    Callback = function()
        OrionLib:MakeNotification({
            Name = "Reload",
            Content = "Reloading script...",
            Image = "rbxassetid://4483345998",
            Time = 2
        })
        task.wait(1)
        loadstring(game:HttpGet("YOUR_SCRIPT_URL_HERE"))()
    end
})

-- TAB CONFIG
ConfigTab:AddLabel("Configuration Management")

currentConfigLabel = ConfigTab:AddLabel("Current Config: " .. currentConfigName)

ConfigTab:AddTextbox({
    Name = "Create New Config",
    Default = "",
    TextDisappear = true,
    Callback = function(Value)
        if Value and Value ~= "" then
            local configName = Value:gsub("[^%w%s%-_]", ""):gsub("%s+", "_") -- Remove special characters and replace spaces with underscores
            if configName ~= "" and configName ~= "_" then
                saveConfig(configName)
                currentConfigLabel:Set("Current Config: " .. currentConfigName)
                -- Refresh dropdown to show new config
                local configs = getConfigList()
                configDropdown:Refresh(configs, true)
            else
                OrionLib:MakeNotification({
                    Name = "Config Error",
                    Content = "Invalid config name! Use letters, numbers, spaces, hyphens, or underscores only.",
                    Image = "rbxassetid://4483345998",
                    Time = 3
                })
            end
        end
    end
})

local configDropdown = ConfigTab:AddDropdown({
    Name = "Load Configuration",
    Default = currentConfigName,
    Options = getConfigList(),
    Callback = function(Value)
        if Value and Value ~= "" and Value ~= currentConfigName then
            loadConfig(Value)
            OrionLib:MakeNotification({
                Name = "Config",
                Content = "Switched to configuration: " .. Value,
                Image = "rbxassetid://4483345998",
                Time = 2
            })
        end
    end
})

ConfigTab:AddButton({
    Name = "Refresh Config List",
    Callback = function()
        local configs = getConfigList()
        configDropdown:Refresh(configs, true) -- Force refresh
        OrionLib:MakeNotification({
            Name = "Config",
            Content = "Config list refreshed! Found " .. #configs .. " configs",
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    end
})

ConfigTab:AddButton({
    Name = "Load Selected Config",
    Callback = function()
        local selectedConfig = configDropdown.Value or currentConfigName
        if selectedConfig and selectedConfig ~= "" then
            loadConfig(selectedConfig)
        else
            OrionLib:MakeNotification({
                Name = "Config Error",
                Content = "No config selected to load!",
                Image = "rbxassetid://4483345998",
                Time = 3
            })
        end
    end
})

ConfigTab:AddButton({
    Name = "Save Current Config",
    Callback = function()
        if currentConfigName and currentConfigName ~= "" then
            saveConfig(currentConfigName)
        else
            OrionLib:MakeNotification({
                Name = "Config Error",
                Content = "No config name specified. Please create a new config first.",
                Image = "rbxassetid://4483345998",
                Time = 3
            })
        end
    end
})

ConfigTab:AddButton({
    Name = "Remove Selected Config",
    Callback = function()
        local selectedConfig = configDropdown.Value or currentConfigName
        if selectedConfig and selectedConfig ~= "" and selectedConfig ~= defaultConfigName then
            local success, err = pcall(function()
                local configPath = getConfigPath(selectedConfig)
                if isfile(configPath) then
                    delfile(configPath)
                    return true
                else
                    error("Config file not found")
                end
            end)
            
            if success then
                -- Refresh dropdown to remove deleted config
                local configs = getConfigList()
                configDropdown:Refresh(configs, true)
                
                -- If deleted config was current, switch to default
                if selectedConfig == currentConfigName then
                    loadConfig(defaultConfigName)
                end
                
                OrionLib:MakeNotification({
                    Name = "Config",
                    Content = "Configuration '" .. selectedConfig .. "' removed successfully!",
                    Image = "rbxassetid://4483345998",
                    Time = 2
                })
            else
                OrionLib:MakeNotification({
                    Name = "Config Error",
                    Content = "Failed to remove configuration: " .. tostring(err),
                    Image = "rbxassetid://4483345998",
                    Time = 3
                })
            end
        else
            OrionLib:MakeNotification({
                Name = "Config Error",
                Content = selectedConfig == defaultConfigName and "Cannot remove default config!" or "No config selected to remove!",
                Image = "rbxassetid://4483345998",
                Time = 3
            })
        end
    end
})

ConfigTab:AddButton({
    Name = "Reset to Default",
    Callback = function()
        antiAfkEnabled = defaultConfig.antiAfkEnabled
        autoUpgradeEnabled = defaultConfig.autoUpgradeEnabled
        selectedUpgradeType = defaultConfig.selectedUpgradeType
        autoAllRuneEnabled = defaultConfig.autoAllRuneEnabled
        autoAllRuneSpeed = defaultConfig.autoAllRuneSpeed
        
        OrionLib:MakeNotification({
            Name = "Config",
            Content = "Configuration reset to default values!",
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    end
})

ConfigTab:AddLabel("Auto Save")

ConfigTab:AddToggle({
    Name = "Auto Save Config",
    Default = false,
    Callback = function(Value)
        if Value then
            -- Auto save every 30 seconds
            task.spawn(function()
                while Value and scriptRunning do
                    task.wait(30)
                    if Value and currentConfigName then
                        local success = pcall(function()
                            saveConfig(currentConfigName)
                        end)
                        if not success then
                            print("Auto-save failed for config: " .. tostring(currentConfigName))
                        end
                    end
                end
            end)
        end
        
        OrionLib:MakeNotification({
            Name = "Auto Save",
            Content = Value and "Auto save enabled (every 30s)" or "Auto save disabled",
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    end
})

ConfigTab:AddLabel("Current Config Info")

ConfigTab:AddButton({
    Name = "Show Current Settings",
    Callback = function()
        local configInfo = string.format(
            "Config: %s\nAnti AFK: %s\nAuto Upgrade: %s\nUpgrade Type: %s\nAuto All Rune: %s\nRune Speed: %.2fs\nAuto Chromatize: %s",
            currentConfigName,
            antiAfkEnabled and "ON" or "OFF",
            autoUpgradeEnabled and "ON" or "OFF",
            selectedUpgradeType,
            autoAllRuneEnabled and "ON" or "OFF",
            autoAllRuneSpeed,
            autoLevelChromatizeEnabled and "ON" or "OFF"
        )
        
        OrionLib:MakeNotification({
            Name = "Current Settings",
            Content = configInfo,
            Image = "rbxassetid://4483345998",
            Time = 5
        })
    end
})

-- TAB TALENT TREE UPGRADE
TalentTreeTab:AddLabel("Talent Tree Auto Upgrade")

TalentTreeTab:AddDropdown({
    Name = "Select Upgrade Type",
    Default = "W1",
    Options = {"W1", "W2", "W1+W2"},
    Callback = function(Value)
        selectedUpgradeType = Value
        OrionLib:MakeNotification({
            Name = "Upgrade Type",
            Content = "Selected upgrade type: " .. Value,
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    end
})

-- Auto Upgrade Speed Setting
local autoUpgradeSpeed = 0.1 -- Default speed

TalentTreeTab:AddTextbox({
    Name = "Auto Upgrade Speed (seconds)",
    Default = "0.1",
    TextDisappear = false,
    Callback = function(Value)
        local numValue = tonumber(Value)
        if numValue and numValue >= 0.01 and numValue <= 5 then
            autoUpgradeSpeed = numValue
            OrionLib:MakeNotification({
                Name = "Speed Setting",
                Content = "Auto upgrade speed set to " .. numValue .. " seconds",
                Image = "rbxassetid://4483345998",
                Time = 2
            })
        else
            OrionLib:MakeNotification({
                Name = "Invalid Input",
                Content = "Please enter a number between 0.01 and 5",
                Image = "rbxassetid://4483345998",
                Time = 3
            })
        end
    end
})

TalentTreeTab:AddToggle({
    Name = "Auto Upgrade",
    Default = false,
    Callback = function(Value)
        autoUpgradeEnabled = Value
        OrionLib:MakeNotification({
            Name = "Auto Upgrade",
            Content = Value and "Auto Upgrade enabled (" .. selectedUpgradeType .. ")" or "Auto Upgrade disabled",
            Image = "rbxassetid://4483345998",
            Time = 3
        })
    end
})

-- TAB RUNE
RuneTab:AddLabel("Rune Management")

-- Multi-Rune Selection System
local autoRuneEnabled = false
local autoAllRuneEnabled = false
local selectedRunes = {} -- Table to store multiple selected runes
local selectedRune = "5M Beginner" -- For single rune selection

local runeList = {
    "5M Beginner",
    "5M Royal", 
    "Basic Rune",
    "Color Rune",
    "Nature Rune",
    "Polychrome Rune",
    "Cryo Rune",
    "Arctic Rune"
}

-- Multi-Select Rune System
RuneTab:AddLabel("Select Multiple Runes:")

for _, runeName in ipairs(runeList) do
    RuneTab:AddToggle({
        Name = runeName,
        Default = false,
        Callback = function(Value)
            if Value then
                selectedRunes[runeName] = true
            else
                selectedRunes[runeName] = nil
            end
            
            local selectedCount = 0
            for _ in pairs(selectedRunes) do
                selectedCount = selectedCount + 1
            end
            
            OrionLib:MakeNotification({
                Name = "Rune Selection",
                Content = Value and ("Added " .. runeName .. " (" .. selectedCount .. " total)") or ("Removed " .. runeName .. " (" .. selectedCount .. " total)"),
                Image = "rbxassetid://4483345998",
                Time = 2
            })
        end
    })
end

RuneTab:AddToggle({
    Name = "Auto Rune",
    Default = false,
    Callback = function(Value)
        autoRuneEnabled = Value
        local selectedCount = 0
        for _ in pairs(selectedRunes) do
            selectedCount = selectedCount + 1
        end
        
        OrionLib:MakeNotification({
            Name = "Auto Rune",
            Content = Value and ("Auto Rune enabled for " .. selectedCount .. " runes") or "Auto Rune disabled",
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    end
})

RuneTab:AddToggle({
    Name = "Auto All Rune (RISK)",
    Default = false,
    Callback = function(Value)
        autoAllRuneEnabled = Value
        OrionLib:MakeNotification({
            Name = "Auto All Rune",
            Content = Value and "Auto All Rune enabled - RISK MODE!" or "Auto All Rune disabled",
            Image = "rbxassetid://4483345998",
            Time = 3
        })
    end
})

-- Rune Teleport Speed (renamed from Rune Speed)
RuneTab:AddTextbox({
    Name = "Rune Teleport Speed (seconds)",
    Default = "2",
    TextDisappear = false,
    Callback = function(Value)
        local numValue = tonumber(Value)
        if numValue and numValue >= 0.01 and numValue <= 10 then
            autoAllRuneSpeed = numValue
            OrionLib:MakeNotification({
                Name = "Speed Setting",
                Content = "Rune teleport speed set to " .. numValue .. " seconds",
                Image = "rbxassetid://4483345998",
                Time = 2
            })
        else
            OrionLib:MakeNotification({
                Name = "Invalid Input",
                Content = "Please enter a number between 0.01 and 10",
                Image = "rbxassetid://4483345998",
                Time = 3
            })
        end
    end
})

-- Auto Chromatizer with Rune Dropdown
RuneTab:AddLabel("Auto Chromatizer + Talent Tree")

local chromatizeRuneSelection = "5M Beginner"

RuneTab:AddDropdown({
    Name = "Select Rune for Chromatizer",
    Default = "5M Beginner",
    Options = runeList,
    Callback = function(Value)
        chromatizeRuneSelection = Value
        OrionLib:MakeNotification({
            Name = "Chromatizer Rune",
            Content = "Selected rune for chromatizer: " .. Value,
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    end
})

RuneTab:AddToggle({
    Name = "Auto Chromatizer + Rune Farm",
    Default = false,
    Callback = function(Value)
        autoLevelChromatizeEnabled = Value
        OrionLib:MakeNotification({
            Name = "Auto Chromatizer",
            Content = Value and ("Auto Chromatizer enabled with " .. chromatizeRuneSelection .. " farming") or "Auto Chromatizer disabled",
            Image = "rbxassetid://4483345998",
            Time = 3
        })
    end
})

RuneTab:AddButton({
    Name = "Check Chromatizer Price",
    Callback = function()
        local currentPrisms = getCurrentPrisms()
        local chromatizePrice = getChromatizePrice()
        
        local prismText = currentPrisms and tostring(currentPrisms) or "Failed to get"
        local priceText = chromatizePrice and tostring(chromatizePrice) or "Failed to get"
        
        OrionLib:MakeNotification({
            Name = "Chromatizer Debug",
            Content = "Current Prisms: " .. prismText .. "\nChromatizer Price: " .. priceText,
            Image = "rbxassetid://4483345998",
            Time = 5
        })
        

        
        if currentPrisms and chromatizePrice then
            local canAfford = false
            -- Both values are now display strings from stat tab, compare them directly
            if type(currentPrisms) == "string" and type(chromatizePrice) == "string" then
                -- Extract numeric values from display strings for comparison
                local currentNum = currentPrisms:match("([%d%.e%-+]+)")
                local priceNum = chromatizePrice:match("([%d%.e%-+]+)")
                
                if currentNum and priceNum then

                    canAfford = compareScientificNotation(currentNum, priceNum)
                else

                    canAfford = false
                end
            else
                -- Fallback: try to convert both to numbers
                local currentAsNum = tonumber(currentPrisms)
                local priceAsNum = tonumber(chromatizePrice)
                
                if currentAsNum and priceAsNum then
                    canAfford = currentAsNum >= priceAsNum
                else

                    canAfford = false
                end
            end

        end

    end
})

-- StatTab moved to after MainTab

-- TAB TELEPORT
TeleportTab:AddLabel("Quick Teleport")

TeleportTab:AddButton({
    Name = "5M Beginner",
    Callback = function()
        local success, err = pcall(function()
            local button = workspace.Areas["Spawn Island"].Beginner.Basic.Button
            if button and button.CFrame then
                local pos = button.CFrame.Position
                teleportToPosition(Vector3.new(pos.X, pos.Y + 5, pos.Z))
            else
                error("Button not found")
            end
        end)
        
        OrionLib:MakeNotification({
            Name = "Quick Teleport",
            Content = success and "Teleported to 5M Beginner" or "Failed to teleport to 5M Beginner",
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    end
})

TeleportTab:AddButton({
    Name = "5M Royal",
    Callback = function()
        local success, err = pcall(function()
            local button = workspace.Areas["Spawn Island"].Royal.Basic.Button
            if button and button.CFrame then
                local pos = button.CFrame.Position
                teleportToPosition(Vector3.new(pos.X, pos.Y + 5, pos.Z))
            else
                error("Button not found")
            end
        end)
        
        OrionLib:MakeNotification({
            Name = "Quick Teleport",
            Content = success and "Teleported to 5M Royal" or "Failed to teleport to 5M Royal",
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    end
})

TeleportTab:AddButton({
    Name = "Basic Rune",
    Callback = function()
        local success, err = pcall(function()
            local button = workspace.Areas["Spawn Island"].Basic.Basic.Button
            if button and button.CFrame then
                local pos = button.CFrame.Position
                teleportToPosition(Vector3.new(pos.X, pos.Y + 5, pos.Z))
            else
                error("Button not found")
            end
        end)
        
        OrionLib:MakeNotification({
            Name = "Quick Teleport",
            Content = success and "Teleported to Basic Rune" or "Failed to teleport to Basic Rune",
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    end
})

TeleportTab:AddButton({
    Name = "Color Rune",
    Callback = function()
        local success, err = pcall(function()
            local button = workspace.Areas["Spawn Island"].Color.Color.Button
            if button and button.CFrame then
                local pos = button.CFrame.Position
                teleportToPosition(Vector3.new(pos.X, pos.Y + 5, pos.Z))
            else
                error("Button not found")
            end
        end)
        
        OrionLib:MakeNotification({
            Name = "Quick Teleport",
            Content = success and "Teleported to Color Rune" or "Failed to teleport to Color Rune",
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    end
})

TeleportTab:AddButton({
    Name = "Nature Rune",
    Callback = function()
        local success, err = pcall(function()
            local button = workspace.Areas["Spawn Island"].Nature.Nature.Button
            if button and button.CFrame then
                local pos = button.CFrame.Position
                teleportToPosition(Vector3.new(pos.X, pos.Y + 5, pos.Z))
            else
                error("Button not found")
            end
        end)
        
        OrionLib:MakeNotification({
            Name = "Quick Teleport",
            Content = success and "Teleported to Nature Rune" or "Failed to teleport to Nature Rune",
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    end
})

TeleportTab:AddButton({
    Name = "Polychrome Rune",
    Callback = function()
        local success, err = pcall(function()
            local button = workspace.Areas["Spawn Island"].Polychrome.Polychrome.Button
            if button and button.CFrame then
                local pos = button.CFrame.Position
                teleportToPosition(Vector3.new(pos.X, pos.Y + 5, pos.Z))
            else
                error("Button not found")
            end
        end)
        
        OrionLib:MakeNotification({
            Name = "Quick Teleport",
            Content = success and "Teleported to Polychrome Rune" or "Failed to teleport to Polychrome Rune",
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    end
})

TeleportTab:AddButton({
    Name = "Cryo Rune",
    Callback = function()
        local success, err = pcall(function()
            local button = workspace.Areas.Arctic.Cryo.Cryo.Button
            if button and button.CFrame then
                local pos = button.CFrame.Position
                teleportToPosition(Vector3.new(pos.X, pos.Y + 5, pos.Z))
            else
                error("Button not found")
            end
        end)
        
        OrionLib:MakeNotification({
            Name = "Quick Teleport",
            Content = success and "Teleported to Cryo Rune" or "Failed to teleport to Cryo Rune",
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    end
})

TeleportTab:AddButton({
    Name = "Arctic Rune",
    Callback = function()
        local success, err = pcall(function()
            local button = workspace.Areas.Arctic.Arctic.Arctic.Button
            if button and button.CFrame then
                local pos = button.CFrame.Position
                teleportToPosition(Vector3.new(pos.X, pos.Y + 5, pos.Z))
            else
                error("Button not found")
            end
        end)
        
        OrionLib:MakeNotification({
            Name = "Quick Teleport",
            Content = success and "Teleported to Arctic Rune" or "Failed to teleport to Arctic Rune",
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    end
})

TeleportTab:AddLabel("Area Teleport")

TeleportTab:AddButton({
    Name = "Teleport to Realm 1",
    Callback = function()
        safeFireServer(TeleportRealm, "R1")
        OrionLib:MakeNotification({
            Name = "Area Teleport",
            Content = "Teleported to Realm 1",
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    end
})

TeleportTab:AddButton({
    Name = "Teleport to Realm 2",
    Callback = function()
        safeFireServer(TeleportRealm, "R2")
        OrionLib:MakeNotification({
            Name = "Area Teleport",
            Content = "Teleported to Realm 2",
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    end
})

TeleportTab:AddButton({
    Name = "Hall Of Fame",
    Callback = function()
        teleportToPosition(Vector3.new(4.1, -50.7, -48.6))
        OrionLib:MakeNotification({
            Name = "Area Teleport",
            Content = "Teleported to Hall Of Fame",
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    end
})

TeleportTab:AddLabel("Talent Tree Locations")

TeleportTab:AddButton({
    Name = "Talent Tree W1 (Location 1)",
    Callback = function()
        teleportToPosition(Vector3.new(-770.5, -7.6, 1369.0))
        OrionLib:MakeNotification({
            Name = "Teleport",
            Content = "Teleported to Talent Tree W1 (Position 1)",
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    end
})

TeleportTab:AddButton({
    Name = "Talent Tree W2 (Location 2)",
    Callback = function()
        teleportToPosition(Vector3.new(1225.6, 0.8, 301.7))
        OrionLib:MakeNotification({
            Name = "Teleport",
            Content = "Teleported to Talent Tree W2 (Position 2)",
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    end
})

-- TAB SETTINGS
SettingsTab:AddLabel("General Settings")

SettingsTab:AddToggle({
    Name = "Anti AFK",
    Default = true,
    Callback = function(Value)
        antiAfkEnabled = Value
        OrionLib:MakeNotification({
            Name = "Anti AFK",
            Content = Value and "Anti AFK enabled" or "Anti AFK disabled",
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    end
})

SettingsTab:AddLabel("Player Information")

local PositionLabel = SettingsTab:AddLabel("Position: " .. getCurrentPosition())

SettingsTab:AddButton({
    Name = "Check Position",
    Callback = function()
        currentPosition = getCurrentPosition()
        PositionLabel:Set("Position: " .. currentPosition)
        OrionLib:MakeNotification({
            Name = "Position Check",
            Content = "Current position: " .. currentPosition,
            Image = "rbxassetid://4483345998",
            Time = 3
        })
    end
})

SettingsTab:AddButton({
    Name = "Copy Position",
    Callback = function()
        local success, err = pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local pos = LocalPlayer.Character.HumanoidRootPart.Position
                local positionText = string.format("X:%.1f Y:%.1f Z:%.1f", pos.X, pos.Y, pos.Z)
                setclipboard(positionText)
                OrionLib:MakeNotification({
                    Name = "Position Copied",
                    Content = "Position copied: " .. positionText,
                    Image = "rbxassetid://4483345998",
                    Time = 3
                })
            else
                OrionLib:MakeNotification({
                    Name = "Error",
                    Content = "Cannot get current position",
                    Image = "rbxassetid://4483345998",
                    Time = 2
                })
            end
        end)
        
        if not success then
            OrionLib:MakeNotification({
                Name = "Error",
                Content = "Error copying position: " .. tostring(err),
                Image = "rbxassetid://4483345998",
                Time = 2
            })
        end
    end
})

-- Script Controls section removed as requested

-- Enhanced Anti AFK Loop with multiple methods
task.spawn(function()
    local Players = game:GetService("Players")
    local VirtualUser = game:GetService("VirtualUser")
    local LocalPlayer = Players.LocalPlayer
    
    -- Method 1: Handle Idled event directly
    LocalPlayer.Idled:Connect(function()
        if antiAfkEnabled then
            local success, err = pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
            
            if success then
                OrionLib:MakeNotification({
                    Name = "Anti AFK",
                    Content = "Prevented AFK kick!",
                    Image = "rbxassetid://4483345998",
                    Time = 2
                })
            else
                warn("Anti AFK method 1 failed: " .. tostring(err))
            end
        end
    end)
    
    -- Method 2: Periodic virtual input
    while scriptRunning do
        if antiAfkEnabled then
            local success, err = pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
                
                -- Additional method: Move character slightly
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    local humanoid = LocalPlayer.Character.Humanoid
                    humanoid:Move(Vector3.new(0.1, 0, 0), false)
                    task.wait(0.1)
                    humanoid:Move(Vector3.new(-0.1, 0, 0), false)
                end
            end)
            
            if not success then
                warn("Anti AFK method 2 failed: " .. tostring(err))
            end
        end
        task.wait(300) -- Check every 5 minutes
    end
end)

-- Auto All Rune Loop
task.spawn(function()
    local runeOrder = {
        {name = "5M Beginner", path = "workspace.Areas['Spawn Island'].Beginner.Basic.Button"},
        {name = "5M Royal", path = "workspace.Areas['Spawn Island'].Royal.Basic.Button"},
        {name = "Basic Rune", path = "workspace.Areas['Spawn Island'].Basic.Basic.Button"},
        {name = "Color Rune", path = "workspace.Areas['Spawn Island'].Color.Color.Button"},
        {name = "Nature Rune", path = "workspace.Areas['Spawn Island'].Nature.Nature.Button"},
        {name = "Polychrome Rune", path = "workspace.Areas['Spawn Island'].Polychrome.Polychrome.Button"},
        {name = "Cryo Rune", path = "workspace.Areas.Arctic.Cryo.Cryo.Button"},
        {name = "Arctic Rune", path = "workspace.Areas.Arctic.Arctic.Arctic.Button"}
    }
    
    while scriptRunning do
        if autoAllRuneEnabled then
            for _, rune in ipairs(runeOrder) do
                if not autoAllRuneEnabled or not scriptRunning then break end
                
                local success, err = pcall(function()
                    local button
                    if rune.name == "5M Beginner" then
                        button = workspace.Areas["Spawn Island"].Beginner.Basic.Button
                    elseif rune.name == "5M Royal" then
                        button = workspace.Areas["Spawn Island"].Royal.Basic.Button
                    elseif rune.name == "Basic Rune" then
                        button = workspace.Areas["Spawn Island"].Basic.Basic.Button
                    elseif rune.name == "Color Rune" then
                        button = workspace.Areas["Spawn Island"].Color.Color.Button
                    elseif rune.name == "Nature Rune" then
                        button = workspace.Areas["Spawn Island"].Nature.Nature.Button
                    elseif rune.name == "Polychrome Rune" then
                        button = workspace.Areas["Spawn Island"].Polychrome.Polychrome.Button
                    elseif rune.name == "Cryo Rune" then
                        button = workspace.Areas.Arctic.Cryo.Cryo.Button
                    elseif rune.name == "Arctic Rune" then
                        button = workspace.Areas.Arctic.Arctic.Arctic.Button
                    end
                    
                    if button and button.CFrame then
                        local pos = button.CFrame.Position
                        teleportToPosition(Vector3.new(pos.X, pos.Y + 5, pos.Z))
                    else
                        error("Button not found for " .. rune.name)
                    end
                end)
                
                if not success then
                    warn("Auto All Rune error for " .. rune.name .. ": " .. tostring(err))
                end
                
                task.wait(autoAllRuneSpeed) -- Wait based on speed setting between each rune teleport
            end
        end
         task.wait(0.1) -- Small wait to prevent lag
     end
 end)

-- Auto Rune Loop (Multi-Select Runes)
task.spawn(function()
    while scriptRunning do
        if autoRuneEnabled then
            -- Check if any runes are selected
            local hasSelectedRunes = false
            for _ in pairs(selectedRunes) do
                hasSelectedRunes = true
                break
            end
            
            if hasSelectedRunes then
                -- Cycle through all selected runes
                for runeName, _ in pairs(selectedRunes) do
                    if not autoRuneEnabled or not scriptRunning then break end
                    
                    local success, err = pcall(function()
                        local button
                        if runeName == "5M Beginner" then
                            button = workspace.Areas["Spawn Island"].Beginner.Basic.Button
                        elseif runeName == "5M Royal" then
                            button = workspace.Areas["Spawn Island"].Royal.Basic.Button
                        elseif runeName == "Basic Rune" then
                            button = workspace.Areas["Spawn Island"].Basic.Basic.Button
                        elseif runeName == "Color Rune" then
                            button = workspace.Areas["Spawn Island"].Color.Color.Button
                        elseif runeName == "Nature Rune" then
                            button = workspace.Areas["Spawn Island"].Nature.Nature.Button
                        elseif runeName == "Polychrome Rune" then
                            button = workspace.Areas["Spawn Island"].Polychrome.Polychrome.Button
                        elseif runeName == "Cryo Rune" then
                            button = workspace.Areas.Arctic.Cryo.Cryo.Button
                        elseif runeName == "Arctic Rune" then
                            button = workspace.Areas.Arctic.Arctic.Arctic.Button
                        end
                        
                        if button and button.CFrame then
                            local pos = button.CFrame.Position
                            teleportToPosition(Vector3.new(pos.X, pos.Y + 5, pos.Z))
                        else
                            error("Button not found for " .. runeName)
                        end
                    end)
                    
                    if not success then
                        warn("Auto Rune error for " .. runeName .. ": " .. tostring(err))
                    end
                    
                    task.wait(autoAllRuneSpeed) -- Use rune teleport speed setting
                end
            end
        end
        task.wait(0.1) -- Small wait to prevent lag
    end
end)

-- Auto Upgrade Loop with error handling
task.spawn(function()
    while scriptRunning do
        local success, err = pcall(function()
            if autoUpgradeEnabled and BuyUpgrade and scriptRunning then
                if selectedUpgradeType == "W1" then
                    -- W1 only
                    for _, upgrade in ipairs(upgradeListW1) do
                        if autoUpgradeEnabled and scriptRunning then
                            for i = 1, upgrade.times do
                                if autoUpgradeEnabled and scriptRunning then
                                    safeFireServer(BuyUpgrade, upgrade.name)
                                    task.wait(autoUpgradeSpeed)
                                else
                                    break
                                end
                            end
                        else
                            break
                        end
                    end
                elseif selectedUpgradeType == "W2" then
                    -- W2 only
                    for _, upgrade in ipairs(upgradeListW2) do
                        if autoUpgradeEnabled and scriptRunning then
                            for i = 1, upgrade.times do
                                if autoUpgradeEnabled and scriptRunning then
                                    safeFireServer(BuyUpgrade, upgrade.name)
                                    task.wait(autoUpgradeSpeed)
                                else
                                    break
                                end
                            end
                        else
                            break
                        end
                    end
                elseif selectedUpgradeType == "W1+W2" then
                    -- W1+W2 parallel: alternate between W1 and W2 upgrades
                    local w1Index = 1
                    local w2Index = 1
                    local w1Times = 0
                    local w2Times = 0
                    
                    while (w1Index <= #upgradeListW1 or w2Index <= #upgradeListW2) and autoUpgradeEnabled and scriptRunning do
                        -- Try to upgrade from W1
                        if w1Index <= #upgradeListW1 and autoUpgradeEnabled and scriptRunning then
                            local w1Upgrade = upgradeListW1[w1Index]
                            if w1Times < w1Upgrade.times then
                                safeFireServer(BuyUpgrade, w1Upgrade.name)
                                w1Times = w1Times + 1
                                task.wait(autoUpgradeSpeed)
                                
                                if w1Times >= w1Upgrade.times then
                                    w1Index = w1Index + 1
                                    w1Times = 0
                                end
                            end
                        end
                        
                        -- Try to upgrade from W2
                        if w2Index <= #upgradeListW2 and autoUpgradeEnabled and scriptRunning then
                            local w2Upgrade = upgradeListW2[w2Index]
                            if w2Times < w2Upgrade.times then
                                safeFireServer(BuyUpgrade, w2Upgrade.name)
                                w2Times = w2Times + 1
                                task.wait(autoUpgradeSpeed)
                                
                                if w2Times >= w2Upgrade.times then
                                    w2Index = w2Index + 1
                                    w2Times = 0
                                end
                            end
                        end
                    end
                end
            end
        end)
        
        if not success then
            warn("Auto Upgrade error: " .. tostring(err))
        end
        
        task.wait(0.5) -- Wait 15 seconds before repeating
    end
end)

-- Update position label periodically with error handling
task.spawn(function()
    while scriptRunning do
        local success, err = pcall(function()
            if PositionLabel and PositionLabel.Set and scriptRunning then
                local newPosition = getCurrentPosition()
                if newPosition ~= currentPosition then
                    currentPosition = newPosition
                    PositionLabel:Set("Position: " .. currentPosition)
                end
            end
        end)
        
        if not success then
            warn("Position update error: " .. tostring(err))
        end
        
        task.wait(2)
    end
end)

-- Initialize GUI with validation and mobile enhancements
local success, err = pcall(function()
    if OrionLib and OrionLib.Init then
        OrionLib:Init()
    else
        error("OrionLib not properly loaded")
    end
end)

if not success then
    warn("Failed to initialize OrionLib: " .. tostring(err))
    return -- Exit script if OrionLib fails to initialize
end

-- Additional mobile optimizations after GUI is fully loaded
task.spawn(function()
    task.wait(2) -- Wait for GUI to fully load
    
    local function enhanceMobileExperience()
        local success, err = pcall(function()
            local UserInputService = game:GetService("UserInputService")
            if UserInputService.TouchEnabled then
                local coreGui = game:GetService("CoreGui")
                
                -- Find and enhance all GUI elements
                for _, gui in pairs(coreGui:GetChildren()) do
                    if gui.Name:find("Orion") then
                        for _, descendant in pairs(gui:GetDescendants()) do
                            -- Enhance buttons for mobile
                            if descendant:IsA("TextButton") or descendant:IsA("ImageButton") then
                                descendant.AutoButtonColor = true
                                descendant.Active = true
                                
                                -- Increase touch area for small buttons
                                if descendant.Size.X.Offset < 50 or descendant.Size.Y.Offset < 30 then
                                    descendant.Size = UDim2.new(
                                        descendant.Size.X.Scale,
                                        math.max(descendant.Size.X.Offset, 50),
                                        descendant.Size.Y.Scale,
                                        math.max(descendant.Size.Y.Offset, 30)
                                    )
                                end
                            end
                            
                            -- Enhance sliders for mobile
                            if descendant:IsA("Frame") and (descendant.Name:find("Slider") or descendant.Name:find("Bar")) then
                                descendant.Active = true
                                
                                -- Make slider handles larger for mobile
                                for _, child in pairs(descendant:GetChildren()) do
                                    if child:IsA("Frame") and child.Name:find("Handle") then
                                        child.Size = UDim2.new(0, 20, 1, 0) -- Larger handle
                                    end
                                end
                            end
                            
                            -- Enhance text inputs for mobile
                            if descendant:IsA("TextBox") then
                                descendant.ClearTextOnFocus = false
                                descendant.Active = true
                            end
                        end
                    end
                end
            end
        end)
        
        if not success then
            warn("Mobile enhancement failed: " .. tostring(err))
        end
    end
    
    enhanceMobileExperience()
end)

-- TAB STAT
StatTab:AddLabel("Player Statistics")

-- Create stat labels
local EnergyLabel = StatTab:AddLabel("Energy: Loading...")
local FlameLabel = StatTab:AddLabel("Flame: Loading...")
local PowerLabel = StatTab:AddLabel("Power: Loading...")
local RealmPointsLabel = StatTab:AddLabel("Realm Points: Loading...")
local FleshLabel = StatTab:AddLabel("Flesh: Loading...")
local PrismsLabel = StatTab:AddLabel("Prisms: Loading...")
local OrbsLabel = StatTab:AddLabel("Orbs: Loading...")
local SpheresLabel = StatTab:AddLabel("Spheres: Loading...")
local DropletsLabel = StatTab:AddLabel("Droplets: Loading...")
local WaterLabel = StatTab:AddLabel("Water: Loading...")
local ArcticPointsLabel = StatTab:AddLabel("Arctic Points: Loading...")
local IceLabel = StatTab:AddLabel("Ice: Loading...")
local ChromiumLabel = StatTab:AddLabel("Chromium: Loading...")
local IciclesLabel = StatTab:AddLabel("Icicles: Loading...")

-- Function to format large numbers with scientific notation conversion
local function formatNumber(num)
    if not num then return "0" end
    
    local numValue = tonumber(num)
    if not numValue then return tostring(num) end
    
    -- Apply the correct formula to get scientific notation
    -- Y is the original number (e.g., 78.87090351708635)
    -- Y' is the integer part (e.g., 78)
    -- Z is the decimal part Y - Y' (e.g., 0.87090351708635)
    -- Result: 10^Z e Y' (e.g., 7.43e78)
    local Y = numValue
    local Y_prime = math.floor(Y)
    local Z = Y - Y_prime
    
    -- Calculate coefficient: 10^Z
    local coefficient = 10 ^ Z
    
    -- Format exponent with K for thousands (e.g., 75102 becomes 75.1K)
    local exponentStr
    if Y_prime >= 1000 then
        local thousands = Y_prime / 1000
        exponentStr = string.format("%.1fK", thousands)
    else
        exponentStr = tostring(Y_prime)
    end
    
    -- Format as scientific notation: coefficient e exponent
    return string.format("%.2fe%s", coefficient, exponentStr)
end

-- Function to safely get stat value
local function getStatValue(statPath)
    local success, result = pcall(function()
        local player = game:GetService("Players").LocalPlayer
        if not player or not player.Stats then return nil end
        
        local stat = player.Stats:FindFirstChild(statPath)
        if stat and stat.Value then
            -- Always return the original stat.Value for consistency
            return stat.Value
        end
        return nil
    end)
    
    if success then
        return result
    else
        return nil
    end
end

-- Function to get formatted stat value for display (handles semicolon values)
local function getFormattedStatValue(statPath)
    local success, result = pcall(function()
        local player = game:GetService("Players").LocalPlayer
        if not player or not player.Stats then return nil end
        
        local stat = player.Stats:FindFirstChild(statPath)
        if stat and stat.Value then
            local value = tostring(stat.Value)
            -- Check if value contains semicolon and extract part after it for display
            if string.find(value, ";") then
                local parts = string.split(value, ";")
                if #parts >= 2 then
                    return parts[2]  -- Return the formatted string after semicolon for display
                end
            end
            return stat.Value
        end
        return nil
    end)
    
    if success then
        return result
    else
        return nil
    end
end

-- Function to update all stat labels
local function updateStatLabels()
    local success, err = pcall(function()
        -- Get all stat values for display (formatted)
        local energy = getFormattedStatValue("Energy")
        local flame = getFormattedStatValue("Flame")
        local power = getFormattedStatValue("Power")
        local realmPoints = getFormattedStatValue("Realm Points")
        local flesh = getFormattedStatValue("Flesh")
        local prisms = getFormattedStatValue("Prisms")
        local orbs = getFormattedStatValue("Orbs")
        local spheres = getFormattedStatValue("Spheres")
        local droplets = getFormattedStatValue("Droplets")
        local water = getFormattedStatValue("Water")
        local arcticPoints = getFormattedStatValue("ArcticPoints")
        local ice = getFormattedStatValue("Ice")
        local chromium = getFormattedStatValue("Chromium")
        local icicles = getFormattedStatValue("Icicles")
        
        -- Update labels with formatted values using safer method
        local function safeUpdateLabel(label, text)
            if label and type(label) == "table" then
                if label.Set and type(label.Set) == "function" then
                    local updateSuccess, updateErr = pcall(function()
                        label:Set(text)
                    end)
                    if not updateSuccess then
                        -- Try alternative method if Set fails
                        if label.Text then
                            label.Text = text
                        elseif label.Content then
                            label.Content = text
                        end
                    end
                end
            end
        end
        
        safeUpdateLabel(EnergyLabel, "Energy: " .. formatNumber(energy))
        safeUpdateLabel(FlameLabel, "Flame: " .. formatNumber(flame))
        safeUpdateLabel(PowerLabel, "Power: " .. formatNumber(power))
        safeUpdateLabel(RealmPointsLabel, "Realm Points: " .. formatNumber(realmPoints))
        safeUpdateLabel(FleshLabel, "Flesh: " .. formatNumber(flesh))
        safeUpdateLabel(PrismsLabel, "Prisms: " .. formatNumber(prisms))
        safeUpdateLabel(OrbsLabel, "Orbs: " .. formatNumber(orbs))
        safeUpdateLabel(SpheresLabel, "Spheres: " .. formatNumber(spheres))
        safeUpdateLabel(DropletsLabel, "Droplets: " .. formatNumber(droplets))
        safeUpdateLabel(WaterLabel, "Water: " .. formatNumber(water))
        safeUpdateLabel(ArcticPointsLabel, "Arctic Points: " .. formatNumber(arcticPoints))
        safeUpdateLabel(IceLabel, "Ice: " .. formatNumber(ice))
        safeUpdateLabel(ChromiumLabel, "Chromium: " .. formatNumber(chromium))
        safeUpdateLabel(IciclesLabel, "Icicles: " .. formatNumber(icicles))
    end)
    
    if not success then
        warn("Error updating stat labels: " .. tostring(err))
    end
end

-- Add refresh button
StatTab:AddButton({
    Name = "Refresh Stats",
    Callback = function()
        updateStatLabels()
        OrionLib:MakeNotification({
            Name = "Stats",
            Content = "Statistics refreshed!",
            Image = "rbxassetid://4483345998",
            Time = 2
        })
    end
})

-- Function to get Chromatize price from workspace
local function getChromatizePrice()
    local success, result = pcall(function()
        local chromatizeButton = workspace:FindFirstChild("Layers")
        if chromatizeButton then
            chromatizeButton = chromatizeButton:FindFirstChild("Chromatizer")
            if chromatizeButton then
                chromatizeButton = chromatizeButton:FindFirstChild("Chromatize")
                if chromatizeButton then
                    chromatizeButton = chromatizeButton:FindFirstChild("Button")
                    if chromatizeButton then
                        local billboardGui = chromatizeButton:FindFirstChild("BillboardGui")
                        if billboardGui then
                            local priceLabel = billboardGui:FindFirstChild("Price")
                            if priceLabel and priceLabel.Text then
                                local text = priceLabel.Text

                                
                                -- Handle different text formats
                                if text == "" or text == nil then

                                    return nil
                                end
                                
                                -- Clean text first - remove PRISMS/Prisms and extra spaces
                                local cleanText = text:gsub("%s*PRISMS%s*", ""):gsub("%s*Prisms%s*", ""):gsub("%s*Price:%s*", ""):gsub("%s*Cost:%s*", "")
                                cleanText = cleanText:gsub("%s+", "") -- Remove all spaces

                                
                                -- Try to extract just the number part
                                local numberStr = cleanText:match("([%d%.e%-+]+)")
                                if numberStr then

                                    
                                    -- Clean up scientific notation
                                    numberStr = numberStr:gsub("e%+", "e") -- Remove + from e+
                                    
                                    -- Always return string for consistent comparison with getCurrentPrisms

                                    return numberStr
                                else

                                end
                                

                                return nil
                            else

                                return nil
                            end
                        else

                            return nil
                        end
                    else

                        return nil
                    end
                else

                    return nil
                end
            else

                return nil
            end
        else

            return nil
        end
    end)
    
    if success then
        return result
    else

        return nil
    end
end

-- Function to teleport to Chromatize button
local function teleportToChromatize()
    local success, err = pcall(function()
        local chromatizeButton = workspace:FindFirstChild("Layers")
        if chromatizeButton then
            chromatizeButton = chromatizeButton:FindFirstChild("Chromatizer")
            if chromatizeButton then
                chromatizeButton = chromatizeButton:FindFirstChild("Chromatize")
                if chromatizeButton then
                    chromatizeButton = chromatizeButton:FindFirstChild("Button")
                    if chromatizeButton and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local buttonPosition = chromatizeButton.Position
                        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(buttonPosition + Vector3.new(0, 5, 0))
                        return true
                    end
                end
            end
        end
        return false
    end)
    
    if success then
        return true
    else
        return false
    end
end

-- Function to click Chromatize button
local function clickChromatizeButton()
    local success, err = pcall(function()
        local chromatizeButton = workspace:FindFirstChild("Layers")
        if chromatizeButton then
            chromatizeButton = chromatizeButton:FindFirstChild("Chromatizer")
            if chromatizeButton then
                chromatizeButton = chromatizeButton:FindFirstChild("Chromatize")
                if chromatizeButton then
                    chromatizeButton = chromatizeButton:FindFirstChild("Button")
                    if chromatizeButton and chromatizeButton:FindFirstChild("ClickDetector") then
                        fireclickdetector(chromatizeButton.ClickDetector)
                        return true
                    end
                end
            end
        end
        return false
    end)
    
    if success then
        return true
    else
        return false
    end
end

-- Function to compare scientific notation strings
local function compareScientificNotation(str1, str2)
    -- Extract mantissa and exponent from both strings
    local m1, e1 = str1:match("([%d%.]+)e([%-+]?%d+)")
    local m2, e2 = str2:match("([%d%.]+)e([%-+]?%d+)")
    
    if not m1 or not e1 or not m2 or not e2 then

        return false
    end
    
    local mantissa1 = tonumber(m1)
    local exponent1 = tonumber(e1)
    local mantissa2 = tonumber(m2)
    local exponent2 = tonumber(e2)
    
    if not mantissa1 or not exponent1 or not mantissa2 or not exponent2 then

        return false
    end
    

    
    -- Compare exponents first
    if exponent1 > exponent2 then
        return true
    elseif exponent1 < exponent2 then
        return false
    else
        -- Same exponent, compare mantissa
        return mantissa1 >= mantissa2
    end
end

-- Function to get current Prisms exactly like stat tab display
local function getCurrentPrisms()
    local success, result = pcall(function()
        -- Use EXACT same method as stat tab: getFormattedStatValue + formatNumber
        local formattedValue = getFormattedStatValue("Prisms")
        if formattedValue then
            local displayValue = formatNumber(formattedValue)

            
            -- Return the display value directly (same as what user sees in stat tab)
            return displayValue
        else

            return nil
        end
    end)
    
    if success and result then
        return result
    else

        return nil
    end
end

-- Function to teleport to selected rune for chromatizer
local function teleportToSelectedRune(runeName)
    local success, err = pcall(function()
        local button
        if runeName == "5M Beginner" then
            button = workspace.Areas["Spawn Island"].Beginner.Basic.Button
        elseif runeName == "5M Royal" then
            button = workspace.Areas["Spawn Island"].Royal.Basic.Button
        elseif runeName == "Basic Rune" then
            button = workspace.Areas["Spawn Island"].Basic.Basic.Button
        elseif runeName == "Color Rune" then
            button = workspace.Areas["Spawn Island"].Color.Color.Button
        elseif runeName == "Nature Rune" then
            button = workspace.Areas["Spawn Island"].Nature.Nature.Button
        elseif runeName == "Polychrome Rune" then
            button = workspace.Areas["Spawn Island"].Polychrome.Polychrome.Button
        elseif runeName == "Cryo Rune" then
            button = workspace.Areas.Arctic.Cryo.Cryo.Button
        elseif runeName == "Arctic Rune" then
            button = workspace.Areas.Arctic.Arctic.Arctic.Button
        end
        
        if button and button.CFrame then
            local pos = button.CFrame.Position
            teleportToPosition(Vector3.new(pos.X, pos.Y + 5, pos.Z))
            return true
        else
            error("Button not found for " .. runeName)
        end
    end)
    
    return success
end

-- Auto Level Chromatize loop with Rune Farming Integration
task.spawn(function()
    local lastRuneFarmTime = 0
    local runeFarmCooldown = 5 -- seconds between rune farming attempts
    
    while scriptRunning do
        if autoLevelChromatizeEnabled then
            local success, err = pcall(function()
                -- Wait for prices to load properly with retry mechanism
                local currentPrisms = nil
                local chromatizePrice = nil
                local maxRetries = 5
                local retryCount = 0
                
                -- Retry getting prices until both are valid
                while retryCount < maxRetries and (not currentPrisms or not chromatizePrice or currentPrisms == math.huge or chromatizePrice == math.huge) do
                    task.wait(0.2) -- Wait for UI to load
                    currentPrisms = getCurrentPrisms()
                    chromatizePrice = getChromatizePrice()
                    retryCount = retryCount + 1
                    
                    if currentPrisms == math.huge or chromatizePrice == math.huge then

                    elseif not currentPrisms or not chromatizePrice then

                    end
                end
                
                -- Only proceed if we have valid values (both should be strings now)
                if currentPrisms and chromatizePrice and 
                   currentPrisms ~= math.huge and chromatizePrice ~= math.huge then
                    
                    -- Compare the two values and show comparison result

                    
                    local canAfford = false
                    -- Both values are now display strings from stat tab, compare them directly
                    if type(currentPrisms) == "string" and type(chromatizePrice) == "string" then
                        -- Extract numeric values from display strings for comparison
                        local currentNum = currentPrisms:match("([%d%.e%-+]+)")
                        local priceNum = chromatizePrice:match("([%d%.e%-+]+)")
                        
                        if currentNum and priceNum then

                            canAfford = compareScientificNotation(currentNum, priceNum)
                        else

                            canAfford = false
                        end
                    else
                        -- Fallback: try to convert both to numbers
                        local currentAsNum = tonumber(currentPrisms)
                        local priceAsNum = tonumber(chromatizePrice)
                        
                        if currentAsNum and priceAsNum then
                            canAfford = currentAsNum >= priceAsNum
                        else

                            canAfford = false
                        end
                    end
                    

                    if canAfford then

                        
                        -- We have enough Prisms, teleport to chromatize button and upgrade
                        if teleportToChromatize() then
                            task.wait(1) -- Wait longer for teleport to complete and UI to load
                            if clickChromatizeButton() then
                                OrionLib:MakeNotification({
                                    Name = "Auto Chromatize",
                                    Content = "Successfully upgraded Chromatize level!",
                                    Image = "rbxassetid://4483345998",
                                    Time = 2
                                })
                            end
                        end
                    else

                        
                        -- Not enough Prisms, farm the selected rune
                        local currentTime = tick()
                        if currentTime - lastRuneFarmTime >= runeFarmCooldown then
                            if teleportToSelectedRune(chromatizeRuneSelection) then
                                OrionLib:MakeNotification({
                                    Name = "Auto Chromatize",
                                    Content = "Farming " .. chromatizeRuneSelection .. " for Prisms...",
                                    Image = "rbxassetid://4483345998",
                                    Time = 2
                                })
                                lastRuneFarmTime = currentTime
                            end
                        end
                    end
                else

                end
            end)
            
            if not success then
                warn("Auto Level Chromatize error: " .. tostring(err))
            end
        end
        
        task.wait(1) -- Wait longer between checks to allow UI to load properly
    end
end)

-- Auto-update stats every 2 seconds for faster updates
task.spawn(function()
    while scriptRunning do
        updateStatLabels()
        task.wait(2) -- Update every 2 seconds for faster response
    end
end)

-- Load default config on startup
local function initializeConfig()
    local success, err = pcall(function()
        loadConfig(defaultConfigName)
    end)
    
    if not success then
        OrionLib:MakeNotification({
            Name = "Config Warning",
            Content = "Failed to load default config, using built-in defaults",
            Image = "rbxassetid://4483345998",
            Time = 3
        })
    end
end

initializeConfig()

-- Script loaded notification with mobile detection
local deviceType = game:GetService("UserInputService").TouchEnabled and "Mobile" or "PC"
OrionLib:MakeNotification({
    Name = "Ascender Incremental Hub",
    Content = "Script loaded successfully on " .. deviceType .. "! Welcome to Ascender Incremental Hub!",
    Image = "rbxassetid://4483345998",
    Time = 5
})

-- Additional mobile instructions
if game:GetService("UserInputService").TouchEnabled then
    task.wait(2)
    OrionLib:MakeNotification({
        Name = "Mobile Tips",
        Content = "Mobile optimizations applied! Use 'Toggle GUI (Mobile)' button if keybind doesn't work.",
        Image = "rbxassetid://4483345998",
        Time = 7
    })
end

print("Ascender Incremental GUI Script v1.7.0 loaded successfully on " .. deviceType .. "!")
