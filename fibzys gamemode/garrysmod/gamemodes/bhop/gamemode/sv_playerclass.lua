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
local lp, Iv, ct, hook_Add, string_sub, math_floor = LocalPlayer, IsValid, CurTime, hook.Add, string.sub, math.floor

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

function TIMER:Spawn(ply)
    if not Iv(ply) then return end
    ply:SetHull(Vector(-16, -16, 0), Vector(16, 16, BHOP.Move.EyeView))
    ply:SetHullDuck(Vector(-16, -16, 0), Vector(16, 16, BHOP.Move.EyeDuck))
    ply:SetViewOffset(Vector(0, 0, BHOP.Move.OffsetView))
    ply:SetViewOffsetDucked(Vector(0, 0, BHOP.Move.OffsetDuck))

    if ply:IsBot() then
        ply:SetModel(BHOP.Models.Bot)
        ply:DrawShadow(false)
        ply:SetMoveType(MOVETYPE_NONE)
        ply:SetFOV(100, 0)
        ply:SetGravity(0)

        if BHOP.GhostBot then
            ply:SetRenderMode(RENDERMODE_TRANSALPHA)
            ply:SetColor(Color(255, 255, 255, 150))
        else
            ply:SetRenderMode(RENDERMODE_NORMAL)
            ply:SetColor(Color(255, 255, 255, 255))
        end

        return
    end

    ply:SetModel(BHOP.Models.Player)
    ply:SetTeam(1)
    ply:DrawShadow(false)
    ply:SetJumpPower(jumppower:GetFloat())
    ply:SetStepSize(stairsize:GetFloat())
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

-- Called on restart for resetting style move types
function TIMER:ResetPlayerAttributes(ply, previous, start)
    if ply.style == TIMER:GetStyleID("LG") then
        ply:SetGravity(0.6)
    elseif ply.style == TIMER:GetStyleID("HG") then
        ply:SetGravity(1.4)
    elseif ply.style == TIMER:GetStyleID("MOON") then
        ply:SetGravity(0.1)
    elseif ply:GetGravity() ~= 0 then
        ply:SetGravity(0)
    end

    local style = TIMER:GetStyle(ply)
    local enableStamina = style == TIMER:GetStyleID("L") or 
    style == TIMER:GetStyleID("Stamina") or IsKZMap()

    -- Reload stamina
    if enableStamina and ply:IsOnGround() and not ply:IsBot() then
        ply.StaminaAirTicks = 4
        ply.StaminaGroundFrames = nil
        ply.StaminaGroundStartTime = nil
    end
end

-- Spawn checks for setspawn use
function TIMER:SpawnChecks(ply)
    self:SetJumps(ply, 0)
    self:ResetPlayerAttributes(ply)

    local isBonus = (ply.style == TIMER:GetStyleID("bonus"))
    local steamID = ply:SteamID()
    local map = game.GetMap()

    local index = Setspawn.Points 
        and Setspawn.Points[map] 
        and Setspawn.Points[map][steamID] 
        and Setspawn.Points[map][steamID][isBonus and 2 or 0]

    if index then
        ply:SetPos(index[1])
        ply:SetEyeAngles(index[2])
    elseif isBonus and Zones.BonusPoint then
        ply:SetPos(Zones:GetSpawnPoint(Zones.BonusPoint))
    elseif not isBonus and Zones.StartPoint then
        ply:SetPos(Zones:GetSpawnPoint(Zones.StartPoint))
    end

    local zoneType = 2 and 0
    ply.outsideSpawn = not Zones:IsInside(ply, zoneType)

    if not ply:IsBot() and ply:GetMoveType() != MOVETYPE_WALK then
        ply:SetMoveType(MOVETYPE_WALK)
    end
end

