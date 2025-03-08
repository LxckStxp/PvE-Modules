return function(Config, Utilities, ESPConfig)
    local TweenService = game:GetService("TweenService")
    
    local ESPObject = {}
    
    function ESPObject.Create(object, espType)
        local highlight = Instance.new("Highlight")
        highlight.FillTransparency = 0.8
        highlight.OutlineTransparency = 0.1
        highlight.Adornee = object
        highlight.Parent = game.CoreGui
        
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 130, 0, espType == "Item" and 25 or 50) -- Increased height for NPC health bar
        billboard.StudsOffset = Vector3.new(0, 3.5, 0) -- Moved above head (was 2.5)
        billboard.Adornee = object:IsA("Model") and (object:FindFirstChild("Head") or object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")) or object
        billboard.AlwaysOnTop = true
        billboard.Parent = game.CoreGui
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, espType == "Item" and 1 or 0.5, 0) -- Adjusted for NPC layout
        label.Position = UDim2.new(0, 0, 0, 0)
        label.BackgroundTransparency = 1
        label.TextSize = 14
        label.Font = Enum.Font.GothamBold
        label.TextStrokeTransparency = 0.2
        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        label.Parent = billboard
        
        local healthBar, healthFill, healthBorder
        if espType == "NPC" then
            healthBar = Instance.new("Frame")
            healthBar.Size = UDim2.new(0.9, 0, 0.3, 0) -- Increased height for visibility
            healthBar.Position = UDim2.new(0.05, 0, 0.6, 0) -- Below name, above head
            healthBar.BackgroundTransparency = 1
            healthBar.Parent = billboard
            
            healthBorder = Instance.new("Frame")
            healthBorder.Size = UDim2.new(1, 4, 1, 4)
            healthBorder.Position = UDim2.new(0, -2, 0, -2)
            healthBorder.BackgroundColor3 = Config.Colors.NPC
            healthBorder.BackgroundTransparency = 0.5
            healthBorder.BorderSizePixel = 0
            healthBorder.ZIndex = 0
            healthBorder.Parent = healthBar
            
            healthFill = Instance.new("Frame")
            healthFill.Size = UDim2.new(1, 0, 1, 0)
            healthFill.Position = UDim2.new(0, 0, 0, 0)
            healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            healthFill.BorderSizePixel = 0
            healthFill.ZIndex = 1
            healthFill.Parent = healthBar
            
            local gradient = Instance.new("UIGradient")
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 0))
            })
            gradient.Rotation = 0
            gradient.Parent = healthFill
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 3)
            corner.Parent = healthBorder
            corner:Clone().Parent = healthFill
        end
        
        local esp = {
            Highlight = highlight,
            Billboard = billboard,
            Label = label,
            HealthBar = healthBar,
            HealthFill = healthFill,
            HealthBorder = healthBorder,
            Object = object,
            Type = espType,
            LastPosition = nil,
            LastDistance = nil,
            
            Update = function(self)
                if not Config.Enabled or not self.Object.Parent then
                    self.Highlight.Enabled = false
                    self.Billboard.Enabled = false
                    if self.HealthBar then self.HealthBar.Visible = false end
                    return
                end
                
                local position = Utilities.getPosition(self.Object)
                local distance = Utilities.getDistance(position)
                
                if self.LastDistance and distance > Config.MaxDistance * ESPConfig.SpatialFilterThreshold and 
                   (self.LastPosition and (position - self.LastPosition).Magnitude < ESPConfig.SpatialMoveThreshold) then
                    return
                end
                
                self.LastPosition = position
                self.LastDistance = distance
                
                if distance > Config.MaxDistance then
                    self.Highlight.Enabled = false
                    self.Billboard.Enabled = false
                    if self.HealthBar then self.HealthBar.Visible = false end
                    return
                end
                
                self.Highlight.Enabled = true
                self.Billboard.Enabled = true
                
                local fadeStart = Config.MaxDistance * ESPConfig.FadeStartMultiplier
                local fade = distance > fadeStart and math.clamp((distance - fadeStart) / (Config.MaxDistance - fadeStart), 0, 1) or 0
                self.Highlight.FillTransparency = 0.8 + fade * 0.2
                self.Highlight.OutlineTransparency = 0.1 + fade * 0.9
                self.Label.TextTransparency = fade
                self.Label.TextStrokeTransparency = 0.2 + fade * 0.8
                
                local color
                if self.Type == "NPC" then
                    color = Config.Colors.NPC
                else -- Item
                    local part = self.Object:IsA("BasePart") and self.Object or (self.Object:IsA("Model") and (self.Object.PrimaryPart or self.Object:FindFirstChildWhichIsA("BasePart")))
                    color = part and part.BrickColor and part.BrickColor.Color or Config.Colors.Default
                end
                
                self.Highlight.FillColor = color
                self.Highlight.OutlineColor = color:Lerp(Color3.fromRGB(255, 255, 255), 0.4)
                
                local name = self.Object.Name
                if #name > 12 then name = name:sub(1, 10) .. "..." end
                local text = string.format("%s [%dm]", name, math.floor(distance))
                self.Label.TextColor3 = color
                self.Label.Text = text
                
                if self.Type == "NPC" then
                    if distance <= ESPConfig.HealthBarDistance then
                        self.HealthBar.Visible = true
                        local health = Utilities.getHealth(self.Object)
                        local healthPercent = math.clamp(health.Current / health.Max, 0, 1)
                        TweenService:Create(self.HealthFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                            Size = UDim2.new(healthPercent, 0, 1, 0)
                        }):Play()
                        self.HealthBorder.BackgroundTransparency = 0.5 + fade * 0.5
                        self.HealthFill.BackgroundTransparency = fade
                    else
                        self.HealthBar.Visible = false
                    end
                end
            end,
            
            Destroy = function(self)
                Utilities.safeDestroy(self.Highlight)
                Utilities.safeDestroy(self.Billboard)
            end
        }
        
        return esp
    end
    
    return ESPObject
end
