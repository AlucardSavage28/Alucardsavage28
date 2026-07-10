-- ================================================
-- EVENT TAB (CARNIVAL CHEST + REBIRTH + SHRINE + SHOP + UPGRADE)
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
local shrineRunning = false
local shrineThread = nil
local shopRunning = false
local shopThread = nil
local koiXLRunning = false
local koiXLThread = nil
local fragRunning = false
local fragThread = nil
local upgradeRunning = false
local upgradeThread = nil

-- ======================================
-- FUNCTIONS
-- ======================================
local function carnivalShrine()
    pcall(function()
        Remote:InvokeServer("DonateToCarnivalShrine", "Mythic", 6, 400)
        task.wait(1)
        RE:FireServer("ClaimCarnivalShrineBuff", "PlushieEgg")
    end)
end

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
-- UI - CARNIVAL SHRINE
-- ======================================
EventTab:CreateSection("Carnival Shrine")

EventTab:CreateToggle({
    Name = "Auto Carnival Shrine",
    CurrentValue = false,
    Callback = function(v)
        shrineRunning = v
        if v then
            carnivalShrine()
            shrineThread = task.spawn(function()
                while shrineRunning do
                    task.wait(43200)
                    carnivalShrine()
                end
            end)
        else
            if shrineThread then task.cancel(shrineThread) end
        end
    end
})

-- ======================================
-- UI - CARNIVAL SHOP
-- ======================================
EventTab:CreateSection("Carnival Shop")

EventTab:CreateToggle({
    Name = "Buy Shadow Crystal with Carnival Coin",
    CurrentValue = false,
    Callback = function(v)
        shopRunning = v
        if v then
            shopThread = task.spawn(function()
                while shopRunning do
                    pcall(function() RE:FireServer("BuyShopItem", "carnival-shop", 2, true) end)
                    task.wait(1)
                end
            end)
        else
            if shopThread then task.cancel(shopThread) end
        end
    end
})

EventTab:CreateToggle({
    Name = "Auto Buy Unicorn Plushie and XL",
    CurrentValue = false,
    Callback = function(v)
        koiXLRunning = v
        if v then
            koiXLThread = task.spawn(function()
                while koiXLRunning do
                    pcall(function() RE:FireServer("BuyShopItem", "rebirth-shop", 9, false) end)
                    pcall(function() RE:FireServer("BuyShopItem", "rebirth-shop", 10, false) end)
                    task.wait(1)
                end
            end)
        else
            if koiXLThread then task.cancel(koiXLThread) end
        end
    end
})

EventTab:CreateToggle({
    Name = "Auto Buy Purple and Rainbow Frag",
    CurrentValue = false,
    Callback = function(v)
        fragRunning = v
        if v then
            fragThread = task.spawn(function()
                while fragRunning do
                    pcall(function() RE:FireServer("BuyShopItem", "rebirth-shop", 7, false) end)
                    pcall(function() RE:FireServer("BuyShopItem", "rebirth-shop", 8, false) end)
                    task.wait(1)
                end
            end)
        else
            if fragThread then task.cancel(fragThread) end
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
