if SERVER then return end

CreateClientConVar("bhop_landing_prediction", "1", true, false, "Toggle landing prediction display.")

local GRAVITY = 800
local PREDICTION_TIME = 3
local TIMESTEP = 0.01
local JUMP_IMPULSE = 290

local mins = Vector(-16, -16, 0)
local maxs = Vector(16, 16, 64)

local landingModel = "models/hunter/plates/plate1x1.mdl" -- flat square
local landingProp = nil

-- Spawn prop once
local function CreateLandingProp()
    if IsValid(landingProp) then return end

    landingProp = ents.CreateClientProp()
    landingProp:SetModel(landingModel)
    landingProp:SetMaterial("models/wireframe") -- optional, can be wireframe or custom
    landingProp:SetColor(Color(255, 255, 0, 150))
    landingProp:SetRenderMode(RENDERMODE_TRANSCOLOR)
    landingProp:SetMoveType(MOVETYPE_NONE)
    landingProp:SetSolid(SOLID_NONE)
    landingProp:Spawn()
end

local function SimulateLanding(ply)
    local pos = ply:GetPos()
    local vel = ply:GetVelocity()

    if ply:OnGround() then
        vel.z = JUMP_IMPULSE
    end

    for t = 0, PREDICTION_TIME, TIMESTEP do
        pos = pos + vel * TIMESTEP
        vel.z = vel.z - GRAVITY * TIMESTEP

        local tr = util.TraceHull({
            start = pos,
            endpos = pos - Vector(0, 0, 2),
            mins = mins,
            maxs = maxs,
            filter = ply,
            mask = MASK_PLAYERSOLID
        })

        if tr.Hit then
            return tr.HitPos
        end
    end
end

hook.Add("Think", "LandingPrediction_Think", function()
    if not GetConVar("bhop_landing_prediction"):GetBool() then
        if IsValid(landingProp) then landingProp:SetNoDraw(true) end
        return
    end

    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    CreateLandingProp()

    local predictedPos = SimulateLanding(ply)
    if predictedPos and IsValid(landingProp) then
        landingProp:SetNoDraw(false)
        landingProp:SetPos(predictedPos + Vector(0, 0, 0.5))
        landingProp:SetAngles(Angle(0, 0, 0))
        landingProp:SetColor(Color(255, 255, 0, 150))
    end
end)
