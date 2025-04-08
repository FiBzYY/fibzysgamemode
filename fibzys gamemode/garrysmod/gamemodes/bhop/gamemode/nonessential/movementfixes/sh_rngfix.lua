RNGFix = {
    Name = "RNGFix",
    Author = "rio ported by FiBzY",
    Description = "Fixes physics bugs in movement game modes",
    Version = "2.2.9",
    URL = "",
}

-- Cache
local band, math_min, math_max = bit.band, math.min, math.max
local hook_Add, traceHull, Iv = hook.Add, util.TraceHull, IsValid
local CurT = CurTime
local math_sin, math_cos, math_rad, bit_band = math.sin, math.cos, math.rad, bit.band
local sl = string.lower

local cachedFactor = 0.01
local band, traceHull, tickInterval, Vector, Angle = bit.band, util.TraceHull, engine.TickInterval, Vector, Angle
local IN_JUMP, IN_DUCK, MASK_PLAYERSOLID_BRUSHONLY = IN_JUMP, IN_DUCK, MASK_PLAYERSOLID_BRUSHONLY
local FL_DUCKING, FL_ONGROUND, FL_BASEVELOCITY = FL_DUCKING, FL_ONGROUND, FL_BASEVELOCITY
local MOVETYPE_WALK, string, ents, math, bit, ipairs = MOVETYPE_WALK, string, ents, math, bit, ipairs
local EFL_DIRTY_ABSVELOCITY, FSOLID_NOT_SOLID = EFL_DIRTY_ABSVELOCITY, FSOLID_NOT_SOLID

local LastGroundEnt = {}
local LastTickPredicted = {}
local LastBaseVelocity = {}
local iTick = {}
local iFrameTime = {}
local iButtons = {}
local iOldButtons = {}
local PreCollisionVelocity  = {}

local TouchingTrigger = false
local iLastMapTeleportTick = {}
local MapTeleportedSequentialTicks = {}
local iLastCollisionTick = {}
local iLastLandTick = {}
local iLastGroundEnt = {}
local collisionPoint = {}
local collisionNormal = {}

-- Engine Constants (do not change)
local NON_JUMP_VELOCITY = 140
local MIN_STANDABLE_ZNRM = 0.7
local LAND_HEIGHT = 2
local DUCK_MIN_DUCKSPEED = 1.5

