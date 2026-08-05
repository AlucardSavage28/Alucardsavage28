repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local ShrineTab = Window:CreateTab("Shrine", nil)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

print("[Shrine Debug] Starting to load remotes...")

local Shared = ReplicatedStorage:FindFirstChild("Shared")
print("[Shrine Debug] Shared found: " .. tostring(Shared ~= nil))

if not Shared then
    print("[Shrine Debug] ❌ Shared not found! Trying WaitForChild...")
    Shared = ReplicatedStorage:WaitForChild("Shared")
    print("[Shrine Debug] Shared loaded via WaitForChild")
end

local Framework = Shared:FindFirstChild("Framework")
print("[Shrine Debug] Framework found: " .. tostring(Framework ~= nil))

if not Framework then
    print("[Shrine Debug] ❌ Framework not found! Trying WaitForChild...")
    Framework = Shared:WaitForChild("Framework")
    print("[Shrine Debug] Framework loaded via WaitForChild")
end

local Network = Framework:FindFirstChild("Network")
print("[Shrine Debug] Network found: " .. tostring(Network ~= nil))

if not Network then
    print("[Shrine Debug] ❌ Network not found! Trying WaitForChild...")
    Network = Framework:WaitForChild("Network")
    print("[Shrine Debug] Network loaded via WaitForChild")
end

local RemoteModule = Network:FindFirstChild("Remote")
print("[Shrine Debug] Remote found: " .. tostring(RemoteModule ~= nil))

if not RemoteModule then
    print("[Shrine Debug] ❌ Remote not found! Trying WaitForChild...")
    RemoteModule = Network:WaitForChild("Remote")
    print("[Shrine Debug] Remote loaded via WaitForChild")
end

print("[Shrine Debug] Loading Remote via require...")
local Remote = require(RemoteModule)
print("[Shrine Debug] Remote loaded: " .. typeof(Remote))

print("[Shrine Debug] Loading RemoteEvent...")
local RemoteEvent = RemoteModule:FindFirstChild("RemoteEvent")
print("[Shrine Debug] RemoteEvent found: " .. tostring(RemoteEvent ~= nil))
if not RemoteEvent then
    RemoteEvent = RemoteModule:WaitForChild("RemoteEvent")
    print("[Shrine Debug] RemoteEvent loaded via WaitForChild")
end

print("[Shrine Debug] Loading RemoteFunction...")
local RemoteFunction = RemoteModule:FindFirstChild("RemoteFunction")
print("[Shrine Debug] RemoteFunction found: " .. tostring(RemoteFunction ~= nil))
if not RemoteFunction then
    RemoteFunction = RemoteModule:WaitForChild("RemoteFunction")
    print("[Shrine Debug] RemoteFunction loaded via WaitForChild")
end

print("[Shrine Debug] ✅ All remotes loaded!")
print("[Shrine Debug] Remote: " .. typeof(Remote))
print("[Shrine Debug] RemoteEvent: " .. typeof(RemoteEvent))
print("[Shrine Debug] RemoteFunction: " .. typeof(RemoteFunction))

-- Stop here - don't load the rest of the tab
print("[Shrine Debug] TEST COMPLETE - Not loading full tab")
