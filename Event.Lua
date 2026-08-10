-- ================================================
-- EVENT TAB (AUTO EVENT + EVENT SHOP 1 + DAILY REWARD SHOP + CRYSTAL ALTAR)
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

-- Crystal Altar settings
local crystalAltarRunning = false
local crystalAltarThread = nil

-- Daily Reward Shop settings
local dailyShadowCrystalRunning = false
local dailyShadowCrystalThread = nil
local dailyEggElixirRunning = false
local dailyEggElixirThread = nil
local dailySecretElixirRunning = false
local dailySecretElixirThread = nil
local dailyGreenBlueRunning = false
local dailyGreenBlueThread = nil
local dailyPurpleRainbowRunning = false
local dailyPurpleRainbowThread = nil

-- Event Shop 1 settings
local shop1Running = false
local shop1Thread = nil
local shop2Running = false
local shop2Thread = nil
local shop3Running = false
local shop3Thread = nil
local shop4Running = false
local shop4Thread = nil
local shop5Running = false
local shop5Thread = nil
local shop6Running = false
local shop6Thread = nil
local shop7Running = false
local shop7Thread = nil
local shop8Running = false
local shop8Thread = nil
local shop9Running = false
local shop9Thread = nil
local shop10Running = false
local shop10Thread = nil

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
-- EVENT SHOP STOCK CHECKER
-- ======================================
local function getStock(itemNum)
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        local screenGui = playerGui:FindFirstChild("ScreenGui")
        if screenGui then
            local itemShop = screenGui:FindFirstChild("ItemShop")
            if itemShop then
                local frame = itemShop:FindFirstChild("Frame")
                if frame then
                    local main = frame:FindFirstChild("Main")
                    if main then
                        local scrollingFrame = main:FindFirstChild("ScrollingFrame")
                        if scrollingFrame then
                            local item = scrollingFrame:FindFirstChild("Item" .. itemNum)
                            if item then
                                local stockLabel = item:FindFirstChild("Stock")
                                if stockLabel then
                                    return stockLabel.Text
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return "Unknown"
end

local function isInStock(itemNum)
    local stock = getStock(itemNum)
    if stock == "Unknown" then return true end
    return not stock:lower():find("out of stock")
end

-- ======================================
-- CRYSTAL ALTAR FUNCTIONS
-- ======================================
local function getCrystalPets()
    local groups = {Normal = {}, Shiny = {}, Mythic = {}, ShinyMythic = {}}
    
    local EXCLUDE_NAMES = {
        ["Ruby Crystal Dragon"] = true,
        ["Emerald Crystal Dragon"] = true,
        ["Sapphire Crystal Dragon"] = true,
        ["Crowned Jewel"] = true,
        ["Crystal Dementor"] = true,
        ["Crystal Koi"] = true,
    }
    
    local data = LocalData:Get()
    if data and data.Pets then
        for _, pet in pairs(data.Pets) do
            if not pet.Locked then
                local info = Pets[pet.Name]
                if info 
                    and info.Egg 
                    and info.Egg == "Crystal Ore Egg" 
                    and info.Rarity 
                    and info.Rarity:find("Secret")
                    and not EXCLUDE_NAMES[pet.Name]
                then
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
-- UI - EVENT SHOP 1
-- ======================================
EventTab:CreateSection("Event Shop 1")

-- Toggle #1: Superhero Egg (Item 1)
EventTab:CreateToggle({
    Name = "Auto Buy Superhero Egg (1)",
    CurrentValue = eventSettings.autoShop1 or false,
    Callback = function(v)
        shop1Running = v
        eventSettings.autoShop1 = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            shop1Thread = task.spawn(function()
                while shop1Running do
                    if isInStock(1) then
                        pcall(function() RE:FireServer("BuyShopItem", "eggcomp-shop", 1, true) end)
                        task.wait(0.1)
                    else
                        task.wait(10)
                    end
                end
            end)
        else
            if shop1Thread then task.cancel(shop1Thread) end
        end
    end
})

