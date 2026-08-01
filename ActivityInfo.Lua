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

local request = http_request or request or (syn and syn.request)

if not request then
    ActivityTab:CreateSection("Error")
    ActivityTab:CreateLabel("Your executor doesn't support webhooks!")
    return
end

-- ======================================
-- LOAD SAVED SETTINGS
-- ======================================
local settings = getgenv().HubSettings or {}
if not settings.activity then settings.activity = {} end

-- ======================================
-- SETTINGS
-- ======================================
local activityWebhookURL = settings.activity.webhookURL or ""
local activityEnabled = settings.activity.enabled or false
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
    if activityWebhookURL == "" then return end
    if msg == lastSent then return end
    
    lastSent = msg
    
    pcall(function()
        request({
            Url = activityWebhookURL,
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
ActivityTab:CreateLabel("Only sends when the action is actually being performed, not on toggle")

ActivityTab:CreateInput({
    Name = "Activity Webhook URL",
    CurrentValue = activityWebhookURL,
    PlaceholderText = "https://discord.com/api/webhooks/...",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        activityWebhookURL = v
        settings.activity.webhookURL = v
        getgenv().HubSettings.activity = settings.activity
        saveHubSettings()
    end
})

ActivityTab:CreateToggle({
    Name = "Turn On/Turn Off",
    CurrentValue = activityEnabled,
    Callback = function(v)
        activityEnabled = v
        lastSent = ""
        settings.activity.enabled = v
        getgenv().HubSettings.activity = settings.activity
        saveHubSettings()
    end
})

print("[Activity Info] Loaded!")
