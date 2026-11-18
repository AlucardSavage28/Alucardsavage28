-- ================================================
-- EVENT TAB (WINDUI VERSION)
-- ================================================
repeat task.wait() until getgenv().Window
local Window = getgenv().Window
local WindUI = getgenv().WindUI

local EventTab = Window:Tab({ Title = "Event", Icon = "calendar" })

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)
local Pets = require(ReplicatedStorage.Shared.Data.Pets)
local RE = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteEvent
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local RemoteContainer = ReplicatedStorage.Shared.Framework.Network.Remote
local RemoteFunction = RemoteContainer.RemoteFunction
local Remote = require(ReplicatedStorage.Shared.Framework.Network.Remote)

local request = http_request or request or (syn and syn.request)

-- ======================================
-- LOAD SAVED SETTINGS
-- ======================================
local settings = getgenv().HubSettings or {}
if not settings.event then settings.event = {} end
local eventSettings = settings.event

-- ======================================
-- SETTINGS
-- ======================================
local selectedEvents = eventSettings.selectedEvents or {"Luck Event"}
if type(selectedEvents) == "string" then selectedEvents = {selectedEvents} end

local eventRunning = false
local eventThread = nil

local autoHatchRiftEnabled = eventSettings.autoHatchRift or false
local autoHatchRiftThread = nil
local autoSummonRiftEnabled = eventSettings.autoSummonRift or false
local autoSummonRiftThread = nil

local HATCH_AMOUNT = 12
local riftName = "cloud-rift"
local riftEgg = "Cloudy Rift Egg"
local riftWorld = "The Overworld"

local EVENTS = {
    "Luck Event", "Shiny Event", "Mythic Event", "Celestial Event",
    "Secret Event", "Infinity Event", "XL Event", "Super Palooza"
}

-- ======================================
-- HALLOWEEN UPGRADES
-- ======================================
local HALLOWEEN_UPGRADES = {
    "Currency",
    "Luck",
    "SecretLuck",
    "InfinityLuck",
    "AutoRebirth",
}

local selectedUpgrades = eventSettings.selectedUpgrades or {}
if type(selectedUpgrades) == "string" then selectedUpgrades = {selectedUpgrades} end

local halloweenUpgradeBuying = false
local halloweenUpgradeThread = nil
local rebirthShopBuying = false
local rebirthShopThread = nil
local eventShopBuying = false
local eventShopThread = nil
local halloweenRebirthAuto = false
local halloweenRebirthThread = nil

-- Dark Shop
local darkShopBuying = false
local darkShopThread = nil
local currentDarkShopItems = {
    "Super Legendary Elixir",
    "Super XL Elixir",
    "Super Secret Elixir",
    "Super Infinity Elixir",
    "Boost Crystal x20"
}
local selectedDarkShopItems = eventSettings.selectedDarkShopItems or {}
if type(selectedDarkShopItems) == "string" then selectedDarkShopItems = {selectedDarkShopItems} end

-- Event Shrine
local shrineRunning = false
local shrineThread = nil
local TARGET_BUFF_OPTIONS = {"Luck", "Shiny", "Mythic", "Secret", "Infinity"}
local targetShrineBuff = eventSettings.targetShrineBuff or "Luck"

-- ======================================
-- DYNAMIC SHOP SCANNER
-- ======================================
local function getShopItems(shopKey)
    local items = {}
    local ok, Shops = pcall(function() return require(ReplicatedStorage.Shared.Data.Shops) end)
    if ok and Shops and Shops[shopKey] and Shops[shopKey].PermanentItems then
        for i, slot in ipairs(Shops[shopKey].PermanentItems) do
            local p = slot.Item or slot
            local prod = p.Product
            if prod then
                local name = prod.Name or "Unknown"
                local level = prod.Level
                local isXL = prod.XL
                
                if level then
                    name = name .. " Lvl " .. tostring(level)
                elseif isXL then
                    name = name .. " (XL)"
                elseif prod.Amount and prod.Amount > 1 then
                    name = name .. " x" .. tostring(prod.Amount)
                end
                table.insert(items, name)
            end
        end
    end
    return items
end

local currentRebirthShopItems = getShopItems("hw26rebirth-shop")
local currentEventShopItems = getShopItems("spooky-shop")

local selectedRebirthItems = eventSettings.selectedRebirthItems or {}
if type(selectedRebirthItems) == "string" then selectedRebirthItems = {selectedRebirthItems} end

local selectedShopItems = eventSettings.selectedShopItems or {}
if type(selectedShopItems) == "string" then selectedShopItems = {selectedShopItems} end

-- ======================================
-- EVENT BOARD READER
-- ======================================
local function getAllActiveEvents()
    local events = {}
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        local screenGui = playerGui:FindFirstChild("ScreenGui")
        if screenGui then
            local eventBoard = screenGui:FindFirstChild("EventBoard")
            if eventBoard then
                local activeEvents = eventBoard:FindFirstChild("Frame") and eventBoard.Frame:FindFirstChild("Main") and eventBoard.Frame.Main:FindFirstChild("ActiveEvents")
                if activeEvents then
                    local container = activeEvents:FindFirstChild("Container")
                    if container then
                        local list = container:FindFirstChild("List")
                        if list then
                            for _, child in ipairs(list:GetChildren()) do
                                if child:IsA("Frame") and child.Name ~= "UIListLayout" and child.Name ~= "UIPadding" then
                                    local frame = child:FindFirstChild("Frame")
                                    if frame then
                                        local title = frame:FindFirstChild("Title")
                                        if title then
                                            local eventLabel = title:FindFirstChild("Event")
                                            if eventLabel then
                                                local eventText = eventLabel.Text
                                                if eventText and eventText ~= "" then
                                                    table.insert(events, eventText)
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return events
end

local function getActiveEventDisplay()
    local events = getAllActiveEvents()
    if #events == 0 then return "No Event" end
    return table.concat(events, ", ")
end

-- ======================================
-- SPAWNABLE RIFT FUNCTIONS
-- ======================================
local function isRiftExists(riftName)
    local riftFolder = workspace:FindFirstChild("Rendered")
    if riftFolder then
        riftFolder = riftFolder:FindFirstChild("Rifts")
        if riftFolder and riftFolder:FindFirstChild(riftName) then
            return true
        end
    end
    return false
end

local function getRiftLuck(rift)
    local display = rift:FindFirstChild("Display")
    if display then
        local surfaceGui = display:FindFirstChild("SurfaceGui")
        if surfaceGui then
            for _, child in ipairs(surfaceGui:GetDescendants()) do
                if child:IsA("TextLabel") and child.Name == "Luck" then
                    local luck = child.Text:match("x(%d+)")
                    if luck then
                        return tonumber(luck)
                    end
                end
            end
        end
    end
    return 0
end

local function getHighestLuckRift(riftName)
    local riftFolder = workspace:FindFirstChild("Rendered")
    if riftFolder then
        riftFolder = riftFolder:FindFirstChild("Rifts")
        if riftFolder then
            local bestRift = nil
            local bestLuck = 0
            
            for _, rift in ipairs(riftFolder:GetChildren()) do
                if rift.Name == riftName then
                    local luck = getRiftLuck(rift)
                    if luck > bestLuck then
                        bestLuck = luck
                        bestRift = rift
                    end
                end
            end
            
            return bestRift, bestLuck
        end
    end
    return nil, 0
