if CLIENT then
    SWEP.DrawAmmo = true
    SWEP.DrawCrosshair = false
    SWEP.ViewModelFOV = 82
    SWEP.ViewModelFlip = true
end

SWEP.PrintName = "KM .45 Tactical"
SWEP.Category = "Counter-Strike: Source"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.AdminOnly = false
SWEP.ViewModel = "models/weapons/v_pist_usp.mdl"
SWEP.WorldModel = "models/weapons/w_pist_usp.mdl"
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Weight = 5
SWEP.Slot = 1
SWEP.SlotPos = 0
SWEP.UseHands = true
SWEP.HoldType = "pistol"
SWEP.FiresUnderwater = true
SWEP.CSMuzzleFlashes = 1
SWEP.Base = "weapon_cs_base"

SWEP.Silencer = 0
SWEP.SilencerState = 0
SWEP.SilencerToggleInterval = 3
SWEP.SilencerSoundInterval = 2.3
SWEP.LastSilencerSoundTime = 0

SWEP.Primary = {
    Sound = Sound("Weapon_USP.Single"),
    ClipSize = 16,
    DefaultClip = 112,
    MaxAmmo = 999,
    Automatic = false,
    Ammo = "Pistol",
    Damage = 34,
    TakeAmmo = 1,
    NumberofShots = 1,
    Spread = 0.004,
    SpreadMin = 0.004,
    SpreadMax = 0.03495,
    SpreadKick = 0.008,
    SpreadMove = 0.05219,
    SpreadAir = 0.28725,
    SpreadMinAlt = 0.003,
    SpreadMaxAlt = 0.02504,
    SpreadMoveAlt = 0.04282,
    SpreadAirAlt = 0.29625,
    SpreadRecoveryTime = 0.28045,
    SpreadRecoveryTimer = CurTime(),
    Delay = 0.15,
    Force = 1
}

SWEP.Secondary = {
    Sound = Sound("Weapon_USP.SilencedShot"),
    ClipSize = 0,
    DefaultClip = 0,
    Automatic = false,
    Ammo = "none"
}

SWEP.SilencerTimer = CurTime()
SWEP.ShotTimer = CurTime()
SWEP.Reloading = 0
SWEP.ReloadingTimer = CurTime()
SWEP.Recoil = 0
SWEP.Idle = 0
SWEP.IdleTimer = CurTime()

function SWEP:Initialize()
    self.Silencer = 0
    self.Idle = 0
    self.IdleTimer = CurTime() + 1
    self.SilencerNextToggle = SysTime() + self.SilencerToggleInterval
end

function SWEP:DrawWeaponSelection(x, y, wide, tall)
    draw.SimpleText("a", "CSSelectIcons", x + wide / 2, y + tall / 4, Color(255, 220, 0), TEXT_ALIGN_CENTER)
end

function SWEP:Deploy()
    if self.SilencerState == 0 then
        self:SendWeaponAnim(ACT_VM_DRAW)
    elseif self.SilencerState == 2 then
        self:SendWeaponAnim(ACT_VM_DRAW_SILENCED)
    end
    self:SetNextPrimaryFire(CurTime() + self.Owner:GetViewModel():SequenceDuration())
    self:SetNextSecondaryFire(CurTime() + self.Owner:GetViewModel():SequenceDuration())
    self:ResetTimers()
    return true
end

function SWEP:Holster()
    self:ResetTimers()
    return true
end

