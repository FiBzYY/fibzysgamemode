local BoostCooldown = { 4, 5, 4.5, 8 }
local BoostMultiplier = { 1.8, 2.4, 3.0, 3.0 }
local IN_ATTACK2 = IN_ATTACK2
local Styles = { Unreal = 10, WTF = 13 }
local sys = SysTime

local function DoUnrealBoost(ply, nForce)
    if ply.InStartZone then
        ply.BoostTimer = nil
    end

    if ply.InStartZone then
        return
    end

    local currentTime = sys()
    if not ply.InStartZone and ply.BoostTimer and currentTime < ply.BoostTimer then return end

    local nType = 1
    local vel = ply:GetVelocity()

    local isForward, isBack, isJump, isMoveLeft, isMoveRight =
        ply:KeyDown(IN_FORWARD), ply:KeyDown(IN_BACK),
        ply:KeyDown(IN_JUMP), ply:KeyDown(IN_MOVELEFT),
        ply:KeyDown(IN_MOVERIGHT)

    if isForward and not (isBack or isMoveLeft or isMoveRight) then
        nType = 2
    elseif isJump and not (isForward or isBack or isMoveLeft or isMoveRight) then
        nType = 3
    elseif isBack and not (isForward or isMoveLeft or isMoveRight) then
        nType = 4
    end

    if nForce then
        nType = nForce
    end

    local nCooldown = BoostCooldown[nType]
    local Points = BoostMultiplier[nType]

    if nType == 1 then
        ply:SetVelocity(Vector(vel[1] * Points, vel[2] * Points, vel[3] * (Points * 1.5)))
    elseif nType == 2 then
        ply:SetVelocity(Vector(vel[1] * Points, vel[2] * Points, vel[3]))
    elseif nType == 3 then
        ply:SetVelocity(Vector(vel[1], vel[2], vel[3] * (vel[3] < 0 and -0.5 * Points or Points)))
    elseif nType == 4 then
        ply:SetVelocity(Vector(vel[1], vel[2], vel[3] * (vel[3] > 0 and -Points or Points)))
    end

    ply.BoostTimer = currentTime + nCooldown
end

hook.Add("StartCommand", "UnrealBoost_StartCommand", function(ply, cmd)
    local style = TIMER:GetStyle(ply)

    if cmd:KeyDown(IN_ATTACK2) then
        if style == TIMER:GetStyleID("Unreal") then
            DoUnrealBoost(ply)
        elseif style == TIMER:GetStyleID("WTF") then
            local st = sys()
            if st - (ply.lastUnrealBoost or 0) > 0.6 then
                local mult = 0.5
                ply:SetVelocity(Vector(ply:GetVelocity()[1] * mult, ply:GetVelocity()[2] * mult, ply:GetVelocity()[3] * (mult * 2)))
                ply.lastUnrealBoost = st
            end
        end
    end
end)