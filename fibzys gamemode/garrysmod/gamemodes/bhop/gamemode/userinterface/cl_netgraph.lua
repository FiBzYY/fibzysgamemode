local fontSize = 33
local lastTickTime = RealTime()
local fps = 0
local frameTimeMs = 0
local fpsUpdateInterval = 0.1
local lastFPSUpdateTime = 0
local fpsAccumulator = 0
local fpsSamples = 0

local showCustomHUD = CreateClientConVar("bhop_netgraph", "0", true, false, "Enable/Disable custom netgraph HUD")
local showCustomHUDPos = CreateClientConVar("bhop_showpos", "0", true, false, "Enable/Disable custom pos HUD")

surface.CreateFont("NetGraphFont", {
    font = "Roboto",
    size = 24,
    weight = 500,
    antialias = true,
    shadow = false,
    outline = false,
    italic = false
})

local function CalculateFrameTimeAndFPS()
    local curTime = RealTime()
    local deltaTime = curTime - lastTickTime

    if deltaTime > 0 then
        frameTimeMs = deltaTime * 1000
        local currentFPS = 1 / deltaTime
        fpsAccumulator = fpsAccumulator + currentFPS
        fpsSamples = fpsSamples + 1
        lastTickTime = curTime
    end
end

-- FPS update
local function UpdateFPS()
    local curTime = RealTime()
    if curTime - lastFPSUpdateTime >= fpsUpdateInterval then
        if fpsSamples > 0 then
            fps = math.floor(fpsAccumulator / fpsSamples)
        end
        fpsAccumulator = 0
        fpsSamples = 0
        lastFPSUpdateTime = curTime
    end
end

-- HUD
local function DrawCustomHUDGraph()
    if not showCustomHUD:GetBool() then
        return
    end

    local screenWidth, screenHeight = ScrW(), ScrH()
    local hudX = screenWidth - 20
    local hudY = screenHeight - (4 * fontSize) - 3
    local ping = LocalPlayer():Ping()

    local cmdrate = GetConVar("cl_cmdrate"):GetInt()
    local interp = math.Round(GetConVar("cl_interp"):GetFloat() * 1000)
    local cmdrateText = (cmdrate > 500 or cmdrate < 0) and "Inf" or tostring(cmdrate)

    surface.SetFont("NetGraphFont")

    -- Ping
    draw.SimpleText("Ping: " .. ping, "NetGraphFont", hudX + 1, hudY + 1, Color(0, 0, 0, 200), TEXT_ALIGN_RIGHT)
    draw.SimpleText("Ping: " .. ping, "NetGraphFont", hudX, hudY, Color(255, 255, 255), TEXT_ALIGN_RIGHT)

    -- CmdRate
    draw.SimpleText("CmdRate: " .. cmdrateText, "NetGraphFont", hudX + 1, hudY + fontSize + 1, Color(0, 0, 0, 200), TEXT_ALIGN_RIGHT)
    draw.SimpleText("CmdRate: " .. cmdrateText, "NetGraphFont", hudX, hudY + fontSize, Color(255, 255, 255), TEXT_ALIGN_RIGHT)

    -- Interp
    draw.SimpleText("Interp: " .. interp .. "%", "NetGraphFont", hudX + 1, hudY + 2 * fontSize + 1, Color(0, 0, 0, 200), TEXT_ALIGN_RIGHT)
    draw.SimpleText("Interp: " .. interp .. "%", "NetGraphFont", hudX, hudY + 2 * fontSize, Color(255, 255, 255), TEXT_ALIGN_RIGHT)

    -- FPS and Frame Time
    draw.SimpleText("FPS: " .. fps .. " " .. string.format("%.2f ms", frameTimeMs), "NetGraphFont", hudX + 1, hudY + 3 * fontSize + 1, Color(0, 0, 0, 200), TEXT_ALIGN_RIGHT)
    draw.SimpleText("FPS: " .. fps .. " " .. string.format("%.2f ms", frameTimeMs), "NetGraphFont", hudX, hudY + 3 * fontSize, Color(255, 255, 255), TEXT_ALIGN_RIGHT)
end

-- Draw
local function DrawCustomPosHUD()
    if not showCustomHUDPos:GetBool() then
        return
    end

    local hudWidth = 180
    local hudHeight = 100
    local hudPosX = ScrW() - hudWidth + 175
    local hudPosY = 20

    local playerPos = LocalPlayer():GetPos()
    local playerAngles = LocalPlayer():EyeAngles()
    local vel = LocalPlayer():GetVelocity()
    local speed3D = vel:Length()

    local posText = string.format("Pos: (%.2f, %.2f, %.2f)", playerPos.x, playerPos.y, playerPos.z)
    local anglesText = string.format("Angles: (%.2f, %.2f, %.2f)", playerAngles.p, playerAngles.y, playerAngles.r)
    local velText = string.format("Vel: %.2f", speed3D)

    draw.SimpleText(posText, "NetGraphFont", hudPosX + 1, hudPosY + 10 + 1, Color(0, 0, 0, 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    draw.SimpleText(posText, "NetGraphFont", hudPosX, hudPosY + 10, Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

    draw.SimpleText(anglesText, "NetGraphFont", hudPosX + 1, hudPosY + 35 + 1, Color(0, 0, 0, 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    draw.SimpleText(anglesText, "NetGraphFont", hudPosX, hudPosY + 35, Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

    draw.SimpleText(velText, "NetGraphFont", hudPosX + 1, hudPosY + 60 + 1, Color(0, 0, 0, 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    draw.SimpleText(velText, "NetGraphFont", hudPosX, hudPosY + 60, Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
end

-- Draw
local function DrawTickRate()
    if not showCustomHUDPos:GetBool() then
        return
    end

    local screenWidth = ScrW()
    local hudX = screenWidth - 125
    local hudY = 5

    local tickrate = 1 / engine.TickInterval()
    surface.SetFont("NetGraphFont")
    surface.SetTextColor(0, 0, 0, 200)
    surface.SetTextPos(hudX + 1, hudY + 1)
    surface.DrawText("TickRate: " .. math.Round(tickrate))

    surface.SetTextColor(255, 255, 255, 255)
    surface.SetTextPos(hudX, hudY)
    surface.DrawText("TickRate: " .. math.Round(tickrate))
end

-- HUD
hook.Add("HUDPaint", "DrawCustomHUD", function()
    CalculateFrameTimeAndFPS()
    UpdateFPS()
    DrawCustomPosHUD()
    DrawTickRate()
    DrawCustomHUDGraph()
end)