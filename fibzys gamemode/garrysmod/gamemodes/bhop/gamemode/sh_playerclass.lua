DEFINE_BASECLASS "player_default"

local PLAYER = {
    DisplayName = "Player",
    AvoidPlayers = false,
    CrouchedWalkSpeed = BHOP.Move.CrouchWalkSpeed / BHOP.Move.WalkSpeed,
    Model = BHOP.Models.Player, BotModel = BHOP.Models.Bot
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

    for ammoType, amount in pairs(BHOP.DefaultAmmo) do
        ply:SetAmmo(amount, ammoType, true)
    end
end

function PLAYER:SetModel()
    local model = self.Player:IsBot() and self.BotModel or self.Model
    self.Player:SetModel(model)
end
player_manager.RegisterClass("player_bhop", PLAYER, "player_default")