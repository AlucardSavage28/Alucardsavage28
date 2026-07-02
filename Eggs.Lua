-- ================================================
-- EGGS TAB (HATCH + 4X + INVENTORY + BOUNTY + RIFT)
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
local Rifts = require(ReplicatedStorage.Shared.Data.Rifts)
local Remote = require(ReplicatedStorage.Shared.Framework.Network.Remote)
local RemoteFunction = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteFunction
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)

-- ======================================
-- EGG LOCATIONS
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
    ["Spikey Egg"] = Vector3.new(-128, 10, 9),
    ["Magma Egg"] = Vector3.new(-137, 11, 3),
    ["Crystal Egg"] = Vector3.new(-144, 10, -5),
    ["Lunar Egg"] = Vector3.new(-148, 11, -15),
    ["Void Egg"] = Vector3.new(-150, 11, -26),
    ["Hell Egg"] = Vector3.new(-149, 11, -37),
    ["Secret Egg"] = Vector3.new(-19438, 8, 18839),
    ["Showman Egg"] = Vector3.new(-130, 10, -60),
    ["Popcorn Egg"] = Vector3.new(-3601, 162, 882),
    ["Sweet Egg"] = Vector3.new(-3586, 162, 883),
    ["Exotic Egg"] = Vector3.new(-3576, 162, 882),
    ["4x Luck Exotic Egg"] = Vector3.new(-3622, 161, 897),
}

local EGG_WORLDS = {
    ["Common Egg"] = "The Overworld",
    ["Classic Egg"] = "The Overworld", ["Vine Egg"] = "The Overworld",
    ["Lava Egg"] = "The Overworld", ["Icy Egg"] = "The Overworld",
    ["Iceshard Egg"] = "The Overworld", ["Spotted Egg"] = "The Overworld",
    ["Atlantis Egg"] = "The Overworld", ["Mining Egg"] = "Minigame Paradise",
    ["Neon Egg"] = "Minigame Paradise", ["Cyber Egg"] = "Minigame Paradise",
    ["Rainbow Egg"] = "The Overworld", ["Nightmare Egg"] = "The Overworld",
    ["Infinity Egg"] = "The Overworld", ["Spikey Egg"] = "The Overworld",
    ["Magma Egg"] = "The Overworld", ["Crystal Egg"] = "The Overworld",
    ["Lunar Egg"] = "The Overworld", ["Void Egg"] = "The Overworld",
    ["Hell Egg"] = "The Overworld", ["Secret Egg"] = "The Overworld",
    ["Showman Egg"] = "The Overworld",
    ["Popcorn Egg"] = "The Overworld", ["Sweet Egg"] = "The Overworld",
    ["Exotic Egg"] = "The Overworld", ["4x Luck Exotic Egg"] = "The Overworld",
}

local ALL_EGG_NAMES = {}
for eggName, _ in pairs(EGG_LOCATIONS) do
    table.insert(ALL_EGG_NAMES, eggName)
end
table.sort(ALL_EGG_NAMES)

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
local HATCH_AMOUNT = 12
local selectedEgg = "Common Egg"
local currentBountyPet = "Unknown"
local currentBountyEgg = "Unknown"
local currentBountyChance = "Unknown"

local fourXEnabled = false
local autoHatchEnabled = false
local spamEEnabled = false
local hideAnimEnabled = false
local inventoryEnabled = false
local bountyEnabled = false
local riftEnabled = false

local fourXThread = nil
local autoHatchThread = nil
local spamEThread = nil
local inventoryThread = nil
local bountyThread = nil
local riftThread = nil

local inventoryEggList = getInventoryEggs()
local selectedInventoryEgg = inventoryEggList[1]

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

local function getRiftPosition(name)
    local key = eggNameToKey(name)
    local riftFolder = workspace:FindFirstChild("Rendered")
    if riftFolder then
        riftFolder = riftFolder:FindFirstChild("Rifts")
        if riftFolder then
            local bestRift = nil
            local bestLuck = -1
            
            for _, rift in ipairs(riftFolder:GetChildren()) do
                if rift.Name == key then
                    local data = Rifts[key]
                    local luck = 0
                    if data and data.Luck then luck = tonumber(data.Luck) or 0 end
                    if luck > bestLuck then
                        bestLuck = luck
                        bestRift = rift
                    end
                end
            end
            
            if bestRift then
                local spawn = bestRift:FindFirstChild("EggPlatformSpawn")
                if spawn then
                    local part = spawn:FindFirstChild("Part")
                    if part then return part.Position end
                end
                for _, child in ipairs(bestRift:GetDescendants()) do
                    if child:IsA("BasePart") then
                        return child.Position
                    end
                end
            end
        end
    end
    return nil
end

