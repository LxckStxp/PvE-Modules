return function(Config, ESP, MiddleClick, Aimbot)
    local CensuraDev = loadstring(game:HttpGet("https://raw.githubusercontent.com/LxckStxp/Censura/main/CensuraDev.lua"))()
    local UI = CensuraDev.new("PvE Cheat")

    -- Toggle ESP Enable (NPCs only)
    UI:CreateToggle("ESP Enable (NPCs)", Config.Enabled, function(state)
        Config.Enabled = state
        if state then
            ESP.Initialize()
            ESP.Update()
        else
            ESP.Cleanup()
        end
    end)
    
    -- Max Distance Slider
    UI:CreateSlider("Max Distance", 100, 2000, Config.MaxDistance, function(value)
        Config.MaxDistance = value
    end)
    
    -- Middle Click Utility Toggle (Dynamic Item Tracking)
    UI:CreateToggle("Middle Click Item Tracking", MiddleClick.Enabled, function(state)
        MiddleClick.Enabled = state
        if not state then
            MiddleClick.Cleanup() -- Clear tracked items when disabled
        end
    end)
    
    -- Aimbot Toggle
    local aimbotEnabled = (Aimbot and Aimbot.Enabled ~= nil) and Aimbot.Enabled or false
    UI:CreateToggle("Aimbot (NPCs)", aimbotEnabled, function(state)
        if Aimbot and Aimbot.Enabled ~= nil then
            Aimbot.Enabled = state
            print("Aimbot toggled to:", state)
        else
            warn("Aimbot module not loaded or Enabled property missing")
        end
    end)
    
    return UI
end
