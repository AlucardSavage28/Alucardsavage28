repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local EnchantTab = Window:CreateTab("Enchant", nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)
local Remote = require(ReplicatedStorage.Shared.Framework.Network.Remote)
local Enchants = require(ReplicatedStorage.Client.Gui.Frames.Enchants)

-- ======================================
-- MANUAL ENCHANT SETTINGS
-- ======================================
local slot1Enchant = "Shiny Seeker"
local slot2Enchant = "Shiny Seeker"
local slot1Running = false
local slot1Thread = nil
local slot2Running = false
local slot2Thread = nil
local useShadowCrystal1 = false
local useShadowCrystal2 = false
local enchantAllRunning = false
local enchantAllThread = nil

local ALL_ENCHANTS_DISPLAY = {
    "Secret Hunter", "Bubbler", "Infinity", "High Roller", "Magnetism",
    "Looter", "Determination", "Team Up", "Ultra Roller", "Shiny Seeker"
}

-- ======================================
-- FUNCTIONS
-- ======================================
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

local function getCurrentEnchants()
    local enchants = {}
    local ui = getEnchantUI()
    if ui then
        local enchant1 = ui:FindFirstChild("Frame") and ui.Frame:FindFirstChild("Inner") and ui.Frame.Inner:FindFirstChild("Details") and ui.Frame.Inner.Details:FindFirstChild("Main") and ui.Frame.Inner.Details.Main:FindFirstChild("Enchants") and ui.Frame.Inner.Details.Main.Enchants:FindFirstChild("Enchant1")
        if enchant1 then
            local title = enchant1:FindFirstChild("Title")
            if title and title.Text ~= "(empty slot)" then
                -- Strip emoji and clean
                local text = title.Text:gsub("[%z\1-\127\194-\244][\128-\191]*", ""):match("%s*(.+)") or title.Text
                text = text:gsub("^%s+", ""):gsub("%s+$", "")
                enchants[1] = text
            end
        end
        
        local enchant2 = ui:FindFirstChild("Frame") and ui.Frame:FindFirstChild("Inner") and ui.Frame.Inner:FindFirstChild("Details") and ui.Frame.Inner.Details:FindFirstChild("Main") and ui.Frame.Inner.Details.Main:FindFirstChild("Enchants") and ui.Frame.Inner.Details.Main.Enchants:FindFirstChild("Enchant2")
        if enchant2 then
            local title = enchant2:FindFirstChild("Title")
            if title and title.Text ~= "(empty slot)" then
                local text = title.Text:gsub("[%z\1-\127\194-\244][\128-\191]*", ""):match("%s*(.+)") or title.Text
                text = text:gsub("^%s+", ""):gsub("%s+$", "")
                enchants[2] = text
            end
        end
    end
    return enchants
end

local function clickChangePet()
    local ui = getEnchantUI()
    if ui then
        local changeBtn = ui:FindFirstChild("Frame") and ui.Frame:FindFirstChild("Inner") and ui.Frame.Inner:FindFirstChild("Details") and ui.Frame.Inner.Details:FindFirstChild("Main") and ui.Frame.Inner.Details.Main:FindFirstChild("Change") and ui.Frame.Inner.Details.Main.Change:FindFirstChild("Button")
        if changeBtn then
            firesignal(changeBtn.Activated)
            return true
        end
    end
    return false
end

local function clickPetInList(petId)
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        local screenGui = playerGui:FindFirstChild("ScreenGui")
        if screenGui then
            local prompt = screenGui:FindFirstChild("PetChoosePrompt")
            if prompt then
                local list = prompt:FindFirstChild("Frame") and prompt.Frame:FindFirstChild("Inner") and prompt.Frame.Inner:FindFirstChild("Pets") and prompt.Frame.Inner.Pets:FindFirstChild("ScrollingFrame") and prompt.Frame.Inner.Pets.ScrollingFrame:FindFirstChild("Team") and prompt.Frame.Inner.Pets.ScrollingFrame.Team:FindFirstChild("Main") and prompt.Frame.Inner.Pets.ScrollingFrame.Team.Main:FindFirstChild("List")
                if list then
                    -- Search for frame containing this pet ID
                    for _, child in ipairs(list:GetChildren()) do
                        if child.Name:find(petId) then
                            local button = child:FindFirstChild("Inner") and child.Inner:FindFirstChild("Button")
                            if button then
                                firesignal(button.Activated)
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    return false
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

local function enchantSingleSlot(slot, targetEnchant, useShadow)
    while true do
        local enchants = getCurrentEnchants()
        local current = enchants[slot]
        
        if current and current:find(targetEnchant, 1, true) then
            print("[Enchant] Slot " .. slot .. " done! Got " .. current)
            return true
        end
        
        local pet = getEquippedPets()
        if #pet > 0 then
            if useShadow then
                pcall(function() Remote:FireServer("UseShadowCrystal", pet[1].Id, nil) end)
            else
                pcall(function() Remote:InvokeServer("RerollEnchants", pet[1].Id, "Gems", nil) end)
            end
            task.wait(2)
        end
    end
end

-- ======================================
-- UI - MANUAL ENCHANT
-- ======================================
EnchantTab:CreateSection("Manual Enchant")

-- Slot 1
EnchantTab:CreateDropdown({
    Name = "Slot 1 Enchant",
    Options = ALL_ENCHANTS_DISPLAY,
    CurrentOption = {"Shiny Seeker"},
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
                if not clickLock(2) then
                    task.wait(0.3)
                end
                enchantSingleSlot(1, slot1Enchant, useShadowCrystal1)
                slot1Running = false
            end)
        else
            if slot1Thread then task.cancel(slot1Thread) end
        end
    end
})

-- Slot 2
EnchantTab:CreateDropdown({
    Name = "Slot 2 Enchant",
    Options = ALL_ENCHANTS_DISPLAY,
    CurrentOption = {"Shiny Seeker"},
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
                while slot1Running do task.wait(0.5) end
                if not clickLock(1) then
                    task.wait(0.3)
                end
                enchantSingleSlot(2, slot2Enchant, useShadowCrystal2)
                slot2Running = false
            end)
        else
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
                    
                    -- Open enchant UI and select pet
                    Enchants:PromptSelectPet()
                    task.wait(0.5)
                    
                    -- Click Change Pet then select the right pet
                    clickChangePet()
                    task.wait(0.5)
                    clickPetInList(pet.Id)
                    task.wait(0.8)
                    
                    -- Enchant Slot 1
                    if not clickLock(2) then task.wait(0.3) end
                    enchantSingleSlot(1, slot1Enchant, useShadowCrystal1)
                    
                    -- Enchant Slot 2
                    if not clickLock(1) then task.wait(0.3) end
                    enchantSingleSlot(2, slot2Enchant, useShadowCrystal2)
                    
                    task.wait(0.5)
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
