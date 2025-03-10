ENT.Type = "anim"
ENT.Base = "base_anim"

local Iv = IsValid

if SERVER then
    AddCSLuaFile()
    util.AddNetworkString("ToggleFullbright")

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
            net.Start("ToggleFullbright")
            net.WriteBool(true)
            net.Send(ent)
        end
    end

    function ENT:EndTouch(ent)
        if Iv(ent) and ent:IsPlayer() then
            net.Start("ToggleFullbright")
            net.WriteBool(false)
            net.Send(ent)
        end
    end
end