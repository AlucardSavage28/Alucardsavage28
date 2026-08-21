-- ================================================
-- POTION TAB (FASTER + FIXED ACTIVITY WEBHOOK)
-- ================================================
repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local PotionTab = Window:CreateTab("Potions", nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)

local RE = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteEvent

-- ======================================
-- LOAD SAVED SETTINGS
-- ======================================
local settings = getgenv().HubSettings or {}
if not settings.potions then settings.potions = {} end
local potionSettings = settings.potions

-- ======================================
-- NORMAL POTION SETTINGS
-- ======================================
local NORMAL_POTIONS = {"Lucky", "Speed", "Mythic", "Coins", "Tickets"}
local NORMAL_LEVELS = {1, 2, 3, 4, 5, 6, 7}

local normalOptions = {}
for _, name in ipairs(NORMAL_POTIONS) do
    for _, level in ipairs(NORMAL_LEVELS) do
        table.insert(normalOptions, name .. " " .. level)
    end
end

local selectedNormal = potionSettings.normalSelected or "Lucky 1"
local normalAmount = potionSettings.normalAmount or 250
local normalRunning = false
local normalThread = nil

-- ======================================
-- SPECIAL POTION SETTINGS
-- ======================================
local SPECIAL_POTIONS = {"Infinity Elixir", "Ultra Infinity Elixir", "Egg Elixir", "Star Elixir", "Secret Elixir"}

local selectedSpecial = potionSettings.specialSelected or "Infinity Elixir"
local specialAmount = potionSettings.specialAmount or 250
local specialRunning = false
local specialThread = nil

-- ======================================
-- EVENT POTION SETTINGS
-- ======================================
local eventPotions = {}
local selectedEvent = potionSettings.eventSelected or ""
local eventAmount = potionSettings.eventAmount or 250
local eventRunning = false
local eventThread = nil

local function getEventPotions()
    local events = {}
    local normalSpecial = {Lucky=true, Speed=true, Mythic=true, Coins=true, Tickets=true, ["Infinity Elixir"]=true, ["Ultra Infinity Elixir"]=true, ["Egg Elixir"]=true, ["Star Elixir"]=true, ["Secret Elixir"]=true}
    local data = LocalData:Get()
    if data and data.Potions then
        for _, potion in pairs(data.Potions) do
            local name = potion.Name
            if not normalSpecial[name] and potion.Amount > 0 then
                if not table.find(events, name) then
                    table.insert(events, name)
                end
            end
        end
    end
    if #events == 0 then
        events = {"Festive Elixir", "Carnival Elixir", "Heaven Elixir"}
    end
    table.sort(events)
    return events
end

eventPotions = getEventPotions()
if selectedEvent == "" then selectedEvent = eventPotions[1] or "" end

-- ======================================
-- UI - NORMAL POTION
-- ======================================
PotionTab:CreateSection("Normal Potion")

PotionTab:CreateDropdown({
    Name = "Select Potion",
    Options = normalOptions,
    CurrentOption = {selectedNormal},
    Callback = function(v)
        selectedNormal = v[1]
        potionSettings.normalSelected = v[1]
        getgenv().HubSettings.potions = potionSettings
        saveHubSettings()
    end
})

PotionTab:CreateInput({
    Name = "Amount (Max 250)",
    CurrentValue = tostring(normalAmount),
    PlaceholderText = "250",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        local n = tonumber(v)
        if n then
            normalAmount = math.min(n, 250)
            potionSettings.normalAmount = normalAmount
            getgenv().HubSettings.potions = potionSettings
            saveHubSettings()
        end
    end
})

