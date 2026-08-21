-- ================================================
-- EVENT TAB (UPDATED - REMOVED SHOP, ADDED RIFT)
-- ================================================
repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local EventTab = Window:CreateTab("Event", nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)
local Pets = require(ReplicatedStorage.Shared.Data.Pets)
local RE = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteEvent

local RemoteContainer = ReplicatedStorage.Shared.Framework.Network.Remote
local RemoteFunction = RemoteContainer.RemoteFunction

-- ======================================
-- LOAD SAVED SETTINGS
-- ======================================
local settings = getgenv().HubSettings or {}
if not settings.event then settings.event = {} end
local eventSettings = settings.event

-- ======================================
-- SETTINGS
-- ======================================
local selectedEvent = eventSettings.selectedEvent or "Luck Event"
local eventRunning = false
local eventThread = nil

-- Spawnable Special Rift settings
local autoHatchRiftEnabled = eventSettings.autoHatchRift or false
local autoHatchRiftThread = nil
local autoSummonRiftEnabled = eventSettings.autoSummonRift or false
local autoSummonRiftThread = nil

local HATCH_AMOUNT = eventSettings.riftHatchAmount or 12
local riftName = "cloud-rift" -- The special rift name
local riftEgg = "Cloudy Rift Egg" -- The egg it hatches

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
-- SPAWNABLE RIFT FUNCTIONS
-- ======================================
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

local function getRiftPosition(riftName)
    local riftFolder = workspace:FindFirstChild("Rendered")
    if riftFolder then
        riftFolder = riftFolder:FindFirstChild("Rifts")
        if riftFolder then
            local rift = riftFolder:FindFirstChild(riftName)
            if rift then
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

local function teleportToRift(riftName)
    local riftPos = getRiftPosition(riftName)
    if riftPos then
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = CFrame.new(riftPos + Vector3.new(0, 5, 0))
            root.Velocity = Vector3.zero
            root.RotVelocity = Vector3.zero
        end
    else
        pcall(function() RE:FireServer("TeleportToRift", riftName) end)
    end
end

-- ======================================
-- UI - EVENT BOARD (renamed from Auto Event)
-- ======================================
EventTab:CreateSection("Event Board")

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
    CurrentOption = {selectedEvent},
    Callback = function(v)
        selectedEvent = v[1]
        eventSettings.selectedEvent = v[1]
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
    end
})

EventTab:CreateToggle({
    Name = "Auto Add Event",
    CurrentValue = eventSettings.autoAddEvent or false,
    Callback = function(v)
        eventRunning = v
        eventSettings.autoAddEvent = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
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
-- UI - SPAWNABLE SPECIAL RIFT
-- ======================================
EventTab:CreateSection("Spawnable Special Rift")

EventTab:CreateLabel("Rift: " .. riftName)
EventTab:CreateLabel("Egg: " .. riftEgg)

EventTab:CreateInput({
    Name = "Hatch Amount",
    CurrentValue = tostring(HATCH_AMOUNT),
    PlaceholderText = "12",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        local n = tonumber(v)
        if n then
            HATCH_AMOUNT = n
            eventSettings.riftHatchAmount = n
            getgenv().HubSettings.event = eventSettings
            saveHubSettings()
        end
    end
})

EventTab:CreateToggle({
    Name = "Auto Hatch",
    CurrentValue = autoHatchRiftEnabled,
    Callback = function(v)
        autoHatchRiftEnabled = v
        eventSettings.autoHatchRift = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            autoHatchRiftThread = task.spawn(function()
                local wasActive = false
                while autoHatchRiftEnabled do
                    if isRiftExists(riftName) then
                        getgenv().questActive = true
                        getgenv().questEgg = riftEgg
                        
                        if not wasActive then
                            getgenv().ActivityStatus.current = "Hatching " .. riftEgg
                            getgenv().ActivityStatus.trigger = true
                            wasActive = true
                        end
                        
                        teleportToRift(riftName)
                        pcall(function() RE:FireServer("HatchEgg", riftEgg, HATCH_AMOUNT) end)
                        task.wait(0.05)
                    else
                        if wasActive then
                            getgenv().ActivityStatus.current = "Rift gone, waiting..."
                            getgenv().ActivityStatus.trigger = true
                            wasActive = false
                        end
                        getgenv().questActive = false
                        getgenv().questEgg = nil
                        task.wait(1)
                    end
                end
            end)
        else
            if autoHatchRiftThread then task.cancel(autoHatchRiftThread) end
            getgenv().questActive = false
            getgenv().questEgg = nil
        end
    end
})

EventTab:CreateToggle({
    Name = "Auto Summon",
    CurrentValue = autoSummonRiftEnabled,
    Callback = function(v)
        autoSummonRiftEnabled = v
        eventSettings.autoSummonRift = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            autoSummonRiftThread = task.spawn(function()
                while autoSummonRiftEnabled do
                    if not isRiftExists(riftName) then
                        getgenv().ActivityStatus.current = "Summoning " .. riftName
                        getgenv().ActivityStatus.trigger = true
                        
                        -- Summon the rift with 60m duration and x25 luck
                        pcall(function()
                            RemoteFunction:InvokeServer("SummonRift", {
                                Type = "Egg",
                                Name = "Cloudy Rift Egg",
                                Time = 60,
                                Luck = 25,
                                World = "The Overworld"
                            })
                        end)
                        
                        task.wait(5) -- Wait for summon to process
                    else
                        task.wait(30) -- Check every 30s if rift exists
                    end
                    
                    task.wait(1)
                end
            end)
        else
            if autoSummonRiftThread then task.cancel(autoSummonRiftThread) end
        end
    end
})

-- ======================================
-- UI - EVENT SHOP (REPLACED WITH LABEL)
-- ======================================
EventTab:CreateSection("Event Shop")

EventTab:CreateLabel("No new event shop")

-- ======================================
-- AUTO-START SAVED TOGGLES
-- ======================================
if eventSettings.autoAddEvent then
    eventRunning = true
    eventThread = task.spawn(function()
        while eventRunning do
            pcall(function() RE:FireServer("PurchaseEventBoard", selectedEvent) end)
            task.wait(900)
        end
    end)
end

if autoHatchRiftEnabled then
    autoHatchRiftThread = task.spawn(function()
        while autoHatchRiftEnabled do
            if isRiftExists(riftName) then
                getgenv().questActive = true
                getgenv().questEgg = riftEgg
                teleportToRift(riftName)
                pcall(function() RE:FireServer("HatchEgg", riftEgg, HATCH_AMOUNT) end)
                task.wait(0.05)
            else
                getgenv().questActive = false
                getgenv().questEgg = nil
                task.wait(1)
            end
        end
    end)
end

if autoSummonRiftEnabled then
    autoSummonRiftThread = task.spawn(function()
        while autoSummonRiftEnabled do
            if not isRiftExists(riftName) then
                pcall(function()
                    RemoteFunction:InvokeServer("SummonRift", {
                        Type = "Egg",
                        Name = "Cloudy Rift Egg",
                        Time = 60,
                        Luck = 25,
                        World = "The Overworld"
                    })
                end)
                task.wait(5)
            else
                task.wait(30)
            end
            task.wait(1)
        end
    end)
end

print("[Event] Loaded!")
