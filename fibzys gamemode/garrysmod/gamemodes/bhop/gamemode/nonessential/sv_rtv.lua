RTV = RTV or {
    Initialized = 0, VotePossible = false,
    DefaultExtend = 15, MaxSlots = 64,
    Extends = 0, Nominations = {},
    LatestList = {}, MapLength = 90 * 60,
    MapInit = CurTime(), MapEnd = 0,
    MapVotes = 0,
    MapVoteList = {0, 0, 0, 0, 0, 0, 0},
    MapListVersion = 1,
    Timers = {}
}

local MapList = MapList or {}
local hook_Add = hook.Add

util.AddNetworkString("SendRTVTimeLeft")

local lastTimeLeft = -1

function RTV:SendTimeLeft()
    if not RTV.MapEnd or not RTV.VotePossible then return end

    local timeLeft = math.max(0, RTV.MapEnd - CurTime()) 

    if timeLeft ~= lastTimeLeft then
        lastTimeLeft = timeLeft
        net.Start("SendRTVTimeLeft")
        net.WriteFloat(timeLeft)
        net.Broadcast()
    end
end

local broadcastInterval = 10
timer.Create("BroadcastRTVTimeLeft", broadcastInterval, 0, function()
    if RTV.VotePossible then
        RTV:SendTimeLeft()
    else
        timer.Remove("BroadcastRTVTimeLeft")
    end
end)

function RTV:Init()
    RTV.MapInit = CurTime()
    RTV.MapEnd = RTV.MapInit + RTV.MapLength

    RTV:LoadData()
    RTV:TrueRandom(1, 5)

    timer.Create("RTV_MapCountdown", RTV.MapLength, 1, function() RTV:StartVote() end)
    timer.Create("BroadcastRTVTimeLeft", 10, 0, function() RTV:SendTimeLeft() end)
end

function RTV:CreateTimer(name, delay, func)
    RTV.Timers[name] = {endTime = CurTime() + delay, callback = func}
end

function RTV:StartVote()
    if RTV.VotePossible then return end

    RTV.VotePossible = true
    RTV.Selections = {}
    BHDATA:Broadcast("Print", {"Server", Lang:Get("VoteStart")})
    SendPopupNotification(nil, "Notification", "Choose your maps!", 10)

    local RTVTempList = {}
    for map, voters in pairs(RTV.Nominations) do
        local nCount = #voters
        RTVTempList[nCount] = RTVTempList[nCount] or {}
        table.insert(RTVTempList[nCount], map)
    end

    local Added = 0
    for i = RTV.MaxSlots, 1, -1 do
        if RTVTempList[i] then
            for _, map in ipairs(RTVTempList[i]) do
                if Added >= 5 then break end
                table.insert(RTV.Selections, map)
                Added = Added + 1
            end
        end
    end

    if Added < 5 and #MapList > 0 then
        local indices = {}
        for i = 1, #MapList do
            table.insert(indices, i)
        end
    
        for i = #indices, 2, -1 do
            local j = math.random(i)
            indices[i], indices[j] = indices[j], indices[i]
        end
    
        for _, index in ipairs(indices) do
            if Added >= 5 then break end
            local data = MapList[index]
            if not table.HasValue(RTV.Selections, data[1]) and data[1] ~= game.GetMap() then
                table.insert(RTV.Selections, data[1])
                Added = Added + 1
            end
        end
    end

    local RTVSend = {}
    for _, map in ipairs(RTV.Selections) do
        table.insert(RTVSend, RTV:GetMapData(map))
    end

    UI:SendToClient(false, "MapVote", "started", RTVSend)
    RTV:CreateTimer("EndVote", 15, function() if not RTV.VIPTriggered then RTV:EndVote() end end)

    RTV:CreateTimer("InstantVote", 0.1, function()
        for map, voters in pairs(RTV.Nominations) do
            for id, data in ipairs(RTVSend) do
                if data[1] == map then
                    UI:SendToClient(voters, "MapVote", "instant", id)
                end
            end
        end
    end)
end

