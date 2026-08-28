-- ================================================
-- EVENT TAB (NEW EVENT SHOP + EVENT ALTAR)
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

local autoHatchRiftEnabled = eventSettings.autoHatchRift or false
local autoHatchRiftThread = nil
local autoSummonRiftEnabled = eventSettings.autoSummonRift or false
local autoSummonRiftThread = nil

local HATCH_AMOUNT = 12
local riftName = "cloud-rift"
local riftEgg = "Cloudy Rift Egg"
local riftWorld = "The Overworld"

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

local function getRiftLuck(rift)
    local display = rift:FindFirstChild("Display")
    if display then
        local surfaceGui = display:FindFirstChild("SurfaceGui")
        if surfaceGui then
            for _, child in ipairs(surfaceGui:GetDescendants()) do
                if child:IsA("TextLabel") and child.Name == "Luck" then
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

local function teleportToBestRift(riftName)
    local bestRift, bestLuck = getHighestLuckRift(riftName)
    if bestRift then
        local spawn = bestRift:FindFirstChild("EggPlatformSpawn")
        if spawn then
            local part = spawn:FindFirstChild("Part")
            if part then
                local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    root.CFrame = CFrame.new(part.Position + Vector3.new(0, 5, 0))
                    root.Velocity = Vector3.zero
                    root.RotVelocity = Vector3.zero
                    return bestLuck
                end
            end
        end
    end
    return 0
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
-- SUMMON WEBHOOK (USES ACTIVITY SETTINGS)
-- ======================================
local lastSummonState = ""

local function sendSummonWebhook(success)
    local webhookURL = settings.activity.webhookURL or ""
    local discordID = settings.activity.userId or ""
    
    if webhookURL == "" then return end
    
    local content = ""
    local color = 0
    
    if success then
        content = "Summon Cloud Rift Success✅"
        color = 0x00FF00
    else
        if discordID ~= "" then
            content = "Failed Summoning Cloud Rift❌ <@" .. discordID .. ">"
        else
            content = "Failed Summoning Cloud Rift❌"
        end
        color = 0xFF0000
    end
    
    if content == lastSummonState then return end
    lastSummonState = content
    
    pcall(function()
        request({
            Url = webhookURL,
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
-- SKY ALTAR FUNCTIONS
-- ======================================
local function getSkyAltarPets()
    local groups = {Normal = {}, Shiny = {}, Mythic = {}, ShinyMythic = {}}
    
    local data = LocalData:Get()
    if data and data.Pets then
        for _, pet in pairs(data.Pets) do
            if not pet.Locked then
                local info = Pets[pet.Name]
                if info and info.Rarity and info.Rarity:find("Secret") then
                    if pet.Shiny and pet.Mythic then
                        table.insert(groups.ShinyMythic, pet)
                    elseif pet.Shiny then
                        table.insert(groups.Shiny, pet)
                    elseif pet.Mythic then
                        table.insert(groups.Mythic, pet)
                    else
                        table.insert(groups.Normal, pet)
                    end
                end
            end
        end
    end
    
    if #groups.Normal >= 5 then return groups.Normal end
    if #groups.Shiny >= 5 then return groups.Shiny end
    if #groups.Mythic >= 5 then return groups.Mythic end
    if #groups.ShinyMythic >= 5 then return groups.ShinyMythic end
    return {}
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
                local currentLuck = 0
                local lastCheckTime = 0
                local riftExists = false
                
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
                        riftExists = false
                        task.wait(1)
                        continue
                    end
                    
                    local now = tick()
                    if now - lastCheckTime >= 5 then
                        lastCheckTime = now
                        riftExists = isRiftExists(riftName)
                        if riftExists then
                            currentLuck = teleportToBestRift(riftName)
                        end
                    end
                    
                    if riftExists then
                        if getgenv().questActive then continue end
                        
                        getgenv().questActive = true
                        getgenv().questEgg = riftEgg
                        
                        if not wasActive then
                            getgenv().ActivityStatus.current = "Hatching " .. riftEgg .. (currentLuck > 0 and " (x" .. currentLuck .. " luck)" or "")
                            getgenv().ActivityStatus.trigger = true
                            wasActive = true
                        end
                        
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
                    getgenv().ActivityStatus.current = "Summoning " .. riftName
                    getgenv().ActivityStatus.trigger = true
                    
                    summonRift()
                    task.wait(5)
                    
                    if isRiftExists(riftName) then
                        sendSummonWebhook(true)
                    else
                        sendSummonWebhook(false)
                    end
                    
                    task.wait(3300)
                end
            end)
        else
            if autoSummonRiftThread then task.cancel(autoSummonRiftThread) end
        end
    end
})

