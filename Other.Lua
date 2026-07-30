-- ================================================
-- OTHER TAB (STATS TRACKER + AUTO BUY SHOP + EFFECTS)
-- ================================================
repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local OtherTab = Window:CreateTab("Misc", nil)

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RE = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteEvent
local Pets = require(ReplicatedStorage.Shared.Data.Pets)
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)

-- ======================================
-- STATS TRACKER
-- ======================================
local statsEnabled = false
local screenGui = nil
local frame = nil
local hatchedLabel = nil
local rateLabel = nil
local timeLabel = nil
local bestHatchLabel = nil

local startTime = 0
local startHatches = 0
local currentHatches = 0

-- Best hatch tracking
local TRACKED_RARITIES = {"Secret", "Celestial", "Infinity", "Void"}
local knownPetIds = {}
local bestHatchName = "None"
local bestHatchChance = "N/A"
local bestHatchVariant = "Normal"
local bestHatchDisplay = "Best Hatch: None\nOdds: N/A"

local function getHatches()
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        for _, stat in ipairs(leaderstats:GetChildren()) do
            if stat.Name:find("Hatches") then
                return tonumber(stat.Value) or 0
            end
        end
    end
    return 0
end

local function getChanceDisplay(chance)
    if chance >= 1 then return chance .. "%"
    elseif chance > 0 then
        local oneIn = 100 / chance
        if oneIn >= 1e9 then return "1/" .. string.format("%.0f", oneIn / 1e9) .. "B"
        elseif oneIn >= 1e6 then return "1/" .. string.format("%.1f", oneIn / 1e6) .. "M"
        elseif oneIn >= 1e3 then return "1/" .. string.format("%.1f", oneIn / 1e3) .. "K"
        else return "1/" .. string.format("%.0f", oneIn) end
    end
    return "Unknown"
end

local function checkForBestHatch()
    local data = LocalData:Get()
    if not data or not data.Pets then return end
    
    for _, pet in pairs(data.Pets) do
        if not knownPetIds[pet.Id] then
            knownPetIds[pet.Id] = true
            
            local info = Pets[pet.Name]
            if info and info.Rarity then
                local rarity = info.Rarity
                local isTracked = false
                for _, r in ipairs(TRACKED_RARITIES) do
                    if rarity:find(r) then
                        isTracked = true
                        rarity = r
                        break
                    end
                end
                
                if isTracked and info.Chance then
                    local chance = tonumber(info.Chance) or 0
                    if bestHatchChance == "N/A" or chance < tonumber(bestHatchChance) then
                        bestHatchName = pet.Name
                        bestHatchChance = tostring(chance)
                        
                        if pet.Shiny and pet.Mythic then bestHatchVariant = "Shiny Mythic"
                        elseif pet.Shiny then bestHatchVariant = "Shiny"
                        elseif pet.Mythic then bestHatchVariant = "Mythic"
                        else bestHatchVariant = "Normal" end
                        
                        local odds = getChanceDisplay(chance)
                        bestHatchDisplay = "Best Hatch: " .. bestHatchVariant .. " " .. bestHatchName .. "\nOdds: " .. odds
                        
                        if bestHatchLabel then
                            pcall(function() bestHatchLabel.Text = bestHatchDisplay end)
                        end
                    end
                end
            end
        end
    end
end

local function updateStats()
    currentHatches = getHatches()
    local elapsed = os.clock() - startTime
    local minutes = elapsed / 60
    local hours = elapsed / 3600
    local hatchedSinceStart = currentHatches - startHatches
    local perMin = minutes > 0 and math.floor(hatchedSinceStart / minutes) or 0
    local perHour = hours > 0 and math.floor(hatchedSinceStart / hours) or 0
    
    local h = math.floor(elapsed / 3600)
    local m = math.floor((elapsed % 3600) / 60)
    local s = math.floor(elapsed % 60)
    local timeStr = string.format("%02d:%02d:%02d", h, m, s)
    
    if hatchedLabel then hatchedLabel.Text = "Hatched: " .. hatchedSinceStart end
    if rateLabel then rateLabel.Text = "Rate: " .. perMin .. "/min | " .. perHour .. "/hr" end
    if timeLabel then timeLabel.Text = "Time: " .. timeStr end
    
    -- Check for new best hatch
    checkForBestHatch()
end

