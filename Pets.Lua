repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local PetTab = Window:CreateTab("Pets", nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)

local NetworkRemote = ReplicatedStorage:WaitForChild("Shared")
    :WaitForChild("Framework")
    :WaitForChild("Network")
    :WaitForChild("Remote")
    :WaitForChild("RemoteFunction")

-- ======================================
-- SETTINGS
-- ======================================
local fuserActive = false
local loopThread = nil
local targetPetNamesString = ""
local selectedVariant = "Normal"

-- ======================================
-- FUNCTIONS
-- ======================================
local function isCorrectVariant(pet)
    if selectedVariant == "Shiny Mythic" then
        return (pet.Shiny and pet.Mythic)
    elseif selectedVariant == "Shiny" then
        return pet.Shiny and not pet.Mythic
    elseif selectedVariant == "Mythic" then
        return pet.Mythic and not pet.Shiny
    else
        return not pet.Shiny and not pet.Mythic
    end
end

local function getVariantPriority(pet)
    if pet.Shiny and pet.Mythic then return 4
    elseif pet.Mythic and not pet.Shiny then return 3
    elseif pet.Shiny and not pet.Mythic then return 2
    else return 1 end
end

local function fusionLoop()
    while fuserActive do
        task.wait(2.5)
        
        if targetPetNamesString == "" then continue end
        
        local targetNames = {}
        for chunk in string.gmatch(targetPetNamesString, "[^,]+") do
            local clean = string.lower(string.gsub(chunk, "^%s*(.-)%s*$", "%1"))
            if clean ~= "" then table.insert(targetNames, clean) end
        end
        
        local data = LocalData:Get()
        if not data or not data.Pets then continue end
        
        local matching = {}
        for _, pet in pairs(data.Pets) do
            if not pet.Locked then
                if isCorrectVariant(pet) then
                    local name = string.lower(pet.Name)
                    for _, t in ipairs(targetNames) do
                        if name:find(t) then
                            table.insert(matching, pet)
                            break
                        end
                    end
                end
            end
        end
        
        if #matching >= 5 then
            table.sort(matching, function(a, b)
                return getVariantPriority(a) < getVariantPriority(b)
            end)
            
            local payload = {}
            for i = 1, 5 do
                table.insert(payload, tostring(matching[i].Id))
            end
            
            pcall(function()
                NetworkRemote:InvokeServer("UseRebirthMachine", payload)
            end)
            task.wait(1.5)
        end
    end
end

-- ======================================
-- UI
-- ======================================
PetTab:CreateSection("Rebirth Machine")

PetTab:CreateInput({
    Name = "Pet Names (comma)",
    PlaceholderText = "doggy, cat, ufo",
    CurrentValue = "",
    Callback = function(V)
        targetPetNamesString = V
    end,
})

PetTab:CreateDropdown({
    Name = "Variant",
    Options = {"Normal","Shiny","Mythic","Shiny Mythic"},
    CurrentOption = {"Normal"},
    Callback = function(V)
        selectedVariant = V[1]
    end,
})

PetTab:CreateToggle({
    Name = "Auto Rebirth Machine",
    CurrentValue = false,
    Callback = function(V)
        fuserActive = V
        if V then
            loopThread = task.spawn(fusionLoop)
        else
            fuserActive = false
            if loopThread then
                task.cancel(loopThread)
                loopThread = nil
            end
        end
    end,
})