-- Toggle #2: Boost Crystal (Item 2)
EventTab:CreateToggle({
    Name = "Auto Buy Boost Crystal (2)",
    CurrentValue = eventSettings.autoShop2 or false,
    Callback = function(v)
        shop2Running = v
        eventSettings.autoShop2 = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            shop2Thread = task.spawn(function()
                while shop2Running do
                    if isInStock(2) then
                        pcall(function() RE:FireServer("BuyShopItem", "eggcomp-shop", 2, true) end)
                        task.wait(0.1)
                    else
                        task.wait(10)
                    end
                end
            end)
        else
            if shop2Thread then task.cancel(shop2Thread) end
        end
    end
})

-- Toggle #3: Shrine Ticket (Item 3)
EventTab:CreateToggle({
    Name = "Auto Buy Shrine Ticket (3)",
    CurrentValue = eventSettings.autoShop3 or false,
    Callback = function(v)
        shop3Running = v
        eventSettings.autoShop3 = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            shop3Thread = task.spawn(function()
                while shop3Running do
                    if isInStock(3) then
                        pcall(function() RE:FireServer("BuyShopItem", "eggcomp-shop", 3, true) end)
                        task.wait(0.1)
                    else
                        task.wait(10)
                    end
                end
            end)
        else
            if shop3Thread then task.cancel(shop3Thread) end
        end
    end
})

-- Toggle #4: Secret, Infinity & Egg Elixir (Items 4,5,6)
EventTab:CreateToggle({
    Name = "Auto Buy Secret, Inf & Egg Elixir (4,5,6)",
    CurrentValue = eventSettings.autoShop4 or false,
    Callback = function(v)
        shop4Running = v
        eventSettings.autoShop4 = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            shop4Thread = task.spawn(function()
                while shop4Running do
                    local anyBought = false
                    for i = 4, 6 do
                        if isInStock(i) then
                            pcall(function() RE:FireServer("BuyShopItem", "eggcomp-shop", i, true) end)
                            anyBought = true
                            task.wait(0.1)
                        end
                    end
                    if not anyBought then
                        task.wait(10)
                    end
                end
            end)
        else
            if shop4Thread then task.cancel(shop4Thread) end
        end
    end
})

-- Toggle #5: Ultra Infinity Elixir (Item 7)
EventTab:CreateToggle({
    Name = "Auto Buy Ultra Inf Elixir (7)",
    CurrentValue = eventSettings.autoShop5 or false,
    Callback = function(v)
        shop5Running = v
        eventSettings.autoShop5 = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            shop5Thread = task.spawn(function()
                while shop5Running do
                    if isInStock(7) then
                        pcall(function() RE:FireServer("BuyShopItem", "eggcomp-shop", 7, true) end)
                        task.wait(0.1)
                    else
                        task.wait(10)
                    end
                end
            end)
        else
            if shop5Thread then task.cancel(shop5Thread) end
        end
    end
})

-- Toggle #6: Lucky, Mythic & Speed Infinity (Items 8,9,10)
EventTab:CreateToggle({
    Name = "Auto Buy Lucky, Mythic & Speed Inf (8,9,10)",
    CurrentValue = eventSettings.autoShop6 or false,
    Callback = function(v)
        shop6Running = v
        eventSettings.autoShop6 = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            shop6Thread = task.spawn(function()
                while shop6Running do
                    local anyBought = false
                    for i = 8, 10 do
                        if isInStock(i) then
                            pcall(function() RE:FireServer("BuyShopItem", "eggcomp-shop", i, true) end)
                            anyBought = true
                            task.wait(0.1)
                        end
                    end
                    if not anyBought then
                        task.wait(10)
                    end
                end
            end)
        else
            if shop6Thread then task.cancel(shop6Thread) end
        end
    end
})

-- Toggle #7: Shop Pet (Item 11)
EventTab:CreateToggle({
    Name = "Auto Buy Shop Pet (11)",
    CurrentValue = eventSettings.autoShop7 or false,
    Callback = function(v)
        shop7Running = v
        eventSettings.autoShop7 = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            shop7Thread = task.spawn(function()
                while shop7Running do
                    if isInStock(11) then
                        pcall(function() RE:FireServer("BuyShopItem", "eggcomp-shop", 11, true) end)
                        task.wait(0.1)
                    else
                        task.wait(10)
                    end
                end
            end)
        else
            if shop7Thread then task.cancel(shop7Thread) end
        end
    end
})

