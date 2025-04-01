SSJ = SSJ or {}

-- Cache
local hook_Add, format, floor, mc, min, band = hook.Add, string.format, math.floor, math.Clamp, math.min, bit.band
local math_sin, math_cos, math_rad, bit_band = math.sin, math.cos, math.rad, bit.band
local mabs, matan, mdeg = math.abs, math.atan, math.deg
local Vector, Color, IsValid = Vector, Color, IsValid

-- Set tables
local BHOP_FRAMES = 10
local g_fTickrate = 0.01
local OFFSETS_MAX_FRAME = 15

local FORWARD_SCALE = 0.3
local SIDE_SCALE = 2
local IDEAL_GAIN = 32.4
local MATH_PI = 3.14159
local zeroVec = Vector(0, 0, 0)

-- SSJ
local g_JumpData = {}
local totalGain = {}
local tickCount = {}
local g_bJumpedThisFrame = {}
local g_iTicksOnGround = {}
local g_iStrafeTick = {}
local g_iSyncedTick = {}
local g_iJump = {}
local g_fOldSpeed = {}
local g_fRawGain = {}
local g_iButtonCache = {}
local g_fOldVelocity = {}
local g_iStrafeCount = {}
local g_fSpeedLoss = {}
local g_fTraveledDistance = {}
local g_fTrajectory = {}
local g_iTouchTicks = {}
local g_bTouchesWall = {}
local g_fOldHeight = {}
local g_fInitialHeight = {}
local g_iUsageMode = {}
local g_bUsageRepeat = {}
local g_bFirstJump = {}

-- JSS
local g_fAvgDiffFromPerf = {}
local g_fAvgAbsoluteJss = {}
local g_fLastAngles = {}
local g_jssThisTick = {}
local g_lastSpeed = {}
local g_prevSpeed = {}
local g_iYawwingTick = {}
local g_fJumpTime = {}
local g_speedDiff = {}
gB_IllegalSSJ = {}

-- Offests
local g_fLastNonZeroMove = {}
local g_iKeyTick = {}
local g_iTurnTick = {}
local g_iCmdNum = {}
local g_iTurnDir = {}

local g_bNoPress = {}
local g_bOverlap = {}
local g_bSawPress = {}
local g_bSawTurn = {}

local FORWARD_MOVE = 0
local SIDE_MOVE = 1
local BHOP_LEFT = 0
local BHOP_RIGHT = 1

if CLIENT then
    CreateClientConVar("bhop_showssj", "1", true, false, "Toggle SSJ display in chat")
    CreateClientConVar("bhop_showpre", "1", true, false, "Toggle SSJ display in chat")
end

hook.Add("Initialize", "SSJ_SetTickRate", function()
    g_fTickrate = engine.TickInterval()
end)

hook.Add("PlayerInitialSpawn", "OnClientPutInServer", function(ply)
    g_JumpData[ply] = {}
    g_iStrafeCount[ply] = 0
    g_bJumpedThisFrame[ply] = false
    g_iButtonCache[ply] = 0
    g_fSpeedLoss[ply] = 0
    g_iTicksOnGround[ply] = 0
    g_iStrafeTick[ply] = 0
    g_iSyncedTick[ply] = 0
    g_iJump[ply] = 0
    g_fRawGain[ply] = 0
    g_fOldVelocity[ply] = 0
    g_fTraveledDistance[ply] = Vector(0, 0, 0)
    g_fTrajectory[ply] = 0
    g_iTouchTicks[ply] = 0
    g_bTouchesWall[ply] = 0
    g_fOldHeight[ply] = 0
    g_fInitialHeight[ply] = 0
    g_iYawwingTick[ply] = 0

    g_fAvgDiffFromPerf[ply] = 0
    g_fAvgAbsoluteJss[ply] = 0
    g_jssThisTick[ply] = 0

    g_speedDiff[ply] = 0
    g_lastSpeed[ply] = 0
    g_fJumpTime[ply] = 0

    g_iUsageMode[ply] = 0
    g_bUsageRepeat[ply] = 0
    g_bFirstJump[ply] = 0

    g_fLastNonZeroMove[ply] = { [SIDE_MOVE] = 0, [FORWARD_MOVE] = 0 }
    g_iKeyTick[ply] = 0
    g_iTurnTick[ply] = 0
    g_iCmdNum[ply] = 0

    g_iTurnDir[ply] = 0
    g_bNoPress[ply] = false
    g_bOverlap[ply] = false
    g_bSawPress[ply] = false
    g_bSawTurn[ply] = false

    gB_IllegalSSJ[ply] = false

    local ssj = ply:GetPData("SSJ_Settings", false)
    ply.SSJ = ssj and {["Settings"] = util.JSONToTable(ssj)} or {
        ["Settings"] = {
            true,  -- 1: Toggle
            true,   -- 2: Mode
            false,   -- 3: Speed Difference
            false,    -- 4: Height Difference
            true,       -- 5: Observers Stats
            false,        -- 6: Gain Percentage
            false,          -- 7: Strafes Per Jump
            false,           -- 8: Show JSS
            false,          -- 9: Show Eff
            false,         -- 10: Show Sync
            false,       -- 11: Show Last Speed
            false,      -- 12: Show Yaw
            false,    -- 13: Show Time
            true  -- 14 Pre-Speed
        }
    }
end)

