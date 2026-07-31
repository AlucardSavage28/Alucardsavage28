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
-- MANUAL ENCHANT SETTINGS
-- ======================================
local slot1Enchant = "secret-hunter"
local slot2Enchant = "secret-hunter"
local useShadowCrystal = false
local enchantRunning = false
local enchantThread = nil

local ALL_ENCHANTS = {
    "secret-hunter", "bubbler", "infinity", "high-roller", "magnetism",
    "looter", "determination", "team-up", "ultra-roller", "shiny-seeker"
}

local ENCHANT_DISPLAY = {
    ["secret-hunter"] = "Secret Hunter",
    ["bubbler"] = "Bubbler",
    ["infinity"] = "Infinity",
    ["high-roller"] = "High Roller",
    ["magnetism"] = "Magnetism",
    ["looter"] = "Looter",
    ["determination"] = "Determination",
    ["team-up"] = "Team Up",
    ["ultra-roller"] = "Ultra Roller",
    ["shiny-seeker"] = "Shiny Seeker",
}

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

local function getSlotEnchantId(pet, slot)
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
    CurrentOption = {"secret-hunter"},
    Callback = function(v)
        slot1Enchant = v[1]
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
    Name = "Use Shadow Crystal",
    CurrentValue = false,
    Callback = function(v)
        useShadowCrystal = v
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
                    print("[Enchant] Pet " .. i .. ": " .. pet.Name)
                    
                    -- Enchant Slot 1
                    while enchantRunning do
                        local data = LocalData:Get()
                        local currentPet = nil
                        if data and data.Pets then
                            for _, p in pairs(data.Pets) do
                                if p.Id == pet.Id then currentPet = p; break end
                            end
                        end
                        local current = getSlotEnchantId(currentPet, 1)
                        if current == slot1Enchant then
                            print("[Enchant] Slot 1 done: " .. ENCHANT_DISPLAY[slot1Enchant])
                            break
                        end
                        if useShadowCrystal then
                            pcall(function() RE:FireServer("UseShadowCrystal", pet.Id, 1) end)
                        else
                            pcall(function() Remote:InvokeServer("RerollEnchants", pet.Id, "Gems", nil) end)
                        end
                        task.wait(1)
                    end
                    
                    -- Enchant Slot 2
                    while enchantRunning do
                        local data = LocalData:Get()
                        local currentPet = nil
                        if data and data.Pets then
                            for _, p in pairs(data.Pets) do
                                if p.Id == pet.Id then currentPet = p; break end
                            end
                        end
                        local current = getSlotEnchantId(currentPet, 2)
                        if current == slot2Enchant then
                            print("[Enchant] Slot 2 done: " .. ENCHANT_DISPLAY[slot2Enchant])
                            break
                        end
                        if useShadowCrystal then
                            pcall(function() RE:FireServer("UseShadowCrystal", pet.Id, 2) end)
                        else
                            pcall(function() Remote:InvokeServer("RerollEnchants", pet.Id, "Gems", nil) end)
                        end
                        task.wait(1)
                    end
                    
                    task.wait(0.3)
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
