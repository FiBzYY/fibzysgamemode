ENT.Type = "anim"
ENT.Base = "base_anim"

local Iv = IsValid
if SERVER then
	AddCSLuaFile()
	
	function ENT:Initialize()  
		self:SetSolid(SOLID_BBOX)
		
		local bbox = ( self.max - self.min ) / 2
	
		self:PhysicsInitBox( -bbox, bbox )
		self:SetCollisionBoundsWS( self.min, self.max )
	
		self:SetTrigger( true )
		self:DrawShadow( false )
		self:SetNotSolid( true )
		self:SetNoDraw( false )

		self.speed = Vector(0, 0, 500)

		self.Phys = self:GetPhysicsObject()
		if Iv( self.Phys ) then
			self.Phys:Sleep()
			self.Phys:EnableCollisions( false )
		end
	end

	function ENT:StartTouch(ent)  
		if Iv(ent) and ent:IsPlayer() then
			local vel = ent:GetVelocity()
			if vel.z > 0 then
				if ent.BoosterZone and CurTime() - ent.BoosterZone < 20 then return end
				ent:SetLocalVelocity(vel + self.speed)
				ent.BoosterZone = CurTime()
				ent.InBoosterZone = true
			end
		end
	end

	function ENT:EndTouch(ent)
		if Iv(ent) and ent:IsPlayer() then
			if ent.InBoosterZone then
				ent.InBoosterZone = false
				ent:SetLocalVelocity(ent:GetVelocity())
			end
		end
	end
else
	function ENT:Initialize()
	end 
	
	function ENT:Draw()
	end
end