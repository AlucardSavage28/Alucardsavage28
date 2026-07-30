repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local EnchantTab = Window:CreateTab("Enchant", nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)
local Remote = require(ReplicatedStorage.Shared.Framework.Network.Remote)

-- ======================================
-- MANUAL ENCHANT SETTINGS
-- ======================================
local slot1Enchant = "secret-hunter"
local slot2Enchant = "secret-hunter"
local slot1Running = false
local slot1Thread = nil
local slot2Running = false
local slot2Thread = nil
local useShadowCrystal1 = false
local useShadowCrystal2 = false

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

local function getEquippedShinyPet()
    local data = LocalData:Get()
    if data and data.Teams then
        local teamNum = data.TeamEquipped or 1
        local team = data.Teams[teamNum]
        if team and team.Pets then
            for _, pet in ipairs(team.Pets) do
                if pet.Shiny then
                    return pet
                end
            end
        end
    end
    return nil
end

local function getPetEnchants(pet)
    local enchants = {}
    if pet and pet.Enchants then
        for slot, enchant in ipairs(pet.Enchants) do
            enchants[slot] = enchant.Id or enchant.id or nil
        end
    end
    return enchants
end

local function getEnchantUI()
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        local screenGui = playerGui:FindFirstChild("ScreenGui")
        if screenGui then
            return screenGui:FindFirstChild("Enchants")
        end
    end
    return nil
end

local function clickLock(slot)
    local ui = getEnchantUI()
    if not ui then return false end
    local enchants = ui:FindFirstChild("Frame") and ui.Frame:FindFirstChild("Inner") and ui.Frame.Inner:FindFirstChild("Details") and ui.Frame.Inner.Details:FindFirstChild("Main") and ui.Frame.Inner.Details.Main:FindFirstChild("Enchants")
    if enchants then
        local enchantFrame = enchants:FindFirstChild("Enchant" .. slot)
        if enchantFrame then
            local lock = enchantFrame:FindFirstChild("Lock")
            if lock then
                local button = lock:FindFirstChild("Button")
                if button then
                    firesignal(button.Activated)
                    return true
                end
            end
        end
    end
    return false
end

local function isSlotLocked(slot)
    local ui = getEnchantUI()
    if not ui then return false end
    local enchants = ui:FindFirstChild("Frame") and ui.Frame:FindFirstChild("Inner") and ui.Frame.Inner:FindFirstChild("Details") and ui.Frame.Inner.Details:FindFirstChild("Main") and ui.Frame.Inner.Details.Main:FindFirstChild("Enchants")
    if enchants then
        local enchantFrame = enchants:FindFirstChild("Enchant" .. slot)
        if enchantFrame then
            local lock = enchantFrame:FindFirstChild("Lock")
            if lock then
                local icon = lock:FindFirstChild("Icon")
                return icon and icon.Visible
            end
        end
    end
    return false
end

-- ======================================
-- UI - MANUAL ENCHANT
-- ======================================
EnchantTab:CreateSection("Manual Enchant")

-- Slot 1
EnchantTab:CreateDropdown({
    Name = "Slot 1 Enchant",
    Options = ALL_ENCHANTS,
    CurrentOption = {"secret-hunter"},
    Callback = function(v)
        slot1Enchant = v[1]
    end
})

EnchantTab:CreateToggle({
    Name = "Use Shadow Crystal (Slot 1)",
    CurrentValue = false,
    Callback = function(v)
        useShadowCrystal1 = v
    end
})

