-- ================================================
-- QUEST TAB (SEASON + GLOBAL + CLAIM)
-- ================================================
repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local QuestTab = Window:CreateTab("Quest", nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)
local Remote = require(ReplicatedStorage.Shared.Framework.Network.Remote)

-- ======================================
-- TELEPORT LOCATIONS
-- ======================================
local COIN_AREA = Vector3.new(36, 15971, 41)
local GEM_AREA = Vector3.new(2286, 3158, 842)
local TICKET_AREA = Vector3.new(9888, 20089, 242)

local EGG_LOCATIONS = {
    ["Common Egg"] = Vector3.new(-80, 7, 5),
    ["Classic Egg"] = Vector3.new(-90, 13, 30),
    ["Vine Egg"] = Vector3.new(-61, 13, 11),
    ["Lava Egg"] = Vector3.new(-69, 14, 19),
    ["Icy Egg"] = Vector3.new(-55, 14, 0),
    ["Iceshard Egg"] = Vector3.new(-119, 11, 13),
    ["Spotted Egg"] = Vector3.new(-11, 10, -69),
    ["Atlantis Egg"] = Vector3.new(-79, 14, 25),
    ["Mining Egg"] = Vector3.new(-122, 11, -69),
    ["Neon Egg"] = Vector3.new(-81, 10, -61),
    ["Cyber Egg"] = Vector3.new(-92, 10, -67),
    ["Rainbow Egg"] = Vector3.new(-140, 10, -57),
    ["Nightmare Egg"] = Vector3.new(-146, 10, -47),
    ["Infinity Egg"] = Vector3.new(-106, 12, -28),
    ["Spikey Egg"] = Vector3.new(-128, 10, 9),
    ["Magma Egg"] = Vector3.new(-137, 11, 3),
    ["Crystal Egg"] = Vector3.new(-144, 10, -5),
    ["Lunar Egg"] = Vector3.new(-148, 11, -15),
    ["Void Egg"] = Vector3.new(-150, 11, -26),
    ["Hell Egg"] = Vector3.new(-149, 11, -37),
    ["Secret Egg"] = Vector3.new(-19438, 8, 18839),
    ["Showman Egg"] = Vector3.new(-130, 10, -60),
    ["Popcorn Egg"] = Vector3.new(-3601, 162, 882),
    ["Sweet Egg"] = Vector3.new(-3586, 162, 883),
    ["Exotic Egg"] = Vector3.new(-3576, 162, 882),
}

-- ======================================
-- SETTINGS
-- ======================================
local seasonRunning = false
local seasonThread = nil
local globalRunning = false
local globalThread = nil
local claimRunning = false
local claimThread = nil
local HATCH_AMOUNT = 12
local COIN_CAP = 5000000000000

-- ======================================
-- FUNCTIONS
-- ======================================
local function getRoot()
    local char = player.Character
    if char then return char:FindFirstChild("HumanoidRootPart") end
end

local function teleportTo(pos)
    local root = getRoot()
    if root then
        root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    end
end

local function savePosition()
    local root = getRoot()
    return root and root.Position or nil
end

local function restorePosition(pos)
    if pos then
        local root = getRoot()
        if root then
            root.CFrame = CFrame.new(pos)
        end
    end
end

local function getSellPosition()
    local overworld = workspace.Worlds["The Overworld"]
    if overworld then
        local sell = overworld:FindFirstChild("Sell")
        if sell then
            local ring = sell:FindFirstChild("Ring")
            if ring then
                return ring.Position
            end
        end
    end
    return Vector3.new(77, 6, -113)
end

local function getActiveQuests(filter)
    local data = LocalData:Get()
    local quests = {}
    if data and data.Quests then
        for _, quest in pairs(data.Quests) do
            if not quest.Claimed then
                local name = quest.Id or ""
                if name:find(filter) and not name:find("bubble") then
                    local task = quest.Tasks and quest.Tasks[1]
                    if task then
                        table.insert(quests, {
                            id = quest.Id,
                            type = task.Type,
                            amount = task.Amount or 0,
                            rarity = task.Rarity,
                            egg = task.Egg,
                            currency = task.Currency or (task.Item and task.Item.Currency),
                        })
                    end
                end
            end
        end
    end
    return quests
end

