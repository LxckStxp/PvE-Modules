local baseUrl = "https://raw.githubusercontent.com/LxckStxp/PvE-Modules/main/PVESystem/modules/"

local Config = loadstring(game:HttpGet(baseUrl .. "Config.lua"))()
local Utilities = loadstring(game:HttpGet(baseUrl .. "Utilities.lua"))()
local ESP = loadstring(game:HttpGet(baseUrl .. "ESP/ESP.lua"))()(Config, Utilities)
local ESPObject = loadstring(game:HttpGet(baseUrl .. "ESP/ESPObject.lua"))()(Config, Utilities, loadstring(game:HttpGet(baseUrl .. "ESP/ESPConfig.lua"))())
local MiddleClick = loadstring(game:HttpGet(baseUrl .. "MiddleClick.lua"))()
local Aimbot = loadstring(game:HttpGet(baseUrl .. "Aimbot.lua"))()
local UI = loadstring(game:HttpGet(baseUrl .. "UI.lua"))()(Config, ESP, MiddleClick, Aimbot)

ESP.Initialize()
MiddleClick.Initialize(ESPObject) -- Pass ESPObject for dynamic tracking
Aimbot.Initialize()

print("PvE Cheat Loaded Successfully!")
