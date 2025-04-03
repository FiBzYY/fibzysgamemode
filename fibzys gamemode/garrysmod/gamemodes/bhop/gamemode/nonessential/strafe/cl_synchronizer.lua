local COLORS = {
    EXTRA = Color(24, 150, 211, 255),
    PERFECT = Color(87, 200, 255, 255),
    GOOD = Color(21, 152, 86, 255),
    SLOW = Color(248, 222, 74, 255),
    NEUTRAL = Color(255, 255, 255, 255),
    LOSS = Color(220, 116, 13, 255),
    STOP = Color(211, 24, 24, 255),
    BACKGROUND = Color(53, 66, 75, 255),
    TEXT = Color(255, 255, 255, 255),
    BLACK = Color(0, 0, 0, 255)
}

local g_fLastAngles = {}
local g_yawRatioHistory = {}
local g_gainRatioHistory = {}
local g_bufferSize = 10  
local strafeRight = 0
local lastUpdateTime = 0
local TICK_UPDATE_INTERVAL = engine.TickInterval()
local indicatorPercentage = 90  

local hudEnabled = CreateClientConVar("bhop_strafesync", "1", true, false, "Enable or disable Strafe Sync HUD")

local function NormalizeAngle(angle)
    return (angle + 180) % 360 - 180
end

local function GetBufferedSum(buffer)
    local sum = 0
    for _, val in ipairs(buffer) do
        sum = sum + val
    end
    return sum / math.max(1, #buffer)
end

local function AddToBuffer(buffer, value)
    table.insert(buffer, value)
    if #buffer > g_bufferSize then
        table.remove(buffer, 1)
    end
end

hook.Add("StartCommand", "CalculateYawRatio", function(ply, cmd)
    if not IsValid(ply) or ply ~= LocalPlayer() then return end
    if cmd:TickCount() == 0 then return end

    local lastYaw = g_fLastAngles[ply] or 0
    local yawDiff = NormalizeAngle(cmd:GetViewAngles()[2] - lastYaw)
    local velocity = ply:GetVelocity():Length2D()
    local perfJss = math.deg(math.atan(32.4 / velocity))

    local yawRatio = math.abs(yawDiff / perfJss)
    local gainRatio = 0 -- DO TO

    AddToBuffer(g_yawRatioHistory, yawRatio)
    AddToBuffer(g_gainRatioHistory, gainRatio)

    g_fLastAngles[ply] = cmd:GetViewAngles()[2]
    strafeRight = cmd:GetSideMove() > 0 and 1 or (cmd:GetSideMove() < 0 and -1 or 0)
end)

local function GetSyncColor(syncRatio)
    if syncRatio > 1.02 then return COLORS.EXTRA
    elseif syncRatio > 0.99 then return COLORS.PERFECT
    elseif syncRatio > 0.95 then return COLORS.GOOD
    elseif syncRatio <= -5 then return COLORS.STOP
    elseif syncRatio > 0.85 then return COLORS.SLOW
    elseif syncRatio > 0.5 then return COLORS.NEUTRAL
    else return COLORS.LOSS
    end
end

hook.Add("HUDPaint", "DrawStrafeSyncHUD", function()
    local localPlayer = LocalPlayer()
    if not IsValid(localPlayer) or not hudEnabled:GetBool() then return end

    local ply = localPlayer:GetObserverTarget()
    if not IsValid(ply) or not ply:IsPlayer() then
        ply = localPlayer
    end

    if ply:IsBot() then return end

    if TIMER:GetStyle(ply) == TIMER:GetStyleID("AS") then return end

    local yawRatio = GetBufferedSum(g_yawRatioHistory)
    local gainRatio = GetBufferedSum(g_gainRatioHistory)

    local screenWidth, screenHeight = ScrW(), ScrH()
    local barWidth, barHeight = 300, 16
    local barX = (screenWidth / 2) - (barWidth / 2)
    local barY = screenHeight - 500

    draw.RoundedBox(8, barX, barY, barWidth, barHeight, COLORS.BACKGROUND)

    local fillWidth = math.Clamp(yawRatio * barWidth * 0.50, 0, barWidth)
    local syncColor = GetSyncColor(yawRatio)

    if strafeRight == 1 then
        draw.RoundedBox(8, (barX + barWidth) - fillWidth, barY, fillWidth, barHeight, syncColor)
    elseif strafeRight == -1 then
        draw.RoundedBox(8, barX, barY, fillWidth, barHeight, syncColor)
    end

    draw.RoundedBox(0, barX + (barWidth / 2) - 1, barY, 2, barHeight, COLORS.BLACK)
end)