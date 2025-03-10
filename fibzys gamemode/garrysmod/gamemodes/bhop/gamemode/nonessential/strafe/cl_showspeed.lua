local centerspeedConVar = CreateClientConVar("bhop_center_speed", "0", true, false, "Displays the current speed in the top middle of the screen")
local colorDifferenceConVar = CreateClientConVar("bhop_center_speed_color_difference", "1", true, false, "Toggles color changes based on speed difference")
local DrawText = draw.SimpleText
local ScrW, ScrH = ScrW, ScrH
local Iv = IsValid

local Centerspeed = {
    Enabled = centerspeedConVar:GetBool(),
    ColorDifference = colorDifferenceConVar:GetBool(),
    TickNumber = 0,
    SpeedUpdateInterval = 50,
    LastSpeed = 0,
    DisplaySpeed = 0,
    Color = Color(255, 255, 255)
}

function Centerspeed.Toggle()
    Centerspeed.Enabled = not Centerspeed.Enabled
    RunConsoleCommand("bhop_center_speed", Centerspeed.Enabled and "1" or "0")
    print("Center Speed: " .. (Centerspeed.Enabled and "Enabled" or "Disabled"))
end

local function GetPlayerSpeed(ply)
    if not Iv(ply) then return 0 end

    -- Uses internal velocity variable when possible for accuracy
    local vel = ply:GetInternalVariable("m_vecAbsVelocity") or ply:GetVelocity()
    return math.Round(vel:Length2D())
end

hook.Add("StartCommand", "UpdateCenterSpeed", function(ply, cmd)
    if not Centerspeed.Enabled or not Iv(ply) then return end

    Centerspeed.TickNumber = Centerspeed.TickNumber + 1

    if Centerspeed.TickNumber % Centerspeed.SpeedUpdateInterval == 0 then
        local speed = GetPlayerSpeed(ply)
        Centerspeed.DisplaySpeed = speed

        if Centerspeed.ColorDifference then
            local speedDelta = speed - Centerspeed.LastSpeed
            local maxVel = 35000

            if speed >= maxVel then
                Centerspeed.Color = Color(255, 174, 0)      -- Max speed warning
            elseif speedDelta > 0 then
                Centerspeed.Color = Color(0, 255, 255)      -- Gaining speed
            elseif speedDelta < 0 then
                Centerspeed.Color = Color(255, 0, 0)        -- Losing speed
            else
                Centerspeed.Color = Color(255, 255, 255)    -- Neutral speed
            end
        else
            Centerspeed.Color = Color(255, 255, 255)
        end

        Centerspeed.LastSpeed = speed
    end
end)

local function DrawCenterSpeed()
    if not Centerspeed.Enabled or Centerspeed.DisplaySpeed == 0 then return end

    local scrW, scrH = ScrW(), ScrH()
    local posX, posY = scrW / 2, (scrH / 2) - 180
    local shadowOffset = 2
    local font = "hud.simplefont"

    DrawText(Centerspeed.DisplaySpeed .. " u/s", font, posX + shadowOffset, posY + shadowOffset, Color(0, 0, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    DrawText(Centerspeed.DisplaySpeed .. " u/s", font, posX, posY, Centerspeed.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

hook.Add("HUDPaint", "DrawCenterSpeed", DrawCenterSpeed)

concommand.Add("bhop_centerspeed_toggle", function()
    Centerspeed.Toggle()
end)

concommand.Add("bhop_centerspeed_colordifference_toggle", function()
    Centerspeed.ColorDifference = not Centerspeed.ColorDifference
    RunConsoleCommand("bhop_center_speed_color_difference", Centerspeed.ColorDifference and "1" or "0")
    print("Color Difference: " .. (Centerspeed.ColorDifference and "Enabled" or "Disabled"))
end)

hook.Add("Initialize", "SyncCenterSpeedConVars", function()
    Centerspeed.Enabled = centerspeedConVar:GetBool()
    Centerspeed.ColorDifference = colorDifferenceConVar:GetBool()
end)

cvars.AddChangeCallback("bhop_center_speed", function(_, _, newValue)
    Centerspeed.Enabled = tobool(newValue)
    print("Center Speed Updated: " .. (Centerspeed.Enabled and "Enabled" or "Disabled"))
end)

cvars.AddChangeCallback("bhop_center_speed_color_difference", function(_, _, newValue)
    Centerspeed.ColorDifference = tobool(newValue)
    print("Color Difference Updated: " .. (Centerspeed.ColorDifference and "Enabled" or "Disabled"))
end)