repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local EnchantTab = Window:CreateTab("Enchant", nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)
local Pets = require(ReplicatedStorage.Shared.Data.Pets)

local RemoteContainer = ReplicatedStorage.Shared.Framework.Network.Remote
local RemoteFunction = RemoteContainer.RemoteFunction
local RemoteEvent = RemoteContainer.RemoteEvent

-- ======================================
-- SETTINGS
-- ======================================
local TARGET_ENCHANTS = {
    { Id = "ultra-roller" },
    { Id = "high-roller" }
}
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

local function isPetEnchantable(pet)
    if not pet then return false end
    if pet.Super then return false end
    local info = Pets[pet.Name]
    if info and info.Rarity then
        local rarity = info.Rarity
        if rarity:find("Secret") or rarity:find("Celestial") or rarity:find("Infinity") or rarity:find("Void") or rarity:find("Legendary") then
            return true
        end
    end
    return false
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
                if pet and isPetEnchantable(pet) then table.insert(pets, pet) end
            end
        end
    end
    return pets
end

local function isSecretOnly(enchantId)
    local data = EnchantsData[enchantId]
    return data and data.IsSecretOnly
end

local function enchantSingleSlot(petId, targetSlot, targetEnchantId)
    local targetIsSecret = isSecretOnly(targetEnchantId)
    while enchantRunning do
        local pet = findPetById(petId)
        if not pet then return false end
        local currentEnchant = (pet.Enchants or {})[targetSlot]
        if currentEnchant and currentEnchant.Id == targetEnchantId then
            print("[Enchant] Slot " .. targetSlot .. " already has " .. ENCHANT_DISPLAY[targetEnchantId])
            return true
        end
        local otherSlot = (targetSlot == 1) and 2 or 1
        local otherEnchant = (pet.Enchants or {})[otherSlot]
        if otherEnchant and otherEnchant.Id == targetEnchantId then
            print("[Enchant] WARNING: " .. ENCHANT_DISPLAY[targetEnchantId] .. " is on Slot " .. otherSlot .. ", cannot roll on Slot " .. targetSlot)
            return false
        end
        if targetIsSecret then
            local lockSlot = (targetSlot == 1) and 2 or 1
            RemoteEvent:FireServer("UseShadowCrystal", petId, lockSlot)
        else
            RemoteEvent:FireServer("RerollEnchant", petId, targetSlot)
        end
        task.wait(COOLDOWN)
    end
    return false
end

-- ======================================
-- UI
-- ======================================
EnchantTab:CreateSection("Manual Enchant")

EnchantTab:CreateLabel("Smart currency: Auto-detects Shadow Crystal or Gems")
EnchantTab:CreateLabel("NOTE: Make sure to check your Pets Enchant. If Secret Hunter is in Slot 1 but some pets already have it on Slot 2, it will roll endlessly!")

EnchantTab:CreateDropdown({Name = "Slot 1 Enchant", Options = ALL_ENCHANTS, CurrentOption = {"ultra-roller"}, Callback = function(v) TARGET_ENCHANTS[1].Id = v[1] end})
EnchantTab:CreateDropdown({Name = "Slot 2 Enchant", Options = ALL_ENCHANTS, CurrentOption = {"high-roller"}, Callback = function(v) TARGET_ENCHANTS[2].Id = v[1] end})

EnchantTab:CreateToggle({Name = "Auto Enchant All Equipped", CurrentValue = false, Callback = function(v) enchantRunning = v if v then enchantThread = task.spawn(function() local pets = getEquippedPets() print("[Enchant] Found " .. #pets .. " enchantable pets (skipped Super Legendary)") print("[Enchant] === PASS 1: Slot 1 (" .. ENCHANT_DISPLAY[TARGET_ENCHANTS[1].Id] .. ") ===") for i, pet in ipairs(pets) do if not enchantRunning then break end print("[Enchant] Pet " .. i .. "/" .. #pets .. ": " .. pet.Name) enchantSingleSlot(pet.Id, 1, TARGET_ENCHANTS[1].Id) if i < #pets then task.wait(0.5) end end if enchantRunning then print("[Enchant] === PASS 2: Slot 2 (" .. ENCHANT_DISPLAY[TARGET_ENCHANTS[2].Id] .. ") ===") for i, pet in ipairs(pets) do if not enchantRunning then break end print("[Enchant] Pet " .. i .. "/" .. #pets .. ": " .. pet.Name) enchantSingleSlot(pet.Id, 2, TARGET_ENCHANTS[2].Id) if i < #pets then task.wait(0.5) end end end print("[Enchant] All pets done!") enchantRunning = false end) else if enchantThread then task.cancel(enchantThread) end end end})

-- ======================================
-- SIMPLE ENCHANT
-- ======================================
EnchantTab:CreateSection("Simple Enchant")
EnchantTab:CreateLabel("If you use this please wait till it finish enchanting and check ur shadow crystal")

local function RunEnchant(primary, secondary, item1, item2)
    getgenv().Settings = {Enchanting = {Enabled = true, PRIMARY_ENCHANTS = primary, SECONDARY_ENCHANTS = secondary, FIRST_SLOT_ITEM_TO_USE = item1, SECOND_SLOT_ITEM_TO_USE = item2, AUTO_SWITCH_TO_ORBS = true, PRIORITIZE_PRIMARY = true}}
    loadstring(game:HttpGet("https://raw.githubusercontent.com/issascripts/bgsi/refs/heads/main/coolestautoenchantintown.lua"))()
end

EnchantTab:CreateButton({Name = "Secret Hunter + Ultra Roller", Callback = function() RunEnchant({"Secret Hunter","Ultra Roller"}, {"Secret Hunter","Ultra Roller"}, "Shadow Crystal", "Shadow Crystal") end})
EnchantTab:CreateButton({Name = "Ultra Roller + High Roller", Callback = function() RunEnchant({"High Roller","Ultra Roller"}, {"High Roller","Ultra Roller"}, "Shadow Crystal", "Gems") end})
EnchantTab:CreateButton({Name = "Shiny Seeker + Ultra Roller", Callback = function() RunEnchant({"Shiny Seeker","Ultra Roller"}, {"Shiny Seeker","Ultra Roller"}, "Shadow Crystal", "Shadow Crystal") end})

EnchantTab:CreateSection("Bubbler Enchanter")
EnchantTab:CreateButton({Name = "Team Up V + Bubbler V", Callback = function() RunEnchant({"Team Up V","Bubbler V"}, {"Team Up V","Bubbler V"}, "Gems", "Gems") end})
EnchantTab:CreateButton({Name = "Determination + Bubbler V", Callback = function() RunEnchant({"Determination","Bubbler V"}, {"Determination","Bubbler V"}, "Shadow Crystal", "Gems") end})

EnchantTab:CreateSection("Currency Enchanter")
EnchantTab:CreateButton({Name = "Team Up V + Looter V", Callback = function() RunEnchant({"Team Up V","Looter V"}, {"Team Up V","Looter V"}, "Gems", "Gems") end})
EnchantTab:CreateButton({Name = "Determination + Looter V", Callback = function() RunEnchant({"Determination","Looter V"}, {"Determination","Looter V"}, "Shadow Crystal", "Gems") end})
