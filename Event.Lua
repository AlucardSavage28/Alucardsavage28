-- ================================================
-- EVENT TAB (UPDATED - PRIORITY HATCH + SUMMON WEBHOOK)
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
local HttpService = game:GetService("HttpService")

local RemoteContainer = ReplicatedStorage.Shared.Framework.Network.Remote
local RemoteFunction = RemoteContainer.RemoteFunction

local request = http_request or request or (syn and syn.request)

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

local HATCH_AMOUNT = 12 -- Hardcoded

-- Rift info
local riftName = "cloud-rift"
local riftEgg = "Cloudy Rift Egg"
local riftWorld = "The Overworld"

-- Summon Webhook settings
local summonWebhookURL = eventSettings.summonWebhookURL or settings.activity.webhookURL or ""
local summonDiscordID = eventSettings.summonDiscordID or settings.activity.userId or ""

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

local function summonRift()
    pcall(function()
        RemoteFunction:InvokeServer("SummonRift", {
            Type = "Egg",
            Name = riftEgg,
            Time = 5,
            Luck = 5,
            World = riftWorld
        })
    end)
end

-- ======================================
-- SUMMON WEBHOOK FUNCTIONS
-- ======================================
local lastSummonState = "" -- Track last sent state to avoid spam

local function sendSummonWebhook(success)
    if summonWebhookURL == "" then return end
    
    local content = ""
    local color = 0
    
    if success then
        -- Success: No tag
        content = "Summon Cloud Rift Success✅"
        color = 0x00FF00 -- Green
    else
        -- Failed: With tag
        if summonDiscordID ~= "" then
            content = "Failed Summoning Cloud Rift❌ <@" .. summonDiscordID .. ">"
        else
            content = "Failed Summoning Cloud Rift❌"
        end
        color = 0xFF0000 -- Red
    end
    
    -- Prevent duplicate sends
    if content == lastSummonState then return end
    lastSummonState = content
    
    pcall(function()
        request({
            Url = summonWebhookURL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                content = content,
                embeds = {{
                    title = success and "✅ Rift Summoned" or "❌ Summon Failed",
                    description = "**" .. player.Name .. "**",
                    color = color,
                    footer = {text = "Renoa Hub * " .. os.date("%Y-%m-%d %H:%M:%S")}
                }}
            })
        })
        print("[Summon Webhook] " .. content)
    end)
end

-- ======================================
-- UI - EVENT BOARD
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
                    -- Wait for questActive to be false (respects priority system)
                    while getgenv().questActive and autoHatchRiftEnabled do
                        wasActive = false
                        task.wait(0.5)
                    end
                    
                    -- Check if higher priority rifts exist
                    local higherPriorityActive = false
                    if isRiftExists("corruptshadow-rift") or isRiftExists("overlord-rift") or isRiftExists("shadow-rift") or isRiftExists("doodle-rift") then
                        higherPriorityActive = true
                    end
                    
                    if higherPriorityActive then
                        wasActive = false
                        task.wait(1)
                        continue
                    end
                    
                    if isRiftExists(riftName) then
                        task.wait(4) -- Wait 4s after questActive false (same as other auto hatches)
                        if getgenv().questActive then continue end
                        
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
                        
                        summonRift()
                        task.wait(3) -- Wait for rift to appear
                        
                        -- Check if summon succeeded
                        if isRiftExists(riftName) then
                            sendSummonWebhook(true) -- Success
                        else
                            sendSummonWebhook(false) -- Failed
                        end
                        
                        task.wait(5)
                    else
                        task.wait(30)
                    end
                end
            end)
        else
            if autoSummonRiftThread then task.cancel(autoSummonRiftThread) end
        end
    end
})

-- ======================================
-- UI - SUMMON WEBHOOK
-- ======================================
EventTab:CreateSection("Summon Webhook")

EventTab:CreateInput({
    Name = "Summon Webhook URL",
    CurrentValue = summonWebhookURL,
    PlaceholderText = "https://discord.com/api/webhooks/...",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        summonWebhookURL = v
        eventSettings.summonWebhookURL = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
    end
})

EventTab:CreateInput({
    Name = "Discord User ID (for failed tag)",
    CurrentValue = summonDiscordID,
    PlaceholderText = "Discord_User_ID",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        summonDiscordID = v
        eventSettings.summonDiscordID = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
    end
})

EventTab:CreateLabel("✅ Success: No tag")
EventTab:CreateLabel("❌ Failed: With tag")

-- ======================================
-- UI - EVENT SHOP
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
        local wasActive = false
        while autoHatchRiftEnabled do
            while getgenv().questActive and autoHatchRiftEnabled do
                wasActive = false
                task.wait(0.5)
            end
            
            local higherPriorityActive = false
            if isRiftExists("corruptshadow-rift") or isRiftExists("overlord-rift") or isRiftExists("shadow-rift") or isRiftExists("doodle-rift") then
                higherPriorityActive = true
            end
            
            if higherPriorityActive then
                wasActive = false
                task.wait(1)
                continue
            end
            
            if isRiftExists(riftName) then
                task.wait(4)
                if getgenv().questActive then continue end
                
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
end

if autoSummonRiftEnabled then
    autoSummonRiftThread = task.spawn(function()
        while autoSummonRiftEnabled do
            if not isRiftExists(riftName) then
                summonRift()
                task.wait(3)
                
                if isRiftExists(riftName) then
                    sendSummonWebhook(true)
                else
                    sendSummonWebhook(false)
                end
                
                task.wait(5)
            else
                task.wait(30)
            end
        end
    end)
end

print("[Event] Loaded!")
