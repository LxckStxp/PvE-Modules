local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer

local MiddleClick = {
    Enabled = false, -- Controlled by UI
    TrackedItems = {}, -- Store tracked items with their ESP instances
    MaxSizeThreshold = 10, -- Studs; threshold for "interactable" size
}

-- Check if an object is small enough to be interactable
local function isInteractableSize(object)
    local size = object:IsA("BasePart") and object.Size or (object:IsA("Model") and object:GetExtentsSize() or Vector3.new(0, 0, 0))
    return size.Magnitude <= MiddleClick.MaxSizeThreshold
end

-- Find all objects with the same name
local function findMatchingObjects(targetName)
    local matches = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == targetName and isInteractableSize(obj) then
            table.insert(matches, obj)
        end
    end
    return matches
end

-- Toggle tracking for an object and its matches
local function toggleTracking(object, espObjectModule)
    if not isInteractableSize(object) then
        print("Object too large to track:", object.Name)
        return
    end

    local targetName = object.Name
    local matches = findMatchingObjects(targetName)
    
    -- If any match is already tracked, remove all matches
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
end

-- Initialize middle-click detection
function MiddleClick.Initialize(espObjectModule)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not MiddleClick.Enabled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton3 then -- Middle click
            local mouse = Player:GetMouse()
            local target = mouse.Target
            if not target then return end

            -- Toggle tracking for the target and all matching items
            toggleTracking(target, espObjectModule)
        end
    end)

    -- Update tracked items
    game:GetService("RunService").Heartbeat:Connect(function()
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

-- Cleanup function to remove all tracked items
function MiddleClick.Cleanup()
    for _, esp in pairs(MiddleClick.TrackedItems) do
        esp:Destroy()
    end
    MiddleClick.TrackedItems = {}
end

return MiddleClick