function SWEP:PrimaryAttack()
    if self:Clip1() <= 0 and self:Ammo1() <= 0 or not self.FiresUnderwater and self.Owner:WaterLevel() == 3 then
        if SERVER then self.Owner:EmitSound("Default.ClipEmpty_Pistol") end
        self:SetNextPrimaryFire(CurTime() + 0.15)
        return
    end

    if self:Clip1() <= 0 then self:Reload() end
    if self:Clip1() <= 0 or not self.FiresUnderwater and self.Owner:WaterLevel() == 3 then return end

    local dmg = self.Primary.Damage

    local bullet = {
        Num = self.Primary.NumberofShots,
        Src = self.Owner:GetShootPos(),
        Dir = self.Owner:GetAimVector(),
        Spread = Vector(self.Primary.Spread, self.Primary.Spread, 0),
        Tracer = 0,
        Distance = 4096,
        Force = self.Primary.Force,
        Damage = dmg,
        AmmoType = self.Primary.Ammo,
        Callback = function(attacker, tr, dmginfo)
            if SERVER and tr.HitPos then
                local tracedata = {
                    start = tr.StartPos,
                    endpos = tr.HitPos + (tr.Normal * 2),
                    filter = attacker,
                    mask = MASK_PLAYERSOLID
                }
                local trace = util.TraceLine(tracedata)

                if IsValid(trace.Entity) then
                    if trace.Entity:GetClass() == "func_button" then
                        trace.Entity:TakeDamage(dmg, attacker, dmginfo:GetInflictor())
                    elseif trace.Entity:GetClass() == "func_physbox_multiplayer" then
                        trace.Entity:TakeDamage(dmg, attacker, dmginfo:GetInflictor())
                    end
                end
            end
        end
    }

    self.Owner:FireBullets(bullet)
    self:EmitSound(self.SilencerState == 0 and self.Primary.Sound or self.Secondary.Sound)

    self:SetClip1(self:GetMaxClip1())

    self:ShootEffects()
    self:TakePrimaryAmmo(self.Primary.TakeAmmo)
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)

    if self.SilencerState == 0 and self.Primary.Spread < self.Primary.SpreadMax or
       self.SilencerState == 2 and self.Primary.Spread < self.Primary.SpreadMaxAlt then
        self.Primary.Spread = self.Primary.Spread + self.Primary.SpreadKick
    end

    self.Primary.SpreadRecoveryTimer = CurTime() + self.Primary.SpreadRecoveryTime
    self.ShotTimer = CurTime() + self.Primary.Delay
    self.ReloadingTimer = CurTime() + self.Primary.Delay
    self.IdleTimer = CurTime() + self.Owner:GetViewModel():SequenceDuration()
end

function SWEP:SecondaryAttack()
    self:ToggleSilencer()
end

function SWEP:ToggleSilencer()
    local currentTime = SysTime()
    if currentTime - self.LastSilencerSoundTime < self.SilencerSoundInterval then return end
    self.LastSilencerSoundTime = currentTime

    if self.SilencerState == 0 then
        self:SendWeaponAnim(ACT_VM_ATTACH_SILENCER)
        self:ScheduleSilencerToggle(1, 2, "Weapon_USP.Silencer_On")
    elseif self.SilencerState == 2 then
        self:SendWeaponAnim(ACT_VM_DETACH_SILENCER)
        self:ScheduleSilencerToggle(3, 0, "Weapon_USP.Silencer_Off")
    end
end

function SWEP:ScheduleSilencerToggle(intermediateState, finalState, sound)
    self:SetNextPrimaryFire(CurTime() + self.Owner:GetViewModel():SequenceDuration())
    self:SetNextSecondaryFire(CurTime() + self.Owner:GetViewModel():SequenceDuration())
    if IsFirstTimePredicted() then
        self.SilencerState = intermediateState
        self:EmitSound(sound)
        timer.Simple(self.Owner:GetViewModel():SequenceDuration(), function()
            if IsValid(self) and self.SilencerState == intermediateState then
                self.SilencerState = finalState
            end
        end)
    end
    self:ResetTimers()
end

function SWEP:ShootEffects()
    if self:Clip1() > 1 then
        self:SendWeaponAnim(self.SilencerState == 0 and ACT_VM_PRIMARYATTACK or ACT_VM_PRIMARYATTACK_SILENCED)
        self.Idle = 0
    else
        self:SendWeaponAnim(self.SilencerState == 0 and ACT_VM_DRYFIRE or ACT_VM_DRYFIRE_SILENCED)
        self.Idle = 2
    end
    self.Owner:SetAnimation(PLAYER_ATTACK1)
    -- self.Owner:MuzzleFlash()
end

function SWEP:Reload()
    if self.Reloading == 0 and self.ReloadingTimer <= CurTime() and self:Clip1() < self.Primary.ClipSize and self:Ammo1() > 0 then
        self:SendWeaponAnim(self.SilencerState == 0 and ACT_VM_RELOAD or ACT_VM_RELOAD_SILENCED)
        self.Owner:SetAnimation(PLAYER_RELOAD)
        self:SetNextPrimaryFire(CurTime() + self.Owner:GetViewModel():SequenceDuration())
        self:SetNextSecondaryFire(CurTime() + self.Owner:GetViewModel():SequenceDuration())
        self.Reloading = 1
        self.ReloadingTimer = CurTime() + self.Owner:GetViewModel():SequenceDuration()
        self.Idle = 0
        self.IdleTimer = CurTime() + self.Owner:GetViewModel():SequenceDuration()
    end
end

