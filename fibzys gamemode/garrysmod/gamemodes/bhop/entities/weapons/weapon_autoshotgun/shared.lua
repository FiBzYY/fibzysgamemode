if CLIENT then
    SWEP.PrintName = "Auto Shotgun"
    SWEP.Author = "Counter-Strike Imported To Lua By Skydive."
    SWEP.Slot = 2
    SWEP.SlotPos = 0
    SWEP.IconLetter = "k"
    
    killicon.AddFont("weapon_xm1014", "CSKillIcons", SWEP.IconLetter, Color(255, 80, 0, 255))
end

SWEP.HoldType = "ar2"
SWEP.Base = "weapon_cs_base"
SWEP.Category = "Counter-Strike"

SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.ViewModel = "models/weapons/v_shot_xm1014.mdl"
SWEP.WorldModel = "models/weapons/w_shot_xm1014.mdl"

SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Primary.Sound = Sound("Weapon_XM1014.Single")
SWEP.Primary.Recoil = 6
SWEP.Primary.Damage = 7.5
SWEP.Primary.NumShots = 12
SWEP.Primary.Cone = 0.045
SWEP.Primary.ClipSize = 6
SWEP.Primary.Delay = 0.25
SWEP.Primary.DefaultClip = 6
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "buckshot"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.IronSightsPos = Vector(5.1536, -3.817, 2.1621)
SWEP.IronSightsAng = Vector(-0.1466, 0.7799, 0)

-- Reload Function
function SWEP:Reload()
    -- Disable ironsights during reload
    self:SetIronsights(false)

    -- Prevent reloading if already reloading
    if self:GetNWBool("reloading", false) then return end

    -- Start reloading if there's room in the clip and the player has ammo
    if self:Clip1() < self.Primary.ClipSize and self.Owner:GetAmmoCount(self.Primary.Ammo) > 0 then
        self:SetNWBool("reloading", true)
        self:SetVar("reloadtimer", CurTime() + 0.3)
        self:SendWeaponAnim(ACT_VM_RELOAD)
        self.Owner:DoReloadEvent()
    end
end

-- Think Function (Handles reload progress)
function SWEP:Think()
    -- If reloading, check the timer
    if self:GetNWBool("reloading", false) then
        if CurTime() >= self:GetVar("reloadtimer", 0) then
            -- Finish reload if the clip is full or player has no ammo
            if self:Clip1() >= self.Primary.ClipSize or self.Owner:GetAmmoCount(self.Primary.Ammo) <= 0 then
                self:SetNWBool("reloading", false)
                self:SendWeaponAnim(ACT_SHOTGUN_RELOAD_FINISH)
                self.Owner:DoReloadEvent()
                return
            end

            -- Continue reloading if there's still room in the clip
            self:SetVar("reloadtimer", CurTime() + 0.3)
            self:SendWeaponAnim(ACT_VM_RELOAD)
            self.Owner:DoReloadEvent()

            -- Add one round to the clip and remove it from the player's reserve ammo
            self.Owner:RemoveAmmo(1, self.Primary.Ammo, false)
            self:SetClip1(self:Clip1() + 1)
        end
    end
end