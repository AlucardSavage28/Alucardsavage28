repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local ShrineTab = Window:CreateTab("Shrine", nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local RemoteFunction = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteFunction
local Remote = require(ReplicatedStorage.Shared.Framework.Network.Remote)
local RemoteEvent = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteEvent

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

local BUBBLE = {
    Level = 1,
    Type = "Potion",
    Name = shrineSettings.bubbleType or "Lucky",
    Amount = shrineSettings.bubbleAmount or 500
}
local DREAMER_AMOUNT = shrineSettings.dreamerAmount or 15
local permEgg = shrineSettings.permEgg or "Common Egg"
local permTargetBuff = shrineSettings.permBuff or "Luck"
local permAmount = shrineSettings.permAmount or 400

local PERM_EGGS = {
    "Common Egg", "Cyber Egg", "Nightmare Egg", "Neon Egg", "Atlantis Egg",
    "Lava Egg", "Icy Egg", "Rainbow Egg", "Mining Egg", "Vine Egg", "Classic Egg"
}
local PERM_BUFFS = {"Luck", "Secret", "Infinity", "Mythic", "Shiny"}

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

local function getPermShrineInfo()
    local info = {buff = "Unknown", time = "Unknown"}
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        local screenGui = playerGui:FindFirstChild("ScreenGui")
        if screenGui then
            local shrine = screenGui:FindFirstChild("PermanentShrine")
            if shrine then
                local buffName = shrine:FindFirstChild("Frame") and shrine.Frame:FindFirstChild("Content") and shrine.Frame.Content:FindFirstChild("Current") and shrine.Frame.Content.Current:FindFirstChild("Buff") and shrine.Frame.Content.Current.Buff:FindFirstChild("BuffName")
                local remaining = shrine:FindFirstChild("Frame") and shrine.Frame:FindFirstChild("Content") and shrine.Frame.Content:FindFirstChild("Current") and shrine.Frame.Content.Current:FindFirstChild("Remaining")
                if buffName then info.buff = buffName.Text end
                if remaining then info.time = remaining.Text end
            end
        end
    end
    return info
end

-- ======================================
-- SHRINE FUNCTIONS
-- ======================================
local function bubble()
    pcall(function() Remote:InvokeServer("DonateToShrine", BUBBLE) end)
end

local function dreamer()
    pcall(function() Remote:InvokeServer("DonateToDreamerShrine", DREAMER_AMOUNT) end)
end

-- ======================================
-- BUBBLE SHRINE
-- ======================================
ShrineTab:CreateSection("Bubble Shrine")

ShrineTab:CreateDropdown({
    Name = "Potion Type",
    CurrentOption = BUBBLE.Name,
    Options = {"Lucky", "Speed", "Coin", "Mythic"},
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
-- DREAMER SHRINE
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
-- PERM SHRINE
-- ======================================
ShrineTab:CreateSection("Perm Shrine")

local permInfoLabel = ShrineTab:CreateLabel("Buff: Unknown | Time: Unknown")
task.spawn(function()
    while true do
        task.wait(30)
        local info = getPermShrineInfo()
        pcall(function() permInfoLabel:SetText("Buff: " .. info.buff .. " | Time: " .. info.time) end)
    end
end)

ShrineTab:CreateDropdown({
    Name = "Egg",
    Options = PERM_EGGS,
    CurrentOption = {permEgg},
    Callback = function(v)
        permEgg = v
        shrineSettings.permEgg = v
        getgenv().HubSettings.shrine = shrineSettings
        saveHubSettings()
    end
})

ShrineTab:CreateDropdown({
    Name = "Target Buff",
    Options = PERM_BUFFS,
    CurrentOption = {permTargetBuff},
    Callback = function(v)
        permTargetBuff = v
        shrineSettings.permBuff = v
        getgenv().HubSettings.shrine = shrineSettings
        saveHubSettings()
    end
})

ShrineTab:CreateInput({
    Name = "Amount",
    CurrentValue = tostring(permAmount),
    PlaceholderText = "400",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        local n = tonumber(v)
        if n then
            permAmount = n
            shrineSettings.permAmount = n
            getgenv().HubSettings.shrine = shrineSettings
            saveHubSettings()
        end
    end
})

ShrineTab:CreateToggle({
    Name = "Auto Perm Shrine",
    CurrentValue = shrineSettings.autoPerm or false,
    Callback = function(v)
        permEnabled = v
        shrineSettings.autoPerm = v
        getgenv().HubSettings.shrine = shrineSettings
        saveHubSettings()
        if v then
            permThread = task.spawn(function()
                while permEnabled do
                    pcall(function() RemoteFunction:InvokeServer("DonateToPermanentShrine", "Lucky", 6, permAmount) end)
                    task.wait(1)
                    pcall(function() RemoteEvent:FireServer("ClaimPermanentShrineBuff", permEgg) end)
                    task.wait(1)
                    
                    getgenv().ActivityStatus.current = "Rerolling buff for " .. permEgg
                    getgenv().ActivityStatus.trigger = true
                    
                    local info = getPermShrineInfo()
                    while permEnabled and not info.buff:lower():find(permTargetBuff:lower()) do
                        pcall(function() RemoteEvent:FireServer("RerollPermanentShrine") end)
                        task.wait(2)
                        info = getPermShrineInfo()
                    end
                    
                    if permEnabled then
                        getgenv().ActivityStatus.current = "Rerolling " .. info.buff .. " for " .. permEgg .. " done!"
                        getgenv().ActivityStatus.trigger = true
                        print("[Shrine] Perm buff set to " .. info.buff)
                        task.wait(43200)
                    end
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

if shrineSettings.autoPerm then
    permEnabled = true
    permThread = task.spawn(function()
        while permEnabled do
            pcall(function() RemoteFunction:InvokeServer("DonateToPermanentShrine", "Lucky", 6, permAmount) end)
            task.wait(1)
            pcall(function() RemoteEvent:FireServer("ClaimPermanentShrineBuff", permEgg) end)
            task.wait(1)
            
            getgenv().ActivityStatus.current = "Rerolling buff for " .. permEgg
            getgenv().ActivityStatus.trigger = true
            
            local info = getPermShrineInfo()
            while permEnabled and not info.buff:lower():find(permTargetBuff:lower()) do
                pcall(function() RemoteEvent:FireServer("RerollPermanentShrine") end)
                task.wait(2)
                info = getPermShrineInfo()
            end
            
            if permEnabled then
                getgenv().ActivityStatus.current = "Rerolling " .. info.buff .. " for " .. permEgg .. " done!"
                getgenv().ActivityStatus.trigger = true
                print("[Shrine] Perm buff set to " .. info.buff)
                task.wait(43200)
            end
        end
    end)
end

print("[Shrine] Loaded!")