end

local function teleportToBestRift(riftName)
    local bestRift, bestLuck = getHighestLuckRift(riftName)
    if bestRift then
        local spawn = bestRift:FindFirstChild("EggPlatformSpawn")
        if spawn then
            local part = spawn:FindFirstChild("Part")
            if part then
                local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    root.CFrame = CFrame.new(part.Position + Vector3.new(0, 5, 0))
                    root.Velocity = Vector3.zero
                    root.RotVelocity = Vector3.zero
                    return bestLuck
                end
            end
        end
    end
    return 0
end

local function summonRift()
    pcall(function()
        RemoteFunction:InvokeServer("SummonRift", {
            Type = "Egg",
            Name = riftEgg,
            Time = 5,
            Luck = 5,
            World = riftWorld
        })
    end)
end

-- ======================================
-- SUMMON WEBHOOK
-- ======================================
local lastSummonState = ""

local function sendSummonWebhook(success)
    local webhookURL = settings.activity and settings.activity.webhookURL or ""
    local discordID = settings.activity and settings.activity.userId or ""
    
    if webhookURL == "" then return end
    if not request then return end
    
    local content = ""
    local color = 0
    
    if success then
        content = "Summon Cloud Rift Success✅"
        color = 0x00FF00
    else
        if discordID ~= "" then
            content = "Failed Summoning Cloud Rift❌ <@" .. discordID .. ">"
        else
            content = "Failed Summoning Cloud Rift❌"
        end
        color = 0xFF0000
    end
    
    if content == lastSummonState then return end
    lastSummonState = content
    
    pcall(function()
        request({
            Url = webhookURL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                content = content,
                allowed_mentions = {parse = {"users"}},
                embeds = {{
                    title = success and "✅ Rift Summoned" or "❌ Summon Failed",
                    description = "**" .. player.Name .. "**",
                    color = color,
                    footer = {text = "Renoa Hub * " .. os.date("%Y-%m-%d %H:%M:%S")}
                }}
            })
        })
    end)
end

-- ======================================
-- UI - EVENT BOARD
-- ======================================
EventTab:Section({ Title = "Event Board" })

local activeEventParagraph = EventTab:Paragraph({
    Title = "Active: " .. getActiveEventDisplay(),
    Desc = "Updates every 15 min or when event changes",
})

local lastEventDisplay = getActiveEventDisplay()
local lastEventUpdate = tick()
local EVENT_UPDATE_INTERVAL = 900

task.spawn(function()
    while true do
        task.wait(30)
        
        local display = getActiveEventDisplay()
        local now = tick()
        
        local shouldUpdateUI = (now - lastEventUpdate) >= EVENT_UPDATE_INTERVAL
        local eventChanged = (display ~= lastEventDisplay)
        
        if eventChanged then
            pcall(function() activeEventParagraph:SetTitle("Active: " .. display) end)
            lastEventDisplay = display
            lastEventUpdate = now
            
            if display == "No Event" then
                getgenv().ActivityStatus.current = "Event Board = No Event (removed)"
            else
                getgenv().ActivityStatus.current = "Event Board = " .. display .. " (activated)"
            end
            getgenv().ActivityStatus.trigger = true
        elseif shouldUpdateUI then
            pcall(function() activeEventParagraph:SetTitle("Active: " .. display) end)
            lastEventUpdate = now
        end
    end
end)

EventTab:Dropdown({
    Title = "Select Events (Multi-Select)",
    Values = EVENTS,
    Value = selectedEvents,
    Multi = true,
    Callback = function(v)
        if type(v) == "table" then
            selectedEvents = v
        else
            selectedEvents = {v}
        end
        eventSettings.selectedEvents = selectedEvents
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
    end,
})

EventTab:Toggle({
    Title = "Auto Add Event",
    Desc = "Adds selected events to the Event Board every 15 minutes",
    Value = eventSettings.autoAddEvent or false,
    Callback = function(v)
        eventRunning = v
        eventSettings.autoAddEvent = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            eventThread = task.spawn(function()
                while eventRunning do
                    for _, eventName in ipairs(selectedEvents) do
                        if not eventRunning then break end
                        local value = type(eventName) == "table" and eventName[1] or eventName
                        pcall(function() RE:FireServer("PurchaseEventBoard", value) end)
                        task.wait(1)
                    end
                    task.wait(900)
                end
            end)
        else
            if eventThread then task.cancel(eventThread) end
        end
    end,
})

-- ======================================
-- UI - DARK SHOP
-- ======================================
EventTab:Section({ Title = "Dark Shop" })

EventTab:Dropdown({
    Title = "Select Items (Multi-Select)",
    Values = currentDarkShopItems,
    Value = selectedDarkShopItems,
    Multi = true,
    Callback = function(v)
        if type(v) == "table" then
            selectedDarkShopItems = v
        else
            selectedDarkShopItems = {v}
        end
        eventSettings.selectedDarkShopItems = selectedDarkShopItems
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
    end,
})

EventTab:Toggle({
    Title = "Auto Buy Dark Shop",
    Desc = "Buys the selected Dark Shop items continuously",
    Value = eventSettings.autoBuyDarkShop or false,
    Callback = function(v)
        darkShopBuying = v
        eventSettings.autoBuyDarkShop = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            darkShopThread = task.spawn(function()
                while darkShopBuying do
                    for _, item in ipairs(selectedDarkShopItems) do
                        if not darkShopBuying then break end
                        local value = type(item) == "table" and item[1] or item
                        local slotIndex = nil
                        for i, name in ipairs(currentDarkShopItems) do
                            if name == value then slotIndex = i; break end
                        end
                        if slotIndex then
                            pcall(function() RE:FireServer("BuyShopItem", "darkmarket-shop", slotIndex, true) end)
                            task.wait(0.5)
                        end
                    end
                    task.wait(5)
                end
            end)
        else
            if darkShopThread then task.cancel(darkShopThread) end
        end
    end,
})

-- ======================================
-- UI - EVENT CHEST
-- ======================================
EventTab:Section({ Title = "Event Chest" })

local halloweenChestClaiming = false
local halloweenChestThread = nil

EventTab:Toggle({
    Title = "Auto Claim Halloween Chest",
    Desc = "Claims Halloween Chest when cooldown is ready",
    Value = eventSettings.autoClaimHalloweenChest or false,
    Callback = function(v)
        halloweenChestClaiming = v
        eventSettings.autoClaimHalloweenChest = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            halloweenChestThread = task.spawn(function()
                while halloweenChestClaiming do
                    local data = LocalData:Get()
                    local cooldowns = data and data.Cooldowns
                    local cd = cooldowns and cooldowns["Halloween Chest"]

                    if cd and os.time() >= cd then
                        pcall(function()
                            Remote:FireServer("ClaimChest", "Halloween Chest")
                        end)
                    end
                    task.wait(5)
                end
            end)
        else
            if halloweenChestThread then task.cancel(halloweenChestThread) end
        end
    end,
})

-- ======================================
-- UI - HALLOWEEN UPGRADES
-- ======================================
EventTab:Section({ Title = "Halloween Upgrades" })

