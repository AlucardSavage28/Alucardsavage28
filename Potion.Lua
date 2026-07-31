-- ================================================
-- POTION TAB
-- ================================================
repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local PotionTab = Window:CreateTab("Potions", nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)

local RE = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteEvent

-- Load heavy module in background
local Potions = nil
task.spawn(function()
    Potions = require(ReplicatedStorage.Shared.Data.Potions)
end)

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

local selectedNormal = "Lucky 1"
local normalAmount = 250
local normalRunning = false
local normalThread = nil

-- ======================================
-- SPECIAL POTION SETTINGS
-- ======================================
local SPECIAL_POTIONS = {"Infinity Elixir", "Ultra Infinity Elixir", "Egg Elixir", "Star Elixir", "Secret Elixir"}

local selectedSpecial = "Infinity Elixir"
local specialAmount = 250
local specialRunning = false
local specialThread = nil

-- ======================================
-- EVENT POTION SETTINGS
-- ======================================
local eventPotions = {}
local selectedEvent = ""
local eventAmount = 250
local eventRunning = false
local eventThread = nil

local function getEventPotions()
    local events = {}
    local data = LocalData:Get()
    if data and data.Powerups then
        for name, amount in pairs(data.Powerups) do
            if name:lower():find("elixir") or name:lower():find("potion") then
                local isNormalOrSpecial = false
                for _, n in ipairs(NORMAL_POTIONS) do
                    if name == n then isNormalOrSpecial = true; break end
                end
                for _, s in ipairs(SPECIAL_POTIONS) do
                    if name == s then isNormalOrSpecial = true; break end
                end
                if not isNormalOrSpecial and name ~= "Lucky" and name ~= "Speed" and name ~= "Mythic" and name ~= "Coins" and name ~= "Tickets" then
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
selectedEvent = eventPotions[1] or ""

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
    end
})

PotionTab:CreateInput({
    Name = "Amount (Max 250)",
    CurrentValue = "250",
    PlaceholderText = "250",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        local n = tonumber(v)
        if n then normalAmount = math.min(n, 250) end
    end
})

PotionTab:CreateToggle({
    Name = "Auto Use Normal Potion",
    CurrentValue = false,
    Callback = function(v)
        normalRunning = v
        if v then
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
                    if data and data.Powerups then
                        local owned = data.Powerups[potionName] or 0
                        if owned < normalAmount then
                            actualAmount = owned
                        end
                    end
                    
                    if actualAmount > 0 then
                        pcall(function() RE:FireServer("UsePotion", potionName, level, actualAmount) end)
                    end
                    task.wait(0.5)
                end
            end)
        else
            if normalThread then task.cancel(normalThread) end
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
    end
})

PotionTab:CreateInput({
    Name = "Amount (Max 250)",
    CurrentValue = "250",
    PlaceholderText = "250",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        local n = tonumber(v)
        if n then specialAmount = math.min(n, 250) end
    end
})

PotionTab:CreateToggle({
    Name = "Auto Use Special Potion",
    CurrentValue = false,
    Callback = function(v)
        specialRunning = v
        if v then
            specialThread = task.spawn(function()
                while specialRunning do
                    local data = LocalData:Get()
                    local actualAmount = specialAmount
                    if data and data.Powerups then
                        local owned = data.Powerups[selectedSpecial] or 0
                        if owned < specialAmount then
                            actualAmount = owned
                        end
                    end
                    
                    if actualAmount > 0 then
                        pcall(function() RE:FireServer("UsePotion", selectedSpecial, 1, actualAmount) end)
                    end
                    task.wait(0.5)
                end
            end)
        else
            if specialThread then task.cancel(specialThread) end
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
        end
    })

    PotionTab:CreateInput({
        Name = "Amount (Max 250)",
        CurrentValue = "250",
        PlaceholderText = "250",
        RemoveTextAfterFocusLost = false,
        Callback = function(v)
            local n = tonumber(v)
            if n then eventAmount = math.min(n, 250) end
        end
    })

    PotionTab:CreateToggle({
        Name = "Auto Use Event Potion",
        CurrentValue = false,
        Callback = function(v)
            eventRunning = v
            if v then
                eventThread = task.spawn(function()
                    while eventRunning do
                        local data = LocalData:Get()
                        local actualAmount = eventAmount
                        if data and data.Powerups then
                            local owned = data.Powerups[selectedEvent] or 0
                            if owned < eventAmount then
                                actualAmount = owned
                            end
                        end
                        
                        local level = 1
                        if Potions then
                            local potionData = Potions[selectedEvent]
                            if potionData and potionData.Levels then
                                level = #potionData.Levels
                            end
                        end
                        
                        if actualAmount > 0 then
                            pcall(function() RE:FireServer("UsePotion", selectedEvent, level, actualAmount) end)
                        end
                        task.wait(0.5)
                    end
                end)
            else
                if eventThread then task.cancel(eventThread) end
            end
        end
    })
else
    PotionTab:CreateLabel("No event potions detected in inventory")
end

print("[Potions] Loaded!")