PotionTab:CreateToggle({
    Name = "Auto Use Normal Potion",
    CurrentValue = potionSettings.normalRunning or false,
    Callback = function(v)
        normalRunning = v
        potionSettings.normalRunning = v
        getgenv().HubSettings.potions = potionSettings
        saveHubSettings()
        if v then
            getgenv().ActivityStatus.current = "Start Auto use " .. selectedNormal
            getgenv().ActivityStatus.trigger = true
            
            normalThread = task.spawn(function()
                while normalRunning do
                    local parts = {}
                    for part in string.gmatch(selectedNormal, "%S+") do
                        table.insert(parts, part)
                    end
                    local potionName = table.concat(parts, " ", 1, #parts - 1)
                    local level = tonumber(parts[#parts]) or 1
                    
                    local data = LocalData:Get()
                    local actualAmount = normalAmount
                    if data and data.Potions then
                        for _, potion in pairs(data.Potions) do
                            if potion.Name == potionName and potion.Level == level then
                                if potion.Amount < normalAmount then
                                    actualAmount = potion.Amount
                                end
                                break
                            end
                        end
                    end
                    
                    if actualAmount > 0 then
                        pcall(function() RE:FireServer("UsePotion", potionName, level, actualAmount) end)
                    end
                    task.wait(0.1) -- FASTER (was 0.5)
                end
            end)
        else
            if normalThread then task.cancel(normalThread) end
            getgenv().ActivityStatus.current = "Stopped Auto use " .. selectedNormal
            getgenv().ActivityStatus.trigger = true
        end
    end
})

-- ======================================
-- UI - SPECIAL POTION
-- ======================================
PotionTab:CreateSection("Special Potion")

PotionTab:CreateDropdown({
    Name = "Select Potion",
    Options = SPECIAL_POTIONS,
    CurrentOption = {selectedSpecial},
    Callback = function(v)
        selectedSpecial = v[1]
        potionSettings.specialSelected = v[1]
        getgenv().HubSettings.potions = potionSettings
        saveHubSettings()
    end
})

PotionTab:CreateInput({
    Name = "Amount (Max 250)",
    CurrentValue = tostring(specialAmount),
    PlaceholderText = "250",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        local n = tonumber(v)
        if n then
            specialAmount = math.min(n, 250)
            potionSettings.specialAmount = specialAmount
            getgenv().HubSettings.potions = potionSettings
            saveHubSettings()
        end
    end
})

PotionTab:CreateToggle({
    Name = "Auto Use Special Potion",
    CurrentValue = potionSettings.specialRunning or false,
    Callback = function(v)
        specialRunning = v
        potionSettings.specialRunning = v
        getgenv().HubSettings.potions = potionSettings
        saveHubSettings()
        if v then
            getgenv().ActivityStatus.current = "Start Auto use " .. selectedSpecial
            getgenv().ActivityStatus.trigger = true
            
            specialThread = task.spawn(function()
                while specialRunning do
                    local data = LocalData:Get()
                    local actualAmount = specialAmount
                    if data and data.Potions then
                        for _, potion in pairs(data.Potions) do
                            if potion.Name == selectedSpecial then
                                if potion.Amount < specialAmount then
                                    actualAmount = potion.Amount
                                end
                                break
                            end
                        end
                    end
                    
                    if actualAmount > 0 then
                        pcall(function() RE:FireServer("UsePotion", selectedSpecial, 1, actualAmount) end)
                    end
                    task.wait(0.1) -- FASTER (was 0.5)
                end
            end)
        else
            if specialThread then task.cancel(specialThread) end
            getgenv().ActivityStatus.current = "Stopped Auto use " .. selectedSpecial
            getgenv().ActivityStatus.trigger = true
        end
    end
})

-- ======================================
-- UI - EVENT POTION
-- ======================================
PotionTab:CreateSection("Event Potion")

if #eventPotions > 0 then
    PotionTab:CreateDropdown({
        Name = "Select Event Potion",
        Options = eventPotions,
        CurrentOption = {selectedEvent},
        Callback = function(v)
            selectedEvent = v[1]
            potionSettings.eventSelected = v[1]
            getgenv().HubSettings.potions = potionSettings
            saveHubSettings()
        end
    })

    PotionTab:CreateInput({
        Name = "Amount (Max 250)",
        CurrentValue = tostring(eventAmount),
        PlaceholderText = "250",
        RemoveTextAfterFocusLost = false,
        Callback = function(v)
            local n = tonumber(v)
            if n then
                eventAmount = math.min(n, 250)
                potionSettings.eventAmount = eventAmount
                getgenv().HubSettings.potions = potionSettings
                saveHubSettings()
            end
        end
    })

    PotionTab:CreateButton({
        Name = "Re Scan Event Potions",
        Callback = function()
            eventPotions = getEventPotions()
            selectedEvent = eventPotions[1] or ""
            print("[Potions] Found " .. #eventPotions .. " event potions")
        end
    })

    PotionTab:CreateToggle({
        Name = "Auto Use Event Potion",
        CurrentValue = potionSettings.eventRunning or false,
        Callback = function(v)
            eventRunning = v
            potionSettings.eventRunning = v
            getgenv().HubSettings.potions = potionSettings
            saveHubSettings()
            if v then
                getgenv().ActivityStatus.current = "Start Auto use " .. selectedEvent
                getgenv().ActivityStatus.trigger = true
                
                eventThread = task.spawn(function()
                    while eventRunning do
                        local data = LocalData:Get()
                        local actualAmount = eventAmount
                        local potionLevel = 1
                        if data and data.Potions then
                            for _, potion in pairs(data.Potions) do
                                if potion.Name == selectedEvent then
                                    potionLevel = potion.Level
                                    if potion.Amount < eventAmount then
                                        actualAmount = potion.Amount
                                    end
                                    break
                                end
                            end
                        end
                        
                        if actualAmount > 0 then
                            pcall(function() RE:FireServer("UsePotion", selectedEvent, potionLevel, actualAmount) end)
                        end
                        task.wait(0.1) -- FASTER (was 0.5)
                    end
                end)
            else
                if eventThread then task.cancel(eventThread) end
                getgenv().ActivityStatus.current = "Stopped Auto use " .. selectedEvent
                getgenv().ActivityStatus.trigger = true
            end
        end
    })
else
    PotionTab:CreateLabel("No event potions detected")
    PotionTab:CreateButton({
        Name = "Re Scan Event Potions",
        Callback = function()
            eventPotions = getEventPotions()
            selectedEvent = eventPotions[1] or ""
            print("[Potions] Found " .. #eventPotions .. " event potions")
        end
    })
end

-- ======================================
-- AUTO-START SAVED TOGGLES
-- ======================================
if potionSettings.normalRunning then
    normalRunning = true
    getgenv().ActivityStatus.current = "Start Auto use " .. selectedNormal
    getgenv().ActivityStatus.trigger = true
    
    normalThread = task.spawn(function()
        while normalRunning do
            local parts = {}
            for part in string.gmatch(selectedNormal, "%S+") do
                table.insert(parts, part)
            end
            local potionName = table.concat(parts, " ", 1, #parts - 1)
            local level = tonumber(parts[#parts]) or 1
            
            local data = LocalData:Get()
            local actualAmount = normalAmount
            if data and data.Potions then
                for _, potion in pairs(data.Potions) do
                    if potion.Name == potionName and potion.Level == level then
                        if potion.Amount < normalAmount then actualAmount = potion.Amount end
                        break
                    end
                end
            end
            
            if actualAmount > 0 then
                pcall(function() RE:FireServer("UsePotion", potionName, level, actualAmount) end)
            end
            task.wait(0.1)
        end
    end)
end

if potionSettings.specialRunning then
    specialRunning = true
    getgenv().ActivityStatus.current = "Start Auto use " .. selectedSpecial
    getgenv().ActivityStatus.trigger = true
    
    specialThread = task.spawn(function()
        while specialRunning do
            local data = LocalData:Get()
            local actualAmount = specialAmount
            if data and data.Potions then
                for _, potion in pairs(data.Potions) do
                    if potion.Name == selectedSpecial then
                        if potion.Amount < specialAmount then actualAmount = potion.Amount end
                        break
                    end
                end
            end
            
            if actualAmount > 0 then
                pcall(function() RE:FireServer("UsePotion", selectedSpecial, 1, actualAmount) end)
            end
            task.wait(0.1)
        end
    end)
end

if potionSettings.eventRunning then
    eventRunning = true
    getgenv().ActivityStatus.current = "Start Auto use " .. selectedEvent
    getgenv().ActivityStatus.trigger = true
    
    eventThread = task.spawn(function()
        while eventRunning do
            local data = LocalData:Get()
            local actualAmount = eventAmount
            local potionLevel = 1
            if data and data.Potions then
                for _, potion in pairs(data.Potions) do
                    if potion.Name == selectedEvent then
                        potionLevel = potion.Level
                        if potion.Amount < eventAmount then actualAmount = potion.Amount end
                        break
                    end
                end
            end
            
            if actualAmount > 0 then
                pcall(function() RE:FireServer("UsePotion", selectedEvent, potionLevel, actualAmount) end)
            end
            task.wait(0.1)
        end
    end)
end

print("[Potions] Loaded!")
