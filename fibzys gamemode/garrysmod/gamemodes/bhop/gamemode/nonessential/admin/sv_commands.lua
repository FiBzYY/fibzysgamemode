-- Admin Commands

CommandTable = {}
CommandTable["kick"] = function(admin, targetSteamID, args)
    if not IsValid(admin) or not admin:IsAdmin() then
        if IsValid(admin) then TIMER:Print(admin, "You do not have permission to use this command.") end
        return
    end

    local reason = args[1] or "No reason provided"
    local target = nil

    for _, ply in ipairs(player.GetAll()) do
        if ply:SteamID() == targetSteamID then
            target = ply
            break
        end
    end

    if not IsValid(target) then
        TIMER:Print(admin, "Kick failed: Player not found.")
        return
    end

    target:Kick("Kicked by Admin: " .. reason)

    if UTIL and UTIL.Notify then
        UTIL:Notify(Color(255, 0, 0), "Admin", target:Nick() .. " was kicked. Reason: " .. reason)
    end
end

CommandTable["ban"] = function(admin, targetSteamID, args)
    if not IsValid(admin) or not admin:IsAdmin() then
        if IsValid(admin) then TIMER:Print(admin, "You do not have permission to use this command.") end
        return
    end

    local length = tonumber(args[1]) or 0
    local reason = args[2] or "Banned from server."

    local target = nil
    for _, ply in ipairs(player.GetAll()) do
        if ply:SteamID() == targetSteamID then
            target = ply
            break
        end
    end

    if not IsValid(target) then
        TIMER:Print(admin, "Player not found.")
        return
    end

    BanPlayer(target, length * 60, reason, admin)
end

CommandTable["banid"] = function(admin, _, args)
    if not IsValid(admin) or not admin:IsAdmin() then
        TIMER:Print(admin, "You do not have permission to use this command.")
        return
    end

    local steamid = args[1]
    local length = tonumber(args[2]) or 0
    local reason = args[3] or "Violation of server rules."

    if not steamid or steamid == "" or not steamid:find("STEAM_") then
        TIMER:Print(admin, "Invalid SteamID.")
        return
    end

    BanPlayerBySteamID(steamid, length * 60, reason, admin)
end

CommandTable["unbanid"] = function(admin, _, args)
    if not IsValid(admin) or not admin:IsAdmin() then
        TIMER:Print(admin, "You do not have permission to use this command.")
        return
    end

    local steamid = args[1]
    if not steamid or steamid == "" or not steamid:find("STEAM_") then
        TIMER:Print(admin, "Invalid SteamID.")
        return
    end

    UnbanPlayer(steamid)
end

CommandTable["setgroup"] = function(admin, targetSteamID, args)
    if not IsValid(admin) or not admin:IsAdmin() then
        TIMER:Print(admin, "You do not have permission to use this command.")
        return
    end

    local groupName = args[1] or "user"
    local targetPly = nil

    for _, ply in ipairs(player.GetAll()) do
        if ply:SteamID() == targetSteamID then
            targetPly = ply
            break
        end
    end

    if not targetPly then
        TIMER:Print(admin, "Target player not found.")
        return
    end

    local steamID64 = targetPly:SteamID64()
    Admin:SetPlayerRankBySteamID64(admin, steamID64, groupName)
end

CommandTable["getip"] = function(admin, targetSteamID, args)
    if not IsValid(admin) or not admin:IsAdmin() then
        TIMER:Print(admin, "You do not have permission to use this command.")
        return
    end

    local target = nil
    for _, ply in ipairs(player.GetAll()) do
        if ply:SteamID() == targetSteamID then
            target = ply
            break
        end
    end

    if not IsValid(target) then
        TIMER:Print(admin, "Player not found.")
        return
    end

    local ip = target:IPAddress()
    if ip == "Error!" then
        TIMER:Print(admin, "That player is a bot or IP could not be fetched.")
        return
    end

    TIMER:Print(admin, target:Nick() .. "'s IP Address: " .. ip)
end

CommandTable["extendmap"] = function(admin, _, args)
    if not IsValid(admin) or not admin:IsAdmin() then
        TIMER:Print(admin, "You do not have permission to use this command.")
        return
    end

    local minutes = tonumber(args[1]) or 15

    if RTV and RTV.VIPExtend then
        RTV:VIPExtend(admin)
        TIMER:Print(admin, "Extend command triggered for " .. minutes .. " minutes.")
    else
        TIMER:Print(admin, "Extend function not available!")
    end
end

