-- ================================================
-- EGGS TAB (UPDATED - REMOVED DEAD EGGS + FIXED AUTO HATCH)
-- ================================================
repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local EggsTab = Window:CreateTab("Eggs", nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer

-- ======================================
-- DATA MODULES
-- ======================================
local SecretBountyUtil = require(ReplicatedStorage.Shared.Utils.Stats.SecretBountyUtil)
local XLEggUtil = require(ReplicatedStorage.Shared.Utils.XLEggUtil)
local Rifts = require(ReplicatedStorage.Shared.Data.Rifts)
local Remote = require(ReplicatedStorage.Shared.Framework.Network.Remote)
local RemoteFunction = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteFunction
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)

-- ======================================
-- LOAD SAVED SETTINGS
-- ======================================
local settings = getgenv().HubSettings or {}
if not settings.eggs then settings.eggs = {} end
local eggSettings = settings.eggs

-- ======================================
-- EGG LOCATIONS (NO POPCORN/SWEET/EXOTIC/OBSIDIAN)
-- ======================================
local EGG_LOCATIONS = {
    ["Common Egg"] = Vector3.new(-80, 7, 5),
    ["Classic Egg"] = Vector3.new(-90, 13, 30),
    ["Vine Egg"] = Vector3.new(-61, 13, 11),
    ["Lava Egg"] = Vector3.new(-69, 14, 19),
    ["Icy Egg"] = Vector3.new(-55, 14, 0),
    ["Iceshard Egg"] = Vector3.new(-119, 11, 13),
    ["Spotted Egg"] = Vector3.new(-11, 10, -69),
    ["Atlantis Egg"] = Vector3.new(-79, 14, 25),
    ["Mining Egg"] = Vector3.new(-122, 11, -69),
    ["Neon Egg"] = Vector3.new(-81, 10, -61),
    ["Cyber Egg"] = Vector3.new(-92, 10, -67),
    ["Rainbow Egg"] = Vector3.new(-140, 10, -57),
    ["Nightmare Egg"] = Vector3.new(-146, 10, -47),
    ["Infinity Egg"] = Vector3.new(-106, 12, -28),
    ["Secret Egg"] = Vector3.new(-19438, 8, 18839),
    ["Showman Egg"] = Vector3.new(-130, 10, -60),
    ["Spikey Egg"] = Vector3.new(-128, 10, 9),
    ["Magma Egg"] = Vector3.new(-137, 11, 3),
    ["Crystal Egg"] = Vector3.new(-144, 10, -5),
    ["Lunar Egg"] = Vector3.new(-148, 11, -15),
    ["Void Egg"] = Vector3.new(-150, 11, -26),
    ["Hell Egg"] = Vector3.new(-149, 11, -37),
}

local EGG_WORLDS = {
    ["Common Egg"] = "The Overworld",
    ["Classic Egg"] = "The Overworld",
    ["Vine Egg"] = "The Overworld",
    ["Lava Egg"] = "The Overworld",
    ["Icy Egg"] = "The Overworld",
    ["Iceshard Egg"] = "The Overworld",
    ["Spotted Egg"] = "The Overworld",
    ["Atlantis Egg"] = "The Overworld",
    ["Mining Egg"] = "Minigame Paradise",
    ["Neon Egg"] = "Minigame Paradise",
    ["Cyber Egg"] = "Minigame Paradise",
    ["Rainbow Egg"] = "The Overworld",
    ["Nightmare Egg"] = "The Overworld",
    ["Infinity Egg"] = "The Overworld",
    ["Secret Egg"] = "The Overworld",
    ["Showman Egg"] = "The Overworld",
    ["Spikey Egg"] = "The Overworld",
    ["Magma Egg"] = "The Overworld",
    ["Crystal Egg"] = "The Overworld",
    ["Lunar Egg"] = "The Overworld",
    ["Void Egg"] = "The Overworld",
    ["Hell Egg"] = "The Overworld",
}

local discoveredEggs = {}

-- ======================================
-- INVENTORY EGGS LIST
-- ======================================
local function getInventoryEggs()
    local eggs = {}
    local data = LocalData:Get()
    if data and data.Powerups then
        for name, amount in pairs(data.Powerups) do
            if name:find("Egg") and amount > 0 and name ~= "Royal Egg" then
                table.insert(eggs, name)
            end
        end
    end
    if #eggs == 0 then
        eggs = {"Dominus Egg", "Stellaris Egg", "Neon Crystal Egg"}
    end
    table.sort(eggs)
    return eggs
end

-- ======================================
-- VARIABLES
-- ======================================
local HATCH_AMOUNT = eggSettings.hatchAmount or 12
local selectedEgg = eggSettings.selectedEgg or "Common Egg"
local currentBountyPet = "Unknown"
local currentBountyEgg = "Unknown"
local currentBountyChance = "Unknown"

local corruptShadowEnabled = eggSettings.autoCorruptShadow or false
local overlordEnabled = eggSettings.autoOverlord or false
local fourXEnabled = eggSettings.auto4x or false
local shadowEnabled = eggSettings.autoShadow or false
local doodleEnabled = eggSettings.autoDoodle or false
local autoHatchEnabled = eggSettings.autoHatch or false
local spamEEnabled = eggSettings.autoSpamE or false
local hideAnimEnabled = eggSettings.hideAnim or false
local inventoryEnabled = false
local bountyEnabled = eggSettings.autoBounty or false
local riftEnabled = eggSettings.autoRiftBounty or false
local xlBountyRunning = false

