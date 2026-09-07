-- ================================================
-- SHRINE TAB (DELTA - FIXED PERM SHRINE - DROPDOWN FIX)
-- ================================================
repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local ShrineTab = Window:CreateTab("Shrine", nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local RemoteFunction = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteFunction
local Remote = require(ReplicatedStorage.Shared.Framework.Network.Remote)
local RemoteEvent = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteEvent
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)

-- ======================================
-- LOAD SAVED SETTINGS
-- ======================================
local settings = getgenv().HubSettings or {}
if not settings.shrine then settings.shrine = {} end
local shrineSettings = settings.shrine

-- ======================================
-- SETTINGS
-- ======================================
local bubbleEnabled = false
local dreamerEnabled = false
local permEnabled = false

local bubbleThread = nil
local dreamerThread = nil
local permThread = nil

-- Potion options (Levels 1-3 for Bubble Shrine)
local POTION_TYPES = {"Lucky", "Speed", "Coins", "Mythic", "Tickets"}
local POTION_LEVELS = {1, 2, 3}

local potionOptions = {}
for _, name in ipairs(POTION_TYPES) do
    for _, level in ipairs(POTION_LEVELS) do
        table.insert(potionOptions, name .. " " .. level)
    end
end

local BUBBLE = {
    Level = 1,
    Type = "Potion",
    Name = shrineSettings.bubbleType or "Lucky 1",
    Amount = shrineSettings.bubbleAmount or 500
}

local DREAMER_AMOUNT = shrineSettings.dreamerAmount or 15

-- PERM SHRINE SETTINGS (NEW)
local permSelectedPotion = shrineSettings.permPotion or "Lucky 6"
local permSelectedEgg = shrineSettings.permEgg or "Cyber Egg"
local permTargetBuff = shrineSettings.permTargetBuff or "Luck"
local permRerollEnabled = shrineSettings.permReroll or false

local permRerollNotified = false

-- ======================================
-- TIMER CHECK FUNCTIONS
-- ======================================
local function getBuffTime(buffName)
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        local screenGui = playerGui:FindFirstChild("ScreenGui")
        if screenGui then
            local buffs = screenGui:FindFirstChild("Buffs")
            if buffs then
                for _, buff in ipairs(buffs:GetChildren()) do
                    if buff.Name == buffName then
                        local button = buff:FindFirstChild("Button")
                        if button then
                            local label = button:FindFirstChild("Label")
                            if label and label.Text ~= "" then return label.Text end
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function isBuffExpired(buffName)
    local time = getBuffTime(buffName)
    if not time then return true end
    if time == "0:00:00" or time == "0s" then return true end
    return false
end

-- ======================================
-- PERM SHRINE FUNCTIONS (NEW)
-- ======================================
local function getPermShrineData()
    local data = LocalData:Get()
    if data and data.PermanentShrine then
        return data.PermanentShrine
    end
    return nil
end

local function getPermShrineRemaining()
    local shrine = getPermShrineData()
    if shrine and shrine.StartTime and shrine.StartTime > 0 then
        local currentTime = os.time()
        local elapsed = currentTime - shrine.StartTime
        local totalDuration = 12 * 3600
        local remaining = totalDuration - elapsed
        return math.max(0, remaining)
    end
    return 0
end

