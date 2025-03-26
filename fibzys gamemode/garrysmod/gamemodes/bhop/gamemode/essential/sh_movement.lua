--[[

 _  _   __   _  _  ____  _  _  ____  __ _  ____    ____  _  _    ____  __  ____  ____  _  _ 
( \/ ) /  \ / )( \(  __)( \/ )(  __)(  ( \(_  _)  (  _ \( \/ )  (  __)(  )(  _ \(__  )( \/ )
/ \/ \(  O )\ \/ / ) _) / \/ \ ) _) /    /  )(     ) _ ( )  /    ) _)  )(  ) _ ( / _/  )  / 
\_)(_/ \__/  \__/ (____)\_)(_/(____)\_)__) (__)   (____/(__/    (__)  (__)(____/(____)(__/  !

]]--

-- Cache
local clamp, ft, ct, currentMap = math.Clamp, FrameTime, CurTime, game.GetMap()
local bn, ba, bo, math_floor = bit.bnot, bit.band, bit.bor, math.floor
local timer_Simple, Vector, hook_Add, Iv = timer.Simple, Vector, hook.Add, IsValid
local math_sin, math_cos, math_rad, bit_band = math.sin, math.cos, math.rad, bit.band
local LastBaseVelocity, duckspeed, unduckspeed = {}, 0.4, 0.2

-- Scroll Height
local scrollpower, normpower = 268.4, 290

-- CVars
CV_FLAGSMV = FCVAR_ARCHIVE + FCVAR_NOTIFY + FCVAR_REPLICATED

-- Settings
movementspeed = CreateConVar("bhop_settings_mv", "32.4", CV_FLAGSMV, "Change air movement speed", 0, 10000)
movementspeedunreal = CreateConVar("bhop_settings_mv_unreal", "49.2", CV_FLAGSMV, "Change air movement speed for unreal", 0, 10000)
movementcap = CreateConVar("bhop_settings_cap", "100", CV_FLAGSMV, "Change air movement speed cap", 0, 10000)
maxspeed = CreateConVar("bhop_settings_maxspeed", "250", CV_FLAGSMV, "Change max movement speed", 0, 100000)
jumppower = CreateConVar("bhop_settings_jumppower", "290", CV_FLAGSMV, "Change jump height", 0, 10000)
walkspeed = CreateConVar("bhop_settings_walkspeed", "250", CV_FLAGSMV, "Change walk speed", 0, 10000)
zonecap = CreateConVar("bhop_settings_zonecap", "290", CV_FLAGSMV, "Change zone cap speed", 0, 10000)

-- Client Cvars
CreateClientConVar("bhop_smoothnoclip", "0", true, true, "Toggle smooth noclipping on or off")
CreateClientConVar("bhop_footsteps", "all", true, true, "Control footstep sounds. Options: 'off', 'local', 'spectate', 'all'")

local noclipSpeedConVar = GetConVar("sv_noclipspeed")
local noclipAccelConVar = GetConVar("sv_noclipaccelerate")

-- Load the latest values
local StyleInfo = {
    mv = movementspeed:GetFloat(),
    cap = movementcap:GetFloat(),
    maxspeed = maxspeed:GetFloat()
}

-- Style Speeds
local function UpdateStyleInfo(client, style)
    if style == TIMER:GetStyleID("Unreal") or style == TIMER:GetStyleID("WTF") or style == TIMER:GetStyleID("Swift") then
        StyleInfo.mv = movementspeedunreal:GetFloat()
        StyleInfo.cap = movementcap:GetFloat()
    elseif style == TIMER:GetStyleID("L") then
        StyleInfo.mv = movementspeed:GetFloat()
        StyleInfo.cap = 100
    else
        StyleInfo.mv = movementspeed:GetFloat()
        StyleInfo.cap = movementcap:GetFloat()
    end
end

-- Air accelerate
local function TickVelocity(vel, dir)
    local d = vel:Dot(dir)

    if d < StyleInfo.mv then
        local current = StyleInfo.mv - d
        if current <= 0 then return vel end

        local wishvel = dir * StyleInfo.maxspeed
        wishvel[3] = 0

        local wishspeed = wishvel:Length()
        if wishspeed > StyleInfo.maxspeed then
            wishvel = wishvel * (StyleInfo.maxspeed / wishspeed)
            wishspeed = StyleInfo.maxspeed
        end

        local cappedcurrent = math.min(StyleInfo.cap * FrameTime() * wishspeed, current)
        vel = vel + (dir * cappedcurrent)
    end

    return vel
end

-- Predict velocity
local function PredictVelocity(pl, mv)
    local absVel = pl:GetAbsVelocity() or Vector(0, 0, 0)
    local moveAngles = mv:GetMoveAngles()
    local forwardSpeed, sideSpeed = mv:GetForwardSpeed(), mv:GetSideSpeed()

    local style = TIMER:GetStyle(pl)
    if style == TIMER:GetStyleID("W") then
        sideSpeed = 0
    end

    local dir = (moveAngles:Forward() * forwardSpeed) + (moveAngles:Right() * sideSpeed)
    dir[3] = 0

    if dir:IsZero() then return absVel end
    dir:Normalize()

    return TickVelocity(absVel, dir)
end

-- Set velocity
local function SetVelocity(ply, velocity, mv, dontUseTeleportEntity)
    if not velocity then return end

    -- Subtract last base velocity
    velocity = velocity - (LastBaseVelocity[ply] or Vector(0, 0, 0))

    if not mv or dontUseTeleportEntity then
        ply:RemoveEFlags(EFL_DIRTY_ABSVELOCITY)
        ply:SetSaveValue("m_vecAbsVelocity", velocity)
        ply:SetSaveValue("m_vecVelocity", velocity)
    else
        mv:SetVelocity(velocity)
    end
end

-- Gravity Style
local function GravityChange(ply, grav)
    local currentGravity = ply:GetGravity()

    if math_floor(currentGravity * 10) / 10 ~= grav then
        if currentGravity == 0 then
            ply:SetGravity(grav)
        elseif currentGravity == 1 then
            timer_Simple(0, function()
                if IsValid(ply) then
                    ply:SetGravity(grav)
                end
            end)
        end
    end
end

hook.Add("SetupMove", "JumpVelocity", function(ply, mv, cmd)
    if not IsValid(ply) or not ply:Alive() then return end

    local style = TIMER:GetStyle(ply)
    if style ~= TIMER:GetStyleID("SPEED") then return end

    if ply:IsOnGround() and mv:KeyDown(IN_JUMP) and not ply.JumpedThisFrame then
        ply.JumpedThisFrame = true
        if SERVER then
            IncrementJumpCounter(ply)
        end
    elseif not ply:IsOnGround() then
        ply.JumpedThisFrame = false
    end

    local onGround = ply:IsOnGround()
    if ply.JumpedThisFrame  and onGround then
        local velocity = ply:GetVelocity()
        local speed = math.sqrt(velocity[1]^2 + velocity[2]^2)

        if speed ~= 0 then
            local velocityMultiplier = 1.2
            local minVelocity = 750

            if velocityMultiplier ~= 0.0 then
                velocity[1] = velocity[1] * velocityMultiplier
                velocity[2] = velocity[2] * velocityMultiplier
            end

            if minVelocity ~= 0.0 and speed < minVelocity then
                local factor = (speed / minVelocity)
                velocity[1] = velocity[1] / factor
                velocity[2] = velocity[2] / factor
            end

            -- Since mv:SetVelocity we use ply:SetVelocity for speed updates
            ply:SetVelocity(velocity - ply:GetVelocity())
        end
    end
end)

-- Main Movement
function GM:SetupMove(client, data, cmd)
    if not Iv(client) or client:IsBot() or not client:Alive() then return end

    -- Movement Sidespeeds and Speed caps
    local velocity = data:GetVelocity()
    local velocity2d = velocity:Length2D()
    local style = TIMER:GetStyle(client)

    local sidespeed = 10000 -- 450
    local speedModifier = (client:OnGround() or client:GetMoveType() == MOVETYPE_NOCLIP) and sidespeed or 10000

    local buttons = data:GetButtons()
    local moveRight = bit.band(buttons, IN_MOVERIGHT) ~= 0
    local moveLeft = bit.band(buttons, IN_MOVELEFT) ~= 0
    local moveForward = bit.band(buttons, IN_FORWARD) ~= 0
    local moveBack = bit.band(buttons, IN_BACK) ~= 0

    data:SetSideSpeed((moveRight and speedModifier) or (moveLeft and -speedModifier) or 0)
    data:SetForwardSpeed((moveForward and speedModifier) or (moveBack and -speedModifier) or 0)

    -- Zone
    if client.InStartZone and not client:GetNWInt("inPractice", false) and style ~= TIMER:GetStyleID("SPEED") and style ~= TIMER:GetStyleID("Prespeed") then
        local speedcap = zonecap:GetFloat()

        if velocity2d > speedcap and not client.Teleporting then
            local diff = velocity2d - speedcap
            velocity[1] = velocity[1] > 0 and velocity[1] - diff or velocity[1] + diff
            velocity[2] = velocity[2] > 0 and velocity[2] - diff or velocity[2] + diff
            data:SetVelocity(velocity)
            return false
        end
    end

    -- Hud
    client.ctick = (client.ctick or 0) + 1
    if client.ctick >= 1 then
        client.current = velocity2d
        client.ctick = 0
    end

    -- Top Speed
    client.topspeed = math.max(client.topspeed or 0, velocity2d)

    -- Auto Hop
    local buttons = cmd:GetButtons()
    local onGround = client:IsOnGround()
    local style = TIMER:GetStyle(client)

    if (style ~= TIMER:GetStyleID("E") and style ~= TIMER:GetStyleID("Legit")) and cmd:KeyDown(IN_JUMP) then
        if client:WaterLevel() < 2 and client:GetMoveType() ~= MOVETYPE_LADDER then
            if onGround and buttons && IN_JUMP ~= 0 then
                data:SetOldButtons(buttons - IN_JUMP)
            end
        end
    end

    -- Crouch Boost
    local DisableCrouch = -1
    local isCrouching = client:Crouching()

    if isCrouching and onGround and cmd:KeyDown(IN_JUMP) then
        if client:GetDuckSpeed() ~= DisableCrouch then
            client:SetDuckSpeed(DisableCrouch)
            client:SetUnDuckSpeed(DisableCrouch)
        end
    else
        client:SetDuckSpeed(duckspeed)
        client:SetUnDuckSpeed(unduckspeed)
    end

    -- Air Movement
    if client:GetMoveType() ~= MOVETYPE_WALK or (client:IsFlagSet(FL_ONGROUND) and not data:KeyDown(IN_JUMP)) then return end

    local style = TIMER:GetStyle(client)
    UpdateStyleInfo(client, style)

    local buttons = cmd:GetButtons()
    local forwardPressed, backPressed = bit_band(buttons, IN_FORWARD) ~= 0, bit_band(buttons, IN_BACK) ~= 0
    local rightPressed, leftPressed = bit_band(buttons, IN_MOVERIGHT) ~= 0, bit_band(buttons, IN_MOVELEFT) ~= 0

    local viewAngles = cmd:GetViewAngles()
    local yawAngle = math_rad(viewAngles[2])
    local lookVector = Vector(math_cos(yawAngle), math_sin(yawAngle), 0)
    local sideVector = Vector(math_cos(yawAngle - math_rad(90)), math_sin(yawAngle - math_rad(90)), 0)

    local forwardInput, sideInput = 0, 0

    -- Gravity styles
    if SERVER then
        if style == TIMER:GetStyleID("LG") then
            GravityChange(client, 0.6)
        elseif style == TIMER:GetStyleID("HG") then
            GravityChange(client, 1.4)
        elseif style == TIMER:GetStyleID("MOON") then
            GravityChange(client, 0.1)
        end
    end

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
    elseif style == TIMER:GetStyleID("AS") then
        if client:GetMoveType() ~= MOVETYPE_WALK or (not client:IsFlagSet(FL_ONGROUND) and data:KeyDown(IN_JUMP)) then
            local moveX = cmd:GetMouseX()

            if moveX ~= 0 then
                local strafeDirection = moveX > 0 and 1 or -1
                sideInput = strafeDirection * 3
            end

            if CLIENT then
                local strafeDirection = moveX > 0 and 1 or (moveX < 0 and -1 or 0)

                if strafeDirection == 0 then
                    RunConsoleCommand("-moveleft")
                    RunConsoleCommand("-moveright")
                else
                    if strafeDirection == -1 then
                        RunConsoleCommand("-moveright")
                        RunConsoleCommand("+moveleft")
                    elseif strafeDirection == 1 then
                        RunConsoleCommand("-moveleft")
                        RunConsoleCommand("+moveright")
                    end
                end
            end
        else
            if CLIENT then
                RunConsoleCommand("-moveleft")
                RunConsoleCommand("-moveright")
            end
        end
    elseif style == TIMER:GetStyleID("Normal") or style == TIMER:GetStyleID("Unreal") or
           style == TIMER:GetStyleID("WTF") or style == TIMER:GetStyleID("Legit") or 
           style == TIMER:GetStyleID("Bonus") or style == TIMER:GetStyleID("Segment") or style == TIMER:GetStyleID("LG") or 
           style == TIMER:GetStyleID("HG") or style == TIMER:GetStyleID("MM") or 
           style == TIMER:GetStyleID("SPEED") or style == TIMER:GetStyleID("E") or 
           style == TIMER:GetStyleID("Stamina") or style == TIMER:GetStyleID("Prespeed") or 
           style == TIMER:GetStyleID("Swift") then
        forwardInput = (forwardPressed and 3 or 0) - (backPressed and 3 or 0)
        sideInput = (rightPressed and 3 or 0) - (leftPressed and 3 or 0)
    end

    local accelForward = lookVector * (forwardInput * 0.3)
    local accelSide = sideVector * (sideInput * 2)

    if accelForward:IsZero() and accelSide:IsZero() then return end
    local dir = (accelForward + accelSide):GetNormalized()

    local newVelocity = TickVelocity(PredictVelocity(client, data), dir)
    local vel = data:GetVelocity()
    local base = client:GetBaseVelocity() or Vector(0, 0, 0)

	vel:Add(base)
	LastBaseVelocity[client] = base

    SetVelocity(client, newVelocity + client:GetBaseVelocity(), data, false)

    -- Sync Stats
    if SERVER and TIMER and TIMER.SyncMonitored and TIMER.SyncAngles and TIMER.SyncTick and 
        TIMER.SyncA and TIMER.SyncB and TIMER.SyncMonitored[client] and TIMER.SyncAngles[client] and 
        not client:IsFlagSet(FL_ONGROUND + FL_INWATER) and client:GetMoveType() ~= MOVETYPE_LADDER then

        local ang = cmd:GetViewAngles()
        local diff = normalizeAngle(ang[2] - TIMER.SyncAngles[client])
        local lastkey = client.lastkey or 0.2
        local getsidespeed = data:GetSideSpeed()

        local syncTick = TIMER.SyncTick[client] or 0
        local syncA = TIMER.SyncA[client] or 0
        local syncB = TIMER.SyncB[client] or 0

        if diff > 0 then
            syncTick = syncTick + 1
            if cmd:KeyDown(IN_MOVELEFT) and not cmd:KeyDown(IN_MOVERIGHT) then
                syncA = syncA + 1
            end
            if getsidespeed < 0 then
                syncB = syncB + 1
            end
        elseif diff < 0 then
            syncTick = syncTick + 1
            if cmd:KeyDown(IN_MOVERIGHT) and not cmd:KeyDown(IN_MOVELEFT) then
                syncA = syncA + 1
            end
            if getsidespeed > 0 then
                syncB = syncB + 1
            end
        end

        TIMER.SyncTick[client] = syncTick
        TIMER.SyncA[client] = syncA
        TIMER.SyncB[client] = syncB
        TIMER.SyncAngles[client] = ang[2]
    end
end

CreateClientConVar("bhop_kzsidefix", "0", true, false, "Enable stamina style for no side on kz maps")

function IsKZMap()
    local map = game.GetMap():lower()
    return string.sub(map, 1, 3) == "kz_"
end

hook.Add("SetupMove", "Stamina", function(client, data, cmd)
    if not IsValid(client) or not client:Alive() then return end

    local style = TIMER:GetStyle(client)
    local onGround = client:IsOnGround()
    local velocity = data:GetVelocity()
    local velocity2d = velocity:Length2D()
    local c = CurTime()

    local enableStamina = style == TIMER:GetStyleID("L") or 
    style == TIMER:GetStyleID("Stamina") or IsKZMap()

    if enableStamina and onGround and not client:IsBot() then
        if client.AirStam then
            data:SetVelocity(velocity)
            if client.AirStam == 4 then
                client.Gtime = c
            end
            client.AirStam = client.AirStam - 1
            if client.AirStam < 0 then
                client.AirStam = nil
            end
        end

        if client.Gtime then
            if client.Gtime == c then
                client.Gset = 0
            elseif client.Gset then
                if client.Gset < 4 then
                    client.Gset = client.Gset + 1
                    return
                end
                local dt = c - client.Gtime
                if dt < 1 then
                    local p = (1 - dt) / 16
                    data:SetVelocity(velocity - (p * velocity))
                else
                    client.Gtime = nil
                    client.Gset = nil
                end
            end
        end
    end

    if enableStamina and not onGround then
        if not client.AirStam or client.AirStam < 4 then 
            client.AirStam = 4 
        end
        if client.Gset then 
            client.Gset = nil 
        end
    end
end)

-- Footsteps
function GM:PlayerFootstep(ply, pos, foot, sound, volume, rf)
    if CLIENT then
        local footstepMode = GetConVar("bhop_footsteps"):GetString()
        local isLocalPlayer = ply == LocalPlayer()
        local isSpectatingObj = LocalPlayer():GetObserverTarget() == ply

        if footstepMode == "off" then
            return true
        elseif footstepMode == "local" and not isLocalPlayer then
            return true
        elseif footstepMode == "spectate" and not isLocalPlayer and not isSpectatingObj then
            return true
        end
    end

    return false
end

-- Hulls
function GM:FinishMove(ply, mv)
    if not IsValid(ply) then return end

    if ply:IsOnGround() and mv:KeyDown(IN_DUCK) then
        ply:SetNWBool("duckUntilOnGround", true)
    end

    if ply:Alive() then
        local eyeClearance = 12
        local offset = ply:GetCurrentViewOffset()

        local vHullMin = Vector(-16, -16, 0)
        local vHullMax = Vector(16, 16, 45)

        -- start position for direct manipulation
        local sx, sy, sz = mv:GetOrigin():Unpack()
        sz = sz + vHullMax[3]

        -- end position
        local ex, ey, ez = sx, sy, sz
        ez = ez + eyeClearance - vHullMax[3]
        ez = ez + (FullyDucked(ply) and VEC_DUCK_VIEW[3] or VEC_VIEW[3])

        -- hull bounds
        vHullMax[3] = 0
        local fudge = Vector(1, 1, 0)
        vHullMin = vHullMin + fudge
        vHullMax = vHullMax - fudge

        -- Trace Hull
        local trace = util.TraceHull({
            start = Vector(sx, sy, sz),
            endpos = Vector(ex, ey, ez),
            mins = vHullMin,
            maxs = vHullMax,
            mask = MASK_PLAYERSOLID,
            collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT,
            filter = ply
        })

        -- If player is obstructed
        if trace.Fraction < 1 then
            local est = sz + trace.Fraction * (ez - sz) - mv:GetOrigin()[3] - eyeClearance

            if NotDucked(ply) then
                offset[3] = est
            else
                offset[3] = math.min(est, offset[3])
            end

            ply:SetCurrentViewOffset(offset)
        else
            if NotDucked(ply) then
                ply:SetCurrentViewOffset(VEC_VIEW)
            elseif ply:GetNWBool("duckUntilOnGround", false) then
                local hullSizeNormal = VEC_HULL_MAX - VEC_HULL_MIN
                local hullSizeCrouch = VEC_DUCK_HULL_MAX - VEC_DUCK_HULL_MIN

                local lowerClearance = hullSizeNormal - hullSizeCrouch
                local duckEyeHeight = VEC_VIEW - lowerClearance

                ply:SetViewOffsetDucked(duckEyeHeight)
            elseif FullyDucked(ply) then
                ply:SetCurrentViewOffset(VEC_DUCK_VIEW)
            end
        end
    end
end

-- Hit Ground
function GM:OnPlayerHitGround(client, isWater, onFloater, Speed)
    local style = TIMER:GetStyle(client)

    if style == TIMER:GetStyleID("L") or style == TIMER:GetStyleID("E") or style == TIMER:GetStyleID("Stamina") then 
        client:SetJumpPower(scrollpower)
        timer.Simple(0.333333333, function() 
            if not IsValid(client) or not client.SetJumpPower or not normpower then return end 
            client:SetJumpPower(normpower) 
        end)
    end
end

function GM:Move(ply, mv)
    if not IsValid(ply) or not ply:Alive() then return end

    -- Noclip
    if ply:GetMoveType() == MOVETYPE_NOCLIP then
        local smoothnoclip = ply:GetInfoNum("bhop_smoothnoclip", 0) == 1
        if smoothnoclip then
            local deltaTime = FrameTime()
            local speedValue = 10
            local accelValue = noclipAccelConVar:GetFloat()

            if mv:KeyDown(IN_SPEED) then
                speedValue = speedValue * 1.5
            end

            local moveAngles = mv:GetMoveAngles()
            local acceleration = (moveAngles:Forward() * mv:GetForwardSpeed()) + (moveAngles:Right() * mv:GetSideSpeed()) + (moveAngles:Up() * mv:GetUpSpeed())

            if mv:GetForwardSpeed() == 0 and mv:GetSideSpeed() == 0 and mv:GetUpSpeed() == 0 then
                mv:SetVelocity(Vector(0, 0, 0))
            else
                local accelSpeed = math.min(acceleration:Length(), ply:GetMaxSpeed())
                local accelDir = acceleration:GetNormalized()
                acceleration = accelDir * accelSpeed * speedValue

                local multiplier = 1
                local newVelocity = mv:GetVelocity() + acceleration * deltaTime * accelValue
                newVelocity = newVelocity * (0.90 - deltaTime * multiplier)

                mv:SetVelocity(newVelocity)
                mv:SetOrigin(mv:GetOrigin() + newVelocity * deltaTime)
            end

            return true
        end
    end

    -- Jump Counter
    if ply:IsOnGround() and mv:KeyDown(IN_JUMP) and not ply.JumpedThisFrame then
        ply.JumpedThisFrame = true
        if SERVER then
            IncrementJumpCounter(ply)
        end
    elseif not ply:IsOnGround() then
        ply.JumpedThisFrame = false
    end
end

-- Auto Strafer for CreateMove
--[[function GM:CreateMove(cmd)
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    local moveX = cmd:GetMouseX()
    local strafeDirection = 0

    if moveX ~= 0 then
        strafeDirection = moveX > 0 and 1 or -1
    end

    if strafeDirection == 0 then
        RunConsoleCommand("-moveleft")
        RunConsoleCommand("-moveright")
    end

    if strafeDirection == -1 then
        RunConsoleCommand("+moveleft")
        cmd:SetSideMove(-450)
    elseif strafeDirection == 1 then
        RunConsoleCommand("+moveright")
        cmd:SetSideMove(450)
    end
end--]]

-- No recoil
function GM:PreRegisterSWEP(swep, class)
    if not swep.Primary or not swep.Primary.Recoil then return end
    swep.Primary.Recoil = 0
end