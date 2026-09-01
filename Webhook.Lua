-- ================================================
-- WEBHOOK TAB (BUFFERED STUCK DETECTION + AUTO REJOIN)
-- ================================================
repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local WebhookTab = Window:CreateTab("Webhook", nil)

-- ======================================
-- SERVICES
-- ======================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer

-- ======================================
-- LOAD SAVED SETTINGS
-- ======================================
local settings = getgenv().HubSettings or {}
if not settings.webhook then settings.webhook = {} end

-- ======================================
-- WEBHOOK SETTINGS
-- ======================================
local HATCH_WEBHOOK_URL = settings.webhook.hatchURL or ""
local ONLINE_WEBHOOK_URL = settings.webhook.onlineURL or ""
local DISCORD_USER_ID = settings.webhook.userId or ""
local PUBLIC_WEBHOOK_URL = "https://discord.com/api/webhooks/1522161241064345691/6plklhELLd8n_zYdwTjTqwTSRdklmffPHXseqPdI-UD25jDUpD2NZRy4FKmvYByfY5fA"

local request = http_request or request or (syn and syn.request)
if not request then
    WebhookTab:CreateSection("Error")
    WebhookTab:CreateLabel("Your executor doesn't support webhooks!")
    return
end

-- ======================================
-- SETTINGS
-- ======================================
local hideUsername = settings.webhook.hideUsername or false
local rareEggNotify = settings.webhook.rareEggNotify
if rareEggNotify == nil then rareEggNotify = true end

-- ======================================
-- FILTER
-- ======================================
local TRACKED_RARITIES = {
    ["Secret"] = true,
    ["Celestial"] = true,
    ["Infinity"] = true,
    ["Void"] = true,
    ["Super Legendary"] = true,
}

-- ======================================
-- ENCHANT DISPLAY NAMES
-- ======================================
local ENCHANT_NAMES = {
    ["super-burst"] = "Burst Blessing",
    ["super-shiny"] = "Shiny Blessing",
    ["super-luck"] = "Luck Boost",
    ["super-hatch"] = "Hatch Blessing",
    ["super-bubble"] = "Bubble Machine",
    ["super-infinity"] = "Infinity Blessing",
    ["super-duplication"] = "Duplication",
}

-- ======================================
-- COLORS
-- ======================================
local COLORS = {
    Secret = {Normal=0xFF0000,Shiny=0xFFD700,Mythic=0x8B00FF,ShinyMythic=0x00FF00},
    Celestial = {Normal=0xFF0000,Shiny=0xFFD700,Mythic=0x8B00FF,ShinyMythic=0x00FF00},
    Infinity = {Normal=0xFF0000,Shiny=0xFFB84D,Mythic=0x7D3CFF,ShinyMythic=0x00E6A8},
    Void = {Normal=0x0D0D0D,Shiny=0x3AA0FF},
    ["Super Legendary"] = {Normal=0x1E90FF,Shiny=0xFFD700,Mythic=0x8B00FF,ShinyMythic=0x00FF00}
}

-- ======================================
-- DATA
-- ======================================
local Pets = require(ReplicatedStorage.Shared.Data.Pets)
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)
local Remote = require(ReplicatedStorage.Shared.Framework.Network.Remote)

-- ======================================
-- FORMAT
-- ======================================
local function formatNum(n)
    if not n then return "0" end
    if n>=1e9 then return string.format("%.1fB",n/1e9)
    elseif n>=1e6 then return string.format("%.1fM",n/1e6)
    elseif n>=1e3 then return string.format("%.1fK",n/1e3)
    else return tostring(n) end
end

local function formatExist(n)
    if not n then return "0" end
    local s = tostring(math.floor(n))
    return s:reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,","")
end

-- ======================================
-- PET EXTRA
-- ======================================
local function getPetChance(petInfo)
    if petInfo.Chance then
        local chance = tonumber(petInfo.Chance) or 0
        if chance >= 1 then return chance .. "%"
        elseif chance > 0 then
            local oneIn = 100 / chance
            if oneIn >= 1e9 then return "1/" .. string.format("%.0f", oneIn / 1e9) .. "B"
            elseif oneIn >= 1e6 then return "1/" .. string.format("%.1f", oneIn / 1e6) .. "M"
            elseif oneIn >= 1e3 then return "1/" .. string.format("%.1f", oneIn / 1e3) .. "K"
            else return "1/" .. string.format("%.0f", oneIn) end
        end
    end
    return "Unknown"