local corruptShadowThread = nil
local overlordThread = nil
local fourXThread = nil
local shadowThread = nil
local doodleThread = nil
local autoHatchThread = nil
local spamEThread = nil
local inventoryThread = nil
local bountyThread = nil
local riftThread = nil
local xlBountyThread = nil

local inventoryEggList = getInventoryEggs()
local selectedInventoryEgg = eggSettings.inventoryEgg or inventoryEggList[1] or "Dominus Egg"

local lastTeleportTime = 0

-- XL Bounty
local selectedXLEgg = ""

local function getXLEggs()
    local eggs = {}
    pcall(function()
        local xlEggs = XLEggUtil:GetEggs()
        if xlEggs then
            for _, egg in ipairs(xlEggs) do
                table.insert(eggs, egg)
            end
        end
    end)
    if #eggs == 0 then
        eggs = {"Rainbow Egg", "Crystal Ore Egg"}
    end
    return eggs
end

local xlEggList = getXLEggs()
selectedXLEgg = xlEggList[1]

-- ======================================
-- FUNCTIONS
-- ======================================
local function getRoot()
    local char = player.Character
    if char then return char:FindFirstChild("HumanoidRootPart") end
end

local function getDistance(pos)
    local root = getRoot()
    if root and pos then
        return (root.Position - pos).Magnitude
    end
    return 999999
end

local function eggNameToKey(name)
    return name:lower():gsub("%s+", "-")
end

-- ======================================
-- HIGHEST LUCK RIFT FUNCTIONS
-- ======================================
local function getRiftLuck(rift)
    local display = rift:FindFirstChild("Display")
    if display then
        local surfaceGui = display:FindFirstChild("SurfaceGui")
        if surfaceGui then
            for _, child in ipairs(surfaceGui:GetDescendants()) do
                if child:IsA("TextLabel") and child.Text:find("Luck") then
                    local luck = child.Text:match("x(%d+)")
                    if luck then
                        return tonumber(luck)
                    end
                end
            end
        end
    end
    return 0
end

local function getHighestLuckRift(riftName)
    local riftFolder = workspace:FindFirstChild("Rendered")
    if riftFolder then
        riftFolder = riftFolder:FindFirstChild("Rifts")
        if riftFolder then
            local bestRift = nil
            local bestLuck = 0
            
            for _, rift in ipairs(riftFolder:GetChildren()) do
                if rift.Name == riftName then
                    local luck = getRiftLuck(rift)
                    if luck > bestLuck then
                        bestLuck = luck
                        bestRift = rift
                    end
                end
            end
            
            return bestRift, bestLuck
        end
    end
    return nil, 0
end

local function getRiftPositionFromRift(rift)
    if rift then
        local spawn = rift:FindFirstChild("EggPlatformSpawn")
        if spawn then
            local part = spawn:FindFirstChild("Part")
            if part then return part.Position end
            if spawn:IsA("BasePart") then return spawn.Position end
        end
        for _, child in ipairs(rift:GetDescendants()) do
            if child:IsA("BasePart") then
                return child.Position
            end
        end
    end
    return nil
end

local function teleportToBestRift(eggName)
    local riftKey = eggNameToKey(eggName)
    local bestRift, bestLuck = getHighestLuckRift(riftKey)
    if bestRift then
        local pos = getRiftPositionFromRift(bestRift)
        if pos then
            local root = getRoot()
            if root then
                root.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
                root.Velocity = Vector3.zero
                root.RotVelocity = Vector3.zero
                return bestLuck
            end
        else
            pcall(function() Remote:FireServer("TeleportToRift", riftKey) end)
            return 0
        end
    end
    return 0
end

-- ======================================
-- FALLBACK TELEPORT (Static location)
-- ======================================
local function teleportToEgg(eggName)
    local pos = EGG_LOCATIONS[eggName] or discoveredEggs[eggName]
    if not pos then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj.Name == eggName and obj:IsA("Model") then
                pos = obj:GetPivot().Position
                discoveredEggs[eggName] = pos
                break
            end
        end
    end
    if pos then
        local dist = getDistance(pos)
        if dist > 10 then
            local root = getRoot()
            if root then root.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0)) end
        end
        return true
    end
    return false
end

local function isRiftExists(riftName)
    local riftFolder = workspace:FindFirstChild("Rendered")
    if riftFolder then
        riftFolder = riftFolder:FindFirstChild("Rifts")
        if riftFolder and riftFolder:FindFirstChild(riftName) then
            return true
        end
    end
    return false
end

local function getRiftPositionByName(riftName)
    local riftFolder = workspace:FindFirstChild("Rendered")
    if riftFolder then
        local rifts = riftFolder:FindFirstChild("Rifts")
        if rifts then
            local rift = rifts:FindFirstChild(riftName)
            if rift then
                local spawn = rift:FindFirstChild("EggPlatformSpawn")
                if spawn then
                    local part = spawn:FindFirstChild("Part")
                    if part then return part.Position end
                end
                for _, child in ipairs(rift:GetDescendants()) do
                    if child:IsA("BasePart") then
                        return child.Position
                    end
                end
            end
        end
    end
    return nil
end

local function teleportToRiftSafely(riftName)
    local riftPos = getRiftPositionByName(riftName)
    if not riftPos then
        pcall(function() Remote:FireServer("TeleportToRift", riftName) end)
        return
    end
    
    local root = getRoot()
    if not root then return end
    
    root.CFrame = CFrame.new(riftPos + Vector3.new(0, 5, 0))
    root.Velocity = Vector3.zero
    root.RotVelocity = Vector3.zero
end

