Player = {
    MultiplierNormal = 1, MultiplierAngled = 1,
    LadderScalar = 1.30,
    NormalScalar = 0.1,
    AngledScalar = 0.1
}

function TIMER:Initialize()
    self.PlayerJumps = {}
    self.Query = {}
    self.QuerySize = 0
end

-- Cache
local lp = LocalPlayer
local Iv = IsValid
local ct = CurTime
local hook_Add = hook.Add
local string_sub = string.sub
local math_floor = math.floor

-- Network
util.AddNetworkString("SyncPlayerData")
util.AddNetworkString("SyncFOV")
util.AddNetworkString("FOVStateChanged")
util.AddNetworkString("UpdatePointsSum")

PlayerJumps = PlayerJumps or {}
playerTimescales = playerTimescales or {}

-- networked jump count
function IncrementJumpCounter(ply)
    if not PlayerJumps[ply] then
        PlayerJumps[ply] = 0
    end

    PlayerJumps[ply] = PlayerJumps[ply] + 1

    local observers = {ply}
    for _, v in ipairs(player.GetHumans()) do
        if IsValid(v:GetObserverTarget()) and v:GetObserverTarget() == ply then
            table.insert(observers, v)
        end
    end

    NETWORK:StartNetworkMessageTimer(observers, "JumpUpdate", {ply, PlayerJumps[ply]})
end

local botmodel = "models/player/ct_gsg9.mdl"
local playermodel = "models/player/ct_gsg9.mdl"

function TIMER:Spawn(ply)
    if not Iv(ply) then return end
    ply:SetHull(Vector(-16, -16, 0), Vector(16, 16, BHOP.Move.EyeView))
    ply:SetHullDuck(Vector(-16, -16, 0), Vector(16, 16, BHOP.Move.EyeDuck))
    ply:SetViewOffset(Vector(0, 0, BHOP.Move.OffsetView))
    ply:SetViewOffsetDucked(Vector(0, 0, BHOP.Move.OffsetDuck))

    if ply:IsBot() then
        ply:SetModel(botmodel)
        ply:DrawShadow(false)
        ply:SetMoveType(MOVETYPE_NONE)
        ply:SetFOV(100, 0)
        ply:SetGravity(0)

        ply:SetRenderMode(RENDERMODE_TRANSALPHA)
        ply:SetColor(Color(255, 255, 255, 150))

        return
    end

    ply:SetModel(playermodel)
    ply:SetTeam(1)
    ply:DrawShadow(false)
    ply:SetJumpPower(jumppower:GetFloat())
    ply:SetStepSize(18)
    ply:SetWalkSpeed(walkspeed:GetFloat())
    ply:SetNoCollideWithTeammates(true)
    ply:SetAvoidPlayers(false)

    ply:SetMoveType(MOVETYPE_CUSTOM)
    ply:SetCollisionGroup(COLLISION_GROUP_PLAYER_MOVEMENT)

    if ply.style == TIMER:GetStyleID("bonus") then
        self:BonusReset(ply)
    else
        self:ResetTimer(ply)
    end

    self:SpawnChecks(ply)
end

function TIMER:ResetPlayerAttributes(ply, previous, start)
    if ply.style == TIMER:GetStyleID("LG") then
        ply:SetGravity(0.6)
    elseif ply.style == TIMER:GetStyleID("HG") then
        ply:SetGravity(1.4)
    elseif ply.style == TIMER:GetStyleID("MOON") then
        ply:SetGravity(0.1)
    elseif ply:GetGravity() != 0 then
        ply:SetGravity(0)
    end

    --[[if ply.style == TIMER:GetStyleID("Stamina") and ply.style == TIMER:GetStyleID("legit") then
        STAMINA_USE[ply] = true
    else
        STAMINA_USE[ply] = false
    end--]]
end

