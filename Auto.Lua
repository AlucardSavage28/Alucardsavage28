-- ================================================
-- AUTO TAB (PRESENT RAIN + BUBBLE + SELL + ORB + PICKUP + BOX)
-- ================================================
repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local AutoTab = Window:CreateTab("Auto", nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local constants = require(ReplicatedStorage.Shared.Constants)
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)

local RE = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteEvent

local function fire(action, ...)
    if RE then RE:FireServer(action, ...) end
end

-- ======================================
-- SETTINGS
-- ======================================
local presentEnabled = false
local bubbleEnabled = false
local sellEnabled = false
local powerOrbEnabled = false
local orbEnabled = false
local pickupEnabled = false
local boxEnabled = false
local presentThread = nil
local bubbleThread = nil
local sellThread = nil
local powerOrbThread = nil
local orbThread = nil
local boxThread = nil

local originalRadius = constants.DefaultPickupRadius
local BUBBLE_CAP = 650000000
local RETURN_POS = Vector3.new(-3583, 161, 914)

-- ======================================
-- GET BOXES FROM INVENTORY
-- ======================================
local function getBoxes()
    local boxes = {}
    local data = LocalData:Get()
    if data and data.Powerups then
        for name, amount in pairs(data.Powerups) do
            if (name:find("Box") or name:find("Crate") or name:find("Giftbox") or name:find("Present")) and amount > 0 then
                table.insert(boxes, name)
            end
        end
    end
    if #boxes == 0 then
        boxes = {"Mystery Box", "Golden Crate", "Wooden Crate"}
    end
    table.sort(boxes)
    return boxes
end

local boxList = getBoxes()
local selectedBox = boxList[1] or "Mystery Box"

-- ======================================
-- FUNCTIONS
-- ======================================
local function getRoot()
    local char = player.Character
    if char then return char:FindFirstChild("HumanoidRootPart") end
end

local function getBubbles()
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        for _, stat in ipairs(leaderstats:GetChildren()) do
            if stat.Name:find("Bubble") then
                return tonumber(stat.Value) or 0
            end
        end
    end
    return 0
end

local function getSellPosition()
    local overworld = workspace.Worlds["The Overworld"]
    if overworld then
        local sell = overworld:FindFirstChild("Sell")
        if sell then
            local ring = sell:FindFirstChild("Ring")
            if ring then
                return ring.Position
            end
        end
    end
    return Vector3.new(77, 6, -113)
end

local function collectAllPresents()
    local rendered = workspace:FindFirstChild("Rendered")
    if not rendered then return 0 end
    
    local presentRain = rendered:FindFirstChild("PresentRain")
    if not presentRain then return 0 end
    
    local root = getRoot()
    local previousPos = root and root.Position or nil
    
    local collected = 0
    for _, model in ipairs(presentRain:GetChildren()) do
        if model:IsA("Model") then
            for _, part in ipairs(model:GetChildren()) do
                if part:IsA("BasePart") then
                    local root = getRoot()
                    if root then
                        root.CFrame = CFrame.new(part.Position + Vector3.new(0, 2, 0))
                        collected = collected + 1
                        task.wait(0.02)
                    end
                    break
                end
            end
        end
    end
    
    if previousPos then
        local root = getRoot()
        if root then
            root.CFrame = CFrame.new(previousPos)
        end
    end
    
    return collected
end

-- ======================================
-- UI - PRESENT RAIN
-- ======================================
AutoTab:CreateSection("Present Rain")

AutoTab:CreateToggle({
    Name = "Auto Collect Presents",
    CurrentValue = false,
    Callback = function(v)
        presentEnabled = v
        if v then
            presentThread = task.spawn(function()
                while presentEnabled do
                    local count = collectAllPresents()
                    if count > 0 then
                        print("[Auto] Collected " .. count .. " presents!")
                    end
                    task.wait(0.5)
                end
            end)
        else
            if presentThread then task.cancel(presentThread) end
        end
    end
})

-- ======================================
-- UI - AUTO
-- ======================================
AutoTab:CreateSection("Auto")

AutoTab:CreateToggle({
    Name = "Auto Blow Bubble",
    CurrentValue = false,
    Callback = function(v)
        bubbleEnabled = v
        if v then
            bubbleThread = task.spawn(function()
                while bubbleEnabled do
                    pcall(function() fire("BlowBubble") end)
                    task.wait(0.01)
                end
            end)
        else
            if bubbleThread then task.cancel(bubbleThread) end
        end
    end
})