EventTab:Dropdown({
    Title = "Select Upgrades (Multi-Select)",
    Values = HALLOWEEN_UPGRADES,
    Value = selectedUpgrades,
    Multi = true,
    Callback = function(v)
        if type(v) == "table" then
            selectedUpgrades = v
        else
            selectedUpgrades = {v}
        end
        eventSettings.selectedUpgrades = selectedUpgrades
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
    end,
})

EventTab:Toggle({
    Title = "Auto Buy Selected Upgrades",
    Desc = "Buys the selected Halloween upgrades continuously",
    Value = eventSettings.autoBuyUpgrades or false,
    Callback = function(v)
        halloweenUpgradeBuying = v
        eventSettings.autoBuyUpgrades = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            halloweenUpgradeThread = task.spawn(function()
                while halloweenUpgradeBuying do
                    for _, upgrade in ipairs(selectedUpgrades) do
                        if not halloweenUpgradeBuying then break end
                        local value = type(upgrade) == "table" and upgrade[1] or upgrade
                        pcall(function() RE:FireServer("BuyHalloween26Upgrade", value) end)
                        task.wait(0.5)
                    end
                    task.wait(5)
                end
            end)
        else
            if halloweenUpgradeThread then task.cancel(halloweenUpgradeThread) end
        end
    end,
})

-- ======================================
-- UI - EVENT CHALLENGE PASS (WINTER PASS)
-- ======================================
EventTab:Section({ Title = "Event Challenge Pass" })

EventTab:Paragraph({
    Title = "⚠️ Note",
    Desc = "Turn off: All Quest Tab, Auto Rain, Auto sell Bubble, Auto Hatch, Auto Special Egg, and Auto\nTurn On: Hide Hatch Animation",
})

EventTab:Paragraph({
    Title = "⚠️ Note 2",
    Desc = "untested",
})

local cpEnabled = false
local cpThread = nil
local claimEnabled = false
local claimThread = nil
local PASS_POS = Vector3.new(77, 8, 46)

local EGG_LOCATIONS = {
    ["Common Egg"] = Vector3.new(-80, 7, 5), ["Classic Egg"] = Vector3.new(-90, 13, 30),
    ["Vine Egg"] = Vector3.new(-61, 13, 11), ["Lava Egg"] = Vector3.new(-69, 14, 19),
    ["Icy Egg"] = Vector3.new(-55, 14, 0), ["Iceshard Egg"] = Vector3.new(-119, 11, 13),
    ["Spotted Egg"] = Vector3.new(-11, 10, -69), ["Atlantis Egg"] = Vector3.new(-79, 14, 25),
    ["Mining Egg"] = Vector3.new(-122, 11, -69), ["Neon Egg"] = Vector3.new(-81, 10, -61),
    ["Cyber Egg"] = Vector3.new(-92, 10, -67), ["Rainbow Egg"] = Vector3.new(-140, 10, -57),
    ["Nightmare Egg"] = Vector3.new(-146, 10, -47), ["Infinity Egg"] = Vector3.new(-106, 12, -28),
    ["Secret Egg"] = Vector3.new(-19438, 8, 18839), ["Showman Egg"] = Vector3.new(-130, 10, -60),
    ["Spikey Egg"] = Vector3.new(-128, 10, 9), ["Magma Egg"] = Vector3.new(-137, 11, 3),
    ["Crystal Egg"] = Vector3.new(-144, 10, -5), ["Lunar Egg"] = Vector3.new(-148, 11, -15),
    ["Void Egg"] = Vector3.new(-150, 11, -26), ["Hell Egg"] = Vector3.new(-149, 11, -37),
    ["Harvest Egg"] = Vector3.new(292, 9, 197), ["Neon Pumpkin Egg"] = Vector3.new(284, 9, 207),
}

local KNOWN_EGGS = {}
for name, _ in pairs(EGG_LOCATIONS) do KNOWN_EGGS[name] = true end
local KNOWN_RARITIES = { ["Secret"]=true, ["Celestial"]=true, ["Infinity"]=true, ["Void"]=true, ["Super Legendary"]=true, ["Legendary"]=true, ["Epic"]=true, ["Rare"]=true }

local function getRoot() local c = player.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function teleportTo(pos) local root = getRoot(); if root and pos then root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) end end

local function getChallengeFrame()
    local pg = player:FindFirstChild("PlayerGui")
    local sg = pg and pg:FindFirstChild("ScreenGui")
    return sg and sg:FindFirstChild("ChallengePass")
end

local function parseNumber(str)
    if not str then return 0 end
    local clean = str:gsub(",", "")
    return tonumber(clean) or 0
end

local function classify(text)
    local num = text:match("Blow%s+([%d,]+)%s+Bubbles")
    if num then return { type = "Bubbles", amount = parseNumber(num), raw = text } end
    
    local mins = text:match("Play%s+for%s+([%d,]+)%s+minutes")
    if mins then return { type = "Playtime", amount = parseNumber(mins), raw = text } end

    local hatchNum, hatchTarget = text:match("Hatch%s+([%d,]+)%s+(.+)$")
    if hatchNum then
        local amount = parseNumber(hatchNum)
        local cleanTarget = hatchTarget:gsub("%s*Eggs?$", ""):gsub("%s*Pets?$", ""):gsub("%s+$", "")
        if cleanTarget == "" then return { type = "HatchAny", amount = amount, raw = text } end
        local eggName = cleanTarget
        if not eggName:find("Egg") then eggName = eggName .. " Egg" end
        if KNOWN_EGGS[eggName] then return { type = "HatchEgg", egg = eggName, amount = amount, raw = text } end
        if KNOWN_RARITIES[cleanTarget] then return { type = "HatchRarity", rarity = cleanTarget, amount = amount, raw = text } end
        if eggName:find("Egg") then return { type = "HatchEgg", egg = eggName, amount = amount, raw = text } end
        return { type = "HatchUnknown", target = cleanTarget, amount = amount, raw = text }
    end
    
    local collectNum, collectTarget = text:match("Collect%s+([%d,]+)%s+(.+)$")
    if collectNum then return { type = "Collect", currency = collectTarget, amount = parseNumber(collectNum), raw = text } end
    
    return { type = "Unknown", raw = text }
end

local function readChallenges()
    local cp = getChallengeFrame()
    if not cp then return {} end
    local results = {}
    local list = cp:FindFirstChild("List", true)
    if not list then return results end
    for _, frame in ipairs(list:GetChildren()) do
        if frame:IsA("Frame") then
            local content = frame:FindFirstChild("Content")
            if content then
                local label = content:FindFirstChild("Label")
                local bar = content:FindFirstChild("Bar")
                local barLabel = bar and bar:FindFirstChild("Label")
                if label and barLabel then
                    local text = label.Text
                    local progressStr = barLabel.Text:gsub("%%", "")
                    local progress = tonumber(progressStr) or 0
                    local parsed = classify(text)
                    parsed.progress = progress
                    parsed.frame = frame
                    parsed.complete = (progress >= 100)
                    table.insert(results, parsed)
                end
            end
        end
    end
    return results
end

