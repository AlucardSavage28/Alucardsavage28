-- ================================================
-- WEBHOOK TAB (DUAL WEBHOOK + PUBLIC + HIDE USERNAME)
-- ================================================
repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local WebhookTab = Window:CreateTab("Webhook", nil)

-- ======================================
-- CHECK CONFIG
-- ======================================
local config = getgenv().config or {}

if not config.HATCH_WEBHOOK_URL or config.HATCH_WEBHOOK_URL == "" then
    WebhookTab:CreateSection("Webhook Not Configured")
    WebhookTab:CreateLabel("Please set your webhooks in the config before executing!")
    WebhookTab:CreateLabel("Add this BEFORE the loadstring in your executor:")
    WebhookTab:CreateLabel([[getgenv().config = {
    HATCH_WEBHOOK_URL = "Put your hatch webhook URL here!",
    ONLINE_WEBHOOK_URL = "Put your online ping webhook URL here!",
    DISCORD_USER_ID = "Put your Discord user ID here!"
}]])
    return
end

-- ======================================
-- SERVICES
-- ======================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

-- ======================================
-- WEBHOOK (from config)
-- ======================================
local HATCH_WEBHOOK_URL = config.HATCH_WEBHOOK_URL
local ONLINE_WEBHOOK_URL = config.ONLINE_WEBHOOK_URL or config.HATCH_WEBHOOK_URL
local DISCORD_USER_ID = config.DISCORD_USER_ID or ""
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
local hideUsername = false

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
    local s=tostring(math.floor(n))
    return s:reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,","")
end

-- ======================================
-- STATS
-- ======================================
local function getStats(eggName)
    local data = LocalData:Get()
    if not data then return "0","0","0" end
    return
        formatNum(data.Coins or 0),
        formatNum(data.Gems or 0),
        formatNum((data.EggsOpened and data.EggsOpened[eggName]) or 0)
end

-- ======================================
-- PET EXTRA
-- ======================================
local function getPetExtra(petInfo)
    local odds="Unknown"
    local exist="Unknown"
    if petInfo.Chance then
        local calc=math.floor(1/petInfo.Chance)
        if calc>0 then odds="1/"..formatExist(calc) end
    elseif petInfo.Odds then
        odds="1/"..formatExist(petInfo.Odds)
    end
    if petInfo.Exists then exist=formatExist(petInfo.Exists) end
    return odds,exist
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
-- WEBHOOK SYSTEM
-- ======================================
local hatchQueue={}
local onlineQueue={}
local publicQueue={}
local hatchProcessing=false
local onlineProcessing=false
local publicProcessing=false

local function sendToWebhook(queue, url)
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

local function processHatch()
    if hatchProcessing then return end
    hatchProcessing = true
    task.spawn(function()
        sendToWebhook(hatchQueue, HATCH_WEBHOOK_URL)
        hatchProcessing = false
    end)
end

local function processPublic()
    if publicProcessing then return end
    publicProcessing = true
    task.spawn(function()
        sendToWebhook(publicQueue, PUBLIC_WEBHOOK_URL)
        publicProcessing = false
    end)
end

local function processOnline()
    if onlineProcessing then return end
    onlineProcessing = true
    task.spawn(function()
        sendToWebhook(onlineQueue, ONLINE_WEBHOOK_URL)
        onlineProcessing = false
    end)
end