local function teleportToEgg(eggName)
    local riftPos = getRiftPosition(eggName)
    if riftPos then
        local dist = getDistance(riftPos)
        if dist > 20 then
            local root = getRoot()
            if root then
                root.CFrame = CFrame.new(riftPos + Vector3.new(0, 5, 0))
            end
        end
        return true
    end
    
    local pos = EGG_LOCATIONS[eggName]
    if pos then
        local dist = getDistance(pos)
        if dist > 20 then
            local root = getRoot()
            if root then
                root.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
            end
        end
        return true
    end
    return false
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

-- ======================================
-- UI - 4X LUCK EXOTIC EGG
-- ======================================
EggsTab:CreateSection("------- 4x Luck Exotic Egg -------")

EggsTab:CreateToggle({
    Name = "Auto 4x Luck Exotic Egg (Admin Spawn)",
    CurrentValue = false,
    Callback = function(v)
        fourXEnabled = v
        if v then
            fourXThread = task.spawn(function()
                while fourXEnabled do
                    while getgenv().questActive and fourXEnabled do
                        task.wait(0.5)
                    end
                    
                    local eggFound = false
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if obj.Name == "4x Luck Exotic Egg" and obj:IsA("Model") then
                            eggFound = true
                            getgenv().questActive = true
                            getgenv().questEgg = "4x Luck Exotic Egg"
                            
                            local pos = obj:GetPivot().Position
                            local root = getRoot()
                            if root then
                                root.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
                            end
                            
                            while fourXEnabled and eggFound do
                                if getgenv().questEgg ~= "4x Luck Exotic Egg" then break end
                                pcall(function() Remote:FireServer("HatchEgg", "4x Luck Exotic Egg", HATCH_AMOUNT) end)
                                task.wait(0.05)
                                
                                eggFound = false
                                for _, obj2 in ipairs(workspace:GetDescendants()) do
                                    if obj2.Name == "4x Luck Exotic Egg" and obj2:IsA("Model") then
                                        eggFound = true
                                        break
                                    end
                                end
                            end
                            
                            if not eggFound or getgenv().questEgg ~= "4x Luck Exotic Egg" then
                                getgenv().questActive = false
                                getgenv().questEgg = nil
                            end
                            break
                        end
                    end
                    
                    if not eggFound then
                        getgenv().questActive = false
                        getgenv().questEgg = nil
                    end
                    
                    task.wait(0.05)
                end
                getgenv().questActive = false
                getgenv().questEgg = nil
            end)
        else
            if fourXThread then task.cancel(fourXThread) end
            getgenv().questActive = false
            getgenv().questEgg = nil
        end
    end
})

-- ======================================
-- UI - HATCH EGG
-- ======================================
EggsTab:CreateSection("------- Hatch Egg -------")

EggsTab:CreateDropdown({
    Name = "Select Egg",
    CurrentOption = {"Common Egg"},
    Options = ALL_EGG_NAMES,
    Callback = function(v)
        selectedEgg = v[1] or v
    end
})

EggsTab:CreateInput({
    Name = "Hatch Amount",
    CurrentValue = tostring(HATCH_AMOUNT),
    PlaceholderText = "12",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        local n = tonumber(v)
        if n then HATCH_AMOUNT = n end
    end
})

EggsTab:CreateToggle({
    Name = "Auto Hatch (Teleport + Hatch)",
    CurrentValue = false,
    Callback = function(v)
        autoHatchEnabled = v
        if v then
            autoHatchThread = task.spawn(function()
                while autoHatchEnabled do
                    while getgenv().questActive and autoHatchEnabled do
                        task.wait(0.5)
                    end
                    
                    teleportToEgg(selectedEgg)
                    pcall(function()
                        Remote:FireServer("HatchEgg", selectedEgg, HATCH_AMOUNT)
                    end)
                    task.wait(0.05)
                end
            end)
        else
            if autoHatchThread then task.cancel(autoHatchThread) end
        end
    end
})

EggsTab:CreateToggle({
    Name = "Auto Spam E",
    CurrentValue = false,
    Callback = function(v)
        spamEEnabled = v
        if v then
            spamEThread = task.spawn(function()
                while spamEEnabled do
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                    task.wait(0.05)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
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
    CurrentValue = false,
    Callback = function(v)
        hideAnimEnabled = v
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
    end
})

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
    CurrentValue = false,
    Callback = function(v)
        bountyEnabled = v
        if v then
            refreshBountyLabels()
            bountyThread = task.spawn(function()
                while bountyEnabled do
                    while getgenv().questActive and bountyEnabled do
                        task.wait(0.5)
                    end
                    
                    refreshBountyLabels()
                    teleportToEgg(currentBountyEgg)
                    pcall(function()
                        Remote:FireServer("HatchEgg", currentBountyEgg, HATCH_AMOUNT)
                    end)
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
    CurrentValue = false,
    Callback = function(v)
        riftEnabled = v
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

print("[Eggs] Loaded!")