CommandTable["gag"] = function(admin, targetSteamID, args)
    if not IsValid(admin) or not admin:IsAdmin() then
        TIMER:Print(admin, "You do not have permission to use this command.")
        return
    end

    local target = nil
    for _, ply in ipairs(player.GetAll()) do
        if ply:SteamID() == targetSteamID then
            target = ply
            break
        end
    end

    if not IsValid(target) then
        TIMER:Print(admin, "Player not found.")
        return
    end

    local steamID = target:SteamID()
    GaggedPlayers[steamID] = true

    TIMER:Print(admin, target:Nick() .. " has been gagged.")
end

CommandTable["ungag"] = function(admin, targetSteamID, args)
    if not IsValid(admin) or not admin:IsAdmin() then
        TIMER:Print(admin, "You do not have permission to use this command.")
        return
    end

    GaggedPlayers[targetSteamID] = nil

    for _, ply in ipairs(player.GetAll()) do
        if ply:SteamID() == targetSteamID then
            NETWORK:StartNetworkMessageTimer(admin, "Print", { "Notification", "You have been ungagged." })
            break
        end
    end

    TIMER:Print(admin, "Player has been ungagged.")
end

CommandTable["spectate"] = function(admin, targetSteamID, args)
    if not IsValid(admin) or not admin:IsAdmin() then
        TIMER:Print(admin, "You do not have permission to use this command.")
        return
    end

    local target = nil
    for _, ply in ipairs(player.GetAll()) do
        if ply:SteamID() == targetSteamID then
            target = ply
            break
        end
    end

    if not IsValid(target) then
        TIMER:Print(admin, "Player not found.")
        return
    end

    -- Move to spectator
    target:SetTeam(TEAM_SPECTATOR)
    target:Spawn()

    -- Activate spectator system
    Spectator:New(target)

    TIMER:Print(admin, "Forced " .. target:Nick() .. " into spectator mode.")
end

CommandTable["mute"] = function(admin, targetSteamID, args)
    if not IsValid(admin) or not admin:IsAdmin() then
        TIMER:Print(admin, "You do not have permission to use this command.")
        return
    end

    local target = nil
    for _, ply in ipairs(player.GetAll()) do
        if ply:SteamID() == targetSteamID then
            target = ply
            break
        end
    end

    if not IsValid(target) then
        TIMER:Print(admin, "Player not found.")
        return
    end

    MutedPlayers[target:SteamID()] = true

    TIMER:Print(admin, target:Nick() .. " has been muted from voice chat.")
    NETWORK:StartNetworkMessageTimer(admin, "Print", { "Notification", "You have been muted by an admin." })
end

CommandTable["unmute"] = function(admin, targetSteamID, args)
    if not IsValid(admin) or not admin:IsAdmin() then
        TIMER:Print(admin, "You do not have permission to use this command.")
        return
    end

    MutedPlayers[targetSteamID] = nil

    for _, ply in ipairs(player.GetAll()) do
        if ply:SteamID() == targetSteamID then
            NETWORK:StartNetworkMessageTimer(admin, "Print", { "Notification", "You have been unmuted." })
            break
        end
    end

    TIMER:Print(admin, "Player has been unmuted.")
end

CommandTable["permmute"] = function(admin, targetSteamID, args)
    if not IsValid(admin) or not admin:IsAdmin() then
        TIMER:Print(admin, "You do not have permission to use this command.")
        return
    end

    local target = nil
    for _, ply in ipairs(player.GetAll()) do
        if ply:SteamID() == targetSteamID then
            target = ply
            break
        end
    end

    PermMutedPlayers[targetSteamID] = true

    if IsValid(target) then
        NETWORK:StartNetworkMessageTimer(admin, "Print", { "Notification", "You have been permanently muted by an admin." })
    end

    TIMER:Print(admin, (IsValid(target) and target:Nick() or targetSteamID) .. " has been permanently muted.")

    -- TODO: Save to SQL
end

CommandTable["permgag"] = function(admin, targetSteamID, args)
    if not IsValid(admin) or not admin:IsAdmin() then
        TIMER:Print(admin, "You do not have permission to use this command.")
        return
    end

    local target = nil
    for _, ply in ipairs(player.GetAll()) do
        if ply:SteamID() == targetSteamID then
            target = ply
            break
        end
    end

    PermGaggedPlayers[targetSteamID] = true

    if IsValid(target) then
        NETWORK:StartNetworkMessageTimer(admin, "Print", { "Notification", "You have been permanently gagged by an admin." })
    end

    TIMER:Print(admin, (IsValid(target) and target:Nick() or targetSteamID) .. " has been permanently gagged.")

    -- TODO: Save to SQL
end