local LastPlayerAngles = {}
function TIMER:SpawnChecks(ply)
    self:SetJumps(ply, 0)
   	self:ResetPlayerAttributes(ply)

    local steamID = ply:SteamID()
    local map = game.GetMap()
    local isBonus = TIMER and TIMER.GetStyleID and (ply.style == TIMER:GetStyleID("bonus"))
    local index = Setspawn.Points[map] and Setspawn.Points[map][steamID] and Setspawn.Points[map][steamID][isBonus and 2 or 0]

    local spawnPos
    if index then
        spawnPos = index[1]
        ply:SetEyeAngles(index[2])
    elseif Zones and Zones.GetSpawnPoint then
        spawnPos = Zones:GetSpawnPoint(isBonus and Zones.BonusPoint or Zones.StartPoint)
    else
        spawnPos = Vector(0, 0, 0)
    end

    ply:SetPos(spawnPos)

    if not ply:IsBot() and ply:GetMoveType() ~= MOVETYPE_WALK then
        ply:SetMoveType(MOVETYPE_WALK)
    end
end

-- FoV
--[[local default_fov = 90
local fov_data_path = "fov_data/"
local playerFOVState = {}

if not file.IsDir(fov_data_path, "DATA") then
    file.CreateDir(fov_data_path)
end

local function SavePlayerFOV(ply, fov)
    local steam_id = ply:SteamID64()
    file.Write(fov_data_path .. steam_id .. ".txt", tostring(fov))
end

local function LoadPlayerFOV(ply)
    local steam_id = ply:SteamID64()
    if file.Exists(fov_data_path .. steam_id .. ".txt", "DATA") then
        local fov = tonumber(file.Read(fov_data_path .. steam_id .. ".txt", "DATA"))
        return fov and fov >= 1 and fov <= 180 and fov or default_fov
    else
        return default_fov
    end
end

hook_Add("PlayerInitialSpawn", "LoadFOVOnJoin", function(ply)
    local steam_id = ply:SteamID64()
    if playerFOVState[steam_id] == nil then
        playerFOVState[steam_id] = true
    end

    local saved_fov = LoadPlayerFOV(ply)
    
    timer.Simple(2, function()
        if IsValid(ply) and playerFOVState[steam_id] then
            local fov_to_set = saved_fov or default_fov
            ply:SetFOV(fov_to_set, 0.2)
            
            net.Start("SyncFOV")
            net.WriteInt(fov_to_set, 32)
            net.Send(ply)
        end
    end)
end)

net.Receive("SyncFOV", function(len, ply)
    local steam_id = ply:SteamID64()

    if playerFOVState[steam_id] == false then
        return
    end

    local new_fov = math.Clamp(net.ReadInt(32) or default_fov, 1, 180)
    if new_fov < 1 or new_fov > 180 then
        new_fov = default_fov
    end

    ply:SetFOV(new_fov, 0.2)
    SavePlayerFOV(ply, new_fov)
end)

hook_Add("PlayerDisconnected", "ResetFOVOnDisconnect", function(ply)
    ply:SetFOV(default_fov, 0.2)
    playerFOVState[ply:SteamID64()] = nil
end)--]]

