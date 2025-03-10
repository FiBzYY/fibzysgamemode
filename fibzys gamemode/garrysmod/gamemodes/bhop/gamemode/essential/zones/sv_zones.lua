--[[~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	📍 Bunny Hop Zones System
		by: fibzy (www.steamcommunity.com/id/fibzy_)

		file: sv_zones.lua
		desc: 🚧 Manages zones (start, end, checkpoints) for Bunny Hop gamemode.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~]]

local Iv = IsValid

util.AddNetworkString("SendZoneData")

Zones = Zones or {
    Type = {
        ["Normal Start"] = 0, ["Normal End"] = 1,
        ["Bonus Start"] = 2, ["Bonus End"] = 3,
        ["Anticheat"] = 4, ["Freestyle"] = 5,
        ["NormalAC"] = 6, ["BonusAC"] = 7,
        ["LegitSpeed"] = 100, ["SolidAC"] = 120,
        ["Helper"] = 130, ["Gravity Zone"] = 122, 
        ["Step Size"] = 123, ["Restart Zone"] = 124, 
        ["Booster Zone"] = 125, ["Full Bright"] = 126
    },

    Options = {
        NoStartLimit = 1, NoSpeedLimit = 2
    },

    StartPoint = nil,
    BonusPoint = nil,

    Entities = {},
    Cache = {},
    Editor = {},
    Extra = {}
}

-- Query
local sq = sql.Query
local math_min = math.min
local math_max = math.max

-- Setup
function Zones:Setup()
    self.StartPoint = nil
    self.BonusPoint = nil
    self.Entities = {}

    for _, zone in pairs(self.Cache) do
        if zone.Type >= self.Type["Helper"] then
            local extractedData = self:ExtractData(zone.Type)
            zone.Type = extractedData[1]
            zone.Data = extractedData[2]
        end

        local ent
        if zone.Type == self.Type["SolidAC"] then
            ent = self:CreateSolidBlockEnt(zone)
        elseif zone.Type == self.Type["Restart Zone"] then
            ent = self:CreateTeleportRestart(zone)
        elseif zone.Type == self.Type["Booster Zone"] then
            ent = self:CreateTeleportRestart(zone)
        elseif zone.Type == self.Type["Full Bright"] then
            ent = self:CreateTriggerFullBright(zone)
        else
            ent = self:CreateZoneEntity(zone)
        end

        if ent then
            self:AssignZonePoints(zone, ent)
            table.insert(self.Entities, ent)
        else
            UTIL:Notify(Color(255, 255, 0), "Zones", "Error: Failed to create entity for zone:", zone.Type)
        end
    end
end

function Zones:CreateZoneEntity(zone)
    local ent = ents.Create("ent_timer")
    if not Iv(ent) then return nil end

    local midpoint = (zone.P1 + zone.P2) / 2
    ent:SetPos(midpoint)
    ent.min = zone.P1
    ent.max = zone.P2
    ent.zonetype = zone.Type

    ent:Spawn()
    return ent
end

function Zones:CreateSolidBlockEnt(zone)
    local ent = ents.Create("ent_soild")
    if not Iv(ent) then return nil end

    local midpoint = (zone.P1 + zone.P2) / 2
    ent:SetPos(midpoint)

    ent.min = zone.P1
    ent.max = zone.P2
    ent.zonetype = zone.Type

    ent:SetNWInt("zonetype", zone.Type)

    ent:Spawn()
    return ent
end

function Zones:CreateTeleportRestart(zone)
    local ent = ents.Create("ent_restart")
    if not Iv(ent) then return nil end

    local midpoint = (zone.P1 + zone.P2) / 2
    ent:SetPos(midpoint)

    ent.min = zone.P1
    ent.max = zone.P2
    ent.zonetype = zone.Type

    ent:SetNWInt("zonetype", zone.Type)

    ent:Spawn()
    return ent
end

function Zones:CreateTriggerFullBright(zone)
    local ent = ents.Create("ent_fullbright")
    if not Iv(ent) then return nil end

    local midpoint = (zone.P1 + zone.P2) / 2
    ent:SetPos(midpoint)

    ent.min = zone.P1
    ent.max = zone.P2
    ent.zonetype = zone.Type

    ent:SetNWInt("zonetype", zone.Type)

    ent:Spawn()
    return ent
