STAMINA_USE = {}
STAMINA_SET = {}

-- Constants
STAMINA_MAX = 100.0
STAMINA_COST_JUMP = 25.0
STAMINA_COST_FALL = 20.0
STAMINA_RECOVER_RATE = 19.0
REFERENCE_FRAMETIME = 1.0 / 70.0

-- Cache
DT_VELMODF, DT_STAM, MODF_ONLAND_DAMAGE = 0, 1, 0.5
MT_WALK, IN_JP = MOVETYPE_WALK, IN_JUMP
FN_FT, FN_ST, FN_P, FN_S = FrameTime, SysTime, math.pow, math.sqrt

function OnVelocityMod(ply)
    if not STAMINA_USE[ply] then return end
    ply:SetNWFloat("DT_VELMODF", MODF_ONLAND_DAMAGE)
end

function OnStaminaMove(ply, mv, cmd)
    local style = TIMER:GetStyle(ply)
    if style == TIMER:GetStyleID("Legit") or style == TIMER:GetStyleID("Stamina") then
        STAMINA_USE[ply] = true
    elseif STAMINA_USE[ply] then
        STAMINA_USE[ply] = false
    end

    if not STAMINA_USE[ply] then return end

    local flStamina = ply:GetNWFloat("DT_STAM", STAMINA_MAX)
    if flStamina > 0 then
        flStamina = math.max(0, flStamina - 1000.0 * FN_FT())
        ply:SetNWFloat("DT_STAM", flStamina)
    end

    local flVelModf = ply:GetNWFloat("DT_VELMODF", 1)
    if flVelModf < 1 then
        flVelModf = math.min(1.0, flVelModf + FN_FT() / 3.0)
        if flVelModf < 1.0 then
            local maxspeed = mv:GetMaxSpeed() * flVelModf
            mv:SetMaxSpeed(maxspeed)

            local f_speed, s_speed, u_speed = mv:GetForwardSpeed(), mv:GetSideSpeed(), mv:GetUpSpeed()
            local spd = f_speed * f_speed + s_speed * s_speed + u_speed * u_speed
            if spd > (maxspeed * maxspeed) then
                local ratio = maxspeed / FN_S(spd)
                mv:SetForwardSpeed(f_speed * ratio)
                mv:SetSideSpeed(s_speed * ratio)
                mv:SetUpSpeed(u_speed * ratio)
            end
        end
        ply:SetNWFloat("DT_VELMODF", flVelModf)
    end

    if ply:WaterLevel() > 1 then return end
    if ply:IsOnGround() then
        if cmd:KeyDown(IN_JP) and (not STAMINA_SET[ply] or FN_ST() - STAMINA_SET[ply] > 0.1) then
            ply:SetJumpPower((flStamina == 0 and 290 or 268.4))
            ply:SetNWFloat("DT_STAM", (STAMINA_COST_JUMP / STAMINA_RECOVER_RATE) * 1000.0)
            STAMINA_SET[ply] = FN_ST()
        elseif flStamina > 0 then
            local flRatio = FN_P((STAMINA_MAX - (flStamina / 1000.0) * STAMINA_RECOVER_RATE) / STAMINA_MAX, FN_FT() / REFERENCE_FRAMETIME)
            local vel = ply:GetBaseVelocity()

            vel[1] = vel[1] * flRatio
            vel[2] = vel[2] * flRatio

            mv:SetVelocity(vel)
        end
    end
end
hook.Add("SetupMove", "CSS_Stamina", OnStaminaMove)

if SERVER then
    hook.Add("OnPlayerHitGround", "CSS_VelMod", OnVelocityMod)

    function EnableStamina(ply, bool)
        STAMINA_USE[ply] = bool
    end

    hook.Add("PlayerSpawn", "ResetPlayerStamina", function(ply)
        ply:SetNWFloat("DT_STAM", STAMINA_MAX)
        STAMINA_USE[ply] = false
    end)
end

-- KZ NoSlide
local isKZMap = string.StartWith(string.lower(game.GetMap()), "kz_") or string.StartWith(string.lower(game.GetMap()), "bhop_kz")
hook.Add("OnPlayerHitGround", "StopPlayerSlide", function(ply, inWater, onFloater, speed)
    if isKZMap and not inWater and not onFloater and not ply:KeyDown(IN_JUMP) then
        local vel = ply:GetVelocity()

        ply:SetVelocity(Vector(-vel[1], -vel[2], 0))
    end
end)