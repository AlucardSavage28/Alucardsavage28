repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local EnchantTab = Window:CreateTab("Enchant", nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)

local RemoteContainer = ReplicatedStorage.Shared.Framework.Network.Remote
local RemoteFunction = RemoteContainer.RemoteFunction
local RemoteEvent = RemoteContainer.RemoteEvent

-- ======================================
-- SETTINGS
-- ======================================
local TARGET_ENCHANTS = {
    { Id = "ultra-roller" },
    { Id = "secret-hunter" }
}
local REROLL_CURRENCY = "Shadow Crystal"
local COOLDOWN = 0.5
local enchantRunning = false
local enchantThread = nil

local ALL_ENCHANTS = {}
local ENCHANT_DISPLAY = {}

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
local function findPetById(petId)
    local data = LocalData:Get()
    if not (data and data.Pets) then return nil end
    for _, pet in pairs(data.Pets) do
        if pet and pet.Id == petId then return pet end
    end
    return nil
end

local function getEquippedPets()
    local pets = {}
    local data = LocalData:Get()
    if data and data.Teams and data.Pets then
        local teamNum = data.TeamEquipped or 1
        local team = data.Teams[teamNum]
        if team and team.Pets then
            for _, equippedId in ipairs(team.Pets) do
                local pet = findPetById(equippedId)
                if pet then table.insert(pets, pet) end
            end
        end
    end
    return pets
end

local function getFoundTargetEnchant(pet)
    local enchants = pet.Enchants or {}
    for i, currentEnchant in ipairs(enchants) do
        for _, targetEnchant in ipairs(TARGET_ENCHANTS) do
            if currentEnchant.Id == targetEnchant.Id then
                return targetEnchant, i
            end
        end
    end
    return nil, nil
end

local function enchantPet(petId)
    while enchantRunning do
        local pet = findPetById(petId)
        if not pet then return end
        
        local foundTarget, foundSlot = getFoundTargetEnchant(pet)
        if foundTarget then
            print("[Enchant] Found " .. ENCHANT_DISPLAY[foundTarget.Id] .. " in Slot " .. foundSlot)
            
            local neededTarget = nil
            for _, target in ipairs(TARGET_ENCHANTS) do
                if target.Id ~= foundTarget.Id then neededTarget = target; break end
            end
            if not neededTarget then
                print("[Enchant] Both targets found!")
                return
            end
            
            local slotToReroll = (foundSlot == 1) and 2 or 1
            print("[Enchant] Rerolling Slot " .. slotToReroll .. " for " .. ENCHANT_DISPLAY[neededTarget.Id])
            
            while enchantRunning do
                local currentPet = findPetById(petId)
                if not currentPet then return end
                
                local enchantInSlot = (currentPet.Enchants or {})[slotToReroll]
                if enchantInSlot and enchantInSlot.Id == neededTarget.Id then
                    print("[Enchant] Done! " .. ENCHANT_DISPLAY[foundTarget.Id] .. " + " .. ENCHANT_DISPLAY[neededTarget.Id])
                    return
                end
                
                RemoteEvent:FireServer("RerollEnchant", petId, slotToReroll)
                task.wait(COOLDOWN)
            end
            return
        end
        
        RemoteFunction:InvokeServer("RerollEnchants", petId, REROLL_CURRENCY)
        task.wait(COOLDOWN)
    end
end

-- ======================================
-- UI
-- ======================================
EnchantTab:CreateSection("Manual Enchant")

EnchantTab:CreateLabel("If you wanna use Enchant that can't be rolled with shadow crystal you might need to change the reroll currency to Gems after getting targetted enchant on slot 1 with shadow crystal")

EnchantTab:CreateDropdown({
    Name = "Slot 1 Enchant",
    Options = ALL_ENCHANTS,
    CurrentOption = {"ultra-roller"},
    Callback = function(v)
        TARGET_ENCHANTS[1].Id = v[1]
    end
})

EnchantTab:CreateDropdown({
    Name = "Slot 2 Enchant",
    Options = ALL_ENCHANTS,
    CurrentOption = {"secret-hunter"},
    Callback = function(v)
        TARGET_ENCHANTS[2].Id = v[1]
    end
})

EnchantTab:CreateDropdown({
    Name = "Currency",
    Options = {"Shadow Crystal", "Gems"},
    CurrentOption = {"Shadow Crystal"},
    Callback = function(v)
        REROLL_CURRENCY = v[1]
    end
})

EnchantTab:CreateToggle({
    Name = "Auto Enchant All Equipped",
    CurrentValue = false,
    Callback = function(v)
        enchantRunning = v
        if v then
            enchantThread = task.spawn(function()
                local pets = getEquippedPets()
                print("[Enchant] Found " .. #pets .. " equipped pets")
                
                for i, pet in ipairs(pets) do
                    if not enchantRunning then break end
                    print("[Enchant] Pet " .. i .. "/" .. #pets .. ": " .. pet.Name)
                    enchantPet(pet.Id)
                    if i < #pets then task.wait(1) end
                end
                
                print("[Enchant] All pets done!")
                enchantRunning = false
            end)
        else
            if enchantThread then task.cancel(enchantThread) end
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