-- ======================================
-- SEND (for regular pets)
-- ======================================
local function send(petName, eggName, ex)
    local info = Pets[petName]
    if not info then return end

    local rarity = info.Rarity
    local tracked = false
    for r in pairs(TRACKED_RARITIES) do
        if rarity:find(r) then tracked = true; rarity = r; break end
    end
    if not tracked then return end

    local variant = getVariant(ex)
    local variantText = getVariantText(variant)
    local color = (COLORS[rarity] and COLORS[rarity][variant]) or 16777215
    local coins, gems, opened = getStats(eggName)
    local odds, exist = getPetExtra(info)
    local img = getImage(petName, ex)
    local displayName = hideUsername and "Hidden" or player.Name

    local embed = {
        title = "Congrats You Hatched A "..variantText.." "..rarity.." "..petName.."!",
        color = color,
        fields = {
            {name = "* User Info", value = "Name : "..displayName.."\nCoin : "..coins.."\nGems : "..gems.."\nEgg Hatched : "..opened, inline = false},
            {name = "Pet Info", value = "Odds : "..odds.."\nExist : "..exist, inline = false}
        },
        footer = {text = "Renoa The Finest has Blessed You! * "..os.date("%Y-%m-%d %H:%M:%S")}
    }
    if img then embed.thumbnail = {url = img} end

    table.insert(hatchQueue, {
        content = (rarity == "Secret") and "<@"..DISCORD_USER_ID..">" or nil,
        embeds = {embed}
    })
    processHatch()

    local publicEmbed = {
        title = "Congrats You Hatched A "..variantText.." "..rarity.." "..petName.."!",
        color = color,
        fields = {
            {name = "* User Info", value = "Name : Hidden", inline = false},
            {name = "Pet Info", value = "Odds : "..odds.."\nExist : "..exist, inline = false}
        },
        footer = {text = "Renoa The Finest has Blessed You! * "..os.date("%Y-%m-%d %H:%M:%S")}
    }
    if img then publicEmbed.thumbnail = {url = img} end
    table.insert(publicQueue, {embeds = {publicEmbed}})
    processPublic()
end

-- ======================================
-- ONLINE PING
-- ======================================
local startTime = os.time()
local lastHatches = 0
local lastPingTime = os.time()

local leaderstats = player:FindFirstChild("leaderstats")
if leaderstats then
    for _, stat in ipairs(leaderstats:GetChildren()) do
        if stat.Name:find("Hatches") then
            lastHatches = tonumber(stat.Value) or 0
        end
    end
end

task.spawn(function()
    while true do
        task.wait(1800)
        if ONLINE_WEBHOOK_URL == "" then continue end
        
        local elapsed = os.time() - startTime
        local hours = math.floor(elapsed / 3600)
        local minutes = math.floor((elapsed % 3600) / 60)
        local data = LocalData:Get()
        local coins = data and formatNum(data.Coins or 0) or "0"
        local gems = data and formatNum(data.Gems or 0) or "0"
        local leaderstats = player:FindFirstChild("leaderstats")
        local bubbles = "0"
        local currentHatches = 0
        if leaderstats then
            for _, stat in ipairs(leaderstats:GetChildren()) do
                if stat.Name:find("Bubble") then bubbles = formatNum(stat.Value) end
                if stat.Name:find("Hatches") then currentHatches = tonumber(stat.Value) or 0 end
            end
        end
        local timeSinceLastPing = (os.time() - lastPingTime) / 60
        local hatchesSinceLastPing = currentHatches - lastHatches
        local perMin = timeSinceLastPing > 0 and math.floor(hatchesSinceLastPing / timeSinceLastPing) or 0
        local perHour = perMin * 60
        lastHatches = currentHatches
        lastPingTime = os.time()

        table.insert(onlineQueue, {
            embeds = {{
                title = "Still Online!",
                description =
                    "**" .. player.Name .. "** is still online!\n\n" ..
                    "Online: " .. hours .. "h " .. minutes .. "m\n" ..
                    "Coins: " .. coins .. "\nGems: " .. gems .. "\nBubbles: " .. bubbles .. "\n\n" ..
                    "**Hatch Rate**\nPer Minute: " .. perMin .. "\nPer Hour: " .. perHour,
                color = 3447003,
                footer = {text = "Renoa Hub * " .. os.date("%Y-%m-%d %H:%M:%S")}
            }}
        })
        processOnline()
    end
end)

-- ======================================
-- HOOK (REGULAR PETS ONLY)
-- ======================================
local success, mod = pcall(function()
    return require(ReplicatedStorage.Client.Effects.HatchEgg)
end)
if success and mod then
    local originalPlay = mod.Play
    local hookedFunction = newcclosure(function(self, data)
        if type(data) == "table" and data.Pets then
            for _, p in ipairs(data.Pets) do
                local pet = p.Pet or p
                if pet and pet.Name and not pet.Super then
                    local ex = {Shiny = pet.Shiny, Mythic = pet.Mythic, XL = pet.XL}
                    send(pet.Name, data.Name or "Egg", ex)
                end
            end
        end
        if getgenv().animationHidden then return end
        return originalPlay(self, data)
    end)
    mod.Play = hookedFunction