hook.Add("PlayerDisconnected", "CleanupSSJData", function(ply)
    g_JumpData[ply] = nil
    g_iStrafeCount[ply] = nil
    g_bJumpedThisFrame[ply] = nil
    g_iButtonCache[ply] = nil
    g_fSpeedLoss[ply] = nil
    g_iTicksOnGround[ply] = nil
    g_iStrafeTick[ply] = nil
    g_iSyncedTick[ply] = nil
    g_iJump[ply] = nil
    g_fRawGain[ply] = nil
    g_fOldVelocity[ply] = nil
    g_fTraveledDistance[ply] = nil
    g_fTrajectory[ply] = nil
    g_iTouchTicks[ply] = nil
    g_bTouchesWall[ply] = nil
    g_fOldHeight[ply] = nil
    g_fInitialHeight[ply] = nil
    g_iYawwingTick[ply] = nil

    g_fAvgDiffFromPerf[ply] = nil
    g_fAvgAbsoluteJss[ply] = nil
    g_jssThisTick[ply] = nil

    g_speedDiff[ply] = nil
    g_lastSpeed[ply] = nil
    g_fJumpTime[ply] = nil

    g_iUsageMode[ply] = nil
    g_bUsageRepeat[ply] = nil
    g_bFirstJump[ply] = nil

    g_fLastNonZeroMove[ply] = nil
    g_iKeyTick[ply] = nil
    g_iTurnTick[ply] = nil
    g_iCmdNum[ply] = nil

    g_iTurnDir[ply] = nil
    g_bNoPress[ply] = nil
    g_bOverlap[ply] = nil
    g_bSawPress[ply] = nil
    g_bSawTurn[ply] = nil

    gB_IllegalSSJ[ply] = nil
end)

-- Update Stats for reset
local function UpdateStats(ply)
    local velocity = ply:GetVelocity()
    velocity[3] = 0
    local origin = ply:GetPos()

    g_fRawGain[ply] = 0.0
    g_iStrafeTick[ply] = 0
    g_iSyncedTick[ply] = 0
    g_iStrafeCount[ply] = 0
    g_fSpeedLoss[ply] = 0
	g_fTrajectory[ply] = 0
    g_fOldHeight[ply] = origin
	g_fTraveledDistance[ply] = Vector(0, 0, 0)

    g_fAvgDiffFromPerf[ply] = 0
    g_fAvgAbsoluteJss[ply] = 0
    g_jssThisTick[ply] = 0

    g_iCmdNum[ply] = 0
    g_bNoPress[ply] = false
    g_bOverlap[ply] = false
    g_bSawPress[ply] = false
    g_bSawTurn[ply] = false
end

local function GainColors(gain)
    if gain > 115 then
        return Color(255, 0, 0, 255)      -- GainReallyBad
    elseif gain > 110 then
        return Color(255, 69, 0, 255)     -- GainReallyBad
    elseif gain > 105 then
        return Color(255, 128, 0, 255)    -- GainBad
    elseif gain > 100 then
        return Color(39, 255, 0, 255)     -- GainGood
    elseif gain >= 90 then
        return Color(0, 255, 255)         -- GainReallyGood
    elseif gain >= 80 then
        return Color(39, 255, 0, 255)     -- GainGood
    elseif gain >= 70 then
        return Color(39, 255, 0, 255)    -- GainMeh
    elseif gain >= 60 then
        return Color(255, 128, 0, 255)    -- GainBad
    else
        return Color(255, 0, 0, 255)      -- GainReallyBad
    end
