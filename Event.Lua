-- ================================================
-- EVENT TAB (AUTO EVENT + CRYSTAL SHOP)
-- ================================================
repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local EventTab = Window:CreateTab("Event", nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local RE = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteEvent

-- ======================================
-- SETTINGS
-- ======================================
local selectedEvent = "Luck Event"
local eventRunning = false
local eventThread = nil

local runeRunning = false
local runeThread = nil
local greenBlueRunning = false
local greenBlueThread = nil
local purpleRainbowRunning = false
local purpleRainbowThread = nil
local crystalRunning = false
local crystalThread = nil
local sunburstRunning = false
local sunburstThread = nil

local EVENTS = {
    "Luck Event", "Shiny Event", "Mythic Event", "Celestial Event",
    "Secret Event", "Infinity Event", "XL Event", "Super Palooza"
}

-- ======================================
-- EVENT BOARD READER
-- ======================================
local function getAllActiveEvents()
    local events = {}
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        local screenGui = playerGui:FindFirstChild("ScreenGui")
        if screenGui then
            local eventBoard = screenGui:FindFirstChild("EventBoard")
            if eventBoard then
                local activeEvents = eventBoard:FindFirstChild("Frame") and eventBoard.Frame:FindFirstChild("Main") and eventBoard.Frame.Main:FindFirstChild("ActiveEvents")
                if activeEvents then
                    local container = activeEvents:FindFirstChild("Container")
                    if container then
                        local list = container:FindFirstChild("List")
                        if list then
                            for _, child in ipairs(list:GetChildren()) do
                                if child:IsA("Frame") and child.Name ~= "UIListLayout" and child.Name ~= "UIPadding" then
                                    local frame = child:FindFirstChild("Frame")
                                    if frame then
                                        local title = frame:FindFirstChild("Title")
                                        if title then
                                            local eventLabel = title:FindFirstChild("Event")
                                            if eventLabel then
                                                local eventText = eventLabel.Text
                                                if eventText and eventText ~= "" then
                                                    table.insert(events, eventText)
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return events
end

local function getActiveEventDisplay()
    local events = getAllActiveEvents()
    if #events == 0 then return "No Event" end
    return table.concat(events, ", ")
end

local lastEventDisplay = ""

-- ======================================
-- UI - AUTO EVENT
-- ======================================
EventTab:CreateSection("Auto Event")

local activeEventLabel = EventTab:CreateLabel("Active: " .. getActiveEventDisplay())

task.spawn(function()
    while true do
        task.wait(30)
        local display = getActiveEventDisplay()
        pcall(function() activeEventLabel:SetText("Active: " .. display) end)
        
        if display ~= lastEventDisplay then
            lastEventDisplay = display
            if display == "No Event" then
                getgenv().ActivityStatus.current = "Event Board = No Event"
            else
                getgenv().ActivityStatus.current = "Event Board = " .. display
            end
            getgenv().ActivityStatus.trigger = true
        end
    end
end)

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
                    task.wait(900)
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
    Name = "Auto Buy Green And Blue Fragment",
    CurrentValue = false,
    Callback = function(v)
        greenBlueRunning = v
        if v then
            greenBlueThread = task.spawn(function()
                while greenBlueRunning do
                    pcall(function() RE:FireServer("BuyShopItem", "crystal-shop", 7, false) end)
                    pcall(function() RE:FireServer("BuyShopItem", "crystal-shop", 8, false) end)
                    task.wait(1)
                end
            end)
        else
            if greenBlueThread then task.cancel(greenBlueThread) end
        end
    end
})

EventTab:CreateToggle({
    Name = "Auto Buy Purple And Rainbow Fragment",
    CurrentValue = false,
    Callback = function(v)
        purpleRainbowRunning = v
        if v then
            purpleRainbowThread = task.spawn(function()
                while purpleRainbowRunning do
                    pcall(function() RE:FireServer("BuyShopItem", "crystal-shop", 9, false) end)
                    pcall(function() RE:FireServer("BuyShopItem", "crystal-shop", 10, false) end)
                    task.wait(1)
                end
            end)
        else
            if purpleRainbowThread then task.cancel(purpleRainbowThread) end
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