end

local function getExists(petName, variant)
    local name = petName
    if variant and variant ~= "Normal" then name = variant .. " " .. petName end
    local ok, result = pcall(function() return Remote:InvokeServer("GetExisting", name) end)
    if ok and result then
        local num = tonumber(result) or 0
        if num > 0 then return formatExist(num) end
    end
    return "N/A"
end

local function getVariant(ex)
    if ex.Shiny and ex.Mythic then return "ShinyMythic"
    elseif ex.Shiny then return "Shiny"
    elseif ex.Mythic then return "Mythic"
    else return "Normal" end
end

local function getVariantText(v)
    if v=="ShinyMythic" then return "Shiny Mythic"
    elseif v=="Shiny" then return "Shiny"
    elseif v=="Mythic" then return "Mythic"
    else return "Normal" end
end

-- ======================================
-- IMAGE (BG.SI CDN)
-- ======================================
local function getImage(petName, ex)
    local n = petName:lower():gsub("%s+", "-"):gsub("[^%w%-]", "")
    local prefix = ""
    if ex.Shiny and ex.Mythic then prefix = "shiny-mythic-"
    elseif ex.Shiny then prefix = "shiny-"
    elseif ex.Mythic then prefix = "mythic-" end
    return "https://cdn.bgsi.gg/items/" .. prefix .. n .. ".png"
end

-- ======================================
-- BUFF TIMER
-- ======================================
local function getBuffTime(buffName)
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        local screenGui = playerGui:FindFirstChild("ScreenGui")
        if screenGui then
            local buffs = screenGui:FindFirstChild("Buffs")
            if buffs then
                for _, buff in ipairs(buffs:GetChildren()) do
                    if buff.Name == buffName then
                        local button = buff:FindFirstChild("Button")
                        if button then
                            local label = button:FindFirstChild("Label")
                            if label and label.Text ~= "" then
                                local text = label.Text
                                if buffName == "Lucky" then
                                    if text:find("^%d+:%d+$") then
                                    else
                                        return text
                                    end
                                else
                                    return text
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return "N/A"
end

local function getBuffTimesForEmbed()
    local buffs = {
        {"Secret Elixir", "Secret Elixir"},
        {"Ultra Infinity Elixir", "Ultra Infinity Elixir"},
        {"Infinity Elixir", "Infinity Elixir"},
        {"Lucky Potion", "Lucky"},
        {"Speed Potion", "Speed"},
        {"Mythic Potion", "Mythic"},
    }
    local lines = {}
    for _, buff in ipairs(buffs) do
        local time = getBuffTime(buff[2])
        if time and time ~= "N/A" and time ~= "0s" then
            table.insert(lines, buff[1] .. ": " .. time)
        end
    end
    if #lines == 0 then return "No active buffs" end
    return table.concat(lines, "\n")
end

-- ======================================
-- DEBUG STATS EXTRACTION
-- ======================================
local function getDebugStats()
    local stats = {
        TotalLuck = "N/A",
        InfinityLuck = "N/A",
        SecretLuck = "N/A",
        HatchSpeed = "N/A",
    }
    Remote:FireServer("SetSetting", "Debug", true)
    task.wait(0.5)
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        for _, obj in ipairs(playerGui:GetDescendants()) do
            if obj:IsA("TextLabel") then
                local text = obj.Text
                text = text:gsub("<[^>]+>", "")
                if stats.TotalLuck == "N/A" and text:find("🍀 Lucky") then stats.TotalLuck = text end
                if stats.InfinityLuck == "N/A" and text:find("♾️ Ultra Infinity Luck") then stats.InfinityLuck = text end
                if stats.SecretLuck == "N/A" and text:find("❓ Secret/Infinity Luck") then stats.SecretLuck = text end
                if stats.HatchSpeed == "N/A" and text:find("⚡ Hatch Speed") then stats.HatchSpeed = text end
            end
        end
    end
    return stats
end

-- ======================================
-- WEBHOOK SYSTEM
-- ======================================
local hatchQueue={}
local onlineQueue={}
local publicQueue={}
local hatchProcessing=false
local onlineProcessing=false
local publicProcessing=false

