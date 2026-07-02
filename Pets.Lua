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
-- GET UNLOCKED PETS
-- ======================================
local function getUnlockedPets()
    local pets = {}
    local seen = {}
    local data = LocalData:Get()
    if data and data.Pets then
        for _, pet in pairs(data.Pets) do
            if pet.Name and not pet.Locked and not seen[pet.Name] then
                seen[pet.Name] = true
                table.insert(pets, pet.Name)
            end
        end
    end
    table.sort(pets)
    return pets
end

-- ======================================
-- SETTINGS
-- ======================================
local petList = getUnlockedPets()
local selectedPet1 = petList[1] or ""
local selectedPet2 = petList[1] or ""
local selectedPet3 = petList[1] or ""
local fuserActive = false
local loopThread = nil

-- ======================================
-- FUNCTIONS
-- ======================================
local function getVariantPriority(pet)
    if pet.Shiny and pet.Mythic then return 4
    elseif pet.Mythic and not pet.Shiny then return 3
    elseif pet.Shiny and not pet.Mythic then return 2
    else return 1 end
end

local function tryFuse(petName)
    local data = LocalData:Get()
    if not data or not data.Pets then return false end
    
    local matching = {}
    for _, pet in pairs(data.Pets) do
        if pet.Name == petName and not pet.Locked then
            table.insert(matching, pet)
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
        return true
    end
    return false
end

local function fusionLoop()
    while fuserActive do
        local fused = false
        
        for _, petName in ipairs({selectedPet1, selectedPet2, selectedPet3}) do
            if petName ~= "" and tryFuse(petName) then
                fused = true
                task.wait(1.5)
                break
            end
        end
        
        if not fused then
            task.wait(5)
        end
    end
end

-- ======================================
-- UI
-- ======================================
PetTab:CreateSection("Rebirth Machine")

PetTab:CreateDropdown({
    Name = "Pet 1",
    Options = petList,
    CurrentOption = {selectedPet1},
    Callback = function(v)
        selectedPet1 = v[1] or v
    end
})

PetTab:CreateDropdown({
    Name = "Pet 2",
    Options = petList,
    CurrentOption = {selectedPet2},
    Callback = function(v)
        selectedPet2 = v[1] or v
    end
})

PetTab:CreateDropdown({
    Name = "Pet 3",
    Options = petList,
    CurrentOption = {selectedPet3},
    Callback = function(v)
        selectedPet3 = v[1] or v
    end
})

PetTab:CreateToggle({
    Name = "Auto Rebirth Machine",
    CurrentValue = false,
    Callback = function(v)
        fuserActive = v
        if v then
            loopThread = task.spawn(fusionLoop)
        else
            if loopThread then
                task.cancel(loopThread)
                loopThread = nil
            end
        end
    end
})
