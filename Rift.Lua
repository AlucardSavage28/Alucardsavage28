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

local WORLD_CHESTS = {
    ["The Overworld"] = {"Golden Chest","Royal Chest","Super Chest","Obsidian Chest"},
    ["Minigame Paradise"] = {"Dice Chest"},
}

local selectedEggWorld = "The Overworld"
local selectedEgg = "Spikey Egg"

local selectedChestWorld = "The Overworld"
local selectedChest = "Golden Chest"

local eggLoop = false
local chestLoop = false
local eggThread = nil
local chestThread = nil

-- ======================================
-- FUNCTIONS
-- ======================================
local function getRoot()
    local char = player.Character
    if char then return char:FindFirstChild("HumanoidRootPart") end
end

local function getChestRiftPosition(chestName)
    local key = chestName:lower():gsub("%s+", "-")
    local riftFolder = workspace:FindFirstChild("Rendered")
    if riftFolder then
        riftFolder = riftFolder:FindFirstChild("Rifts")
        if riftFolder then
            local rift = riftFolder:FindFirstChild(key)
            if rift then
                local chest = rift:FindFirstChild("Chest")
                if chest then
                    for _, child in ipairs(chest:GetDescendants()) do
                        if child:IsA("BasePart") then
                            return child.Position
                        end
                    end
                end
                for _, child in ipairs(rift:GetDescendants()) do
                    if child:IsA("BasePart") then
                        return child.Position
                    end
                end
            end
        end
    end
    return nil
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
    Name = "Chest World",
    Options = WORLDS,
    CurrentOption = {selectedChestWorld},
    Callback = function(v)
        selectedChestWorld = v[1]
        selectedChest = WORLD_CHESTS[selectedChestWorld][1]
    end
})

RiftTab:CreateDropdown({
    Name = "Chest",
    Options = WORLD_CHESTS[selectedChestWorld],
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
                                World=selectedChestWorld
                            }
                        )
                    end)
                    
                    task.wait(3)
                    
                    local pos = getChestRiftPosition(selectedChest)
                    if pos then
                        local root = getRoot()
                        if root then
                            root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                        end
                    end
                    
                    task.wait(0.5)
                    
                    pcall(function()
                        Remote:FireServer("ClaimChest", selectedChest, true)
                    end)
                    
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
