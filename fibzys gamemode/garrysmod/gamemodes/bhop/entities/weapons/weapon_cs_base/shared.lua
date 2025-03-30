if CLIENT then
    CreateClientConVar("bhop_unlimited_ammo", "1", true, false, "Enable or disable unlimited ammo ")

	SWEP.DrawAmmo = true
	SWEP.DrawCrosshair = false
	SWEP.ViewModelFOV = 82
	SWEP.ViewModelFlip = true
	SWEP.CSMuzzleFlashes = true

	surface.CreateFont("CSKillIcons", { font="csd", weight="500", size=ScreenScale(30),antialiasing=true,additive=true })
	surface.CreateFont("CSSelectIcons", { font="csd", weight="500", size=ScreenScale(60),antialiasing=true,additive=true })
end

SWEP.Author = "Counter-Strike"
SWEP.Spawnable = false
SWEP.AdminSpawnable = false

SWEP.Primary = {
	Sound = Sound("Weapon_AK47.Single"),
	Recoil = 1.5,
	Damage = 40,
	NumShots = 1,
	Cone = 0.02,
	Delay = 0.15,
	ClipSize = -1,
	DefaultClip = -1,
	Automatic = false,
	Ammo = "none"
}

SWEP.Secondary = {
	ClipSize = -1,
	DefaultClip = -1,
	Automatic = false,
	Ammo = "none"
}

function SWEP:Initialize()
	if SERVER then
		self:SetNPCMinBurst(30)
		self:SetNPCMaxBurst(30)
		self:SetNPCFireRate(0.01)
	end
	self:SetIronsights(false)
end

function SWEP:Reload()
	self:DefaultReload(ACT_VM_RELOAD)
	self:SetIronsights(false)
end

function SWEP:Think()
end

function SWEP:PrimaryAttack()
	self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

	if not self:CanPrimaryAttack() then return end

	if CLIENT then
		if LocalPlayer() and IsValid(LocalPlayer()) and (GetConVar("bhop_gunsounds"):GetInt() == 1) then
			self:EmitSound(self.Primary.Sound)
		end
	end

	self:CSShootBullet(self.Primary.Damage, self.Primary.Recoil, self.Primary.NumShots, self.Primary.Cone)
	self:TakePrimaryAmmo(1)

	if self.Owner:IsNPC() then return end

	if (game.SinglePlayer() and SERVER) or CLIENT then
		self:SetNetworkedFloat("LastShootTime", CurTime())
	end
end

function SWEP:CSShootBullet(dmg, recoil, numbul, cone)
	numbul = numbul or 1
	cone = cone or 0.01

	local bullet = {
		Num = numbul,
		Src = self.Owner:GetShootPos(),
		Dir = self.Owner:GetAimVector(),
		Spread = Vector(cone, cone, 0),
		Tracer = 4,
		Force = 5,
		Damage = dmg,
		Callback = function(attacker, tr, dmginfo)
			if SERVER and tr.HitPos then
				local trace = util.TraceLine({
					start = tr.StartPos,
					endpos = tr.HitPos + (tr.Normal * 2),
					filter = attacker,
					mask = MASK_PLAYERSOLID
				})

				if IsValid(trace.Entity) then
					if trace.Entity:GetClass() == "func_button" then
						trace.Entity:TakeDamage(dmg, attacker, dmginfo:GetInflictor())
						trace.Entity:TakeDamage(dmg, attacker, dmginfo:GetInflictor())
					elseif trace.Entity:GetClass() == "func_physbox_multiplayer" then
						trace.Entity:TakeDamage(dmg, attacker, dmginfo:GetInflictor())
					end
				end
			end
		end
	}

	self.Owner:FireBullets(bullet)
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	self.Owner:MuzzleFlash()
	self.Owner:SetAnimation(PLAYER_ATTACK1)

	if self.Owner:IsNPC() then return end

	if (game.SinglePlayer() and SERVER) or (not game.SinglePlayer() and CLIENT and IsFirstTimePredicted()) then
		local eyeang = self.Owner:EyeAngles()
		eyeang.pitch = eyeang.pitch - recoil
		self.Owner:SetEyeAngles(eyeang)
	end
end

function SWEP:DrawWeaponSelection(x, y, wide, tall, alpha)
end

local IRONSIGHT_TIME = 0.25