-- ======================================
-- UI - EVENT SHOP (NEW)
-- ======================================
EventTab:CreateSection("Event Shop")

-- Toggle #1: Event Egg (Item 1)
EventTab:CreateToggle({
    Name = "Auto Buy Event Egg (1)",
    CurrentValue = eventSettings.autoShop1 or false,
    Callback = function(v)
        eventSettings.autoShop1 = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            task.spawn(function()
                while v do
                    pcall(function() RE:FireServer("BuyShopItem", "megaegg-shop", 1, false) end)
                    task.wait(0.5)
                end
            end)
        end
    end
})

-- Toggle #2: Boost Crystal (Item 2)
EventTab:CreateToggle({
    Name = "Auto Buy Boost Crystal (2)",
    CurrentValue = eventSettings.autoShop2 or false,
    Callback = function(v)
        eventSettings.autoShop2 = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            task.spawn(function()
                while v do
                    pcall(function() RE:FireServer("BuyShopItem", "megaegg-shop", 2, false) end)
                    task.wait(0.5)
                end
            end)
        end
    end
})

-- Toggle #3: Event Elixir (Item 3)
EventTab:CreateToggle({
    Name = "Auto Buy Event Elixir (3)",
    CurrentValue = eventSettings.autoShop3 or false,
    Callback = function(v)
        eventSettings.autoShop3 = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            task.spawn(function()
                while v do
                    pcall(function() RE:FireServer("BuyShopItem", "megaegg-shop", 3, false) end)
                    task.wait(0.5)
                end
            end)
        end
    end
})

-- Toggle #4: Infinity Elixir (Items 4-7)
EventTab:CreateToggle({
    Name = "Auto Buy Infinity Elixir (4,5,6,7)",
    CurrentValue = eventSettings.autoShop4 or false,
    Callback = function(v)
        eventSettings.autoShop4 = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            task.spawn(function()
                while v do
                    for i = 4, 7 do
                        pcall(function() RE:FireServer("BuyShopItem", "megaegg-shop", i, false) end)
                        task.wait(0.3)
                    end
                end
            end)
        end
    end
})

-- Toggle #5: Infinity luck/mythic/gold (Items 8-10)
EventTab:CreateToggle({
    Name = "Auto Buy Infinity Luck/Mythic/Gold (8,9,10)",
    CurrentValue = eventSettings.autoShop5 or false,
    Callback = function(v)
        eventSettings.autoShop5 = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            task.spawn(function()
                while v do
                    for i = 8, 10 do
                        pcall(function() RE:FireServer("BuyShopItem", "megaegg-shop", i, false) end)
                        task.wait(0.3)
                    end
                end
            end)
        end
    end
})

-- Toggle #6: Normal Pet Shop (Item 11)
EventTab:CreateToggle({
    Name = "Auto Buy Normal Pet (11)",
    CurrentValue = eventSettings.autoShop6 or false,
    Callback = function(v)
        eventSettings.autoShop6 = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            task.spawn(function()
                while v do
                    pcall(function() RE:FireServer("BuyShopItem", "megaegg-shop", 11, false) end)
                    task.wait(0.5)
                end
            end)
        end
    end
})

-- Toggle #7: XL Pet Shop (Item 12)
EventTab:CreateToggle({
    Name = "Auto Buy XL Pet (12)",
    CurrentValue = eventSettings.autoShop7 or false,
    Callback = function(v)
        eventSettings.autoShop7 = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            task.spawn(function()
                while v do
                    pcall(function() RE:FireServer("BuyShopItem", "megaegg-shop", 12, false) end)
                    task.wait(0.5)
                end
            end)
        end
    end
})

