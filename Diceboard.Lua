repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local DiceBoardTab = Window:CreateTab("Dice Board", nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local Board = require(ReplicatedStorage.Client.Gui.Frames.Board)

local TILE_TYPES = {
    ["Chance"] = {5,13,25,29,32,36,39,40,44,50,53,55,60,61,62,72,76,78,79,83},
    ["Dice-Key"] = {19,21,34,47,80},
    ["Dice"] = {4,12,16,41,42,54,59},
    ["Giant-Dice"] = {69},
    ["Golden-Dice"] = {10,20,26,28,45,49,75,86},
    ["Infinity-Elixir"] = {17,64},
    ["Special-Egg"] = {27,57,63,71,82},
    ["Super-Ticket"] = {8,11,18,52,65,66},
    ["Basic"] = {1,6,7,9,14,15,22,23,24,30,31,35,37,48,51,56,58,67,68,70,73,74,81,84,85,87},
}

local targetTile = "Chance"
local running = false
local thread = nil

local function getNode()
    for name, piece in pairs(Board.Pieces) do
        if name == player.Name then
            local raw = piece.Node.Part
            if typeof(raw) == "number" then return raw
            elseif typeof(raw) == "string" then return tonumber(raw)
            elseif typeof(raw) == "Instance" then return tonumber(raw.Name)
            end
        end
    end
    return nil
end

local function getClosest(current, list)
    local closest = nil
    local dist = math.huge
    for _, num in ipairs(list) do
        local d = (num >= current) and (num - current) or (88 - current + num)
        if d < dist then
            dist = d
            closest = num
        end
    end
    return closest, dist
end

local function hasGoldenDice()
    local ok, LocalData = pcall(function()
        return require(ReplicatedStorage.Client.Framework.Services.LocalData)
    end)
    if not ok then return false end
    local data = LocalData:Get()
    if data and data.Powerups then
        local gd = data.Powerups["Golden Dice"] or 0
        return gd > 0
    end
    return false
end

local function getBoardHUD()
    local ok, playerGui = pcall(function() return player.PlayerGui end)
    if not ok then return nil end
    local screenGui = playerGui:FindFirstChild("ScreenGui")
    if not screenGui then return nil end
    return screenGui:FindFirstChild("BoardHUD")
end

local function selectDice(diceName)
    local hud = getBoardHUD()
    if not hud then return false end
    local diceFrame = hud.Dice.Inventory:FindFirstChild(diceName)
    if not diceFrame then return false end
    local button = diceFrame:FindFirstChild("Button")
    if not button then return false end
    firesignal(button.Activated)
    return true
end

local function pressRoll()
    local hud = getBoardHUD()
    if not hud then return false end
    local rollButton = hud.Dice.Actions.Roll.Button
    if not rollButton then return false end
    firesignal(rollButton.Activated)
    return true
end

local function waitForNodeChange(oldNode, timeout)
    local elapsed = 0
    while elapsed < timeout do
        task.wait(0.3)
        elapsed = elapsed + 0.3
        local current = getNode()
        if current and current ~= oldNode then return current end
    end
    return getNode()
end

local function loop()
    while running do
        local node = getNode()
        if not node then
            task.wait(2)
            continue
        end

        local target, dist = getClosest(node, TILE_TYPES[targetTile])

        local goldenAvailable = hasGoldenDice()
        local diceName = "Dice"
        local waitTime = 2.5

        if goldenAvailable and dist <= 3 then
            diceName = "Golden Dice"
            waitTime = 1.5
        elseif dist >= 10 then
            diceName = "Giant Dice"
            waitTime = 4.5
        else
            diceName = "Dice"
            waitTime = 2.5
        end

        local selected = selectDice(diceName)
        if not selected then
            selectDice("Dice")
            diceName = "Dice"
            waitTime = 2.5
        end

        task.wait(0.3)
        pressRoll()
        waitForNodeChange(node, waitTime + 2)
        task.wait(1)
    end
end

-- ======================================
-- UI
-- ======================================
DiceBoardTab:CreateSection("Settings")

DiceBoardTab:CreateDropdown({
    Name = "Target Tile",
    CurrentOption = {"Chance"},
    Options = {
        "Chance","Dice-Key","Dice","Giant-Dice","Golden-Dice",
        "Infinity-Elixir","Special-Egg","Super-Ticket","Basic"
    },
    Callback = function(v)
        targetTile = v[1]
    end
})

DiceBoardTab:CreateToggle({
    Name = "Auto Dice Board",
    CurrentValue = false,
    Callback = function(v)
        running = v
        if v then
            if not getBoardHUD() then
                running = false
                return
            end
            thread = task.spawn(loop)
        else
            running = false
            if thread then task.cancel(thread) end
        end
    end
})

print("[DiceBoard] Loaded!")
