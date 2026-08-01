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

-- ======================================
-- NORMAL POTION SETTINGS
-- ======================================
local NORMAL_POTIONS = {"Lucky", "Speed", "Mythic", "Coins", "Tickets"}
local NORMAL_LEVELS = {1, 2, 3, 4, 5, 6, 7}

local normalOptions = {}
for _, name in ipairs(NORMAL_POTIONS) do for _, level in ipairs(NORMAL_LEVELS) do table.insert(normalOptions, name .. " " .. level) end end

local selectedNormal = "Lucky 1"
local normalAmount = 250
local normalRunning = false; local normalThread = nil

-- ======================================
-- SPECIAL POTION SETTINGS
-- ======================================
local SPECIAL_POTIONS = {"Infinity Elixir", "Ultra Infinity Elixir", "Egg Elixir", "Star Elixir", "Secret Elixir"}

local selectedSpecial = "Infinity Elixir"
local specialAmount = 250
local specialRunning = false; local specialThread = nil

-- ======================================
-- EVENT POTION SETTINGS
-- ======================================
local eventPotions = {}
local selectedEvent = ""
local eventAmount = 250
local eventRunning = false; local eventThread = nil

local function getEventPotions()
    local events = {}
    local normalSpecial = {Lucky=true, Speed=true, Mythic=true, Coins=true, Tickets=true, ["Infinity Elixir"]=true, ["Ultra Infinity Elixir"]=true, ["Egg Elixir"]=true, ["Star Elixir"]=true, ["Secret Elixir"]=true}
    local data = LocalData:Get()
    if data and data.Potions then
        for _, potion in pairs(data.Potions) do
            local name = potion.Name
            if not normalSpecial[name] and potion.Amount > 0 then
                if not table.find(events, name) then table.insert(events, name) end
            end
        end
    end
    if #events == 0 then events = {"Festive Elixir", "Carnival Elixir", "Heaven Elixir"} end
    table.sort(events)
    return events
end

eventPotions = getEventPotions()
selectedEvent = eventPotions[1] or ""

-- ======================================
-- UI - NORMAL POTION
-- ======================================
PotionTab:CreateSection("Normal Potion")
PotionTab:CreateDropdown({Name = "Select Potion", Options = normalOptions, CurrentOption = {selectedNormal}, Callback = function(v) selectedNormal = v[1] end})
PotionTab:CreateInput({Name = "Amount (Max 250)", CurrentValue = "250", PlaceholderText = "250", RemoveTextAfterFocusLost = false, Callback = function(v) local n = tonumber(v) if n then normalAmount = math.min(n, 250) end end})
PotionTab:CreateToggle({
    Name = "Auto Use Normal Potion", CurrentValue = false,
    Callback = function(v)
        normalRunning = v
        if v then
            getgenv().ActivityStatus.current = "Using " .. selectedNormal .. " x" .. normalAmount
            normalThread = task.spawn(function()
                while normalRunning do
                    local parts = {}; for part in string.gmatch(selectedNormal, "%S+") do table.insert(parts, part) end
                    local potionName = table.concat(parts, " ", 1, #parts - 1)
                    local level = tonumber(parts[#parts]) or 1
                    local data = LocalData:Get(); local actualAmount = normalAmount
                    if data and data.Potions then for _, potion in pairs(data.Potions) do if potion.Name == potionName and potion.Level == level then if potion.Amount < normalAmount then actualAmount = potion.Amount end break end end end
                    if actualAmount > 0 then pcall(function() RE:FireServer("UsePotion", potionName, level, actualAmount) end) end
                    task.wait(0.5)
                end
            end)
        else if normalThread then task.cancel(normalThread) end end
    end
})

-- ======================================
-- UI - SPECIAL POTION
-- ======================================
PotionTab:CreateSection("Special Potion")
PotionTab:CreateDropdown({Name = "Select Potion", Options = SPECIAL_POTIONS, CurrentOption = {selectedSpecial}, Callback = function(v) selectedSpecial = v[1] end})
PotionTab:CreateInput({Name = "Amount (Max 250)", CurrentValue = "250", PlaceholderText = "250", RemoveTextAfterFocusLost = false, Callback = function(v) local n = tonumber(v) if n then specialAmount = math.min(n, 250) end end})
PotionTab:CreateToggle({
    Name = "Auto Use Special Potion", CurrentValue = false,
    Callback = function(v)
        specialRunning = v
        if v then
            getgenv().ActivityStatus.current = "Using " .. selectedSpecial .. " x" .. specialAmount
            specialThread = task.spawn(function()
                while specialRunning do
                    local data = LocalData:Get(); local actualAmount = specialAmount
                    if data and data.Potions then for _, potion in pairs(data.Potions) do if potion.Name == selectedSpecial then if potion.Amount < specialAmount then actualAmount = potion.Amount end break end end end
                    if actualAmount > 0 then pcall(function() RE:FireServer("UsePotion", selectedSpecial, 1, actualAmount) end) end
                    task.wait(0.5)
                end
            end)
        else if specialThread then task.cancel(specialThread) end end
    end
})

-- ======================================
-- UI - EVENT POTION
-- ======================================
PotionTab:CreateSection("Event Potion")
if #eventPotions > 0 then
    PotionTab:CreateDropdown({Name = "Select Event Potion", Options = eventPotions, CurrentOption = {selectedEvent}, Callback = function(v) selectedEvent = v[1] end})
    PotionTab:CreateInput({Name = "Amount (Max 250)", CurrentValue = "250", PlaceholderText = "250", RemoveTextAfterFocusLost = false, Callback = function(v) local n = tonumber(v) if n then eventAmount = math.min(n, 250) end end})
    PotionTab:CreateButton({Name = "Re Scan Event Potions", Callback = function() eventPotions = getEventPotions() selectedEvent = eventPotions[1] or "" print("[Potions] Found " .. #eventPotions .. " event potions") end})
    PotionTab:CreateToggle({
        Name = "Auto Use Event Potion", CurrentValue = false,
        Callback = function(v)
            eventRunning = v
            if v then
                getgenv().ActivityStatus.current = "Using " .. selectedEvent .. " x" .. eventAmount
                eventThread = task.spawn(function()
                    while eventRunning do
                        local data = LocalData:Get(); local actualAmount = eventAmount; local potionLevel = 1
                        if data and data.Potions then for _, potion in pairs(data.Potions) do if potion.Name == selectedEvent then potionLevel = potion.Level if potion.Amount < eventAmount then actualAmount = potion.Amount end break end end end
                        if actualAmount > 0 then pcall(function() RE:FireServer("UsePotion", selectedEvent, potionLevel, actualAmount) end) end
                        task.wait(0.5)
                    end
                end)
            else if eventThread then task.cancel(eventThread) end end
        end
    })
else
    PotionTab:CreateLabel("No event potions detected")
    PotionTab:CreateButton({Name = "Re Scan Event Potions", Callback = function() eventPotions = getEventPotions() selectedEvent = eventPotions[1] or "" print("[Potions] Found " .. #eventPotions .. " event potions") end})
end

print("[Potions] Loaded!")
