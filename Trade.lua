-- ================================================
-- TRADE TAB
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
-- UI
-- ======================================
TradeTab:CreateSection("Trade")

TradeTab:CreateLabel("Only 1 player can be input, and send/accept trade only can with the player name you input")

TradeTab:CreateInput({
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
                    if targetPlayer ~= "" then
                        pcall(function()
                            Remote:FireServer("TradeAcceptRequest", targetPlayer)
                        end)
                    end
                    task.wait(3)
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
                    -- Wait if auto move pet is running
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
                    -- Wait if auto move pet is running
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
                    -- Accept trade first
                    pcall(function()
                        Remote:FireServer("TradeAccept")
                    end)
                    task.wait(0.5)
                    
                    -- Add pets fast (12 slots)
                    local data = LocalData:Get()
                    local added = 0
                    if data and data.Pets then
                        for _, pet in pairs(data.Pets) do
                            if not pet.Locked and added < 12 then
                                pcall(function()
                                    Remote:FireServer("TradeAddPet", pet.Id .. ":0")
                                end)
                                added = added + 1
                                task.wait(0.05)
                            end
                            if added >= 12 then break end
                        end
                    end
                    
                    task.wait(0.3)
                    
                    -- Confirm trade
                    pcall(function()
                        Remote:FireServer("TradeConfirm")
                    end)
                    
                    -- Wait before next trade cycle
                    task.wait(2)
                end
            end)
        else
            if movePetThread then task.cancel(movePetThread) end
        end
    end
})

print("[Trade] Loaded!")