-- What gets loaded when the player spawns
function TIMER:Load(ply)
    ply:SetTeam(1)

    ply.style = TIMER:GetStyleID("Normal")
    ply.record, ply.Rank = 0, -1

    ply:SetNWInt("Style", ply.style)
    ply:SetNWFloat("Record", ply.record)
    ply:SetNWBool("duckUntilOnGround", false)

    timer.Simple(0.1, function()
        if IsValid(ply) then
            NETWORK:StartNetworkMessage(ply, "UpdateSingleVar", ply, "style", ply.style)
        end
    end)

    if ply:IsBot() then
        ply.Temporary, ply.Rank = true, -2
        ply:SetMoveType(MOVETYPE_NONE)
        ply:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)

        ply:SetFOV(104, 0)
        ply:SetGravity(0)
        ply:SetNWInt("Rank", ply.Rank)

        return
    end

    timer.Simple(1, function()
        self:LoadBest(ply)
    end)

    self:LoadRank(ply)
    self:SendInitialRecords(ply)

    if Admin and Admin.CheckPlayerStatus then
        Admin:CheckPlayerStatus(ply)
    end

    if Replay and Replay.StartRecording then
        Replay:StartRecording(ply)
    end

    if SYNC and SYNC.Monitor then
        SYNC:Monitor(ply, true)
    end

    TIMER:UpdateWRs(ply)
    UTIL:GetPlayerCountryByIP(ply)

    local currentMonth = os.date("%b")

    if currentMonth == "Oct" then
        BHDATA:Broadcast("Print", { "Server", TIMER:RedToBlackFade("Happy Halloween!") })
    end

    BHDATA:Broadcast("Print", { "Server", "Gamemode loaded (" .. BHOP.Version.GM .. ")." })

    local connectionCount = ply:GetPData("connectionv2", 0)
    connectionCount = connectionCount + 1
    ply:SetPData("connectionv2", connectionCount)

    BHDATA:Broadcast("Print", { "Server", ply:Nick() .. " has connected " .. connectionCount .. " times." })
end

-- Load the style
function TIMER:LoadStyle(ply, style)
    ply.style, ply.record = style, 0
    Command:PerformRestart(ply)

    self:LoadBest(ply)
    self:LoadRank(ply, true)

    ply:SetNWInt("Style", ply.style)
    ply:SetNWFloat("Record", ply.record)

   	self:ResetPlayerAttributes(ply, ply.style)

    timer.Simple(0.1, function()
        if IsValid(ply) then
            NETWORK:StartNetworkMessage(ply, "UpdateSingleVar", ply, "style", ply.style)
        end
    end)

    NETWORK:StartNetworkMessageTimer(ply, "Print", {"Timer", Lang:Get("StyleChange", {TIMER:StyleName(ply.style)})})
end

-- Load the rank
function TIMER:LoadRank(ply, update)
    self:CachePointSum(ply.style, ply:SteamID())
    local nSum = self:GetPointSum(ply.style, ply:SteamID())
    local nRank = self:GetRank(nSum, self:GetRankType(ply.style, true))

    ply.RankSum = nSum

    if nRank ~= ply.Rank then
        ply.Rank = nRank
        ply:SetNWInt("Rank", ply.Rank)
    end

    self:SetSubRank(ply, nRank, nSum)
    
    if not update then
        NETWORK:StartNetworkMessageTimer(ply, "Timer", {"Ranks", Player.NormalScalar, Player.AngledScalar})
    end
end

