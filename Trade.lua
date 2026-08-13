-- ================================================
-- TRADE TAB - Fixed with case-insensitive search
-- ================================================
repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local TradeTab = Window:CreateTab("Trade", nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)
local Remote = require(ReplicatedStorage.Shared.Framework.Network.Remote)

-- ======================================
-- SETTINGS
-- ======================================
local targetPlayerInput = nil
local targetPlayer = ""
local sendRunning = false
local sendThread = nil
local acceptRunning = false
local acceptThread = nil
local confirmRunning = false
local confirmThread = nil
local movePetRunning = false
local movePetThread = nil

-- ======================================
-- FUNCTIONS
-- ======================================
local function findPlayer(name)
    if name == "" then return nil end
    
    -- Try exact match first
    local exact = Players:FindFirstChild(name)
    if exact then return exact end
    
    -- Case-insensitive search
    local lowerName = name:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == lowerName then
            return p
        end
    end
    
    -- Partial match search
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():find(lowerName) then
            return p
        end
    end
    
    return nil
end

local function getTargetPlayerName()
    -- Try callback value first
    if targetPlayer ~= "" then return targetPlayer end
    
    -- Try reading from input object
    if targetPlayerInput then
        pcall(function()
            if targetPlayerInput.CurrentValue and targetPlayerInput.CurrentValue ~= "" then
                targetPlayer = targetPlayerInput.CurrentValue
            end
        end)
    end
    
    return targetPlayer
end

-- ======================================
-- UI
-- ======================================
TradeTab:CreateSection("Trade")

TradeTab:CreateLabel("Only 1 player can be input, and send/accept trade only can with the player name you input")

targetPlayerInput = TradeTab:CreateInput({
    Name = "Target Player Name",
    PlaceholderText = "PlayerName123",
    CurrentValue = "",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        targetPlayer = v
    end
})

TradeTab:CreateToggle({
    Name = "Send Trade",
    CurrentValue = false,
    Callback = function(v)
        sendRunning = v
        if v then
            sendThread = task.spawn(function()
                while sendRunning do
                    local name = getTargetPlayerName()
                    local target = findPlayer(name)
                    if target then
                        pcall(function()
                            Remote:FireServer("TradeRequest", target)
                        end)
                        print("[Trade] Sent request to " .. target.Name)
                    else
                        print("[Trade] Player not found: '" .. name .. "'")
                    end
                    task.wait(0.5)
                end
            end)
        else
            if sendThread then task.cancel(sendThread) end
        end
    end
})

TradeTab:CreateToggle({
    Name = "Accept Trade",
    CurrentValue = false,
    Callback = function(v)
        acceptRunning = v
        if v then
            acceptThread = task.spawn(function()
                while acceptRunning do
                    local name = getTargetPlayerName()
                    local target = findPlayer(name)
                    if target then
                        pcall(function()
                            Remote:FireServer("TradeAcceptRequest", target)
                        end)
                        print("[Trade] Accepted request from " .. target.Name)
                    else
                        print("[Trade] Player not found: '" .. name .. "'")
                    end
                    task.wait(1)
                end
            end)
        else
            if acceptThread then task.cancel(acceptThread) end
        end
    end
})

TradeTab:CreateToggle({
    Name = "Accept And Confirm",
    CurrentValue = false,
    Callback = function(v)
        confirmRunning = v
        if v then
            confirmThread = task.spawn(function()
                while confirmRunning do
                    while movePetRunning do
                        task.wait(0.5)
                    end
                    pcall(function()
                        Remote:FireServer("TradeAccept")
                    end)
                    task.wait(0.3)
                    pcall(function()
                        Remote:FireServer("TradeConfirm")
                    end)
                    task.wait(0.3)
                end
            end)
        else
            if confirmThread then task.cancel(confirmThread) end
        end
    end
})

TradeTab:CreateSection("Auto Move Pet")

TradeTab:CreateLabel("This Will add all your pet in inventory to the trade")

TradeTab:CreateToggle({
    Name = "Auto Move Pet",
    CurrentValue = false,
    Callback = function(v)
        movePetRunning = v
        if v then
            movePetThread = task.spawn(function()
                while movePetRunning do
                    pcall(function()
                        Remote:FireServer("TradeAccept")
                    end)
                    task.wait(1)
                    
                    local data = LocalData:Get()
                    local added = 0
                    local petNames = {}
                    if data and data.Pets then
                        for _, pet in pairs(data.Pets) do
                            if not pet.Locked and added < 12 then
                                pcall(function()
                                    Remote:FireServer("TradeAddPet", pet.Id .. ":0")
                                end)
                                table.insert(petNames, pet.Name)
                                added = added + 1
                                task.wait(0.15)
                            end
                            if added >= 12 then break end
                        end
                    end
                    
                    if #petNames > 0 then
                        getgenv().ActivityStatus.current = "Auto moving pets to trade: " .. table.concat(petNames, ", ")
                        getgenv().ActivityStatus.trigger = true
                    end
                    
                    task.wait(0.5)
                    pcall(function()
                        Remote:FireServer("TradeConfirm")
                    end)
                    
                    task.wait(3)
                end
            end)
        else
            if movePetThread then task.cancel(movePetThread) end
        end
    end
})

print("[Trade] Loaded!")
