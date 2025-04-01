-- Whitelist system
local hook_Add = hook.Add
CreateConVar("bhop_whitelist", "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Whitelist enabled")

local function IsPlayerWhitelisted(ply)
    if not IsValid(ply) or not ply:IsPlayer() then
        return false
    end

    if ply:IsSuperAdmin() or ply:IsBot() then
        return true
    end

    local steamid = ply:SteamID()
    UTIL:Notify(Color(255, 255, 255), "Whitelist", "Checking whitelist for SteamID: " .. steamid)

    return BHOP.Whitelist[steamid] or false
end

hook.Add("CheckPassword", "WhitelistCheck", function(steamid64, ip, sv_password, cl_password, name)
    -- whitelist is OFF, check the normal password
    if not BHOP.IsWhitelistOn then
        if sv_password ~= "" and cl_password ~= sv_password then
            UTIL:Notify(Color(255, 255, 255), "Whitelist", "~ " .. name .. " failed to provide the correct password! ~")
            return false, "Incorrect server password!"
        end
        return true
    end

    local steamid = util.SteamIDFrom64(steamid64)
    UTIL:Notify(Color(255, 255, 255), "Whitelist", "~ CheckPassword: Checking if SteamID " .. steamid .. " (" .. name .. ") is whitelisted ~")

    -- if the player is whitelisted
    if BHOP.Whitelist[steamid] then
        UTIL:Notify(Color(255, 255, 255), "Whitelist", "~ SteamID " .. steamid .. " (" .. name .. ") is whitelisted ~")
        return true
    else
        UTIL:Notify(Color(255, 255, 255), "Whitelist", "~ SteamID " .. steamid .. " (" .. name .. ") is NOT whitelisted ~")
        SendPopupNotification(nil, "Notification", "~ SteamID " .. steamid .. " (" .. name .. ") tried to join ~", 2)
        return false, "You are not allowed to join this server."
    end
end)

local function KickNonWhitelisted(ply)
    if not IsPlayerWhitelisted(ply) then
        UTIL:Notify(Color(255, 255, 255), "Whitelist", "~ " .. ply:Nick() .. " (" .. ply:SteamID() .. ") is not whitelisted and will be kicked ~")
        ply:Kick("~ You are not allowed to join this server. ~")
    end
end

hook_Add("PlayerInitialSpawn", "CheckWhitelistOnSpawn", function(ply)
    if BHOP.IsWhitelistOn then
        KickNonWhitelisted(ply)
    end
end)

concommand.Add("whitelist_toggle", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then
        SendPopupNotification(ply, "You don't have permission to use this command.", 2)
        return
    end

    BHOP.IsWhitelistOn = not BHOP.IsWhitelistOn

    local status = BHOP.IsWhitelistOn and "enabled" or "disabled"

    if IsValid(ply) then
        SendPopupNotification(nil, "Whitelist is now " .. status, 2)
    else
        SendPopupNotification(nil, "Whitelist is now " .. status, 2)
    end
end)