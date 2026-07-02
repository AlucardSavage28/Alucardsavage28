repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local ShrineTab = Window:CreateTab("Shrine", nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remote
local RemoteEvent
local RemoteFunc

pcall(function()
    Remote = require(ReplicatedStorage.Shared.Framework.Network.Remote)
end)

pcall(function()
    RemoteEvent = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteEvent
end)

pcall(function()
    RemoteFunc = require(ReplicatedStorage.Shared.Framework.Network.Remote)
end)

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
    Name = "Lucky",
    Amount = 500
}

local DREAMER_AMOUNT = 15
local PERM_EGG = "Common Egg"
local PERM_AMOUNT = 400
local INTERVAL = 43200

-- ======================================
-- FUNCTIONS
-- ======================================
local function bubble()
    pcall(function()
        Remote:InvokeServer("DonateToShrine", BUBBLE)
    end)
end

local function dreamer()
    pcall(function()
        Remote:InvokeServer("DonateToDreamerShrine", DREAMER_AMOUNT)
    end)
end

local function permShrine()
    pcall(function()
        RemoteFunc:InvokeServer("DonateToPermanentShrine", "Lucky", 6, PERM_AMOUNT)
        task.wait(1)
        RemoteEvent:FireServer("ClaimPermanentShrineBuff", PERM_EGG)
        task.wait(1)
        RemoteEvent:FireServer("ClaimPermanentShrineBuff", PERM_EGG)
    end)
end

-- ======================================
-- BUBBLE SHRINE
-- ======================================
ShrineTab:CreateSection("Bubble Shrine")

ShrineTab:CreateDropdown({
    Name = "Potion Type",
    CurrentOption = "Lucky",
    Options = {"Lucky", "Speed", "Coin", "Mythic"},
    Callback = function(v)
        BUBBLE.Name = v
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
        end
    end
})

ShrineTab:CreateToggle({
    Name = "Auto Bubble",
    CurrentValue = false,
    Callback = function(v)
        bubbleEnabled = v

        if v then
            bubble()
            bubbleThread = task.spawn(function()
                while bubbleEnabled do
                    task.wait(INTERVAL)
                    bubble()
                end
            end)
        else
            if bubbleThread then
                task.cancel(bubbleThread)
                bubbleThread = nil
            end
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
        end
    end
})

ShrineTab:CreateToggle({
    Name = "Auto Dreamer",
    CurrentValue = false,
    Callback = function(v)
        dreamerEnabled = v

        if v then
            dreamer()
            dreamerThread = task.spawn(function()
                while dreamerEnabled do
                    task.wait(INTERVAL)
                    dreamer()
                end
            end)
        else
            if dreamerThread then
                task.cancel(dreamerThread)
                dreamerThread = nil
            end
        end
    end
})

-- ======================================
-- PERM SHRINE
-- ======================================
ShrineTab:CreateSection("Perm Shrine")

ShrineTab:CreateDropdown({
    Name = "Egg",
    CurrentOption = "Common Egg",
    Options = {
        "Common Egg",
        "Nightmare Egg",
        "Rainbow Egg",
        "Mining Egg",
        "Cyber Egg",
        "Neon Egg",
        "Vine Egg",
        "Lava Egg",
        "Atlantis Egg",
        "Classic Egg"
    },
    Callback = function(v)
        PERM_EGG = v
    end
})

ShrineTab:CreateInput({
    Name = "Amount",
    CurrentValue = tostring(PERM_AMOUNT),
    PlaceholderText = "400",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        local n = tonumber(v)
        if n then
            PERM_AMOUNT = n
        end
    end
})

ShrineTab:CreateToggle({
    Name = "Auto Perm Shrine",
    CurrentValue = false,
    Callback = function(v)
        permEnabled = v

        if v then
            permShrine()
            permThread = task.spawn(function()
                while permEnabled do
                    task.wait(INTERVAL)
                    permShrine()
                end
            end)
        else
            if permThread then
                task.cancel(permThread)
                permThread = nil
            end
        end
    end
})

print("[Shrine] Loaded!")
