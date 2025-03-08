return function(Config, Utilities, ESPObject, ESPConfig)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Player = Players.LocalPlayer
    
    local ESPManager = {
        Humanoids = {}, -- Only track NPCs
        Connection = nil,
    }
    
    function ESPManager.Update()
        if not Config.Enabled then return end
        
        -- Track only NPCs (non-player humanoids)
        for _, humanoid in pairs(workspace:GetDescendants()) do
            if humanoid:IsA("Model") and humanoid:FindFirstChildOfClass("Humanoid") and humanoid ~= Player.Character then
                local hum = humanoid:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 and not ESPManager.Humanoids[humanoid] then
                    local isPlayer = Utilities.isPlayerCharacter(humanoid)
                    if not isPlayer then -- Only NPCs, no players
                        ESPManager.Humanoids[humanoid] = ESPObject.Create(humanoid, "NPC")
                    end
                end
            end
        end
        
        for humanoid, esp in pairs(ESPManager.Humanoids) do
            if humanoid.Parent then
                local hum = humanoid:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    esp:Update()
                else
                    esp:Destroy()
                    ESPManager.Humanoids[humanoid] = nil
                end
            else
                esp:Destroy()
                ESPManager.Humanoids[humanoid] = nil
            end
        end
    end
    
    function ESPManager.Initialize()
        local lastUpdate = 0
        ESPManager.Connection = RunService.Heartbeat:Connect(function()
            local currentTime = tick()
            if currentTime - lastUpdate >= ESPConfig.UpdateInterval then
                ESPManager.Update()
                lastUpdate = currentTime
            end
        end)
        ESPManager.Update()
        print("ESP Initialized - Enabled:", Config.Enabled)
    end
    
    function ESPManager.Cleanup()
        for _, esp in pairs(ESPManager.Humanoids) do
            esp:Destroy()
        end
        ESPManager.Humanoids = {}
        if ESPManager.Connection then
            ESPManager.Connection:Disconnect()
            ESPManager.Connection = nil
        end
        print("ESP Cleaned Up")
    end
    
    function ESPManager.SetEnabled(enabled)
        Config.Enabled = enabled
        if enabled then
            ESPManager.Initialize()
            ESPManager.Update()
            print("ESP Enabled")
        else
            ESPManager.Cleanup()
            print("ESP Disabled")
        end
    end
    
    function ESPManager.IsEnabled()
        return Config.Enabled
    end
    
    return ESPManager
end