EnchantTab:CreateToggle({
    Name = "Auto Enchant Slot 1",
    CurrentValue = false,
    Callback = function(v)
        slot1Running = v
        if v then
            slot1Thread = task.spawn(function()
                if not isSlotLocked(2) then
                    clickLock(2)
                    task.wait(0.3)
                end
                
                while slot1Running do
                    local pet = getEquippedShinyPet()
                    if pet then
                        local enchants = getPetEnchants(pet)
                        if enchants[1] == slot1Enchant then
                            print("[Enchant] Slot 1 done! Got " .. ENCHANT_DISPLAY[slot1Enchant])
                            slot1Running = false
                        else
                            if useShadowCrystal1 then
                                pcall(function() Remote:FireServer("UseShadowCrystal", pet.Id, nil) end)
                            else
                                pcall(function() Remote:InvokeServer("RerollEnchants", pet.Id, "Gems", nil) end)
                            end
                            task.wait(1.5)
                        end
                    end
                    task.wait(0.5)
                end
            end)
        else
            if slot1Thread then task.cancel(slot1Thread) end
        end
    end
})

-- Slot 2
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
        useShadowCrystal2 = v
    end
})

EnchantTab:CreateToggle({
    Name = "Auto Enchant Slot 2",
    CurrentValue = false,
    Callback = function(v)
        slot2Running = v
        if v then
            slot2Thread = task.spawn(function()
                while slot1Running do
                    task.wait(0.5)
                end
                
                if not isSlotLocked(1) then
                    clickLock(1)
                    task.wait(0.3)
                end
                
                while slot2Running do
                    local pet = getEquippedShinyPet()
                    if pet then
                        local enchants = getPetEnchants(pet)
                        if enchants[2] == slot2Enchant then
                            print("[Enchant] Slot 2 done! Got " .. ENCHANT_DISPLAY[slot2Enchant])
                            slot2Running = false
                        else
                            if useShadowCrystal2 then
                                pcall(function() Remote:FireServer("UseShadowCrystal", pet.Id, nil) end)
                            else
                                pcall(function() Remote:InvokeServer("RerollEnchants", pet.Id, "Gems", nil) end)
                            end
                            task.wait(1.5)
                        end
                    end
                    task.wait(0.5)
                end
            end)
        else
            if slot2Thread then task.cancel(slot2Thread) end
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
        RunEnchant(
            {"Secret Hunter","Ultra Roller"},
            {"Secret Hunter","Ultra Roller"},
            "Shadow Crystal",
            "Shadow Crystal"
        )
    end
})

EnchantTab:CreateButton({
    Name = "Ultra Roller + High Roller",
    Callback = function()
        RunEnchant(
            {"High Roller","Ultra Roller"},
            {"High Roller","Ultra Roller"},
            "Shadow Crystal",
            "Gems"
        )
    end
})

EnchantTab:CreateButton({
    Name = "Shiny Seeker + Ultra Roller",
    Callback = function()
        RunEnchant(
            {"Shiny Seeker","Ultra Roller"},
            {"Shiny Seeker","Ultra Roller"},
            "Shadow Crystal",
            "Shadow Crystal"
        )
    end
})

-- ======================================
-- BUBBLER ENCHANTER
-- ======================================
EnchantTab:CreateSection("Bubbler Enchanter")

EnchantTab:CreateButton({
    Name = "Team Up V + Bubbler V",
    Callback = function()
        RunEnchant(
            {"Team Up V","Bubbler V"},
            {"Team Up V","Bubbler V"},
            "Gems",
            "Gems"
        )
    end
})

EnchantTab:CreateButton({
    Name = "Determination + Bubbler V",
    Callback = function()
        RunEnchant(
            {"Determination","Bubbler V"},
            {"Determination","Bubbler V"},
            "Shadow Crystal",
            "Gems"
        )
    end
})

-- ======================================
-- CURRENCY ENCHANTER
-- ======================================
EnchantTab:CreateSection("Currency Enchanter")

EnchantTab:CreateButton({
    Name = "Team Up V + Looter V",
    Callback = function()
        RunEnchant(
            {"Team Up V","Looter V"},
            {"Team Up V","Looter V"},
            "Gems",
            "Gems"
        )
    end
})

EnchantTab:CreateButton({
    Name = "Determination + Looter V",
    Callback = function()
        RunEnchant(
            {"Determination","Looter V"},
            {"Determination","Looter V"},
            "Shadow Crystal",
            "Gems"
        )
    end
})