end

function Zones:CreateBoosterZone(zone)
    local ent = ents.Create("ent_booster")
    if not Iv(ent) then return nil end

    local midpoint = (zone.P1 + zone.P2) / 2
    ent:SetPos(midpoint)

    ent.min = zone.P1
    ent.max = zone.P2
    ent.zonetype = zone.Type

    ent:SetNWInt("zonetype", zone.Type)

    ent:Spawn()
    return ent
end

function Zones:AssignZonePoints(zone, ent)
    local midpoint = (zone.P1 + zone.P2) / 2
    if zone.Type == self.Type["Normal Start"] then
        self.StartPoint = {zone.P1, zone.P2, midpoint}
        self.BotPoint = Vector(midpoint[1], midpoint[2], zone.P1[3])
    elseif zone.Type == self.Type["Bonus Start"] then
        self.BonusPoint = {zone.P1, zone.P2, midpoint}
    end
end

-- Reload
function Zones:Reload()
    self:ClearEntities()
    TIMER:LoadZones()
    self:Setup()
end

function Zones:ClearEntities()
    for _, ent in pairs(self.Entities) do
        if IsValid(ent) then
            ent:Remove()
        end
    end
    self.Entities = {}
end

function Zones:GetName(nID)
    for name, id in pairs(self.Type) do
        if id == nID then
            return name
        end
    end
    return "Unknown"
end

function Zones:ExtractData(nType)
    local nID = tonumber(string.sub(nType, 1, 3))
    local nData = tonumber(string.sub(nType, 4))
    return {nID, nData}
end

function Zones:GetCenterPoint(nType)
    for _, zone in pairs(self.Entities) do
        if IsValid(zone) and zone.zonetype == nType then
            local pos = zone:GetPos()
            pos[3] = pos[3] - (zone.max[3] - zone.min[3]) / 2
            return pos
        end
    end
    return nil
end

function Zones:GetSpawnPoint(data)
    if not data or not data[1] or not data[3] then
        return Vector(0, 0, 0)
    end

    local groundOffset = 5

    return Vector(data[3][1], data[3][2], data[1][3] + groundOffset)
end

function Zones:IsInside(ply, nType)
    local pos = ply:GetPos()
    for _, zone in pairs(self.Entities) do
        if Iv(zone) and zone.zonetype == nType then
            if pos:WithinAABox(zone.min, zone.max) then
                return true
            end
        end
    end
    return false
end

function Zones:IsInArea(ply, vec, vec2)
    if not Iv(ply) then return false end

    local pos = ply:GetPos()

    if pos:WithinAABox(vec, vec2) then
        return true
    end

    return false
end

function Zones:StartSet(ply, ID)
    if self.Extra[ID] and not ply.ZoneExtra then
        ply.ZoneExtra = true
        BHDATA:Send(ply, "Print", {"Admin", "Automatically enabled 'Add Extra' for this zone."})
    end

    self.Editor[ply] = {Active = true, Type = ID}

    NETWORK:StartNetworkMessageTimer(ply, "Admin", {"EditZone", self.Editor[ply]})
    NETWORK:StartNetworkMessageTimer(ply, "Print", {"Admin", Lang:Get("ZoneStart")})
end

net.Receive("SendZoneData", function(len, ply)
    local zoneData = net.ReadTable()

    if zoneData and zoneData.Start and zoneData.End and zoneData.Type then
        Zones.Editor[ply] = {
            Start = zoneData.Start,
            End = zoneData.End,
            Type = zoneData.Type,
            Active = true
        }

        Zones:FinishSet(ply)
    else
        UTIL:Notify(Color(255, 255, 0), "Zones", "Error: Invalid zone data received from client!")
    end
end)

function Zones:FinishSet(ply, extra)
    local editor = self.Editor[ply]

    if editor and editor.Start and editor.End then
        self:SaveZoneToDatabase(editor)

        self:CancelSet(ply)
        self:Reload()

        if (editor.Type == self.Type["Bonus Start"] or editor.Type == self.Type["Bonus End"]) and not extra then
            self:ClearBonusRecords()
        end
    else
        UTIL:Notify(Color(255, 255, 0), "Zones", "Error: Missing Start or End point, or editor is inactive!")
    end
end

