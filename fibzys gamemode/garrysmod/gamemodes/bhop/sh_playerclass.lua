DEFINE_BASECLASS "player_default"

local PLAYER = {
    DisplayName = "Player",
    AvoidPlayers = false,
    CrouchedWalkSpeed = 0.6,
    Model = "models/player/group01/male_01.mdl", BotModel = "models/player/group01/male_01.mdl"
}

local DEFAULT_AMMO = {
    pistol = 999, smg1 = 999,
    buckshot = 999
}

function PLAYER:Loadout()
    local ply = self.Player

    ply.enablepickup = true

    if ply.Inventory then
        for _, weapon in pairs(ply.Inventory) do
            ply:Give(weapon)
        end
    end

    if ply.ActiveWeapon and ply:HasWeapon(ply.ActiveWeapon) then
        ply:SelectWeapon(ply.ActiveWeapon)
    end

    ply.enablepickup = false

    for ammoType, count in pairs(DEFAULT_AMMO) do
        ply:SetAmmo(count, ammoType)
    end
end

function PLAYER:SetModel()
    local model = self.Player:IsBot() and self.BotModel or self.Model
    self.Player:SetModel(model)
end
player_manager.RegisterClass("player_bhop", PLAYER, "player_default")