function SWEP:Think()
    if self.SilencerTimer < CurTime() then
        if self.SilencerState == 1 then self.SilencerState = 2 end
        if self.SilencerState == 3 then self.SilencerState = 0 end
    end

    if CLIENT and IsFirstTimePredicted() then
        if self.Recoil < 0 then self.Recoil = 0 end
        if self.Recoil > 0 then
            self.Owner:SetEyeAngles(self.Owner:EyeAngles() + Angle(0.25, 0, 0))
            self.Recoil = self.Recoil - 0.25
        end
    end

    if self.ShotTimer > CurTime() then
        self.Primary.SpreadRecoveryTimer = CurTime() + self.Primary.SpreadRecoveryTime
    end

    self:HandleSpreadRecovery()

    if self.Reloading == 1 and self.ReloadingTimer <= CurTime() then
        self:CompleteReload()
    end

    if self.IdleTimer <= CurTime() then
        self:HandleIdle()
    end

    self:LimitMaxAmmo()

    if self.Owner:KeyDown(IN_ATTACK2) then
        self:AutoToggleSilencer()
    end
end

function SWEP:HandleSpreadRecovery()
    if self.Owner:IsOnGround() then
        if self.Primary.SpreadRecoveryTimer <= CurTime() then
            if self.SilencerState == 0 then
                self.Primary.Spread = self.Primary.SpreadMin
            elseif self.SilencerState == 2 then
                self.Primary.Spread = self.Primary.SpreadMinAlt
            end
            if self.Primary.Spread > self.Primary.SpreadMin then
                self.Primary.Spread = ((self.Primary.SpreadRecoveryTimer - CurTime()) / self.Primary.SpreadRecoveryTime) * self.Primary.Spread
            end
        end
        if self.SilencerState == 0 and self.Primary.Spread > self.Primary.SpreadMax then
            self.Primary.Spread = self.Primary.SpreadMax
        elseif self.SilencerState == 2 and self.Primary.Spread > self.Primary.SpreadMaxAlt then
            self.Primary.Spread = self.Primary.SpreadMaxAlt
        end
        self.Primary.SpreadRecoveryTimer = CurTime() + self.Primary.SpreadRecoveryTime
    else
        if self.SilencerState == 0 then
            self.Primary.Spread = self.Primary.SpreadAir
            if self.Primary.Spread > self.Primary.SpreadMin then
                self.Primary.Spread = ((self.Primary.SpreadRecoveryTimer - CurTime()) / self.Primary.SpreadRecoveryTime) * self.Primary.SpreadAir
            end
        elseif self.SilencerState == 2 then
            self.Primary.Spread = self.Primary.SpreadAirAlt
            if self.Primary.Spread > self.Primary.SpreadMinAlt then
                self.Primary.Spread = ((self.Primary.SpreadRecoveryTimer - CurTime()) / self.Primary.SpreadRecoveryTime) * self.Primary.SpreadAirAlt
            end
        end
        self.Primary.SpreadRecoveryTimer = CurTime() + self.Primary.SpreadRecoveryTime
    end
end

function SWEP:CompleteReload()
    if self:Ammo1() > (self.Primary.ClipSize - self:Clip1()) then
        self.Owner:SetAmmo(self:Ammo1() - self.Primary.ClipSize + self:Clip1(), self.Primary.Ammo)
        self:SetClip1(self.Primary.ClipSize)
    elseif (self:Ammo1() - self.Primary.ClipSize + self:Clip1()) + self:Clip1() < self.Primary.ClipSize then
        self:SetClip1(self:Clip1() + self:Ammo1())
        self.Owner:SetAmmo(0, self.Primary.Ammo)
    end
    self.Reloading = 0
end

function SWEP:HandleIdle()
    if self.Idle == 0 then
        self.Idle = 1
    end
    if SERVER and self.Idle == 1 then
        self:SendWeaponAnim(self.SilencerState == 0 and ACT_VM_IDLE or ACT_VM_IDLE_SILENCED)
    end
    self.IdleTimer = CurTime() + self.Owner:GetViewModel():SequenceDuration()
end

function SWEP:LimitMaxAmmo()
    if self:Ammo1() > self.Primary.MaxAmmo then
        self.Owner:SetAmmo(self.Primary.MaxAmmo, self.Primary.Ammo)
    end
end

function SWEP:AutoToggleSilencer()
    if SysTime() >= self.SilencerNextToggle and self.SilencerState % 2 == 0 then
        self:ToggleSilencer()
        self.SilencerNextToggle = SysTime() + self.SilencerToggleInterval
    end
end

function SWEP:ResetTimers()
    self.SilencerTimer = CurTime()
    self.ShotTimer = CurTime()
    self.Reloading = 0
    self.ReloadingTimer = CurTime() + self.Owner:GetViewModel():SequenceDuration()
    self.Recoil = 0
    self.Idle = 0
    self.IdleTimer = CurTime() + self.Owner:GetViewModel():SequenceDuration()
end