-- ================================================
-- OTHER TAB (STATS TRACKER + EFFECTS)
-- ================================================
repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local OtherTab = Window:CreateTab("Other", nil)

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ======================================
-- STATS TRACKER
-- ======================================
local statsEnabled = false
local screenGui = nil
local frame = nil
local hatchedLabel = nil
local rateLabel = nil
local timeLabel = nil

local startTime = 0
local startHatches = 0
local currentHatches = 0

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
end

local function createStatsUI()
    if screenGui then return end
    
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "StatsTracker"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 90)
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
    end
end

-- ======================================
-- EFFECTS
-- ======================================
local function safeSet(obj, prop, value)
    pcall(function() obj[prop] = value end)
end

local function RunFPSBoost()
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("BasePart") then
            safeSet(v, "Material", Enum.Material.SmoothPlastic)
        end
        if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
            safeSet(v, "Enabled", false)
        end
        if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") then
            safeSet(v, "Enabled", false)
        end
        if v:IsA("Decal") or v:IsA("Texture") then
            safeSet(v, "Transparency", 1)
        end
        if v:IsA("Sky") then
            safeSet(v, "Parent", nil)
        end
    end
end

-- FPS Improve #2 - Disables pet models and ReplicatedStorage assets
local fps2Enabled = false
local fps2Disabled = {}
local fps2Thread = nil

local function disableInContainer(container)
    local count = 0
    for _, v in ipairs(container:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Beam") or v:IsA("Trail") then
            if v.Enabled then
                v.Enabled = false
                table.insert(fps2Disabled, v)
                count = count + 1
            end
        end
        -- Hide pet models
        if v:IsA("Model") and v.Parent and v.Parent.Name == "Pets" then
            for _, part in ipairs(v:GetDescendants()) do
                if part:IsA("BasePart") and part.Transparency < 1 then
                    table.insert(fps2Disabled, {object = part, oldTrans = part.Transparency})
                    part.Transparency = 1
                    count = count + 1
                end
            end
        end
    end
    return count
end

local function applyFPS2()
    fps2Disabled = {}
    local count = 0
    
    -- Workspace
    count = count + disableInContainer(workspace)
    
    -- ReplicatedStorage Assets
    local assets = ReplicatedStorage:FindFirstChild("Assets")
    if assets then
        count = count + disableInContainer(assets)
    end
    
    print("[FPS #2] Disabled " .. count .. " effects")
end

local function removeFPS2()
    local count = 0
    for _, item in ipairs(fps2Disabled) do
        if type(item) == "table" and item.object then
            pcall(function() item.object.Transparency = item.oldTrans end)
        else
            pcall(function() item.Enabled = true end)
        end
        count = count + 1
    end
    fps2Disabled = {}
    print("[FPS #2] Restored " .. count .. " effects")
end

local function watchForNewPets()
    while fps2Enabled do
        local rendered = workspace:FindFirstChild("Rendered")
        if rendered then
            local pets = rendered:FindFirstChild("Pets")
            if pets then
                for _, pet in ipairs(pets:GetChildren()) do
                    if pet:IsA("Model") then
                        for _, v in ipairs(pet:GetDescendants()) do
                            if v:IsA("ParticleEmitter") and v.Enabled then
                                v.Enabled = false
                                table.insert(fps2Disabled, v)
                            end
                            if v:IsA("BasePart") and v.Transparency < 1 then
                                table.insert(fps2Disabled, {object = v, oldTrans = v.Transparency})
                                v.Transparency = 1
                            end
                        end
                    end
                end
            end
        end
        task.wait(3)
    end
end

local function RunFullBright()
    local Lighting = game:GetService("Lighting")
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
            createStatsUI()
        else
            destroyStatsUI()
        end
    end
})

OtherTab:CreateSection("Effects")

OtherTab:CreateButton({
    Name = "Click to Improve FPS",
    Callback = function()
        RunFPSBoost()
    end
})

OtherTab:CreateToggle({
    Name = "FPS Improve #2",
    CurrentValue = false,
    Callback = function(v)
        fps2Enabled = v
        if v then
            applyFPS2()
            fps2Thread = task.spawn(watchForNewPets)
        else
            if fps2Thread then task.cancel(fps2Thread) end
            removeFPS2()
        end
    end
})

OtherTab:CreateButton({
    Name = "Click for Brightness",
    Callback = function()
        RunFullBright()
    end
})

print("[Other] Loaded!")