local function donatePermShrine(potionName)
    local parts = {}
    for part in string.gmatch(potionName, "%S+") do
        table.insert(parts, part)
    end
    local name = table.concat(parts, " ", 1, #parts - 1)
    local level = tonumber(parts[#parts]) or 6
    
    local data = LocalData:Get()
    local currentXP = data and data.PermanentShrine and data.PermanentShrine.XPOffered or 0
    local neededXP = 1000000 - currentXP
    
    if neededXP <= 0 then return true end
    
    local xpPerPotion = 2500
    local amountNeeded = math.ceil(neededXP / xpPerPotion)
    
    if data and data.Potions then
        for _, potion in pairs(data.Potions) do
            if potion.Name == name and potion.Level == level then
                if potion.Amount < amountNeeded then
                    amountNeeded = potion.Amount
                end
                break
            end
        end
    end
    
    if amountNeeded > 0 then
        pcall(function()
            RemoteFunction:InvokeServer("DonateToPermanentShrine", name, level, amountNeeded)
        end)
        task.wait(1)
    end
    
    data = LocalData:Get()
    local newXP = data and data.PermanentShrine and data.PermanentShrine.XPOffered or 0
    return newXP >= 1000000
end

local function claimPermShrineBuff(eggName)
    pcall(function()
        RemoteEvent:FireServer("ClaimPermanentShrineBuff", eggName)
    end)
end

local function rerollPermShrine()
    pcall(function()
        RemoteEvent:FireServer("RerollPermanentShrine")
    end)
end

local function getPermShrineBuff()
    local shrine = getPermShrineData()
    if shrine then
        return shrine.Buff or "Unknown"
    end
    return "Unknown"
end

-- ======================================
-- SHRINE FUNCTIONS (OLD)
-- ======================================
local function bubble()
    local parts = {}
    for part in string.gmatch(BUBBLE.Name, "%S+") do
        table.insert(parts, part)
    end
    local potionName = table.concat(parts, " ", 1, #parts - 1)
    local level = tonumber(parts[#parts]) or 1
    
    BUBBLE.Level = level
    BUBBLE.Name = potionName
    
    pcall(function() Remote:InvokeServer("DonateToShrine", BUBBLE) end)
end

local function dreamer()
    pcall(function() Remote:InvokeServer("DonateToDreamerShrine", DREAMER_AMOUNT) end)
end

-- ======================================
-- BUBBLE SHRINE (UNCHANGED)
-- ======================================
ShrineTab:CreateSection("Bubble Shrine")

ShrineTab:CreateDropdown({
    Name = "Potion Type (Level 1-3)",
    CurrentOption = {BUBBLE.Name},
    Options = potionOptions,
    Callback = function(v)
        BUBBLE.Name = v
        shrineSettings.bubbleType = v
        getgenv().HubSettings.shrine = shrineSettings
        saveHubSettings()
    end
})

ShrineTab:CreateInput({
    Name = "Amount",
    CurrentValue = tostring(BUBBLE.Amount),
    PlaceholderText = "500",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        local n = tonumber(v)
        if n then
            BUBBLE.Amount = n
            shrineSettings.bubbleAmount = n
            getgenv().HubSettings.shrine = shrineSettings
            saveHubSettings()
        end
    end
})

ShrineTab:CreateToggle({
    Name = "Auto Bubble",
    CurrentValue = shrineSettings.autoBubble or false,
    Callback = function(v)
        bubbleEnabled = v
        shrineSettings.autoBubble = v
        getgenv().HubSettings.shrine = shrineSettings
        saveHubSettings()
        if v then
            getgenv().ActivityStatus.current = "Bubble Shrine Activated"
            getgenv().ActivityStatus.trigger = true
            bubble()
            bubbleThread = task.spawn(function()
                while bubbleEnabled do
                    task.wait(60)
                    if isBuffExpired("ShrineBlessing") then
                        getgenv().ActivityStatus.current = "Bubble Shrine Activated"
                        getgenv().ActivityStatus.trigger = true
                        bubble()
                    end
                end
            end)
        else
            if bubbleThread then task.cancel(bubbleThread); bubbleThread = nil end
        end
    end
})

-- ======================================
-- DREAMER SHRINE (UNCHANGED)
-- ======================================
ShrineTab:CreateSection("Dreamer Shrine")

ShrineTab:CreateInput({
    Name = "Amount",
    CurrentValue = tostring(DREAMER_AMOUNT),
    PlaceholderText = "15",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        local n = tonumber(v)
        if n then
            DREAMER_AMOUNT = n
            shrineSettings.dreamerAmount = n
            getgenv().HubSettings.shrine = shrineSettings
            saveHubSettings()
        end
    end
})

ShrineTab:CreateToggle({
    Name = "Auto Dreamer",
    CurrentValue = shrineSettings.autoDreamer or false,
    Callback = function(v)
        dreamerEnabled = v
        shrineSettings.autoDreamer = v
        getgenv().HubSettings.shrine = shrineSettings
        saveHubSettings()
        if v then
            getgenv().ActivityStatus.current = "Dreamer Shrine Activated"
            getgenv().ActivityStatus.trigger = true
            dreamer()
            dreamerThread = task.spawn(function()
                while dreamerEnabled do
                    task.wait(60)
                    if isBuffExpired("DreamerBlessing") then
                        getgenv().ActivityStatus.current = "Dreamer Shrine Activated"
                        getgenv().ActivityStatus.trigger = true
                        dreamer()
                    end
                end
            end)
        else
            if dreamerThread then task.cancel(dreamerThread); dreamerThread = nil end
        end
    end
})

-- ======================================
-- PERM SHRINE (UPDATED - FIXED DROPDOWNS)
-- ======================================
ShrineTab:CreateSection("Perm Shrine (Fixed)")

local permInfoLabel = ShrineTab:CreateLabel("Buff: None | Egg: None | XP: 0/1M")

task.spawn(function()
    while true do
        task.wait(10)
        local data = LocalData:Get()
        if data and data.PermanentShrine then
            local shrine = data.PermanentShrine
            local buff = shrine.Buff or "None"
            local egg = shrine.Egg or "None"
            local xp = shrine.XPOffered or 0
            local remaining = getPermShrineRemaining()
            
            local timeText = ""
            if remaining > 0 then
                local hours = math.floor(remaining / 3600)
                local minutes = math.floor((remaining % 3600) / 60)
                timeText = " | " .. hours .. "h " .. minutes .. "m"
            end
            
            pcall(function() 
                permInfoLabel:SetText("Buff: " .. buff .. " | Egg: " .. egg .. " | XP: " .. xp .. "/1M" .. timeText) 
            end)
        end
    end
end)

ShrineTab:CreateDropdown({
    Name = "Donate Potion (Level 6 Only)",
    Options = {"Lucky 6", "Speed 6", "Coins 6", "Mythic 6", "Tickets 6"},
    CurrentOption = permSelectedPotion,
    Callback = function(v)
        permSelectedPotion = v
        shrineSettings.permPotion = v
        getgenv().HubSettings.shrine = shrineSettings
        saveHubSettings()
    end
})

ShrineTab:CreateDropdown({
    Name = "Egg",
    Options = {"Common Egg", "Cyber Egg", "Nightmare Egg", "Neon Egg", "Atlantis Egg", "Lava Egg", "Icy Egg", "Rainbow Egg", "Mining Egg", "Vine Egg", "Classic Egg"},
    CurrentOption = permSelectedEgg,
    Callback = function(v)
        permSelectedEgg = v
        shrineSettings.permEgg = v
        getgenv().HubSettings.shrine = shrineSettings
        saveHubSettings()
    end
})

ShrineTab:CreateDropdown({
    Name = "Target Buff",
    Options = {"Luck", "Secret", "Infinity", "Mythic", "Shiny"},
    CurrentOption = permTargetBuff,
    Callback = function(v)
        permTargetBuff = v
        shrineSettings.permTargetBuff = v
        getgenv().HubSettings.shrine = shrineSettings
        saveHubSettings()
    end
})

ShrineTab:CreateToggle({
    Name = "Reroll Until Target Buff",
    CurrentValue = permRerollEnabled,
    Callback = function(v)
        permRerollEnabled = v
        shrineSettings.permReroll = v
        getgenv().HubSettings.shrine = shrineSettings
        saveHubSettings()
        if not v then
            permRerollNotified = false
        end
    end
})

ShrineTab:CreateToggle({
    Name = "Auto Perm Shrine",
    CurrentValue = shrineSettings.autoPermShrine or false,
    Callback = function(v)
        permEnabled = v
        shrineSettings.autoPermShrine = v
        getgenv().HubSettings.shrine = shrineSettings
        saveHubSettings()
        
        if v then
            permRerollNotified = false
            
            permThread = task.spawn(function()
                while permEnabled do
                    local data = LocalData:Get()
                    local shrine = data and data.PermanentShrine
                    
                    if not shrine then
                        task.wait(5)
                        continue
                    end
                    
                    local xp = shrine.XPOffered or 0
                    local remaining = getPermShrineRemaining()
                    
                    if xp < 1000000 and remaining <= 0 then
                        getgenv().ActivityStatus.current = "Donating " .. permSelectedPotion .. " to Perm Shrine"
                        getgenv().ActivityStatus.trigger = true
                        
                        local success = donatePermShrine(permSelectedPotion)
                        
                        if success then
                            getgenv().ActivityStatus.current = "Claiming Perm Shrine buff for " .. permSelectedEgg
                            getgenv().ActivityStatus.trigger = true
                            
                            claimPermShrineBuff(permSelectedEgg)
                            task.wait(2)
                        end
                    end
                    
                    if permRerollEnabled and remaining > 0 then
                        local currentBuff = getPermShrineBuff()
                        
                        if currentBuff ~= permTargetBuff then
                            getgenv().ActivityStatus.current = "Rerolling Perm Shrine for " .. permTargetBuff .. " (current: " .. currentBuff .. ")"
                            getgenv().ActivityStatus.trigger = true
                            
                            rerollPermShrine()
                            task.wait(3)
                            
                            local newBuff = getPermShrineBuff()
                            local newRemaining = getPermShrineRemaining()
                            
                            if newRemaining <= 0 then
                                if not permRerollNotified then
                                    permRerollNotified = true
                                    
                                    local discordID = settings.activity and settings.activity.userId or ""
                                    local pingMsg = ""
                                    if discordID ~= "" then
                                        pingMsg = "<@" .. discordID .. "> "
                                    end
                                    
                                    getgenv().ActivityStatus.current = pingMsg .. "Perm Shrine ran out of rerolls! Current buff: " .. newBuff
                                    getgenv().ActivityStatus.trigger = true
                                end
                            end
                        else
                            getgenv().ActivityStatus.current = "Perm Shrine got target buff: " .. currentBuff .. "!"
                            getgenv().ActivityStatus.trigger = true
                            
                            task.wait(getPermShrineRemaining() + 5)
                            permRerollNotified = false
                        end
                    end
                    
                    task.wait(5)
                end
            end)
        else
            if permThread then task.cancel(permThread) end
        end
    end
})

-- ======================================
-- AUTO-START SAVED TOGGLES
-- ======================================
if shrineSettings.autoBubble then
    bubbleEnabled = true
    getgenv().ActivityStatus.current = "Bubble Shrine Activated"
    getgenv().ActivityStatus.trigger = true
    bubble()
    bubbleThread = task.spawn(function()
        while bubbleEnabled do
            task.wait(60)
            if isBuffExpired("ShrineBlessing") then
                getgenv().ActivityStatus.current = "Bubble Shrine Activated"
                getgenv().ActivityStatus.trigger = true
                bubble()
            end
        end
    end)
end

if shrineSettings.autoDreamer then
    dreamerEnabled = true
    getgenv().ActivityStatus.current = "Dreamer Shrine Activated"
    getgenv().ActivityStatus.trigger = true
    dreamer()
    dreamerThread = task.spawn(function()
        while dreamerEnabled do
            task.wait(60)
            if isBuffExpired("DreamerBlessing") then
                getgenv().ActivityStatus.current = "Dreamer Shrine Activated"
                getgenv().ActivityStatus.trigger = true
                dreamer()
            end
        end
    end)
end

print("[Shrine] Loaded! - Perm Shrine Fixed v2")
