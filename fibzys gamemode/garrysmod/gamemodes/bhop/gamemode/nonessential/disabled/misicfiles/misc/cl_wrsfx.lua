local cv_enabled = CreateClientConVar("bhop_wrsfx", "1", true, true, "WR sounds enabled state", 0, 1)
local cv_volume = CreateClientConVar("bhop_wrsfx_volume", "0.4", true, false, "WR sounds volume", 0, 1)

net.Receive("WRSFX_Broadcast", function(len, ply)
    if not cv_enabled:GetBool() then return end
    local soundPath = "wrsfx/" .. net.ReadString()

    ply:EmitSound(soundPath, 75, 100, cv_volume:GetFloat())
end)