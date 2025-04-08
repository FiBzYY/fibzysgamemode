HUDData = HUDData or {}

local StrafeStates = {
    [1] = { axis = 0, direction = nil, still = 0, buttons = nil },
    [2] = { axis = 0, direction = nil, still = 0, buttons = nil },
}

local fb = bit.band
local ik = input.IsKeyDown
local lp = LocalPlayer
local ts = TEAM_SPECTATOR
local Iv = IsValid

local StrafeCounter, StrafeData = 0, 0
local StrafeDirection = nil
local LastUpdate = CurTime()

function ResetStrafes() StrafeCounter = 0 end
function SetSyncData(data) StrafeData = data end

local function handle_strafe(index, ang)
    local state = StrafeStates[index]
    local diff = math.NormalizeAngle(ang - state.axis)

    if diff > 0 then
        state.direction = -1
        state.still = 0
    elseif diff < 0 then
        state.direction = 1
        state.still = 0
    else
        if state.still > 20 then
            state.direction = nil
        end
        state.still = state.still + 1
    end

    state.axis = ang
end

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

hook.Add("SetupMove", "MonitorInputCombined", function(ply, data)
    local ang = data:GetAngles().y
    local sideSpeed = data:GetSideSpeed()
    local buttons = data:GetButtons()

    if sideSpeed ~= 0 then
        handle_strafe(1, ang)
        handle_strafe(2, ang)
    end

    StrafeStates[1].buttons = buttons
    StrafeStates[2].buttons = buttons
end)

local lastStrafeAxis = 0
local hudHideConVar = GetConVar("bhop_hud_hide")

hook.Add("HUDPaint", "HUDPaintStrafes", function()
    local localPly = lp()
    if not Iv(localPly) then return end

    local ply = (localPly:Team() == ts and localPly:GetObserverTarget()) or localPly
    if not Iv(ply) then return end

    if hudHideConVar:GetInt() == 1 then return end

    local ang = ply:EyeAngles()[2]
    local yawDiff = math.NormalizeAngle(ang - lastStrafeAxis)
    lastStrafeAxis = ang

    local mouseLeft = yawDiff > 0
    local mouseRight = yawDiff < 0

    local buttons1 = StrafeStates[1].buttons or 0
    local buttons2 = StrafeStates[2].buttons or 0

    HUDData[ply] = {
        pos = {20, 20},
        sync = StrafeData,
        strafes = StrafeCounter,
        l = mouseLeft,
        r = mouseRight,
        a = fb(buttons1, IN_MOVELEFT) > 0,
        d = fb(buttons1, IN_MOVERIGHT) > 0,
        w = fb(buttons2, IN_FORWARD) > 0,
        s = fb(buttons2, IN_BACK) > 0,
        jump = ik(KEY_SPACE) or fb(buttons2, IN_JUMP) > 0,
        duck = fb(buttons2, IN_DUCK) > 0,
    }
end)