local function doBubbles(challenge)
    local startProg = challenge.progress
    local stallCount = 0
    local hit100 = false
    local overkillTimer = 0
    
    while cpEnabled do
        for _ = 1, 10 do
            pcall(function() RE:FireServer("BlowBubble") end)
            task.wait(0.02)
        end
        if not hit100 then
            task.wait(2)
            local fresh = readChallenges()
            local found = nil
            for _, c in ipairs(fresh) do if c.raw == challenge.raw then found = c; break end end
            if not found or found.complete then 
                hit100 = true; overkillTimer = os.clock()
            elseif found.progress > startProg then
                startProg = found.progress; stallCount = 0
            else
                stallCount = stallCount + 1
                if stallCount >= 30 then return false end
            end
        else
            if os.clock() - overkillTimer >= 5 then return true end
            task.wait(0.5)
        end
    end
    return false
end

local function doHatch(challenge, eggName)
    local pos = EGG_LOCATIONS[eggName]
    if pos then teleportTo(pos) end
    task.wait(0.3)
    
    local startProg = challenge.progress
    local stallCount = 0
    local hit100 = false
    local overkillTimer = 0
    
    -- HARDCODED SPAM E THREAD (Matches Eggs.lua exactly)
    local spamEThread = task.spawn(function()
        while cpEnabled do
            if hit100 and (os.clock() - overkillTimer >= 5) then break end
            
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.03)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
            
            local eggToHatch = eggName or "Infinity Egg"
            if eggToHatch then
                pcall(function() Remote:FireServer("HatchEgg", eggToHatch, 12) end)
            end
            task.wait(0.03)
        end
    end)
    
    while cpEnabled do
        if not hit100 then
            task.wait(1)
            local fresh = readChallenges()
            local found = nil
            for _, c in ipairs(fresh) do if c.raw == challenge.raw then found = c; break end end
            
            if not found or found.complete then
                hit100 = true; overkillTimer = os.clock()
            elseif found.progress > startProg then
                startProg = found.progress; stallCount = 0
            else
                stallCount = stallCount + 1
                if stallCount >= 30 then break end
            end
        else
            if os.clock() - overkillTimer >= 5 then break end
            task.wait(0.5) 
        end
    end
    
    task.cancel(spamEThread)
    return true
end

local function doChallenge(challenge)
    if challenge.complete then return true end
    if challenge.type == "Bubbles" then return doBubbles(challenge)
    elseif challenge.type == "HatchEgg" then return doHatch(challenge, challenge.egg)
    elseif challenge.type == "HatchAny" then return doHatch(challenge, "Infinity Egg")
    elseif challenge.type == "HatchRarity" then return doHatch(challenge, "Nightmare Egg")
    elseif challenge.type == "Playtime" then return doHatch(challenge, "Infinity Egg")
    elseif challenge.type == "HatchUnknown" then return false
    elseif challenge.type == "Collect" then return false
    else return false end
end

-- ================================================
-- AUTO CLAIM & RESET LOGIC
-- ================================================
local function claimAllRewards()
    pcall(function() RE:FireServer("ChallengePassClaimReward") end)
    
    local cp = getChallengeFrame()
    if cp then
        local btn = cp:FindFirstChild("Button", true)
        local claimFrame = cp:FindFirstChild("ClaimAll", true)
        if claimFrame then btn = claimFrame:FindFirstChild("Button") or btn end
        
        if btn and btn:IsA("ImageButton") then
            local center = btn.AbsolutePosition + (btn.AbsoluteSize / 2)
            pcall(function()
                VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 1)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 1)
            end)
        end
    end
end

local function checkAndReset()
    local data = LocalData:Get()
    if not data or not data.ChallengePass then return false end
    
    local claimed = data.ChallengePass.Claimed or {}
    local claimedMap = {}
    for _, v in ipairs(claimed) do claimedMap[v] = true end
    
    local allClaimed = true
    for tier = 1, 15 do
        if not claimedMap[tier] then allClaimed = false; break end
    end
    
    if allClaimed then
        pcall(function() RE:FireServer("ChallengePassReset") end)
        task.wait(3)
        return true
    end
    return false
end

EventTab:Toggle({
    Title = "Auto Event Challenge Pass",
    Value = eventSettings.autoChallengePass or false,
    Callback = function(v)
        cpEnabled = v
        eventSettings.autoChallengePass = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        
        if v then
            getgenv().ActivityStatus.current = "Auto Event Challange Pass"
            getgenv().ActivityStatus.trigger = true
            
            cpThread = task.spawn(function()
                teleportTo(PASS_POS)
                task.wait(4)
                
                while cpEnabled do
                    if checkAndReset() then
                        task.wait(5)
                        continue
                    end
                    
                    local challenges = readChallenges()
                    if #challenges == 0 then 
                        task.wait(5) 
                        continue 
                    end
                    
                    local allDone = true
                    for _, c in ipairs(challenges) do if not c.complete then allDone = false; break end end
                    
                    if allDone then
                        task.wait(3)
                        local newChallenges = readChallenges()
                        local stillComplete = true
                        for _, c in ipairs(newChallenges) do if not c.complete then stillComplete = false; break end end
                        if stillComplete then task.wait(15) end
                        continue
                    end
                    
                    for _, c in ipairs(challenges) do
                        if not cpEnabled then break end
                        if not c.complete then doChallenge(c) end
                    end
                    
                    task.wait(2)
                end
            end)
        else
            if cpThread then task.cancel(cpThread); cpThread = nil end
        end
    end,
})

EventTab:Toggle({
    Title = "Auto Claim & Reset Pass",
    Desc = "Spams claim every 3s and resets when all 15 tiers are claimed",
    Value = eventSettings.autoClaimPass or false,
    Callback = function(v)
        claimEnabled = v
        eventSettings.autoClaimPass = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        
        if v then
            claimThread = task.spawn(function()
                while claimEnabled do
                    claimAllRewards()
                    task.wait(3)
                    if checkAndReset() then
                        task.wait(5)
                    end
                end
            end)
        else
            if claimThread then task.cancel(claimThread); claimThread = nil end
        end
    end,
})

-- ======================================
-- UI - REBIRTH SHOP (Dynamic)
-- ======================================
EventTab:Section({ Title = "Rebirth Shop" })

local rebirthShopDropdown = EventTab:Dropdown({
    Title = "Select Items (Multi-Select)",
    Values = currentRebirthShopItems,
    Value = selectedRebirthItems,
    Multi = true,
    Callback = function(v)
        if type(v) == "table" then
            selectedRebirthItems = v
        else
            selectedRebirthItems = {v}
        end
        eventSettings.selectedRebirthItems = selectedRebirthItems
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
    end,
})

EventTab:Button({
    Title = "Re Scan Rebirth Shop",
    Desc = "Refreshes the list of items",
    Callback = function()
        currentRebirthShopItems = getShopItems("hw26rebirth-shop")
        for i = #rebirthShopDropdown.Values, 1, -1 do rebirthShopDropdown.Values[i] = nil end
        for _, v in ipairs(currentRebirthShopItems) do table.insert(rebirthShopDropdown.Values, v) end
        pcall(function() rebirthShopDropdown:Select(rebirthShopDropdown.Value) end)
    end,
})