local function sendToWebhook(queue, url)
    if url == "" then return end
    while #queue > 0 do
        local p = table.remove(queue, 1)
        pcall(function()
            request({
                Url = url,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(p)
            })
        end)
        task.wait(1)
    end
end

local function processHatch() if not hatchProcessing then hatchProcessing = true task.spawn(function() sendToWebhook(hatchQueue, HATCH_WEBHOOK_URL) hatchProcessing = false end) end end
local function processPublic() if not publicProcessing then publicProcessing = true task.spawn(function() sendToWebhook(publicQueue, PUBLIC_WEBHOOK_URL) publicProcessing = false end) end end
local function processOnline() if not onlineProcessing then onlineProcessing = true task.spawn(function() sendToWebhook(onlineQueue, ONLINE_WEBHOOK_URL) onlineProcessing = false end) end end

-- ======================================
-- STUCK DETECTION (EVERY 2 MIN + 6 MIN BUFFER)
-- ======================================
local lastHatches = 0
local zeroHatchCount = 0
local stuckNotified = false
local isRejoining = false
local ZERO_WINDOW_THRESHOLD = 3

local leaderstats = player:FindFirstChild("leaderstats")
if leaderstats then
    for _, stat in ipairs(leaderstats:GetChildren()) do
        if stat.Name:find("Hatches") then lastHatches = tonumber(stat.Value) or 0 end
    end
end

task.spawn(function()
    while true do
        task.wait(120)
        if ONLINE_WEBHOOK_URL == "" then continue end
        if isRejoining then continue end
        
        local currentHatches = 0
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            for _, stat in ipairs(leaderstats:GetChildren()) do
                if stat.Name:find("Hatches") then currentHatches = tonumber(stat.Value) or 0 end
            end
        end
        
        local hatchesInWindow = currentHatches - lastHatches
        lastHatches = currentHatches
        
        if hatchesInWindow == 0 then
            zeroHatchCount = zeroHatchCount + 1
            
            if zeroHatchCount >= ZERO_WINDOW_THRESHOLD and not stuckNotified then
                stuckNotified = true
                isRejoining = true
                
                local pingMsg = ""
                if DISCORD_USER_ID ~= "" then
                    pingMsg = "<@" .. DISCORD_USER_ID .. "> Trying to rejoin, Please Still keep an eye on your roblox!"
                else
                    pingMsg = "Trying to rejoin, Please Still keep an eye on your roblox!"
                end
                
                table.insert(onlineQueue, {
                    content = pingMsg,
                    embeds = {{
                        title = "⚠️ STUCK DETECTED - REJOINING!",
                        description = "**" .. player.Name .. "** has no hatches for " .. (zeroHatchCount * 2) .. " minutes! Rejoining...",
                        color = 0xFF0000,
                        footer = {text = "Renoa Hub * " .. os.date("%Y-%m-%d %H:%M:%S")}
                    }}
                })
                processOnline()
                
                task.spawn(function()
                    task.wait(5)
                    pcall(function()
                        TeleportService:Teleport(game.PlaceId, player)
                    end)
                end)
            end
        else
            zeroHatchCount = 0
            stuckNotified = false
            isRejoining = false
        end
    end
end)

-- ======================================
-- REGULAR ONLINE PING (EVERY 30 MIN)
-- ======================================
local startTime = os.time()

task.spawn(function()
    while true do
        task.wait(1800)
        if ONLINE_WEBHOOK_URL == "" then continue end
        if isRejoining then continue end
        
        local elapsed = os.time() - startTime
        local hours = math.floor(elapsed / 3600)
        local minutes = math.floor((elapsed % 3600) / 60)
        local data = LocalData:Get()
        local coins = data and formatNum(data.Coins or 0) or "0"
        local gems = data and formatNum(data.Gems or 0) or "0"
        local leaderstats = player:FindFirstChild("leaderstats")
        local bubbles = "0"
        if leaderstats then
            for _, stat in ipairs(leaderstats:GetChildren()) do
                if stat.Name:find("Bubble") then bubbles = formatNum(stat.Value) end
            end
        end
        
        local debugStats = getDebugStats()
        
        local fragData = data and data.Fragments
        local fragmentText = "N/A"
        if fragData then
            fragmentText = 
                "Green: " .. (fragData.Green or 0) .. "/250\n" ..
                "Blue: " .. (fragData.Blue or 0) .. "/250\n" ..
                "Purple: " .. (fragData.Purple or 0) .. "/250\n" ..
                "Rainbow: " .. (fragData.Rainbow or 0) .. "/250"
        end

        table.insert(onlineQueue, {
            embeds = {{
                title = "Still Online!",
                description =
                    "**" .. player.Name .. "** is still online!\n\n" ..
                    "Online: " .. hours .. "h " .. minutes .. "m\n" ..
                    "Coins: " .. coins .. "\nGems: " .. gems .. "\nBubbles: " .. bubbles .. "\n\n" ..
                    "**Fragments**\n" .. fragmentText .. "\n\n" ..
                    "**Stats**\n" .. debugStats.TotalLuck .. "\n" .. debugStats.InfinityLuck .. "\n" .. debugStats.SecretLuck .. "\n" .. debugStats.HatchSpeed,
                color = 3447003,
                footer = {text = "Renoa Hub * " .. os.date("%Y-%m-%d %H:%M:%S")}
            }}
        })
        processOnline()
    end
end)