function Zones:CheckSet(ply, finish, extra)
    if self.Editor[ply] then
        if finish then
            if extra then
                ply.ZoneExtra = nil
            end
            self:FinishSet(ply, extra)
        end
        return true
    end

    return false
end

util.AddNetworkString("CancelZonePlacement")

function Zones:CancelSet(ply, force)
    self.Editor[ply] = nil

    NETWORK:StartNetworkMessageTimer(ply, "Admin", {"EditZone", nil})
    NETWORK:StartNetworkMessageTimer(ply, "Print", {"Admin", Lang:Get(force and "ZoneCancel" or "ZoneFinish")})

    net.Start("CancelZonePlacement")
    net.Send(ply)
end

function Zones:SaveZoneToDatabase(editor)
    local Min = util.TypeToString(Vector(
        math.min(editor.Start[1], editor.End[1]),
        math.min(editor.Start[2], editor.End[2]),
        math.min(editor.Start[3], editor.End[3])
    ))

    local Max = util.TypeToString(Vector(
        math.max(editor.Start[1], editor.End[1]),
        math.max(editor.Start[2], editor.End[2]),
        math.max(editor.Start[3] + BHOP.Zone.ZoneHeight, editor.End[3] + BHOP.Zone.ZoneHeight)
    ))

    if not game.GetMap() or not editor.Type or not Min or not Max then
        UTIL:Notify(Color(255, 255, 0), "Zones", "Error: Missing required values for SQL query.")
        return
    end

    local map = game.GetMap()
    local zoneType = editor.Type
    local selectQuery = "SELECT type FROM timer_zones WHERE map = '" .. map .. "' AND type = " .. zoneType


    MySQL:Start(selectQuery, function(result)
        if result and #result > 0 then
            local updateQuery = "UPDATE timer_zones SET pos1 = '" .. Min .. "', pos2 = '" .. Max .. "' WHERE map = '" .. map .. "' AND type = " .. zoneType
            MySQL:Start(updateQuery, function(updateResult)
                if not updateResult then
                    print("[ERROR] MySQL Update Failed: " .. sql.LastError())
                else
                    UTIL:Notify(Color(0, 255, 0), "Zones", "Zone updated successfully!")
                    ReloadZonesOnMapLoad()
                end
            end)
        else
            local insertQuery = "INSERT INTO timer_zones (map, type, pos1, pos2) VALUES ('" .. map .. "', " .. zoneType .. ", '" .. Min .. "', '" .. Max .. "')"
            MySQL:Start(insertQuery, function(insertResult)
                if not insertResult then
                    print("[ERROR] MySQL Insert Failed: " .. sql.LastError())
                else
                    UTIL:Notify(Color(0, 255, 0), "Zones", "New zone added successfully!")
                    ReloadZonesOnMapLoad()
                end
            end)
        end
    end)
end

function Zones:ClearBonusRecords()
    local bonusstyleID = TIMER:GetStyleID("bonus")
    sq("DELETE FROM timer_times WHERE map = '" .. game.GetMap() .. "' AND style = " .. bonusstyleID)
    TIMER:LoadRecords()
end

function Zones:FindNearestSpawn(at, tab)
    if not at or not tab then return nil end

    local order = {}
    for _, v in pairs(tab) do
        local distance = (at - v[1]):Length()
        table.insert(order, {Dist = distance, Vec = v[1], Ang = v[2]})
    end

    table.SortByMember(order, "Dist", true)

    for i = 1, #order do
        local tr = util.TraceLine({start = at, endpos = order[i].Vec})
        if not tr.HitWorld then
            return order[i]
        end
    end

    return order[1]
end

function Zones:AssignBonusAngles()
    TIMER.BonusAngles = {}

    for _, zone in pairs(self.Entities) do
        if Iv(zone) and zone.zonetype == Zones.Type["Bonus Start"] then
            local bonusPoint = (zone.min + zone.max) / 2
            local near = FindNearestSpawn(bonusPoint, tps)

            if near then
                TIMER.BonusAngles[1] = near.Ang
            end
            break
        end
    end
end

function Zones:PermanentFixes()
    for _, ent in pairs(ents.GetAll()) do
        if Iv(ent) then
            ent:SetRenderMode(RENDERMODE_TRANSALPHA)
        end
    end
end

function Zones:SetupMap()
    if self.MapSetup then return end
    self.MapSetup = true
    self:PermanentFixes()

    self:RemoveHooks()
    self:SetupEntities()
