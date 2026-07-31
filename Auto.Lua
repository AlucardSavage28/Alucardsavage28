-- ================================================
-- AUTO TAB (PRESENT RAIN + BUBBLE + SELL + ORB + PICKUP + BOX + RUNE/FRAGMENT + FISHING)
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
local SELL_POS = Vector3.new(77, 6, -113)

-- Rune settings
local rune1Type = "Luck"
local rune1Tier = "1"
local rune1Amount = 200
local rune1Running = false
local rune1Thread = nil

local rune2Type = "Secret"
local rune2Tier = "1"
local rune2Amount = 200
local rune2Running = false
local rune2Thread = nil

local rune3Type = "Bubble"
local rune3Tier = "1"
local rune3Amount = 200
local rune3Running = false
local rune3Thread = nil

-- Fragment settings
local fragRunning = false
local fragThread = nil

-- Playtime
local playtimeRunning = false
local playtimeThread = nil

-- Daily login
local dailyRunning = false
local dailyThread = nil

-- Fishing
local fishRunning = false

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
-- UI - AUTO RUNE/FRAGMENT
-- ======================================
AutoTab:CreateSection("Auto Rune/Fragment")

-- Rune #1 (Luck)
AutoTab:CreateDropdown({
    Name = "Luck Rune Tier",
    Options = {"Luck Tier 1", "Luck Tier 2", "Luck Tier 3"},
    CurrentOption = {"Luck Tier 1"},
    Callback = function(v)
        local split = string.split(v[1], " ")
        rune1Type = split[1]
        rune1Tier = split[3]
    end
})

AutoTab:CreateInput({
    Name = "Input the amount u want to use",
    CurrentValue = "200",
    PlaceholderText = "200",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        local n = tonumber(v)
        if n then rune1Amount = n end
    end
})

AutoTab:CreateToggle({
    Name = "Auto Use Luck Rune",
    CurrentValue = false,
    Callback = function(v)
        rune1Running = v
        if v then
            rune1Thread = task.spawn(function()
                pcall(function() RE:FireServer("UseRune", rune1Type, tonumber(rune1Tier), rune1Amount) end)
                rune1Running = false
            end)
        else
            if rune1Thread then task.cancel(rune1Thread) end
        end
    end
})

-- Rune #2 (Secret)
AutoTab:CreateDropdown({
    Name = "Secret Rune Tier",
    Options = {"Secret Tier 1", "Secret Tier 2", "Secret Tier 3"},
    CurrentOption = {"Secret Tier 1"},
    Callback = function(v)
        local split = string.split(v[1], " ")
        rune2Type = split[1]
        rune2Tier = split[3]
    end
})

AutoTab:CreateInput({
    Name = "Input the amount u want to use",
    CurrentValue = "200",
    PlaceholderText = "200",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        local n = tonumber(v)
        if n then rune2Amount = n end
    end
})

AutoTab:CreateToggle({
    Name = "Auto Use Secret Rune",
    CurrentValue = false,
    Callback = function(v)
        rune2Running = v
        if v then
            rune2Thread = task.spawn(function()
                pcall(function() RE:FireServer("UseRune", rune2Type, tonumber(rune2Tier), rune2Amount) end)
                rune2Running = false
            end)
        else
            if rune2Thread then task.cancel(rune2Thread) end
        end
    end
})

-- Rune #3 (Bubble)
AutoTab:CreateDropdown({
    Name = "Bubble Rune Tier",
    Options = {"Bubble Tier 1", "Bubble Tier 2", "Bubble Tier 3"},
    CurrentOption = {"Bubble Tier 1"},
    Callback = function(v)
        local split = string.split(v[1], " ")
        rune3Type = split[1]
        rune3Tier = split[3]
    end
})

AutoTab:CreateInput({
    Name = "Input the amount u want to use",
    CurrentValue = "200",
    PlaceholderText = "200",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        local n = tonumber(v)
        if n then rune3Amount = n end
    end
})

AutoTab:CreateToggle({
    Name = "Auto Use Bubble Rune",
    CurrentValue = false,
    Callback = function(v)
        rune3Running = v
        if v then
            rune3Thread = task.spawn(function()
                pcall(function() RE:FireServer("UseRune", rune3Type, tonumber(rune3Tier), rune3Amount) end)
                rune3Running = false
            end)
        else
            if rune3Thread then task.cancel(rune3Thread) end
        end
    end
})

