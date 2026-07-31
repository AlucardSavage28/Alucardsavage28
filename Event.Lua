-- ================================================
-- EVENT TAB (AUTO EVENT + CRYSTAL SHOP)
-- ================================================
repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local EventTab = Window:CreateTab("Event", nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RE = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteEvent

-- ======================================
-- SETTINGS
-- ======================================
local eventRunning = false
local eventThread = nil
local selectedEvent = "Luck Event"

local runeRunning = false
local runeThread = nil
local fragRunning = false
local fragThread = nil
local crystalRunning = false
local crystalThread = nil
local sunburstRunning = false
local sunburstThread = nil

local EVENTS = {
    "Luck Event", "Shiny Event", "Mythic Event", "Celestial Event",
    "Secret Event", "Infinity Event", "XL Event", "Super Palooza"
}

-- ======================================
-- UI - AUTO EVENT
-- ======================================
EventTab:CreateSection("Auto Event")

EventTab:CreateDropdown({
    Name = "Select Event",
    Options = EVENTS,
    CurrentOption = {"Luck Event"},
    Callback = function(v)
        selectedEvent = v[1]
    end
})

EventTab:CreateToggle({
    Name = "Auto Add Event",
    CurrentValue = false,
    Callback = function(v)
        eventRunning = v
        if v then
            eventThread = task.spawn(function()
                while eventRunning do
                    pcall(function() RE:FireServer("PurchaseEventBoard", selectedEvent) end)
                    task.wait(900) -- 15 minutes
                end
            end)
        else
            if eventThread then task.cancel(eventThread) end
        end
    end
})

-- ======================================
-- UI - CRYSTAL SHOP
-- ======================================
EventTab:CreateSection("Crystal Shop")

EventTab:CreateToggle({
    Name = "Auto Buy Hatching Rune",
    CurrentValue = false,
    Callback = function(v)
        runeRunning = v
        if v then
            runeThread = task.spawn(function()
                while runeRunning do
                    pcall(function() RE:FireServer("BuyShopItem", "crystal-shop", 4, false) end)
                    pcall(function() RE:FireServer("BuyShopItem", "crystal-shop", 5, false) end)
                    pcall(function() RE:FireServer("BuyShopItem", "crystal-shop", 6, false) end)
                    task.wait(1)
                end
            end)
        else
            if runeThread then task.cancel(runeThread) end
        end
    end
})

EventTab:CreateToggle({
    Name = "Auto Buy All Fragment",
    CurrentValue = false,
    Callback = function(v)
        fragRunning = v
        if v then
            fragThread = task.spawn(function()
                while fragRunning do
                    pcall(function() RE:FireServer("BuyShopItem", "crystal-shop", 7, false) end)
                    pcall(function() RE:FireServer("BuyShopItem", "crystal-shop", 8, false) end)
                    pcall(function() RE:FireServer("BuyShopItem", "crystal-shop", 9, false) end)
                    pcall(function() RE:FireServer("BuyShopItem", "crystal-shop", 10, false) end)
                    task.wait(1)
                end
            end)
        else
            if fragThread then task.cancel(fragThread) end
        end
    end
})

EventTab:CreateToggle({
    Name = "Auto Buy Power Crystal",
    CurrentValue = false,
    Callback = function(v)
        crystalRunning = v
        if v then
            crystalThread = task.spawn(function()
                while crystalRunning do
                    pcall(function() RE:FireServer("BuyShopItem", "crystal-shop", 13, false) end)
                    task.wait(1)
                end
            end)
        else
            if crystalThread then task.cancel(crystalThread) end
        end
    end
})

EventTab:CreateToggle({
    Name = "Auto Buy Sunburst",
    CurrentValue = false,
    Callback = function(v)
        sunburstRunning = v
        if v then
            sunburstThread = task.spawn(function()
                while sunburstRunning do
                    pcall(function() RE:FireServer("BuyShopItem", "crystal-shop", 14, false) end)
                    task.wait(1)
                end
            end)
        else
            if sunburstThread then task.cancel(sunburstThread) end
        end
    end
})

print("[Event] Loaded!")
