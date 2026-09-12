-- ================================================
-- ENCHANT TAB (WINDUI VERSION)
-- ================================================
repeat task.wait() until getgenv().Window
local Window = getgenv().Window
local WindUI = getgenv().WindUI

local EnchantTab = Window:Tab({ Title = "Enchant", Icon = "sparkles" })

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)
local Pets = require(ReplicatedStorage.Shared.Data.Pets)

local RemoteContainer = ReplicatedStorage.Shared.Framework.Network.Remote
local RemoteFunction = RemoteContainer.RemoteFunction
local RemoteEvent = RemoteContainer.RemoteEvent

-- ======================================
-- LOAD SAVED SETTINGS
-- ======================================
local settings = getgenv().HubSettings or {}
if not settings.enchant then settings.enchant = {} end
local enchantSettings = settings.enchant

-- ======================================
-- SETTINGS
-- ======================================
local TARGET_ENCHANTS = {
    { Id = enchantSettings.slot1 or "ultra-roller" },
    { Id = enchantSettings.slot2 or "secret-hunter" }
}
local COOLDOWN = 0.5
local enchantRunning = false
local enchantThread = nil
local monitorRunning = false
local monitorThread = nil

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
                if pet and isPetEnchantable(pet) then
                    table.insert(pets, pet)
                end
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
            return true
        end
        
        local otherSlot = (targetSlot == 1) and 2 or 1
        local otherEnchant = (pet.Enchants or {})[otherSlot]
        if otherEnchant and otherEnchant.Id == targetEnchantId then
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

local function checkEnchantStatus()
    local pets = getEquippedPets()
    local missing = {slot1 = 0, slot2 = 0}
    
    for _, pet in ipairs(pets) do
        local enchants = pet.Enchants or {}
        
        local slot1Enchant = enchants[1]
        if not (slot1Enchant and slot1Enchant.Id == TARGET_ENCHANTS[1].Id) then
            missing.slot1 = missing.slot1 + 1
        end
        
        local slot2Enchant = enchants[2]
        if not (slot2Enchant and slot2Enchant.Id == TARGET_ENCHANTS[2].Id) then
            missing.slot2 = missing.slot2 + 1
        end
    end
    
    return missing
end

local function reEnchantMissingSlots(missing)
    local pets = getEquippedPets()
    if #pets == 0 then return end
    
    if missing.slot1 > 0 then
        for i, pet in ipairs(pets) do
            if not enchantRunning then break end
            local enchants = pet.Enchants or {}
            local slot1Enchant = enchants[1]
            if not (slot1Enchant and slot1Enchant.Id == TARGET_ENCHANTS[1].Id) then
                enchantSingleSlot(pet.Id, 1, TARGET_ENCHANTS[1].Id)
                task.wait(0.5)
            end
        end
    end
    
    if missing.slot2 > 0 then
        for i, pet in ipairs(pets) do
            if not enchantRunning then break end
            local enchants = pet.Enchants or {}
            local slot2Enchant = enchants[2]
            if not (slot2Enchant and slot2Enchant.Id == TARGET_ENCHANTS[2].Id) then
                enchantSingleSlot(pet.Id, 2, TARGET_ENCHANTS[2].Id)
                task.wait(0.5)
            end
        end
    end
end

local function startMonitor()
    while monitorRunning do
        task.wait(10)
        
        if enchantRunning then
            local missing = checkEnchantStatus()
            if missing.slot1 > 0 or missing.slot2 > 0 then
                reEnchantMissingSlots(missing)
            end
        end
    end
end

-- ======================================
-- ENCHANT RUNNER (reusable for callback + auto-start)
-- ======================================
local function startEnchant()
    if enchantRunning then return end
    enchantRunning = true
    monitorRunning = true
    
    getgenv().ActivityStatus.current = "Auto Enchanting with " .. ENCHANT_DISPLAY[TARGET_ENCHANTS[1].Id] .. " + " .. ENCHANT_DISPLAY[TARGET_ENCHANTS[2].Id]
    getgenv().ActivityStatus.trigger = true
    
    monitorThread = task.spawn(startMonitor)
    
    enchantThread = task.spawn(function()
        local pets = getEquippedPets()
        
        for i, pet in ipairs(pets) do
            if not enchantRunning then break end
            enchantSingleSlot(pet.Id, 1, TARGET_ENCHANTS[1].Id)
            if i < #pets then task.wait(0.5) end
        end
        
        if enchantRunning then
            for i, pet in ipairs(pets) do
                if not enchantRunning then break end
                enchantSingleSlot(pet.Id, 2, TARGET_ENCHANTS[2].Id)
                if i < #pets then task.wait(0.5) end
            end
        end
    end)
end

local function stopEnchant()
    enchantRunning = false
    monitorRunning = false
    if enchantThread then task.cancel(enchantThread); enchantThread = nil end
    if monitorThread then task.cancel(monitorThread); monitorThread = nil end
