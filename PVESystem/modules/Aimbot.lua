local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local Player = Players.LocalPlayer

local Aimbot = {
    Enabled = false, -- Controlled by UI
    Aiming = false, -- Tracks right-click state
    Target = nil,   -- Current NPC target
    RenderConnection = nil, -- Store RenderStepped connection
    Settings = {
        AimKey = Enum.UserInputType.MouseButton2, -- RightClick
    }
}

-- NPC caching
local npcCache = {}
local lastCacheUpdate = 0

-- Update NPC cache
local function updateNPCCache()
    npcCache = {}
    for _, humanoid in pairs(workspace:GetDescendants()) do
        if humanoid:IsA("Model") and humanoid:FindFirstChildOfClass("Humanoid") and humanoid ~= Player.Character then
            local isPlayer = Players:GetPlayerFromCharacter(humanoid)
            if not isPlayer and humanoid:FindFirstChildOfClass("Humanoid").Health > 0 then
                table.insert(npcCache, humanoid)
            end
        end
    end
    lastCacheUpdate = tick()
    print("NPC cache updated:", #npcCache, "NPCs found")
end

-- Get cached NPCs, updating if necessary
local function getNPCs()
    if tick() - lastCacheUpdate > 0.5 then -- Update every 0.5 seconds
        updateNPCCache()
    end
    return npcCache
end

-- Check if there's a clear line of sight to the target
local function hasLineOfSight(target)
    local head = target:FindFirstChild("Head") or target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
    if not head then return false end

    local rayOrigin = Camera.CFrame.Position
    local rayDirection = (head.Position - rayOrigin).Unit * 1000
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {Player.Character, target}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    return not result -- No obstruction if result is nil
end

-- Find closest NPC to crosshair with line of sight
local function findClosestNPC()
    local mouse = UserInputService:GetMouseLocation()
    local ray = Camera:ScreenPointToRay(mouse.X, mouse.Y)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {Player.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local closestNPC, closestDistance = nil, math.huge
    for _, npc in pairs(getNPCs()) do
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
    if closestNPC then
        print("Found closest NPC:", closestNPC.Name)
    else
        print("No visible NPC found")
    end
    return closestNPC
end

-- Aim at target’s head or primary part instantly
local function aimAtTarget()
    if not Aimbot.Target or not Aimbot.Target.Parent then
        Aimbot.Target = findClosestNPC() -- Switch target if current one is gone
        if not Aimbot.Target then return end
    end
    
    local head = Aimbot.Target:FindFirstChild("Head") or Aimbot.Target.PrimaryPart
    if not head or not hasLineOfSight(Aimbot.Target) then
        Aimbot.Target = findClosestNPC() -- Switch if no line of sight
        if not Aimbot.Target then return end
        head = Aimbot.Target:FindFirstChild("Head") or Aimbot.Target.PrimaryPart
    end
    
    local targetPos = head.Position
    local lookVector = (targetPos - Camera.CFrame.Position).Unit
    local newCFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + lookVector)
    
    Camera.CFrame = newCFrame
end

-- Handle input for aimbot
function Aimbot.Initialize()
    updateNPCCache() -- Initial cache population
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not Aimbot.Enabled then return end
        if input.UserInputType == Aimbot.Settings.AimKey then
            print("Aimbot activated")
            Aimbot.Aiming = true
            Aimbot.Target = findClosestNPC()
            if Aimbot.Target then
                if Aimbot.RenderConnection then
                    Aimbot.RenderConnection:Disconnect()
                end
                Aimbot.RenderConnection = RunService.RenderStepped:Connect(aimAtTarget)
            end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed or not Aimbot.Enabled then return end
        if input.UserInputType == Aimbot.Settings.AimKey then
            print("Aimbot deactivated")
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