-- What gets loaded when the player spawns
function TIMER:Load(ply)
    ply:SetTeam(1)

    ply.style, ply.mode = TIMER:GetStyleID("Normal"), 1
    ply.record, ply.Rank = 0, -1

    ply:SetNWInt("Style", ply.style)
    ply:SetNWFloat("Record", ply.record)
    ply:SetNWBool("duckUntilOnGround", false)

    timer.Simple(0.1, function()
        if IsValid(ply) then
            NETWORK:StartNetworkMessage(ply, "UpdateSingleVar", ply, "style", ply.style)
            NETWORK:StartNetworkMessage(ply, "UpdateSingleVar", ply, "mode", ply.mode)
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

    -- Update and broadcast connection count
    local connectionCount = ply:GetPData("connectionv2", 0)
    connectionCount = connectionCount + 1
    ply:SetPData("connectionv2", connectionCount)

    -- Broadcast the message
    NETWORK:StartNetworkMessage(nil, "ConnectionCount", ply:Nick(), connectionCount)

    -- Server sends version info
    timer.Simple(1, function()
        if not IsValid(ply) or not cachedVersionMsg then return end

        NETWORK:StartNetworkMessage(ply, "VersionData", cachedVersionMsg)
    end)

    net.Start("SendVersionDataMenu")
    net.WriteString(cachedVersionMsg)
    net.Send(ply)
end

-- Load the style
function TIMER:LoadStyle(ply, style)
    ply.style, ply.record, ply.mode = style, 0, 1
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
    local Sum = self:GetPointSum(ply.style, ply:SteamID())
    local Rank = self:GetRank(Sum, self:GetRankType(ply.style, true))

    ply.RankSum = Sum

    if Rank ~= ply.Rank then
        ply.Rank = Rank
        ply:SetNWInt("Rank", ply.Rank)
    end

    self:SetSubRank(ply, Rank, Sum)
    
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
        ply.WRCount = 0
        ply:SetNWInt("WRCount", ply.WRCount)

        TIMER:SetRecord(ply, ply.record, ply.style)

        if IsValid(ply) then
            return NETWORK:StartNetworkMessage(ply, "TIMER/Record", ply, ply.record, ply.style)
        else
            return
        end
    end

    if not IsValid(ply) then return end

    MySQL:Start("SELECT t1.time, (SELECT COUNT(*) + 1 FROM timer_times AS t2 WHERE map = '" .. game.GetMap() ..
        "' AND t2.time < t1.time AND style = " .. ply.style .. ") AS Rank FROM timer_times AS t1 WHERE t1.uid = '" ..
        ply:SteamID() .. "' AND t1.style = " .. ply.style .. " AND t1.map = '" .. game.GetMap() .. "'", function(Fetch)
        
        if not IsValid(ply) then return end

        if self:Assert(Fetch, "time") then
            local recordTime = tonumber(Fetch[1].time)
            ply.record = recordTime
            ply:SetNWFloat("Record", recordTime)

            TIMER:SetRecord(ply, recordTime, ply.style)
            NETWORK:StartNetworkMessage(ply, "TIMER/Record", ply, recordTime, ply.style)

            ply.Placement = tonumber(Fetch[1].Rank)
            ply:SetNWInt("Placement", ply.Placement)
        else
            ply.record = 0
            ply:SetNWFloat("Record", ply.record)

            TIMER:SetRecord(ply, 0, ply.style)
            NETWORK:StartNetworkMessage(ply, "TIMER/Record", ply, 0, ply.style)

            ply.Placement = 0
            ply:SetNWInt("Placement", ply.Placement)
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

                ply.WRCount = #Fetch
                ply:SetNWInt("WRCount", ply.WRCount)

                NETWORK:StartNetworkMessage(ply, "TIMER/RecordList", ply.FirstPlaceTimes)
            else
                ply.FirstPlaceTimes = {}
                ply.WRCount = 0
                ply:SetNWInt("WRCount", ply.WRCount)

                NETWORK:StartNetworkMessage(ply, "TIMER/RecordList", {})
            end
        end
    )
end

Player.Points = {}

function TIMER:CachePointSum(style, id, callback)
    MySQL:Start("SELECT SUM(points) AS Sum FROM timer_times WHERE uid = '" .. id .. "' AND (" .. self:GetMatchingstyles(style) .. ")", function(data)
        if data and data[1] and data[1].Sum then
            local pointSum = tonumber(data[1].Sum) or 0
            Player.Points[id] = Player.Points[id] or {}
            Player.Points[id][style] = pointSum

            if callback then
                callback(pointSum)
            end
        else
            UTIL:Notify(Color(255, 0, 0), "Database", "No users have any points yet")
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
        local Sum = self:GetPointSum(ply.style, ply:SteamID())
        local Rank = self:GetRank(Sum, self:GetRankType(ply.style, true))

        if Rank ~= ply.Rank then
            ply.Rank = Rank
            ply:SetNWInt("Rank", ply.Rank)
        end

        self:SetSubRank(ply, Rank, Sum)

        ply.Sum = Sum

        NETWORK:StartNetworkMessage(ply, "UpdatePointsSum", Sum)

        if not update then
            NETWORK:StartNetworkMessageTimer(ply, "Timer", {"Ranks", Player.NormalScalar, Player.AngledScalar})
        end
    end)
end

-- Sub Ranks
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
    local Points = self:GetMultiplier(ply.style)
    if not Points or Points == 0 then return end
    
    local average = self:GetAverage(ply.style)
    if not average or not old then return end

    for _, p in ipairs(player.GetHumans()) do
        if p == ply or p.Style ~= ply.style or not p.RankSum or not p.Rank or not p.Record or p.Record == 0 then
            continue
        end

        local nCurrent = Points * (old / p.Record)
        local nNew = Points * (average / p.Record)
        local points = p.RankSum - nCurrent + nNew

        local Rank = self:GetRank(points, self:GetRankType(p.Style, true))
        if Rank ~= p.Rank then
            p.Rank = Rank
            p:SetNWInt("Rank", p.Rank)
        end

        p.RankSum = points
        self:SetSubRank(p, p.Rank, p.RankSum)
    end
end

function TIMER:SetRankMedal(ply, nPos)
    MySQL:Start("SELECT t1.uid, (SELECT COUNT(*) + 1 FROM timer_times AS t2 WHERE map = '" .. game.GetMap() .. "' AND t2.time < t1.time AND style = " .. ply.style .. ") AS Rank FROM timer_times AS t1 WHERE t1.map = '" .. game.GetMap() .. "' AND t1.style = " .. ply.style .. " ORDER BY Rank ASC LIMIT 100", function(Query)
        if self:Assert(Query, "uid") then
            for _, p in pairs(player.GetHumans()) do
                if p.style ~= ply.style then continue end
                local bSet = false
                for _, d in pairs(Query) do
                    if p:SteamID() == d.uid then
                        bSet = true
                        p.Placement = tonumber(d.Rank) > 3 and 0 or tonumber(d.Rank)
                        p:SetNWInt("Placement", p.WRCount)
                    end
                end
                if not bSet and p.WRCount then
                    p.Placement = 0
                    p:SetNWInt("Placement", p.WRCount)
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

function TIMER:FindScalar(Points)
    local count = #self.Ranks
    local sum = Points * Player.LadderScalar
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
    if TIMER:Assert(result, "Sum") then
        for i, d in ipairs(result) do
            if d.nStyle == style then
                cache[style][i] = { string_sub(d.szPlayer, 1, 20), math_floor(tonumber(d.Sum)) }
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
    local normal = self:GetRankType(self:GetStyleID("normal"), true)
    local angled = self:GetRankType(self:GetStyleID("sideways"), true)

    self.TopCache[normal], self.TopCache[angled] = {}, {}

    MySQL:Start("SELECT player, SUM(points) as Sum, style FROM timer_times WHERE style IN (" .. normal .. ", " .. self:GetStyleID("bonus") .. ") GROUP BY uid ORDER BY Sum DESC LIMIT " .. self.TopLimit, function(Normal)
        CacheTopPlayers(Normal, self.TopCache, normal)
        TIMER:ClearOldCache(self.TopCache[normal], TIMER.TopLimit)
    end)

    MySQL:Start("SELECT player, SUM(points) as Sum, style FROM timer_times WHERE style IN (" .. self:GetStyleID("sideways") .. ", " .. self:GetStyleID("halfsideways") .. ") GROUP BY uid ORDER BY Sum DESC LIMIT " .. self.TopLimit, function(Angled)
        CacheTopPlayers(Angled, self.TopCache, angled)
        TIMER:ClearOldCache(self.TopCache[angled], TIMER.TopLimit)
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
                    tonumber(d.time),
                    tonumber(d.points)
                })
            end
        end

        NETWORK:StartNetworkMessageTimer(ply, "GUI_Open", { "Maps", { callback, tab } })
    end)
end

TIMER.RemoteWRCache = {}

function TIMER:SendRemoteWRList(ply, mapName, styleID, page, isUpdate)
    if not mapName or type(mapName) ~= "string" or not styleID or type(styleID) ~= "number" then return end
    if mapName == game.GetMap() then return UI:SendToClient(ply, "wr", self:GetRecordList(styleID, page), styleID, page, self:GetRecordCount(styleID)) end

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

            if self:Assert(result, "uid") then
                for _, data in pairs(result) do
                    table.insert(self.RemoteWRCache[mapName][styleID], {
                        data.uid, 
                        data.player, 
                        tonumber(data.time), 
                        self:Null(data.date), 
                        self:Null(data.data)
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

    -- Leave messages
    local connectMessage = Lang:Get("Disconnect", { ply:Nick(), ply:SteamID(), "left the game" })
    BHDATA:Broadcast("Print", { "Server", connectMessage })
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