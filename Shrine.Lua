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

local function getPermShrineBuff()
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        local screenGui = playerGui:FindFirstChild("ScreenGui")
        if screenGui then
            local shrine = screenGui:FindFirstChild("PermanentShrine")
            if shrine then
                local buffName = shrine:FindFirstChild("Frame") and shrine.Frame:FindFirstChild("Content") and shrine.Frame.Content:FindFirstChild("Current") and shrine.Frame.Content.Current:FindFirstChild("Buff") and shrine.Frame.Content.Current.Buff:FindFirstChild("BuffName")
                if buffName then
                    return buffName.Text
                end
            end
        end
    end
    return "Unknown"
end

local function getPermShrineTime()
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        local screenGui = playerGui:FindFirstChild("ScreenGui")
        if screenGui then
            local shrine = screenGui:FindFirstChild("PermanentShrine")
            if shrine then
                local remaining = shrine:FindFirstChild("Frame") and shrine.Frame:FindFirstChild("Content") and shrine.Frame.Content:FindFirstChild("Current") and shrine.Frame.Content.Current:FindFirstChild("Remaining")
                if remaining then
                    return remaining.Text
                end
            end
        end
    end
    return "Unknown"
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

local function donatePermShrine()
    -- Click Lucky/6 potion in inventory
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        local screenGui = playerGui:FindFirstChild("ScreenGui")
        if screenGui then
            local shrine = screenGui:FindFirstChild("PermanentShrine")
            if shrine then
                local items = shrine:FindFirstChild("Frame") and shrine.Frame:FindFirstChild("Content") and shrine.Frame.Content:FindFirstChild("Donate") and shrine.Frame.Content.Donate:FindFirstChild("Inventory") and shrine.Frame.Content.Donate.Inventory:FindFirstChild("Main") and shrine.Frame.Content.Donate.Inventory.Main:FindFirstChild("Items") and shrine.Frame.Content.Donate.Inventory.Main.Items:FindFirstChild("List")
                if items then
                    local luckyItem = items:FindFirstChild("Lucky/6")
                    if luckyItem then
                        local itemFrame = luckyItem:FindFirstChild("ItemFrame")
                        if itemFrame then
                            local btn = itemFrame:FindFirstChild("Button")
                            if btn then
                                firesignal(btn.Activated)
                                task.wait(0.3)
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Fire remote as backup
    pcall(function() RemoteFunction:InvokeServer("DonateToPermanentShrine", "Lucky", 6, permAmount) end)
end

local function choosePermEgg()
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        local screenGui = playerGui:FindFirstChild("ScreenGui")
        if screenGui then
            local shrine = screenGui:FindFirstChild("PermanentShrine")
            if shrine then
                -- Click Choose Egg button
                local chooseBtn = shrine:FindFirstChild("Frame") and shrine.Frame:FindFirstChild("Content") and shrine.Frame.Content:FindFirstChild("Donate") and shrine.Frame.Content.Donate:FindFirstChild("Inventory") and shrine.Frame.Content.Donate.Inventory:FindFirstChild("Main") and shrine.Frame.Content.Donate.Inventory.Main:FindFirstChild("Overlay") and shrine.Frame.Content.Donate.Inventory.Main.Overlay:FindFirstChild("Choose")
                if chooseBtn then
                    local btn = chooseBtn:FindFirstChild("Button")
                    if btn then
                        firesignal(btn.Activated)
                        task.wait(0.3)
                    end
                end
                
                -- Click the selected egg
                local eggList = shrine:FindFirstChild("Frame") and shrine.Frame:FindFirstChild("Content") and shrine.Frame.Content:FindFirstChild("Donate") and shrine.Frame.Content.Donate:FindFirstChild("Eggs") and shrine.Frame.Content.Donate.Eggs:FindFirstChild("List")
                if eggList then
                    local targetEgg = eggList:FindFirstChild(permEgg)
                    if targetEgg then
                        local eggBtn = targetEgg:FindFirstChild("Button")
                        if eggBtn then
                            firesignal(eggBtn.Activated)
                            task.wait(0.3)
                        end
                    end
                end
            end
        end
    end
    
    -- Fire remote as backup
    pcall(function() RemoteEvent:FireServer("ClaimPermanentShrineBuff", permEgg) end)
end