local UPHILL_LOSS = -1 -- Force a jump, AND negatively affect speed as if a collision occurred (fix RNG not in player's favor)
local UPHILL_DEFAULT = 0 -- Do nothing (retain RNG)
local UPHILL_NEUTRAL = 1 -- Force a jump (respecting NON_JUMP_VELOCITY) (fix RNG in player's favor)

-- Hulls
local unducked = Vector(16, 16, 62)
local ducked = Vector(16, 16, 45)
local playermins = Vector(-16, -16, 0)

-- Correct for GMod
local duckdelta = unducked[3] - ducked[3] -- 17 units simple height difference

local gravity = GetConVar("sv_gravity")
local maxVelocity = GetConVar("sv_maxvelocity")

RNGFixHudDetect = RNGFixHudDetect or {}

-- CVars
local isSurfMap = string.StartWith(sl(game.GetMap()), "surf_")
local CV_FLAGS = FCVAR_NOTIFY + FCVAR_REPLICATED
local rngfix_edgefix = CreateConVar("bhop_rngfix_edgefix", "1", CV_FLAGS, "Enable edgebug fix.", 0, 1)
local rngfix_downhill = CreateConVar("bhop_rngfix_downhill", "1", CV_FLAGS, "Enable downhill incline fix.", 0, 1)
local rngfix_uphill = CreateConVar("bhop_rngfix_uphill", "1", CV_FLAGS,"Enable uphill incline fix. Set to -1 to normalize effects not in the player's favor.", -1, 1)
local rngfix_useoldslopefixlogic = CreateConVar("bhop_rngfix_useoldslopefixlogic", "0", CV_FLAGS,"Old Slopefix had some logic errors that could cause double boosts.", 0, 1)
local rngfix_stairs = CreateConVar("bhop_rngfix_stairs", "0", CV_FLAGS, "Enable stair slide fix", 0, 1)
local rngfix_telehop = CreateConVar("bhop_rngfix_telehop", "1", CV_FLAGS, "Enable telehop fix.", 0, 1)
local rngfix_triggerjump = CreateConVar("bhop_rngfix_triggerjump", "0", CV_FLAGS, "Enable trigger jump fix. (not needed on gmod)", 0, 1)

if SERVER then
    if isSurfMap then rngfix_stairs:SetBool(true) end
end

-- Utils
local function TR_TraceHullFilter(startPos, endPos, mins, maxs, mask, filter)
    return traceHull({
        start = startPos,
        endpos = endPos,
        mins = mins,
        maxs = maxs,
        mask = mask,
        filter = filter
    })
end

local function TracePlayerBBoxForGround(origin, originBelow, mins, maxs, ply)
	-- See CGameMovement::TracePlayerBBoxForGround()
    local origMins, origMaxs = Vector(mins), Vector(maxs)
    local tempMins, tempMaxs = Vector(), Vector()
    local tr = nil

    -- -x -y
    tempMins:Set(origMins)
    tempMaxs:SetUnpacked(math_min(origMaxs[1], 0), math_min(origMaxs[2], 0), origMaxs[3])
    tr = TR_TraceHullFilter(origin, originBelow, tempMins, tempMaxs, MASK_PLAYERSOLID_BRUSHONLY, ply)
    if tr.Hit and tr.HitNormal[3] >= MIN_STANDABLE_ZNRM then
        return tr
    end

    -- +x +y
    tempMins:SetUnpacked(math_max(origMins[1], 0), math_max(origMins[2], 0), origMins[3])
    tempMaxs:Set(origMaxs)
    tr = TR_TraceHullFilter(origin, originBelow, tempMins, tempMaxs, MASK_PLAYERSOLID_BRUSHONLY, ply)
    if tr.Hit and tr.HitNormal[3] >= MIN_STANDABLE_ZNRM then
        return tr
    end

    -- -x +y
    tempMins:SetUnpacked(origMins[1], math_max(origMins[2], 0), origMins[3])
    tempMaxs:SetUnpacked(math_min(origMaxs[1], 0), origMaxs[2], origMaxs[3])
    tr = TR_TraceHullFilter(origin, originBelow, tempMins, tempMaxs, MASK_PLAYERSOLID_BRUSHONLY, ply)
    if tr.Hit and tr.HitNormal[3] >= MIN_STANDABLE_ZNRM then
        return tr
    end

    -- +x -y
    tempMins:SetUnpacked(math_max(origMins[1], 0), origMins[2], origMins[3])
    tempMaxs:SetUnpacked(origMaxs[1], math_min(origMaxs[2], 0), origMaxs[3])
    tr = TR_TraceHullFilter(origin, originBelow, tempMins, tempMaxs, MASK_PLAYERSOLID_BRUSHONLY, ply)
    if tr.Hit and tr.HitNormal[3] >= MIN_STANDABLE_ZNRM then
        return tr
    end

    return nil
end

local function ClipVelocity(vel, nrm)
    local backoff = vel:Dot(nrm)
    local out = Vector()
    out[1] = vel[1] - nrm[1] * backoff
    out[2] = vel[2] - nrm[2] * backoff
    out[3] = vel[3] - nrm[3] * backoff

	-- The adjust step only matters with overbounce which doesnt apply to walkable surfaces.
    return out
end

local function PreventCollision(ply, origin, collision, veltick, mv)
    -- Rewind part of a tick so at the end of this tick we will end up close to the ground without colliding with it.
    -- This effectively simulates a mid-tick jump (we lose part of a tick but it's a minuscule trade-off).
    -- This is also only an approximation of a partial tick rewind but it's good enough.
    local newOrigin = collision - veltick

    -- Add a small buffer to prevent floating point issues causing ground collision.
    newOrigin[3] = newOrigin[3] + 0.1

    -- Compute adjustment vector
    local adjustment = newOrigin - origin

    -- No longer colliding this tick, clear our prediction flag
    LastTickPredicted[ply] = 0
    mv:SetOrigin(newOrigin)
end

-- Old buttons auto hop compatibility
local function CanJump(ply)
    if not iButtons[ply] or not iOldButtons[ply] then return true end
    if (iButtons[ply] and IN_JUMP) ~= 0 then
        iOldButtons[ply] = iOldButtons[ply] - IN_JUMP
        return true
    end

    return false
end

-- Teleport ent
function TeleportEntity(ent, pos, ang, vel)
    local solid = ent:GetSolidFlags()
    ent:AddSolidFlags(FSOLID_NOT_SOLID)

    if ang then
        ent:SetAngles(ang)
        if ent:IsPlayer() then
            ent:SetEyeAngles(ang)
        end
    end

    if vel then
        local absVel = ent:GetInternalVariable("m_vecAbsVelocity")
        if absVel ~= vel then
            ent:RemoveEFlags(EFL_DIRTY_ABSVELOCITY)
            ent:SetSaveValue("m_vecAbsVelocity", vel)
        end
        
        local baseVelocity = ent:GetInternalVariable("m_vecBaseVelocity") or Vector(0, 0, 0)
        ent:SetSaveValue("m_vecBaseVelocity", baseVelocity)

        local parent = ent:GetMoveParent()
        if not Iv(parent) then
            ent:SetSaveValue("m_vecVelocity", vel)
        else
            local parentVel = parent:GetInternalVariable("m_vecAbsVelocity") or Vector(0, 0, 0)
            local new_vel = vel - parentVel

            local parentAngles = parent:GetAngles()
            new_vel:Rotate(-parentAngles)

            ent:SetSaveValue("m_vecVelocity", new_vel)
        end
    end

    if pos then
        ent:SetPos(pos)
        ent:AddEFlags(EFL_DIRTY_ABSTRANSFORM)
    end

    ent:SetSolidFlags(solid)
end

local function SetVelocity(ply, velocity, mv, dontUseTeleportEntity)
    if not velocity then return end

    -- Pull out base velocity from the desired true velocity
    -- Use the pre-tick base velocity because that is what influenced this tick's movement and the desired new velocity.
    velocity:Sub(LastBaseVelocity[ply] or Vector(0, 0, 0))

    if dontUseTeleportEntity and not Iv(ply:GetMoveParent()) then
        ply:RemoveEFlags(EFL_DIRTY_ABSVELOCITY)
        ply:SetSaveValue("m_vecAbsVelocity", velocity)
        ply:SetSaveValue("m_vecVelocity", velocity)
    else
        local baseVelocity = ply:GetBaseVelocity() or Vector(0, 0, 0)

        TeleportEntity(ply, nil, nil, velocity)

        -- TeleportEntity with non-null velocity wipes out base velocity, so restore it after.
        -- Since we didn't change position, nothing should change regarding influences on base velocity.
        ply:SetSaveValue("m_vecBaseVelocity", baseVelocity)

        if mv then
            mv:SetVelocity(velocity)
        end
    end
end

local function Duck(ply, origin, mins, maxs)
    local isDucking = ply:IsFlagSet(FL_DUCKING)
    local willDuck = isDucking
    local buttons = iButtons[ply]

    if band(buttons, IN_DUCK) ~= 0 and not isDucking then
        -- IsDuckCoolingDown always returns false we remove the check
        origin[3] = origin[3] + duckdelta
        willDuck = true
    elseif band(buttons, IN_DUCK) == 0 and isDucking then
        origin[3] = origin[3] - duckdelta

        local tr = TR_TraceHullFilter(origin, origin, playermins, unducked, MASK_PLAYERSOLID, ply)

        -- Cannot unduck in air, not enough room
        if tr.Hit then 
            origin[3] = origin[3] + duckdelta
        else 
            willDuck = false
        end
    end

    mins = playermins
    maxs = willDuck and ducked or unducked

    return origin
end

local function CheckVelocity(velocity)
    local maxvel = maxVelocity:GetFloat()

    velocity[1] = math_min(math_max(velocity[1], -maxvel), maxvel)
    velocity[2] = math_min(math_max(velocity[2], -maxvel), maxvel)
    velocity[3] = math_min(math_max(velocity[3], -maxvel), maxvel)

    return velocity
end

local function StartGravity(ply, velocity)
	local localGravity = ply:GetGravity()
	if localGravity == 0 then localGravity = 1 end

	local svGravity = gravity:GetFloat()

	local baseVelocity = ply:GetBaseVelocity()
	velocity[3] = velocity[3] + (baseVelocity[3] - localGravity * 600 * 0.5) * iFrameTime[ply] / .23

	return CheckVelocity(velocity)
end

local function FinishGravity(ply, velocity)
	local localGravity = ply:GetGravity()
	if localGravity == 0 then localGravity = 1 end

	local svGravity = gravity:GetFloat()
	velocity[3] = velocity[3] - localGravity * 800 * 0.5 * iFrameTime[ply]

	return CheckVelocity(velocity)
end

local function GetSurfaceJumpFactor(ply)
    local trace = util.TraceLine({
        start = ply:GetPos(),
        endpos = ply:GetPos() - Vector(0, 0, 8),
        filter = ply
    })

    if trace.Hit and trace.SurfaceProps then
        local surfaceData = util.GetSurfaceData(trace.SurfaceProps)
        if surfaceData and surfaceData.jumpFactor then
            return surfaceData.jumpFactor
        end
    end

    return 1
end

local function CheckJumpButton(ply, velocity)
	-- Skip dead and water checks since we already did them.
    -- We need to check for ground somewhere so stick it here.
    if not ply:IsFlagSet(FL_ONGROUND) then return velocity end
    if not CanJump(ply) then return velocity end

    local jumpPower = ply:GetJumpPower()
    local jumpFactor = GetSurfaceJumpFactor(ply)
    jumpPower = jumpPower * jumpFactor

	-- This conditional is why jumping while crouched jumps higher! Bad!
    if ply:IsFlagSet(FL_DUCKING) then
        velocity[3] = jumpPower
    else
        velocity[3] = velocity[3] + jumpPower
    end

    return FinishGravity(ply, velocity)
end

local maxVelocity, airAcceleration = 32.4, 10000
local function GetControlDirection(ply, mv)
    local forward, side = mv:GetForwardSpeed(), mv:GetSideSpeed()
    local viewAngles = mv:GetAngles()
    
    local forwardVec = viewAngles:Forward()
    local rightVec = viewAngles:Right()

    forwardVec[3], rightVec[3] = 0, 0
    forwardVec:Normalize()
    rightVec:Normalize()

    local controlDir = Vector(0, 0, 0)
    local keyDown = mv:GetButtons()

    if band(keyDown, IN_FORWARD) ~= 0 then controlDir:Add(forwardVec) end
    if band(keyDown, IN_BACK) ~= 0 then controlDir:Sub(forwardVec) end
    if band(keyDown, IN_MOVELEFT) ~= 0 then controlDir:Sub(rightVec) end
    if band(keyDown, IN_MOVERIGHT) ~= 0 then controlDir:Add(rightVec) end

    return controlDir
end

local function PredictVelocity(ply, mv)
    if not ply:Alive() or ply:IsOnGround() then return mv:GetVelocity() end

    local controlDir = GetControlDirection(ply, mv)
    if controlDir:IsZero() then return mv:GetVelocity() end

    controlDir:Normalize()
    local velocity = mv:GetVelocity()
    local verticalVelocity = velocity.z
    velocity.z = 0

    local currentSpeed = velocity:Dot(controlDir)
    if currentSpeed < maxVelocity then
        local addSpeed = maxVelocity - currentSpeed
        local accelSpeed = airAcceleration * engine.TickInterval() * ply:GetLaggedMovementValue() * maxVelocity

        if accelSpeed > addSpeed then
            accelSpeed = addSpeed
        end

        velocity:Add(controlDir * accelSpeed)
    end

    velocity.z = verticalVelocity
    return velocity
end

local function DoPreTickChecks(ply, mv, cmd)
    -- Recreate enough of CGameMovement::ProcessMovement to predict if fixes are needed.
    -- We only care about limited scenarios (less than waist-deep in water, MOVETYPE_WALK, air movement).

    if not ply:Alive() then return false end
    if ply:GetMoveType() ~= MOVETYPE_WALK then return false end
    if ply:WaterLevel() ~= 0 then return false end
    if ply:GetMoveType() == MOVETYPE_NOCLIP then return end

    -- If we are definitely staying on the ground this tick, don't predict it.
    LastGroundEnt[ply] = ply:GetGroundEntity()
    if Iv(LastGroundEnt[ply]) and not CanJump(ply) then return false end

    iButtons[ply] = mv:GetButtons()
    iOldButtons[ply] = mv:GetOldButtons()
    LastTickPredicted[ply] = iTick[ply]

    local origin = mv:GetOrigin()
    local mins, maxs = playermins, unducked
    local nextOrigin = Duck(ply, Vector(origin), mins, maxs)

    -- These replicate their CGameMovement equivalents.
    local vel = PredictVelocity(ply, mv)
    vel = StartGravity(ply, vel)

    -- Fix sliding
    vel = CheckJumpButton(ply, vel)

    -- Base velocity is not stored in MoveData
	local base = (bit.band(ply:GetFlags(), FL_BASEVELOCITY) != 0) and ply:GetBaseVelocity() or Vector(0, 0, 0)

    -- StartGravity dealt with Z base velocity.
    base[3] = 0
    vel:Add(base)

    LastBaseVelocity[ply] = base

    -- Store this for later in case we need to undo the effects of a collision.
    PreCollisionVelocity[ply] = vel

    -- This is where TryPlayerMove happens.
    -- We don't care about anything after TryPlayerMove either.
    local veltick = Vector(vel)
    veltick:Mul(iFrameTime[ply])

    nextOrigin:Add(veltick)

    -- Check if we will hit something this tick.
    local tr = TR_TraceHullFilter(origin, nextOrigin, mins, maxs, MASK_PLAYERSOLID, ply)
    if tr.Hit then
        local nrm, collision = tr.HitNormal, tr.HitPos

        -- Store this result for post-tick fixes.
        iLastCollisionTick[ply] = iTick[ply]
        collisionPoint[ply] = collision
        collisionNormal[ply] = nrm

        -- If we are moving up too fast, we can't land anyway so these fixes aren't needed.
		-- Landing also requires a walkable surface.
		-- This will give false negatives if the surface initially collided
		-- is too steep but the final one isn't (rare and unlikely to mat
        if nrm[3] < MIN_STANDABLE_ZNRM or vel[3] > NON_JUMP_VELOCITY then return end

        -- Slopefix --
        -- Check uphill incline fix first since it's more common and faster.
        if rngfix_uphill:GetInt() == UPHILL_NEUTRAL then
            -- Make sure it's not flat, and that we are actually going uphill (X/Y dot product < 0.0)
            if nrm[3] < 1.0 and (nrm[1] * vel[1] + nrm[2] * vel[2] < 0.0) then
                local shouldDoDownhillFixInstead = false

                if rngfix_downhill:GetBool() then
                	-- We also want to make sure this isn't a case where it's actually more beneficial to do the downhill fix.
                    local newVelocity = ClipVelocity(vel, nrm)

                    if newVelocity[1] * newVelocity[1] + newVelocity[2] * newVelocity[2] > vel[1] * vel[1] + vel[2] * vel[2] then
                        shouldDoDownhillFixInstead = true
                    end
                end

                if not shouldDoDownhillFixInstead then
                    RNGFixHudDetect[ply] = true

                    --This naturally prevents any edge bugs so we can skip the edge fix.
                    PreventCollision(ply, origin, collision, veltick, mv)
                    return
                end
            end
        end

        -- Edge Fix --
        if rngfix_edgefix:GetBool() then
            -- Estimate where we will be at the end of the tick after colliding.
            -- This assumes no further collisions happen in this tick.
            local fraction_left = 1 - tr.Fraction
            local tickEnd = collision

            if nrm[3] == 1.0 then
                -- If the ground is level, only Z velocity is affected.
                tickEnd[1] = collision[1] + veltick[1] * fraction_left
                tickEnd[2] = collision[2] + veltick[2] * fraction_left
                tickEnd[3] = collision[3]
            else
                local velocity2 = ClipVelocity(vel, nrm)
                if velocity2[3] > NON_JUMP_VELOCITY then
                    -- This would be an "edge bug" (slide without landing at the end of the tick)
                    return
                else
                    velocity2:Mul(iFrameTime[ply] * fraction_left) 
                    tickEnd:Add(velocity2)
                end
            end

        	-- Check if there's something close enough to land on below the player at the end of this tick.
            local tickEndBelow = Vector(tickEnd[1], tickEnd[2], tickEnd[3] - LAND_HEIGHT)
            local tr_edge = TR_TraceHullFilter(tickEnd, tickEndBelow, mins, maxs, MASK_PLAYERSOLID, ply)

            -- There's something there, can we land on it?
            if tr_edge.Hit then
            	-- Yes, it's not too steep.
                if tr_edge.HitNormal[3] >= MIN_STANDABLE_ZNRM then 
                    return 
                end
                -- Yes, the quadrant check finds ground that isn't too steep.
                if TracePlayerBBoxForGround(tickEnd, tickEndBelow, mins, maxs) then 
                    return 
                end
            end

            RNGFixHudDetect[ply] = true
            PreventCollision(ply, origin, collision, veltick, mv)
        end
    end
end

local function OnPlayerHitGround(ply, inWater, float, speed)
    if ply:GetMoveType() == MOVETYPE_NOCLIP then return end
    if inWater or float then return end

    if ply:GetGroundEntity() ~= NULL then
        iLastLandTick[ply] = iTick[ply] or 0
    end
end
hook.Add("OnPlayerHitGround", "RNGFIXGround", OnPlayerHitGround)

local function DoInclineCollisionFixes(ply, mv, nrm)
    if not rngfix_downhill:GetBool() and rngfix_uphill:GetInt() ~= UPHILL_LOSS then return false end
    if iTick[ply] ~= LastTickPredicted[ply] then return false end

	-- There's no point in checking for fix if we were moving up, unless we want to do an uphill collision
    if PreCollisionVelocity[ply][3] > 0 and rngfix_uphill:GetInt() ~= UPHILL_LOSS then return false end

	-- If a collision was predicted this tick (and wasn't prevented by another fix alrady), no fix is needed.
	-- It's possible we actually have to run the edge bug fix and an incline fix in the same tick.
	-- If using the old Slopefix logic, do the fix regardless of necessity just like Slopefix
	-- so we can be sure to trigger a double boost if applicable.
    if iLastCollisionTick[ply] == iTick[ply] and not rngfix_useoldslopefixlogic:GetBool() then return false end

	-- Make sure the ground is not level, otherwise a collision would do nothing important anyway.
    if nrm[3] == 1.0 then return false end

	-- This velocity includes changes from player input this tick as well as
	-- the half tick of gravity applied before collision would occur.
    local velocity = Vector(PreCollisionVelocity[ply][1], PreCollisionVelocity[ply][2], PreCollisionVelocity[ply][3])

    if rngfix_useoldslopefixlogic:GetBool() then
		-- The old slopefix did not consider basevelocity when calculating deflected velocity
        VectorSubtract(velocity, LastBaseVelocity[ply], velocity)
    end

    local dot = velocity[1] * nrm[1] + velocity[2] * nrm[2]
    if dot >= 0 and not rngfix_downhill:GetBool() then
        -- If going downhill, only adjust velocity if the downhill incline fix is on.
        return false
    end

    local newVelocity = ClipVelocity(velocity, nrm)
    local downhillFixIsBeneficial = false

    if newVelocity[1] * newVelocity[1] + newVelocity[2] * newVelocity[2] > velocity[1] * velocity[1] + velocity[2] * velocity[2] then
        downhillFixIsBeneficial = true
        RNGFixHudDetect[ply] = true
    end

    if dot < 0 then
        if not ((downhillFixIsBeneficial and rngfix_downhill:GetBool()) or rngfix_uphill:GetInt() == UPHILL_LOSS) then
            -- If going uphill, only adjust velocity if uphill incline fix is set to loss mode
		    -- OR if this is actually a case where the downhill incline fix is better.
            return false
        end
    end

	-- Make sure Z velocity is zero since we are on the ground.
    newVelocity[3] = 0.0

	-- Since we are on the ground, we also don't need to FinishGravity().
    if rngfix_useoldslopefixlogic:GetBool() then
		-- The old slopefix immediately moves basevelocity into local velocity to keep it from getting cleared.
		-- This results in double boosts as the player is likely still being influenced by the source of the basevelocity.
        if ply:IsFlagSet(FL_BASEVELOCITY) then
            local baseVelocity = ply:GetBaseVelocity()
            VectorAdd(newVelocity, baseVelocity, newVelocity)
        end

        if mv then
            mv:SetVelocity(newVelocity)
        else
            ply:SetVelocity(newVelocity - ply:GetVelocity())
        end

        TeleportEntity(ply, nil, nil, newVelocity)
    else
        SetVelocity(ply, newVelocity, mv)
    end

    return true
end

-- OnEndTouch might not be needed
local function PrepareTPs()
    for _, ent in pairs(ents.FindByClass("trigger_teleport")) do
        ent:Fire("AddOutput", "OnStartTouch !activator:teleported:0:0:-1")
    end
end
hook_Add("InitPostEntity", "PrepareTPs", PrepareTPs)

local function OnPlayerTeleported(ent, input, activator, caller)
    if not Iv(activator) or not activator:IsPlayer() then return end
    if input ~= "teleported" then return end

    if (iLastMapTeleportTick[activator] == (iTick[activator] or 0) - 1) then
        MapTeleportedSequentialTicks[activator] = true
    else
        MapTeleportedSequentialTicks[activator] = false
    end

    iLastMapTeleportTick[activator] = iTick[activator] or 0
end
hook.Add("AcceptInput", "OnPlayerTeleported_AcceptInput", OnPlayerTeleported)

local function DoTelehopFix(ply, mv)
    if not rngfix_telehop:GetBool() then return false end

    if iLastMapTeleportTick[ply] ~= iTick[ply] then return false end
    if LastTickPredicted[ply] ~= iTick[ply] then return false end

	-- If the player was teleported two ticks in a row, don't do this fix because the player likely just passed
	-- through a speed-stopping teleport hub, and the map really did want to stop the player this way.
    if MapTeleportedSequentialTicks[ply] then return false end

	-- Check if we either collided this tick OR landed during this tick.
	-- Note that we could have landed this tick, lost Z velocity, then gotten teleported, making us no longer on the ground.
	-- This is why we need to remember if we landed mid-tick rather than just check ground state now.
    if not (iLastCollisionTick[ply] == iTick[ply] or iLastLandTick[ply] == iTick[ply]) then return false end

	-- At this point, ideally we should check if the teleport would have triggered "after" the collision (within the tick duration),
	-- and, if so, not restore speed, but properly doing that would involve completely duplicating TryPlayerMove but with
	-- multiple intermediate trigger checks which is probably a bad idea... better to just give people the benefit of the doubt sometimes.

	-- Restore the velocity we would have had if we didn't collide or land.
    local vel = PreCollisionVelocity[ply]

    -- Don't forget to add the second half-tick of gravity ourselves.
    vel = FinishGravity(ply, vel)

    local origin = ply:GetPos() 
    local mins = playermins
    local maxs = unducked

    local stuckTrace = TR_TraceHullFilter(origin, origin, mins, maxs, MASK_PLAYERSOLID_BRUSHONLY, ply)

	-- If we appear to be "stuck" after teleporting (likely because the teleport destination
	-- was exactly on the ground), set velocity directly to avoid side-effects of
	-- TeleportEntity that can cause the player to really get stuck in the ground.
	-- This might only be an issue in CSS, but do it on CSGO too just to be safe.
    local dontUseTeleportEntity = stuckTrace.Hit

    SetVelocity(ply, vel, mv, dontUseTeleportEntity)
end

local function DoStairsFix(ply, mv)
    if not rngfix_stairs:GetBool() then return false end

	-- This fix has undesirable side-effects on bhop. It is also very unlikely to help on bhop.
    if not isSurfMap then return false end

    if LastTickPredicted[ply] ~= iTick[ply] then return false end

	-- Let teleports take precedence (including teleports activated by the trigger jumping fix).
    if iLastMapTeleportTick[ply] == iTick[ply] then return false end

	-- If moving upward, the player would never be able to slide up with any current position.
    if PreCollisionVelocity[ply][3] > 0 then return false end

	-- Stair step faces don't necessarily have to be completely vertical, but, if they are not,
	-- sliding up them at high speed -- or even just walking up -- usually doesn't work.
	-- Plus, it's really unlikely that there are actual stairs shaped like that.
    if iLastCollisionTick[ply] ~= iTick[ply] then return false end
    if collisionNormal[ply][3] ~= 0 then return false end

    -- Do this first and stop if we are moving slowly (less than 1 unit per tick).
    local velocity_dir = Vector(PreCollisionVelocity[ply])
    velocity_dir[3] = 0
    if (velocity_dir:Length() * iFrameTime[ply] < 1) then 
        return false 
    end
    velocity_dir:Normalize()

    -- We seem to have collided with a "wall", now figure out if it's a stair step.
    -- Look for ground below us
    local mins, maxs = ply:GetCollisionBounds()
    local stepsize = ply:GetStepSize()
    local endPos = collisionPoint[ply] - Vector(0, 0, stepsize)

    local tr = TR_TraceHullFilter(collisionPoint[ply], endPos, mins, maxs, MASK_PLAYERSOLID_BRUSHONLY, ply)

    if not tr.Hit then return false end

    local nrm = tr.HitNormal

    -- Ground below is not walkable, not stairs
    if nrm[3] < MIN_STANDABLE_ZNRM then return false end

    -- Find triggers that we would trigger if we did touch the ground here.

    -- Now follow CGameMovement::StepMove behavior.
    local start = tr.HitPos
    endPos = Vector(start)
    endPos[3] = endPos[3] + stepsize

    tr = TR_TraceHullFilter(start, endPos, mins, maxs, MASK_PLAYERSOLID_BRUSHONLY, ply)

    if tr.Hit then endPos = tr.HitPos end

    -- Trace over (only 1 unit, just to find a stair step)
    start = endPos
    endPos = start + velocity_dir

    tr = TR_TraceHullFilter(start, endPos, mins, maxs, MASK_PLAYERSOLID_BRUSHONLY, ply)

    if tr.Hit then
		-- The plane we collided with is too tall to be a stair step (i.e. it's a wall, not stairs).
		-- Or possibly: the ceiling is too low to get on top of it.
        return false 
    end

    -- Trace downward
    start = Vector(endPos)
    endPos[3] = endPos[3] - stepsize

    tr = TR_TraceHullFilter(start, endPos, mins, maxs, MASK_PLAYERSOLID_BRUSHONLY, ply)

    if not tr.Hit then 
        return false -- Shouldn't happen
    end
    nrm = tr.HitNormal

    -- Ground atop "stair" is not walkable, not stairs
    if nrm[3] < MIN_STANDABLE_ZNRM then return false end

    endPos = tr.HitPos

    -- It looks like we actually collided with a stair step.
	-- Put the player just barely on top of the stair step we found and restore their speed
    if mv then
        mv:SetOrigin(endPos)
    else
        ply:SetNetworkOrigin(endPos)
    end

    TeleportEntity(ply, endpos, nil, nil)
    SetVelocity(ply, PreCollisionVelocity[ply], mv)

    return true
end

local function RNGFix_SetupMove(ply, mv, cmd)
    if not Iv(ply) then return end

    if not iTick[ply] then iTick[ply] = 0 end 

    DoTelehopFix(ply, mv)

    iTick[ply] = iTick[ply] + 1 or 12345

    local tickinterval = engine.TickInterval()
    local lagged = ply:GetLaggedMovementValue()

    iFrameTime[ply] = tickinterval * lagged

    MapTeleportedSequentialTicks[ply] = false
    RNGFixHudDetect[ply] = false

    if movement_rngfix:GetBool() and (rngfix_downhill:GetBool() or rngfix_uphill:GetBool() or rngfix_edgefix:GetBool() or rngfix_stairs:GetBool() or rngfix_telehop:GetBool()) then
        DoPreTickChecks(ply, mv, cmd)
    end
end
hook.Add("SetupMove", "RNGFix", RNGFix_SetupMove)

-- PostThink works a little better than a ProcessMovement post hook because we need to wait for ProcessImpacts (trigger activation)
local function PlayerPostThink(ply, mv)
    if not Iv(ply) or not ply:Alive() or ply:GetMoveType() ~= MOVETYPE_WALK or ply:WaterLevel() ~= 0 then return end

    local origin = mv:GetOrigin()
    local mins, maxs = ply:OBBMins(), ply:OBBMaxs()
    local originBelow = Vector(origin[1], origin[2], origin[3] - maxs[3])

    local tr = TR_TraceHullFilter(origin, originBelow, mins, maxs, MASK_PLAYERSOLID, ply)

    local wasOnGround = iLastGroundEnt[ply] or false
    local isOnGround = ply:IsOnGround()
    local landed = isOnGround and not wasOnGround
    iLastGroundEnt[ply] = isOnGround

    -- The stair sliding fix changes the outcome of this tick more significantly, so it doesn't really make sense to do incline fixes too.
    if DoStairsFix(ply, mv) then return end

    local frac = tr.Fraction
    local nrm = tr.HitNormal
    local landingPoint = tr.HitPos

	-- Get info about the ground we landed on (if we need to do landing fixes).
    if landed and not tr.Hit then
        landed = false
    end

    if landed and frac > 0 and SERVER and rngfix_triggerjump:GetBool() then
        local landingMins, landingMaxs = ply:GetCollisionBounds()

        if not ply:IsFlagSet(FL_ONGROUND) then
            -- This should never happen, since we know we are on the ground.
            landed = false
            iLastGroundEnt[ply] = false
        end
    end

    if landed then
		-- This is rare, and how the incline fix should behave isn't entirely clear because maybe we should
		-- collide with multiple faces at once in this case, but let's just get the ground we officially
		-- landed on and use that for our ground normal.

		-- landingMins and landingMaxs will contain the final values used to find the ground after returning.
        if nrm[3] < MIN_STANDABLE_ZNRM then
            local tr2 = TracePlayerBBoxForGround(origin, originBelow, mins, maxs, ply)
            if tr2 and tr2.Hit then
                nrm = tr2.HitNormal
            else
                -- This should also never happen.
                landed = false
            end
        end

        if landed and nrm[3] > MIN_STANDABLE_ZNRM and nrm[3] < 1 then
            DoInclineCollisionFixes(ply, mv, nrm)
        end
    end
end
hook_Add("FinishMove", "RNGFixPost", PlayerPostThink)