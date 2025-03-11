if CLIENT then
	SWEP.DrawAmmo = true
	SWEP.DrawCrosshair = false
	SWEP.ViewModelFOV = 82
	SWEP.ViewModelFlip = true
end

SWEP.PrintName = "Glock"
SWEP.HoldType = "pistol"
SWEP.Base = "weapon_cs_base"
SWEP.Category = "Counter-Strike"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.ViewModel = "models/weapons/v_pist_glock18.mdl"
SWEP.WorldModel = "models/weapons/w_pist_glock18.mdl"
SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.IronSightsPos = Vector(4.3, -2, 2.7)

SWEP.Primary = {
	Sound = Sound("Weapon_Glock.Single"),
	Recoil = 1.8,
	Damage = 16,
	NumShots = 1,
	Cone = 0.03,
	ClipSize = 16,
	Delay = 0.05,
	DefaultClip = 21,
	Automatic = false,
	Ammo = "pistol"
}

SWEP.Secondary = {
	ClipSize = -1,
	DefaultClip = -1,
	Automatic = false,
	Ammo = "none"
}

local function PlayerPostThink(ply)
	if not IsValid(ply) or not ply.GetActiveWeapon then return end
	local weapon = ply:GetActiveWeapon()
	if IsValid(weapon) and weapon.IsGlock then
		weapon:FireExtraBullets()
	end
end
hook.Add("PlayerPostThink", "ProcessFire", PlayerPostThink)

function SWEP:Initialize()
	self.IsGlock = true
end

function SWEP:CSSGlockShoot(dmg, recoil, numbul, cone, anim)
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
        Callback = function(a, b, c)
            if SERVER and b.HitPos then
                local tracedata = {
                    start = b.StartPos,
                    endpos = b.HitPos + (b.Normal * 2),
                    filter = a,
                    mask = MASK_PLAYERSOLID
                }
                local trace = util.TraceLine(tracedata)
                                                        
                if IsValid(trace.Entity) then
                    if trace.Entity:GetClass() == "func_button" or trace.Entity:GetClass() == "func_physbox_multiplayer" then
                        trace.Entity:TakeDamage(dmg, a, c:GetInflictor())
                    end
                end
            end
        end
    }

    if SERVER and GetConVar("bhop_gunsounds"):GetInt() == 1 then
        self.Owner:EmitSound("Weapon_Glock.Single", 100, 100, 1, CHAN_WEAPON)
    end

    self.Owner:FireBullets(bullet)

    if anim then
        if self:GetDTInt(0) == 1 then
            self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
        else
            self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
        end
    end

    self.Owner:MuzzleFlash()
    self.Owner:SetAnimation(PLAYER_ATTACK1)

    if self.Owner:IsNPC() then return end
end

function SWEP:FireExtraBullets()
	if self:GetDTInt(0) == 1 and self.ShootNext and self.NextShoot < CurTime() and self.ShotsLeft > 0 then
		self:GlockShoot(false)
	end
end

function SWEP:GlockShoot(showanim)
	if self:GetDTInt(0) == 1 then self.ShootNext = false end
	if not self:CanPrimaryAttack() then return end

	self:CSSGlockShoot(self.Primary.Damage, self.Primary.Recoil, self.Primary.NumShots, self.Primary.Cone, showanim)
	self:TakePrimaryAmmo(1)

	if self.Owner:IsNPC() then return end

	if (game.SinglePlayer() and SERVER) or CLIENT then
		self:SetNetworkedFloat("LastShootTime", CurTime())
	end

	if self:GetDTInt(0) == 1 and self.ShotsLeft > 0 and not self.ShootNext then
		self.ShootNext = true
		self.ShotsLeft = self.ShotsLeft - 1
	end

	self.NextShoot = CurTime() + 0.04
end

function SWEP:PrimaryAttack()
	self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)

	if self:GetDTInt(0) == 1 then
		self:SetNextPrimaryFire(CurTime() + 0.5)
		self.ShotsLeft = 3
		self.NextShoot = CurTime() + 0.04
	else
		self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
	end

	self:GlockShoot(true)
end

function SWEP:SecondaryAttack()
	if self:GetDTInt(0) == 1 then
		self:SetDTInt(0, 0)
		self.Owner:PrintMessage(HUD_PRINTCENTER, "Switched to semi-automatic")
	else
		self:SetDTInt(0, 1)
		self.Owner:PrintMessage(HUD_PRINTCENTER, "Switched to burst-fire mode")
	end
end