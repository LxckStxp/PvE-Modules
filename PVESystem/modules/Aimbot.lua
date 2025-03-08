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
local npcCache = {} -- Table of NPCs
local npcMap = {} -- Map of NPC instances to track existence
local distanceThreshold = 100 -- Only cache NPCs within 100 studs

-- Check if an object is an NPC
local function isValidNPC(humanoid)
    if not humanoid:IsA("Model") or humanoid == Player.Character then return false end
    local hum = humanoid:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    return not Players:GetPlayerFromCharacter(humanoid)
end

-- Add NPC to cache
local function addNPC(humanoid)
    local head = humanoid:FindFirstChild("Head") or humanoid.PrimaryPart or humanoid:FindFirstChildWhichIsA("BasePart")
    if head and (head.Position - Camera.CFrame.Position).Magnitude <= distanceThreshold and not npcMap[humanoid] then
        table.insert(npcCache, humanoid)
        npcMap[humanoid] = true
    end
end

-- Remove NPC from cache
local function removeNPC(humanoid)
    if npcMap[humanoid] then
        for i, npc in ipairs(npcCache) do
            if npc == humanoid then
                table.remove(npcCache, i)
                npcMap[humanoid] = nil
                break
            end
        end
    end
end

-- Initial async scan
local function initialScanAsync()
    coroutine.wrap(function()
        local descendants = workspace:GetDescendants()
        local batchSize = 50 -- Smaller batch for less lag
        for i = 1, #descendants, batchSize do
            for j = i, math.min(i + batchSize - 1, #descendants) do
                local obj = descendants[j]
                if isValidNPC(obj) then
                    addNPC(obj)
                end
            end
            task.wait()
        end
        -- print("Initial NPC scan completed:", #npcCache, "NPCs found")
    end)()
end

-- Dynamic NPC updates
local function setupDynamicUpdates()
    -- Add new NPCs
    workspace.DescendantAdded:Connect(function(descendant)
        if isValidNPC(descendant) then
            addNPC(descendant)
        end
    end)

    -- Remove NPCs when they leave
    workspace.DescendantRemoving:Connect(function(descendant)
        if npcMap[descendant] then
            removeNPC(descendant)
        end
    end)

    -- Update on health changes (e.g., death)
    RunService.Heartbeat:Connect(function()
        for i = #npcCache, 1, -1 do -- Iterate backwards to safely remove
            local npc = npcCache[i]
            local hum = npc:FindFirstChildOfClass("Humanoid")
            if not npc.Parent or not hum or hum.Health <= 0 or (npc:FindFirstChild("Head") or npc.PrimaryPart or npc:FindFirstChildWhichIsA("BasePart")).Position - Camera.CFrame.Position).Magnitude > distanceThreshold then
                removeNPC(npc)
            end
        end
    end)
end

-- Get cached NPCs
local function getNPCs()
    return npcCache
end

-- Check line of sight (cached result per frame)
local lastRaycastFrame = 0
local raycastCache = {}
local function hasLineOfSight(target)
    local currentFrame = RunService.RenderStepped:Wait() -- Use frame time as key
    if lastRaycastFrame ~= currentFrame then
        raycastCache = {}
        lastRaycastFrame = currentFrame
    end

    if raycastCache[target] ~= nil then return raycastCache[target] end

    local head = target:FindFirstChild("Head") or target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
    if not head then
        raycastCache[target] = false
        return false
    end

    local rayOrigin = Camera.CFrame.Position
    local rayDirection = (head.Position - rayOrigin).Unit * distanceThreshold
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {Player.Character, target}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    raycastCache[target] = not result
    return raycastCache[target]
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
    initialScanAsync() -- One-time async scan
    setupDynamicUpdates() -- Start event-driven updates
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
