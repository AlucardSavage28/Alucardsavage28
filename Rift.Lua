-- ================================================
-- RIFT TAB (EGG RIFT + CHEST RIFT)
-- ================================================
repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local RiftTab = Window:CreateTab("Rift", nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local RemoteFunction = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteFunction
local Remote = require(ReplicatedStorage.Shared.Framework.Network.Remote)

local WORLDS = {"The Overworld","Minigame Paradise"}

local WORLD_EGGS = {
    ["The Overworld"] = {"Spikey Egg","Magma Egg","Crystal Egg","Lunar Egg","Void Egg","Hell Egg","Nightmare Egg","Rainbow Egg","Obsidian Egg"},
    ["Minigame Paradise"] = {"Mining Egg","Cyber Egg","Neon Egg"},
}

local selectedEggWorld = "The Overworld"
local selectedEgg = "Spikey Egg"

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

-- ======================================
-- FUNCTIONS
-- ======================================
local function summonAndOpen(riftKey, world)
    pcall(function()
        RemoteFunction:InvokeServer("SummonRift", {
            ["Time"] = 5,
            ["Type"] = "Chest",
            ["Name"] = riftKey,
            ["World"] = world
        })
    end)
    task.wait(3)
    pcall(function() Remote:FireServer("TeleportToRift", riftKey) end)
    task.wait(0.5)
    pcall(function() Remote:FireServer("UnlockRiftChest", riftKey, false) end)
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
    end
})

RiftTab:CreateDropdown({
    Name = "Egg",
    Options = WORLD_EGGS[selectedEggWorld],
    CurrentOption = {selectedEgg},
    Callback = function(v)
        selectedEgg = v[1]
    end
})

RiftTab:CreateToggle({
    Name = "Auto Egg Rift",
    CurrentValue = false,
    Callback = function(v)
        eggLoop = v

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
-- AUTO CHEST RIFT
-- =========================
RiftTab:CreateSection("Auto Chest Rift")

RiftTab:CreateToggle({
    Name = "Auto Golden Chest",
    CurrentValue = false,
    Callback = function(v)
        goldenRunning = v
        if v then
            goldenThread = task.spawn(function()
                while goldenRunning do
                    summonAndOpen("golden-chest", "The Overworld")
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
    CurrentValue = false,
    Callback = function(v)
        royalRunning = v
        if v then
            royalThread = task.spawn(function()
                while royalRunning do
                    summonAndOpen("royal-chest", "The Overworld")
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
    CurrentValue = false,
    Callback = function(v)
        superRunning = v
        if v then
            superThread = task.spawn(function()
                while superRunning do
                    summonAndOpen("super-chest", "The Overworld")
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
    CurrentValue = false,
    Callback = function(v)
        diceRunning = v
        if v then
            diceThread = task.spawn(function()
                while diceRunning do
                    summonAndOpen("dice-rift", "Minigame Paradise")
                    task.wait(1860)
                end
            end)
        else
            if diceThread then task.cancel(diceThread) end
        end
    end
})

print("[Rift] Loaded!")