end

function Zones:RemoveHooks()
    hook.Remove("PreDrawHalos", "PropertiesHover")
    hook.Remove("PlayerPostThink", "ProcessFire")
end

function Zones:SetupEntities()
    for _, ent in pairs(ents.FindByClass("func_lod")) do
        ent:SetRenderMode(RENDERMODE_TRANSALPHA)
    end

    for _, ent in pairs(ents.FindByClass("env_hudhint")) do
        ent:Remove()
    end

    for _, ent in pairs(ents.GetAll()) do
        if ent:GetRenderFX() ~= 0 and ent:GetRenderMode() == 0 then
            ent:SetRenderMode(RENDERMODE_TRANSALPHA)
        end
    end

    self:SetupFuncDoors()
    self:SetupFuncButtons()
end

function Zones:SetupFuncDoors()
    for _, ent in pairs(ents.FindByClass("func_door")) do
        if not ent.IsP then continue end
        local mins = ent:OBBMins()
        local maxs = ent:OBBMaxs()
        local height = maxs[3] - mins[3]
        if height > 80 then continue end
        local tab = ents.FindInBox(ent:LocalToWorld(mins) - Vector(0, 0, 10), ent:LocalToWorld(maxs) + Vector(0, 0, 5))
        if tab or ent.BHSp > 100 then
            self:LockDoor(ent, tab)
        end
    end
end

function Zones:LockDoor(ent, tab)
    local teleport = nil
    for _, v2 in pairs(tab) do
        if Iv(v2) and v2:GetClass() == "trigger_teleport" then
            teleport = v2
        end
    end
    if teleport or ent.BHSp > 100 then
        ent:Fire("Lock")
        ent:SetKeyValue("spawnflags", "1024")
        ent:SetKeyValue("speed", "0")
        ent:SetRenderMode(RENDERMODE_TRANSALPHA)
        ent:SetKeyValue("locked_sound", ent.BHS or "DoorSound.DefaultMove")
        ent:SetNWInt("Platform", 1)
    end
end

function Zones:SetupFuncButtons()
    for _, ent in pairs(ents.FindByClass("func_button")) do
        if not ent.IsP then continue end
        if ent.SpawnFlags == "256" then
            local mins = ent:OBBMins()
            local maxs = ent:OBBMaxs()
            local tab = ents.FindInBox(ent:LocalToWorld(mins) - Vector(0, 0, 10), ent:LocalToWorld(maxs) + Vector(0, 0, 5))
            if tab then
                self:LockButton(ent, tab)
            end
        end
    end
end

function Zones:LockButton(ent, tab)
    local teleport = nil
    for _, v2 in pairs(tab) do
        if IsValid(v2) and v2:GetClass() == "trigger_teleport" then
            teleport = v2
        end
    end
    if teleport then
        ent:Fire("Lock")
        ent:SetKeyValue("spawnflags", "257")
        ent:SetKeyValue("speed", "0")
        ent:SetRenderMode(RENDERMODE_TRANSALPHA)
        ent:SetKeyValue("locked_sound", ent.BHS or "None (Silent)")
        ent:SetNWInt("Platform", 1)
    end
end

__HOOK = __HOOK or {}
__MAP = __MAP or {}

local function includeIfExists(filePath)
    if file.Exists(filePath, "LUA") then
        include(filePath)
    end
end

includeIfExists("bhop/gamemode/maps/wildcard.lua")
includeIfExists("bhop/gamemode/maps/disable_sprites.lua")
-- includeIfExists("bhop/gamemode/maps/.lua")
includeIfExists("bhop/gamemode/maps/" .. game.GetMap() .. ".lua")

for identifier, func in pairs(__HOOK) do
    local hookName = identifier .. "_" .. game.GetMap()
    hook.Add(identifier, hookName, func)
end

for identifier, bool in pairs(__MAP) do
    if bool == nil then
        return
    end

    if identifier ~= "CustomEntitySetup" then
        Zones[identifier] = Zones[identifier] or {}
        Zones[identifier][game.GetMap()] = bool
    else
        Zones[identifier] = bool
        UTIL:Notify(Color(255, 255, 0), "Zones", "Handled CustomEntitySetup for identifier:", identifier)
        break
    end
end