function SWEP:GetViewModelPosition(pos, ang)
	if not self.IronSightsPos then return pos, ang end

	local bIron = self:GetNetworkedBool("Ironsights")
	if bIron ~= self.bLastIron then
		self.bLastIron = bIron
		self.fIronTime = CurTime()

		if bIron then
			self.SwayScale = 0
			self.BobScale = 0
		else
			self.SwayScale = 0
			self.BobScale = 0
		end
	end

	local Mul = 1.0

	if self.fIronTime > CurTime() - IRONSIGHT_TIME then
		Mul = math.Clamp((CurTime() - self.fIronTime) / IRONSIGHT_TIME, 0, 1)
		if not bIron then Mul = 1 - Mul end
	end

	local Offset = self.IronSightsPos

	if self.IronSightsAng then
		ang = ang * 1
		ang:RotateAroundAxis(ang:Right(), self.IronSightsAng.x * Mul)
		ang:RotateAroundAxis(ang:Up(), self.IronSightsAng.y * Mul)
		ang:RotateAroundAxis(ang:Forward(), self.IronSightsAng.z * Mul)
	end

	local Right = ang:Right()
	local Up = ang:Up()
	local Forward = ang:Forward()

	pos = pos + Offset.x * Right * Mul
	pos = pos + Offset.y * Forward * Mul
	pos = pos + Offset.z * Up * Mul

	return pos, ang
end

function SWEP:SetIronsights(b)
	self:SetNetworkedBool("Ironsights", b)
end

SWEP.NextSecondaryAttack = 0

local CCrosshair = CreateClientConVar("bhop_crosshair", "1", true, false)
local CGap = CreateClientConVar("bhop_cross_gap", "1", true, false)
local CThick = CreateClientConVar("bhop_cross_thick", "0", true, false)
local CLength = CreateClientConVar("bhop_cross_length", "1", true, false)
local CCRB = CreateClientConVar("bhop_cross_rainbow", "0", true, false)
local CColorR = CreateClientConVar("bhop_cross_color_r", "0", true, false)
local CColorG = CreateClientConVar("bhop_cross_color_g", "160", true, false)
local CColorB = CreateClientConVar("bhop_cross_color_b", "180", true, false)
local CColorA = CreateClientConVar("bhop_cross_opacity", "255", true, false)

if CLIENT then
	local function DrawFilledCircle(x, y, radius)
		local segments = 360
		local vertices = {}

		for i = 0, segments do
			local angle = math.rad((i / segments) * -360)
			table.insert(vertices, {
				x = x + math.sin(angle) * radius,
				y = y + math.cos(angle) * radius
			})
		end

		surface.SetDrawColor(255, 255, 255, 255)
		draw.NoTexture()
		surface.DrawPoly(vertices)
	end

	function SWEP:DrawHUD()
		if self:GetNetworkedBool("Ironsights") then return end
		if not CCrosshair:GetBool() then return end

		local x, y
		if self.Owner == LocalPlayer() and self.Owner:ShouldDrawLocalPlayer() then
			local tr = util.GetPlayerTrace(self.Owner)
			tr.mask = bit.bor(CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_MONSTER, CONTENTS_WINDOW, CONTENTS_DEBRIS, CONTENTS_GRATE, CONTENTS_AUX)
			local trace = util.TraceLine(tr)
			local coords = trace.HitPos:ToScreen()
			x, y = coords.x, coords.y
		else
			x, y = ScrW() / 2.0, ScrH() / 2.0
		end

		local scale = 10 * self.Primary.Cone
		local LastShootTime = self:GetNetworkedFloat("LastShootTime", 0)
		scale = scale * (2 - math.Clamp((CurTime() - LastShootTime) * 5, 0.0, 1.0))

		local wepcrossrb = CCRB:GetInt()

		if wepcrossrb == 1 then
			surface.SetDrawColor(HSVToColor(RealTime() * 40 % 360, 1, 1))
		else
			surface.SetDrawColor(CColorR:GetInt(), CColorG:GetInt(), CColorB:GetInt(), CColorA:GetInt())
		end

		local gap = 40 * (scale * CGap:GetInt())
		local length = gap + 20 * (scale * CLength:GetInt())
		local thick = CThick:GetInt()

		if thick > 0 then
			for i = -thick, thick do
				surface.DrawLine(x - length, y + i, x - gap, y + i)
				surface.DrawLine(x + length, y + i, x + gap, y + i)
				surface.DrawLine(x + i, y - length, x + i, y - gap)
				surface.DrawLine(x + i, y + length, x + i, y + gap)
			end
		else
			surface.DrawLine(x - length, y, x - gap, y)
			surface.DrawLine(x + length, y, x + gap, y)
			surface.DrawLine(x, y - length, x, y - gap)
			surface.DrawLine(x, y + length, x, y + gap)
		end

		local circleRadius = 3
		--DrawFilledCircle(x, y, circleRadius)
	end
end

function SWEP:OnRestore()
	self.NextSecondaryAttack = 0
	self:SetIronsights(false)
end