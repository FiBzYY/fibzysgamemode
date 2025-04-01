Setspawn = Setspawn or {
    Points = Setspawn and Setspawn.Points or {}
}

local function isValidSpawnPoint(ply)
    if ply:Team() == TEAM_SPECTATOR then
        NETWORK:StartNetworkMessageTimer(ply, "Print", {"Timer", "You have to be alive and playing to be able to use it"})
        SendPopupNotification(ply, "Notification", "You have to be alive and playing to be able to use it", 2)

        return false
    end

    if not ply:OnGround() then
        NETWORK:StartNetworkMessageTimer(ply, "Print", {"Timer", "You have to touch the ground to be able to use it"})
        SendPopupNotification(ply, "Notification", "You have to touch the ground to be able to use it", 2)

        return false
    end

    if ply:GetVelocity():Length2D() > 0.01 then
        NETWORK:StartNetworkMessageTimer(ply, "Print", {"Timer", "You have to stay still to be able to use it"})
        SendPopupNotification(ply, "Notification", "You have to stay still to be able to use it", 2)

        return false
    end

    return true
end

local function getSpawnIdentifier(ply)
    return ply.style == 12 and 2 or 0
end

local setspawnFile = "setspawnmaplist.txt"
local function SaveSetSpawn()
    local map = game.GetMap()
    local data = util.TableToJSON(Setspawn.Points, true)
    if data then
        file.Write(setspawnFile, data)
    end
end

local function LoadSetSpawn()
    if not file.Exists(setspawnFile, "DATA") then return end
    local map = game.GetMap()
    local data = file.Read(setspawnFile, "DATA")
    
    if data then
        Setspawn.Points = util.JSONToTable(data) or {}
    else
        Setspawn.Points = {}
    end
end
hook.Add("Initialize", "LoadMapSetSpawns", LoadSetSpawn)

local function setSpawnPoint(ply)
    local steamID = ply:SteamID()
    local map = game.GetMap()

    Setspawn.Points[map] = Setspawn.Points[map] or {}
    Setspawn.Points[map][steamID] = Setspawn.Points[map][steamID] or {}

    local modelPos, eyeAngle = ply:GetPos(), ply:EyeAngles()
    local spawnIdentifier = getSpawnIdentifier(ply)

    Setspawn.Points[map][steamID][spawnIdentifier] = {modelPos, eyeAngle}

    Setspawn.Points[map][steamID][spawnIdentifier .. "_up"] = {modelPos + Vector(0, 0, 20), eyeAngle}
    Setspawn.Points[map][steamID][spawnIdentifier .. "_down"] = {modelPos - Vector(0, 0, 20), eyeAngle}

    SaveSetSpawn()

    NETWORK:StartNetworkMessageTimer(ply, "Print", {"Timer", "You have set a new spawn point!"})
    SendPopupNotification(ply, "Notification", "You have set a new spawn point!", 2)
end

local function SetspawnHandler(ply)
    if isValidSpawnPoint(ply) then
        setSpawnPoint(ply)
    end
end
Command:Register({"setspawn", "spawnpoint", "ss", "spawn"}, SetspawnHandler)

local function RemoveSpawnPoint(ply)
    local steamID = ply:SteamID()
    local map = game.GetMap()
    local spawnIdentifier = getSpawnIdentifier(ply)

    if Setspawn.Points[map] and Setspawn.Points[map][steamID] then
        Setspawn.Points[map][steamID][spawnIdentifier] = nil
        Setspawn.Points[map][steamID][spawnIdentifier .. "_up"] = nil
        Setspawn.Points[map][steamID][spawnIdentifier .. "_down"] = nil

        if table.IsEmpty(Setspawn.Points[map][steamID]) then
            Setspawn.Points[map][steamID] = nil
        end
        if table.IsEmpty(Setspawn.Points[map]) then
            Setspawn.Points[map] = nil
        end

        SaveSetSpawn()

        NETWORK:StartNetworkMessageTimer(ply, "Print", {"Timer", "Your spawn point has been removed!"})
        SendPopupNotification(ply, "Notification", "Your spawn point has been removed!", 2)
    else
        NETWORK:StartNetworkMessageTimer(ply, "Print", {"Timer", "You don't have a custom spawn point set!"})
        SendPopupNotification(ply, "Notification", "No custom spawn found to remove!", 2)
    end
end
Command:Register({"removess", "delspawn", "removespawn"}, RemoveSpawnPoint)