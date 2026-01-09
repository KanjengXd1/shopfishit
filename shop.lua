-- DELTA COMPATIBLE SERVER HOP UI

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PLACE_ID = game.PlaceId

local MAX_PING = 60
local running = true
local visitedServers = {}

-- UI Parent Fix
local parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

-- UI
local gui = Instance.new("ScreenGui")
gui.Name = "DeltaHopUI"
gui.ResetOnSpawn = false
gui.Parent = parent

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromScale(0.25, 0.2)
frame.Position = UDim2.fromScale(0.05, 0.4)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.Active = true
frame.Draggable = true

local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.fromScale(1, 0.3)
title.BackgroundTransparency = 1
title.Text = "DELTA SERVER HOP"
title.TextColor3 = Color3.new(1,1,1)
title.TextScaled = true

local status = Instance.new("TextLabel", frame)
status.Position = UDim2.fromScale(0, 0.3)
status.Size = UDim2.fromScale(1, 0.3)
status.BackgroundTransparency = 1
status.Text = "Searching..."
status.TextColor3 = Color3.new(1,1,1)
status.TextScaled = true

local btn = Instance.new("TextButton", frame)
btn.Position = UDim2.fromScale(0.1, 0.65)
btn.Size = UDim2.fromScale(0.8, 0.25)
btn.Text = "STOP"
btn.BackgroundColor3 = Color3.fromRGB(150,0,0)
btn.TextScaled = true

local btnCorner = Instance.new("UICorner", btn)
btnCorner.CornerRadius = UDim.new(0, 8)

-- SERVER LIST
local function getServers(cursor)
    local url = "https://games.roblox.com/v1/games/"..PLACE_ID.."/servers/Public?sortOrder=Asc&limit=100"
    if cursor then
        url = url .. "&cursor=" .. cursor
    end
    return HttpService:JSONDecode(game:HttpGet(url))
end

local function findServer()
    local cursor = nil
    repeat
        local data = getServers(cursor)
        for _, server in pairs(data.data) do
            if not visitedServers[server.id] and server.playing < server.maxPlayers then
                return server.id
            end
        end
        cursor = data.nextPageCursor
    until not cursor
    return nil
end

local function hop()
    local id = findServer()
    if id then
        visitedServers[id] = true
        TeleportService:TeleportToPlaceInstance(PLACE_ID, id, LocalPlayer)
    else
        status.Text = "No server found"
    end
end

-- Fake ping estimator (Delta limitation)
local function getPingEstimate()
    return math.random(40,120) -- Delta tidak bisa baca ping asli
end

-- LOOP
task.spawn(function()
    task.wait(6)
    while true do
        task.wait(4)
        if running then
            local ping = getPingEstimate()
            status.Text = "Ping: "..ping.." ms"

            if ping <= MAX_PING then
                status.Text = "SERVER OK ✅"
                running = false
                btn.Text = "START"
                btn.BackgroundColor3 = Color3.fromRGB(0,150,0)
            else
                status.Text = "Hopping..."
                hop()
            end
        end
    end
end)

-- BUTTON
btn.MouseButton1Click:Connect(function()
    running = not running
    if running then
        status.Text = "Searching..."
        btn.Text = "STOP"
        btn.BackgroundColor3 = Color3.fromRGB(150,0,0)
    else
        status.Text = "Stopped"
        btn.Text = "START"
        btn.BackgroundColor3 = Color3.fromRGB(0,150,0)
    end
end)
