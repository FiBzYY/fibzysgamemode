ENT.Type = "anim"
ENT.Base = "base_anim"

local Iv = IsValid

if SERVER then
	AddCSLuaFile()
	
	function ENT:Initialize()  
		self:SetSolid(SOLID_BBOX)
		
		local bbox = (self.max - self.min) / 2
	
		self:PhysicsInitBox( -bbox, bbox )
		self:SetCollisionBoundsWS( self.min,self.max )
	
		self:SetTrigger( true )
		self:DrawShadow( false )
		self:SetNotSolid( true )
		self:SetNoDraw( false )
	
		self.Phys = self:GetPhysicsObject()
		if Iv( self.Phys ) then
			self.Phys:Sleep()
			self.Phys:EnableCollisions( false )
		end
	end

	function ENT:StartTouch( ent )  
		if Iv( ent ) and ent:IsPlayer() then
			ent:SetHullDuck( Vector( -16, -16, 0 ), Vector( 16, 16, self.height ) )
		end
	end
	
	function ENT:EndTouch( ent )
		if Iv( ent ) and ent:IsPlayer() then
			ent:SetHullDuck( Vector( -16, -16, 0 ), Vector( 16, 16, 45 ) )
		end
	end
else
	function ENT:Initialize()
	end 
	
	function ENT:Draw()
	end
end