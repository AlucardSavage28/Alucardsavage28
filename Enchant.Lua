repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local EnchantTab = Window:CreateTab("Enchant", nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)
local Remote = require(ReplicatedStorage.Shared.Framework.Network.Remote)
local RE = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteEvent

-- ======================================
-- SETTINGS
-- ======================================
local slot1Enchant = "ultra-roller"
local slot2Enchant = "secret-hunter"
local useShadow1 = false
local useShadow2 = false
local slot1Running = false
local slot1Thread = nil
local slot2Running = false
local slot2Thread = nil
local enchantAllRunning = false
local enchantAllThread = nil

local ALL_ENCHANTS = {}
local ENCHANT_DISPLAY = {}

-- Load enchant list
local EnchantsData = require(ReplicatedStorage.Shared.Data.Enchants)
for id, data in pairs(EnchantsData) do
    if not id:find("^super-") or id == "super-burst" or id == "super-duplication" then
        table.insert(ALL_ENCHANTS, id)
        ENCHANT_DISPLAY[id] = data.DisplayName or id
    end
end
table.sort(ALL_ENCHANTS)

-- ======================================
-- FUNCTIONS
-- ======================================
local function getEquippedPets()
    local pets = {}
    local data = LocalData:Get()
    if data and data.Teams and data.Pets then
        local teamNum = data.TeamEquipped or 1
        local team = data.Teams[teamNum]
        if team and team.Pets then
            for _, equippedId in ipairs(team.Pets) do
                for _, pet in pairs(data.Pets) do
                    if pet.Id == equippedId then
                        table.insert(pets, pet)
                        break
                    end
                end
            end
        end
    end
    return pets
end

local function refreshPet(petId)
    local data = LocalData:Get()
    if data and data.Pets then
        for _, pet in pairs(data.Pets) do
            if pet.Id == petId then return pet end
        end
    end
    return nil
end

local function getEnchantId(pet, slot)
    if pet and pet.Enchants and pet.Enchants[slot] then
        return pet.Enchants[slot].Id
    end
    return nil
end

-- ======================================
-- UI - MANUAL ENCHANT
-- ======================================
EnchantTab:CreateSection("Manual Enchant")

EnchantTab:CreateDropdown({
    Name = "Slot 1 Enchant",
    Options = ALL_ENCHANTS,
    CurrentOption = {"ultra-roller"},
    Callback = function(v)
        slot1Enchant = v[1]
    end
})

EnchantTab:CreateToggle({
    Name = "Use Shadow Crystal (Slot 1)",
    CurrentValue = false,
    Callback = function(v)
        useShadow1 = v
    end
})

EnchantTab:CreateDropdown({
    Name = "Slot 2 Enchant",
    Options = ALL_ENCHANTS,
    CurrentOption = {"secret-hunter"},
    Callback = function(v)
        slot2Enchant = v[1]
    end
})

EnchantTab:CreateToggle({
    Name = "Use Shadow Crystal (Slot 2)",
    CurrentValue = false,
    Callback = function(v)
        useShadow2 = v
    end
})

EnchantTab:CreateToggle({
    Name = "Auto Enchant Current Pet",
    CurrentValue = false,
    Callback = function(v)
        slot1Running = v
        slot2Running = v
        if v then
            local pets = getEquippedPets()
            if #pets == 0 then
                slot1Running = false
                slot2Running = false
                return
            end
            local pet = pets[1]
            
            -- Enchant Slot 1
            slot1Thread = task.spawn(function()
                while slot1Running do
                    local currentPet = refreshPet(pet.Id)
                    local current = getEnchantId(currentPet, 1)
                    
                    if current == slot1Enchant then
                        print("[Enchant] Slot 1 done: " .. ENCHANT_DISPLAY[slot1Enchant])
                        slot1Running = false
                    else
                        if useShadow1 then
                            pcall(function() RE:FireServer("UseShadowCrystal", pet.Id, 1) end)
                        else
                            pcall(function() Remote:InvokeServer("RerollEnchants", pet.Id, "Gems", nil) end)
                        end
                        task.wait(1.5)
                    end
                end
            end)
            
            -- Enchant Slot 2 (waits for Slot 1 to finish)
            slot2Thread = task.spawn(function()
                while slot1Running do task.wait(0.5) end
                
                while slot2Running do
                    local currentPet = refreshPet(pet.Id)
                    local current1 = getEnchantId(currentPet, 1)
                    local current2 = getEnchantId(currentPet, 2)
                    
                    -- Fix Slot 1 if it changed (from gems)
                    if useShadow2 and current1 ~= slot1Enchant then
                        while slot2Running do
                            pcall(function() RE:FireServer("UseShadowCrystal", pet.Id, 1) end)
                            task.wait(1.5)
                            currentPet = refreshPet(pet.Id)
                            if getEnchantId(currentPet, 1) == slot1Enchant then break end
                        end
                    end
                    
                    -- Check completion
                    if current2 == slot2Enchant and current2 ~= current1 then
                        print("[Enchant] Slot 2 done: " .. ENCHANT_DISPLAY[slot2Enchant])
                        slot2Running = false
                    else
                        if useShadow2 then
                            pcall(function() RE:FireServer("UseShadowCrystal", pet.Id, 2) end)
                        else
                            pcall(function() Remote:InvokeServer("RerollEnchants", pet.Id, "Gems", nil) end)
                        end
                        task.wait(1.5)
                    end
                end
            end)
        else
            if slot1Thread then task.cancel(slot1Thread) end
            if slot2Thread then task.cancel(slot2Thread) end
        end
    end
})

