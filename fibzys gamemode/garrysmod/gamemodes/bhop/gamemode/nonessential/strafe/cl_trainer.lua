--[[

 ____  ____  ____   __   ____  ____  ____  ____   __   __  __ _  ____  ____ 
/ ___)(_  _)(  _ \ / _\ (  __)(  __)(_  _)(  _ \ / _\ (  )(  ( \(  __)(  _ \
\___ \  )(   )   //    \ ) _)  ) _)   )(   )   //    \ )( /    / ) _)  )   /
(____/ (__) (__\_)\_/\_/(__)  (____) (__) (__\_)\_/\_/(__)\_)__)(____)(__\_) !

]]--

local ct = CurTime
local strafetrainer = CreateClientConVar("bhop_strafetrainer", 0, true, false, "Controls strafe trainer", 0, 1)
local strafetrainer_interval = CreateClientConVar("bhop_strafetrainer_interval", 10, true, false, "Update rate in ticks", 1, 100)
local strafetrainer_ground = CreateClientConVar("bhop_strafetrainer_ground", 0, true, false, "Update on ground", 0, 1)
local tickRate = 1 / engine.TickInterval()
local interval = tickRate * (strafetrainer_interval:GetInt() / 100)
local ground = strafetrainer_ground:GetBool()
local movementSpeed = BHOP.Move.SpeedGain or 32.8
local lastAngle, clientTickCount, clientPercentages = Angle():Zero(), 1, {}
local TRAINER_TICK_INTERVAL = 10
local lastUpdate, fadeStart = nil, nil
local FADE_OUT_DURATION = 0.1

local deg, atan, abs, floor = math.deg, math.atan, math.abs, math.floor
local hook_Add, cvars_AddChangeCallback = hook.Add, cvars.AddChangeCallback

cvars_AddChangeCallback("bhop_strafetrainer_interval", function(_, _, new)
    interval = tickRate * (tonumber(new) / 100)
end)

cvars_AddChangeCallback("bhop_strafetrainer_ground", function(_, _, new)
    ground = (new == "1")
end)

local function GetPerfectAngle(vel)
    return vel > 0 and deg(atan(movementSpeed / vel)) or 0
end

local lastAngle = 0
local tick = 0
local rollingSum = 0
local rollingCount = 0
CurrentTrainValue = CurrentTrainValue or 0

local function StartCommand(client, cmd)
    if not strafetrainer:GetBool() then return end
    if client:IsOnGround() and not ground then return end
    if cmd:TickCount() == 0 then return end
    if client:GetMoveType() == MOVETYPE_NOCLIP then return end

    local vel = client:GetVelocity():Length2D()
    local ang = cmd:GetViewAngles().y
    local diff = math.NormalizeAngle(lastAngle - ang)
    local perfect = GetPerfectAngle(vel)
    local perc = (perfect > 0) and abs(diff) / perfect or 0

    rollingSum = rollingSum + perc
    rollingCount = rollingCount + 1

    if tick >= interval then
        CurrentTrainValue = math.Approach(CurrentTrainValue, rollingSum / rollingCount, 0.5)
        rollingSum, rollingCount, tick = 0, 0, 0
    else
        tick = tick + 1
    end

    lastAngle = ang
end
hook_Add("StartCommand", "BHOP_OptimizedStrafeTrainer", StartCommand)