-- Toggle #8: Shop Pet XL (Item 12)
EventTab:CreateToggle({
    Name = "Auto Buy Shop Pet XL (12)",
    CurrentValue = eventSettings.autoShop8 or false,
    Callback = function(v)
        shop8Running = v
        eventSettings.autoShop8 = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            shop8Thread = task.spawn(function()
                while shop8Running do
                    if isInStock(12) then
                        pcall(function() RE:FireServer("BuyShopItem", "eggcomp-shop", 12, true) end)
                        task.wait(0.1)
                    else
                        task.wait(10)
                    end
                end
            end)
        else
            if shop8Thread then task.cancel(shop8Thread) end
        end
    end
})

-- Toggle #9: Green & Blue Fragment (Items 13,14)
EventTab:CreateToggle({
    Name = "Auto Buy Green & Blue Frag (13,14)",
    CurrentValue = eventSettings.autoShop9 or false,
    Callback = function(v)
        shop9Running = v
        eventSettings.autoShop9 = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            shop9Thread = task.spawn(function()
                while shop9Running do
                    local anyBought = false
                    for i = 13, 14 do
                        if isInStock(i) then
                            pcall(function() RE:FireServer("BuyShopItem", "eggcomp-shop", i, true) end)
                            anyBought = true
                            task.wait(0.1)
                        end
                    end
                    if not anyBought then
                        task.wait(10)
                    end
                end
            end)
        else
            if shop9Thread then task.cancel(shop9Thread) end
        end
    end
})

-- Toggle #10: Purple & Rainbow Fragment (Items 15,16)
EventTab:CreateToggle({
    Name = "Auto Buy Purple & Rainbow Frag (15,16)",
    CurrentValue = eventSettings.autoShop10 or false,
    Callback = function(v)
        shop10Running = v
        eventSettings.autoShop10 = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            shop10Thread = task.spawn(function()
                while shop10Running do
                    local anyBought = false
                    for i = 15, 16 do
                        if isInStock(i) then
                            pcall(function() RE:FireServer("BuyShopItem", "eggcomp-shop", i, true) end)
                            anyBought = true
                            task.wait(0.1)
                        end
                    end
                    if not anyBought then
                        task.wait(10)
                    end
                end
            end)
        else
            if shop10Thread then task.cancel(shop10Thread) end
        end
    end
})

-- ======================================
-- UI - DAILY REWARD SHOP
-- ======================================
EventTab:CreateSection("Daily Reward Shop")

EventTab:CreateToggle({
    Name = "Auto Buy Shadow Crystal (24)",
    CurrentValue = eventSettings.autoDailyShadowCrystal or false,
    Callback = function(v)
        dailyShadowCrystalRunning = v
        eventSettings.autoDailyShadowCrystal = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            dailyShadowCrystalThread = task.spawn(function()
                while dailyShadowCrystalRunning do
                    pcall(function() RE:FireServer("DailyRewardsBuyItem", 24) end)
                    task.wait(1)
                end
            end)
        else
            if dailyShadowCrystalThread then task.cancel(dailyShadowCrystalThread) end
        end
    end
})

EventTab:CreateToggle({
    Name = "Auto Buy Egg Elixir (23)",
    CurrentValue = eventSettings.autoDailyEggElixir or false,
    Callback = function(v)
        dailyEggElixirRunning = v
        eventSettings.autoDailyEggElixir = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            dailyEggElixirThread = task.spawn(function()
                while dailyEggElixirRunning do
                    pcall(function() RE:FireServer("DailyRewardsBuyItem", 23) end)
                    task.wait(1)
                end
            end)
        else
            if dailyEggElixirThread then task.cancel(dailyEggElixirThread) end
        end
    end
})

