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

-- Toggle tracking for an object
local function toggleTracking(object, espObjectModule)
    if not isInteractableSize(object) then
        print("Object too large to track:", object.Name)
        return
    end

    if MiddleClick.TrackedItems[object] then
        -- Remove from tracking if already tracked
        MiddleClick.TrackedItems[object]:Destroy()
        MiddleClick.TrackedItems[object] = nil
        print("Stopped tracking:", object.Name)
    else
        -- Add to tracking if not already tracked
        local esp = espObjectModule.Create(object, "Item")
        MiddleClick.TrackedItems[object] = esp
        esp:Update()
        print("Started tracking:", object.Name)
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

            -- Toggle tracking for the target
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