function RTV:EndVote()
    RTV.VIPTriggered = nil

    if RTV.CancelVote then
        RTV.VotePossible = false
        return RTV:ResetVote("Yes", 2, false, "VoteCancelled")
    end

    local nMax, nWin = 0, -1
    for i = 1, 7 do
        if RTV.MapVoteList[i] > nMax then
            nMax = RTV.MapVoteList[i]
            nWin = i
        end
    end

    if nMax == 0 then
        nWin = 6
    end

    if nWin <= 0 then
        nWin = RTV:TrueRandom(1, 5)
    elseif nWin == 6 then
        BHDATA:Broadcast("Print", { "Server", Lang:Get("VoteExtend", { RTV.DefaultExtend }) })
        return RTV:ResetVote(nil, 1, true, nil, true)
    elseif nWin == 7 then
        RTV.VotePossible = false

        if MapList and #MapList > 0 then
            local nValue = RTV:TrueRandom(1, #MapList)
            local tabWin = MapList[nValue]
            local szMap = tabWin[1]

            BHDATA:Broadcast("Print", { "Server", Lang:Get("VoteChange", { szMap }) })
            RunConsoleCommand("changelevel", szMap)
        else
            nWin = RTV:TrueRandom(1, 5)
        end
    end

    local szMap = RTV.Selections[nWin]
    if not szMap or not type(szMap) == "string" then return end

    BHDATA:Broadcast("Print", { "Server", Lang:Get("VoteChange", { szMap }) })
    if not RTV:IsAvailable(szMap) then
        BHDATA:Broadcast("Print", { "Server", Lang:Get("VoteMissing", { szMap }) })
    end

    BHDATA:Unload()
    RTV:CreateTimer("ChangeLevel", 10, function() RunConsoleCommand("changelevel", szMap) end)
end

function RTV:ResetVote(szCancel, nMult, bExtend, szMsg, bNominate)
    nMult = nMult or 1
    if szCancel == "Yes" then RTV.CancelVote = nil end

    RTV.VotePossible = false
    RTV.Selections = {}
    if bNominate then RTV.Nominations = {} end

    RTV.MapInit = CurTime()
    RTV.MapEnd = RTV.MapInit + (nMult * RTV.DefaultExtend * 60)
    RTV.MapVotes = 0
    RTV.MapVoteList = {0, 0, 0, 0, 0, 0, 0}

    if bExtend then RTV.Extends = RTV.Extends + 1 end

    for _, p in ipairs(player.GetHumans()) do
        p.Rocked = nil
        if bNominate then p.NominatedMap = nil end
    end

    timer.Create("RTV_MapCountdown", nMult * RTV.DefaultExtend * 60, 1, function() RTV:StartVote() end)

    if szMsg then
        BHDATA:Broadcast("Print", {"Server", Lang:Get(szMsg)})
    end
end

function RTV:CreateTimer(name, delay, func)
    timer.Create(name, delay, 1, func)
end

function RTV:Vote(ply)
    if ply.RTVLimit and CurTime() - ply.RTVLimit < 12 then
        return NETWORK:StartNetworkMessageTimer(ply, "Print", {"Server", Lang:Get("VoteLimit", {math.ceil(12 - (CurTime() - ply.RTVLimit))})})
    elseif ply.Rocked then
        return NETWORK:StartNetworkMessageTimer(ply, "Print", {"Server", Lang:Get("VoteAlready")})
    elseif RTV.VotePossible then
        return NETWORK:StartNetworkMessageTimer(ply, "Print", {"Server", Lang:Get("VotePeriod")})
    end

    ply.RTVLimit = CurTime()
    ply.Rocked = true

    RTV.MapVotes = RTV.MapVotes + 1
    RTV.Required = math.max(math.ceil((#player.GetHumans() - Spectator:GetAFK()) * (2 / 3)), 1)
    local nVotes = RTV.Required - RTV.MapVotes
    BHDATA:Broadcast("Print", {"Server", Lang:Get("VotePlayer", {ply:Name(), nVotes, nVotes == 1 and "vote" or "votes"})})

    if RTV.MapVotes >= RTV.Required and RTV.MapVotes > 0 then
        RTV:StartVote()
    end
end

function RTV:Revoke(ply)
    if RTV.VotePossible then
        return NETWORK:StartNetworkMessageTimer(ply, "Print", {"Server", Lang:Get("VotePeriod")})
    end

    if ply.Rocked then
        ply.Rocked = false

        RTV.MapVotes = RTV.MapVotes - 1
        RTV.Required = math.ceil((#player.GetHumans() - Spectator:GetAFK()) * (2 / 3))
        local nVotes = RTV.Required - RTV.MapVotes
        BHDATA:Broadcast("Print", {"Server", Lang:Get("VoteRevoke", {ply:Name(), nVotes, nVotes == 1 and "vote" or "votes"})})
    else
        NETWORK:StartNetworkMessageTimer(ply, "Print", {"Server", Lang:Get("RevokeFail")})
    end
end

function RTV:Nominate(ply, szMap)
    local szIdentifier = "Nomination"
    local varArgs = {ply:Name(), szMap}

    if ply.NominatedMap and ply.NominatedMap ~= szMap then
        if RTV.Nominations[ply.NominatedMap] then
            for id, p in ipairs(RTV.Nominations[ply.NominatedMap]) do
                if p == ply then
                    table.remove(RTV.Nominations[ply.NominatedMap], id)
                    if #RTV.Nominations[ply.NominatedMap] == 0 then
                        RTV.Nominations[ply.NominatedMap] = nil
                    end

                    szIdentifier = "NominationChange"
                    varArgs = {ply:Name(), ply.NominatedMap, szMap}
                    break
                end
            end
        end
    elseif ply.NominatedMap == szMap then
        return NETWORK:StartNetworkMessageTimer(ply, "Print", {"Server", Lang:Get("NominationAlready")})
    end

    RTV.Nominations[szMap] = RTV.Nominations[szMap] or {}
    if not table.HasValue(RTV.Nominations[szMap], ply) then
        table.insert(RTV.Nominations[szMap], ply)
        ply.NominatedMap = szMap
        BHDATA:Broadcast("Print", {"Server", Lang:Get(szIdentifier, varArgs)})
    else
        NETWORK:StartNetworkMessageTimer(ply, "Print", {"Server", Lang:Get("NominationAlready")})
    end
end

function RTV:ReceiveVote(ply, nVote, nOld)
    if not RTV.VotePossible or not nVote then return end
    local nAdd = ply.IsVIP and ply.VIPLevel and ply.VIPLevel >= Admin.Level.Elevated and 1 or 1

    if not nOld then
        if nVote < 1 or nVote > 7 then return end
        RTV.MapVoteList[nVote] = RTV.MapVoteList[nVote] + nAdd
    else
        if nVote < 1 or nVote > 7 or nOld < 1 or nOld > 7 then return end
        RTV.MapVoteList[nVote] = RTV.MapVoteList[nVote] + nAdd
        RTV.MapVoteList[nOld] = RTV.MapVoteList[nOld] - nAdd
        if RTV.MapVoteList[nOld] < 0 then RTV.MapVoteList[nOld] = 0 end
    end

    BHDATA:Broadcast("RTV", {"VoteList", RTV.MapVoteList})

    UI:SendToClient(false, "MapVote", "update", RTV.MapVoteList)
    NETWORK:GetNetworkMessage(ply, "MapVote", RTV.MapVoteList)
end

NETWORK:GetNetworkMessage("VoteCallback", function(ply, data)
    local mapId = data[1]
    local oldId = data[2]
    RTV:ReceiveVote(ply, mapId, oldId)
end)

function RTV:IsAvailable(szMap)
    return file.Exists("maps/" .. szMap .. ".bsp", "GAME")
end

function RTV:Who(ply)
    local Voted = {}
    local NotVoted = {}

    for _, p in ipairs(player.GetHumans()) do
        if p.Rocked then
            table.insert(Voted, p:Name())
        else
            table.insert(NotVoted, p:Name())
        end
    end

    RTV.Required = math.ceil((#player.GetHumans() - Spectator:GetAFK()) * (2 / 3))
    NETWORK:StartNetworkMessageTimer(ply, "Print", {"Server", Lang:Get("VoteList", {RTV.Required, #Voted, table.concat(Voted, ", "), #NotVoted, table.concat(NotVoted, ", ")})})
end

function RTV:CheckVotes()
    for _, ply in ipairs(player.GetHumans()) do
        if ply.AFK and ply.Rocked then
            ply.Rocked = false
            RTV.MapVotes = RTV.MapVotes - 1
            RTV.Required = math.max(math.ceil((#player.GetHumans() - Spectator:GetAFK()) * (2 / 3)), 1)

            NETWORK:StartNetworkMessageTimer(ply, "Print", { "RTV", "You are AFK, your RTV vote has been removed." })
        end
    end

    local required = math.max(math.ceil((#player.GetHumans() - Spectator:GetAFK()) * (2 / 3)), 1)
    if RTV.MapVotes >= required and RTV.MapVotes > 0 then
        RTV:StartVote()
    end
end

function RTV:Check(ply)
    RTV.Required = math.ceil((#player.GetHumans() - Spectator:GetAFK()) * (2 / 3))
    local nVotes = RTV.Required - RTV.MapVotes
    NETWORK:StartNetworkMessageTimer(ply, "Print", {"Server", Lang:Get("VoteCheck", {nVotes, nVotes == 1 and "vote" or "votes"})})
end

function RTV:VIPExtend(ply)
    if RTV.VotePossible then
        if RTV.VIPRequired then
            BHDATA:Broadcast("RTV", {"VIPExtend"})
            RTV:CreateTimer("EndVote", 31, function() RTV:EndVote() end)

            RTV.VIPTriggered = ply
            RTV.VIPRequired = nil
        else
            if not RTV.VIPTriggered then
                NETWORK:StartNetworkMessageTimer(ply, "Print", {"Server", "You can only use this command when people want to extend the map more than 2 times."})
            elseif ply ~= RTV.VIPTriggered then
                NETWORK:StartNetworkMessageTimer(ply, "Print", {"Server", "Your fellow VIP " .. RTV.VIPTriggered:Name() .. " has already triggered the extend vote."})
            else
                NETWORK:StartNetworkMessageTimer(ply, "Print", {"Server", "You cannot use this command again in the same session."})
            end
        end
    else
        NETWORK:StartNetworkMessageTimer(ply, "Print", {"Server", "You can only use this command while a vote is active!"})
    end
end

function RTV:LoadData()
    MapList = {}

    MySQL:Start("SELECT map, multiplier, plays FROM timer_map", function(results)
        if not results or #results == 0 then
            print("[RTV] No maps found in MySQL database!")
            return
        end

        for _, data in ipairs(results) do
            table.insert(MapList, {
                data["map"],
                tonumber(data["multiplier"]) or 0,
                tonumber(data["plays"]) or 0
            })
        end
    end)

    file.CreateDir("rtv/")

    if not file.Exists("rtv/settings.txt", "DATA") then
        file.Write("rtv/settings.txt", tostring(RTV.MapListVersion))
    else
        local data = file.Read("rtv/settings.txt", "DATA")
        RTV.MapListVersion = tonumber(data)
    end
end

function RTV:UpdateMapListVersion()
    RTV.MapListVersion = RTV.MapListVersion + 1
    file.Write("rtv/settings.txt", tostring(RTV.MapListVersion))
end

local EncodedData, EncodedLength
function RTV:GetMapList(ply, nVersion)
    if nVersion ~= RTV.MapListVersion then
        if not EncodedData or not EncodedLength then
            EncodedData = util.Compress(util.TableToJSON({MapList, RTV.MapListVersion}))
            EncodedLength = #EncodedData
        end

        if not EncodedData or not EncodedLength then
            NETWORK:StartNetworkMessageTimer(ply, "Print", {"Server", "Couldn't obtain map list, please reconnect!"})
        else
            net.Start("BinaryTransfer")
            net.WriteString("List")
            net.WriteUInt(EncodedLength, 16)
            net.WriteData(EncodedData, EncodedLength)
            net.Send(ply)
        end
    end
end

function RTV:MapExists(szMap)
    for _, data in ipairs(MapList) do
        if data[1] == szMap then
            return true
        end
    end
    return false
end

function RTV:GetMapData(szMap)
    for _, data in ipairs(MapList) do
        if data[1] == szMap then
            return data
        end
    end
    return {szMap, 1}
end

function RTV:TrueRandom(nUp, nDown)
    if not RTV.RandomInit then
        math.randomseed(os.time() + math.random())
        RTV.RandomInit = true
    end

    return math.random(nUp, nDown)
end

hook_Add("InitPostEntity", "InitializeRTV", function()
    RTV:Init()
end)

function RTV:SendMapList(client)
    local mapList = {}
    local seenMaps = {}

    for _, data in ipairs(MapList) do
        local mapName = tostring(data[1])

        if not seenMaps[mapName] then
            seenMaps[mapName] = true

            table.insert(mapList, { 
                name = mapName, 
                points = tonumber(data[2]) or 0
            })
        end
    end

    UI:SendToClient(client or false, "nominate_list", mapList)
end

hook.Add("PlayerInitialSpawn", "SendNominateList", function(client)
    RTV:SendMapList(client)
end)