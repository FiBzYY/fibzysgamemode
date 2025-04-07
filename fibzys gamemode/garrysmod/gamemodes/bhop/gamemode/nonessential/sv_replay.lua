-- CVars
CreateConVar("bhop_replay_simplenames", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Enable or disable simplified Replay replay names")

-- Cache
local hook_Add, sq, st, Iv = hook.Add, sql.Query, SysTime, IsValid

Replay = Replay or {
    BotPlayer = {},
    BotFrame = {},
    BotFrames = {},
    BotData = {},
    BotInfo = {},
    Players = {},
    Active = {},
    Recording = {},
    Frame = {},
    StartedFrame = {},
    EndedFrame = {},
    RecordingFinished = {}
}

-- Types
BotType = {Main = 1, Multi = 2}

function Replay:Setup()
    self.BotPlayer = {}
    self.BotFrame = {}
    self.BotFrames = {}
    self.BotInfo = {}
    self.BotData = {}
    self.PerStyle = {}

    self:LoadData()
end

-- Old replays
local function OldBotToNewStructure(style, tab)
    if not tab then return end

    local tabFrames = #tab[1]
    local newTab = {}

    for i = 1, tabFrames do
        newTab[i] = {tab[1][i], tab[2][i], tab[3][i], tab[4][i], tab[5][i], tab[6][i]}
    end

    Replay.BotData[style] = newTab
    Replay.BotFrame[style] = 1
    Replay.BotFrames[style] = #Replay.BotData[style]
end

-- Start Recording
function Replay:StartRecording(ply)
    self:CheckEndFrames(ply)

    self.Recording[ply] = {{}, {}, {}, {}, {}, {}, {}}

    for i = 1, 2 do
        self.Recording[ply][1][i] = 0
        self.Recording[ply][2][i] = 0
        self.Recording[ply][3][i] = 0
        self.Recording[ply][4][i] = 0
        self.Recording[ply][5][i] = 0
        self.Recording[ply][6][i] = 0
    end

    self.Players[ply] = true
    self.Active[ply] = true
    self.Frame[ply] = 1
    self.StartedFrame[ply] = 1
end

-- Stop Recording
function Replay:StopRecording(ply, time, record)
    if not IsValid(ply) or not time then return end
    if not self.Recording[ply] or self.Frame[ply] <= 1 then return end
    if record and record ~= 0 and record < time then return end

    local tempStyle = ply.style
    local botInfo = self.BotInfo[tempStyle] and self.BotInfo[tempStyle].Time
    if botInfo and botInfo < time then return end

    local endFrame = math.max(self.Frame[ply] - 1, 1)
    for i = 1, 6 do
        local tempTable = {}
        for j = 1, endFrame do
            tempTable[j] = self.Recording[ply][i][j]
        end
        self.Recording[ply][i] = tempTable
    end

    self.RecordingFinished[ply] = tempStyle
    self.EndedFrame[ply] = endFrame

    self.BotInfo[tempStyle] = {
        Name = ply:Name(),
        Time = time,
        Style = tempStyle,
        SteamID = ply:SteamID(),
        Date = os.date("%Y-%m-%d %H:%M:%S", os.time()), -- date
        Saved = false,
        Start = CurTime(), -- run time
        Frame = {self.StartedFrame[ply], self.EndedFrame[ply]}
    }

    -- to see more of end run
    timer.Simple(0.5, function()
	    self:CheckEndFrames(ply)
    end)
end

-- Trim frames
function Replay:TrimRecording(ply)
    if not self.Frame[ply] then return end

    local tempFrame = self.Frame[ply]
    self.StartedFrame[ply] = tempFrame

    local trimtime = 300 -- trim 300 frames
    if tempFrame < trimtime then return end

    local tempRecording = {
        {}, {}, {}, {}, {}, {}
    }

    local tempCounter = 1
    for i = tempFrame - trimtime, tempFrame do
        for j = 1, 6 do
            if self.Recording[ply][j][i] then
                tempRecording[j][tempCounter] = self.Recording[ply][j][i]
            end
        end
        tempCounter = tempCounter + 1
    end

    self.Recording[ply] = tempRecording
    self.Frame[ply] = trimtime
    self.StartedFrame[ply] = trimtime
end

function Replay:CheckEndFrames(ply)
    local tempStyle = self.RecordingFinished[ply]
    if not tempStyle then return end

    self.BotData[tempStyle] = self.Recording[ply]

    self.BotFrame[tempStyle] = 1
    self.BotFrames[tempStyle] = #self.BotData[tempStyle][1]

    self:SetMultiBot(tempStyle)

    self.Recording[ply] = nil
    self.Frame[ply] = 0
    self.RecordingFinished[ply] = nil
end

-- Load SQL data
function Replay:LoadData()
    MySQL:Start("SELECT * FROM timer_replays WHERE map = " .. MySQL:Escape(game.GetMap()) .. " ORDER BY style ASC", function(results)
        if not results or #results == 0 then return end

        for _, Info in ipairs(results) do
            local name = "timer/replays/data_" .. game.GetMap()
            local style = tonumber(Info["style"])

            if style ~= TIMER:GetStyleID("Normal") then
                name = name .. "_" .. style .. ".txt"
            else
                name = name .. ".txt"
            end

            local RawData = file.Read(name, "DATA")
            if not RawData or RawData == "" then continue end
            local RunData = util.Decompress(RawData)
            if not RunData then continue end

            self.BotData[style] = util.JSONToTable(RunData)

            if #self.BotData[style] == 1 then
                OldBotToNewStructure(style, self.BotData[style])
            else
                self.BotFrame[style] = 1
                self.BotFrames[style] = #self.BotData[style][1]
            end

            local tempFrame = {0, self.BotFrames[style]}
            if Info["frame"] then
                local convFrame = util.JSONToTable(Info["frame"])
                if convFrame then
                    tempFrame = {convFrame[1], convFrame[2]}
                end
            end

            self.BotInfo[style] = {
                Name = Info["player"],
                Time = tonumber(Info["time"]),
                Style = style,
                SteamID = Info["steam"],
                Date = Info["date"],
                Saved = true,
                Start = CurTime(),
                CompletedRun = true,
                Frame = tempFrame
            }
        end
    end)
end

function Replay:ClearStyle(replay)
    self.BotFrame[replay] = nil
    self.BotFrames[replay] = nil
    self.BotData[replay] = nil
    self.BotInfo[replay] = nil
end

function Replay:SetMultiBot(replay)
    local normalStyleID = TIMER:GetStyleID("Normal")
    local target = nil

    for _, Replay in pairs(player.GetBots()) do
        local isNormal = replay == normalStyleID
        local matchesStyle = (isNormal and Replay.Style == normalStyleID) or (not isNormal and Replay.Style != normalStyleID)

        if matchesStyle and not Replay.Temporary then
            target = Replay
            break
        end
    end

    if IsValid(target) then
        target.Style = replay
        self:SetInfo(target, replay, true)
        self.BotFrame[replay] = 1
        self.BotInfo[replay].CompletedRun = nil
        self.BotPlayer[target] = replay
        self:NotifyRestart(replay)
    end
end

-- Spawn replay
function Replay:Spawn(multi, replay, none)
    replay = multi and replay or TIMER:GetStyleID("Normal")

    for _, Replay in pairs(player.GetBots()) do
        if Replay.Temporary then
            self:InitializeBot(Replay, replay)
            return true
        end
    end

    if #player.GetBots() < 2 then
        self:CreateBot(multi, replay, none)
    end
end

-- Replay Spawn
function Replay:InitializeBot(Replay, replay)
    Replay:SetMoveType(MOVETYPE_NONE)
    Replay:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
    Replay.Style = replay

    Replay:SetFOV(BHOP.ReplayFov, 0)
    Replay:SetGravity(0)

    Replay.Temporary = nil
    self:SetInfo(Replay, replay, true)
end

-- Info
function Replay:DisplayBotInfo(replay)
    local info = self.BotInfo[replay]
    if info then
        local name = info.Name or "Unknown"
        local time = info.Time or "No Time Recorded"
        print(string.format("Replay Style: %d, Name: %s, Time: %.2f", replay, name, time))
    else
        print("No information available for this Replay style.")
    end
end

local format = string.format
local floor = math.floor
local cache = {}

-- Time display
local function cTime(ns)
    if cache[ns] then
        return cache[ns]
    end

    local milliseconds = floor((ns % 1) * 1000)
    local result

    if ns >= 3600 then
        result = format("%d:%.2d:%.2d.%.3d", floor(ns / 3600), floor(ns / 60 % 60), floor(ns % 60), milliseconds)
    elseif ns >= 60 then 
        result = format("%.2d:%.2d.%.3d", floor(ns / 60 % 60), floor(ns % 60), milliseconds)
    else
        result = format("%.2d.%.3d", floor(ns % 60), milliseconds)
    end

    cache[ns] = result

    return result
end

-- Shorten a name
local function ShortenName(name, maxLength)
    if string.len(name) > maxLength then
        return string.sub(name, 1, maxLength - 3)
    else
        return name
    end
end

-- Create replays
function Replay:CreateBot(multi, replay, bNone)
    local botType = multi and BotType.Multi or BotType.Main
    local info = self.BotInfo[replay]

    local maxNameLength = 10
    local displayName = nil

    local useSimplifiedNames = GetConVar("bhop_replay_simplenames"):GetBool()

    if info ~= nil and not useSimplifiedNames then
        local formattedTime = cTime(info.Time)
        local shortName = ShortenName(info.Name, maxNameLength)
        if botType == BotType.Main then
            displayName = "Normal: " .. shortName .. " - " .. formattedTime
        elseif botType == BotType.Multi then
            displayName = "Multi-Style: " .. shortName .. " - " .. formattedTime
        end
    else
        if botType == BotType.Main then
            if useSimplifiedNames then
                displayName = "Normal Replay"
            else
                displayName = "Normal Replay: No Record"
            end
        elseif botType == BotType.Multi then
            if useSimplifiedNames then
                displayName = "Multi-Style Replay"
            else
                displayName = "Multi-Style Replay: No Record"
            end
        end
    end

    player.CreateNextBot(displayName)
    self:Spawn(multi, replay)
end

-- Check Status
function Replay:CheckStatus()
    if self.IsStatusCheck then return true end

    self.IsStatusCheck = true

    local tick = 0
    local normal, multi

    for _, Replay in pairs(player.GetBots()) do
        if Replay.Style == TIMER:GetStyleID("Normal") then
            normal = true
        else
            multi = true
        end

        tick = tick + 1
    end

    if tick < 2 then
        if not normal then
            self:Spawn()
        end

        if not multi then
            local replay, set = 0, true
            for style, _ in pairs(self.BotData) do
                if style ~= TIMER:GetStyleID("Normal") then
                    replay = style
                    set = nil
                    break
                end
            end

            self.SpawnData = {replay, set}
            if self and self.Spawn and self.SpawnData then
                self:Spawn(true, self.SpawnData[1], self.SpawnData[2])
            end
        end
    end

    self.IsStatusCheck = nil
end

function Replay:Save(replay)
    if not replay and #player.GetHumans() > 0 then
        self:Save(true)
        return
    end

    local mapName = game.GetMap()
    local savedCount = 0
    local startTime = SysTime()

    BHDATA:Broadcast("Print", {"Server", Lang:Get("BotSaving")})

    for style, _ in pairs(self.BotData) do
        local info = self.BotInfo[style]

        if info.Saved or not self.BotData[style] or not self.BotData[style][1] or #self.BotData[style][1] == 0 or self.BotFrames[style] == 0 then 
            continue 
        end

        local styleID = info.Style

        local escName = MySQL:Escape(info.Name)
        local escSteamID = MySQL:Escape(info.SteamID)
        local escDate = MySQL:Escape(os.date("%Y-%m-%d %H:%M:%S"))
        local escFrame = util.TableToJSON(info.Frame)

        MySQL:Start("SELECT time FROM timer_replays WHERE map = " .. MySQL:Escape(mapName) .. " AND style = " .. styleID, function(results)
            if results and results[1] and tonumber(results[1]["time"]) then
                MySQL:Start("UPDATE timer_replays SET " ..
                    "player = " .. escName .. ", " ..
                    "time = " .. info.Time .. ", " ..
                    "steam = " .. escSteamID .. ", " ..
                    "date = " .. escDate .. ", " ..
                    "frame = '" .. escFrame .. "' " ..
                    "WHERE map = " .. MySQL:Escape(mapName) .. " AND style = " .. styleID
                )
            else
                MySQL:Start("INSERT INTO timer_replays (map, player, time, style, steam, date, frame) VALUES (" ..
                    MySQL:Escape(mapName) .. ", " ..
                    escName .. ", " ..
                    info.Time .. ", " ..
                    styleID .. ", " ..
                    escSteamID .. ", " ..
                    escDate .. ", " ..
                    "'" .. escFrame .. "')"
                )
            end
        end)

        local baseFileName = "timer/replays/data_" .. mapName
        if style ~= TIMER:GetStyleID("Normal") then
            baseFileName = baseFileName .. "_" .. style
        end

        if file.Exists(baseFileName .. ".txt", "DATA") then
            local version = 1
            local backupFile = baseFileName .. "_v"

            while file.Exists(backupFile .. version .. ".txt", "DATA") do
                version = version + 1
            end

            local existingData = file.Read(baseFileName .. ".txt", "DATA")
            file.Write(backupFile .. version .. ".txt", util.TableToJSON(info) .. "\n" .. existingData)
        end

        local compressedData = util.Compress(util.TableToJSON(self.BotData[style]))
        file.Write(baseFileName .. ".txt", compressedData)

        self.BotInfo[style].Saved = true
        savedCount = savedCount + 1
    end

    local endTime = SysTime()
    local totalTime = math.Round(endTime - startTime, 2)

    local savedCountData = savedCount
    local totalTimeData = totalTime
    local ID = "BotSavingStats"
    local Data = { savedCountData, totalTimeData }

    BHDATA:Broadcast("Print", { "Server", Lang:Get(ID, Data) })
end

function Replay:CountPlayers()
    local count = 0

    for d, b in pairs(self.Players) do
        if d and b and IsValid(d) and d:IsPlayer() then
            count = count + 1
        else
            self.Players[d] = nil
        end
    end

    return count
end

function Replay:ShowStatus(ply)
    NETWORK:StartNetworkMessageTimer(ply, "Print", {"Notification", Lang:Get("BotStatus", {self:IsRecorded(ply) and "being" or "not being"})})
end

function Replay:GetMultiStyle()
	for _, bot in pairs(player.GetAll()) do
		if bot:IsBot() then
			if bot.Style ~= TIMER:GetStyleID("Normal") then
				return bot.Style
			end
		end
	end

	return 0
end

function Replay:ChangeMultiBot(style)
	local current = self:GetMultiStyle()

	if not TIMER:IsValidStyle(current) then  return "None" end
	if not TIMER:IsValidStyle(style) then return "Invalid" end
	if style == TIMER:GetStyleID("Normal") then return "Exclude" end
	if current == style then return "Same" end

    if self.BotInfo[style] and self.BotData[style] then
        if self.BotInfo[current].CompletedRun then
            local ply = Replay:GetPlayer(current)
            if not ply then 
                return "NoBot"
            end

            ply.style = style
            Replay:SetInfo(ply, style, true)
            self.BotFrame[style] = 1
            self.BotInfo[style].CompletedRun = nil
            self.BotInfo[style].Start = nil
            self.BotInfo[style].Waiting = true
            self.BotPlayer[ply] = style
            Replay:NotifyRestart(style)

			return "The replay is now displaying " .. self.BotInfo[style].Name .. "'s " .. TIMER:StyleName(self.BotInfo[style].Style) .. " run!"
		else
			return "Wait"
		end
	else
		return "Error"
	end
end

function Replay:GetMultiBots()
	local tabStyles = {}
	for style, data in pairs(self.BotData) do
		if style != TIMER:GetStyleID("Normal") then
			local styleName = TIMER:StyleName(style)
			table.insert(tabStyles, styleName)
		end
	end

	return tabStyles
end

function Replay:SaveBot(ply)
    local saved = false
    local savedCount = 0

    for styleID, info in pairs(self.BotInfo) do
        if info.SteamID == ply:SteamID() then
            if not info.Saved then
                saved = true
                self:Save()
                savedCount = savedCount + 1
            end
        end
    end

    local message
    if saved then
        message = "Your replay has been saved, Total replays saved: " .. savedCount
    else
        message = "All your replays have already been saved or you have none."
    end

    NETWORK:StartNetworkMessageTimer(ply, "Print", {"Timer", message})
end

function Replay:Exists(replay)
    return self.BotFrame[replay] and self.BotFrames[replay] and self.BotInfo[replay].Start
end

function Replay:NotifyRestart(replay)
    local ply = self:GetPlayer(replay)
    local info = self.BotInfo[replay]
    local empty = false

    if Iv(ply) and not info then
        empty = true
    elseif not info or not info.Start or not Iv(ply) then
        return false
    end

    local tab, Watchers = {"Timer", true, nil, "Waiting replay", nil, CurTime(), "Save"}, {}
    for _, p in pairs(player.GetHumans()) do
        if not p.Spectating then continue end
        local ob = p:GetObserverTarget()
        if Iv(ob) and ob:IsBot() and ob == ply then
            table.insert(Watchers, p)
        end
    end

    if not empty then
        tab = {"Timer", true, info.Start, info.Name, info.Time, CurTime(), "Save"}
    end

    NETWORK:StartNetworkMessageTimer(Watchers, "Spectate", tab)
end

function Replay:GenerateNotify(replay, varList)
    if not self.BotInfo[replay] or not self.BotInfo[replay].Start then return end
    return {"Timer", true, self.BotInfo[replay].Start, self.BotInfo[replay].Name, self.BotInfo[replay].Time, CurTime(), varList}
end

function Replay:GetPlayer(replay)
	for _, ply in pairs(player.GetBots()) do
		if ply.Style == replay and IsValid(ply) then -- dont use ply.style here
			return ply
		end
	end
	return nil
end

function Replay:SIDToProfile(sid)
    return util.SteamIDTo64(sid)
end

function Replay:GetInfo(replay)
    return self.BotInfo[replay]
end

function Replay:SetInfoData(replay, varData)
    self.BotInfo[replay] = varData
end

function Replay:SetInfo(ply, replay, bSet)
    local info = self.BotInfo[replay]
    if not info then
        ply:SetNWString("ReplayName", "No Time Recorded")
        ply:SetNWInt("Style", 0)
        return false
    end

    if info.Style then
        self:SetFramePosition(info.Style, 1)
    end

    if info.Start then
        ply:SetNWString("ReplayName", info.Name)
        ply:SetNWString("ProfileURI", self:SIDToProfile(info.SteamID))
        ply:SetNWFloat("Record", info.Time)
        ply:SetNWInt("Style", info.Style)
        ply:SetNWInt("Rank", -2)

        local pos = TIMER:GetRecordID(info.Time, info.Style)
        ply:SetNWInt("WRPos", pos > 0 and pos or 0)

        self.PerStyle[info.Style] = pos
    end

    if bSet then
        self.BotInfo[replay].Start = nil -- wait for actual start frame
        self.BotInfo[replay].Waiting = true 
        self.Initialized = true
        self.BotPlayer[ply] = replay
    end
end

function Replay:SetWRPosition(replay)
    local ply = self:GetPlayer(replay)
    if not Iv(ply) then return end

    local info = self.BotInfo[replay]
    if not info then
        ply:SetNWString("ReplayName", "No Time Recorded")
        ply:SetNWInt("Style", 0)
        return false
    end

    if info.Start then
        local pos = TIMER:GetRecordID(info.Time, replay)
        ply:SetNWInt("WRPos", pos > 0 and pos or 0)

        self.PerStyle[replay] = pos
    end
end

function Replay:SetFramePosition(replay, nFrame)
    if Iv(self:GetPlayer(replay)) and self.BotFrame[replay] then
        self:NotifyRestart(replay)

        if nFrame < self.BotFrames[replay] then
            self.BotFrame[replay] = nFrame
        end
    end
end

function Replay:GetFramePosition(replay)
    if Iv(self:GetPlayer(replay)) and self.BotFrame[replay] and self.BotFrames[replay] then
        return {self.BotFrame[replay], self.BotFrames[replay]}
    end

    return {0, 0}
end

function Replay:StripFromFrame(ply, frame)
    self.Frame[ply] = frame

    for i = frame, #self.Recording[ply] do
        self.Recording[ply][i] = nil
    end
end

function Replay:GetFrame(ply)
    return self.Frame[ply] or 0
end

-- Record player
local function BotRecord(ply, data)
    if  Replay.Recording[ply] then
        local origin = data:GetOrigin()
        local eyes = data:GetAngles()
        local frame = Replay.Frame[ply]

        Replay.Recording[ply][1][frame] = origin.x
        Replay.Recording[ply][2][frame] = origin.y
        Replay.Recording[ply][3][frame] = origin.z
        Replay.Recording[ply][4][frame] = eyes.p
        Replay.Recording[ply][5][frame] = eyes.y
        Replay.Recording[ply][7] = Replay.Recording[ply][7] or {} -- Track frame landing
        Replay.Recording[ply][7][frame] = ply:GetFlags() or 0


        Replay.Frame[ply] = frame + 1

    elseif Replay.BotPlayer[ply] then
        local style = Replay.BotPlayer[ply]
        local frame = Replay.BotFrame[style]

        if frame >= Replay.BotFrames[style] then
            if not Replay.BotInfo[style].BotCooldown then
                Replay.BotInfo[style].BotCooldown = CurTime()
                Replay.BotInfo[style].Start = CurTime() + 4
                Replay:NotifyRestart(style)
            end

            local nDifference = CurTime() - Replay.BotInfo[style].BotCooldown

            if nDifference >= 4 then
                Replay.BotFrame[style] = 1
                Replay.BotInfo[style].Start = CurTime()
                Replay.BotInfo[style].BotCooldown = nil
                Replay.BotInfo[style].CompletedRun = true
                return Replay:NotifyRestart(style)
            elseif nDifference >= 2 then
                frame = 1
            elseif nDifference >= 0 then
                frame = Replay.BotFrames[style]
            end

            local d = Replay.BotData[style]
            data:SetOrigin(Vector(d[1][frame], d[2][frame], d[3][frame]))
            return ply:SetEyeAngles(Angle(d[4][frame], d[5][frame], 0))
        end

        local d = Replay.BotData[style]
        data:SetOrigin(Vector(d[1][frame], d[2][frame], d[3][frame]))
        ply:SetEyeAngles(Angle(d[4][frame], d[5][frame], 0))

        if Replay.BotInfo[style].Frame and frame == Replay.BotInfo[style].Frame[1] then
            Replay.BotInfo[style].Start = CurTime()
            Replay:NotifyRestart(style)
        end

        Replay.BotFrame[style] = frame + 1
    end
end
hook.Add("SetupMove", "PositionRecord", BotRecord)

-- Save buttons
local function BotButtonRecord(ply, data)
    if Replay.Recording[ply] then
        Replay.Recording[ply][6][Replay.Frame[ply]] = data:GetButtons()
    elseif Replay.BotPlayer[ply] then
        data:ClearButtons()
        data:ClearMovement()

        local style = Replay.BotPlayer[ply]

        if Replay.BotData[style][6][Replay.BotFrame[style]] and ply:GetMoveType() == 0 then
            local buttons = tonumber(Replay.BotData[style][6][Replay.BotFrame[style]])
            data:SetButtons(buttons)
        else
        end
    end
end
hook.Add("StartCommand", "ButtonRecord", BotButtonRecord)

-- Load
hook.Add("Initialize", "SpawnBotsOnMapLoad", function()
    Replay:Setup()

    timer.Simple(5, function()
        if #player.GetBots() == 0 then
            Replay:CheckStatus()
        end
    end)

    timer.Create("EnsureReplayBots", 10, 0, function()
        if #player.GetBots() == 0 then
            Replay:CheckStatus()
        end
    end)
end)