local function getAllEggNames()
    local eggs = {}
    local seen = {}
    
    for name, _ in pairs(EGG_LOCATIONS) do
        seen[name] = true
        table.insert(eggs, name)
    end
    
    for name, _ in pairs(EGG_WORLDS) do
        if not seen[name] then
            seen[name] = true
            table.insert(eggs, name)
        end
    end
    
    for name, _ in pairs(discoveredEggs) do
        if not seen[name] then
            seen[name] = true
            table.insert(eggs, name)
        end
    end
    
    table.sort(eggs)
    return eggs
end

local function updateBountyInfo()
    local ok, bounty = pcall(function()
        return SecretBountyUtil:Get()
    end)
    if ok and bounty then
        currentBountyPet = bounty.Name or "Unknown"
        currentBountyEgg = bounty.Egg or "Unknown"
        currentBountyChance = bounty.Chance and "1/" .. tostring(math.floor(1/bounty.Chance)) or "Unknown"
        return true
    end
    return false
end

local function getTimeUntilReset()
    local sign = workspace:FindFirstChild("Worlds")
    if sign then
        sign = sign:FindFirstChild("The Overworld")
        if sign then
            sign = sign:FindFirstChild("SecretBounty")
            if sign then
                local label = sign:FindFirstChild("Counter")
                if label then
                    label = label:FindFirstChild("Display")
                    if label then
                        label = label:FindFirstChild("SurfaceGui")
                        if label then
                            label = label:FindFirstChild("Label")
                            if label then
                                return label.Text
                            end
                        end
                    end
                end
            end
        end
    end
    return "Unknown"
end

local function toggleAutoHatchR()
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        local screenGui = playerGui:FindFirstChild("ScreenGui")
        if screenGui then
            local hud = screenGui:FindFirstChild("HUD")
            if hud then
                local lootPool = hud:FindFirstChild("LootPoolViewer")
                if lootPool then
                    local keybinds = lootPool:FindFirstChild("Keybinds")
                    if keybinds then
                        local key2 = keybinds:FindFirstChild("2")
                        if key2 then
                            local btn = key2:FindFirstChild("Button")
                            if btn then
                                firesignal(btn.Activated)
                            end
                        end
                    end
                end
            end
        end
    end
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
end

-- ======================================
-- UI - SPECIAL EGGS (Priority Order)
-- ======================================
EggsTab:CreateSection("------- Special Eggs -------")

-- CORRUPTSHADOW RIFT (Priority 1)
EggsTab:CreateToggle({
    Name = "Auto CorruptShadow Rift",
    CurrentValue = corruptShadowEnabled,
    Callback = function(v)
        corruptShadowEnabled = v
        eggSettings.autoCorruptShadow = v
        getgenv().HubSettings.eggs = eggSettings
        saveHubSettings()
        if v then
            corruptShadowThread = task.spawn(function()
                while corruptShadowEnabled do
                    if isRiftExists("corruptshadow-rift") then
                        getgenv().questActive = true
                        getgenv().questEgg = "Dark Rift Egg"
                        
                        getgenv().ActivityStatus.current = "Doing CorruptShadow Rift right now"
                        getgenv().ActivityStatus.trigger = true
                        
                        teleportToRiftSafely("corruptshadow-rift")
                        lastTeleportTime = tick()
                        task.wait(0.3)
                        
                        while corruptShadowEnabled and isRiftExists("corruptshadow-rift") do
                            getgenv().questActive = true
                            getgenv().questEgg = "Dark Rift Egg"
                            
                            if tick() - lastTeleportTime >= 3 then
                                teleportToRiftSafely("corruptshadow-rift")
                                lastTeleportTime = tick()
                            end
                            
                            pcall(function() Remote:FireServer("HatchEgg", "Dark Rift Egg", HATCH_AMOUNT) end)
                            task.wait(0.05)
                        end
                        
                        getgenv().ActivityStatus.current = "Finished CorruptShadow Rift"
                        getgenv().ActivityStatus.trigger = true
                        getgenv().questActive = false
                        getgenv().questEgg = nil
                    end
                    task.wait(1)
                end
            end)
        else
            if corruptShadowThread then task.cancel(corruptShadowThread) end
            getgenv().questActive = false
            getgenv().questEgg = nil
        end
    end
})

-- OVERLORD RIFT (Priority 2)
EggsTab:CreateToggle({
    Name = "Auto Overlord Rift",
    CurrentValue = overlordEnabled,
    Callback = function(v)
        overlordEnabled = v
        eggSettings.autoOverlord = v
        getgenv().HubSettings.eggs = eggSettings
        saveHubSettings()
        if v then
            overlordThread = task.spawn(function()
                while overlordEnabled do
                    if isRiftExists("overlord-rift") and not isRiftExists("corruptshadow-rift") then
                        getgenv().questActive = true
                        getgenv().questEgg = "Overlord Egg"
                        
                        getgenv().ActivityStatus.current = "Doing Overlord Rift right now"
                        getgenv().ActivityStatus.trigger = true
                        
                        teleportToRiftSafely("overlord-rift")
                        lastTeleportTime = tick()
                        task.wait(0.3)
                        
                        while overlordEnabled and isRiftExists("overlord-rift") do
                            getgenv().questActive = true
                            getgenv().questEgg = "Overlord Egg"
                            
                            if tick() - lastTeleportTime >= 3 then
                                teleportToRiftSafely("overlord-rift")
                                lastTeleportTime = tick()
                            end
                            
                            pcall(function() Remote:FireServer("HatchEgg", "Overlord Egg", HATCH_AMOUNT) end)
                            task.wait(0.05)
                        end
                        
                        getgenv().ActivityStatus.current = "Finished Overlord Rift"
                        getgenv().ActivityStatus.trigger = true
                        getgenv().questActive = false
                        getgenv().questEgg = nil
                    end
                    task.wait(1)
                end
            end)
        else
            if overlordThread then task.cancel(overlordThread) end
            getgenv().questActive = false
            getgenv().questEgg = nil
        end
    end
})

