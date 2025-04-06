SSJTOP = SSJTOP or {}

-- Cache system
local hook_Add, Iv = hook.Add, IsValid
local util_TableToJSON, util_JSONToTable = util.TableToJSON, util.JSONToTable
local file_Write, file_Read, file_Exists = file.Write, file.Read, file.Exists
local ipairs, IsValid, timer_Create, timer_Start = ipairs, IsValid, timer.Create, timer.Start
local ents_FindByClass = ents.FindByClass

playerDuckStatus = {}

if SERVER then
    util.AddNetworkString("SSJTOP_RemoveRecord")

    function SaveSSJToMySQL(ply, ssjType, jumpSpeed)
        if not Iv(ply) then return end

        local steamID = ply:SteamID()

        local query = string.format([[
            INSERT INTO ssjtop_records (steamid, type, jumpspeed)
            VALUES ('%s', '%s', %f)
            ON DUPLICATE KEY UPDATE jumpspeed = GREATEST(jumpspeed, %f)
        ]],
            steamID, ssjType, jumpSpeed, jumpSpeed
        )

        MySQL:Start(query, function(result)
            if result then
                 UTIL:Notify(Color(255, 0, 255), "SSJTop", "MySQL saved for " .. steamID .. " (" .. ssjType .. ")")
            else
                 UTIL:Notify(Color(255, 0, 255), "SSJTop", "Failed MySQL save for " .. steamID)
            end
        end)
    end

    net.Receive("SSJTOP_RemoveRecord", function(len, ply)
        if not Iv(ply) or not ply:IsAdmin() then return end

        local playerName = net.ReadString()
        local steamID64 = net.ReadString()

        if not steamID64 or steamID64 == "" then
            UTIL:Notify(Color(255, 0, 255), "SSJTop", "Invalid SteamID64 provided.")
            return
        end

        local steamID = util.SteamIDFrom64(steamID64)
        if not steamID then
            UTIL:Notify(Color(255, 0, 255), "SSJTop", "Failed to convert SteamID64.")
            return
        end

        -- Wipe from memory
        SSJTOP[steamID64] = nil

        -- MySQL DELETE
        local query = string.format("DELETE FROM ssjtop_records WHERE steamid = '%s'", steamID)
        MySQL:Start(query, function(result)
            if result then
                UTIL:Notify(Color(255, 0, 255), "SSJTop", "Successfully deleted record for " .. playerName)
            else
                UTIL:Notify(Color(255, 0, 255), "SSJTop", "Failed to delete SSJTop record for " .. playerName)
            end
        end)
    end)

    -- Fetch top SSJ from database when player joins
    hook.Add("PlayerInitialSpawn", "SSJTop_LoadFromDB", function(ply)
        if not IsValid(ply) or not ply:IsPlayer() or ply:IsBot() then return end

        local steamID = ply:SteamID()
        local steamID64 = ply:SteamID64()

        local query = string.format("SELECT * FROM ssjtop_records WHERE steamid = '%s'", steamID)
        MySQL:Start(query, function(results)
            if results and istable(results) then
                 SSJTOP[steamID64] = SSJTOP[steamID64] or { duck = 0, normal = 0, name = ply:Nick() }
                 SSJTOP[steamID64].name = ply:Nick()

                for _, row in ipairs(results) do
                    local ssjType = row.type
                    local speed = tonumber(row.jumpspeed) or 0
                    if SSJTOP[steamID64][ssjType] == nil or speed > SSJTOP[steamID64][ssjType] then
                        SSJTOP[steamID64][ssjType] = speed
                    end
                end
            end
        end)
    end)
end

-- Crouch Status Before Jump
hook_Add("StartCommand", "TrackDuckDuringJumps", function(ply)
    if not Iv(ply) then return end

    if ply:IsOnGround() then
        playerDuckStatus[ply:SteamID()] = ply:Crouching()
    end
end)

-- Teleport
local function SSJTOP_OnPlayerTeleported(ent, input, activator)
    if input == "teleported" and Iv(activator) and activator:IsPlayer() then
        gB_IllegalSSJ[activator] = true
    end
end
hook_Add("AcceptInput", "SSJTOP_OnPlayerTeleported", SSJTOP_OnPlayerTeleported)

-- Teleport Triggers
hook_Add("InitPostEntity", "SSJTOP_HandleNewTeleports", function()
    for _, ent in ipairs(ents_FindByClass("trigger_teleport")) do
        ent:Fire("AddOutput", "OnStartTouch !activator:teleported:0:0:-1")
        ent:Fire("AddOutput", "OnEndTouch !activator:teleported:0:0:-1")
    end
end)

-- Ground Trace
local function TracePlayerGround(ply)
    if not Iv(ply) or not ply:Alive() or ply:GetMoveType() ~= MOVETYPE_WALK or ply:WaterLevel() > 1 then return nil end

    local origin, mins, maxs = ply:GetPos(), ply:GetHull()

    return util.TraceHull({
        start = origin,
        endpos = origin - Vector(0, 0, 2),
        mins = mins,
        maxs = maxs,
        mask = MASK_PLAYERSOLID,
        filter = ply
    })
end

-- Slope Detection
function IsPlayerOnSlope(ply)
    local tr = TracePlayerGround(ply)
    if tr and tr.Hit and tr.HitNormal.z < 0.99 then
        gB_IllegalSSJ[ply] = true
    end
end

-- Ground Units
function GetGroundUnits(ply)
    if ply:GetNWInt("inPractice", true) then
        gB_IllegalSSJ[ply] = true
        return 0
    end

    local tr = TracePlayerGround(ply)
    return tr and tr.Hit and (ply:GetPos().z - tr.HitPos.z + 0.03125) or 0
end

hook_Add("SetupMove", "CheckPlayerOnSlope", function(ply)
    if Iv(ply) and ply:Alive() and ply:GetMoveType() == MOVETYPE_WALK then
        IsPlayerOnSlope(ply)
        GetGroundUnits(ply)
    end
end)