EventTab:Toggle({
    Title = "Auto Buy Selected Items",
    Desc = "Buys the selected Rebirth shop items continuously",
    Value = eventSettings.autoBuyRebirthShop or false,
    Callback = function(v)
        rebirthShopBuying = v
        eventSettings.autoBuyRebirthShop = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            rebirthShopThread = task.spawn(function()
                while rebirthShopBuying do
                    for _, item in ipairs(selectedRebirthItems) do
                        if not rebirthShopBuying then break end
                        local value = type(item) == "table" and item[1] or item
                        local slotIndex = nil
                        for i, name in ipairs(currentRebirthShopItems) do
                            if name == value then slotIndex = i; break end
                        end
                        if slotIndex then
                            pcall(function() RE:FireServer("BuyShopItem", "hw26rebirth-shop", slotIndex, false) end)
                            task.wait(0.5)
                        end
                    end
                    task.wait(5)
                end
            end)
        else
            if rebirthShopThread then task.cancel(rebirthShopThread) end
        end
    end,
})

-- ======================================
-- UI - EVENT SHOP (Dynamic)
-- ======================================
EventTab:Section({ Title = "Event Shop" })

local eventShopDropdown = EventTab:Dropdown({
    Title = "Select Items (Multi-Select)",
    Values = currentEventShopItems,
    Value = selectedShopItems,
    Multi = true,
    Callback = function(v)
        if type(v) == "table" then
            selectedShopItems = v
        else
            selectedShopItems = {v}
        end
        eventSettings.selectedShopItems = selectedShopItems
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
    end,
})

EventTab:Button({
    Title = "Re Scan Event Shop",
    Desc = "Refreshes the list of items",
    Callback = function()
        currentEventShopItems = getShopItems("spooky-shop")
        for i = #eventShopDropdown.Values, 1, -1 do eventShopDropdown.Values[i] = nil end
        for _, v in ipairs(currentEventShopItems) do table.insert(eventShopDropdown.Values, v) end
        pcall(function() eventShopDropdown:Select(eventShopDropdown.Value) end)
    end,
})

EventTab:Toggle({
    Title = "Auto Buy Selected Items",
    Desc = "Buys the selected Event shop items continuously",
    Value = eventSettings.autoBuyShop or false,
    Callback = function(v)
        eventShopBuying = v
        eventSettings.autoBuyShop = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            eventShopThread = task.spawn(function()
                while eventShopBuying do
                    for _, item in ipairs(selectedShopItems) do
                        if not eventShopBuying then break end
                        local value = type(item) == "table" and item[1] or item
                        local slotIndex = nil
                        for i, name in ipairs(currentEventShopItems) do
                            if name == value then slotIndex = i; break end
                        end
                        if slotIndex then
                            pcall(function() RE:FireServer("BuyShopItem", "spooky-shop", slotIndex, true) end)
                            task.wait(0.5)
                        end
                    end
                    task.wait(5)
                end
            end)
        else
            if eventShopThread then task.cancel(eventShopThread) end
        end
    end,
})

-- ======================================
-- UI - EVENT SHRINE
-- ======================================
EventTab:Section({ Title = "Event Shrine" })

EventTab:Paragraph({
    Title = "⚠️ Important",
    Desc = "Donate and claim buff manually after that turn on this and u dont have to worry about it anymore",
})

EventTab:Dropdown({
    Title = "Target Buff",
    Values = TARGET_BUFF_OPTIONS,
    Value = targetShrineBuff,
    Callback = function(v)
        targetShrineBuff = v
        eventSettings.targetShrineBuff = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
    end,
})

EventTab:Toggle({
    Title = "Auto Event Shrine Reroll",
    Desc = "Rerolls purely via remotes in the background",
    Value = eventSettings.autoShrineReroll or false,
    Callback = function(v)
        shrineRunning = v
        eventSettings.autoShrineReroll = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            getgenv().ActivityStatus.current = "Auto rerolling for " .. targetShrineBuff .. " -Event Shrine"
            getgenv().ActivityStatus.trigger = true

            shrineThread = task.spawn(function()
                local foundTarget = false
                
                while shrineRunning do
                    task.wait(1)
                    local data = LocalData:Get()
                    local shrine = data and data.HalloweenShrine
                    
                    if shrine and shrine.Buff then
                        local currentBuff = tostring(shrine.Buff)
                        
                        if currentBuff == "None" then
                            task.wait(5)
                        elseif currentBuff:lower() ~= targetShrineBuff:lower() then
                            pcall(function() Remote:FireServer("RerollHalloweenShrine") end)
                            task.wait(3)
                        else
                            if shrine.StartTime and shrine.StartTime > 0 then
                                local elapsed = os.time() - shrine.StartTime
                                local total = 12 * 3600
                                local remaining = total - elapsed
                                
                                if remaining < 10800 then
                                    getgenv().ActivityStatus.current = "Buff almost ran out,Updating.. -Event Shrine"
                                    getgenv().ActivityStatus.trigger = true
                                    foundTarget = false
                                    pcall(function() Remote:FireServer("RerollHalloweenShrine") end)
                                    task.wait(3)
                                else
                                    if not foundTarget then
                                        getgenv().ActivityStatus.current = targetShrineBuff .. " Found! -Event Shrine"
                                        getgenv().ActivityStatus.trigger = true
                                        foundTarget = true
                                    end
                                    task.wait(5)
                                end
                            else
                                task.wait(5)
                            end
                        end
                    else
                        task.wait(5)
                    end
                end
            end)
        else
            if shrineThread then task.cancel(shrineThread) end
        end
    end,
})

-- ======================================
-- UI - EVENT ALTAR / REBIRTH MACHINE
-- ======================================
EventTab:Section({ Title = "Event Altar/Rebirth Machine" })

EventTab:Paragraph({
    Title = "⚠️ Warning",
    Desc = "Make sure to LOCK your Rainshine if you don't want it to be used!",
})

EventTab:Paragraph({
    Title = "Priority",
    Desc = "Celestial (Rainshine) > Secret (Empyrean Bolt). Groups by variant: Normal, Shiny, Mythic, ShinyMythic, XL.",
})

local altarTrackerParagraph = EventTab:Paragraph({
    Title = "Last Used: None",
    Desc = "Waiting for first conversion",
})

local altarEnabled = false
local altarThread = nil

local function getTrueRarity_WA(info)
    if not info then return "None" end
    if info.Void then return "Void" end
    if info.Infinity then return "Infinity" end
    if info.Celestial then return "Celestial" end
    if info.Rarity == "Secret" then return "Secret" end
    return info.Rarity or "None"
end

local function isWinterAltarEligible(pet, info)
    if not pet or not info then return false end
    if info.Egg ~= "Wintery Egg" then return false end
    if getTrueRarity_WA(info) ~= "Secret" then return false end
    if pet.Super then return false end
    if pet.XL then return false end
    if pet.Locked then return false end
    return true
end

local function getWinterGroups()
    local data = LocalData:Get()
    local groups = {Normal = {}, Shiny = {}, Mythic = {}, ShinyMythic = {}}
    if not data or not data.Pets then return groups end
    for _, pet in pairs(data.Pets) do
        local info = Pets[pet.Name]
        if isWinterAltarEligible(pet, info) then
            if pet.Shiny and pet.Mythic then table.insert(groups.ShinyMythic, pet)
            elseif pet.Shiny then table.insert(groups.Shiny, pet)
            elseif pet.Mythic then table.insert(groups.Mythic, pet)
            else table.insert(groups.Normal, pet) end
        end
    end
    return groups
end

