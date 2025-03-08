local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local Utilities = {}

function Utilities.getDistance(position)
    if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then return 9999 end
    return (Player.Character.HumanoidRootPart.Position - position).Magnitude
end

function Utilities.getPosition(object)
    if object:IsA("Model") then
        local primaryPart = object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")
        return primaryPart and primaryPart.Position or Vector3.new(0, 0, 0)
    end
    return object:IsA("BasePart") and object.Position or Vector3.new(0, 0, 0)
end

function Utilities.isPlayerCharacter(model)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character == model then return true end
    end
    return false
end

function Utilities.safeDestroy(instance)
    pcall(function()
        if instance and instance.Parent then
            instance:Destroy()
        end
    end)
end

-- Get health information for a humanoid
function Utilities.getHealth(model)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then
        return {
            Current = humanoid.Health,
            Max = humanoid.MaxHealth
        }
    end
    return { Current = 0, Max = 100 } -- Fallback if no humanoid found
end

return Utilities