-- Toggle #8: Green & Blue Fragment (Items 13-14)
EventTab:CreateToggle({
    Name = "Auto Buy Green & Blue Fragment (13,14)",
    CurrentValue = eventSettings.autoShop8 or false,
    Callback = function(v)
        eventSettings.autoShop8 = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            task.spawn(function()
                while v do
                    for i = 13, 14 do
                        pcall(function() RE:FireServer("BuyShopItem", "megaegg-shop", i, false) end)
                        task.wait(0.3)
                    end
                end
            end)
        end
    end
})

-- Toggle #9: Purple & Rainbow Fragment (Items 15-16)
EventTab:CreateToggle({
    Name = "Auto Buy Purple & Rainbow Fragment (15,16)",
    CurrentValue = eventSettings.autoShop9 or false,
    Callback = function(v)
        eventSettings.autoShop9 = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            task.spawn(function()
                while v do
                    for i = 15, 16 do
                        pcall(function() RE:FireServer("BuyShopItem", "megaegg-shop", i, false) end)
                        task.wait(0.3)
                    end
                end
            end)
        end
    end
})

-- ======================================
-- UI - EVENT ALTAR (EVENT REBIRTH MACHINE)
-- ======================================
EventTab:CreateSection("Event Altar (Event Rebirth Machine)")

EventTab:CreateLabel("Uses SkyAltar with Secret pets")

local altarTrackerLabel = EventTab:CreateLabel("Last Used: None")

EventTab:CreateToggle({
    Name = "Auto Event Altar",
    CurrentValue = eventSettings.autoSkyAltar or false,
    Callback = function(v)
        eventSettings.autoSkyAltar = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            pcall(function() altarTrackerLabel:SetText("Last Used: None") end)
            task.spawn(function()
                local lastPrint = ""
                local wasActive = false
                while v do
                    task.wait(5)
                    
                    local pets = getSkyAltarPets()
                    if #pets < 5 then
                        wasActive = false
                        continue
                    end
                    
                    local variantName = "Normal"
                    if pets[1].Shiny and pets[1].Mythic then variantName = "Shiny Mythic"
                    elseif pets[1].Shiny then variantName = "Shiny"
                    elseif pets[1].Mythic then variantName = "Mythic" end
                    
                    local payload = {}
                    local usedNames = {}
                    for i = 1, 5 do
                        table.insert(payload, tostring(pets[i].Id))
                        table.insert(usedNames, variantName .. " " .. pets[i].Name)
                    end
                    
                    local text = table.concat(usedNames, ", ")
                    pcall(function() altarTrackerLabel:SetText("Last Used: " .. text) end)
                    
                    pcall(function()
                        RemoteFunction:InvokeServer("UseRebirthMachine", "SkyAltar", payload)
                    end)
                    
                    if not wasActive then
                        getgenv().ActivityStatus.current = "Event Altar used: " .. text
                        getgenv().ActivityStatus.trigger = true
                        wasActive = true
                    end
                    
                    if text ~= lastPrint then
                        print("[Event Altar] " .. text)
                        lastPrint = text
                    end
                    
                    task.wait(1.5)
                end
            end)
        end
    end
})

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
        local currentLuck = 0
        local lastCheckTime = 0
        local riftExists = false
        
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
                riftExists = false
                task.wait(1)
                continue
            end
            
            local now = tick()
            if now - lastCheckTime >= 5 then
                lastCheckTime = now
                riftExists = isRiftExists(riftName)
                if riftExists then
                    currentLuck = teleportToBestRift(riftName)
                end
            end
            
            if riftExists then
                if getgenv().questActive then continue end
                
                getgenv().questActive = true
                getgenv().questEgg = riftEgg
                
                if not wasActive then
                    getgenv().ActivityStatus.current = "Hatching " .. riftEgg .. (currentLuck > 0 and " (x" .. currentLuck .. " luck)" or "")
                    getgenv().ActivityStatus.trigger = true
                    wasActive = true
                end
                
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
            summonRift()
            task.wait(5)
            
            if isRiftExists(riftName) then
                sendSummonWebhook(true)
            else
                sendSummonWebhook(false)
            end
            
            task.wait(3300)
        end
    end)