end

-- Sync Colors
local function GetSyncColor(sync)
    if sync == 0 then
        return Color(255, 255, 255)      -- White for 0 sync
    elseif sync >= 94 then
        return Color(0, 255, 255)        -- Cyan for high sync (94+)
    elseif sync <= 90 then
        return Color(200, 0, 0)          -- Red for low sync (90 and below)
    else
        return Color(255, 255, 255)      -- Default white (91-93)
    end
end

-- JSS Colors
local function GetJSSIndicator(jss)
    if jss >= 101 then
        return Color(0, 0, 255, 255), "✓"  -- 101 for high JSS
    elseif jss <= 70 then
        return Color(255, 0, 0, 255), "▼"  -- 70 for lower JSS
    else
        return Color(0, 255, 0, 255), "▲"
    end
end

if SERVER then
    util.AddNetworkString("SyncSSJSettings")
    util.AddNetworkString("SyncSSJFromServer")

    net.Receive("SyncSSJSettings", function(len, ply)
        local showSSJ = net.ReadBool()
        local showPre = net.ReadBool()

        local ssjData = ply:GetPData("SSJ_Settings", nil)
        local previousSettings = ssjData and util.JSONToTable(ssjData) or {true, true}
        
        previousSettings[1] = showSSJ
        
        ply:SetPData("SSJ_Settings", util.TableToJSON(previousSettings))

        ply:SetNWBool("bhop_showssj", showSSJ)
        ply:SetNWBool("bhop_showpre", showPre)
    end)

    hook.Add("PlayerInitialSpawn", "SyncSSJOnSpawn", function(ply)
        local ssjData = ply:GetPData("SSJ_Settings", nil)
        if ssjData then
            net.Start("SyncSSJFromServer")
            net.WriteString(ssjData)
            net.Send(ply)
        end
    end)
end

if CLIENT then
    CreateClientConVar("bhop_showssj", "1", true, false, "Toggle SSJ display in chat")
    CreateClientConVar("bhop_showpre", "1", true, false, "Toggle Prestrafe display in chat")

    local lastSSJ = GetConVar("bhop_showssj"):GetBool()
    local lastPre = GetConVar("bhop_showpre"):GetBool()

    net.Receive("SyncSSJFromServer", function()
        local ssjSettings = util.JSONToTable(net.ReadString()) or {}

        if ssjSettings[1] ~= nil then
            RunConsoleCommand("bhop_showssj", ssjSettings[1] and "1" or "0")
            lastSSJ = ssjSettings[1]
        end
    end)

    local function SyncSSJSettings()
        local newSSJ = GetConVar("bhop_showssj"):GetBool()
        local newPre = GetConVar("bhop_showpre"):GetBool()

        if newSSJ ~= lastSSJ or newPre ~= lastPre then
            lastSSJ, lastPre = newSSJ, newPre

            net.Start("SyncSSJSettings")
            net.WriteBool(newSSJ)
            net.WriteBool(newPre)
            net.SendToServer()
        end
    end

    cvars.AddChangeCallback("bhop_showssj", function() timer.Simple(0.05, SyncSSJSettings) end)
    cvars.AddChangeCallback("bhop_showpre", function() timer.Simple(0.05, SyncSSJSettings) end)
end

local ILLEGAL_STYLE_IDS = {
    ["TAS"] = true,
    ["Unreal"] = true,
    ["WTF"] = true,
    ["AS"] = true,
    ["Swift"] = true,
    ["SPEED"] = true,
    ["LG"] = true,
    ["Pre"] = true,
    ["MOON"] = true,
    ["Stamina"] = true,
    ["Segment"] = true
}

local function IsIllegalStyle(style)
    for name in pairs(ILLEGAL_STYLE_IDS) do
        local id = TIMER:GetStyleID(name)
        if style == id then
            return true
        end
    end
    return false
end

local function GetSSJSettings(ply)
    if not ply.SSJ then
        local ssj = ply:GetPData("SSJ_Settings", false)
        ply.SSJ = ssj and {["Settings"] = util.JSONToTable(ssj)} or {
            ["Settings"] = {
                true, true, false, false, true,
                false, false, false, false, false,
                false, false, false, true
            }
        }
    end
    return ply.SSJ["Settings"]