-- Fragment
AutoTab:CreateToggle({
    Name = "Auto Use All Fragment",
    CurrentValue = false,
    Callback = function(v)
        fragRunning = v
        if v then
            fragThread = task.spawn(function()
                while fragRunning do
                    pcall(function() RE:FireServer("UseFragment", "Green", 1) end)
                    pcall(function() RE:FireServer("UseFragment", "Blue", 1) end)
                    pcall(function() RE:FireServer("UseFragment", "Purple", 1) end)
                    pcall(function() RE:FireServer("UseFragment", "Rainbow", 1) end)
                    task.wait(2)
                end
            end)
        else
            if fragThread then task.cancel(fragThread) end
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
            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local returnCFrame = root and root.CFrame or nil
            
            sellThread = task.spawn(function()
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
                        
                        if root then root.CFrame = CFrame.new(SELL_POS) end
                        task.wait(0.2)
                        
                        for i = 1, 3 do
                            local before = getBubbles()
                            pcall(function() fire("SellBubble") end)
                            task.wait(0.3)
                            local after = getBubbles()
                            if after < before then break end
                        end
                        
                        if returnCFrame and root then
                            root.CFrame = returnCFrame
                            root.Velocity = Vector3.zero
                            root.RotVelocity = Vector3.zero
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
    Name = "Daily Login Streak",
    CurrentValue = false,
    Callback = function(v)
        dailyRunning = v
        if v then
            dailyThread = task.spawn(function()
                pcall(function() RE:FireServer("DailyRewardsForfeitStreak") end)
                task.wait(0.5)
                pcall(function() RE:FireServer("DailyRewardClaimStars") end)
                dailyRunning = false
            end)
        else
            if dailyThread then task.cancel(dailyThread) end
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

AutoTab:CreateToggle({
    Name = "Auto Playtime",
    CurrentValue = false,
    Callback = function(v)
        playtimeRunning = v
        if v then
            playtimeThread = task.spawn(function()
                while playtimeRunning do
                    pcall(function() RE:FireServer("ClaimAllPlaytime") end)
                    task.wait(60)
                end
            end)
        else
            if playtimeThread then task.cancel(playtimeThread) end
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

AutoTab:CreateButton({
    Name = "Re Scan Boxes",
    Callback = function()
        boxList = getBoxes()
        selectedBox = boxList[1] or "Mystery Box"
        local text = "Found " .. #boxList .. " boxes"
        pcall(function() boxListLabel:SetText(text) end)
        print("[Auto] Box Rescan: " .. text)
        for _, name in ipairs(boxList) do
            print("  - " .. name)
        end
    end
})

local boxListLabel = AutoTab:CreateLabel("Boxes loaded. Click Rescan to refresh")

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

-- ======================================
-- UI - FISHING
-- ======================================
AutoTab:CreateSection("Fishing")

AutoTab:CreateLabel("After you turn it on make sure to go first person POV and then look to your left side and then you can leave it")

AutoTab:CreateToggle({
    Name = "Auto Fishing Quest",
    CurrentValue = false,
    Callback = function(v)
        fishRunning = v
        if v then
            -- Start fish script
            getgenv().RdotAfishingConfig = {
                Mode = "Quest",
                Zone = "Fisher's Island",
            }
            loadstring(game:HttpGet("https://raw.githubusercontent.com/IRdotAI/Rcash-Hub/main/random-shit/autofish.lua"))()
            
            -- Wait 1 second then look left
            task.wait(1)
            local camera = workspace.CurrentCamera
            if camera then
                local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    camera.CameraType = Enum.CameraType.Scriptable
                    local forward = root.CFrame.LookVector
                    local right = root.CFrame.RightVector
                    local leftPos = root.Position + (-right * 10) + (forward * 5)
                    camera.CFrame = CFrame.new(root.Position + Vector3.new(0, 2, 0), leftPos)
                    task.wait(0.3)
                    camera.CameraType = Enum.CameraType.LockFirstPerson
                end
            end
        else
            -- Stop fish script
            getgenv().RdotAfishingConfig = {
                Mode = "Off",
                Zone = "Fisher's Island",
            }
            -- Reload character to reset any hooks
            if player.Character then
                player.Character:BreakJoints()
            end
        end
    end
})

print("[Auto] Loaded!")