local function completeQuest(quest)
    getgenv().questActive = true
    
    if quest.type == "Bubbles" then
        getgenv().questEgg = nil
        local prevPos = savePosition()
        local sellPos = getSellPosition()
        local root = getRoot()
        if root then root.CFrame = CFrame.new(sellPos) end
        task.wait(0.5)
        while true do
            pcall(function() Remote:FireServer("BlowBubble") end)
            task.wait(0.01)
            local newQuests = getActiveQuests(quest.id:match("^(.-)%d+$") or "")
            local stillActive = false
            for _, q in ipairs(newQuests) do
                if q.id == quest.id then stillActive = true; break end
            end
            if not stillActive then break end
        end
        restorePosition(prevPos)
        
    elseif quest.type == "Hatch" then
        if quest.egg then
            local eggName = quest.egg
            getgenv().questEgg = eggName
            local prevPos = savePosition()
            local pos = EGG_LOCATIONS[eggName] or EGG_LOCATIONS["Magma Egg"]
            if pos then teleportTo(pos) end
            task.wait(0.5)
            while true do
                pcall(function() Remote:InvokeServer("HatchEgg", eggName, HATCH_AMOUNT) end)
                task.wait(1)
                local newQuests = getActiveQuests(quest.id:match("^(.-)%d+$") or "")
                local stillActive = false
                for _, q in ipairs(newQuests) do
                    if q.id == quest.id then stillActive = true; break end
                end
                if not stillActive then break end
            end
            restorePosition(prevPos)
        else
            getgenv().questActive = false
            getgenv().questEgg = nil
            task.wait(5)
        end
        
    elseif quest.type == "Collect" then
        local curr = quest.currency or ""
        if curr:lower():find("pearl") then
            getgenv().questActive = false
            getgenv().questEgg = nil
            task.wait(1)
            return
        end
        
        getgenv().questEgg = nil
        local prevPos = savePosition()
        local isCoinQuest = not curr:lower():find("gem") and not curr:lower():find("ticket")
        
        if curr:lower():find("gem") then teleportTo(GEM_AREA)
        elseif curr:lower():find("ticket") then teleportTo(TICKET_AREA)
        else teleportTo(COIN_AREA) end
        
        while true do
            if isCoinQuest then
                local data = LocalData:Get()
                local coins = data and data.Coins or 0
                if coins >= COIN_CAP then
                    local rainbowPos = EGG_LOCATIONS["Rainbow Egg"]
                    if rainbowPos then teleportTo(rainbowPos) end
                    task.wait(0.5)
                    for i = 1, 3 do
                        pcall(function() Remote:FireServer("HatchEgg", "Rainbow Egg", 12) end)
                        task.wait(1)
                    end
                    teleportTo(COIN_AREA)
                    task.wait(0.5)
                end
            end
            task.wait(3)
            local newQuests = getActiveQuests(quest.id:match("^(.-)%d+$") or "")
            local stillActive = false
            for _, q in ipairs(newQuests) do
                if q.id == quest.id then stillActive = true; break end
            end
            if not stillActive then break end
        end
        restorePosition(prevPos)
    end
    
    getgenv().questActive = false
    getgenv().questEgg = nil
end

local function questLoop(filter)
    return function()
        while true do
            local quests = getActiveQuests(filter)
            if #quests == 0 then
                getgenv().questActive = false
                getgenv().questEgg = nil
                task.wait(10)
                continue
            end
            
            local questToDo = nil
            for _, q in ipairs(quests) do
                local curr = q.currency or ""
                if q.type == "Hatch" and not q.egg and not q.rarity then
                elseif q.type == "Collect" and curr:lower():find("pearl") then
                else
                    questToDo = q
                    break
                end
            end
            
            if questToDo then
                completeQuest(questToDo)
            else
                getgenv().questActive = false
                getgenv().questEgg = nil
                task.wait(30)
            end
        end
    end
end

-- ======================================
-- UI
-- ======================================
QuestTab:CreateSection("Season Pass")

QuestTab:CreateInput({
    Name = "Hatch Amount",
    CurrentValue = tostring(HATCH_AMOUNT),
    PlaceholderText = "12",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        local n = tonumber(v)
        if n then HATCH_AMOUNT = n end
    end
})

QuestTab:CreateToggle({
    Name = "Auto Season Quests",
    CurrentValue = false,
    Callback = function(v)
        seasonRunning = v
        if v then
            seasonThread = task.spawn(questLoop("challenge"))
        else
            if seasonThread then task.cancel(seasonThread) end
            getgenv().questActive = false
            getgenv().questEgg = nil
        end
    end
})

QuestTab:CreateToggle({
    Name = "Auto Claim Season Pass",
    CurrentValue = false,
    Callback = function(v)
        claimRunning = v
        if v then
            claimThread = task.spawn(function()
                while claimRunning do
                    pcall(function() Remote:FireServer("ClaimSeason") end)
                    task.wait(5)
                end
            end)
        else
            if claimThread then task.cancel(claimThread) end
        end
    end
})

QuestTab:CreateSection("Global Incentive")

QuestTab:CreateToggle({
    Name = "Auto Global Incentive",
    CurrentValue = false,
    Callback = function(v)
        globalRunning = v
        if v then
            globalThread = task.spawn(function()
                while globalRunning do
                    local quests = getActiveQuests("global")
                    if #quests == 0 then
                        pcall(function() Remote:FireServer("ClaimGlobalIncentiveQuest") end)
                        getgenv().questActive = false
                        getgenv().questEgg = nil
                        task.wait(60)
                    else
                        local questToDo = nil
                        for _, q in ipairs(quests) do
                            local curr = q.currency or ""
                            if q.type == "Collect" and curr:lower():find("pearl") then
                            else
                                questToDo = q
                                break
                            end
                        end
                        if questToDo then
                            completeQuest(questToDo)
                        else
                            getgenv().questActive = false
                            getgenv().questEgg = nil
                            task.wait(30)
                        end
                    end
                end
            end)
        else
            if globalThread then task.cancel(globalThread) end
            getgenv().questActive = false
            getgenv().questEgg = nil
        end
    end
})

print("[Quest] Loaded!")