local function createStatsUI()
    if screenGui then return end
    
    -- Save current pet IDs so we only track new ones
    local data = LocalData:Get()
    if data and data.Pets then
        for petId, _ in pairs(data.Pets) do
            knownPetIds[petId] = true
        end
    end
    
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "StatsTracker"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 135)
    frame.Position = UDim2.new(1, -210, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -10, 0, 22)
    title.Position = UDim2.new(0, 5, 0, 5)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Text = "Stats Tracker"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame
    
    hatchedLabel = Instance.new("TextLabel")
    hatchedLabel.Size = UDim2.new(1, -10, 0, 18)
    hatchedLabel.Position = UDim2.new(0, 5, 0, 28)
    hatchedLabel.BackgroundTransparency = 1
    hatchedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    hatchedLabel.Text = "Hatched: 0"
    hatchedLabel.Font = Enum.Font.Gotham
    hatchedLabel.TextSize = 12
    hatchedLabel.TextXAlignment = Enum.TextXAlignment.Left
    hatchedLabel.Parent = frame
    
    rateLabel = Instance.new("TextLabel")
    rateLabel.Size = UDim2.new(1, -10, 0, 18)
    rateLabel.Position = UDim2.new(0, 5, 0, 47)
    rateLabel.BackgroundTransparency = 1
    rateLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    rateLabel.Text = "Rate: 0/min | 0/hr"
    rateLabel.Font = Enum.Font.Gotham
    rateLabel.TextSize = 12
    rateLabel.TextXAlignment = Enum.TextXAlignment.Left
    rateLabel.Parent = frame
    
    timeLabel = Instance.new("TextLabel")
    timeLabel.Size = UDim2.new(1, -10, 0, 18)
    timeLabel.Position = UDim2.new(0, 5, 0, 66)
    timeLabel.BackgroundTransparency = 1
    timeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    timeLabel.Text = "Time: 00:00:00"
    timeLabel.Font = Enum.Font.Gotham
    timeLabel.TextSize = 12
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.Parent = frame
    
    -- Best Hatch label
    bestHatchLabel = Instance.new("TextLabel")
    bestHatchLabel.Size = UDim2.new(1, -10, 0, 36)
    bestHatchLabel.Position = UDim2.new(0, 5, 0, 88)
    bestHatchLabel.BackgroundTransparency = 1
    bestHatchLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    bestHatchLabel.Text = "Best Hatch: None\nOdds: N/A"
    bestHatchLabel.Font = Enum.Font.Gotham
    bestHatchLabel.TextSize = 11
    bestHatchLabel.TextXAlignment = Enum.TextXAlignment.Left
    bestHatchLabel.RichText = true
    bestHatchLabel.Parent = frame
    
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    
    title.InputEnded:Connect(function(input)
        dragging = false
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    task.spawn(function()
        while statsEnabled do
            updateStats()
            task.wait(1)
        end
    end)
end

local function destroyStatsUI()
    if screenGui then
        screenGui:Destroy()
        screenGui = nil
        frame = nil
        hatchedLabel = nil
        rateLabel = nil
        timeLabel = nil
        bestHatchLabel = nil
    end
end

-- ======================================
-- AUTO BUY SHOP
-- ======================================
local SHOP_ITEMS = {
    ["shadow-shop"] = {1, 2, 3},
    ["alien-shop"] = {1, 2, 3},
    ["shard-shop"] = {1, 2, 3},
    ["dice-shop"] = {1, 2, 3},
}

local selectedShop = "shadow-shop"
local shopRunning = false
local shopThread = nil
local buyAllRunning = false
local buyAllThread = nil

local function buyShop(shopName)
    local items = SHOP_ITEMS[shopName]
    if items then
        for _, itemNum in ipairs(items) do
            pcall(function() RE:FireServer("BuyShopItem", shopName, itemNum, true) end)
        end
    end
end

-- ======================================
-- EFFECTS
-- ======================================
local function safeSet(obj, prop, value)
    pcall(function() obj[prop] = value end)
end

local function fps1_DisableParticles()
    local count = 0
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("BasePart") then
            safeSet(v, "Material", Enum.Material.SmoothPlastic)
            count = count + 1
        end
        if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
            safeSet(v, "Enabled", false)
            count = count + 1
        end
        if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") then
            safeSet(v, "Enabled", false)
            count = count + 1
        end
        if v:IsA("Decal") or v:IsA("Texture") then
            safeSet(v, "Transparency", 1)
            count = count + 1
        end
        if v:IsA("Sky") then
            safeSet(v, "Parent", nil)
            count = count + 1
        end
        if count % 500 == 0 then task.wait(0.01) end
    end
    print("[FPS] Disabled " .. count .. " effects")
end

local function fps2_HidePets()
    local count = 0
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Beam") or v:IsA("Trail") then
            if v.Enabled then
                v.Enabled = false
                count = count + 1
            end
        end
        if v:IsA("Model") and v.Parent and v.Parent.Name == "Pets" then
            for _, part in ipairs(v:GetDescendants()) do
                if part:IsA("BasePart") and part.Transparency < 1 then
                    part.Transparency = 1
                    count = count + 1
                end
            end
        end
        if count % 500 == 0 then task.wait(0.01) end
    end
    print("[FPS] Disabled " .. count .. " pet effects")
end

local function fps3_RemoveTextures()
    local count = 0
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("Decal") or v:IsA("Texture") then
            v.Texture = ""
            count = count + 1
        end
        if v:IsA("ParticleEmitter") or v:IsA("Beam") or v:IsA("Trail") or v:IsA("Sparkles") then
            if v.Enabled then
                v.Enabled = false
                count = count + 1
            end
        end
        if v:IsA("BasePart") and v.Material ~= Enum.Material.SmoothPlastic then
            v.Material = Enum.Material.SmoothPlastic
            count = count + 1
        end
        if v:IsA("BasePart") and v.CastShadow then
            v.CastShadow = false
            count = count + 1
        end
        if count % 1000 == 0 then task.wait(0.01) end
    end
    Lighting.GlobalShadows = false
    Lighting.Outlines = false
    print("[FPS] Disabled " .. count .. " effects")
end

local function fullBright()
    safeSet(Lighting, "Brightness", 5)
    safeSet(Lighting, "Ambient", Color3.fromRGB(255, 255, 255))
    safeSet(Lighting, "OutdoorAmbient", Color3.fromRGB(255, 255, 255))
    safeSet(Lighting, "FogEnd", math.huge)
end

-- ======================================
-- UI
-- ======================================
OtherTab:CreateSection("Stats Tracker")

OtherTab:CreateToggle({
    Name = "Show Stats UI",
    CurrentValue = false,
    Callback = function(v)
        statsEnabled = v
        if v then
            startTime = os.clock()
            startHatches = getHatches()
            bestHatchName = "None"
            bestHatchChance = "N/A"
            bestHatchVariant = "Normal"
            bestHatchDisplay = "Best Hatch: None\nOdds: N/A"
            knownPetIds = {}
            createStatsUI()
        else
            destroyStatsUI()
        end
    end
})

OtherTab:CreateSection("Auto Buy Shop")

OtherTab:CreateDropdown({
    Name = "Select Shop",
    Options = {"shadow-shop", "alien-shop", "shard-shop", "dice-shop"},
    CurrentOption = {selectedShop},
    Callback = function(v)
        selectedShop = v[1]
    end
})

OtherTab:CreateToggle({
    Name = "Auto Buy Selected Shop",
    CurrentValue = false,
    Callback = function(v)
        shopRunning = v
        if v then
            shopThread = task.spawn(function()
                while shopRunning do
                    buyShop(selectedShop)
                    task.wait(1)
                end
            end)
        else
            if shopThread then task.cancel(shopThread) end
        end
    end
})

OtherTab:CreateToggle({
    Name = "Auto Buy All Shop",
    CurrentValue = false,
    Callback = function(v)
        buyAllRunning = v
        if v then
            buyAllThread = task.spawn(function()
                while buyAllRunning do
                    for shopName, _ in pairs(SHOP_ITEMS) do
                        buyShop(shopName)
                    end
                    task.wait(1)
                end
            end)
        else
            if buyAllThread then task.cancel(buyAllThread) end
        end
    end
})

OtherTab:CreateButton({
    Name = "Reroll Shadow Shop Stock",
    Callback = function()
        pcall(function() RE:FireServer("ShopFreeReroll", "shadow-shop") end)
        print("[Shop] Shadow Shop rerolled!")
    end
})

OtherTab:CreateSection("Effects")

OtherTab:CreateButton({
    Name = "Disable Particles & Materials",
    Callback = function()
        fps1_DisableParticles()
    end
})

OtherTab:CreateButton({
    Name = "Hide Pets & Effects",
    Callback = function()
        fps2_HidePets()
    end
})

OtherTab:CreateButton({
    Name = "Remove Shadows & Textures",
    Callback = function()
        fps3_RemoveTextures()
    end
})

OtherTab:CreateButton({
    Name = "Click for Brightness",
    Callback = function()
        fullBright()
    end
})

print("[Misc] Loaded!")