end

-- Print the stats
local function SSJ_PrintStats(ply, lastSpeed, jumpTimeDiff)
    if not IsValid(ply) then return end

    local coeffsum = g_iStrafeTick[ply] > 0 and (g_fRawGain[ply] / g_iStrafeTick[ply]) * 100 or 0
    local strafes = g_iStrafeCount[ply] or 0
    local strafeTicks = g_iStrafeTick[ply]
    local syncedTicks = g_iSyncedTick[ply]

    local sync = strafeTicks > 0 and mc(floor((syncedTicks / strafeTicks) * 100), 0, 100) or 0

    -- Distance & Efficiency
    local traveledDist = g_fTraveledDistance[ply]:Length2D()
    local trajectory = g_fTrajectory[ply]
    local distance = min(traveledDist, trajectory)

    local efficiency = (distance > 0 and trajectory > 0) and (coeffsum * distance) / trajectory or 0
    efficiency = floor(efficiency * 100 + 0.5) / 100

    -- Jump Sync Stats
    local avgDiff = g_fAvgDiffFromPerf[ply] or 0
    local avgAbsJSS = g_fAvgAbsoluteJss[ply] or 0
    local yawTick = g_iYawwingTick[ply] or 0
    local strafeTicks = g_iStrafeTick[ply] or 1

    local jss = avgDiff / strafeTicks
    local absjss = avgAbsJSS / strafeTicks
    local yawwing = (yawTick / strafeTicks) * 100

    -- Colors
    local ColorSSJ = ply.DynamicColor or Color(255, 255, 255)
    local colorgain = GainColors(coeffsum)
    local colorsync = GetSyncColor(sync)

    -- Stats Message
    local str = {ColorSSJ, color_white}

    local absVel = ply:GetAbsVelocity()
    local velocity = floor(absVel:Length2D())

    -- Height Check
    local originZ = floor(ply:GetPos()[3])
    local heightDiff = originZ - floor(g_fInitialHeight[ply])
    
    if heightDiff ~= 0 then gB_IllegalSSJ[ply] = true end

    local settings = GetSSJSettings(ply)
    local jumpCount = g_iJump[ply]

    if jumpCount == 1 then
        str[#str + 1] = "Prestrafe: "
        str[#str + 1] = ColorSSJ
        str[#str + 1] = tostring(velocity)
        str[#str + 1] = color_white
    elseif jumpCount >= 2 then
        str[#str + 1] = "J: "
        str[#str + 1] = ColorSSJ
        str[#str + 1] = tostring(jumpCount)
        str[#str + 1] = color_white

        str[#str + 1] = " | S: "
        str[#str + 1] = ColorSSJ
        str[#str + 1] = tostring(velocity)
        str[#str + 1] = color_white

        if settings[3] then
            str[#str + 1] = " | ΔS: "
            str[#str + 1] = ColorSSJ
            str[#str + 1] = tostring(g_speedDiff[ply])
            str[#str + 1] = color_white
        end

        if settings[6] then
            str[#str + 1] = " | Gn: "
            str[#str + 1] = colorgain
            str[#str + 1] = format("%.2f%%", coeffsum)
            str[#str + 1] = color_white
        end

        if settings[4] then
            str[#str + 1] = " | H Δ: "
            str[#str + 1] = ColorSSJ
            str[#str + 1] = format("%.2f", heightDiff)
            str[#str + 1] = color_white
        end

        if settings[7] then
            str[#str + 1] = " | Strfs: "
            str[#str + 1] = ColorSSJ
            str[#str + 1] = tostring(strafes)
            str[#str + 1] = color_white
        end

        if settings[9] then
            str[#str + 1] = " | Eff: "
            str[#str + 1] = ColorSSJ
            str[#str + 1] = format("%.2f", efficiency)
            str[#str + 1] = color_white
        end

        if settings[10] then
            str[#str + 1] = " | Snc: "
            str[#str + 1] = colorsync
            str[#str + 1] = format("%.2f%%", sync)
            str[#str + 1] = color_white
        end

        if settings[8] then
            local jssDisplay = floor(jss * 100)
            local absJssDisplay = floor(absjss)
            local jssColor, jssSuffix = jssDisplay >= 102 and Color(255, 0, 0) or GetJSSIndicator(jssDisplay)

            str[#str + 1] = " | JSS: "
            str[#str + 1] = jssColor
            str[#str + 1] = tostring(jssDisplay)
            str[#str + 1] = jssDisplay ~= 100 and (jssDisplay > 100 and " ↓" or " ↑") or " ✓"
            str[#str + 1] = color_white
        end

        if settings[11] then
            str[#str + 1] = " | Last Speed: "
            str[#str + 1] = ColorSSJ
            str[#str + 1] = tostring(floor(lastSpeed))
            str[#str + 1] = color_white
        end

        if settings[12] then
            str[#str + 1] = " | Yaw: "
            str[#str + 1] = ColorSSJ
            str[#str + 1] = tostring(floor(yawwing))
            str[#str + 1] = color_white
        end

        if settings[13] and jumpTimeDiff > 0 then
            str[#str + 1] = " | Time: "
            str[#str + 1] = ColorSSJ
            str[#str + 1] = format("%.2f", jumpTimeDiff)
            str[#str + 1] = color_white
        end
    end

    -- Message & Spectators
    local clients = {}
    clients[1] = ply

    local target = ply:GetObserverTarget()

    for _, v in ipairs(player.GetAll()) do
        local ssj = v.SSJ and v.SSJ["Settings"]
        if v.Spectating and ssj and ssj[5] and IsValid(target) and target == ply then
            clients[#clients + 1] = v
        end
    end

    for _, v in ipairs(clients) do
        local ssj = v.SSJ and v.SSJ["Settings"]
        local showSSJ = v:GetNWBool("bhop_showssj", true)
        local showPre = v:GetNWBool("bhop_showpre", true)

        if ssj and ssj[1] and showSSJ then
            -- "Prestrafe Only" (Setting 14) toggle
            if settings[14] and jumpCount == 1 then
                NETWORK:StartNetworkMessageTimer(v, "Print", {"Timer", str})
        
            -- Normal "All" mode
            elseif ssj[2] then
                if not showPre and jumpCount == 1 then
                    -- Skip Prestrafe when it's disabled in "All" mode
                else
                    NETWORK:StartNetworkMessageTimer(v, "Print", {"Timer", str})
                end

            -- Limited mode (Jump 1 + 6 only if Prestrafe shown)
            elseif showPre and (jumpCount == 1 or jumpCount == 6) then
                NETWORK:StartNetworkMessageTimer(v, "Print", {"Timer", str})

            -- Limited mode (Jump 6 only if Prestrafe disabled)
            elseif not showPre and jumpCount == 6 then
                NETWORK:StartNetworkMessageTimer(v, "Print", {"Timer", str})
            end
        end
    end

    -- SSJ HUD Update
    NETWORK:StartNetworkMessageSSJ(ply, "SSJ", jumpCount, coeffsum, velocity, strafes, efficiency, sync, lastSpeed or 0, g_speedDiff[ply])

    -- Illegal Check
    local illegal = false

    local style = TIMER:GetStyle(ply)
    if jumpCount == 1 and velocity > 290 then
        illegal = true
    elseif IsIllegalStyle(style) then
        illegal = true
    elseif ply:GetNWInt("inPractice", true) then
        illegal = true
    end

    gB_IllegalSSJ[ply] = illegal

    -- SSJ TOP Record
    if SSJTOP and jumpCount == 6 and not gB_IllegalSSJ[ply] then
        local steamID = ply:SteamID()
        local wasDucking = playerDuckStatus[steamID] or false
        local ssjType = wasDucking and "duck" or "normal"
        local jumpSpeed = floor(velocity)

        SSJTOP[steamID] = SSJTOP[steamID] or { duck = 0, normal = 0 }

        if jumpSpeed > SSJTOP[steamID][ssjType] then
            SSJTOP[steamID][ssjType] = jumpSpeed

            if SERVER then
                local ID = "ssjTop"
                local Data = { ply:Nick(), tostring(jumpSpeed), ssjType:upper(), "6th" }
                NETWORK:StartNetworkMessageTimer(nil, "Print", { ID, Lang:Get(ID, Data) })

                SaveSSJToMySQL(ply, ssjType, jumpSpeed)
            end
        end
    end
end

-- Player jump
local function Player_Jump(ply)
    if not g_iJump[ply] then
        g_iJump[ply] = 0
    end

    if not g_iStrafeTick[ply] then
        g_iStrafeTick[ply] = 0
    end

    -- Prevent jump tracking if no strafing happened yet
    if (g_iJump[ply] > 0 and g_iStrafeTick[ply] == 0) then return end

    local absVel = ply:GetAbsVelocity()
    local currentSpeed = floor(absVel:Length2D())
    local lastSpeed = g_prevSpeed[ply] or currentSpeed
    local jumpCount = g_iJump[ply]
    local currentTime = SysTime()

    -- Previous speed
    g_prevSpeed[ply] = currentSpeed

    -- Height only for first jump
    if jumpCount == 0 then
        g_fInitialHeight[ply] = floor(ply:GetPos()[3])
    end

    -- Speed difference
    g_speedDiff[ply] = currentSpeed - lastSpeed

    -- Increment jump count
    g_iJump[ply] = (ply.time ~= 0) and (jumpCount + 1) or TIMER:GetJumps(ply)

    -- Jump time difference
    local jumpTimeDiff = (g_fJumpTime[ply] and g_fJumpTime[ply] > 0) and (currentTime - g_fJumpTime[ply]) or 0
    g_fJumpTime[ply] = currentTime

    -- Notify spectators about jump count update immediately
    local specs = {ply}

    for _, v in ipairs(player.GetHumans()) do
        if v:GetObserverMode() ~= OBS_MODE_NONE and v:GetObserverTarget() == ply then
            NETWORK:StartNetworkMessageTimer(v, "JumpUpdate", {ply, jumpCount})
        end
    end

    -- Print stats & update stats
    SSJ_PrintStats(ply, lastSpeed, jumpTimeDiff)
    UpdateStats(ply)
end

local function OnPluginStart(ply, cmd)
    if not IsValid(ply) or not ply:Alive() then return end

    local buttons = cmd:GetButtons()
    local wasOnGround = ply:IsFlagSet(FL_ONGROUND)

    if wasOnGround and band(buttons, IN_JUMP) ~= 0 then
        g_iTicksOnGround[ply] = 0
        Player_Jump(ply)
    end
end
hook.Add("StartCommand", "OnPluginStart", OnPluginStart)

-- Movement
local function SSJ_GetStats(ply, cmd)
    if not IsValid(ply) or not ply:Alive() then return end
    if ply:GetMoveType() ~= MOVETYPE_WALK or (ply:IsFlagSet(FL_ONGROUND) and not cmd:KeyDown(IN_JUMP)) then return end

    local buttons = cmd:GetButtons()
    local velocity = ply:GetAbsVelocity() or zeroVec
    local lagged = ply:GetLaggedMovementValue()
    local yaw = cmd:GetViewAngles()[2]
    local style = TIMER:GetStyle(ply)
    velocity[3] = 0

    local tickrateMulti = g_fTickrate * lagged

    g_iStrafeTick[ply] = (g_iStrafeTick[ply] or 0) + 1

    -- movement distance
    g_fTraveledDistance[ply] = g_fTraveledDistance[ply] or zeroVec
    local x, y, z = g_fTraveledDistance[ply]:Unpack()
    x = x + (velocity[1] * tickrateMulti)
    y = y + (velocity[2] * tickrateMulti)
    g_fTraveledDistance[ply]:SetUnpacked(x, y, z)

    g_fTrajectory[ply] = (g_fTrajectory[ply] or 0) + (velocity:Length2D() * tickrateMulti)

    local buttons = cmd:GetButtons()
    local forwardPressed, backPressed = bit_band(buttons, IN_FORWARD) ~= 0, bit_band(buttons, IN_BACK) ~= 0
    local rightPressed, leftPressed = bit_band(buttons, IN_MOVERIGHT) ~= 0, bit_band(buttons, IN_MOVELEFT) ~= 0

    local viewAngles = cmd:GetViewAngles()
    local yawAngle = math_rad(viewAngles[2])
    local lookVector = Vector(math_cos(yawAngle), math_sin(yawAngle), 0)
    local sideVector = Vector(math_cos(yawAngle - math_rad(90)), math_sin(yawAngle - math_rad(90)), 0)

    local forwardInput, sideInput = 0, 0

    -- Styles
    if style == TIMER:GetStyleID("W") then
        forwardInput = forwardPressed and 3 or 0
    elseif style == TIMER:GetStyleID("SW") then
        forwardInput = (forwardPressed and 3 or 0) - (backPressed and 3 or 0)
    elseif style == TIMER:GetStyleID("HSW") then
        forwardInput = forwardPressed and 2 or 0
    elseif style == TIMER:GetStyleID("A") then
        forwardInput = 0
        sideInput = leftPressed and -3 or 0
    elseif style == TIMER:GetStyleID("D") then
        forwardInput = 0
        sideInput = rightPressed and 3 or 0
    elseif style == TIMER:GetStyleID("Backwards") then
        forwardInput = (forwardPressed and 3 or 0) - (backPressed and 3 or 0)
        sideInput = (rightPressed and 3 or 0) - (leftPressed and 3 or 0)

        local velAngle = velocity:Angle()[2]
        local viewAngle = cmd:GetViewAngles()[2]
        local diff = math.AngleDifference(viewAngle, velAngle)

        if math.abs(diff) < 100 then
            forwardInput = 0
            sideInput = 0
        end
    elseif style == TIMER:GetStyleID("Normal") or style == TIMER:GetStyleID("Unreal") or
           style == TIMER:GetStyleID("WTF") or style == TIMER:GetStyleID("Legit") or 
           style == TIMER:GetStyleID("Bonus") or style == TIMER:GetStyleID("Segment") or style == TIMER:GetStyleID("LG") or 
           style == TIMER:GetStyleID("HG") or style == TIMER:GetStyleID("MM") or 
           style == TIMER:GetStyleID("SPEED") or style == TIMER:GetStyleID("E") or 
           style == TIMER:GetStyleID("Stamina") or style == TIMER:GetStyleID("Prespeed") or 
           style == TIMER:GetStyleID("Swift") or style == TIMER:GetStyleID("AS") then
        forwardInput = (forwardPressed and 3 or 0) - (backPressed and 3 or 0)
        sideInput = (rightPressed and 3 or 0) - (leftPressed and 3 or 0)
    end

    local accelForward = lookVector * (forwardInput * 0.3)
    local accelSide = sideVector * (sideInput * 2)
    if accelForward:IsZero() and accelSide:IsZero() then return end

    local accel = accelForward + accelSide
    local dir = accel:GetNormalized()

    -- wish velocity
    local wishvel = accel * 250
    wishvel[3] = 0

    local wishspeed = wishvel:Length()
    if wishspeed > 250 then
        wishvel:Mul(250 / wishspeed)
    end

    -- gain coefficient
    local absVel = ply:GetAbsVelocity() or Vector(0, 0, 0)
    absVel[3] = 0
    local currentGain = absVel:Dot(wishvel:GetNormalized())

    if (wishspeed > 0) then
        -- JSS
        local lastYaw = g_fLastAngles[ply] or 0
        local yawDiff = normalizeAngle(yaw - lastYaw)
        if yawDiff ~= 0 then
            local perfJss = mdeg(matan(IDEAL_GAIN / velocity:Length2D()))
            local finalJss = mabs(yawDiff / perfJss)

            g_fAvgDiffFromPerf[ply] = (g_fAvgDiffFromPerf[ply] or 0) + finalJss
            g_fAvgAbsoluteJss[ply] = (g_fAvgAbsoluteJss[ply] or 0) + (100 - mabs((finalJss * 100) - 100))
            g_jssThisTick[ply] = finalJss
            g_fLastAngles[ply] = yaw
        end

        -- Yaw
        if band(buttons, IN_MOVELEFT) ~= 0 or band(buttons, IN_MOVERIGHT) ~= 0 then
            g_iYawwingTick[ply] = (g_iYawwingTick[ply] or 0) + 1
        end

        -- Gain 
        if currentGain < IDEAL_GAIN then
            local gaincoeff = (IDEAL_GAIN - mabs(currentGain)) / IDEAL_GAIN
            gaincoeff = floor(gaincoeff * 100 + 0.5) / 100

            g_iSyncedTick[ply] = (g_iSyncedTick[ply] or 0) + 1
            local rawGain = g_fRawGain[ply] or 0
            rawGain = rawGain + gaincoeff
            g_fRawGain[ply] = rawGain
        end

        -- last non-zero movement
        if velocity[1] ~= 0 or velocity[2] ~= 0 then
            g_fLastNonZeroMove[ply] = g_fLastNonZeroMove[ply] or {}
            g_fLastNonZeroMove[ply][FORWARD_MOVE] = velocity[1]
            g_fLastNonZeroMove[ply][SIDE_MOVE] = velocity[2]
        end
    end

    -- command count
    g_iCmdNum[ply] = (g_iCmdNum[ply] or 0) + 1
end

local function OnPlayerStartCmd(ply, cmd)
    if not IsValid(ply) or not ply:Alive() then return end

    -- to reduce table lookups
    local buttons = cmd:GetButtons()
    local absVel = ply:GetAbsVelocity()
    local speed = absVel:Length2D()

    local wasOnGround = ply:IsFlagSet(FL_ONGROUND)
    local buttonCache = g_iButtonCache[ply] or 0
    local jumpedThisFrame = band(buttons, IN_JUMP) ~= 0

    -- Strafe counting
    if not wasOnGround then
        if band(g_iButtonCache[ply] or 0, IN_FORWARD) == 0 and band(buttons, IN_FORWARD) > 0 then
            g_iStrafeCount[ply] = (g_iStrafeCount[ply] or 0) + 1
        end
        if band(g_iButtonCache[ply] or 0, IN_MOVELEFT) == 0 and band(buttons, IN_MOVELEFT) > 0 then
            g_iStrafeCount[ply] = (g_iStrafeCount[ply] or 0) + 1
        end
        if band(g_iButtonCache[ply] or 0, IN_BACK) == 0 and band(buttons, IN_BACK) > 0 then
            g_iStrafeCount[ply] = (g_iStrafeCount[ply] or 0) + 1
        end
        if band(g_iButtonCache[ply] or 0, IN_MOVERIGHT) == 0 and band(buttons, IN_MOVERIGHT) > 0 then
            g_iStrafeCount[ply] = (g_iStrafeCount[ply] or 0) + 1
        end
    end

    -- speed loss
    local oldSpeed = g_fOldVelocity[ply] or speed
    if oldSpeed > speed then
        g_fSpeedLoss[ply] = (g_fSpeedLoss[ply] or 0) + (oldSpeed - speed)
    end

    -- interactions
    if wasOnGround then
        local ticksOnGround = (g_iTicksOnGround[ply] or 0) + 1
        g_iTicksOnGround[ply] = ticksOnGround

        -- Reset stats after BHOP_FRAMES
        if ticksOnGround > BHOP_FRAMES then
            g_iJump[ply], g_iSyncedTick[ply], g_fRawGain[ply] = 0, 0, 0
            g_iStrafeTick[ply], g_iStrafeCount[ply], g_fTrajectory[ply] = 0, 0, 0
            g_fTraveledDistance[ply] = Vector(0, 0, 0)
            g_fAvgDiffFromPerf[ply], g_fAvgAbsoluteJss[ply], g_jssThisTick[ply] = 0, 0, 0
            g_iYawwingTick[ply], g_iCmdNum[ply] = 0, 0
            g_bNoPress[ply], g_bOverlap[ply], g_bSawPress[ply], g_bSawTurn[ply] = false, false, false, false
        end

        -- jump
        if jumpedThisFrame and g_iTicksOnGround[ply] == 1 then
           g_iTicksOnGround[ply] = 0
           SSJ_GetStats(ply, cmd)
        end
   else
        local movetype = ply:GetMoveType()
        if movetype ~= MOVETYPE_NONE and movetype ~= MOVETYPE_NOCLIP and movetype ~= MOVETYPE_LADDER and ply:WaterLevel() < 2 then
            SSJ_GetStats(ply, cmd)
        end

        g_bJumpedThisFrame[ply] = false
        g_iTicksOnGround[ply] = 0
    end

    -- button state & velocity for next frame
    g_iButtonCache[ply] = buttons
    g_fOldVelocity[ply] = speed
end
hook.Add("StartCommand", "OnPlayerStartCmd", OnPlayerStartCmd)

hook.Add("PlayerInitialSpawn", "OnClientPutInServer2", function(ply)
    local ssj = ply:GetPData("SSJ_Settings", false)
    if ssj then
        ply.SSJ = {["Settings"] = util.JSONToTable(ssj)}
    else
        ply.SSJ = {["Settings"] = {
            true, true, false, false, true, true, true, true, true, true, true, true, true, false
        }}
    end
end)