local function rerollPermShrine()
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        local screenGui = playerGui:FindFirstChild("ScreenGui")
        if screenGui then
            local shrine = screenGui:FindFirstChild("PermanentShrine")
            if shrine then
                local rerollHolder = shrine:FindFirstChild("Frame") and shrine.Frame:FindFirstChild("Content") and shrine.Frame.Content:FindFirstChild("Current") and shrine.Frame.Content.Current:FindFirstChild("RerollHolder")
                if rerollHolder then
                    local reroll = rerollHolder:FindFirstChild("Reroll")
                    if reroll then
                        local btn = reroll:FindFirstChild("Button")
                        if btn and btn.Visible then
                            firesignal(btn.Activated)
                            return true
                        end
                    end
                end
            end
        end
    end
    
    -- Fire remote as backup
    pcall(function() RemoteEvent:FireServer("RerollPermanentShrine") end)
    return true
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
        local buff = getPermShrineBuff()
        local time = getPermShrineTime()
        pcall(function() permInfoLabel:SetText("Buff: " .. buff .. " | Time: " .. time) end)
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
                    -- Step 1: Donate
                    getgenv().ActivityStatus.current = "Donating Lucky 6 x" .. permAmount .. " to Perm Shrine"
                    getgenv().ActivityStatus.trigger = true
                    donatePermShrine()
                    task.wait(1)
                    
                    -- Step 2: Choose egg
                    getgenv().ActivityStatus.current = "Claiming Perm Shrine buff for " .. permEgg
                    getgenv().ActivityStatus.trigger = true
                    choosePermEgg()
                    task.wait(1)
                    
                    -- Step 3: Check buff and reroll if needed
                    local currentBuff = getPermShrineBuff()
                    local rerolls = 0
                    
                    if currentBuff:lower():find(permTargetBuff:lower()) then
                        getgenv().ActivityStatus.current = "Perm Shrine: Got " .. currentBuff .. " (no rerolls needed)"
                        getgenv().ActivityStatus.trigger = true
                        print("[Shrine] Perm buff already correct: " .. currentBuff)
                    else
                        getgenv().ActivityStatus.current = "Rerolling Perm Shrine for " .. permTargetBuff .. " buff on " .. permEgg
                        getgenv().ActivityStatus.trigger = true
                        
                        while permEnabled and not currentBuff:lower():find(permTargetBuff:lower()) do
                            if rerollPermShrine() then
                                rerolls = rerolls + 1
                                task.wait(2)
                                currentBuff = getPermShrineBuff()
                            else
                                task.wait(2)
                            end
                        end
                        
                        if permEnabled then
                            getgenv().ActivityStatus.current = "Perm Shrine done! " .. currentBuff .. " (" .. rerolls .. " rerolls)"
                            getgenv().ActivityStatus.trigger = true
                            print("[Shrine] Perm buff set to " .. currentBuff .. " after " .. rerolls .. " rerolls")
                        end
                    end
                    
                    if permEnabled then
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
            getgenv().ActivityStatus.current = "Donating Lucky 6 x" .. permAmount .. " to Perm Shrine"
            getgenv().ActivityStatus.trigger = true
            donatePermShrine()
            task.wait(1)
            
            getgenv().ActivityStatus.current = "Claiming Perm Shrine buff for " .. permEgg
            getgenv().ActivityStatus.trigger = true
            choosePermEgg()
            task.wait(1)
            
            local currentBuff = getPermShrineBuff()
            local rerolls = 0
            
            if currentBuff:lower():find(permTargetBuff:lower()) then
                getgenv().ActivityStatus.current = "Perm Shrine: Got " .. currentBuff .. " (no rerolls needed)"
                getgenv().ActivityStatus.trigger = true
                print("[Shrine] Perm buff already correct: " .. currentBuff)
            else
                getgenv().ActivityStatus.current = "Rerolling Perm Shrine for " .. permTargetBuff .. " buff on " .. permEgg
                getgenv().ActivityStatus.trigger = true
                
                while permEnabled and not currentBuff:lower():find(permTargetBuff:lower()) do
                    if rerollPermShrine() then
                        rerolls = rerolls + 1
                        task.wait(2)
                        currentBuff = getPermShrineBuff()
                    else
                        task.wait(2)
                    end
                end
                
                if permEnabled then
                    getgenv().ActivityStatus.current = "Perm Shrine done! " .. currentBuff .. " (" .. rerolls .. " rerolls)"
                    getgenv().ActivityStatus.trigger = true
                    print("[Shrine] Perm buff set to " .. currentBuff .. " after " .. rerolls .. " rerolls")
                end
            end
            
            if permEnabled then
                task.wait(43200)
            end
        end
    end)
end

print("[Shrine] Loaded!")