-- 4X EGG (Priority 3)
EggsTab:CreateToggle({
    Name = "Auto 4x Egg",
    CurrentValue = fourXEnabled,
    Callback = function(v)
        fourXEnabled = v
        eggSettings.auto4x = v
        getgenv().HubSettings.eggs = eggSettings
        saveHubSettings()
        if v then
            fourXThread = task.spawn(function()
                while fourXEnabled do
                    if not isRiftExists("corruptshadow-rift") and not isRiftExists("overlord-rift") then
                        local eggFound = false
                        local eggName = nil
                        local eggObj = nil
                        
                        for _, obj in ipairs(workspace:GetDescendants()) do
                            if obj.Name:find("4x Luck") and obj:IsA("Model") then
                                eggFound = true
                                eggName = obj.Name
                                eggObj = obj
                                break
                            end
                        end
                        
                        if eggFound and eggObj then
                            getgenv().questActive = true
                            getgenv().questEgg = eggName
                            
                            getgenv().ActivityStatus.current = "Doing 4x Egg right now"
                            getgenv().ActivityStatus.trigger = true
                            
                            local pos = eggObj:GetPivot().Position
                            local root = getRoot()
                            if root then root.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0)) end
                            
                            while fourXEnabled and eggFound do
                                if isRiftExists("corruptshadow-rift") or isRiftExists("overlord-rift") then break end
                                
                                getgenv().questActive = true
                                getgenv().questEgg = eggName
                                
                                pcall(function() Remote:FireServer("HatchEgg", eggName, HATCH_AMOUNT) end)
                                task.wait(0.05)
                                
                                eggFound = false
                                for _, obj2 in ipairs(workspace:GetDescendants()) do
                                    if obj2.Name == eggName and obj2:IsA("Model") then
                                        eggFound = true; break
                                    end
                                end
                            end
                            
                            getgenv().ActivityStatus.current = "Finished 4x Egg"
                            getgenv().ActivityStatus.trigger = true
                            getgenv().questActive = false
                            getgenv().questEgg = nil
                        end
                    end
                    task.wait(1)
                end
            end)
        else
            if fourXThread then task.cancel(fourXThread) end
            getgenv().questActive = false
            getgenv().questEgg = nil
        end
    end
})

-- SHADOW RIFT (Priority 4)
EggsTab:CreateToggle({
    Name = "Auto Shadow Rift",
    CurrentValue = shadowEnabled,
    Callback = function(v)
        shadowEnabled = v
        eggSettings.autoShadow = v
        getgenv().HubSettings.eggs = eggSettings
        saveHubSettings()
        if v then
            shadowThread = task.spawn(function()
                while shadowEnabled do
                    local fourXExists = false
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if obj.Name:find("4x Luck") and obj:IsA("Model") then
                            fourXExists = true
                            break
                        end
                    end
                    
                    if isRiftExists("shadow-rift") 
                        and not isRiftExists("corruptshadow-rift") 
                        and not isRiftExists("overlord-rift")
                        and not fourXExists then
                        
                        getgenv().questActive = true
                        getgenv().questEgg = "Dark Rift Egg"
                        
                        getgenv().ActivityStatus.current = "Doing Shadow Rift right now"
                        getgenv().ActivityStatus.trigger = true
                        
                        teleportToRiftSafely("shadow-rift")
                        lastTeleportTime = tick()
                        task.wait(0.3)
                        
                        while shadowEnabled and isRiftExists("shadow-rift") do
                            getgenv().questActive = true
                            getgenv().questEgg = "Dark Rift Egg"
                            
                            if tick() - lastTeleportTime >= 3 then
                                teleportToRiftSafely("shadow-rift")
                                lastTeleportTime = tick()
                            end
                            
                            pcall(function() Remote:FireServer("HatchEgg", "Dark Rift Egg", HATCH_AMOUNT) end)
                            task.wait(0.05)
                        end
                        
                        getgenv().ActivityStatus.current = "Finished Shadow Rift"
                        getgenv().ActivityStatus.trigger = true
                        getgenv().questActive = false
                        getgenv().questEgg = nil
                    end
                    task.wait(1)
                end
            end)
        else
            if shadowThread then task.cancel(shadowThread) end
            getgenv().questActive = false
            getgenv().questEgg = nil
        end
    end
})

-- DOODLE RIFT (Priority 5)
EggsTab:CreateToggle({
    Name = "Auto Doodle Rift",
    CurrentValue = doodleEnabled,
    Callback = function(v)
        doodleEnabled = v
        eggSettings.autoDoodle = v
        getgenv().HubSettings.eggs = eggSettings
        saveHubSettings()
        if v then
            doodleThread = task.spawn(function()
                while doodleEnabled do
                    local fourXExists = false
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if obj.Name:find("4x Luck") and obj:IsA("Model") then
                            fourXExists = true
                            break
                        end
                    end
                    
                    if isRiftExists("doodle-rift")
                        and not isRiftExists("corruptshadow-rift")
                        and not isRiftExists("overlord-rift")
                        and not isRiftExists("shadow-rift")
                        and not fourXExists then
                        
                        getgenv().questActive = true
                        getgenv().questEgg = "Doodle Egg"
                        
                        getgenv().ActivityStatus.current = "Doing Doodle Rift right now"
                        getgenv().ActivityStatus.trigger = true
                        
                        teleportToRiftSafely("doodle-rift")
                        lastTeleportTime = tick()
                        task.wait(0.3)
                        
                        while doodleEnabled and isRiftExists("doodle-rift") do
                            getgenv().questActive = true
                            getgenv().questEgg = "Doodle Egg"
                            
                            if tick() - lastTeleportTime >= 3 then
                                teleportToRiftSafely("doodle-rift")
                                lastTeleportTime = tick()
                            end
                            
                            pcall(function() Remote:FireServer("HatchEgg", "Doodle Egg", HATCH_AMOUNT) end)
                            task.wait(0.05)
                        end
                        
                        getgenv().ActivityStatus.current = "Finished Doodle Rift"
                        getgenv().ActivityStatus.trigger = true
                        getgenv().questActive = false
                        getgenv().questEgg = nil
                    end
                    task.wait(1)
                end
            end)
        else
            if doodleThread then task.cancel(doodleThread) end
            getgenv().questActive = false
            getgenv().questEgg = nil
        end
    end
})

