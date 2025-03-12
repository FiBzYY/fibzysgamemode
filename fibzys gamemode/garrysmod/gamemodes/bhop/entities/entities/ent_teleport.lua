ENT.Type = "anim"
ENT.Base = "base_anim"

local Iv = IsValid

if SERVER then
    AddCSLuaFile()

    function ENT:Initialize()
        self.min = Vector(-32, -32, 0)
        self.max = Vector(32, 32, 64)

        self:SetSolid(SOLID_BBOX)
        local bbox = (self.max - self.min) / 2

        self:PhysicsInitBox(-bbox, bbox)
        self:SetCollisionBoundsWS(self.min, self.max)

        self:SetTrigger(true)
        self:DrawShadow(false)
        self:SetNotSolid(true)
        self:SetNoDraw(false)

        self.targetpos = Vector(0, 0, 0)
        self.targetang = Angle(0, 0, 0)

        self.Phys = self:GetPhysicsObject()
        if Iv(self.Phys) then
            self.Phys:Sleep()
            self.Phys:EnableCollisions(false)
        end
    end

    function ENT:StartTouch(ent)
        if Iv(ent) and ent:IsPlayer() then
            ent:SetPos(self.targetpos)
            ent:SetEyeAngles(self.targetang)
        end
    end
else
    function ENT:Initialize()
    end

    function ENT:Draw()
    end
end