EventTab:CreateToggle({
    Name = "Auto Buy Secret Elixir (22)",
    CurrentValue = eventSettings.autoDailySecretElixir or false,
    Callback = function(v)
        dailySecretElixirRunning = v
        eventSettings.autoDailySecretElixir = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            dailySecretElixirThread = task.spawn(function()
                while dailySecretElixirRunning do
                    pcall(function() RE:FireServer("DailyRewardsBuyItem", 22) end)
                    task.wait(1)
                end
            end)
        else
            if dailySecretElixirThread then task.cancel(dailySecretElixirThread) end
        end
    end
})

EventTab:CreateToggle({
    Name = "Auto Buy Green & Blue Fragment (25 & 26)",
    CurrentValue = eventSettings.autoDailyGreenBlue or false,
    Callback = function(v)
        dailyGreenBlueRunning = v
        eventSettings.autoDailyGreenBlue = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            dailyGreenBlueThread = task.spawn(function()
                while dailyGreenBlueRunning do
                    pcall(function() RE:FireServer("DailyRewardsBuyItem", 25) end)
                    pcall(function() RE:FireServer("DailyRewardsBuyItem", 26) end)
                    task.wait(1)
                end
            end)
        else
            if dailyGreenBlueThread then task.cancel(dailyGreenBlueThread) end
        end
    end
})

EventTab:CreateToggle({
    Name = "Auto Buy Purple & Rainbow Fragment (27 & 28)",
    CurrentValue = eventSettings.autoDailyPurpleRainbow or false,
    Callback = function(v)
        dailyPurpleRainbowRunning = v
        eventSettings.autoDailyPurpleRainbow = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            dailyPurpleRainbowThread = task.spawn(function()
                while dailyPurpleRainbowRunning do
                    pcall(function() RE:FireServer("DailyRewardsBuyItem", 27) end)
                    pcall(function() RE:FireServer("DailyRewardsBuyItem", 28) end)
                    task.wait(1)
                end
            end)
        else
            if dailyPurpleRainbowThread then task.cancel(dailyPurpleRainbowThread) end
        end
    end
})

-- ======================================
-- UI - REBIRTH MACHINE (CRYSTAL ALTAR)
-- ======================================
EventTab:CreateSection("Rebirth Machine (Crystal Altar)")

EventTab:CreateLabel("Testing, Make sure to Lock all Valuable Pets before execute this")
EventTab:CreateLabel("Only uses 3 Secret pets from Crystal Ore Egg (same variant)")
EventTab:CreateLabel("Excluded: Ruby/Emerald/Sapphire Crystal Dragon, Crowned Jewel, Crystal Dementor, Crystal Koi")

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

if eventSettings.autoShop1 then
    shop1Running = true
    shop1Thread = task.spawn(function()
        while shop1Running do
            if isInStock(1) then
                pcall(function() RE:FireServer("BuyShopItem", "eggcomp-shop", 1, true) end)
                task.wait(0.1)
            else
                task.wait(10)
            end
        end
    end)
end

if eventSettings.autoShop2 then
    shop2Running = true
    shop2Thread = task.spawn(function()
        while shop2Running do
            if isInStock(2) then
                pcall(function() RE:FireServer("BuyShopItem", "eggcomp-shop", 2, true) end)
                task.wait(0.1)
            else
                task.wait(10)
            end
        end
    end)
end

if eventSettings.autoShop3 then
    shop3Running = true
    shop3Thread = task.spawn(function()
        while shop3Running do
            if isInStock(3) then
                pcall(function() RE:FireServer("BuyShopItem", "eggcomp-shop", 3, true) end)
                task.wait(0.1)
            else
                task.wait(10)
            end
        end
    end)
end

if eventSettings.autoShop4 then
    shop4Running = true
    shop4Thread = task.spawn(function()
        while shop4Running do
            local anyBought = false
            for i = 4, 6 do
                if isInStock(i) then
                    pcall(function() RE:FireServer("BuyShopItem", "eggcomp-shop", i, true) end)
                    anyBought = true
                    task.wait(0.1)
                end
            end
            if not anyBought then
                task.wait(10)
            end
        end
    end)
end