end

-- ======================================
-- SUPER LEGENDARY INVENTORY SCANNER
-- ======================================
local knownSL = {}
local initData = LocalData:Get()
if initData and initData.Pets then
    for _, pet in pairs(initData.Pets) do
        if pet.Super then knownSL[pet.Id] = true end
    end
end

task.spawn(function()
    while true do
        task.wait(10)
        local data = LocalData:Get()
        if data and data.Pets then
            for _, pet in pairs(data.Pets) do
                if pet.Super and not knownSL[pet.Id] then
                    knownSL[pet.Id] = true
                    local enchantNames = {}
                    if pet.Enchants then
                        for _, enchant in pairs(pet.Enchants) do
                            if enchant.Id then table.insert(enchantNames, enchant.Id) end
                        end
                    end
                    local displayEnchants = {}
                    for _, id in ipairs(enchantNames) do
                        table.insert(displayEnchants, ENCHANT_NAMES[id] or id)
                    end
                    local displayStr = #displayEnchants > 0 and table.concat(displayEnchants, ", ") or "None"
                    local variant = "Normal"
                    if pet.Shiny and pet.Mythic then variant = "Shiny Mythic"
                    elseif pet.Shiny then variant = "Shiny"
                    elseif pet.Mythic then variant = "Mythic" end
                    local displayName = hideUsername and "Hidden" or player.Name

                    local embed = {
                        title = "Congrats You Hatched A "..variant.." Super Legendary "..pet.Name.."!",
                        color = 0x1E90FF,
                        fields = {
                            {name = "* User Info", value = "Name : "..displayName, inline = false},
                            {name = "Ultra Legendary Enchant", value = displayStr, inline = false}
                        },
                        footer = {text = "Renoa The Finest has Blessed You! * "..os.date("%Y-%m-%d %H:%M:%S")}
                    }
                    local pingMsg = "<@"..DISCORD_USER_ID..">"
                    if displayStr ~= "None" then
                        pingMsg = "<@"..DISCORD_USER_ID..">, You Got "..displayStr.."!"
                    end
                    
                    table.insert(hatchQueue, {content = pingMsg, embeds = {embed}})
                    processHatch()
                    
                    -- Public webhook (same layout, no ping, hidden name)
                    local publicEmbed = {
                        title = "Congrats You Hatched A "..variant.." Super Legendary "..pet.Name.."!",
                        color = 0x1E90FF,
                        fields = {
                            {name = "* User Info", value = "Name : Hidden", inline = false},
                            {name = "Ultra Legendary Enchant", value = displayStr, inline = false}
                        },
                        footer = {text = "Renoa The Finest has Blessed You! * "..os.date("%Y-%m-%d %H:%M:%S")}
                    }
                    table.insert(publicQueue, {embeds = {publicEmbed}})
                    processPublic()
                end
            end
        end
    end
end)

-- ======================================
-- UI
-- ======================================
WebhookTab:CreateSection("Settings")

WebhookTab:CreateToggle({
    Name = "Hide Username (shows 'Hidden')",
    CurrentValue = false,
    Callback = function(v)
        hideUsername = v
    end
})

WebhookTab:CreateSection("Status")
WebhookTab:CreateLabel("Webhook is Running!")
WebhookTab:CreateLabel("Tracking: Secret, Celestial, Infinity, Void, Super Legendary")
WebhookTab:CreateLabel("Online ping: Every 30 minutes")
WebhookTab:CreateLabel("Ping: "..(DISCORD_USER_ID ~= "" and "ON <@"..DISCORD_USER_ID..">" or "OFF"))

print("Webhook Is Online, Good Luck Hatching Guys! Me (Renoa The Finest) Wishing for our luck")
