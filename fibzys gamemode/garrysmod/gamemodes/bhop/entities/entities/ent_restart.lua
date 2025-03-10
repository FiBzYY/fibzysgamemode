ENT.Type = "anim"
ENT.Base = "base_anim"

local Iv = IsValid

if SERVER then
    AddCSLuaFile()

    function ENT:Initialize()
        self:SetSolid(SOLID_BBOX)

        local BBOX = (self.max - self.min) / 2

        self:PhysicsInitBox(-BBOX, BBOX)
        self:SetCollisionBoundsWS(self.min, self.max)

        self:SetTrigger(true)
        self:DrawShadow(false)
        self:SetNotSolid(true)
        self:SetNoDraw(true)

        local phys = self:GetPhysicsObject()
        if Iv(phys) then
            phys:EnableMotion(false)
        end

        self:SetNWInt("zonetype", self.zonetype)
    end

    function ENT:StartTouch(ent)
        if Iv(ent) and ent:IsPlayer() then
            TIMER:ResetTimer(ent)
            ent:Spawn()
        end
    end

else
    function ENT:Initialize()
    end

    function ENT:Draw()
    end
end