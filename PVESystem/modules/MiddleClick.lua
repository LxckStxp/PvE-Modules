local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local MiddleClick = {
    Enabled = false,
    TrackedItems = {},
    MaxSizeThreshold = 10,
}

-- Check if an object is small enough
local function isInteractableSize(object)
    local size = object:IsA("BasePart") and object.Size or (object:IsA("Model") and object:GetExtentsSize() or Vector3.new(0, 0, 0))
    return size.Magnitude <= MiddleClick.MaxSizeThreshold
end

-- Async find matching objects
local function findMatchingObjectsAsync(targetName, callback)
    coroutine.wrap(function()
        local matches = {}
        local descendants = workspace:GetDescendants()
        local batchSize = 100
        for i = 1, #descendants, batchSize do
            for j = i, math.min(i + batchSize - 1, #descendants) do
                local obj = descendants[j]
                if obj.Name == targetName and isInteractableSize(obj) then
                    table.insert(matches, obj)
                end
            end
            task.wait()
        end
        callback(matches)
    end)()
end

-- Toggle tracking async
local function toggleTracking(object, espObjectModule)
    if not isInteractableSize(object) then
        print("Object too large to track:", object.Name)
        return
    end

    local targetName = object.Name
    findMatchingObjectsAsync(targetName, function(matches)
        local isTracked = false
        for _, match in pairs(matches) do
            if MiddleClick.TrackedItems[match] then
                isTracked = true
                break
            end
        end

        if isTracked then
            for _, match in pairs(matches) do
                if MiddleClick.TrackedItems[match] then
                    MiddleClick.TrackedItems[match]:Destroy()
                    MiddleClick.TrackedItems[match] = nil
                end
            end
            print("Stopped tracking all:", targetName)
        else
            for _, match in pairs(matches) do
                if not MiddleClick.TrackedItems[match] then
                    local esp = espObjectModule.Create(match, "Item")
                    MiddleClick.TrackedItems[match] = esp
                    esp:Update()
                end
            end
            print("Started tracking all:", targetName, "(", #matches, "items)")
        end
    end)
end

-- Initialize middle-click
function MiddleClick.Initialize(espObjectModule)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not MiddleClick.Enabled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton3 then
            local mouse = Player:GetMouse()
            local target = mouse.Target
            if not target then return end
            toggleTracking(target, espObjectModule)
        end
    end)

    -- Update tracked items efficiently
    RunService.Heartbeat:Connect(function()
        for obj, esp in pairs(MiddleClick.TrackedItems) do
            if obj.Parent then
                esp:Update()
            else
                esp:Destroy()
                MiddleClick.TrackedItems[obj] = nil
            end
        end
    end)
end

function MiddleClick.Cleanup()
    for _, esp in pairs(MiddleClick.TrackedItems) do
        esp:Destroy()
    end
    MiddleClick.TrackedItems = {}
end

return MiddleClick