-- ======================================
-- FULL INVENTORY SCANNER
-- ======================================
local knownPets = {}

local initData = LocalData:Get()
if initData and initData.Pets then
    for _, pet in pairs(initData.Pets) do
        if pet.Super then knownPets[pet.Id] = true
        else
            local info = Pets[pet.Name]
            if info and info.Rarity then
                for r in pairs(TRACKED_RARITIES) do
                    if info.Rarity:find(r) then knownPets[pet.Id] = true; break end
                end
            end
        end
    end
end

task.spawn(function()
    while true do
        task.wait(5)
        local data = LocalData:Get()
        if data and data.Pets then
            for _, pet in pairs(data.Pets) do
                if not knownPets[pet.Id] then
                    local isSuper = pet.Super
                    local info = Pets[pet.Name]
                    local isXL = pet.XL
                    
                    if isSuper and not info then
                        local baseName = pet.Name:gsub("^Shiny ", ""):gsub("^Mythic ", ""):gsub("^Shiny Mythic ", ""):gsub("^XL ", "")
                        info = Pets[baseName]
                    end
                    
                    local shouldTrack = false
                    if isSuper then shouldTrack = true
                    elseif info and info.Rarity then
                        for r in pairs(TRACKED_RARITIES) do
                            if info.Rarity:find(r) then shouldTrack = true; break end
                        end
                    end
                    
                    if shouldTrack then
                        local rarity = info and info.Rarity or "Super Legendary"
                        if isSuper then rarity = "Super Legendary" end
                        knownPets[pet.Id] = true
                        
                        local debugStats = getDebugStats()
                        local statsStr = debugStats.TotalLuck .. "\n" .. debugStats.InfinityLuck .. "\n" .. debugStats.SecretLuck .. "\n" .. debugStats.HatchSpeed
                        local buffStr = getBuffTimesForEmbed()
                        
                        if isSuper then
                            local enchantNames = {}
                            if pet.Enchants then
                                for _, enchant in pairs(pet.Enchants) do
                                    if enchant.Id then table.insert(enchantNames, enchant.Id) end
                                end
                            end
                            local displayEnchants = {}
                            for _, id in ipairs(enchantNames) do table.insert(displayEnchants, ENCHANT_NAMES[id] or id) end
                            local displayStr = #displayEnchants > 0 and table.concat(displayEnchants, ", ") or "None"
                            local variant = "Normal"
                            if pet.Shiny and pet.Mythic then variant = "Shiny Mythic"
                            elseif pet.Shiny then variant = "Shiny"
                            elseif pet.Mythic then variant = "Mythic" end
                            local displayName = hideUsername and "Hidden" or player.Name
                            local coins = formatNum(data.Coins or 0)
                            local gems = formatNum(data.Gems or 0)
                            
                            local embed = {
                                title = "Congrats You Hatched A "..variant.." Super Legendary "..pet.Name.."!",
                                color = 0x1E90FF,
                                fields = {
                                    {name = "* User Info", value = "Name : "..displayName.."\nCoin : "..coins.."\nGems : "..gems, inline = false},
                                    {name = "Ultra Legendary Enchant", value = displayStr, inline = false},
                                    {name = "Stats", value = statsStr, inline = false},
                                    {name = "Buff Time Left", value = buffStr, inline = false}
                                },
                                footer = {text = "Renoa The Finest has Blessed You! * "..os.date("%Y-%m-%d %H:%M:%S")}
                            }
                            local pingMsg = "<@"..DISCORD_USER_ID..">"
                            if displayStr ~= "None" then pingMsg = "<@"..DISCORD_USER_ID..">, You Got "..displayStr.."!" end
                            
                            table.insert(hatchQueue, {content = DISCORD_USER_ID ~= "" and pingMsg or nil, embeds = {embed}})
                            processHatch()
                            
                            local publicEmbed = {
                                title = "Congrats You Hatched A "..variant.." Super Legendary "..pet.Name.."!",
                                color = 0x1E90FF,
                                fields = {
                                    {name = "* User Info", value = "Name : Hidden", inline = false},
                                    {name = "Ultra Legendary Enchant", value = displayStr, inline = false},
                                    {name = "Stats", value = statsStr, inline = false}
                                },
                                footer = {text = "Renoa The Finest has Blessed You! * "..os.date("%Y-%m-%d %H:%M:%S")}
                            }
                            table.insert(publicQueue, {embeds = {publicEmbed}})
                            processPublic()
                        else
                            local variant = "Normal"
                            if isXL and pet.Shiny and pet.Mythic then variant = "XL Shiny Mythic"
                            elseif isXL and pet.Shiny then variant = "XL Shiny"
                            elseif isXL and pet.Mythic then variant = "XL Mythic"
                            elseif isXL then variant = "XL"
                            elseif pet.Shiny and pet.Mythic then variant = "Shiny Mythic"
                            elseif pet.Shiny then variant = "Shiny"
                            elseif pet.Mythic then variant = "Mythic" end
                            local color = (COLORS[rarity] and COLORS[rarity][variant:gsub("^XL ", "")]) or 16777215
                            if isXL then color = 0xFFA500 end
                            local img = getImage(pet.Name, {Shiny=pet.Shiny, Mythic=pet.Mythic})
                            local displayName = hideUsername and "Hidden" or player.Name
                            local coins = formatNum(data.Coins or 0)
                            local gems = formatNum(data.Gems or 0)
                            local opened = formatNum(data.EggsOpened and data.EggsOpened["Common Egg"] or 0)
                            local chance = info and getPetChance(info) or "Unknown"
                            local existStr = getExists(pet.Name, variant ~= "Normal" and getVariantText(variant:gsub("^XL ", "")) or nil)
                            local displayRarity = isXL and ("XL " .. rarity) or rarity
                            
                            local embed = {
                                title = "Congrats You Hatched A "..variant.." "..displayRarity.." "..pet.Name.."!",
                                color = color,
                                fields = {
                                    {name = "* User Info", value = "Name : "..displayName.."\nCoin : "..coins.."\nGems : "..gems.."\nEgg Hatched : "..opened, inline = false},
                                    {name = "Pet Info", value = "Chance : "..chance.."\nExist : "..existStr, inline = false},
                                    {name = "Stats", value = statsStr, inline = false},
                                    {name = "Buff Time Left", value = buffStr, inline = false}
                                },
                                footer = {text = "Renoa The Finest has Blessed You! * "..os.date("%Y-%m-%d %H:%M:%S")}
                            }
                            if img then embed.thumbnail = {url = img} end
                            
                            table.insert(hatchQueue, {
                                content = (rarity:find("Secret") and DISCORD_USER_ID ~= "") and "<@"..DISCORD_USER_ID..">" or nil,
                                embeds = {embed}
                            })
                            processHatch()
                            
                            local publicEmbed = {
                                title = "Congrats You Hatched A "..variant.." "..displayRarity.." "..pet.Name.."!",
                                color = color,
                                fields = {
                                    {name = "* User Info", value = "Name : Hidden", inline = false},
                                    {name = "Pet Info", value = "Chance : "..chance.."\nExist : "..existStr, inline = false},
                                    {name = "Stats", value = statsStr, inline = false}
                                },
                                footer = {text = "Renoa The Finest has Blessed You! * "..os.date("%Y-%m-%d %H:%M:%S")}
                            }
                            if img then publicEmbed.thumbnail = {url = img} end
                            table.insert(publicQueue, {embeds = {publicEmbed}})
                            processPublic()
                        end
                    end
                end
            end
        end
    end
end)

