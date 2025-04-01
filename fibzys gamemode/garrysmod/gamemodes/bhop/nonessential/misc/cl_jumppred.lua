local hook_Add = hook.Add
local JUMP_POWER = 290
local GRAVITY = 800
local PREDICTION_INTERVAL = 0.02
local BOX_SIZE = 32
local MAX_HORIZONTAL_DISTANCE = 64

CreateClientConVar("bhop_landing_prediction", "0", true, false, "Toggle landing prediction display.")

local function PredictLandingPosition()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local startPosition = ply:GetPos()
    local forwardDirection = ply:GetForward()
    local horizontalVelocity = forwardDirection * math.min(ply:GetVelocity():Length2D(), MAX_HORIZONTAL_DISTANCE / PREDICTION_INTERVAL)
    local verticalVelocity = JUMP_POWER
    local position = startPosition
    local landingPosition = nil

    for t = 0, 5, PREDICTION_INTERVAL do
        local horizontalStep = horizontalVelocity * PREDICTION_INTERVAL
        if position:Distance(startPosition + forwardDirection * MAX_HORIZONTAL_DISTANCE) > MAX_HORIZONTAL_DISTANCE then
            horizontalStep = forwardDirection * (MAX_HORIZONTAL_DISTANCE - position:Distance(startPosition))
        end
        position = position + horizontalStep

        position.z = position.z + verticalVelocity * PREDICTION_INTERVAL
        verticalVelocity = verticalVelocity - (GRAVITY * PREDICTION_INTERVAL)

        local trace = util.TraceLine({
            start = position,
            endpos = position - Vector(0, 0, 5),
            filter = ply,
            mask = MASK_PLAYERSOLID
        })

        if trace.Hit then
            landingPosition = trace.HitPos
            break
        end
    end

    return landingPosition
end

local function DrawLandingPrediction()
    if not GetConVar("bhop_landing_prediction"):GetBool() then return end

    local landingPosition = PredictLandingPosition()
    if not landingPosition then return end

    render.SetColorMaterial()
    render.DrawQuadEasy(landingPosition + Vector(0, 0, 1), Vector(0, 0, 1), BOX_SIZE, BOX_SIZE, Color(255, 0, 0, 150), 0)
end
hook_Add("PostDrawOpaqueRenderables", "DrawLandingPredictionBox", DrawLandingPrediction)