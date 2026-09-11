-- ================================================
-- INFO TAB
-- ================================================
repeat task.wait() until getgenv().Window

local Window = getgenv().Window
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local player = Players.LocalPlayer

local InfoTab = Window:CreateTab("Info")

-- ======================================
-- WELCOME SECTION
-- ======================================
local startTime = os.clock()

InfoTab:CreateLabel("Hello " .. player.Name .. "! Welcome back")

local sessionLabel = InfoTab:CreateLabel("Session: 00:00")

task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            local elapsed = os.clock() - startTime
            local minutes = math.floor(elapsed / 60)
            local seconds = math.floor(elapsed % 60)
            sessionLabel.Text = string.format("Session: %02d:%02d", minutes, seconds)
        end)
    end
end)

-- ======================================
-- DISCORD SECTION
-- ======================================
InfoTab:CreateSection("Discord")

InfoTab:CreateLabel("Join our Discord community!")
InfoTab:CreateLabel("discord.gg/GfjXmXkG4E")

InfoTab:CreateButton({
    Name = "Copy Discord Invite",
    Callback = function()
        pcall(function()
            setclipboard("https://discord.gg/GfjXmXkG4E")
        end)
        print("[Info] Discord invite copied!")
    end,
})

-- ======================================
-- DONATION SECTION (EMPTY)
-- ======================================
InfoTab:CreateSection("Donation")

InfoTab:CreateLabel("Support Renoa Hub development!")
InfoTab:CreateLabel("Donation links coming soon!")

InfoTab:CreateButton({
    Name = "Copy Donation Link",
    Callback = function()
        -- Empty for now
        print("[Info] Donation link coming soon!")
    end,
})

-- ======================================
-- SUGGESTION SECTION
-- ======================================
InfoTab:CreateSection("Suggestion")

InfoTab:CreateLabel("Send your suggestion directly to us!")
InfoTab:CreateLabel("We read every single message.")

local suggestionInput = InfoTab:CreateInput({
    Name = "Your Suggestion",
    CurrentValue = "",
    PlaceholderText = "Type your suggestion here...",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        getgenv()._suggestionText = v
    end,
})

InfoTab:CreateButton({
    Name = "Send Suggestion",
    Callback = function()
        local message = getgenv()._suggestionText
        
        if not message or message == "" then
            if suggestionInput and suggestionInput.Text then
                message = suggestionInput.Text
            end
        end
        
        if not message or message == "" then
            print("[Info] Please type a suggestion first!")
            return
        end
        
        local webhookURL = "https://discord.com/api/webhooks/1545103112308523183/3s00vtdmI7pV5fw-ghjnPNDoSSUUsPWWz19Q0VVuEWdHfndl7pbR1UHeYYYRj8sutU4l"
        
        local request = http_request or request or (syn and syn.request)
        if not request then
            print("[Info] Cannot send right now!")
            return
        end
        
        pcall(function()
            request({
                Url = webhookURL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({
                    embeds = {{
                        title = "💡 New Suggestion!",
                        description = message,
                        color = 0x8B00FF,
                        fields = {{
                            name = "From",
                            value = player.Name,
                            inline = true
                        }, {
                            name = "Game",
                            value = MarketplaceService:GetProductInfo(game.PlaceId).Name,
                            inline = true
                        }},
                        footer = {text = "Renoa Hub Suggestion * " .. os.date("%Y-%m-%d %H:%M:%S")}
                    }}
                })
            })
            print("[Info] ✅ Suggestion sent! Thank you!")
            getgenv()._suggestionText = ""
        end)
    end,
})

print("[Info] Loaded!")
