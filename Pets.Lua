repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local PetTab = Window:CreateTab("Pets", nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)
local Pets = require(ReplicatedStorage.Shared.Data.Pets)

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

local fuseAllActive = false
local fuseAllThread = nil

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
                NetworkRemote:InvokeServer("UseRebirthMachine", "RebirthMachine", payload)
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

PetTab:CreateSection("Rebirth Machine (All Unlocked)")

PetTab:CreateLabel("Testing, Make sure to Lock all Valuable Pets before execute this")

local trackerLabel = PetTab:CreateLabel("Last Used: None")

PetTab:CreateToggle({
    Name = "Auto Rebirth Machine (All Unlocked Pets)",
    CurrentValue = false,
    Callback = function(V)
        fuseAllActive = V
        if V then
            pcall(function() trackerLabel:SetText("Last Used: None") end)
            fuseAllThread = task.spawn(function()
                local lastPrint = ""
                local wasActive = false
                while fuseAllActive do
                    task.wait(5)
                    
                    local data = LocalData:Get()
                    if not data or not data.Pets then
                        wasActive = false
                        continue
                    end
                    
                    local groups = {Normal = {}, Shiny = {}, Mythic = {}, ShinyMythic = {}}
                    for _, pet in pairs(data.Pets) do
                        if not pet.Locked then
                            local info = Pets[pet.Name]
                            if info and info.Rarity and info.Rarity:find("Secret") then
                                if pet.Shiny and pet.Mythic then
                                    table.insert(groups.ShinyMythic, pet)
                                elseif pet.Shiny then
                                    table.insert(groups.Shiny, pet)
                                elseif pet.Mythic then
                                    table.insert(groups.Mythic, pet)
                                else
                                    table.insert(groups.Normal, pet)
                                end
                            end
                        end
                    end
                    
                    local selectedGroup = nil
                    if #groups.Normal >= 5 then selectedGroup = groups.Normal
                    elseif #groups.Shiny >= 5 then selectedGroup = groups.Shiny
                    elseif #groups.Mythic >= 5 then selectedGroup = groups.Mythic
                    elseif #groups.ShinyMythic >= 5 then selectedGroup = groups.ShinyMythic
                    end
                    
                    if selectedGroup then
                        local beforeCount = 0
                        for _, _ in pairs(data.Pets) do beforeCount = beforeCount + 1 end
                        
                        local payload = {}
                        local usedWithVariant = {}
                        for i = 1, 5 do
                            local pet = selectedGroup[i]
                            table.insert(payload, tostring(pet.Id))
                            local variant = "Normal"
                            if pet.Shiny and pet.Mythic then variant = "Shiny Mythic"
                            elseif pet.Shiny then variant = "Shiny"
                            elseif pet.Mythic then variant = "Mythic" end
                            table.insert(usedWithVariant, variant .. " " .. pet.Name)
                        end
                        
                        local text = table.concat(usedWithVariant, ", ")
                        
                        pcall(function() trackerLabel:SetText("Last Used: " .. text) end)
                        
                        pcall(function()
                            NetworkRemote:InvokeServer("UseRebirthMachine", "RebirthMachine", payload)
                        end)
                        
                        task.wait(1.5)
                        
                        local data2 = LocalData:Get()
                        local afterCount = 0
                        if data2 and data2.Pets then
                            for _, _ in pairs(data2.Pets) do afterCount = afterCount + 1 end
                        end
                        
                        if afterCount < beforeCount then
                            if not wasActive then
                                getgenv().ActivityStatus.current = "Rebirth Machine used: " .. text
                                getgenv().ActivityStatus.trigger = true
                                wasActive = true
                            end
                            
                            if text ~= lastPrint then
                                print("[Rebirth] " .. text)
                                lastPrint = text
                            end
                        else
                            wasActive = false
                        end
                    else
                        wasActive = false
                    end
                end
            end)
        else
            fuseAllActive = false
            if fuseAllThread then
                task.cancel(fuseAllThread)
                fuseAllThread = nil
            end
        end
    end,
})
