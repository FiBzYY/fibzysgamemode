--[[

 ____  ____  ____   __   ____  ____  ____  ____   __   __  __ _  ____  ____ 
/ ___)(_  _)(  _ \ / _\ (  __)(  __)(_  _)(  _ \ / _\ (  )(  ( \(  __)(  _ \
\___ \  )(   )   //    \ ) _)  ) _)   )(   )   //    \ )( /    / ) _)  )   /
(____/ (__) (__\_)\_/\_/(__)  (____) (__) (__\_)\_/\_/(__)\_)__)(____)(__\_) !

]]--

local ct = CurTime
local strafetrainer = CreateClientConVar("bhop_strafetrainer", 0, true, false, "Display strafe trainer", 0, 1)
local strafetrainercss = CreateClientConVar("bhop_strafetrainercss", 0, true, false, "Display CS:S strafe trainer", 0, 1)
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

-- CS:S Strafe Trainer
concommand.Add("bhop_strafetrainercss_toggle", function()
    local currentValue = Strafetrainer.Enabled:GetBool()
    RunConsoleCommand("bhop_strafetrainercss", currentValue and "0" or "1")
end)

local function PerfStrafeAngle(speed)
    return math.deg(math.atan(movementSpeed / speed))
end

local function VisualisationString(percentage)
    local str = ""
    local maxSpaces = 38

    if (0.5 <= percentage) and (percentage <= 1.5) then
        local spacesBefore = math.Round((percentage - 0.5) * maxSpaces)
        local spacesAfter = maxSpaces - spacesBefore

        for i = 1, spacesBefore do
            str = str .. " "
        end

        str = str .. "|"

        for i = 1, spacesAfter do
            str = str .. " "
        end
    else
        str = (percentage < 1.0 and "|" .. string.rep(" ", maxSpaces) or string.rep(" ", maxSpaces) .. "|")
    end

    return str
end

local function GetTrainerColorCSS(convar)
    local colStr = GetConVar(convar):GetString()
    local r, g, b = string.match(colStr, "(%d+)%s+(%d+)%s+(%d+)")
    return Color(tonumber(r) or 255, tonumber(g) or 255, tonumber(b) or 255)
end

local function GetPercentageColor(percentage)
    local offset = math.abs(1 - percentage)

    if offset < 0.05 then
        return GetTrainerColorCSS("bhop_trainer_verygood")
    elseif offset < 0.1 then
        return GetTrainerColorCSS("bhop_trainer_good")
    elseif offset < 0.25 then
        return GetTrainerColorCSS("bhop_trainer_ok")
    elseif offset < 0.5 then
        return GetTrainerColorCSS("bhop_trainer_meh")
    else
        return GetTrainerColorCSS("bhop_trainer_bad")
    end
end

local color = Color(0, 0, 0, 0)
local stDisplay = {
    [1] = "",
    [2] = "────────^────────",
    [3] = "",
    [4] = "────────^────────"
}

local function StrafeTrainerCSS(ply, mv)
    if not strafetrainercss:GetBool() then return end
    if not IsFirstTimePredicted() then return end
    if ply:OnGround() or ply:GetMoveType() == MOVETYPE_NOCLIP or ply:GetMoveType() == MOVETYPE_LADDER then return end

    local currentAngle = mv:GetMoveAngles().y
    local currentVelocity = mv:GetVelocity():Length2D()
    if not lastAngle then lastAngle = currentAngle end

    local AngDiff = math.NormalizeAngle(lastAngle - currentAngle)
    local PerfAngle = PerfStrafeAngle(currentVelocity)
    local Percentage = abs(AngDiff / PerfAngle) or 0

    if ply.CmdNum == nil then
        ply.CmdNum = 0
    end

    ply.CmdNum = ply.CmdNum + 1

    if Percentage == 0 then
        if not fadeStart then
            fadeStart = ply.CmdNum
        elseif ply.CmdNum > fadeStart + FADE_OUT_DURATION then
            stDisplay[1] = "0%"
            lastUpdate = nil
        end
    else
        fadeStart = nil
    end

    if clientTickCount > TRAINER_TICK_INTERVAL then
        local AveragePercentage = 0.0
        for i = 1, TRAINER_TICK_INTERVAL do
            AveragePercentage = AveragePercentage + (clientPercentages[i] or 0)
            clientPercentages[i] = 0.0
        end

        AveragePercentage = AveragePercentage / TRAINER_TICK_INTERVAL
        stDisplay[1] = math.Round(AveragePercentage * 100) .. "%"

        stDisplay[3] = VisualisationString(AveragePercentage)
        color = GetPercentageColor(AveragePercentage)
        lastUpdate = ply.CmdNum
        clientTickCount = 1
    else
        clientPercentages[clientTickCount] = Percentage
        clientTickCount = clientTickCount + 1
    end

    lastAngle = currentAngle
end
hook_Add("SetupMove", "CSSStrafeTrainer", StrafeTrainerCSS)

-- HUD
local function DrawStrafeTrainerCSS()
    if not strafetrainercss:GetBool() then return end
    if not lastUpdate then return end

    if ct() > (lastUpdate + 3) then
        color = ColorAlpha(color, color.a - 1)
    end

    local x, y = ScrW() / 2, ScrH() / 1.85
    draw.SimpleText(stDisplay[1], "StrafeTrainerCSS", x, y, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(stDisplay[2], "StrafeTrainerCSS", x, y + 30, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(stDisplay[3], "StrafeTrainerCSS", x, y + 65, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(stDisplay[4], "StrafeTrainerCSS", x, y + 100, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end
hook_Add("HUDPaint", "CSSDrawTrainer", DrawStrafeTrainerCSS)