if eventSettings.autoShop5 then
    shop5Running = true
    shop5Thread = task.spawn(function()
        while shop5Running do
            if isInStock(7) then
                pcall(function() RE:FireServer("BuyShopItem", "eggcomp-shop", 7, true) end)
                task.wait(0.1)
            else
                task.wait(10)
            end
        end
    end)
end

if eventSettings.autoShop6 then
    shop6Running = true
    shop6Thread = task.spawn(function()
        while shop6Running do
            local anyBought = false
            for i = 8, 10 do
                if isInStock(i) then
                    pcall(function() RE:FireServer("BuyShopItem", "eggcomp-shop", i, true) end)
                    anyBought = true
                    task.wait(0.1)
                end
            end
            if not anyBought then
                task.wait(10)
            end
        end
    end)
end

if eventSettings.autoShop7 then
    shop7Running = true
    shop7Thread = task.spawn(function()
        while shop7Running do
            if isInStock(11) then
                pcall(function() RE:FireServer("BuyShopItem", "eggcomp-shop", 11, true) end)
                task.wait(0.1)
            else
                task.wait(10)
            end
        end
    end)
end

if eventSettings.autoShop8 then
    shop8Running = true
    shop8Thread = task.spawn(function()
        while shop8Running do
            if isInStock(12) then
                pcall(function() RE:FireServer("BuyShopItem", "eggcomp-shop", 12, true) end)
                task.wait(0.1)
            else
                task.wait(10)
            end
        end
    end)
end

if eventSettings.autoShop9 then
    shop9Running = true
    shop9Thread = task.spawn(function()
        while shop9Running do
            local anyBought = false
            for i = 13, 14 do
                if isInStock(i) then
                    pcall(function() RE:FireServer("BuyShopItem", "eggcomp-shop", i, true) end)
                    anyBought = true
                    task.wait(0.1)
                end
            end
            if not anyBought then
                task.wait(10)
            end
        end
    end)
end

if eventSettings.autoShop10 then
    shop10Running = true
    shop10Thread = task.spawn(function()
        while shop10Running do
            local anyBought = false
            for i = 15, 16 do
                if isInStock(i) then
                    pcall(function() RE:FireServer("BuyShopItem", "eggcomp-shop", i, true) end)
                    anyBought = true
                    task.wait(0.1)
                end
            end
            if not anyBought then
                task.wait(10)
            end
        end
    end)
end

if eventSettings.autoDailyShadowCrystal then
    dailyShadowCrystalRunning = true
    dailyShadowCrystalThread = task.spawn(function()
        while dailyShadowCrystalRunning do
            pcall(function() RE:FireServer("DailyRewardsBuyItem", 24) end)
            task.wait(1)
        end
    end)
end

if eventSettings.autoDailyEggElixir then
    dailyEggElixirRunning = true
    dailyEggElixirThread = task.spawn(function()
        while dailyEggElixirRunning do
            pcall(function() RE:FireServer("DailyRewardsBuyItem", 23) end)
            task.wait(1)
        end
    end)
end

if eventSettings.autoDailySecretElixir then
    dailySecretElixirRunning = true
    dailySecretElixirThread = task.spawn(function()
        while dailySecretElixirRunning do
            pcall(function() RE:FireServer("DailyRewardsBuyItem", 22) end)
            task.wait(1)
        end
    end)
end

if eventSettings.autoDailyGreenBlue then
    dailyGreenBlueRunning = true
    dailyGreenBlueThread = task.spawn(function()
        while dailyGreenBlueRunning do
            pcall(function() RE:FireServer("DailyRewardsBuyItem", 25) end)
            pcall(function() RE:FireServer("DailyRewardsBuyItem", 26) end)
            task.wait(1)
        end
    end)
end

if eventSettings.autoDailyPurpleRainbow then
    dailyPurpleRainbowRunning = true
    dailyPurpleRainbowThread = task.spawn(function()
        while dailyPurpleRainbowRunning do
            pcall(function() RE:FireServer("DailyRewardsBuyItem", 27) end)
            pcall(function() RE:FireServer("DailyRewardsBuyItem", 28) end)
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
