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

-- ======================================
-- CONFIG
-- ======================================
local config = getgenv().config or {}
local ACTIVITY_WEBHOOK_URL = config.HATCH_WEBHOOK_URL or ""
local DISCORD_USER_ID = config.DISCORD_USER_ID or ""

local request = http_request or request or (syn and syn.request)

-- ======================================
-- SETTINGS
-- ======================================
local activityEnabled = false

if not getgenv().ActivityStatus then
    getgenv().ActivityStatus = {
        current = "Idle",
        lastSent = "",
    }
end

-- ======================================
-- FUNCTIONS
-- ======================================
local function sendActivity(msg)
    if not activityEnabled then return end
    if not ACTIVITY_WEBHOOK_URL or ACTIVITY_WEBHOOK_URL == "" then return end
    if msg == getgenv().ActivityStatus.lastSent then return end
    
    getgenv().ActivityStatus.lastSent = msg
    
    pcall(function()
        request({
            Url = ACTIVITY_WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                content = "<@"..DISCORD_USER_ID..">",
                embeds = {{
                    title = player.Name .. "'s Activity",
                    description = msg,
                    color = 5814783,
                    footer = {text = "Renoa Hub * " .. os.date("%Y-%m-%d %H:%M:%S")}
                }}
            })
        })
    end)
end

task.spawn(function()
    while true do
        task.wait(5)
        local status = getgenv().ActivityStatus
        if status.current ~= status.lastSent then
            sendActivity(status.current)
        end
    end
end)

-- ======================================
-- UI
-- ======================================
ActivityTab:CreateSection("Activity Webhook")

ActivityTab:CreateLabel("Sends webhook updates about what your character is doing")
ActivityTab:CreateLabel("Uses your Hatch Webhook URL from config")
ActivityTab:CreateLabel("Tracks: Season Pass, Hatching, Bounty, Fishing, Enchanting, Shrine, Runes, Teleport, Doodle Rift, 4x Egg, and more")

ActivityTab:CreateToggle({
    Name = "Turn On/Turn Off",
    CurrentValue = false,
    Callback = function(v)
        activityEnabled = v
        if v then
            sendActivity("Activity tracking started!")
        end
    end
})

print("[Activity Info] Loaded!")
