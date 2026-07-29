-- ================================================
-- EVENT TAB (CRYSTAL SHOP)
-- ================================================
repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local EventTab = Window:CreateTab("Event", nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RE = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteEvent

-- ======================================
-- SETTINGS
-- ======================================
local fragRunning = false
local fragThread = nil
local runeRunning = false
local runeThread = nil

-- ======================================
-- UI - CRYSTAL SHOP
-- ======================================
EventTab:CreateSection("Crystal Shop")

EventTab:CreateToggle({
    Name = "Auto Buy All Fragment",
    CurrentValue = false,
    Callback = function(v)
        fragRunning = v
        if v then
            fragThread = task.spawn(function()
                while fragRunning do
                    pcall(function() RE:FireServer("BuyShopItem", "crystal-shop", 11, false) end)
                    pcall(function() RE:FireServer("BuyShopItem", "crystal-shop", 12, false) end)
                    task.wait(1)
                end
            end)
        else
            if fragThread then task.cancel(fragThread) end
        end
    end
})

EventTab:CreateToggle({
    Name = "Auto Buy Hatching Rune",
    CurrentValue = false,
    Callback = function(v)
        runeRunning = v
        if v then
            runeThread = task.spawn(function()
                while runeRunning do
                    pcall(function() RE:FireServer("BuyShopItem", "crystal-shop", 6, false) end)
                    pcall(function() RE:FireServer("BuyShopItem", "crystal-shop", 7, false) end)
                    task.wait(1)
                end
            end)
        else
            if runeThread then task.cancel(runeThread) end
        end
    end
})

print("[Event] Loaded!")