local function getWinterCooldown()
    local data = LocalData:Get()
    if data and data.NextWinterAltarUse then
        return math.max(0, data.NextWinterAltarUse - os.time())
    end
    return 0
end

EventTab:Toggle({
    Title = "Auto Event Altar/Rebirth Machine",
    Desc = "Merges 3 Wintery Egg Secrets of same variant (waits for cooldown)",
    Value = eventSettings.autoWinterAltar or false,
    Callback = function(v)
        altarEnabled = v
        eventSettings.autoWinterAltar = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        
        if v then
            getgenv().ActivityStatus.current = "Auto Winter Altar started"
            getgenv().ActivityStatus.trigger = true
            
            altarThread = task.spawn(function()
                while altarEnabled do
                    local remaining = getWinterCooldown()
                    if remaining > 0 then
                        pcall(function()
                            altarTrackerParagraph:SetTitle("Status: Waiting")
                            altarTrackerParagraph:SetDesc(string.format("Cooldown: %dm %ds", math.floor(remaining/60), remaining%60))
                        end)
                        task.wait(math.min(remaining + 2, 60))
                        continue
                    end
                    
                    local groups = getWinterGroups()
                    local group, variantName = nil, nil
                    if #groups.Normal >= 3 then group, variantName = groups.Normal, "Normal"
                    elseif #groups.Shiny >= 3 then group, variantName = groups.Shiny, "Shiny"
                    elseif #groups.Mythic >= 3 then group, variantName = groups.Mythic, "Mythic"
                    elseif #groups.ShinyMythic >= 3 then group, variantName = groups.ShinyMythic, "Shiny Mythic" end
                    
                    if not group then
                        pcall(function()
                            altarTrackerParagraph:SetTitle("Status: Idle")
                            altarTrackerParagraph:SetDesc("Not enough Wintery Egg Secrets of same variant")
                        end)
                        altarEnabled = false
                        break
                    end
                    
                    local payload = {
                        tostring(group[1].Id),
                        tostring(group[2].Id),
                        tostring(group[3].Id),
                    }
                    local names = group[1].Name .. ", " .. group[2].Name .. ", " .. group[3].Name
                    
                    local NetworkRemote = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteFunction
                    pcall(function()
                        NetworkRemote:InvokeServer("UseRebirthMachine", "WinterAltar", payload)
                    end)
                    
                    pcall(function()
                        altarTrackerParagraph:SetTitle("Last Merge: " .. variantName)
                        altarTrackerParagraph:SetDesc(names)
                    end)
                    
                    getgenv().ActivityStatus.current = "Winter Altar merged (" .. variantName .. "): " .. names
                    getgenv().ActivityStatus.trigger = true
                    
                    task.wait(3)
                end
            end)
        else
            if altarThread then task.cancel(altarThread); altarThread = nil end
            pcall(function()
                altarTrackerParagraph:SetTitle("Status: Idle")
                altarTrackerParagraph:SetDesc("Stopped")
            end)
        end
    end,
})

-- ======================================
-- UI - HALLOWEEN REBIRTH
-- ======================================
EventTab:Section({ Title = "Halloween Rebirth" })

EventTab:Toggle({
    Title = "Auto Halloween Rebirth",
    Desc = "Rebirths when progress is full",
    Value = eventSettings.autoHalloweenRebirth or false,
    Callback = function(v)
        halloweenRebirthAuto = v
        eventSettings.autoHalloweenRebirth = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            halloweenRebirthThread = task.spawn(function()
                while halloweenRebirthAuto do
                    local playerGui = player:FindFirstChild("PlayerGui")
                    local sg = playerGui and playerGui:FindFirstChild("ScreenGui")
                    local hr = sg and sg:FindFirstChild("HalloweenRebirth")

                    if hr then
                        local ok, progressLabel = pcall(function()
                            return hr.Frame.Inner.Frame.Progress.Info.Label
                        end)

                        if ok and progressLabel and progressLabel.Text then
                            local currStr, maxStr = progressLabel.Text:match("([%d,]+)%s*/%s*([%d,]+)")
                            if currStr and maxStr then
                                local currClean = currStr:gsub(",", "")
                                local maxClean = maxStr:gsub(",", "")
                                local current = tonumber(currClean)
                                local max = tonumber(maxClean)

                                if current and max and current >= max then
                                    local rebirthBtn = hr.Frame
                                        and hr.Frame:FindFirstChild("Inner")
                                        and hr.Frame.Inner:FindFirstChild("Frame")
                                        and hr.Frame.Inner.Frame:FindFirstChild("Buttons")
                                        and hr.Frame.Inner.Frame.Buttons:FindFirstChild("Rebirth")
                                        and hr.Frame.Inner.Frame.Buttons.Rebirth:FindFirstChild("Button")

                                    if rebirthBtn and (rebirthBtn:IsA("TextButton") or rebirthBtn:IsA("ImageButton")) then
                                        pcall(function() firesignal(rebirthBtn.Activated) end)
                                    else
                                        pcall(function()
                                            RE:FireServer("Halloween Rebirth")
                                        end)
                                    end
                                    task.wait(3)
                                end
                            end
                        end
                    end
                    task.wait(2)
                end
            end)
        else
            if halloweenRebirthThread then task.cancel(halloweenRebirthThread) end
        end
    end,
})

-- ======================================
-- UI - NONE (Spawnable Special Rift)
-- ======================================
EventTab:Section({ Title = "None" })

EventTab:Toggle({
    Title = "Auto Hatch",
    Desc = "Hatches Cloudy Rift Egg automatically",
    Value = autoHatchRiftEnabled,
    Callback = function(v)
        autoHatchRiftEnabled = v
        eventSettings.autoHatchRift = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            autoHatchRiftThread = task.spawn(function()
                local wasActive = false
                local currentLuck = 0
                local lastCheckTime = 0
                local riftExists = false
                
                while autoHatchRiftEnabled do
                    while getgenv().questActive and autoHatchRiftEnabled do
                        wasActive = false
                        task.wait(0.5)
                    end
                    
                    local higherPriorityActive = false
                    if isRiftExists("corruptshadow-rift") or isRiftExists("overlord-rift") or isRiftExists("shadow-rift") or isRiftExists("doodle-rift") then
                        higherPriorityActive = true
                    end
                    
                    if higherPriorityActive then
                        wasActive = false
                        riftExists = false
                        task.wait(1)
                        continue
                    end
                    
                    local now = tick()
                    if now - lastCheckTime >= 5 then
                        lastCheckTime = now
                        riftExists = isRiftExists(riftName)
                        if riftExists then
                            currentLuck = teleportToBestRift(riftName)
                        end
                    end
                    
                    if riftExists then
                        if getgenv().questActive then continue end
                        
                        getgenv().questActive = true
                        getgenv().questEgg = riftEgg
                        
                        if not wasActive then
                            getgenv().ActivityStatus.current = "Hatching " .. riftEgg .. (currentLuck > 0 and " (x" .. currentLuck .. " luck)" or "")
                            getgenv().ActivityStatus.trigger = true
                            wasActive = true
                        end
                        
                        pcall(function() RE:FireServer("HatchEgg", riftEgg, HATCH_AMOUNT) end)
                        task.wait(0.05)
                    else
                        if wasActive then
                            getgenv().ActivityStatus.current = "Rift gone, waiting..."
                            getgenv().ActivityStatus.trigger = true
                            wasActive = false
                        end
                        getgenv().questActive = false
                        getgenv().questEgg = nil
                        task.wait(1)
                    end
                end
            end)
        else
            if autoHatchRiftThread then task.cancel(autoHatchRiftThread) end
            getgenv().questActive = false
            getgenv().questEgg = nil
        end
    end,
})