-- Enchant All
EnchantTab:CreateToggle({
    Name = "Auto Enchant All Equipped",
    CurrentValue = false,
    Callback = function(v)
        enchantAllRunning = v
        if v then
            enchantAllThread = task.spawn(function()
                local pets = getEquippedPets()
                print("[Enchant] Found " .. #pets .. " equipped pets")
                
                for i, pet in ipairs(pets) do
                    if not enchantAllRunning then break end
                    print("[Enchant] Pet " .. i .. ": " .. pet.Name)
                    
                    -- Slot 1
                    while enchantAllRunning do
                        local currentPet = refreshPet(pet.Id)
                        if getEnchantId(currentPet, 1) == slot1Enchant then break end
                        if useShadow1 then
                            pcall(function() RE:FireServer("UseShadowCrystal", pet.Id, 1) end)
                        else
                            pcall(function() Remote:InvokeServer("RerollEnchants", pet.Id, "Gems", nil) end)
                        end
                        task.wait(1.5)
                    end
                    
                    -- Slot 2
                    while enchantAllRunning do
                        local currentPet = refreshPet(pet.Id)
                        local c1 = getEnchantId(currentPet, 1)
                        local c2 = getEnchantId(currentPet, 2)
                        
                        if c2 == slot2Enchant and c2 ~= c1 then break end
                        
                        -- Fix slot 1 if needed
                        if useShadow2 and c1 ~= slot1Enchant then
                            while enchantAllRunning do
                                pcall(function() RE:FireServer("UseShadowCrystal", pet.Id, 1) end)
                                task.wait(1.5)
                                currentPet = refreshPet(pet.Id)
                                if getEnchantId(currentPet, 1) == slot1Enchant then break end
                            end
                        end
                        
                        if useShadow2 then
                            pcall(function() RE:FireServer("UseShadowCrystal", pet.Id, 2) end)
                        else
                            pcall(function() Remote:InvokeServer("RerollEnchants", pet.Id, "Gems", nil) end)
                        end
                        task.wait(1.5)
                    end
                end
                print("[Enchant] All pets done!")
                enchantAllRunning = false
            end)
        else
            if enchantAllThread then task.cancel(enchantAllThread) end
        end
    end
})

-- ======================================
-- SIMPLE ENCHANT
-- ======================================
EnchantTab:CreateSection("Simple Enchant")

EnchantTab:CreateLabel("If you use this please wait till it finish enchanting and check ur shadow crystal")

local function RunEnchant(primary, secondary, item1, item2)
    getgenv().Settings = {
        Enchanting = {
            Enabled = true,
            PRIMARY_ENCHANTS = primary,
            SECONDARY_ENCHANTS = secondary,
            FIRST_SLOT_ITEM_TO_USE = item1,
            SECOND_SLOT_ITEM_TO_USE = item2,
            AUTO_SWITCH_TO_ORBS = true,
            PRIORITIZE_PRIMARY = true
        }
    }
    loadstring(game:HttpGet("https://raw.githubusercontent.com/issascripts/bgsi/refs/heads/main/coolestautoenchantintown.lua"))()
end

EnchantTab:CreateButton({
    Name = "Secret Hunter + Ultra Roller",
    Callback = function()
        RunEnchant({"Secret Hunter","Ultra Roller"}, {"Secret Hunter","Ultra Roller"}, "Shadow Crystal", "Shadow Crystal")
    end
})

EnchantTab:CreateButton({
    Name = "Ultra Roller + High Roller",
    Callback = function()
        RunEnchant({"High Roller","Ultra Roller"}, {"High Roller","Ultra Roller"}, "Shadow Crystal", "Gems")
    end
})

EnchantTab:CreateButton({
    Name = "Shiny Seeker + Ultra Roller",
    Callback = function()
        RunEnchant({"Shiny Seeker","Ultra Roller"}, {"Shiny Seeker","Ultra Roller"}, "Shadow Crystal", "Shadow Crystal")
    end
})

-- ======================================
-- BUBBLER ENCHANTER
-- ======================================
EnchantTab:CreateSection("Bubbler Enchanter")

EnchantTab:CreateButton({
    Name = "Team Up V + Bubbler V",
    Callback = function()
        RunEnchant({"Team Up V","Bubbler V"}, {"Team Up V","Bubbler V"}, "Gems", "Gems")
    end
})

EnchantTab:CreateButton({
    Name = "Determination + Bubbler V",
    Callback = function()
        RunEnchant({"Determination","Bubbler V"}, {"Determination","Bubbler V"}, "Shadow Crystal", "Gems")
    end
})

-- ======================================
-- CURRENCY ENCHANTER
-- ======================================
EnchantTab:CreateSection("Currency Enchanter")

EnchantTab:CreateButton({
    Name = "Team Up V + Looter V",
    Callback = function()
        RunEnchant({"Team Up V","Looter V"}, {"Team Up V","Looter V"}, "Gems", "Gems")
    end
})

EnchantTab:CreateButton({
    Name = "Determination + Looter V",
    Callback = function()
        RunEnchant({"Determination","Looter V"}, {"Determination","Looter V"}, "Shadow Crystal", "Gems")
    end
})