end

if eventSettings.autoShop1 then
    task.spawn(function()
        while eventSettings.autoShop1 do
            pcall(function() RE:FireServer("BuyShopItem", "megaegg-shop", 1, false) end)
            task.wait(0.5)
        end
    end)
end

if eventSettings.autoShop2 then
    task.spawn(function()
        while eventSettings.autoShop2 do
            pcall(function() RE:FireServer("BuyShopItem", "megaegg-shop", 2, false) end)
            task.wait(0.5)
        end
    end)
end

if eventSettings.autoShop3 then
    task.spawn(function()
        while eventSettings.autoShop3 do
            pcall(function() RE:FireServer("BuyShopItem", "megaegg-shop", 3, false) end)
            task.wait(0.5)
        end
    end)
end

if eventSettings.autoShop4 then
    task.spawn(function()
        while eventSettings.autoShop4 do
            for i = 4, 7 do
                pcall(function() RE:FireServer("BuyShopItem", "megaegg-shop", i, false) end)
                task.wait(0.3)
            end
        end
    end)
end

if eventSettings.autoShop5 then
    task.spawn(function()
        while eventSettings.autoShop5 do
            for i = 8, 10 do
                pcall(function() RE:FireServer("BuyShopItem", "megaegg-shop", i, false) end)
                task.wait(0.3)
            end
        end
    end)
end

if eventSettings.autoShop6 then
    task.spawn(function()
        while eventSettings.autoShop6 do
            pcall(function() RE:FireServer("BuyShopItem", "megaegg-shop", 11, false) end)
            task.wait(0.5)
        end
    end)
end

if eventSettings.autoShop7 then
    task.spawn(function()
        while eventSettings.autoShop7 do
            pcall(function() RE:FireServer("BuyShopItem", "megaegg-shop", 12, false) end)
            task.wait(0.5)
        end
    end)
end

if eventSettings.autoShop8 then
    task.spawn(function()
        while eventSettings.autoShop8 do
            for i = 13, 14 do
                pcall(function() RE:FireServer("BuyShopItem", "megaegg-shop", i, false) end)
                task.wait(0.3)
            end
        end
    end)
end

if eventSettings.autoShop9 then
    task.spawn(function()
        while eventSettings.autoShop9 do
            for i = 15, 16 do
                pcall(function() RE:FireServer("BuyShopItem", "megaegg-shop", i, false) end)
                task.wait(0.3)
            end
        end
    end)
end

if eventSettings.autoSkyAltar then
    task.spawn(function()
        local lastPrint = ""
        local wasActive = false
        while eventSettings.autoSkyAltar do
            task.wait(5)
            
            local pets = getSkyAltarPets()
            if #pets < 5 then
                wasActive = false
                continue
            end
            
            local variantName = "Normal"
            if pets[1].Shiny and pets[1].Mythic then variantName = "Shiny Mythic"
            elseif pets[1].Shiny then variantName = "Shiny"
            elseif pets[1].Mythic then variantName = "Mythic" end
            
            local payload = {}
            local usedNames = {}
            for i = 1, 5 do
                table.insert(payload, tostring(pets[i].Id))
                table.insert(usedNames, variantName .. " " .. pets[i].Name)
            end
            
            local text = table.concat(usedNames, ", ")
            pcall(function() altarTrackerLabel:SetText("Last Used: " .. text) end)
            
            pcall(function()
                RemoteFunction:InvokeServer("UseRebirthMachine", "SkyAltar", payload)
            end)
            
            if not wasActive then
                getgenv().ActivityStatus.current = "Event Altar used: " .. text
                getgenv().ActivityStatus.trigger = true
                wasActive = true
            end
            
            if text ~= lastPrint then
                print("[Event Altar] " .. text)
                lastPrint = text
            end
            
            task.wait(1.5)
        end
    end)
end

print("[Event] Loaded!")