-- ======================================
-- UI - HATCH SELECTED EGG
-- ======================================
EggsTab:CreateSection("------- Hatch Selected Egg -------")

local allEggs = getAllEggNames()

EggsTab:CreateDropdown({
    Name = "Select Egg",
    CurrentOption = {selectedEgg},
    Options = allEggs,
    Callback = function(v)
        selectedEgg = v[1] or v
        eggSettings.selectedEgg = selectedEgg
        getgenv().HubSettings.eggs = eggSettings
        saveHubSettings()
    end
})

EggsTab:CreateButton({
    Name = "Re Scan The Egg Dropdown",
    Callback = function()
        local newEggs = getAllEggNames()
        local text = "Found " .. #newEggs .. " eggs"
        pcall(function() eggListLabel:SetText(text) end)
        print("[Eggs] Rescan: " .. text)
    end
})

local eggListLabel = EggsTab:CreateLabel("Eggs loaded. Click Rescan to refresh")

EggsTab:CreateInput({
    Name = "Hatch Amount",
    CurrentValue = tostring(HATCH_AMOUNT),
    PlaceholderText = "12",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        local n = tonumber(v)
        if n then
            HATCH_AMOUNT = n
            eggSettings.hatchAmount = n
            getgenv().HubSettings.eggs = eggSettings
            saveHubSettings()
        end
    end
})

EggsTab:CreateToggle({
    Name = "Auto Hatch (Teleport + Hatch)",
    CurrentValue = autoHatchEnabled,
    Callback = function(v)
        autoHatchEnabled = v
        eggSettings.autoHatch = v
        getgenv().HubSettings.eggs = eggSettings
        saveHubSettings()
        if v then
            autoHatchThread = task.spawn(function()
                local wasActive = false
                local lastLuck = 0
                while autoHatchEnabled do
                    while getgenv().questActive and autoHatchEnabled do
                        wasActive = false
                        task.wait(0.5)
                    end
                    
                    task.wait(4)
                    if getgenv().questActive then continue end
                    
                    -- Check if selected egg has a rift active
                    local riftKey = eggNameToKey(selectedEgg)
                    
                    if isRiftExists(riftKey) then
                        -- RIFT EXISTS - Hatch at highest luck rift
                        local luck = teleportToBestRift(selectedEgg)
                        
                        if not wasActive or luck ~= lastLuck then
                            getgenv().ActivityStatus.current = "Auto Hatching " .. selectedEgg .. (luck > 0 and " (x" .. luck .. " luck)" or "")
                            getgenv().ActivityStatus.trigger = true
                            wasActive = true
                            lastLuck = luck
                        end
                        
                        pcall(function() Remote:FireServer("HatchEgg", selectedEgg, HATCH_AMOUNT) end)
                        task.wait(0.05)
                    else
                        -- NO RIFT - Just teleport to static coordinates
                        if not wasActive then
                            getgenv().ActivityStatus.current = "Auto Hatching " .. selectedEgg
                            getgenv().ActivityStatus.trigger = true
                            wasActive = true
                        end
                        lastLuck = 0
                        
                        teleportToEgg(selectedEgg)
                        pcall(function() Remote:FireServer("HatchEgg", selectedEgg, HATCH_AMOUNT) end)
                        task.wait(0.05)
                    end
                end
            end)
        else
            if autoHatchThread then task.cancel(autoHatchThread) end
        end
    end
})

EggsTab:CreateToggle({
    Name = "Auto Spam E",
    CurrentValue = spamEEnabled,
    Callback = function(v)
        spamEEnabled = v
        eggSettings.autoSpamE = v
        getgenv().HubSettings.eggs = eggSettings
        saveHubSettings()
        if v then
            spamEThread = task.spawn(function()
                local lastAutoHatchR = 0
                while spamEEnabled do
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                    task.wait(0.05)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                    
                    local eggToHatch = nil
                    if getgenv().questActive and getgenv().questEgg then
                        eggToHatch = getgenv().questEgg
                    elseif bountyEnabled then
                        eggToHatch = currentBountyEgg
                    else
                        eggToHatch = selectedEgg
                    end
                    
                    if eggToHatch then
                        pcall(function() Remote:FireServer("HatchEgg", eggToHatch, HATCH_AMOUNT) end)
                    end
                    
                    if tick() - lastAutoHatchR >= 60 then
                        lastAutoHatchR = tick()
                        toggleAutoHatchR()
                    end
                    
                    task.wait(0.1)
                end
            end)
        else
            if spamEThread then task.cancel(spamEThread) end
        end
    end
})

