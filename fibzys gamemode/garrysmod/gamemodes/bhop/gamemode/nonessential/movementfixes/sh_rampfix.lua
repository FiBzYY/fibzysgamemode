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
local HookAdd = hook.Add
local BOUNDARY_MIN = Vector(-16, -16, 0)
local BOUNDARY_MAX = Vector(16, 16, 62)

if SERVER then
    hook.Add("PlayerInitialSpawn", "FixSurf_SetupData", function(ply)
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

local function RampCorrection(player, moveData)
    if not IsValid(player) then return end
    if player:Team() == TEAM_SPECTATOR or player:Team() == TEAM_UNASSIGNED then return end
    if not player.prevSpeed then InitializePlayerState(player) end
    if player:OnGround() then InitializePlayerState(player) return end

    local baseVel = player:GetBaseVelocity()
    local totalVel = moveData:GetVelocity() + baseVel
    local speedSquared = totalVel:LengthSqr()

    if player.prevSpeed > speedSquared then
        local speedReduction = player.prevSpeed - speedSquared
        local lossPercent = (speedReduction / player.prevSpeed) * 100

        if lossPercent == 100 then InitializePlayerState(player) return end

        if lossPercent > 96 and lossPercent ~= player.prevLossPercent then
            local traceLengths = {5, 10, 20, 30, 45, 60, 75, 90}
            local isSurfaceInclined = false
            local detectedNormal = nil

            for _, length in ipairs(traceLengths) do
                local fwdTrace = util.TraceHull({
                    start = player:GetPos(),
                    endpos = player:GetPos() + (player:GetForward() * length),
                    mins = BOUNDARY_MIN,
                    maxs = BOUNDARY_MAX,
                    filter = player,
                    mask = MASK_PLAYERSOLID_BRUSHONLY + CONTENTS_DETAIL
                })

                local bwdTrace = util.TraceHull({
                    start = player:GetPos(),
                    endpos = player:GetPos() - (player:GetForward() * length),
                    mins = BOUNDARY_MIN,
                    maxs = BOUNDARY_MAX,
                    filter = player,
                    mask = MASK_PLAYERSOLID_BRUSHONLY + CONTENTS_DETAIL
                })

                local downTrace = util.TraceHull({
                    start = player:GetPos(),
                    endpos = player:GetPos() - Vector(0, 0, 100),
                    mins = BOUNDARY_MIN,
                    maxs = BOUNDARY_MAX,
                    filter = player,
                    mask = MASK_PLAYERSOLID_BRUSHONLY + CONTENTS_DETAIL
                })

                local leftTrace = util.TraceHull({
                    start = player:GetPos(),
                    endpos = player:GetPos() - (player:GetRight() * length),
                    mins = BOUNDARY_MIN,
                    maxs = BOUNDARY_MAX,
                    filter = player,
                    mask = MASK_PLAYERSOLID_BRUSHONLY + CONTENTS_DETAIL
                })

                local rightTrace = util.TraceHull({
                    start = player:GetPos(),
                    endpos = player:GetPos() + (player:GetRight() * length),
                    mins = BOUNDARY_MIN,
                    maxs = BOUNDARY_MAX,
                    filter = player,
                    mask = MASK_PLAYERSOLID_BRUSHONLY + CONTENTS_DETAIL
                })

                if fwdTrace.Hit then
                    detectedNormal = fwdTrace.HitNormal
                elseif bwdTrace.Hit then
                    detectedNormal = bwdTrace.HitNormal
                elseif downTrace.Hit then
                    detectedNormal = downTrace.HitNormal
                elseif leftTrace.Hit then
                    detectedNormal = leftTrace.HitNormal
                elseif rightTrace.Hit then
                    detectedNormal = rightTrace.HitNormal
                end

                if detectedNormal and detectedNormal[3] < 0.7 and detectedNormal[3] > 0.1 then
                    isSurfaceInclined = true
                    break
                end
            end

            if not isSurfaceInclined then InitializePlayerState(player) return end

            local lastVelSpeed = math.sqrt(player.prevSpeed)
            if lastVelSpeed < 0 or lastVelSpeed > 10000 then return end

            local fixedVelocity = ModifyVelocity(player.prevVelocity + baseVel, detectedNormal, 1.0)
            if moveData:GetVelocity()[3] > 0 then
                fixedVelocity = fixedVelocity * 1.02
            end

            moveData:SetVelocity(fixedVelocity)
            moveData:SetOrigin(moveData:GetOrigin() + Vector(0, 0, 1))
            moveData:SetMoveAngles(player.prevMoveAngles)

            player.prevLossPercent = lossPercent
            return
        end
    end

    player.prevSpeed = speedSquared
    player.prevVelocity = moveData:GetVelocity()
    player.prevMoveAngles = moveData:GetMoveAngles()
end
HookAdd("SetupMove", "RampCorrection", RampCorrection)