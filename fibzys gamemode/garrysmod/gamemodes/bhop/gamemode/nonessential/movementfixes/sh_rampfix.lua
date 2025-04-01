local math_max = math.max
local math_min = math.min
local HullTrace = util.TraceHull
local Hook_Add = hook.Add

local BOUNDARY_MIN = Vector(-16, -16, 0)
local BOUNDARY_MAX = Vector(16, 16, 62)

local function ClipVelocity(vel, norm, bounceFactor)
    local reduction = vel:Dot(norm) * bounceFactor
    return vel - (norm * reduction)
end

local function InitializePlayerState(player)
    player.prevSpeed = 0
    player.prevVelocity = Vector(0, 0, 0)
    player.prevMoveAngles = Angle(0, 0, 0)
    player.prevLossPercent = 0
end

local function FindRampNormal(ply)
    local pos = ply:GetPos()
    local forward = ply:GetForward()
    local right = ply:GetRight()
    local directions = {
        forward * 30,
        -forward * 30,
        Vector(0, 0, -100),
        -right * 30,
        right * 30
    }

    for _, dir in ipairs(directions) do
        local tr = HullTrace({
            start = pos,
            endpos = pos + dir,
            mins = BOUNDARY_MIN,
            maxs = BOUNDARY_MAX,
            filter = ply,
            mask = MASK_PLAYERSOLID_BRUSHONLY + CONTENTS_DETAIL
        })

        if tr.Hit and tr.HitNormal[3] < 0.7 and tr.HitNormal[3] > 0.1 then
            return tr.HitNormal
        end
    end

    return nil
end

local function RampLossFix(ply, mv)
    if not IsValid(ply) or not ply:Alive() then return end
    if ply:Team() == TEAM_SPECTATOR or ply:GetMoveType() == MOVETYPE_NOCLIP then return end
    if not ply.prevSpeed then InitializePlayerState(ply) end
    if ply:IsOnGround() then InitializePlayerState(ply) return end

    local baseVel = ply:GetBaseVelocity()
    local vel = mv:GetVelocity() + baseVel
    local speedSqr = vel:LengthSqr()

    if ply.prevSpeed > speedSqr then
        local loss = ply.prevSpeed - speedSqr
        local lossPercent = (loss / ply.prevSpeed) * 100

        if lossPercent == 100 then InitializePlayerState(ply) return end
        if lossPercent > 96 and lossPercent ~= ply.prevLossPercent then
            local normal = FindRampNormal(ply)
            if not normal then InitializePlayerState(ply) return end

            local corrected = ClipVelocity(ply.prevVelocity + baseVel, normal, 1.0)
            corrected[1] = math.Clamp(corrected[1], -10000, 10000)
            corrected[2] = math.Clamp(corrected[2], -10000, 10000)
            corrected[3] = math.Clamp(corrected[3], -10000, 10000)

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
Hook_Add("Move", "RampLossFix", RampLossFix)