end

-- ======================================
-- UI
-- ======================================
EnchantTab:Section({ Title = "Manual Enchant" })

EnchantTab:Paragraph({
    Title = "Smart Currency",
    Desc = "Auto-detects Shadow Crystal or Gems based on enchant type.",
})

EnchantTab:Paragraph({
    Title = "⚠️ Warning",
    Desc = "Make sure to check your Pets Enchant. If Secret Hunter is in Slot 1 but some pets already have it on Slot 2, it will roll endlessly!",
})

EnchantTab:Dropdown({
    Title = "Slot 1 Enchant",
    Values = ALL_ENCHANTS,
    Value = TARGET_ENCHANTS[1].Id,
    Callback = function(v)
        TARGET_ENCHANTS[1].Id = v
        enchantSettings.slot1 = v
        getgenv().HubSettings.enchant = enchantSettings
        saveHubSettings()
    end,
})

EnchantTab:Dropdown({
    Title = "Slot 2 Enchant",
    Values = ALL_ENCHANTS,
    Value = TARGET_ENCHANTS[2].Id,
    Callback = function(v)
        TARGET_ENCHANTS[2].Id = v
        enchantSettings.slot2 = v
        getgenv().HubSettings.enchant = enchantSettings
        saveHubSettings()
    end,
})

EnchantTab:Toggle({
    Title = "Auto Enchant All Equipped (Monitor Mode)",
    Desc = "Continuously monitors and re-enchants pets when enchants are lost",
    Value = enchantSettings.autoEnchant or false,
    Callback = function(v)
        enchantSettings.autoEnchant = v
        getgenv().HubSettings.enchant = enchantSettings
        saveHubSettings()
        if v then
            startEnchant()
        else
            stopEnchant()
        end
    end,
})

-- ======================================
-- SIMPLE ENCHANT (PRESETS)
-- ======================================
EnchantTab:Section({ Title = "Simple Enchant" })

EnchantTab:Paragraph({
    Title = "Presets",
    Desc = "If you use these, wait until it finishes enchanting and check your Shadow Crystal count.",
})

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

EnchantTab:Button({
    Title = "Secret Hunter + Ultra Roller",
    Desc = "Shadow Crystal + Shadow Crystal",
    Callback = function()
        RunEnchant({"Secret Hunter","Ultra Roller"}, {"Secret Hunter","Ultra Roller"}, "Shadow Crystal", "Shadow Crystal")
    end,
})

EnchantTab:Button({
    Title = "Ultra Roller + High Roller",
    Desc = "Shadow Crystal + Gems",
    Callback = function()
        RunEnchant({"High Roller","Ultra Roller"}, {"High Roller","Ultra Roller"}, "Shadow Crystal", "Gems")
    end,
})

EnchantTab:Button({
    Title = "Shiny Seeker + Ultra Roller",
    Desc = "Shadow Crystal + Shadow Crystal",
    Callback = function()
        RunEnchant({"Shiny Seeker","Ultra Roller"}, {"Shiny Seeker","Ultra Roller"}, "Shadow Crystal", "Shadow Crystal")
    end,
})

EnchantTab:Section({ Title = "Bubbler Enchanter" })

EnchantTab:Button({
    Title = "Team Up V + Bubbler V",
    Desc = "Gems + Gems",
    Callback = function()
        RunEnchant({"Team Up V","Bubbler V"}, {"Team Up V","Bubbler V"}, "Gems", "Gems")
    end,
})

EnchantTab:Button({
    Title = "Determination + Bubbler V",
    Desc = "Shadow Crystal + Gems",
    Callback = function()
        RunEnchant({"Determination","Bubbler V"}, {"Determination","Bubbler V"}, "Shadow Crystal", "Gems")
    end,
})

EnchantTab:Section({ Title = "Currency Enchanter" })

EnchantTab:Button({
    Title = "Team Up V + Looter V",
    Desc = "Gems + Gems",
    Callback = function()
        RunEnchant({"Team Up V","Looter V"}, {"Team Up V","Looter V"}, "Gems", "Gems")
    end,
})

EnchantTab:Button({
    Title = "Determination + Looter V",
    Desc = "Shadow Crystal + Gems",
    Callback = function()
        RunEnchant({"Determination","Looter V"}, {"Determination","Looter V"}, "Shadow Crystal", "Gems")
    end,
})

-- ======================================
-- AUTO-START SAVED TOGGLES
-- ======================================
task.spawn(function()
    task.wait(1.5)
    
    -- Auto Enchant (Monitor Mode)
    if enchantSettings.autoEnchant then
        startEnchant()
    end
    
    print("[Enchant] Auto-started saved toggles!")
end)

print("[Enchant] Loaded!")
