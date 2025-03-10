HUDData = HUDData or {}

local StrafeData = nil
local StrafeAxis, StrafeButtons, StrafeCounter, StrafeLast, StrafeDirection, StrafeStill = 0, nil, 0, nil, nil, 0
local StrafeAxis2, StrafeButtons2, StrafeCounter2, StrafeLast2, StrafeDirection2, StrafeStill2 = 0, nil, 0, nil, nil, 0
local StrafeAxis11, StrafeButtons11, StrafeCounter11, StrafeLast11, StrafeDirection11, StrafeStill11 = 0, nil, 0, nil, nil, 0
local MouseLeft, MouseRight = nil, nil

local fb, ik, lp, ts, abs, Iv = bit.band, input.IsKeyDown, LocalPlayer, TEAM_SPECTATOR, math.abs, IsValid
local LastUpdate = CurTime()

function ResetStrafes() StrafeCounter = 0 end
function SetSyncData(data) StrafeData = data end

local curTick = 0
hook.Add("SetupMove", "MonitorInput", function(ply, data)
    local ang = data:GetAngles().y

    if ply:IsFlagSet(FL_ONGROUND + FL_INWATER) or ply:GetMoveType() ~= MOVETYPE_WALK then
        return
    end

    if not ply.curTick then
        ply.curTick = 0
    end

    ply.curTick = ply.curTick + 1

    if ply.curTick - (LastUpdate or 0) < 100 then return end
    LastUpdate = ply.curTick

    local difference = math.NormalizeAngle(ang - (StrafeAxis or 0))
    local sideSpeed = data:GetSideSpeed()
    
    local oldButtons = data:GetOldButtons()
    local left = bit.band(oldButtons, IN_MOVELEFT) > 0
    local right = bit.band(oldButtons, IN_MOVERIGHT) > 0

    if difference ~= 0 and (left or right) and sideSpeed ~= 0 then
        if difference > 0 and left and not right and StrafeDirection ~= IN_MOVELEFT and sideSpeed < 0 then
            StrafeDirection = IN_MOVELEFT
            StrafeCounter = (StrafeCounter or 0) + 1
        elseif difference < 0 and right and not left and StrafeDirection ~= IN_MOVERIGHT and sideSpeed > 0 then
            StrafeDirection = IN_MOVERIGHT
            StrafeCounter = (StrafeCounter or 0) + 1
        end
    end

    StrafeAxis = ang
end)

local function MonitorInputCombined(ply, data)
    local buttons = data:GetButtons()
    local ang = data:GetAngles().y
    local sideSpeed = data:GetSideSpeed()

    if sideSpeed ~= 0 then
        local diff2 = math.NormalizeAngle(ang - StrafeAxis2)
        if diff2 > 0 then
            StrafeDirection2 = -1
            StrafeStill2 = 0
        elseif diff2 < 0 then
            StrafeDirection2 = 1
            StrafeStill2 = 0
        else
            if StrafeStill2 > 20 then
                StrafeDirection2 = nil
            end
            StrafeStill2 = StrafeStill2 + 1
        end
        StrafeAxis2 = ang

        local diff11 = math.NormalizeAngle(ang - StrafeAxis11)
        if diff11 > 0 then
            StrafeDirection11 = -1
            StrafeStill11 = 0
        elseif diff11 < 0 then
            StrafeDirection11 = 1
            StrafeStill11 = 0
        else
            if StrafeStill11 > 20 then
                StrafeDirection11 = nil
            end
            StrafeStill11 = StrafeStill11 + 1
        end
        StrafeAxis11 = ang
    end

    StrafeButtons2 = buttons
    StrafeButtons11 = buttons
end
hook.Add("SetupMove", "MonitorInputCombined", MonitorInputCombined)

local lastStrafeAxis = 0
local lastMouseLeft, lastMouseRight = nil, nil
local lastStrafeCounter, lastStrafeData = 0, 0
local hudHideConVar = GetConVar("bhop_hud_hide")

local function HUDPaintStrafes()
    local ply = lp()
    if not Iv(ply) or ply:Team() == ts then return end

    if hudHideConVar:GetInt() == 1 then return end

    local ang = ply:EyeAngles().y
    local yawDifference = math.NormalizeAngle(ang - lastStrafeAxis)
    lastStrafeAxis = ang

    MouseLeft, MouseRight = nil, nil

    local colchange = Color(142, 42, 42)
    if yawDifference > 0 then
        MouseLeft = colchange
    elseif yawDifference < 0 then
        MouseRight = colchange
    end

    local buttons = StrafeButtons2 or 0
    local buttons11 = StrafeButtons11 or 0

    local moveLeft = fb(buttons, IN_MOVELEFT) > 0
    local moveRight = fb(buttons, IN_MOVERIGHT) > 0
    local moveForward = fb(buttons11, IN_FORWARD) > 0
    local moveBackward = fb(buttons11, IN_BACK) > 0
    local jump = ik(KEY_SPACE) or fb(buttons11, IN_JUMP) > 0
    local duck = fb(buttons11, IN_DUCK) > 0

    local strafeCount = StrafeCounter or 0
    local strafeSync = StrafeData or 0

    HUDData[ply] = {
        pos = {20, 20},
        sync = strafeSync,
        strafes = strafeCount,
        l = MouseLeft ~= nil,
        r = MouseRight ~= nil,
        a = moveLeft,
        d = moveRight,
        w = moveForward,
        s = moveBackward,
        jump = jump,
        duck = duck,
    }
end
hook.Add("HUDPaint", "HUDPaintStrafes", HUDPaintStrafes)