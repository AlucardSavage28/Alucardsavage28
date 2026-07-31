-- ================================================
-- TELEPORT TAB
-- ================================================
repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local TeleportTab = Window:CreateTab("Teleport", nil)

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- ======================================
-- TELEPORT LOCATIONS
-- ======================================
local OVERWORLD = {
    ["Spawn"] = Vector3.new(-1, 9, -22),
    ["Floating Island"] = Vector3.new(-16, 423, 143),
    ["Outer Space"] = Vector3.new(41, 2663, -7),
    ["Twilight"] = Vector3.new(-78, 6862, 88),
    ["The Void"] = Vector3.new(16, 10145, 151),
    ["Zen"] = Vector3.new(36, 15971, 41),
}

local MINIGAME = {
    ["Spawn"] = Vector3.new(9981, 26, 172),
    ["Dice Island"] = Vector3.new(9900, 2907, 208),
    ["Minecart Forest"] = Vector3.new(9882, 7682, 203),
    ["Robot Factory"] = Vector3.new(9887, 13409, 227),
    ["Hyperwave Island"] = Vector3.new(9885, 20089, 226),
}

local SEVENSEAS = {
    ["Spawn"] = Vector3.new(-23663, 7, -80),
    ["Blizzard Hill"] = Vector3.new(-21426, 6, -100923),
    ["Poison Jungle"] = Vector3.new(-19332, 6, 18763),
    ["Infernite Volcano"] = Vector3.new(-17253, 10, -20407),
    ["Lost Atlantis"] = Vector3.new(-13947, 8, -20432),
    ["Dream Island"] = Vector3.new(-21818, 7, -20524),
    ["Classic Island"] = Vector3.new(-41526, 8, -20509),
}

local SHADOW_REALM = Vector3.new(2335, 3158, 949)

-- ======================================
-- SETTINGS
-- ======================================
local unlockRunning = false
local unlockThread = nil

local overworldSelected = "Spawn"
local overworldRunning = false
local overworldThread = nil

local minigameSelected = "Spawn"
local minigameRunning = false
local minigameThread = nil

local sevenseasSelected = "Spawn"
local sevenseasRunning = false
local sevenseasThread = nil

local shadowRunning = false
local shadowThread = nil

-- ======================================
-- FUNCTIONS
-- ======================================
local function getRoot()
    local char = player.Character
    if char then return char:FindFirstChild("HumanoidRootPart") end
end

local function teleportTo(pos)
    local root = getRoot()
    if root then
        root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    end
end

-- ======================================
-- UI - AUTO UNLOCK
-- ======================================
TeleportTab:CreateSection("Auto Unlock")

TeleportTab:CreateToggle({
    Name = "Auto Unlock All Islands",
    CurrentValue = false,
    Callback = function(v)
        unlockRunning = v
        if v then
            unlockThread = task.spawn(function()
                while unlockRunning do
                    -- The Overworld
                    for _, pos in pairs(OVERWORLD) do
                        if not unlockRunning then break end
                        teleportTo(pos)
                        task.wait(1.5)
                    end
                    -- Minigame Paradise
                    for _, pos in pairs(MINIGAME) do
                        if not unlockRunning then break end
                        teleportTo(pos)
                        task.wait(1.5)
                    end
                    -- Seven Seas
                    for _, pos in pairs(SEVENSEAS) do
                        if not unlockRunning then break end
                        teleportTo(pos)
                        task.wait(1.5)
                    end
                    task.wait(2)
                end
            end)
        else
            if unlockThread then task.cancel(unlockThread) end
        end
    end
})

-- Shadow Realm button (Auto Unlock)
TeleportTab:CreateButton({
    Name = "Teleport to Shadow Realm (Unlock)",
    Callback = function()
        teleportTo(SHADOW_REALM)
    end
})

-- ======================================
-- UI - TELEPORT
-- ======================================
TeleportTab:CreateSection("Teleport")

-- The Overworld
local overworldOptions = {}
for name, _ in pairs(OVERWORLD) do
    table.insert(overworldOptions, name)
end
table.sort(overworldOptions)

TeleportTab:CreateDropdown({
    Name = "The Overworld",
    Options = overworldOptions,
    CurrentOption = {overworldSelected},
    Callback = function(v)
        overworldSelected = v[1]
    end
})

TeleportTab:CreateToggle({
    Name = "Auto Teleport Overworld",
    CurrentValue = false,
    Callback = function(v)
        overworldRunning = v
        if v then
            overworldThread = task.spawn(function()
                while overworldRunning do
                    teleportTo(OVERWORLD[overworldSelected])
                    task.wait(1.5)
                end
            end)
        else
            if overworldThread then task.cancel(overworldThread) end
        end
    end
})

-- Minigame Paradise
local minigameOptions = {}
for name, _ in pairs(MINIGAME) do
    table.insert(minigameOptions, name)
end
table.sort(minigameOptions)

TeleportTab:CreateDropdown({
    Name = "Minigame Paradise",
    Options = minigameOptions,
    CurrentOption = {minigameSelected},
    Callback = function(v)
        minigameSelected = v[1]
    end
})

TeleportTab:CreateToggle({
    Name = "Auto Teleport Minigame Paradise",
    CurrentValue = false,
    Callback = function(v)
        minigameRunning = v
        if v then
            minigameThread = task.spawn(function()
                while minigameRunning do
                    teleportTo(MINIGAME[minigameSelected])
                    task.wait(1.5)
                end
            end)
        else
            if minigameThread then task.cancel(minigameThread) end
        end
    end
})

-- Seven Seas
local sevenseasOptions = {}
for name, _ in pairs(SEVENSEAS) do
    table.insert(sevenseasOptions, name)
end
table.sort(sevenseasOptions)

TeleportTab:CreateDropdown({
    Name = "Seven Seas",
    Options = sevenseasOptions,
    CurrentOption = {sevenseasSelected},
    Callback = function(v)
        sevenseasSelected = v[1]
    end
})

TeleportTab:CreateToggle({
    Name = "Auto Teleport Seven Seas",
    CurrentValue = false,
    Callback = function(v)
        sevenseasRunning = v
        if v then
            sevenseasThread = task.spawn(function()
                while sevenseasRunning do
                    teleportTo(SEVENSEAS[sevenseasSelected])
                    task.wait(1.5)
                end
            end)
        else
            if sevenseasThread then task.cancel(sevenseasThread) end
        end
    end
})

-- Shadow Realm button (Teleport)
TeleportTab:CreateButton({
    Name = "Teleport to Shadow Realm",
    Callback = function()
        teleportTo(SHADOW_REALM)
    end
})

print("[Teleport] Loaded!")
