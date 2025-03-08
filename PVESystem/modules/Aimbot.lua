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
local lastCacheUpdate = 0
local cacheCoroutine = nil

-- Async NPC cache update
local function updateNPCCacheAsync()
    if cacheCoroutine then return end -- Prevent overlapping updates
    cacheCoroutine = coroutine.create(function()
        local newCache = {}
        local descendants = workspace:GetDescendants()
        local batchSize = 100 -- Process 100 items per frame
        for i = 1, #descendants, batchSize do
            for j = i, math.min(i + batchSize - 1, #descendants) do
                local humanoid = descendants[j]
                if humanoid:IsA("Model") and humanoid:FindFirstChildOfClass("Humanoid") and humanoid ~= Player.Character then
                    local isPlayer = Players:GetPlayerFromCharacter(humanoid)
                    if not isPlayer and humanoid:FindFirstChildOfClass("Humanoid").Health > 0 then
                        local head = humanoid:FindFirstChild("Head") or humanoid.PrimaryPart or humanoid:FindFirstChildWhichIsA("BasePart")
                        if head and (head.Position - Camera.CFrame.Position).Magnitude <= 100 then -- Limit to 100 studs
                            table.insert(newCache, humanoid)
                        end
                    end
                end
            end
            task.wait() -- Yield to next frame
        end
        npcCache = newCache
        lastCacheUpdate = tick()
        cacheCoroutine = nil
        -- print("NPC cache updated:", #npcCache, "NPCs found")
    end)
    coroutine.resume(cacheCoroutine)
end

-- Get cached NPCs, updating async if necessary
local function getNPCs()
    if tick() - lastCacheUpdate > 0.5 and not cacheCoroutine then -- Update every 0.5s, only if not already updating
        updateNPCCacheAsync()
    end
    return npcCache
end

-- Check line of sight efficiently
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

-- Find closest NPC efficiently
local function findClosestNPC()
    local mouse = UserInputService:GetMouseLocation()
    local ray = Camera:ScreenPointToRay(mouse.X, mouse.Y)
    
    local closestNPC, closestDistance = nil, math.huge
    for _, npc in ipairs(getNPCs()) do -- Use ipairs for faster iteration
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
    updateNPCCacheAsync() -- Initial async cache
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
