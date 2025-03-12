ENT.Type = "anim"
ENT.Base = "base_anim"

local TEAM_SPECTATOR = TEAM_SPECTATOR
local Iv = IsValid

local ZONE = {
    MAIN_START = 0,
    MAIN_END = 1,
    BONUS_START = 2,
    BONUS_END = 3,
    RESTART = 10,
    VELOCITY = 11,
    SOILDAC = 120,
    SURFGRAVITY = 122,
    STEPSIZE = 123
}

if SERVER then
AddCSLuaFile()
   function ENT:Initialize()
        self:SetModel("models/hunter/blocks/cube025x025x025.mdl")
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_VPHYSICS)

        local BBOX = (self.max - self.min) / 2
        local difference = self.max - self.min

        self:SetSolid(SOLID_BBOX)
        self:PhysicsInitBox(-BBOX, BBOX)
        self:SetCollisionBoundsWS(self.min, self.max)

        local phys = self:GetPhysicsObject()
        if Iv(phys) then
            phys:EnableMotion(false)
        end

        self:SetNWInt("zonetype", self.zonetype)
    end
else
    local ViewZones = CreateClientConVar("bhop_showsoild_zones", "0", true, false, "Show or hide soild zones")
    local DAng = Angle(0, 0, 0)
    local DCol = Color(255, 0, 255)

    function ENT:Initialize()
        hook.Add("PostDrawTranslucentRenderables", "RenderSolid" .. self:EntIndex(), function()
            if Iv(self) and self.IsDrawing then
                self:DrawBox(self:GetCollisionBounds())
            end
        end)
    end

    function ENT:Draw()
    end

    function ENT:DrawBox(Min, Max)
        render.DrawWireframeBox(self:GetPos(), DAng, Min, Max, DCol, true)
    end

    function ENT:Think()
        local b = ViewZones:GetBool()
        if not b then
            self.IsDrawing = nil
        elseif not self.IsDrawing then
            self.IsDrawing = true
        end
    end
end