EventTab:Toggle({
    Title = "Auto Summon",
    Desc = "Summons Cloudy Rift every 55 minutes",
    Value = autoSummonRiftEnabled,
    Callback = function(v)
        autoSummonRiftEnabled = v
        eventSettings.autoSummonRift = v
        getgenv().HubSettings.event = eventSettings
        saveHubSettings()
        if v then
            autoSummonRiftThread = task.spawn(function()
                while autoSummonRiftEnabled do
                    getgenv().ActivityStatus.current = "Summoning " .. riftName
                    getgenv().ActivityStatus.trigger = true
                    
                    summonRift()
                    task.wait(5)
                    
                    if isRiftExists(riftName) then
                        sendSummonWebhook(true)
                    else
                        sendSummonWebhook(false)
                    end
                    
                    task.wait(3300)
                end
            end)
        else
            if autoSummonRiftThread then task.cancel(autoSummonRiftThread) end
        end
    end,
})

-- ======================================
-- AUTO-START SAVED TOGGLES
-- ======================================
task.spawn(function()
    task.wait(1.5)
    
    if eventSettings.autoAddEvent then
        eventRunning = true
        eventThread = task.spawn(function()
            while eventRunning do
                for _, eventName in ipairs(selectedEvents) do
                    if not eventRunning then break end
                    local value = type(eventName) == "table" and eventName[1] or eventName
                    pcall(function() RE:FireServer("PurchaseEventBoard", value) end)
                    task.wait(1)
                end
                task.wait(900)
            end
        end)
    end
    
    if eventSettings.autoClaimHalloweenChest then
        halloweenChestClaiming = true
        halloweenChestThread = task.spawn(function()
            while halloweenChestClaiming do
                local data = LocalData:Get()
                local cooldowns = data and data.Cooldowns
                local cd = cooldowns and cooldowns["Halloween Chest"]
                if cd and os.time() >= cd then
                    pcall(function() Remote:FireServer("ClaimChest", "Halloween Chest") end)
                end
                task.wait(5)
            end
        end)
    end
    
    if eventSettings.autoBuyUpgrades then
        halloweenUpgradeBuying = true
        halloweenUpgradeThread = task.spawn(function()
            while halloweenUpgradeBuying do
                for _, upgrade in ipairs(selectedUpgrades) do
                    if not halloweenUpgradeBuying then break end
                    local value = type(upgrade) == "table" and upgrade[1] or upgrade
                    pcall(function() RE:FireServer("BuyHalloween26Upgrade", value) end)
                    task.wait(0.5)
                end
                task.wait(5)
            end
        end)
    end
    
    if eventSettings.autoBuyRebirthShop then
        rebirthShopBuying = true
        rebirthShopThread = task.spawn(function()
            while rebirthShopBuying do
                for _, item in ipairs(selectedRebirthItems) do
                    if not rebirthShopBuying then break end
                    local value = type(item) == "table" and item[1] or item
                    local slotIndex = nil
                    for i, name in ipairs(currentRebirthShopItems) do
                        if name == value then slotIndex = i; break end
                    end
                    if slotIndex then
                        pcall(function() RE:FireServer("BuyShopItem", "hw26rebirth-shop", slotIndex, false) end)
                        task.wait(0.5)
                    end
                end
                task.wait(5)
            end
        end)
    end
    
    if eventSettings.autoBuyShop then
        eventShopBuying = true
        eventShopThread = task.spawn(function()
            while eventShopBuying do
                for _, item in ipairs(selectedShopItems) do
                    if not eventShopBuying then break end
                    local value = type(item) == "table" and item[1] or item
                    local slotIndex = nil
                    for i, name in ipairs(currentEventShopItems) do
                        if name == value then slotIndex = i; break end
                    end
                    if slotIndex then
                        pcall(function() RE:FireServer("BuyShopItem", "spooky-shop", slotIndex, true) end)
                        task.wait(0.5)
                    end
                end
                task.wait(5)
            end
        end)
    end
    
    if eventSettings.autoBuyDarkShop then
        darkShopBuying = true
        darkShopThread = task.spawn(function()
            while darkShopBuying do
                for _, item in ipairs(selectedDarkShopItems) do
                    if not darkShopBuying then break end
                    local value = type(item) == "table" and item[1] or item
                    local slotIndex = nil
                    for i, name in ipairs(currentDarkShopItems) do
                        if name == value then slotIndex = i; break end
                    end
                    if slotIndex then
                        pcall(function() RE:FireServer("BuyShopItem", "darkmarket-shop", slotIndex, true) end)
                        task.wait(0.5)
                    end
                end
                task.wait(5)
            end
        end)
    end
    
    if eventSettings.autoShrineReroll then
        shrineRunning = true
        
        getgenv().ActivityStatus.current = "Auto rerolling for " .. targetShrineBuff .. " -Event Shrine"
        getgenv().ActivityStatus.trigger = true

        shrineThread = task.spawn(function()
            local foundTarget = false
            
            while shrineRunning do
                task.wait(1)
                local data = LocalData:Get()
                local shrine = data and data.HalloweenShrine
                
                if shrine and shrine.Buff then
                    local currentBuff = tostring(shrine.Buff)
                    
                    if currentBuff == "None" then
                        task.wait(5)
                    elseif currentBuff:lower() ~= targetShrineBuff:lower() then
                        pcall(function() Remote:FireServer("RerollHalloweenShrine") end)
                        task.wait(3)
                    else
                        if shrine.StartTime and shrine.StartTime > 0 then
                            local elapsed = os.time() - shrine.StartTime
                            local total = 12 * 3600
                            local remaining = total - elapsed
                            
                            if remaining < 10800 then
                                getgenv().ActivityStatus.current = "Buff almost ran out,Updating.. -Event Shrine"
                                getgenv().ActivityStatus.trigger = true
                                foundTarget = false
                                pcall(function() Remote:FireServer("RerollHalloweenShrine") end)
                                task.wait(3)
                            else
                                if not foundTarget then
                                    getgenv().ActivityStatus.current = targetShrineBuff .. " Found! -Event Shrine"
                                    getgenv().ActivityStatus.trigger = true
                                    foundTarget = true
                                end
                                task.wait(5)
                            end
                        else
                            task.wait(5)
                        end
                    end
                else
                    task.wait(5)
                end
            end
        end)
    end
    
    if eventSettings.autoHalloweenRebirth then
        halloweenRebirthAuto = true
        halloweenRebirthThread = task.spawn(function()
            while halloweenRebirthAuto do
                local playerGui = player:FindFirstChild("PlayerGui")
                local sg = playerGui and playerGui:FindFirstChild("ScreenGui")
                local hr = sg and sg:FindFirstChild("HalloweenRebirth")
                if hr then
                    local ok, progressLabel = pcall(function()
                        return hr.Frame.Inner.Frame.Progress.Info.Label
                    end)
                    if ok and progressLabel and progressLabel.Text then
                        local currStr, maxStr = progressLabel.Text:match("([%d,]+)%s*/%s*([%d,]+)")
                        if currStr and maxStr then
                            local currClean = currStr:gsub(",", "")
                            local maxClean = maxStr:gsub(",", "")
                            local current = tonumber(currClean)
                            local max = tonumber(maxClean)
                            if current and max and current >= max then
                                local rebirthBtn = hr.Frame
                                    and hr.Frame:FindFirstChild("Inner")
                                    and hr.Frame.Inner:FindFirstChild("Frame")
                                    and hr.Frame.Inner.Frame:FindFirstChild("Buttons")
                                    and hr.Frame.Inner.Frame.Buttons:FindFirstChild("Rebirth")
                                    and hr.Frame.Inner.Frame.Buttons.Rebirth:FindFirstChild("Button")
                                if rebirthBtn and (rebirthBtn:IsA("TextButton") or rebirthBtn:IsA("ImageButton")) then
                                    pcall(function() firesignal(rebirthBtn.Activated) end)
                                else
                                    pcall(function() RE:FireServer("Halloween Rebirth") end)
                                end
                                task.wait(3)
                            end
                        end
                    end
                end
                task.wait(2)
            end
        end)
    end
    
    if eventSettings.autoHatchRift then
        autoHatchRiftEnabled = true
        autoHatchRiftThread = task.spawn(function()
            local wasActive = false
            local currentLuck = 0
            local lastCheckTime = 0
            local riftExists = false
            
            while autoHatchRiftEnabled do
                while getgenv().questActive and autoHatchRiftEnabled do
                    wasActive = false
                    task.wait(0.5)
                end
                
                local higherPriorityActive = false
                if isRiftExists("corruptshadow-rift") or isRiftExists("overlord-rift") or isRiftExists("shadow-rift") or isRiftExists("doodle-rift") then
                    higherPriorityActive = true
                end
                
                if higherPriorityActive then
                    wasActive = false
                    riftExists = false
                    task.wait(1)
                    continue
                end
                
                local now = tick()
                if now - lastCheckTime >= 5 then
                    lastCheckTime = now
                    riftExists = isRiftExists(riftName)
                    if riftExists then
                        currentLuck = teleportToBestRift(riftName)
                    end
                end
                
                if riftExists then
                    if getgenv().questActive then continue end
                    getgenv().questActive = true
                    getgenv().questEgg = riftEgg
                    if not wasActive then
                        getgenv().ActivityStatus.current = "Hatching " .. riftEgg .. (currentLuck > 0 and " (x" .. currentLuck .. " luck)" or "")
                        getgenv().ActivityStatus.trigger = true
                        wasActive = true
                    end
                    pcall(function() RE:FireServer("HatchEgg", riftEgg, HATCH_AMOUNT) end)
                    task.wait(0.05)
                else
                    if wasActive then
                        getgenv().ActivityStatus.current = "Rift gone, waiting..."
                        getgenv().ActivityStatus.trigger = true
                        wasActive = false
                    end
                    getgenv().questActive = false
                    getgenv().questEgg = nil
                    task.wait(1)
                end
            end
        end)
    end
    
    if eventSettings.autoSummonRift then
        autoSummonRiftEnabled = true
        autoSummonRiftThread = task.spawn(function()
            while autoSummonRiftEnabled do
                getgenv().ActivityStatus.current = "Summoning " .. riftName
                getgenv().ActivityStatus.trigger = true
                summonRift()
                task.wait(5)
                if isRiftExists(riftName) then
                    sendSummonWebhook(true)
                else
                    sendSummonWebhook(false)
                end
                task.wait(3300)
            end
        end)
    end
    
    if eventSettings.autoChallengePass then
        cpEnabled = true
        getgenv().ActivityStatus.current = "Auto Event Challange Pass"
        getgenv().ActivityStatus.trigger = true
        
        cpThread = task.spawn(function()
            teleportTo(PASS_POS)
            task.wait(4)
            
            while cpEnabled do
                if checkAndReset() then
                    task.wait(5)
                    continue
                end
                
                local challenges = readChallenges()
                if #challenges == 0 then 
                    task.wait(5) 
                    continue 
                end
                
                local allDone = true
                for _, c in ipairs(challenges) do if not c.complete then allDone = false; break end end
                
                if allDone then
                    task.wait(3)
                    local newChallenges = readChallenges()
                    local stillComplete = true
                    for _, c in ipairs(newChallenges) do if not c.complete then stillComplete = false; break end end
                    if stillComplete then task.wait(15) end
                    continue
                end
                
                for _, c in ipairs(challenges) do
                    if not cpEnabled then break end
                    if not c.complete then doChallenge(c) end
                end
                
                task.wait(2)
            end
        end)
    end

    if eventSettings.autoClaimPass then
        claimEnabled = true
        claimThread = task.spawn(function()
            while claimEnabled do
                claimAllRewards()
                task.wait(3)
                if checkAndReset() then
                    task.wait(5)
                end
            end
        end)
    end
    
    if eventSettings.autoWinterAltar then
        altarEnabled = true
        getgenv().ActivityStatus.current = "Auto Winter Altar started"
        getgenv().ActivityStatus.trigger = true
        
        altarThread = task.spawn(function()
            while altarEnabled do
                local remaining = getWinterCooldown()
                if remaining > 0 then
                    pcall(function()
                        altarTrackerParagraph:SetTitle("Status: Waiting")
                        altarTrackerParagraph:SetDesc(string.format("Cooldown: %dm %ds", math.floor(remaining/60), remaining%60))
                    end)
                    task.wait(math.min(remaining + 2, 60))
                    continue
                end
                
                local groups = getWinterGroups()
                local group, variantName = nil, nil
                if #groups.Normal >= 3 then group, variantName = groups.Normal, "Normal"
                elseif #groups.Shiny >= 3 then group, variantName = groups.Shiny, "Shiny"
                elseif #groups.Mythic >= 3 then group, variantName = groups.Mythic, "Mythic"
                elseif #groups.ShinyMythic >= 3 then group, variantName = groups.ShinyMythic, "Shiny Mythic" end
                
                if not group then
                    pcall(function()
                        altarTrackerParagraph:SetTitle("Status: Idle")
                        altarTrackerParagraph:SetDesc("Not enough Wintery Egg Secrets of same variant")
                    end)
                    altarEnabled = false
                    break
                end
                
                local payload = {
                    tostring(group[1].Id),
                    tostring(group[2].Id),
                    tostring(group[3].Id),
                }
                local names = group[1].Name .. ", " .. group[2].Name .. ", " .. group[3].Name
                
                local NetworkRemote = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteFunction
                pcall(function()
                    NetworkRemote:InvokeServer("UseRebirthMachine", "WinterAltar", payload)
                end)
                
                pcall(function()
                    altarTrackerParagraph:SetTitle("Last Merge: " .. variantName)
                    altarTrackerParagraph:SetDesc(names)
                end)
                
                getgenv().ActivityStatus.current = "Winter Altar merged (" .. variantName .. "): " .. names
                getgenv().ActivityStatus.trigger = true
                
                task.wait(3)
            end
        end)
    end
end)

print("[Event] Loaded!")
