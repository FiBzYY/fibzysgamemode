PreviousPos = PreviousPos or {}
PreviousVelocity = PreviousVelocity or {}
WasOnGround = WasOnGround or {}
Landed = Landed or {}
Jumped = Jumped or {}
GroundTrace = GroundTrace or {}
OnRamp = OnRamp or {}

local math_max = math.max
local math_min = math.min

local HullTrace, LineTrace = util.TraceHull, util.TraceLine
local Hook_Add = hook.Add
local BOUNDARY_MIN = Vector(-16, -16, 0)
local BOUNDARY_MAX = Vector(16, 16, 62)

if SERVER then
    Hook_Add("PlayerInitialSpawn", "FixSurf_SetupData", function(ply)
        if not IsValid(ply) then return end
        PreviousPos[ply] = Vector()
        PreviousVelocity[ply] = Vector()
        WasOnGround[ply] = true
        Landed[ply] = false
        Jumped[ply] = false
        GroundTrace[ply] = {}
        OnRamp[ply] = false
    end)
end

local function ModifyVelocity(vel, norm, bounceFactor)
    local reduction = vel:Dot(norm) * bounceFactor
    local adjustedVel = vel - (norm * reduction)

    return adjustedVel
end

local function InitializePlayerState(player)
    player.prevSpeed = 0
    player.prevVelocity = Vector(0, 0, 0)
    player.prevMoveAngles = Angle(0, 0, 0)
    player.prevLossPercent = 0
    player.traceRecords = {}
end

local function RampLossFix(ply, mv)
    if not IsValid(ply) or not ply:Alive() then return end
    if ply:Team() == TEAM_SPECTATOR or ply:GetMoveType() == MOVETYPE_NOCLIP then return end
    if not ply.prevSpeed then InitializePlayerState(ply) end
    if ply:OnGround() then InitializePlayerState(ply) return end

    local baseVel = ply:GetBaseVelocity()
    local vel = mv:GetVelocity() + baseVel
    local speedSqr = vel:LengthSqr()

    if ply.prevSpeed > speedSqr then
        local loss = ply.prevSpeed - speedSqr
        local lossPercent = (loss / ply.prevSpeed) * 100

        if lossPercent == 100 then InitializePlayerState(ply) return end
        if lossPercent > 96 and lossPercent ~= ply.prevLossPercent then
            local pos = ply:GetPos()
            local fwd, bwd, left, right = ply:GetForward(), -ply:GetForward(), -ply:GetRight(), ply:GetRight()
            local directions = {fwd, bwd, Vector(0, 0, -100), left, right}
            local foundNormal

            for _, dir in ipairs(directions) do
                local tr = util.TraceHull({
                    start = pos,
                    endpos = pos + dir * 30,
                    mins = BOUNDARY_MIN,
                    maxs = BOUNDARY_MAX,
                    filter = ply,
                    mask = MASK_PLAYERSOLID_BRUSHONLY + CONTENTS_DETAIL
                })

                if tr.Hit and tr.HitNormal.z < 0.7 and tr.HitNormal.z > 0.1 then
                    foundNormal = tr.HitNormal
                    break
                end
            end

            if not foundNormal then InitializePlayerState(ply) return end
            local corrected = ModifyVelocity(ply.prevVelocity + baseVel, foundNormal, 1.0)
            mv:SetVelocity(corrected)
            mv:SetOrigin(mv:GetOrigin() + Vector(0, 0, 1))
            mv:SetMoveAngles(ply.prevMoveAngles)
            ply.prevLossPercent = lossPercent
            return
        end
    end

    ply.prevSpeed = speedSqr
    ply.prevVelocity = mv:GetVelocity()
    ply.prevMoveAngles = mv:GetMoveAngles()
end
hook.Add("Move", "RampLossFix", RampLossFix)