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
-- LOAD SAVED SETTINGS
-- ======================================
local settings = getgenv().HubSettings or {}
if not settings.auto then settings.auto = {} end
local autoSettings = settings.auto

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
local rune1Amount = autoSettings.luckRuneAmount or 200
local rune1Running = false
local rune1Thread = nil

local rune2Type = "Secret"
local rune2Tier = "1"
local rune2Amount = autoSettings.secretRuneAmount or 200
local rune2Running = false
local rune2Thread = nil

local rune3Type = "Bubble"
local rune3Tier = "1"
local rune3Amount = autoSettings.bubbleRuneAmount or 200
local rune3Running = false
local rune3Thread = nil

-- Fragment settings
local fragRunning = false
local fragThread = nil

-- Playtime
local playtimeRunning = false
local playtimeThread = nil

-- Daily streak
local dailyRunning = false
local dailyThread = nil
local forfeitRunning = false
local forfeitThread = nil

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
local selectedBox = autoSettings.selectedBox or boxList[1] or "Mystery Box"

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
        if root then root.CFrame = CFrame.new(previousPos) end
    end
    return collected
end

-- ======================================
-- UI - PRESENT RAIN
-- ======================================
AutoTab:CreateSection("Present Rain")

AutoTab:CreateToggle({
    Name = "Auto Collect Presents",
    CurrentValue = autoSettings.presentRain or false,
    Callback = function(v)
        presentEnabled = v
        autoSettings.presentRain = v
        getgenv().HubSettings.auto = autoSettings
        saveHubSettings()
        if v then
            local wasCollecting = false
            presentThread = task.spawn(function()
                while presentEnabled do
                    if getgenv().questActive then
                        task.wait(0.5)
                        continue
                    end
                    
                    local count = collectAllPresents()
                    if count > 0 then
                        if not wasCollecting then
                            getgenv().ActivityStatus.current = "Collecting Presents (" .. count .. " found)"
                            getgenv().ActivityStatus.trigger = true
                            wasCollecting = true
                        end
                        
                    else
                        if wasCollecting then
                            getgenv().ActivityStatus.current = "Done collecting presents"
                            getgenv().ActivityStatus.trigger = true
                            wasCollecting = false
                        end
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
    CurrentOption = {autoSettings.luckRuneTier or "Luck Tier 1"},
    Callback = function(v)
        local split = string.split(v[1], " ")
        rune1Type = split[1]
        rune1Tier = split[3]
        autoSettings.luckRuneTier = v[1]
        getgenv().HubSettings.auto = autoSettings
        saveHubSettings()
    end
})

AutoTab:CreateInput({
    Name = "Input the amount u want to use",
    CurrentValue = tostring(rune1Amount),
    PlaceholderText = "200",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        local n = tonumber(v)
        if n then
            rune1Amount = n
            autoSettings.luckRuneAmount = n
            getgenv().HubSettings.auto = autoSettings
            saveHubSettings()
        end
    end
})

AutoTab:CreateToggle({
    Name = "Auto Use Luck Rune",
    CurrentValue = false,
    Callback = function(v)
        rune1Running = v
        if v then
            rune1Thread = task.spawn(function()
                getgenv().ActivityStatus.current = "Using " .. rune1Type .. " Rune " .. rune1Amount
                getgenv().ActivityStatus.trigger = true
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
    CurrentOption = {autoSettings.secretRuneTier or "Secret Tier 1"},
    Callback = function(v)
        local split = string.split(v[1], " ")
        rune2Type = split[1]
        rune2Tier = split[3]
        autoSettings.secretRuneTier = v[1]
        getgenv().HubSettings.auto = autoSettings
        saveHubSettings()
    end
})

AutoTab:CreateInput({
    Name = "Input the amount u want to use",
    CurrentValue = tostring(rune2Amount),
    PlaceholderText = "200",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        local n = tonumber(v)
        if n then
            rune2Amount = n
            autoSettings.secretRuneAmount = n
            getgenv().HubSettings.auto = autoSettings
            saveHubSettings()
        end
    end
})

AutoTab:CreateToggle({
    Name = "Auto Use Secret Rune",
    CurrentValue = false,
    Callback = function(v)
        rune2Running = v
        if v then
            rune2Thread = task.spawn(function()
                getgenv().ActivityStatus.current = "Using " .. rune2Type .. " Rune " .. rune2Amount
                getgenv().ActivityStatus.trigger = true
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
    CurrentOption = {autoSettings.bubbleRuneTier or "Bubble Tier 1"},
    Callback = function(v)
        local split = string.split(v[1], " ")
        rune3Type = split[1]
        rune3Tier = split[3]
        autoSettings.bubbleRuneTier = v[1]
        getgenv().HubSettings.auto = autoSettings
        saveHubSettings()
    end
})

AutoTab:CreateInput({
    Name = "Input the amount u want to use",
    CurrentValue = tostring(rune3Amount),
    PlaceholderText = "200",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        local n = tonumber(v)
        if n then
            rune3Amount = n
            autoSettings.bubbleRuneAmount = n
            getgenv().HubSettings.auto = autoSettings
            saveHubSettings()
        end
    end
})

AutoTab:CreateToggle({
    Name = "Auto Use Bubble Rune",
    CurrentValue = false,
    Callback = function(v)
        rune3Running = v
        if v then
            rune3Thread = task.spawn(function()
                getgenv().ActivityStatus.current = "Using " .. rune3Type .. " Rune " .. rune3Amount
                getgenv().ActivityStatus.trigger = true
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
    CurrentValue = autoSettings.autoFragment or false,
    Callback = function(v)
        fragRunning = v
        autoSettings.autoFragment = v
        getgenv().HubSettings.auto = autoSettings
        saveHubSettings()
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
    CurrentValue = autoSettings.autoBubble or false,
    Callback = function(v)
        bubbleEnabled = v
        autoSettings.autoBubble = v
        getgenv().HubSettings.auto = autoSettings
        saveHubSettings()
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
    CurrentValue = autoSettings.autoSell or false,
    Callback = function(v)
        sellEnabled = v
        autoSettings.autoSell = v
        getgenv().HubSettings.auto = autoSettings
        saveHubSettings()
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
    Name = "Auto Daily Streak",
    CurrentValue = autoSettings.dailyStreak or false,
    Callback = function(v)
        dailyRunning = v
        autoSettings.dailyStreak = v
        getgenv().HubSettings.auto = autoSettings
        saveHubSettings()
        if v then
            dailyThread = task.spawn(function()
                while dailyRunning do
                    local playerGui = player:FindFirstChild("PlayerGui")
                    
                    -- Open Daily Rewards UI
                    if playerGui then
                        local screenGui = playerGui:FindFirstChild("ScreenGui")
                        if screenGui then
                            local hud = screenGui:FindFirstChild("HUD")
                            if hud then
                                local left = hud:FindFirstChild("Left")
                                if left then
                                    local buttons = left:FindFirstChild("Buttons")
                                    if buttons then
                                        local dailyBtn = buttons:FindFirstChild("DailyRewards")
                                        if dailyBtn then
                                            local btn = dailyBtn:FindFirstChild("Button")
                                            if btn then
                                                firesignal(btn.Activated)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    
                    task.wait(0.5)
                    
                    -- Read streak count
                    local streakText = "Unknown"
                    if playerGui then
                        local screenGui = playerGui:FindFirstChild("ScreenGui")
                        if screenGui then
                            local dailyRewards = screenGui:FindFirstChild("DailyRewards")
                            if dailyRewards then
                                local shop = dailyRewards:FindFirstChild("Shop")
                                if shop then
                                    local streak = shop:FindFirstChild("Streak")
                                    if streak then
                                        local label = streak:FindFirstChild("Label")
                                        if label then
                                            streakText = label.Text
                                        end
                                    end
                                end
                            end
                        end
                    end
                    
                    -- Click Claim button
                    local claimed = false
                    if playerGui then
                        local screenGui = playerGui:FindFirstChild("ScreenGui")
                        if screenGui then
                            local dailyRewards = screenGui:FindFirstChild("DailyRewards")
                            if dailyRewards then
                                local login = dailyRewards:FindFirstChild("Login")
                                if login then
                                    local loginFrame = login:FindFirstChild("Frame")
                                    if loginFrame then
                                        local claim = loginFrame:FindFirstChild("Claim")
                                        if claim then
                                            local claimBtn = claim:FindFirstChild("Button")
                                            if claimBtn and claimBtn.Visible then
                                                firesignal(claimBtn.Activated)
                                                claimed = true
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    
                    -- Fire remote
                    pcall(function() RE:FireServer("DailyRewardClaimStars") end)
                    claimed = true
                    
                    task.wait(0.3)
                    
                    -- Close Daily Rewards UI
                    if playerGui then
                        local screenGui = playerGui:FindFirstChild("ScreenGui")
                        if screenGui then
                            local hud = screenGui:FindFirstChild("HUD")
                            if hud then
                                local left = hud:FindFirstChild("Left")
                                if left then
                                    local buttons = left:FindFirstChild("Buttons")
                                    if buttons then
                                        local dailyBtn = buttons:FindFirstChild("DailyRewards")
                                        if dailyBtn then
                                            local btn = dailyBtn:FindFirstChild("Button")
                                            if btn then
                                                firesignal(btn.Activated)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    
                    if claimed then
                        getgenv().ActivityStatus.current = "Signed in for your Daily Streak! (" .. streakText .. ")"
                        getgenv().ActivityStatus.trigger = true
                        print("[Auto] Daily streak claimed! (" .. streakText .. ")")
                    else
                        print("[Auto] Daily streak already claimed, waiting 24h...")
                    end
                    
                    task.wait(86400)
                end
            end)
        else
            if dailyThread then task.cancel(dailyThread) end
        end
    end
})

AutoTab:CreateToggle({
    Name = "Auto Forfeit Streak",
    CurrentValue = autoSettings.autoForfeit or false,
    Callback = function(v)
        forfeitRunning = v
        autoSettings.autoForfeit = v
        getgenv().HubSettings.auto = autoSettings
        saveHubSettings()
        if v then
            forfeitThread = task.spawn(function()
                local playerGui = player:FindFirstChild("PlayerGui")
                local hasStreak = false
                if playerGui then
                    local screenGui = playerGui:FindFirstChild("ScreenGui")
                    if screenGui then
                        local dailyRewards = screenGui:FindFirstChild("DailyRewards")
                        if dailyRewards then
                            local streak = dailyRewards:FindFirstChild("Streak")
                            if streak then
                                local label = streak:FindFirstChild("Label")
                                if label and label.Text ~= "" and label.Text ~= "0" then
                                    hasStreak = true
                                end
                            end
                        end
                    end
                end
                
                if hasStreak then
                    pcall(function() RE:FireServer("DailyRewardsForfeitStreak") end)
                    getgenv().ActivityStatus.current = "Forfeited Daily Streak!"
                    getgenv().ActivityStatus.trigger = true
                    print("[Auto] Daily streak forfeited!")
                else
                    print("[Auto] No active streak to forfeit")
                end
                
                forfeitRunning = false
            end)
        else
            if forfeitThread then task.cancel(forfeitThread) end
        end
    end
})

AutoTab:CreateToggle({
    Name = "Auto Claim XL Index",
    CurrentValue = autoSettings.autoXLIndex or false,
    Callback = function(v)
        autoSettings.autoXLIndex = v
        getgenv().HubSettings.auto = autoSettings
        saveHubSettings()
        if v then
            task.spawn(function()
                local XLIndexTasks = require(ReplicatedStorage.Shared.Data.XLIndexTasks)
                local totalTasks = 0
                for _ in pairs(XLIndexTasks) do totalTasks = totalTasks + 1 end
                
                while v do
                    local data = LocalData:Get()
                    local claimed = data and data.XLIndexClaimed
                    local beforeCount = claimed and #claimed or 0
                    
                    if beforeCount < totalTasks then
                        pcall(function() RE:FireServer("ClaimXLIndexRewards") end)
                        task.wait(1)
                        
                        local data2 = LocalData:Get()
                        local afterClaimed = data2 and data2.XLIndexClaimed
                        local afterCount = afterClaimed and #afterClaimed or 0
                        
                        if afterCount > beforeCount then
                            getgenv().ActivityStatus.current = "Claimed XL Index Reward! (" .. afterCount .. "/" .. totalTasks .. ")"
                            getgenv().ActivityStatus.trigger = true
                            print("[XL Index] Claimed! " .. afterCount .. "/" .. totalTasks)
                            task.wait(5)
                        else
                            task.wait(600)
                        end
                    else
                        print("[XL Index] All complete!")
                        break
                    end
                end
            end)
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
    CurrentValue = autoSettings.autoGoldenOrb or false,
    Callback = function(v)
        orbEnabled = v
        autoSettings.autoGoldenOrb = v
        getgenv().HubSettings.auto = autoSettings
        saveHubSettings()
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
    CurrentValue = autoSettings.autoPickup or false,
    Callback = function(v)
        pickupEnabled = v
        autoSettings.autoPickup = v
        getgenv().HubSettings.auto = autoSettings
        saveHubSettings()
        if v then
            constants.DefaultPickupRadius = math.huge
        else
            constants.DefaultPickupRadius = originalRadius
        end
    end
})

AutoTab:CreateToggle({
    Name = "Auto Playtime",
    CurrentValue = autoSettings.autoPlaytime or false,
    Callback = function(v)
        playtimeRunning = v
        autoSettings.autoPlaytime = v
        getgenv().HubSettings.auto = autoSettings
        saveHubSettings()
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
        autoSettings.selectedBox = selectedBox
        getgenv().HubSettings.auto = autoSettings
        saveHubSettings()
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
    end
})

local boxListLabel = AutoTab:CreateLabel("Boxes loaded. Click Rescan to refresh")

AutoTab:CreateToggle({
    Name = "Auto Open Box (don't use near egg)",
    CurrentValue = autoSettings.autoOpenBox or false,
    Callback = function(v)
        boxEnabled = v
        autoSettings.autoOpenBox = v
        getgenv().HubSettings.auto = autoSettings
        saveHubSettings()
        if v then
            boxThread = task.spawn(function()
                local VIM = game:GetService("VirtualInputManager")
                while boxEnabled do
                    local data = LocalData:Get()
                    local amount = data and data.Powerups and data.Powerups[selectedBox] or 0
                    if amount > 0 then
                        local openAmount = math.min(amount, 25)
                        getgenv().ActivityStatus.current = "Opening " .. selectedBox .. " x" .. openAmount
                        getgenv().ActivityStatus.trigger = true
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
    CurrentValue = autoSettings.autoFishing or false,
    Callback = function(v)
        fishRunning = v
        autoSettings.autoFishing = v
        getgenv().HubSettings.auto = autoSettings
        saveHubSettings()
        if v then
            getgenv().ActivityStatus.current = "Starting Fishing quest..."
            getgenv().ActivityStatus.trigger = true
            
            getgenv().RdotAfishingConfig = {
                Mode = "Quest",
                Zone = "Fisher's Island",
            }
            loadstring(game:HttpGet("https://raw.githubusercontent.com/IRdotAI/Rcash-Hub/main/random-shit/autofish.lua"))()
            
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
            getgenv().ActivityStatus.current = "Done Fishing Quest"
            getgenv().ActivityStatus.trigger = true
            
            getgenv().RdotAfishingConfig = {
                Mode = "Off",
                Zone = "Fisher's Island",
                Enabled = false
            }
            getgenv().RdotAfishingStop = true
            task.wait(0.5)
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame + Vector3.new(0, 50, 0)
            end
        end
    end
})

-- ======================================
-- AUTO-START SAVED TOGGLES
-- ======================================
if autoSettings.presentRain then
    presentEnabled = true
    local wasCollecting = false
    presentThread = task.spawn(function()
        while presentEnabled do
            if getgenv().questActive then
                task.wait(0.5)
                continue
            end
            local count = collectAllPresents()
            if count > 0 then
                if not wasCollecting then
                    getgenv().ActivityStatus.current = "Collecting Presents (" .. count .. " found)"
                    getgenv().ActivityStatus.trigger = true
                    wasCollecting = true
                end
                
            else
                if wasCollecting then
                    getgenv().ActivityStatus.current = "Done collecting presents"
                    getgenv().ActivityStatus.trigger = true
                    wasCollecting = false
                end
            end
            task.wait(0.5)
        end
    end)
end

if autoSettings.autoBubble then
    bubbleEnabled = true
    bubbleThread = task.spawn(function()
        while bubbleEnabled do
            pcall(function() fire("BlowBubble") end)
            task.wait(0.01)
        end
    end)
end

if autoSettings.autoSell then
    sellEnabled = true
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local returnCFrame = root and root.CFrame or nil
    sellThread = task.spawn(function()
        local needsSell = false
        while sellEnabled do
            local bubbles = getBubbles()
            if bubbles >= BUBBLE_CAP then needsSell = true
            elseif bubbles < 100000000 then needsSell = false end
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
end

if autoSettings.dailyStreak then
    dailyRunning = true
    dailyThread = task.spawn(function()
        while dailyRunning do
            local playerGui = player:FindFirstChild("PlayerGui")
            
            if playerGui then
                local screenGui = playerGui:FindFirstChild("ScreenGui")
                if screenGui then
                    local hud = screenGui:FindFirstChild("HUD")
                    if hud then
                        local left = hud:FindFirstChild("Left")
                        if left then
                            local buttons = left:FindFirstChild("Buttons")
                            if buttons then
                                local dailyBtn = buttons:FindFirstChild("DailyRewards")
                                if dailyBtn then
                                    local btn = dailyBtn:FindFirstChild("Button")
                                    if btn then
                                        firesignal(btn.Activated)
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            task.wait(0.5)
            
            -- Read streak count
            local streakText = "Unknown"
            if playerGui then
                local screenGui = playerGui:FindFirstChild("ScreenGui")
                if screenGui then
                    local dailyRewards = screenGui:FindFirstChild("DailyRewards")
                    if dailyRewards then
                        local shop = dailyRewards:FindFirstChild("Shop")
                        if shop then
                            local streak = shop:FindFirstChild("Streak")
                            if streak then
                                local label = streak:FindFirstChild("Label")
                                if label then
                                    streakText = label.Text
                                end
                            end
                        end
                    end
                end
            end
            
            -- Click Claim
            local claimed = false
            if playerGui then
                local screenGui = playerGui:FindFirstChild("ScreenGui")
                if screenGui then
                    local dailyRewards = screenGui:FindFirstChild("DailyRewards")
                    if dailyRewards then
                        local login = dailyRewards:FindFirstChild("Login")
                        if login then
                            local loginFrame = login:FindFirstChild("Frame")
                            if loginFrame then
                                local claim = loginFrame:FindFirstChild("Claim")
                                if claim then
                                    local claimBtn = claim:FindFirstChild("Button")
                                    if claimBtn and claimBtn.Visible then
                                        firesignal(claimBtn.Activated)
                                        claimed = true
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            -- Fire remote
            pcall(function() RE:FireServer("DailyRewardClaimStars") end)
            claimed = true
            
            task.wait(0.3)
            
            -- Close UI
            if playerGui then
                local screenGui = playerGui:FindFirstChild("ScreenGui")
                if screenGui then
                    local hud = screenGui:FindFirstChild("HUD")
                    if hud then
                        local left = hud:FindFirstChild("Left")
                        if left then
                            local buttons = left:FindFirstChild("Buttons")
                            if buttons then
                                local dailyBtn = buttons:FindFirstChild("DailyRewards")
                                if dailyBtn then
                                    local btn = dailyBtn:FindFirstChild("Button")
                                    if btn then
                                        firesignal(btn.Activated)
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            if claimed then
                getgenv().ActivityStatus.current = "Signed in for your Daily Streak! (" .. streakText .. ")"
                getgenv().ActivityStatus.trigger = true
                print("[Auto] Daily streak claimed! (" .. streakText .. ")")
            else
                print("[Auto] Daily streak already claimed, waiting 24h...")
            end
            
            task.wait(86400)
        end
    end)
end

if autoSettings.autoForfeit then
    forfeitRunning = true
    forfeitThread = task.spawn(function()
        local playerGui = player:FindFirstChild("PlayerGui")
        local hasStreak = false
        if playerGui then
            local screenGui = playerGui:FindFirstChild("ScreenGui")
            if screenGui then
                local dailyRewards = screenGui:FindFirstChild("DailyRewards")
                if dailyRewards then
                    local streak = dailyRewards:FindFirstChild("Streak")
                    if streak then
                        local label = streak:FindFirstChild("Label")
                        if label and label.Text ~= "" and label.Text ~= "0" then
                            hasStreak = true
                        end
                    end
                end
            end
        end
        
        if hasStreak then
            pcall(function() RE:FireServer("DailyRewardsForfeitStreak") end)
            getgenv().ActivityStatus.current = "Forfeited Daily Streak!"
            getgenv().ActivityStatus.trigger = true
            print("[Auto] Daily streak forfeited!")
        end
    end)
end

if autoSettings.autoGoldenOrb then
    orbEnabled = true
    orbThread = task.spawn(function()
        while orbEnabled do
            pcall(function() fire("UseGoldenOrb") end)
            task.wait(1)
        end
    end)
end

if autoSettings.autoPickup then
    pickupEnabled = true
    constants.DefaultPickupRadius = math.huge
end

if autoSettings.autoFragment then
    fragRunning = true
    fragThread = task.spawn(function()
        while fragRunning do
            pcall(function() RE:FireServer("UseFragment", "Green", 1) end)
            pcall(function() RE:FireServer("UseFragment", "Blue", 1) end)
            pcall(function() RE:FireServer("UseFragment", "Purple", 1) end)
            pcall(function() RE:FireServer("UseFragment", "Rainbow", 1) end)
            task.wait(2)
        end
    end)
end

if autoSettings.autoOpenBox then
    boxEnabled = true
    boxThread = task.spawn(function()
        local VIM = game:GetService("VirtualInputManager")
        while boxEnabled do
            local data = LocalData:Get()
            local amount = data and data.Powerups and data.Powerups[selectedBox] or 0
            if amount > 0 then
                local openAmount = math.min(amount, 25)
                getgenv().ActivityStatus.current = "Opening " .. selectedBox .. " x" .. openAmount
                getgenv().ActivityStatus.trigger = true
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
end

if autoSettings.autoPlaytime then
    playtimeRunning = true
    playtimeThread = task.spawn(function()
        while playtimeRunning do
            pcall(function() RE:FireServer("ClaimAllPlaytime") end)
            task.wait(60)
        end
    end)
end

if autoSettings.autoXLIndex then
    task.spawn(function()
        local XLIndexTasks = require(ReplicatedStorage.Shared.Data.XLIndexTasks)
        local totalTasks = 0
        for _ in pairs(XLIndexTasks) do totalTasks = totalTasks + 1 end
        while autoSettings.autoXLIndex do
            local data = LocalData:Get()
            local claimed = data and data.XLIndexClaimed
            local beforeCount = claimed and #claimed or 0
            if beforeCount < totalTasks then
                pcall(function() RE:FireServer("ClaimXLIndexRewards") end)
                task.wait(1)
                local data2 = LocalData:Get()
                local afterClaimed = data2 and data2.XLIndexClaimed
                local afterCount = afterClaimed and #afterClaimed or 0
                if afterCount > beforeCount then
                    getgenv().ActivityStatus.current = "Claimed XL Index Reward! (" .. afterCount .. "/" .. totalTasks .. ")"
                    getgenv().ActivityStatus.trigger = true
                    print("[XL Index] Claimed! " .. afterCount .. "/" .. totalTasks)
                    task.wait(5)
                else
                    task.wait(600)
                end
            else
                print("[XL Index] All complete!")
                break
            end
        end
    end)
end

print("[Auto] Loaded!")