EggsTab:CreateToggle({
    Name = "Hide Hatch Animation",
    CurrentValue = hideAnimEnabled,
    Callback = function(v)
        hideAnimEnabled = v
        eggSettings.hideAnim = v
        getgenv().HubSettings.eggs = eggSettings
        saveHubSettings()
        getgenv().animationHidden = v
    end
})

-- ======================================
-- UI - INVENTORY EGG
-- ======================================
EggsTab:CreateSection("------- Inventory Egg -------")

EggsTab:CreateDropdown({
    Name = "Select Inventory Egg",
    CurrentOption = {selectedInventoryEgg},
    Options = inventoryEggList,
    Callback = function(v)
        selectedInventoryEgg = v[1] or v
        eggSettings.inventoryEgg = selectedInventoryEgg
        getgenv().HubSettings.eggs = eggSettings
        saveHubSettings()
    end
})

EggsTab:CreateButton({
    Name = "Re Scan Inventory Eggs",
    Callback = function()
        inventoryEggList = getInventoryEggs()
        selectedInventoryEgg = inventoryEggList[1]
        local text = "Found " .. #inventoryEggList .. " inventory eggs"
        pcall(function() invListLabel:SetText(text) end)
        print("[Eggs] Inventory Rescan: " .. text)
    end
})

local invListLabel = EggsTab:CreateLabel("Inventory eggs loaded. Click Rescan to refresh")

EggsTab:CreateToggle({
    Name = "Auto Open Inventory Egg",
    CurrentValue = false,
    Callback = function(v)
        inventoryEnabled = v
        if v then
            inventoryThread = task.spawn(function()
                while inventoryEnabled do
                    pcall(function() Remote:FireServer("HatchPowerupEgg", selectedInventoryEgg, HATCH_AMOUNT) end)
                    task.wait(0.5)
                end
            end)
        else
            if inventoryThread then task.cancel(inventoryThread) end
        end
    end
})

-- ======================================
-- UI - BOUNTY HATCH
-- ======================================
updateBountyInfo()

EggsTab:CreateSection("------- Bounty Hatch -------")

local bountyPetLabel = EggsTab:CreateLabel("Pet: " .. currentBountyPet)
local bountyEggLabel = EggsTab:CreateLabel("Egg: " .. currentBountyEgg)
local bountyChanceLabel = EggsTab:CreateLabel("Chance: " .. currentBountyChance)
local bountyResetLabel = EggsTab:CreateLabel("Resets in: " .. getTimeUntilReset())

local function refreshBountyLabels()
    updateBountyInfo()
    pcall(function() bountyPetLabel:SetText("Pet: " .. currentBountyPet) end)
    pcall(function() bountyEggLabel:SetText("Egg: " .. currentBountyEgg) end)
    pcall(function() bountyChanceLabel:SetText("Chance: " .. currentBountyChance) end)
    pcall(function() bountyResetLabel:SetText("Resets in: " .. getTimeUntilReset()) end)
end

EggsTab:CreateToggle({
    Name = "Auto Bounty (Teleport + Hatch)",
    CurrentValue = bountyEnabled,
    Callback = function(v)
        bountyEnabled = v
        eggSettings.autoBounty = v
        getgenv().HubSettings.eggs = eggSettings
        saveHubSettings()
        if v then
            refreshBountyLabels()
            bountyThread = task.spawn(function()
                local wasActive = false
                local lastLuck = 0
                while bountyEnabled do
                    while getgenv().questActive and bountyEnabled do
                        wasActive = false
                        task.wait(0.5)
                    end
                    
                    task.wait(4)
                    if getgenv().questActive then continue end
                    
                    refreshBountyLabels()
                    
                    local luck = teleportToBestRift(currentBountyEgg)
                    
                    if not wasActive or luck ~= lastLuck then
                        getgenv().ActivityStatus.current = "Auto Hatching Bounty: " .. currentBountyPet .. " from " .. currentBountyEgg .. (luck > 0 and " (x" .. luck .. " luck)" or "")
                        getgenv().ActivityStatus.trigger = true
                        wasActive = true
                        lastLuck = luck
                    end
                    
                    pcall(function() Remote:FireServer("HatchEgg", currentBountyEgg, HATCH_AMOUNT) end)
                    task.wait(0.05)
                end
            end)
        else
            if bountyThread then task.cancel(bountyThread) end
        end
    end
})

EggsTab:CreateToggle({
    Name = "Auto Summon Rift for Bounty",
    CurrentValue = riftEnabled,
    Callback = function(v)
        riftEnabled = v
        eggSettings.autoRiftBounty = v
        getgenv().HubSettings.eggs = eggSettings
        saveHubSettings()
        if v then
            refreshBountyLabels()
            local world = EGG_WORLDS[currentBountyEgg] or "The Overworld"
            pcall(function()
                RemoteFunction:InvokeServer("SummonRift", {
                    Type = "Egg",
                    Name = currentBountyEgg,
                    Time = 5,
                    Luck = 5,
                    World = world
                })
            end)
            riftThread = task.spawn(function()
                while riftEnabled do
                    task.wait(1860)
                    refreshBountyLabels()
                    pcall(function()
                        RemoteFunction:InvokeServer("SummonRift", {
                            Type = "Egg",
                            Name = currentBountyEgg,
                            Time = 5,
                            Luck = 5,
                            World = EGG_WORLDS[currentBountyEgg] or "The Overworld"
                        })
                    end)
                end
            end)
        else
            if riftThread then task.cancel(riftThread) end
        end
    end
})

-- ======================================
-- UI - XL EGG BOUNTY
-- ======================================
EggsTab:CreateSection("------- XL Egg Bounty -------")

