-- ================================================
-- ACTIVITY INFO TAB
-- ================================================
repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local ActivityTab = Window:CreateTab("Activity Info", nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local config = getgenv().config or {}
local ACTIVITY_WEBHOOK_URL = config.ACTIVITY_WEBHOOK_URL or ""

local request = http_request or request or (syn and syn.request)

if not request then
    ActivityTab:CreateSection("Error")
    ActivityTab:CreateLabel("Your executor doesn't support webhooks!")
    return
end

if ACTIVITY_WEBHOOK_URL == "" then
    ActivityTab:CreateSection("Webhook Not Configured")
    ActivityTab:CreateLabel("Please set ACTIVITY_WEBHOOK_URL in your config!")
    ActivityTab:CreateLabel("Add this BEFORE the loadstring:")
    ActivityTab:CreateLabel([[getgenv().config = {
    ACTIVITY_WEBHOOK_URL = "Put your activity webhook URL here!",
}]])
    return
end

-- ======================================
-- SETTINGS
-- ======================================
local activityEnabled = false
local lastSent = ""

-- Initialize global activity tracker
if not getgenv().ActivityStatus then
    getgenv().ActivityStatus = {
        current = "Idle",
        trigger = false,
    }
end

-- ======================================
-- FUNCTIONS
-- ======================================
local function sendActivity(msg)
    if not activityEnabled then return end
    if not ACTIVITY_WEBHOOK_URL or ACTIVITY_WEBHOOK_URL == "" then return end
    if msg == lastSent then return end
    
    lastSent = msg
    
    pcall(function()
        request({
            Url = ACTIVITY_WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                embeds = {{
                    title = "Activity Update",
                    description = "**" .. player.Name .. "**\n" .. msg,
                    color = 5814783,
                    footer = {text = "Renoa Hub * " .. os.date("%Y-%m-%d %H:%M:%S")}
                }}
            })
        })
    end)
end

-- Monitor global activity trigger
task.spawn(function()
    while true do
        task.wait(3)
        local status = getgenv().ActivityStatus
        if status.trigger and status.current ~= lastSent then
            sendActivity(status.current)
            status.trigger = false
        end
    end
end)

-- ======================================
-- UI
-- ======================================
ActivityTab:CreateSection("Activity Webhook")

ActivityTab:CreateLabel("Sends webhook when your character is actively doing something")
ActivityTab:CreateLabel("Uses ACTIVITY_WEBHOOK_URL from config")
ActivityTab:CreateLabel("Only sends when the action is actually being performed, not on toggle")

ActivityTab:CreateToggle({
    Name = "Turn On/Turn Off",
    CurrentValue = false,
    Callback = function(v)
        activityEnabled = v
        if v then
            lastSent = ""
        end
    end
})

print("[Activity Info] Loaded!")