AutoTab:CreateToggle({
    Name = "Auto Sell Bubble",
    CurrentValue = false,
    Callback = function(v)
        sellEnabled = v
        if v then
            sellThread = task.spawn(function()
                local sellPos = getSellPosition()
                local needsSell = false
                
                while sellEnabled do
                    local bubbles = getBubbles()
                    
                    if bubbles >= BUBBLE_CAP then
                        needsSell = true
                    elseif bubbles < 100000000 then
                        needsSell = false
                    end
                    
                    if needsSell and bubbles >= BUBBLE_CAP then
                        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                        
                        if root then root.CFrame = CFrame.new(sellPos) end
                        task.wait(0.2)
                        
                        for i = 1, 3 do
                            local before = getBubbles()
                            pcall(function() fire("SellBubble") end)
                            task.wait(0.3)
                            local after = getBubbles()
                            if after < before then break end
                        end
                        
                        if root then
                            root.CFrame = CFrame.new(RETURN_POS)
                        end
                        task.wait(3)
                    end
                    task.wait(1)
                end
            end)
        else
            if sellThread then task.cancel(sellThread) end
        end
    end
})

AutoTab:CreateToggle({
    Name = "Auto Use Power Orb",
    CurrentValue = false,
    Callback = function(v)
        powerOrbEnabled = v
        if v then
            powerOrbThread = task.spawn(function()
                local petIDs = {
                    "a0a3c245-ff67-4723-b85c-5d141d0a9649",
                    "2ac153c7-11b7-49c1-85e3-354f80941818",
                    "bd2d105a-1fcb-4e81-a420-80224d8830ad",
                    "10ee81b6-f9c3-4ec3-a829-9b2f868b6400",
                    "8a69932e-e1bf-4f0f-b23d-16d2c0449eb",
                    "d89b08da-0523-4598-9640-eae1cd880e70",
                    "a67d8c44-1c52-4787-8f55-81bb9bdafa",
                    "16a93d1f-a19a-4057-860b-bcf0c227d2kd",
                    "ac52d576-fcbe-4502-9753-57e271a16e00",
                    "742c65af-b0e9-43e5-b107-0e3a3fd6e57",
                    "d4142051-aecc-4c3f-8339-149f4cbb95a7",
                    "4a9c203f-8d7e-49ae-abe1-e07bb7559980",
                    "1b809029-dee6-4eb4-8414-7139037kb19",
                }
                for i = 1, #petIDs do
                    if not powerOrbEnabled then break end
                    pcall(function() fire("UsePowerOrb", petIDs[i]) end)
                    task.wait(0.5)
                end
                powerOrbEnabled = false
            end)
        else
            if powerOrbThread then task.cancel(powerOrbThread) end
        end
    end
})

AutoTab:CreateToggle({
    Name = "Auto Use Golden Orb",
    CurrentValue = false,
    Callback = function(v)
        orbEnabled = v
        if v then
            orbThread = task.spawn(function()
                while orbEnabled do
                    pcall(function() fire("UseGoldenOrb") end)
                    task.wait(1)
                end
            end)
        else
            if orbThread then task.cancel(orbThread) end
        end
    end
})

AutoTab:CreateToggle({
    Name = "Auto Collect Pickup (Re equip a pet)",
    CurrentValue = false,
    Callback = function(v)
        pickupEnabled = v
        if v then
            constants.DefaultPickupRadius = math.huge
        else
            constants.DefaultPickupRadius = originalRadius
        end
    end
})

-- ======================================
-- AUTO OPEN BOX
-- ======================================
AutoTab:CreateSection("Auto Open Box")

AutoTab:CreateDropdown({
    Name = "Select Box",
    CurrentOption = {selectedBox},
    Options = boxList,
    Callback = function(v)
        selectedBox = v[1] or v
    end
})

AutoTab:CreateToggle({
    Name = "Auto Open Box (don't use near egg)",
    CurrentValue = false,
    Callback = function(v)
        boxEnabled = v
        if v then
            boxThread = task.spawn(function()
                local VIM = game:GetService("VirtualInputManager")
                while boxEnabled do
                    local data = LocalData:Get()
                    local amount = data and data.Powerups and data.Powerups[selectedBox] or 0
                    if amount > 0 then
                        local openAmount = math.min(amount, 25)
                        pcall(function() fire("UseGift", selectedBox, openAmount) end)
                        for i = 1, openAmount do
                            if not boxEnabled then break end
                            VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                            VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                        end
                        task.wait(0.1)
                    else
                        task.wait(5)
                    end
                end
            end)
        else
            if boxThread then task.cancel(boxThread) end
        end
    end
})

print("[Auto] Loaded!")