-- Load the players best time and WRs
function TIMER:LoadBest(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    local practicestyleID = TIMER:GetStyleID("practice")

    if ply.style == practicestyleID then
        if not IsValid(ply) then return end
        ply:SetNWFloat("Record", ply.record)
        ply.SpecialRank = 0
        ply:SetNWInt("SpecialRank", ply.SpecialRank)

        TIMER:SetRecord(ply, ply.record, ply.style)

        if IsValid(ply) then
            return NETWORK:StartNetworkMessage(ply, "TIMER/Record", ply, ply.record, ply.style)
        else
            return
        end
    end

    if not IsValid(ply) then return end

    MySQL:Start("SELECT t1.time, (SELECT COUNT(*) + 1 FROM timer_times AS t2 WHERE map = '" .. game.GetMap() ..
        "' AND t2.time < t1.time AND style = " .. ply.style .. ") AS nRank FROM timer_times AS t1 WHERE t1.uid = '" ..
        ply:SteamID() .. "' AND t1.style = " .. ply.style .. " AND t1.map = '" .. game.GetMap() .. "'", function(Fetch)
        
        if not IsValid(ply) then return end

        if self:Assert(Fetch, "time") then
            local recordTime = tonumber(Fetch[1].time)
            ply.record = recordTime
            ply:SetNWFloat("Record", recordTime)

            TIMER:SetRecord(ply, recordTime, ply.style)
            NETWORK:StartNetworkMessage(ply, "TIMER/Record", ply, recordTime, ply.style)

            ply.SpecialRankMap = tonumber(Fetch[1].nRank)
            ply:SetNWInt("SpecialRankMap", ply.SpecialRankMap)
        else
            ply.record = 0
            ply:SetNWFloat("Record", ply.record)

            TIMER:SetRecord(ply, 0, ply.style)
            NETWORK:StartNetworkMessage(ply, "TIMER/Record", ply, 0, ply.style)

            ply.SpecialRankMap = 0
            ply:SetNWInt("SpecialRankMap", ply.SpecialRankMap)
        end
    end)

    if not IsValid(ply) then return end

    MySQL:Start(
        "SELECT map, time FROM timer_times AS t1 WHERE uid = '" .. ply:SteamID() ..
        "' AND style = " .. ply.style .. " AND " ..
        "(SELECT COUNT(*) FROM timer_times AS t2 WHERE t1.map = t2.map AND t2.time < t1.time AND t2.style = t1.style) = 0",
        function(Fetch)
            if not IsValid(ply) then return end

            if Fetch and #Fetch > 0 then
                ply.FirstPlaceTimes = {}

                for _, record in ipairs(Fetch) do
                    table.insert(ply.FirstPlaceTimes, {Map = record.map, Time = tonumber(record.time)})
                end

                ply.SpecialRank = #Fetch
                ply:SetNWInt("SpecialRank", ply.SpecialRank)

                NETWORK:StartNetworkMessage(ply, "TIMER/RecordList", ply.FirstPlaceTimes)
            else
                ply.FirstPlaceTimes = {}
                ply.SpecialRank = 0
                ply:SetNWInt("SpecialRank", ply.SpecialRank)

                NETWORK:StartNetworkMessage(ply, "TIMER/RecordList", {})
            end
        end
    )
end

Player.Points = {}

function TIMER:CachePointSum(style, id, callback)
    MySQL:Start("SELECT SUM(points) AS nSum FROM timer_times WHERE uid = '" .. id .. "' AND (" .. self:GetMatchingstyles(style) .. ")", function(data)
        if data and data[1] and data[1].nSum then
            local pointSum = tonumber(data[1].nSum) or 0
            Player.Points[id] = Player.Points[id] or {}
            Player.Points[id][style] = pointSum

            if callback then
                callback(pointSum)
            end
        else
            UTIL:Notify(Color(255, 0, 0), "Database Error", "No users to fetch points for:", id)
        end
    end)
end

function TIMER:GetPointSum(style, id)
    return (Player.Points[id] and Player.Points[id][style]) and Player.Points[id][style] or 0
end

-- Get the players rank
function TIMER:GetRank(points, type)
    local Rank = -1

    for RankID, Data in ipairs(TIMER.Ranks) do
        if RankID >= 0 then
            local rankThreshold = Data[3]
            if points >= rankThreshold then
                Rank = RankID
            else
                break
            end
        end
    end

    return Rank
end

-- Load the players rank
function TIMER:LoadRank(ply, update)
    self:CachePointSum(ply.style, ply:SteamID(), function()
        local nSum = self:GetPointSum(ply.style, ply:SteamID())
        local nRank = self:GetRank(nSum, self:GetRankType(ply.style, true))

        if nRank ~= ply.Rank then
            ply.Rank = nRank
            ply:SetNWInt("Rank", ply.Rank)
        end

        self:SetSubRank(ply, nRank, nSum)

        ply.nSum = nSum

        net.Start("UpdatePointsSum")
        net.WriteInt(nSum, 32)
        net.Send(ply)

        if not update then
            NETWORK:StartNetworkMessageTimer(ply, "Timer", {"Ranks", Player.NormalScalar, Player.AngledScalar})
        end
    end)
end

function TIMER:SetSubRank(ply, rank, points)
    if rank >= #TIMER.Ranks then
        local targetRank = 10
        if ply.SubRank ~= targetRank then
            ply.SubRank = targetRank
            ply:SetNWInt("SubRank", ply.SubRank)
        end
        return
    end

    local pointsInCurrentRank = TIMER.Ranks[rank][3]
    local pointsInNextRank = TIMER.Ranks[rank + 1][3]
    local stepSize = (pointsInNextRank - pointsInCurrentRank) / 10

    local subRank = math.ceil((points - pointsInCurrentRank) / stepSize)

    subRank = math.Clamp(subRank, 1, 10)

    if ply.SubRank ~= subRank then
        ply.SubRank = subRank
        ply:SetNWInt("SubRank", ply.SubRank)
    end
end

function TIMER:ReloadSubRanks(ply, old)
    local nMultiplier = self:GetMultiplier(ply.style)
    if not nMultiplier or nMultiplier == 0 then return end
    
    local nAverage = self:GetAverage(ply.style)
    if not nAverage or not old then return end

    for _, p in ipairs(player.GetHumans()) do
        if p == ply or p.Style ~= ply.style or not p.RankSum or not p.Rank or not p.Record or p.Record == 0 then
            continue
        end

        local nCurrent = nMultiplier * (old / p.Record)
        local nNew = nMultiplier * (nAverage / p.Record)
        local nPoints = p.RankSum - nCurrent + nNew

        local nRank = self:GetRank(nPoints, Player:GetRankType(p.Style, true))
        if nRank ~= p.Rank then
            p.Rank = nRank
            p:SetNWInt("Rank", p.Rank)
        end

        p.RankSum = nPoints
        Player:SetSubRank(p, p.Rank, p.RankSum)
    end
end

function TIMER:SetRankMedal(ply, nPos)
    MySQL:Start("SELECT t1.uid, (SELECT COUNT(*) + 1 FROM timer_times AS t2 WHERE map = '" .. game.GetMap() .. "' AND t2.time < t1.time AND style = " .. ply.style .. ") AS nRank FROM timer_times AS t1 WHERE t1.map = '" .. game.GetMap() .. "' AND t1.style = " .. ply.style .. " ORDER BY nRank ASC LIMIT 100", function(Query)
        if self:Assert(Query, "uid") then
            for _, p in pairs(player.GetHumans()) do
                if p.style ~= ply.style then continue end
                local bSet = false
                for _, d in pairs(Query) do
                    if p:SteamID() == d.uid then
                        bSet = true
                        p.SpecialRank = tonumber(d.nRank) > 3 and 0 or tonumber(d.nRank)
                        p:SetNWInt("SpecialRank", p.SpecialRank)
                    end
                end
                if not bSet and p.SpecialRank then
                    p.SpecialRank = 0
                    p:SetNWInt("SpecialRank", p.SpecialRank)
                end
            end
        end
    end)
end

function TIMER:UpdateRank(ply)
    self:LoadRank(ply, true)
end

-- Add scores
function TIMER:AddScore(ply)
	ply:AddFrags(1)
end

function TIMER:GetMatchingstyles(style)
    local baseStyles = { 
        self:GetStyleID("Normal"), 
        self:GetStyleID("E"), 
        self:GetStyleID("Legit"), 
        self:GetStyleID("Bonus"), 
        self:GetStyleID("Practice") 
    }

    local advancedStyles = { 
        self:GetStyleID("Sideways"), 
        self:GetStyleID("Half-Sideways"), 
        self:GetStyleID("WOnly"), 
        self:GetStyleID("AOnly") 
    }

    for _, styleID in ipairs(baseStyles) do
        if styleID == 0 then
        end
    end

    for _, styleID in ipairs(advancedStyles) do
        if styleID == 0 then
        end
    end

    local tab = baseStyles
    if style >= self:GetStyleID("Sideways") and style <= self:GetStyleID("AOnly") then
        tab = advancedStyles
    end

    local t = {}
    for _, styleID in ipairs(tab) do
        if styleID and styleID > 0 then
            table.insert(t, "style = " .. styleID)
        else
        end
    end

    if #t == 0 then
        return "style = 1"
    end

    return string.Implode(" OR ", t)
end

function TIMER:FindScalar(nMultiplier)
    local count = #self.Ranks
    local sum = nMultiplier * Player.LadderScalar
    return (sum / count) ^ 0.33333
end

function TIMER:GetRankType(style, num)
    local swstyleID = self:GetStyleID("Sideways")
    local aOnlystyleID = self:GetStyleID("AOnly")
    local isAdvancedStyle = (style >= swstyleID and style <= aOnlystyleID)
    
    return num and (isAdvancedStyle and 4 or 3) or isAdvancedStyle
end

function TIMER:GetOnlineVIPs()
    local tabVIP = {}
    for _, p in pairs(player.GetHumans()) do
        if p.IsVIP then table.insert(tabVIP, p) end
    end
    return tabVIP
end

TIMER.PageSize = 7
TIMER.TopCache = {}
TIMER.TopLimit = 10

local function CacheTopPlayers(result, cache, style)
    if TIMER:Assert(result, "nSum") then
        for i, d in ipairs(result) do
            if d.nStyle == style then
                cache[style][i] = { string_sub(d.szPlayer, 1, 20), math_floor(tonumber(d.nSum)) }
            end
        end

        TIMER:ClearOldCache(cache[style], TIMER.TopLimit)
    end
end

function TIMER:ClearOldCache(cache, maxEntries)
    while table.Count(cache) > maxEntries do
        table.remove(cache, 1)
    end
end

-- Load top times
function TIMER:LoadTop()
    local nNormal = self:GetRankType(self:GetStyleID("normal"), true)
    local nAngled = self:GetRankType(self:GetStyleID("sideways"), true)

    self.TopCache[nNormal], self.TopCache[nAngled] = {}, {}

    MySQL:Start("SELECT player, SUM(points) as nSum, style FROM timer_times WHERE style IN (" .. nNormal .. ", " .. self:GetStyleID("bonus") .. ") GROUP BY uid ORDER BY nSum DESC LIMIT " .. self.TopLimit, function(Normal)
        CacheTopPlayers(Normal, self.TopCache, nNormal)
        TIMER:ClearOldCache(self.TopCache[nNormal], TIMER.TopLimit)
    end)

    MySQL:Start("SELECT player, SUM(points) as nSum, style FROM timer_times WHERE style IN (" .. self:GetStyleID("sideways") .. ", " .. self:GetStyleID("halfsideways") .. ") GROUP BY uid ORDER BY nSum DESC LIMIT " .. self.TopLimit, function(Angled)
        CacheTopPlayers(Angled, self.TopCache, nAngled)
        TIMER:ClearOldCache(self.TopCache[nAngled], TIMER.TopLimit)
    end)
end

function TIMER:GetTopPage(page, style)
    local tab, Number = {}, self:GetRankType(style, true)
    for i = self.PageSize * page - self.PageSize + 1, self.PageSize * page do
        if self.TopCache[Number][i] then
            tab[i] = self.TopCache[Number][i]
        end
    end
    return tab
end

function TIMER:GetTopCount(style)
    return #self.TopCache[self:GetRankType(style, true)]
end

function TIMER:SendTopList(ply, page, type)
    local style = type == 4 and self:GetStyleID("sideways") or self:GetStyleID("normal")

    local topPage = self:GetTopPage(page, style)
    local topCount = self:GetTopCount(style)
    
    NETWORK:StartNetworkMessageTimer(ply, "GUI_Update", { "Top", { 4, topPage, page, topCount, type } })
end

-- Get the players finished maps
function TIMER:GetMapsBeat(ply, callback)
    local steamID = ply:SteamID()
    local style = ply.style
    local query = string.format("SELECT map, time, points FROM timer_times WHERE uid = '%s' AND style = %d ORDER BY points ASC", steamID, style)

    MySQL:Start(query, function(List)
        local tab = {}

        if self:Assert(List, "map") then
            for _, d in pairs(List) do
                table.insert(tab, {
                    d.map,
                    tonumber(d.nTime),
                    tonumber(d.nPoints)
                })
            end
        end

        NETWORK:StartNetworkMessageTimer(ply, "GUI_Open", { "Maps", { callback, tab } })
    end)
end

Player.RemoteWRCache = {}

function TIMER:SendRemoteWRList(ply, mapName, styleID, page, isUpdate)
    if not mapName or type(mapName) ~= "string" or not styleID or type(styleID) ~= "number" then 
        return 
    end

    if mapName == game.GetMap() then
        return UI:SendToClient(ply, "wr", self:GetRecordList(styleID, page), styleID, page, self:GetRecordCount(styleID))
    end

    local remoteCache = self.RemoteWRCache[mapName]
    local pageSize = self.PageSize

    if not remoteCache or not remoteCache[styleID] then
        if not RTV:MapExists(mapName) then
            return NETWORK:StartNetworkMessageTimer(ply, "Print", {"Timer", Lang:Get("MapUnavailable", {mapName})})
        end

        MySQL:Start("SELECT * FROM timer_times WHERE map = '" .. MySQL:Escape(mapName) .. "' AND style = " .. MySQL:Escape(styleID) .. " ORDER BY time ASC", function(result)
            if not self.RemoteWRCache[mapName] then
                self.RemoteWRCache[mapName] = {}
            end
            self.RemoteWRCache[mapName][styleID] = {}

            if self:Assert(result, "szUID") then
                for _, data in pairs(result) do
                    table.insert(self.RemoteWRCache[mapName][styleID], {
                        data.szUID, 
                        data.szPlayer, 
                        tonumber(data.nTime), 
                        self:Null(data.szDate), 
                        self:Null(data.vData)
                    })
                end
            end

            self:SendPaginatedWRList(ply, mapName, styleID, page, isUpdate)
        end)

        return
    end

    self:SendPaginatedWRList(ply, mapName, styleID, page, isUpdate)
end

-- UI page data
function TIMER:SendPaginatedWRList(ply, mapName, styleID, page, isUpdate)
    local cache = self.RemoteWRCache[mapName][styleID]
    local pageSize = self.PageSize
    local sendData = {}

    for i = (page - 1) * pageSize + 1, page * pageSize do
        if cache[i] then
            table.insert(sendData, cache[i])
        end
    end

    if next(sendData) == nil then
        if not isUpdate then
            NETWORK:StartNetworkMessageTimer(ply, "Print", {"Timer", "No World Record Data found for " .. mapName .. " on Style " .. TIMER:StyleName(styleID)})
        end
    else
        UI:SendToClient(ply, "wr", sendData, styleID, page, #cache, isUpdate and nil or mapName)
    end
end

-- When the player leaves
function TIMER:Disconnect(ply)
    if #player.GetHumans() - 1 < 1 then
        BHDATA:Unload()
    end

    if ply.Spectating then 
        Spectator:End(ply, ply:GetObserverTarget())
        ply.Spectating = nil 
    end

    if RTV then
        if RTV.VotePossible then 
            return 
        end

        collectgarbage("collect")

        if ply.Rocked then 
            RTV.MapVotes = RTV.MapVotes - 1 
        end

        local Count = #player.GetHumans()
        if Count > 1 then
            RTV.Required = math.ceil((Count - 1) * 0.6666)
            if RTV.MapVotes >= RTV.Required then 
                RTV:StartVote() 
            end
        end
    end
end

hook_Add("PlayerDisconnected", "PlayerDisconnect", function(ply) 
    TIMER:Disconnect(ply) 
end)

function TIMER:Connect(ply)
    if not Iv(ply) then
        UTIL:Notify(Color(233, 123, 255), "Player Load", "Invalid player entity passed to Player Connect")
        return
    end

    collectgarbage("collect")

    if not ply:IsBot() and not SQL.Available and not SQL.Busy then
        BHDATA:StartSQL()
    end
end

hook_Add("PlayerInitialSpawn", "PlayerConnect", function(ply)
    TIMER:Connect(ply)
end)

TIMER:Initialize()