EggsTab:CreateDropdown({
    Name = "Select XL Egg",
    Options = xlEggList,
    CurrentOption = {selectedXLEgg},
    Callback = function(v)
        selectedXLEgg = v[1] or v
    end
})

EggsTab:CreateButton({
    Name = "Re Scan XL Eggs",
    Callback = function()
        xlEggList = getXLEggs()
        selectedXLEgg = xlEggList[1]
        print("[XL Bounty] Found " .. #xlEggList .. " XL eggs")
    end
})

EggsTab:CreateToggle({
    Name = "Auto XL Bounty (Teleport + Hatch)",
    CurrentValue = false,
    Callback = function(v)
        xlBountyRunning = v
        if v then
            xlBountyThread = task.spawn(function()
                local wasActive = false
                local lastLuck = 0
                while xlBountyRunning do
                    while getgenv().questActive and xlBountyRunning do
                        wasActive = false
                        task.wait(0.5)
                    end
                    
                    task.wait(4)
                    if getgenv().questActive then continue end
                    
                    local luck = teleportToBestRift(selectedXLEgg)
                    
                    if not wasActive or luck ~= lastLuck then
                        getgenv().ActivityStatus.current = "Auto Hatching XL Bounty: " .. selectedXLEgg .. (luck > 0 and " (x" .. luck .. " luck)" or "")
                        getgenv().ActivityStatus.trigger = true
                        wasActive = true
                        lastLuck = luck
                    end
                    
                    pcall(function() Remote:FireServer("HatchEgg", selectedXLEgg, HATCH_AMOUNT) end)
                    task.wait(0.05)
                end
            end)
        else
            if xlBountyThread then task.cancel(xlBountyThread) end
        end
    end
})

-- ======================================
-- AUTO-START SAVED TOGGLES
-- ======================================
if corruptShadowEnabled then
    corruptShadowThread = task.spawn(function()
        while corruptShadowEnabled do
            if isRiftExists("corruptshadow-rift") then
                getgenv().questActive = true
                getgenv().questEgg = "Dark Rift Egg"
                teleportToRiftSafely("corruptshadow-rift")
                lastTeleportTime = tick()
                task.wait(0.3)
                while corruptShadowEnabled and isRiftExists("corruptshadow-rift") do
                    getgenv().questActive = true
                    getgenv().questEgg = "Dark Rift Egg"
                    if tick() - lastTeleportTime >= 3 then
                        teleportToRiftSafely("corruptshadow-rift")
                        lastTeleportTime = tick()
                    end
                    pcall(function() Remote:FireServer("HatchEgg", "Dark Rift Egg", HATCH_AMOUNT) end)
                    task.wait(0.05)
                end
                getgenv().questActive = false
                getgenv().questEgg = nil
            end
            task.wait(1)
        end
    end)
end

if overlordEnabled then
    overlordThread = task.spawn(function()
        while overlordEnabled do
            if isRiftExists("overlord-rift") and not isRiftExists("corruptshadow-rift") then
                getgenv().questActive = true
                getgenv().questEgg = "Overlord Egg"
                teleportToRiftSafely("overlord-rift")
                lastTeleportTime = tick()
                task.wait(0.3)
                while overlordEnabled and isRiftExists("overlord-rift") do
                    getgenv().questActive = true
                    getgenv().questEgg = "Overlord Egg"
                    if tick() - lastTeleportTime >= 3 then
                        teleportToRiftSafely("overlord-rift")
                        lastTeleportTime = tick()
                    end
                    pcall(function() Remote:FireServer("HatchEgg", "Overlord Egg", HATCH_AMOUNT) end)
                    task.wait(0.05)
                end
                getgenv().questActive = false
                getgenv().questEgg = nil
            end
            task.wait(1)
        end
    end)
end

if fourXEnabled then
    fourXThread = task.spawn(function()
        while fourXEnabled do
            if not isRiftExists("corruptshadow-rift") and not isRiftExists("overlord-rift") then
                local eggFound = false
                local eggName = nil
                local eggObj = nil
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj.Name:find("4x Luck") and obj:IsA("Model") then
                        eggFound = true
                        eggName = obj.Name
                        eggObj = obj
                        break
                    end
                end
                if eggFound and eggObj then
                    getgenv().questActive = true
                    getgenv().questEgg = eggName
                    local pos = eggObj:GetPivot().Position
                    local root = getRoot()
                    if root then root.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0)) end
                    while fourXEnabled and eggFound do
                        if isRiftExists("corruptshadow-rift") or isRiftExists("overlord-rift") then break end
                        getgenv().questActive = true
                        getgenv().questEgg = eggName
                        pcall(function() Remote:FireServer("HatchEgg", eggName, HATCH_AMOUNT) end)
                        task.wait(0.05)
                        eggFound = false
                        for _, obj2 in ipairs(workspace:GetDescendants()) do
                            if obj2.Name == eggName and obj2:IsA("Model") then
                                eggFound = true; break
                            end
                        end
                    end
                    getgenv().questActive = false
                    getgenv().questEgg = nil
                end
            end
            task.wait(1)
        end
    end)
end

