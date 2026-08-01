-- ================================================
-- SHRINE TAB
-- ================================================
repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local ShrineTab = Window:CreateTab("Shrine", nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local Remote; local RemoteEvent; local RemoteFunc
pcall(function() Remote = require(ReplicatedStorage.Shared.Framework.Network.Remote) end)
pcall(function() RemoteEvent = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteEvent end)
pcall(function() RemoteFunc = require(ReplicatedStorage.Shared.Framework.Network.Remote) end)

-- ======================================
-- SETTINGS
-- ======================================
local bubbleEnabled = false; local dreamerEnabled = false; local permEnabled = false
local bubbleThread = nil; local dreamerThread = nil; local permThread = nil
local BUBBLE = {Level = 1, Type = "Potion", Name = "Lucky", Amount = 500}
local DREAMER_AMOUNT = 15
local permEgg = "Common Egg"; local permTargetBuff = "Luck"; local permAmount = 400
local PERM_EGGS = {"Common Egg", "Cyber Egg", "Nightmare Egg", "Neon Egg", "Atlantis Egg", "Lava Egg", "Icy Egg", "Rainbow Egg", "Mining Egg", "Vine Egg", "Classic Egg"}
local PERM_BUFFS = {"Luck", "Secret", "Infinity", "Mythic", "Shiny"}

-- ======================================
-- TIMER FUNCTIONS
-- ======================================
local function getBuffTime(buffName)
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then local screenGui = playerGui:FindFirstChild("ScreenGui") if screenGui then local buffs = screenGui:FindFirstChild("Buffs") if buffs then for _, buff in ipairs(buffs:GetChildren()) do if buff.Name == buffName then local button = buff:FindFirstChild("Button") if button then local label = button:FindFirstChild("Label") if label and label.Text ~= "" then return label.Text end end end end end end end end
    return nil
end
local function isBuffExpired(buffName) local time = getBuffTime(buffName) if not time then return true end if time == "0:00:00" or time == "0s" then return true end return false end
local function getPermShrineInfo()
    local info = {buff = "Unknown", time = "Unknown"}
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then local screenGui = playerGui:FindFirstChild("ScreenGui") if screenGui then local shrine = screenGui:FindFirstChild("PermanentShrine") if shrine then local buffName = shrine:FindFirstChild("Frame") and shrine.Frame:FindFirstChild("Content") and shrine.Frame.Content:FindFirstChild("Current") and shrine.Frame.Content.Current:FindFirstChild("Buff") and shrine.Frame.Content.Current.Buff:FindFirstChild("BuffName") local remaining = shrine:FindFirstChild("Frame") and shrine.Frame:FindFirstChild("Content") and shrine.Frame.Content:FindFirstChild("Current") and shrine.Frame.Content.Current:FindFirstChild("Remaining") if buffName then info.buff = buffName.Text end if remaining then info.time = remaining.Text end end end end end
    return info
end

-- ======================================
-- SHRINE FUNCTIONS
-- ======================================
local function bubble() pcall(function() Remote:InvokeServer("DonateToShrine", BUBBLE) end) end
local function dreamer() pcall(function() Remote:InvokeServer("DonateToDreamerShrine", DREAMER_AMOUNT) end) end

-- ======================================
-- BUBBLE SHRINE
-- ======================================
ShrineTab:CreateSection("Bubble Shrine")
ShrineTab:CreateDropdown({Name = "Potion Type", CurrentOption = "Lucky", Options = {"Lucky", "Speed", "Coin", "Mythic"}, Callback = function(v) BUBBLE.Name = v end})
ShrineTab:CreateInput({Name = "Amount", CurrentValue = tostring(BUBBLE.Amount), PlaceholderText = "500", RemoveTextAfterFocusLost = false, Callback = function(v) local n = tonumber(v) if n then BUBBLE.Amount = n end end})
ShrineTab:CreateToggle({Name = "Auto Bubble", CurrentValue = false, Callback = function(v) bubbleEnabled = v if v then bubble() getgenv().ActivityStatus.current = "Bubble Shrine Activated" bubbleThread = task.spawn(function() while bubbleEnabled do task.wait(60) if isBuffExpired("ShrineBlessing") then bubble() end end end) else if bubbleThread then task.cancel(bubbleThread); bubbleThread = nil end end end})

-- ======================================
-- DREAMER SHRINE
-- ======================================
ShrineTab:CreateSection("Dreamer Shrine")
ShrineTab:CreateInput({Name = "Amount", CurrentValue = tostring(DREAMER_AMOUNT), PlaceholderText = "15", RemoveTextAfterFocusLost = false, Callback = function(v) local n = tonumber(v) if n then DREAMER_AMOUNT = n end end})
ShrineTab:CreateToggle({Name = "Auto Dreamer", CurrentValue = false, Callback = function(v) dreamerEnabled = v if v then dreamer() getgenv().ActivityStatus.current = "Dreamer Shrine Activated" dreamerThread = task.spawn(function() while dreamerEnabled do task.wait(60) if isBuffExpired("DreamerBlessing") then dreamer() end end end) else if dreamerThread then task.cancel(dreamerThread); dreamerThread = nil end end end})

-- ======================================
-- PERM SHRINE
-- ======================================
ShrineTab:CreateSection("Perm Shrine")
local permInfoLabel = ShrineTab:CreateLabel("Buff: Unknown | Time: Unknown")
task.spawn(function() while true do task.wait(30) local info = getPermShrineInfo() pcall(function() permInfoLabel:SetText("Buff: " .. info.buff .. " | Time: " .. info.time) end) end end)
ShrineTab:CreateDropdown({Name = "Egg", Options = PERM_EGGS, CurrentOption = {"Common Egg"}, Callback = function(v) permEgg = v end})
ShrineTab:CreateDropdown({Name = "Target Buff", Options = PERM_BUFFS, CurrentOption = {"Luck"}, Callback = function(v) permTargetBuff = v end})
ShrineTab:CreateInput({Name = "Amount", CurrentValue = tostring(permAmount), PlaceholderText = "400", RemoveTextAfterFocusLost = false, Callback = function(v) local n = tonumber(v) if n then permAmount = n end end})
ShrineTab:CreateToggle({Name = "Auto Perm Shrine", CurrentValue = false, Callback = function(v) permRunning = v if v then getgenv().ActivityStatus.current = "Perm Shrine - Rerolling for " .. permTargetBuff .. " buff" permThread = task.spawn(function() while permRunning do pcall(function() RemoteFunc:InvokeServer("DonateToPermanentShrine", "Lucky", 6, permAmount) end) task.wait(1) pcall(function() RemoteEvent:FireServer("ClaimPermanentShrineBuff", permEgg) end) task.wait(1) local info = getPermShrineInfo() while permRunning and not info.buff:lower():find(permTargetBuff:lower()) do pcall(function() RemoteEvent:FireServer("RerollPermanentShrine") end) task.wait(2) info = getPermShrineInfo() end if permRunning then task.wait(43200) end end end) else if permThread then task.cancel(permThread) end end end})

print("[Shrine] Loaded!")