-- ======================================
-- SPECIAL EVENTS SCANNER (4X EGG ONLY)
-- ======================================
local was4xPlushieActive = false

task.spawn(function()
    while true do
        task.wait(10)
        if not rareEggNotify then continue end
        
        local fourXFound = false
        local rendered = workspace:FindFirstChild("Rendered")
        if rendered then
            for _, obj in ipairs(rendered:GetDescendants()) do
                if obj.Name == "4x Luck Plushie Egg" and obj:IsA("Model") then fourXFound = true; break end
            end
        end
        if not fourXFound then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj.Name == "4x Luck Plushie Egg" and obj:IsA("Model") then fourXFound = true; break end
            end
        end
        
        if fourXFound and not was4xPlushieActive then
            was4xPlushieActive = true
            if HATCH_WEBHOOK_URL ~= "" then
                pcall(function() request({Url = HATCH_WEBHOOK_URL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode({content = (DISCORD_USER_ID ~= "" and "<@"..DISCORD_USER_ID.."> " or "") .. "4x Egg Has Spawned!", embeds = {{title = "4x Egg Spawned!", description = "Go hatch it now!", color = 0xFF4500, footer = {text = "Good Luck Hatching! | Renoa Hub"}}}})}) end)
            end
        elseif not fourXFound then was4xPlushieActive = false end
    end
end)