if shadowEnabled then
    shadowThread = task.spawn(function()
        while shadowEnabled do
            local fourXExists = false
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj.Name:find("4x Luck") and obj:IsA("Model") then
                    fourXExists = true
                    break
                end
            end
            if isRiftExists("shadow-rift") and not isRiftExists("corruptshadow-rift") and not isRiftExists("overlord-rift") and not fourXExists then
                getgenv().questActive = true
                getgenv().questEgg = "Dark Rift Egg"
                teleportToRiftSafely("shadow-rift")
                lastTeleportTime = tick()
                task.wait(0.3)
                while shadowEnabled and isRiftExists("shadow-rift") do
                    getgenv().questActive = true
                    getgenv().questEgg = "Dark Rift Egg"
                    if tick() - lastTeleportTime >= 3 then
                        teleportToRiftSafely("shadow-rift")
                        lastTeleportTime = tick()
                    end
                    pcall(function() Remote:FireServer("HatchEgg", "Dark Rift Egg", HATCH_AMOUNT) end)
                    task.wait(0.05)
                end
                getgenv().questActive = false
                getgenv().questEgg = nil
            end
            task.wait(1)
        end
    end)
end

if doodleEnabled then
    doodleThread = task.spawn(function()
        while doodleEnabled do
            local fourXExists = false
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj.Name:find("4x Luck") and obj:IsA("Model") then
                    fourXExists = true
                    break
                end
            end
            if isRiftExists("doodle-rift") and not isRiftExists("corruptshadow-rift") and not isRiftExists("overlord-rift") and not isRiftExists("shadow-rift") and not fourXExists then
                getgenv().questActive = true
                getgenv().questEgg = "Doodle Egg"
                teleportToRiftSafely("doodle-rift")
                lastTeleportTime = tick()
                task.wait(0.3)
                while doodleEnabled and isRiftExists("doodle-rift") do
                    getgenv().questActive = true
                    getgenv().questEgg = "Doodle Egg"
                    if tick() - lastTeleportTime >= 3 then
                        teleportToRiftSafely("doodle-rift")
                        lastTeleportTime = tick()
                    end
                    pcall(function() Remote:FireServer("HatchEgg", "Doodle Egg", HATCH_AMOUNT) end)
                    task.wait(0.05)
                end
                getgenv().questActive = false
                getgenv().questEgg = nil
            end
            task.wait(1)
        end
    end)
end

if autoHatchEnabled then
    autoHatchThread = task.spawn(function()
        local wasActive = false
        local lastLuck = 0
        while autoHatchEnabled do
            while getgenv().questActive and autoHatchEnabled do
                wasActive = false
                task.wait(0.5)
            end
            task.wait(4)
            if getgenv().questActive then continue end
            
            local riftKey = eggNameToKey(selectedEgg)
            
            if isRiftExists(riftKey) then
                local luck = teleportToBestRift(selectedEgg)
                if not wasActive or luck ~= lastLuck then
                    getgenv().ActivityStatus.current = "Auto Hatching " .. selectedEgg .. (luck > 0 and " (x" .. luck .. " luck)" or "")
                    getgenv().ActivityStatus.trigger = true
                    wasActive = true
                    lastLuck = luck
                end
            else
                if not wasActive then
                    getgenv().ActivityStatus.current = "Auto Hatching " .. selectedEgg
                    getgenv().ActivityStatus.trigger = true
                    wasActive = true
                end
                lastLuck = 0
                teleportToEgg(selectedEgg)
            end
            
            pcall(function() Remote:FireServer("HatchEgg", selectedEgg, HATCH_AMOUNT) end)
            task.wait(0.05)
        end
    end)
end

if bountyEnabled then
    refreshBountyLabels()
    bountyThread = task.spawn(function()
        local wasActive = false
        local lastLuck = 0
        while bountyEnabled do
            while getgenv().questActive and bountyEnabled do
                wasActive = false
                task.wait(0.5)
            end
            task.wait(4)
            if getgenv().questActive then continue end
            refreshBountyLabels()
            local luck = teleportToBestRift(currentBountyEgg)
            if not wasActive or luck ~= lastLuck then
                getgenv().ActivityStatus.current = "Auto Hatching Bounty: " .. currentBountyPet .. " from " .. currentBountyEgg .. (luck > 0 and " (x" .. luck .. " luck)" or "")
                getgenv().ActivityStatus.trigger = true
                wasActive = true
                lastLuck = luck
            end
            pcall(function() Remote:FireServer("HatchEgg", currentBountyEgg, HATCH_AMOUNT) end)
            task.wait(0.05)
        end
    end)
end

if riftEnabled then
    refreshBountyLabels()
    local world = EGG_WORLDS[currentBountyEgg] or "The Overworld"
    pcall(function()
        RemoteFunction:InvokeServer("SummonRift", {
            Type = "Egg",
            Name = currentBountyEgg,
            Time = 5,
            Luck = 5,
            World = world
        })
    end)
    riftThread = task.spawn(function()
        while riftEnabled do
            task.wait(1860)
            refreshBountyLabels()
            pcall(function()
                RemoteFunction:InvokeServer("SummonRift", {
                    Type = "Egg",
                    Name = currentBountyEgg,
                    Time = 5,
                    Luck = 5,
                    World = EGG_WORLDS[currentBountyEgg] or "The Overworld"
                })
            end)
        end
    end)
end

if spamEEnabled then
    spamEThread = task.spawn(function()
        local lastAutoHatchR = 0
        while spamEEnabled do
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
            local eggToHatch = nil
            if getgenv().questActive and getgenv().questEgg then
                eggToHatch = getgenv().questEgg
            elseif bountyEnabled then
                eggToHatch = currentBountyEgg
            else
                eggToHatch = selectedEgg
            end
            if eggToHatch then
                pcall(function() Remote:FireServer("HatchEgg", eggToHatch, HATCH_AMOUNT) end)
            end
            if tick() - lastAutoHatchR >= 60 then
                lastAutoHatchR = tick()
                toggleAutoHatchR()
            end
            task.wait(0.1)
        end
    end)
end

if hideAnimEnabled then
    getgenv().animationHidden = true
end

print("[Eggs] Loaded!")
