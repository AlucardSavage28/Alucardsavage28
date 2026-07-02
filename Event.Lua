-- ================================================
-- EVENT TAB (CARNIVAL CHEST + REBIRTH + UPGRADE)
-- ================================================
repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local EventTab = Window:CreateTab("Event", nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local RE = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteEvent
local Remote = require(ReplicatedStorage.Shared.Framework.Network.Remote)

local function fire(action, ...)
    if RE then RE:FireServer(action, ...) end
end

-- ======================================
-- SETTINGS
-- ======================================
local carnivalRunning = false
local carnivalThread = nil
local rebirthRunning = false
local rebirthThread = nil
local upgradeRunning = false
local upgradeThread = nil

-- ======================================
-- UI - CARNIVAL CHEST
-- ======================================
EventTab:CreateSection("Carnival Chest")

EventTab:CreateToggle({
    Name = "Auto Claim Carnival Chest",
    CurrentValue = false,
    Callback = function(v)
        carnivalRunning = v
        if v then
            carnivalThread = task.spawn(function()
                while carnivalRunning do
                    pcall(function() RE:FireServer("ClaimChest", "Carnival Chest") end)
                    task.wait(0.1)
                end
            end)
        else
            if carnivalThread then task.cancel(carnivalThread) end
        end
    end
})

-- ======================================
-- UI - CARNIVAL REBIRTH
-- ======================================
EventTab:CreateSection("Carnival Rebirth")

EventTab:CreateToggle({
    Name = "Auto Carnival Rebirth",
    CurrentValue = false,
    Callback = function(v)
        rebirthRunning = v
        if v then
            rebirthThread = task.spawn(function()
                while rebirthRunning do
                    pcall(function() RE:FireServer("CarnivalRebirth") end)
                    task.wait(0.1)
                end
            end)
        else
            if rebirthThread then task.cancel(rebirthThread) end
        end
    end
})

-- ======================================
-- UI - CARNIVAL UPGRADE
-- ======================================
EventTab:CreateSection("Carnival Upgrade")

EventTab:CreateToggle({
    Name = "Auto Carnival Rebirth Upgrade",
    CurrentValue = false,
    Callback = function(v)
        upgradeRunning = v
        if v then
            upgradeThread = task.spawn(function()
                while upgradeRunning do
                    pcall(function() RE:FireServer("BuyCarnivalUpgrade", "Currency") end)
                    pcall(function() RE:FireServer("BuyCarnivalUpgrade", "Luck") end)
                    pcall(function() RE:FireServer("BuyCarnivalUpgrade", "SecretLuck") end)
                    pcall(function() RE:FireServer("BuyCarnivalUpgrade", "InfinityLuck") end)
                    task.wait(0.1)
                end
            end)
        else
            if upgradeThread then task.cancel(upgradeThread) end
        end
    end
})

print("[Event] Loaded!")
