local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local Player = Players.LocalPlayer

local Aimbot = {
    Enabled = false,
    Aiming = false,
    Target = nil,
    RenderConnection = nil,
    Settings = {
        AimKey = Enum.UserInputType.MouseButton2,
    }
}

-- NPC caching
local npcCache = {}
local humanoidDirectories = {} -- Store directories with humanoids
local lastFullScan = 0
local lastCacheUpdate = 0
local cacheCoroutine = nil

-- Initial full scan to find humanoid directories
local function initialScanForDirectories()
    humanoidDirectories = {}
    local descendants = workspace:GetDescendants()
    local batchSize = 100
    for i = 1, #descendants, batchSize do
        for j = i, math.min(i + batchSize - 1, #descendants) do
            local obj = descendants[j]
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
                local dir = obj.Parent
                if dir and not humanoidDirectories[dir] then
                    humanoidDirectories[dir] = true
                end
            end
        end
        task.wait()
    end
end

-- Update NPC cache from known directories
local function updateNPCCacheFromDirectories()
    local newCache = {}
    for dir in pairs(humanoidDirectories) do
        if dir.Parent then -- Ensure directory still exists
            for _, humanoid in pairs(dir:GetDescendants()) do
                if humanoid:IsA("Model") and humanoid:FindFirstChildOfClass("Humanoid") and humanoid ~= Player.Character then
                    local isPlayer = Players:GetPlayerFromCharacter(humanoid)
                    if not isPlayer and humanoid:FindFirstChildOfClass("Humanoid").Health > 0 then
                        local head = humanoid:FindFirstChild("Head") or humanoid.PrimaryPart or humanoid:FindFirstChildWhichIsA("BasePart")
                        if head and (head.Position - Camera.CFrame.Position).Magnitude <= 100 then
                            table.insert(newCache, humanoid)
                        end
                    end
                end
            end
        end
    end
    npcCache = newCache
    lastCacheUpdate = tick()
end

-- Async full rescan
local function fullRescanAsync()
    if cacheCoroutine then return end
    cacheCoroutine = coroutine.create(function()
        initialScanForDirectories()
        updateNPCCacheFromDirectories()
        lastFullScan = tick()
        cacheCoroutine = nil
        -- print("Full rescan completed:", #npcCache, "NPCs in", table.getn(humanoidDirectories), "directories")
    end)
    coroutine.resume(cacheCoroutine)
end

-- Get cached NPCs, updating async if needed
local function getNPCs()
    if tick() - lastFullScan > 60 then -- Full rescan every 60 seconds
        fullRescanAsync()
    elseif tick() - lastCacheUpdate > 0.5 and not cacheCoroutine then -- Update directories every 0.5s
        updateNPCCacheFromDirectories()
    end
    return npcCache
end

-- Check line of sight
local function hasLineOfSight(target)
    local head = target:FindFirstChild("Head") or target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
    if not head then return false end

    local rayOrigin = Camera.CFrame.Position
    local rayDirection = (head.Position - rayOrigin).Unit * 1000
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {Player.Character, target}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    return not workspace:Raycast(rayOrigin, rayDirection, raycastParams)
end

-- Find closest NPC
local function findClosestNPC()
    local mouse = UserInputService:GetMouseLocation()
    local ray = Camera:ScreenPointToRay(mouse.X, mouse.Y)
    
    local closestNPC, closestDistance = nil, math.huge
    for _, npc in ipairs(getNPCs()) do
        local head = npc:FindFirstChild("Head") or npc.PrimaryPart or npc:FindFirstChildWhichIsA("BasePart")
        if head then
            local screenPos, onScreen = Camera:WorldToScreenPoint(head.Position)
            if onScreen and hasLineOfSight(npc) then
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - mouse).Magnitude
                if distance < closestDistance then
                    closestNPC = npc
                    closestDistance = distance
                end
            end
        end
    end
    return closestNPC
end

-- Aim at target
local function aimAtTarget()
    if not Aimbot.Target or not Aimbot.Target.Parent then
        Aimbot.Target = findClosestNPC()
        if not Aimbot.Target then return end
    end
    
    local head = Aimbot.Target:FindFirstChild("Head") or Aimbot.Target.PrimaryPart
    if not head or not hasLineOfSight(Aimbot.Target) then
        Aimbot.Target = findClosestNPC()
        if not Aimbot.Target then return end
        head = Aimbot.Target:FindFirstChild("Head") or Aimbot.Target.PrimaryPart
    end
    
    local targetPos = head.Position
    local lookVector = (targetPos - Camera.CFrame.Position).Unit
    Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + lookVector)
end

-- Initialize aimbot
function Aimbot.Initialize()
    initialScanForDirectories() -- Initial directory scan
    updateNPCCacheFromDirectories() -- Initial cache from directories
    lastFullScan = tick()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not Aimbot.Enabled then return end
        if input.UserInputType == Aimbot.Settings.AimKey then
            Aimbot.Aiming = true
            Aimbot.Target = findClosestNPC()
            if Aimbot.Target then
                if Aimbot.RenderConnection then Aimbot.RenderConnection:Disconnect() end
                Aimbot.RenderConnection = RunService.RenderStepped:Connect(aimAtTarget)
            end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed or not Aimbot.Enabled then return end
        if input.UserInputType == Aimbot.Settings.AimKey then
            Aimbot.Aiming = false
            Aimbot.Target = nil
            if Aimbot.RenderConnection then
                Aimbot.RenderConnection:Disconnect()
                Aimbot.RenderConnection = nil
            end
        end
    end)
end

return Aimbot
