-- ================================================
-- RIFT TAB (SUMMON + AUTO TP + OPEN CHEST)
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

local ALL_CHESTS = {"Golden Chest","Royal Chest","Super Chest","Dice Chest"}

local selectedEggWorld = "The Overworld"
local selectedEgg = "Spikey Egg"

local selectedChest = "Golden Chest"

local eggLoop = false
local chestLoop = false
local eggThread = nil
local chestThread = nil

-- ======================================
-- FUNCTIONS
-- ======================================
local function getChestRiftKey(chestName)
    return chestName:lower():gsub("%s+", "-")
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
-- CHEST RIFT
-- =========================
RiftTab:CreateSection("Chest Rift")

RiftTab:CreateDropdown({
    Name = "Chest",
    Options = ALL_CHESTS,
    CurrentOption = {selectedChest},
    Callback = function(v)
        selectedChest = v[1]
    end
})

RiftTab:CreateToggle({
    Name = "Auto Chest Rift (Summon + TP + Open)",
    CurrentValue = false,
    Callback = function(v)
        chestLoop = v

        if v then
            chestThread = task.spawn(function()
                while chestLoop do
                    pcall(function()
                        RemoteFunction:InvokeServer(
                            "SummonRift",
                            {
                                Type="Chest",
                                Name=selectedChest,
                                Time=5,
                                World="The Overworld"
                            }
                        )
                    end)
                    
                    task.wait(3)
                    
                    local riftKey = getChestRiftKey(selectedChest)
                    pcall(function() Remote:FireServer("TeleportToRift", riftKey) end)
                    task.wait(0.5)
                    pcall(function() Remote:FireServer("UnlockRiftChest", riftKey, false) end)
                    
                    task.wait(1860)
                end
            end)
        else
            chestLoop = false
            if chestThread then task.cancel(chestThread) end
        end
    end
})

print("[Rift] Loaded!")
