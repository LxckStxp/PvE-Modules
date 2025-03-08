local ESPConfig = {
    FadeStartMultiplier = 0.7, -- Fade starts at 70% of MaxDistance
    HealthBarDistance = 100,   -- Health bars visible under 100 studs (NPCs only)
    SpatialFilterThreshold = 0.9, -- Skip updates beyond 90% MaxDistance
    SpatialMoveThreshold = 5,  -- Movement threshold for spatial filtering (studs)
    UpdateInterval = 0.2,      -- Update every 0.2 seconds
}

return ESPConfig
