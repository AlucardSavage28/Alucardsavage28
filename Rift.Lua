-- ================================================
-- RIFT TAB (EGG RIFT + CHEST RIFT + WORLD CHEST)
-- ================================================
repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local RiftTab = Window:CreateTab("Rift", nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local RemoteFunction = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteFunction
local Remote = require(ReplicatedStorage.Shared.Framework.Network.Remote)

-- ======================================
-- LOAD SAVED SETTINGS
-- ======================================
local settings = getgenv().HubSettings or {}
if not settings.rift then settings.rift = {} end
local riftSettings = settings.rift

-- ======================================
-- SETTINGS
-- ======================================
local WORLDS = {"The Overworld","Minigame Paradise"}

local WORLD_EGGS = {
    ["The Overworld"] = {"Spikey Egg","Magma Egg","Crystal Egg","Lunar Egg","Void Egg","Hell Egg","Nightmare Egg","Rainbow Egg","Obsidian Egg"},
    ["Minigame Paradise"] = {"Mining Egg","Cyber Egg","Neon Egg"},
}

local selectedEggWorld = riftSettings.eggWorld or "The Overworld"
local selectedEgg = riftSettings.eggRift or "Spikey Egg"

local eggLoop = false
local eggThread = nil

-- Chest rift settings
local goldenRunning = false
local goldenThread = nil
local royalRunning = false
local royalThread = nil
local superRunning = false
local superThread = nil
local diceRunning = false
local diceThread = nil

-- World chest settings
local seasonRunning = false
local seasonThread = nil
local giantRunning = false
local giantThread = nil
local voidRunning = false
local voidThread = nil
local ticketRunning = false
local ticketThread = nil
local claimAllRunning = false
local claimAllThread = nil

-- ======================================
-- FUNCTIONS
-- ======================================
local function summonAndOpen(riftKey, world, chestName)
    pcall(function()
        RemoteFunction:InvokeServer("SummonRift", {
            ["Time"] = 5,
            ["Type"] = "Chest",
            ["Name"] = riftKey,
            ["World"] = world
        })
    end)
    task.wait(3)
    
    getgenv().ActivityStatus.current = "Teleporting to " .. chestName
    getgenv().ActivityStatus.trigger = true
    
    pcall(function() Remote:FireServer("TeleportToRift", riftKey) end)
    task.wait(0.5)
    
    getgenv().ActivityStatus.current = "Opening " .. chestName
    getgenv().ActivityStatus.trigger = true
    
    while true do
        local riftFolder = workspace:FindFirstChild("Rendered")
        local riftExists = false
        if riftFolder then
            riftFolder = riftFolder:FindFirstChild("Rifts")
            if riftFolder and riftFolder:FindFirstChild(riftKey) then
                riftExists = true
            end
        end
        
        if not riftExists then break end
        
        pcall(function() Remote:FireServer("UnlockRiftChest", riftKey, false) end)
        task.wait(0.5)
    end
end

-- =========================
-- EGG RIFT
-- =========================
RiftTab:CreateSection("Egg Rift")

RiftTab:CreateDropdown({
    Name = "Egg World",
    Options = WORLDS,
    CurrentOption = {selectedEggWorld},
    Callback = function(v)
        selectedEggWorld = v[1]
        selectedEgg = WORLD_EGGS[selectedEggWorld][1]
        riftSettings.eggWorld = v[1]
        getgenv().HubSettings.rift = riftSettings
        saveHubSettings()
    end
})

RiftTab:CreateDropdown({
    Name = "Egg",
    Options = WORLD_EGGS[selectedEggWorld],
    CurrentOption = {selectedEgg},
    Callback = function(v)
        selectedEgg = v[1]
        riftSettings.eggRift = v[1]
        getgenv().HubSettings.rift = riftSettings
        saveHubSettings()
    end
})

RiftTab:CreateToggle({
    Name = "Auto Egg Rift",
    CurrentValue = riftSettings.autoEggRift or false,
    Callback = function(v)
        eggLoop = v
        riftSettings.autoEggRift = v
        getgenv().HubSettings.rift = riftSettings
        saveHubSettings()

        if v then
            eggThread = task.spawn(function()
                while eggLoop do
                    pcall(function()
                        RemoteFunction:InvokeServer(
                            "SummonRift",
                            {
                                Type="Egg",
                                Name=selectedEgg,
                                Time=5,
                                Luck=5,
                                World=selectedEggWorld
                            }
                        )
                    end)
                    task.wait(1860)
                end
            end)
        else
            eggLoop = false
            if eggThread then task.cancel(eggThread) end
        end
    end
})

-- =========================
-- AUTO WORLD CHEST
-- =========================
RiftTab:CreateSection("Auto World Chest")

RiftTab:CreateToggle({
    Name = "Auto Season Chest",
    CurrentValue = riftSettings.autoSeasonChest or false,
    Callback = function(v)
        seasonRunning = v
        riftSettings.autoSeasonChest = v
        getgenv().HubSettings.rift = riftSettings
        saveHubSettings()
        if v then
            seasonThread = task.spawn(function()
                while seasonRunning do
                    getgenv().ActivityStatus.current = "Opening Season Chest"
                    getgenv().ActivityStatus.trigger = true
                    pcall(function() Remote:FireServer("UnlockEventChest", "Season Chest", false) end)
                    task.wait(1)
                end
            end)
        else
            if seasonThread then task.cancel(seasonThread) end
        end
    end
})

RiftTab:CreateToggle({
    Name = "Auto Giant Chest",
    CurrentValue = riftSettings.autoGiantChest or false,
    Callback = function(v)
        giantRunning = v
        riftSettings.autoGiantChest = v
        getgenv().HubSettings.rift = riftSettings
        saveHubSettings()
        if v then
            giantThread = task.spawn(function()
                while giantRunning do
                    getgenv().ActivityStatus.current = "Opening Giant Chest"
                    getgenv().ActivityStatus.trigger = true
                    pcall(function() Remote:FireServer("ClaimChest", "Giant Chest") end)
                    task.wait(1)
                end
            end)
        else
            if giantThread then task.cancel(giantThread) end
        end
    end
})

RiftTab:CreateToggle({
    Name = "Auto Void Chest",
    CurrentValue = riftSettings.autoVoidChest or false,
    Callback = function(v)
        voidRunning = v
        riftSettings.autoVoidChest = v
        getgenv().HubSettings.rift = riftSettings
        saveHubSettings()
        if v then
            voidThread = task.spawn(function()
                while voidRunning do
                    getgenv().ActivityStatus.current = "Opening Void Chest"
                    getgenv().ActivityStatus.trigger = true
                    pcall(function() Remote:FireServer("ClaimChest", "Void Chest") end)
                    task.wait(1)
                end
            end)
        else
            if voidThread then task.cancel(voidThread) end
        end
    end
})

RiftTab:CreateToggle({
    Name = "Auto Ticket Chest",
    CurrentValue = riftSettings.autoTicketChest or false,
    Callback = function(v)
        ticketRunning = v
        riftSettings.autoTicketChest = v
        getgenv().HubSettings.rift = riftSettings
        saveHubSettings()
        if v then
            ticketThread = task.spawn(function()
                while ticketRunning do
                    getgenv().ActivityStatus.current = "Opening Ticket Chest"
                    getgenv().ActivityStatus.trigger = true
                    pcall(function() Remote:FireServer("ClaimChest", "Ticket Chest") end)
                    task.wait(1)
                end
            end)
        else
            if ticketThread then task.cancel(ticketThread) end
        end
    end
})

RiftTab:CreateToggle({
    Name = "Auto Claim All",
    CurrentValue = riftSettings.autoClaimAllChest or false,
    Callback = function(v)
        claimAllRunning = v
        riftSettings.autoClaimAllChest = v
        getgenv().HubSettings.rift = riftSettings
        saveHubSettings()
        if v then
            claimAllThread = task.spawn(function()
                while claimAllRunning do
                    getgenv().ActivityStatus.current = "Opening all World Chests"
                    getgenv().ActivityStatus.trigger = true
                    pcall(function() Remote:FireServer("UnlockEventChest", "Season Chest", false) end)
                    pcall(function() Remote:FireServer("ClaimChest", "Giant Chest") end)
                    pcall(function() Remote:FireServer("ClaimChest", "Void Chest") end)
                    pcall(function() Remote:FireServer("ClaimChest", "Ticket Chest") end)
                    task.wait(1)
                end
            end)
        else
            if claimAllThread then task.cancel(claimAllThread) end
        end
    end
})

-- =========================
-- AUTO CHEST RIFT
-- =========================
RiftTab:CreateSection("Auto Chest Rift")

RiftTab:CreateToggle({
    Name = "Auto Golden Chest",
    CurrentValue = riftSettings.autoGoldenChest or false,
    Callback = function(v)
        goldenRunning = v
        riftSettings.autoGoldenChest = v
        getgenv().HubSettings.rift = riftSettings
        saveHubSettings()
        if v then
            goldenThread = task.spawn(function()
                while goldenRunning do
                    summonAndOpen("golden-chest", "The Overworld", "Golden Chest")
                    task.wait(1860)
                end
            end)
        else
            if goldenThread then task.cancel(goldenThread) end
        end
    end
})

RiftTab:CreateToggle({
    Name = "Auto Royal Chest",
    CurrentValue = riftSettings.autoRoyalChest or false,
    Callback = function(v)
        royalRunning = v
        riftSettings.autoRoyalChest = v
        getgenv().HubSettings.rift = riftSettings
        saveHubSettings()
        if v then
            royalThread = task.spawn(function()
                while royalRunning do
                    summonAndOpen("royal-chest", "The Overworld", "Royal Chest")
                    task.wait(1860)
                end
            end)
        else
            if royalThread then task.cancel(royalThread) end
        end
    end
})

RiftTab:CreateToggle({
    Name = "Auto Super Chest",
    CurrentValue = riftSettings.autoSuperChest or false,
    Callback = function(v)
        superRunning = v
        riftSettings.autoSuperChest = v
        getgenv().HubSettings.rift = riftSettings
        saveHubSettings()
        if v then
            superThread = task.spawn(function()
                while superRunning do
                    summonAndOpen("super-chest", "The Overworld", "Super Chest")
                    task.wait(1860)
                end
            end)
        else
            if superThread then task.cancel(superThread) end
        end
    end
})

RiftTab:CreateToggle({
    Name = "Auto Dice Chest",
    CurrentValue = riftSettings.autoDiceChest or false,
    Callback = function(v)
        diceRunning = v
        riftSettings.autoDiceChest = v
        getgenv().HubSettings.rift = riftSettings
        saveHubSettings()
        if v then
            diceThread = task.spawn(function()
                while diceRunning do
                    summonAndOpen("dice-rift", "Minigame Paradise", "Dice Chest")
                    task.wait(1860)
                end
            end)
        else
            if diceThread then task.cancel(diceThread) end
        end
    end
})

print("[Rift] Loaded!")