-- ======================================
-- ANIMATION TOGGLE
-- ======================================
local success, mod = pcall(function() return require(ReplicatedStorage.Client.Effects.HatchEgg) end)
if success and mod then
    local originalPlay = mod.Play
    mod.Play = newcclosure(function(self, data)
        if getgenv().animationHidden then return end
        return originalPlay(self, data)
    end)
end

-- ======================================
-- UI
-- ======================================
WebhookTab:CreateSection("Webhook Settings")

WebhookTab:CreateInput({
    Name = "Hatch Webhook URL",
    CurrentValue = HATCH_WEBHOOK_URL,
    PlaceholderText = "https://discord.com/api/webhooks/...",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        HATCH_WEBHOOK_URL = v
        settings.webhook.hatchURL = v
        getgenv().HubSettings.webhook = settings.webhook
        saveHubSettings()
    end
})

WebhookTab:CreateInput({
    Name = "Online Ping Webhook URL",
    CurrentValue = ONLINE_WEBHOOK_URL,
    PlaceholderText = "https://discord.com/api/webhooks/...",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        ONLINE_WEBHOOK_URL = v
        settings.webhook.onlineURL = v
        getgenv().HubSettings.webhook = settings.webhook
        saveHubSettings()
    end
})

WebhookTab:CreateInput({
    Name = "Discord User ID",
    CurrentValue = DISCORD_USER_ID,
    PlaceholderText = "Discord_User_ID",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        DISCORD_USER_ID = v
        settings.webhook.userId = v
        getgenv().HubSettings.webhook = settings.webhook
        saveHubSettings()
    end
})

WebhookTab:CreateSection("Settings")

WebhookTab:CreateToggle({
    Name = "Hide Username (shows 'Hidden')",
    CurrentValue = hideUsername,
    Callback = function(v)
        hideUsername = v
        settings.webhook.hideUsername = v
        getgenv().HubSettings.webhook = settings.webhook
        saveHubSettings()
    end
})

WebhookTab:CreateToggle({
    Name = "On/Off Rare Egg Notification",
    CurrentValue = rareEggNotify,
    Callback = function(v)
        rareEggNotify = v
        settings.webhook.rareEggNotify = v
        getgenv().HubSettings.webhook = settings.webhook
        saveHubSettings()
    end
})

WebhookTab:CreateSection("Status")
WebhookTab:CreateLabel("Webhook is Running!")
WebhookTab:CreateLabel("Tracking: Secret, Celestial, Infinity, Void, Super Legendary, XL")
WebhookTab:CreateLabel("Alerts: 4x Egg")
WebhookTab:CreateLabel("Online ping: Every 30 minutes")
WebhookTab:CreateLabel("Stuck detection: Every 2 min, rejoin after 6 min of no hatches")
WebhookTab:CreateLabel("Fragments + Stats + Buff Times added")
WebhookTab:CreateLabel("Ping: "..(DISCORD_USER_ID ~= "" and "ON <@"..DISCORD_USER_ID..">" or "OFF"))

print("Webhook Is Online, Good Luck Hatching Guys! Me (Renoa The Finest) Wishing for our luck")
