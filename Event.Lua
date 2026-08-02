-- ================================================
-- EVENT TAB (AUTO EVENT + CRYSTAL SHOP + CRYSTAL ALTAR)
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

-- Crystal Altar settings
local crystalAltarRunning = false
local crystalAltarThread = nil

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
-- CRYSTAL ALTAR FUNCTIONS
-- ======================================
local function getCrystalPets()
    local groups = {Normal = {}, Shiny = {}, Mythic = {}, ShinyMythic = {}}
    local data = LocalData:Get()
    if data and data.Pets then
        for _, pet in pairs(data.Pets) do
            if not pet.Locked then
                local info = Pets[pet.Name]
                if info and info.Egg and info.Egg == "Crystal Ore Egg" then
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
    
    if #groups.Normal >= 3 then return groups.Normal end
    if #groups.Shiny >= 3 then return groups.Shiny end
    if #groups.Mythic >= 3 then return groups.Mythic end
    if #groups.ShinyMythic >= 3 then return groups.ShinyMythic end
    return {}
end

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
-- UI - CRYSTAL SHOP
-- ======================================
EventTab:CreateSection("Crystal Shop")

EventTab:CreateToggle({
    Name = "Auto Buy Hatching Rune",
    CurrentValue = eventSettings.autoBuyRune or false,
    Callback = function(v)
        runeRunning = v
        eventSettings.autoBuyRune = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
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
    CurrentValue = eventSettings.autoBuyGreenBlue or false,
    Callback = function(v)
        greenBlueRunning = v
        eventSettings.autoBuyGreenBlue = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
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
    CurrentValue = eventSettings.autoBuyPurpleRainbow or false,
    Callback = function(v)
        purpleRainbowRunning = v
        eventSettings.autoBuyPurpleRainbow = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
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
    CurrentValue = eventSettings.autoBuyPowerCrystal or false,
    Callback = function(v)
        crystalRunning = v
        eventSettings.autoBuyPowerCrystal = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
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
    CurrentValue = eventSettings.autoBuySunburst or false,
    Callback = function(v)
        sunburstRunning = v
        eventSettings.autoBuySunburst = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
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

-- ======================================
-- UI - REBIRTH MACHINE (CRYSTAL ALTAR)
-- ======================================
EventTab:CreateSection("Rebirth Machine (Crystal Altar)")

EventTab:CreateLabel("Testing, Make sure to Lock all Valuable Pets before execute this")
EventTab:CreateLabel("Only uses 3 pets from Crystal Ore Egg (same variant)")

local crystalTrackerLabel = EventTab:CreateLabel("Last Used: None")

EventTab:CreateToggle({
    Name = "Auto Crystal Altar",
    CurrentValue = eventSettings.autoCrystalAltar or false,
    Callback = function(v)
        crystalAltarRunning = v
        eventSettings.autoCrystalAltar = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            pcall(function() crystalTrackerLabel:SetText("Last Used: None") end)
            crystalAltarThread = task.spawn(function()
                local lastPrint = ""
                local wasActive = false
                while crystalAltarRunning do
                    task.wait(3)
                    
                    local pets = getCrystalPets()
                    if #pets < 3 then
                        wasActive = false
                        continue
                    end
                    
                    local variantName = "Normal"
                    if pets[1].Shiny and pets[1].Mythic then variantName = "Shiny Mythic"
                    elseif pets[1].Shiny then variantName = "Shiny"
                    elseif pets[1].Mythic then variantName = "Mythic" end
                    
                    local payload = {}
                    local usedNames = {}
                    for i = 1, 3 do
                        table.insert(payload, tostring(pets[i].Id))
                        table.insert(usedNames, variantName .. " " .. pets[i].Name)
                    end
                    
                    local text = table.concat(usedNames, ", ")
                    pcall(function() crystalTrackerLabel:SetText("Last Used: " .. text) end)
                    
                    pcall(function()
                        RemoteFunction:InvokeServer("UseRebirthMachine", "CrystalAltar", payload)
                    end)
                    
                    if not wasActive then
                        getgenv().ActivityStatus.current = "Crystal Altar used: " .. text
                        getgenv().ActivityStatus.trigger = true
                        wasActive = true
                    end
                    
                    if text ~= lastPrint then
                        print("[Crystal Altar] " .. text)
                        lastPrint = text
                    end
                    
                    task.wait(1.5)
                end
            end)
        else
            if crystalAltarThread then task.cancel(crystalAltarThread) end
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

if eventSettings.autoBuyRune then
    runeRunning = true
    runeThread = task.spawn(function()
        while runeRunning do
            pcall(function() RE:FireServer("BuyShopItem", "crystal-shop", 4, false) end)
            pcall(function() RE:FireServer("BuyShopItem", "crystal-shop", 5, false) end)
            pcall(function() RE:FireServer("BuyShopItem", "crystal-shop", 6, false) end)
            task.wait(1)
        end
    end)
end

if eventSettings.autoBuyGreenBlue then
    greenBlueRunning = true
    greenBlueThread = task.spawn(function()
        while greenBlueRunning do
            pcall(function() RE:FireServer("BuyShopItem", "crystal-shop", 7, false) end)
            pcall(function() RE:FireServer("BuyShopItem", "crystal-shop", 8, false) end)
            task.wait(1)
        end
    end)
end

if eventSettings.autoBuyPurpleRainbow then
    purpleRainbowRunning = true
    purpleRainbowThread = task.spawn(function()
        while purpleRainbowRunning do
            pcall(function() RE:FireServer("BuyShopItem", "crystal-shop", 9, false) end)
            pcall(function() RE:FireServer("BuyShopItem", "crystal-shop", 10, false) end)
            task.wait(1)
        end
    end)
end

if eventSettings.autoBuyPowerCrystal then
    crystalRunning = true
    crystalThread = task.spawn(function()
        while crystalRunning do
            pcall(function() RE:FireServer("BuyShopItem", "crystal-shop", 13, false) end)
            task.wait(1)
        end
    end)
end

if eventSettings.autoBuySunburst then
    sunburstRunning = true
    sunburstThread = task.spawn(function()
        while sunburstRunning do
            pcall(function() RE:FireServer("BuyShopItem", "crystal-shop", 14, false) end)
            task.wait(1)
        end
    end)
end

if eventSettings.autoCrystalAltar then
    crystalAltarRunning = true
    crystalAltarThread = task.spawn(function()
        local lastPrint = ""
        local wasActive = false
        while crystalAltarRunning do
            task.wait(3)
            
            local pets = getCrystalPets()
            if #pets < 3 then
                wasActive = false
                continue
            end
            
            local variantName = "Normal"
            if pets[1].Shiny and pets[1].Mythic then variantName = "Shiny Mythic"
            elseif pets[1].Shiny then variantName = "Shiny"
            elseif pets[1].Mythic then variantName = "Mythic" end
            
            local payload = {}
            local usedNames = {}
            for i = 1, 3 do
                table.insert(payload, tostring(pets[i].Id))
                table.insert(usedNames, variantName .. " " .. pets[i].Name)
            end
            
            local text = table.concat(usedNames, ", ")
            pcall(function() crystalTrackerLabel:SetText("Last Used: " .. text) end)
            
            pcall(function()
                RemoteFunction:InvokeServer("UseRebirthMachine", "CrystalAltar", payload)
            end)
            
            if not wasActive then
                getgenv().ActivityStatus.current = "Crystal Altar used: " .. text
                getgenv().ActivityStatus.trigger = true
                wasActive = true
            end
            
            if text ~= lastPrint then
                print("[Crystal Altar] " .. text)
                lastPrint = text
            end
            
            task.wait(1.5)
        end
    end)
end

print("[Event] Loaded!")
