--[[~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	🕒 Bunny Hop Server Timer
		by: fibzy (www.steamcommunity.com/id/fibzy_)

		file: sv_timer.lua
		desc: ⏲️ Handles server-side timing and logic for Bunny Hop runs.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~]]

-- Cache
local sq, Iv, floor, format, st = sql.Query, IsValid, math.floor, string.format, SysTime

-- Cvars
CreateConVar("timer_multiplier", "15", FCVAR_ARCHIVE, "Default timer multiplier.")
CreateConVar("timer_bonus_multiplier", "15", FCVAR_ARCHIVE, "Bonus timer multiplier.")

-- Timer
Timer = {
    Multiplier = GetConVar("timer_multiplier"):GetFloat(),
    BonusMultiplier = GetConVar("timer_bonus_multiplier"):GetFloat(),
    Options = 0,
    CheckpointTime = 0,
    CheckpointStartTick = 0,
    Tier = 1
}

timer_sounds = {}
local g_groundticks = 20

local ok, loadedReqwest = pcall(require, "reqwest")
if ok and loadedReqwest then
    reqwest = loadedReqwest
else
    UTIL:Notify(Color(255, 0, 0), "Module", "reqwest not found — skipping discord features.")
end

local WEBHOOK = file.Read("bhop-wr-webhook.txt", "DATA")
local WEBHOOKOFF = file.Read("bhop_wr-webhook-offstyles.txt", "DATA")

-- Config
function Timer:RefreshMultipliers()
    self.Multiplier = GetConVar("timer_multiplier"):GetFloat()
    self.BonusMultiplier = GetConVar("timer_bonus_multiplier"):GetFloat()
end

cvars.AddChangeCallback("timer_multiplier", function(_, _, newValue)
    Timer.Multiplier = tonumber(newValue) or 15
end)

cvars.AddChangeCallback("timer_bonus_multiplier", function(_, _, newValue)
    Timer.BonusMultiplier = tonumber(newValue) or 15
end)

-- Timer Data
TimerData = {}
TimerData.__index = TimerData

-- Initialize
function TimerData:Initialize()
    local obj = {
        Total = 0,
        Count = 0,
        Average = 0,
        Records = {},
        InitialRecord = 0,
    }
    setmetatable(obj, { __index = self })
    return obj
end

-- UTILS
function TIMER:EnsurePlayerTimer(ply)
    ply.TimerState = ply.TimerState or {
        fractionalTicks = 0,
        fullTicks = 0,
        wasInEndZone = false,
        inSpawn = true,
    }
    return ply.TimerState
end

-- Update Total Time
function TimerData:UpdateTotalTime(newTime, oldTime)
    if oldTime then
        self.Total = self.Total + (newTime - oldTime)
    else
        self.Total = self.Total + newTime
        self.Count = self.Count + 1
    end

    self:CalculateAverage()
end

-- Calculate Average
function TimerData:CalculateAverage()
    if self.Count > 0 then
        self.Average = self.Total / self.Count
    end
end

-- Add Record
function TimerData:AddRecord(newRecord)
    local found = false
    for i, record in ipairs(self.Records) do
        if record[1] == newRecord[1] then
            if newRecord[3] < record[3] then
                self.Records[i] = newRecord
            end
            found = true
            break
        end
    end

    if not found then
        table.insert(self.Records, newRecord)
    end

    table.sort(self.Records, function(a, b) return a[3] < b[3] end)
end

-- Get Records
function TimerData:GetRecords(page, pageSize)
    local startIndex = (page - 1) * pageSize + 1
    local endIndex = startIndex + pageSize - 1
    local records = {}

    for i = startIndex, endIndex do
        if self.Records[i] then
            table.insert(records, self.Records[i])
        end
    end
    return records
end

-- Get Records Count
function TimerData:GetRecordCount()
    return #self.Records
end

function TimerData:SetInitialRecord(record)
    self.InitialRecord = record
end

function TimerData:GetInitialRecord()
    return self.InitialRecord
end

function TimerData:GetAverage()
    return self.Average
end

-- Initialize Styles
function TIMER:InitializeStyles()
    for id, _ in pairs(self.Styles) do
        self.Styles[id].Data = TimerData:Initialize()
    end
end

TIMER:InitializeStyles()

-- Discord
local DISCORD_WR_WEBHOOK = file.Read("bhop-wr-webhook.txt", "DATA") or ""
if DISCORD_WR_WEBHOOK == "" then
    UTIL:Notify(Color(255, 255, 0), "Timer", "Discord webhook not set. High scores won't be posted.")
end

local timerPrefix = "Timer"

-- Timer print to chat
function TIMER:Print(target, ...)
    local args = {...}

    if type(args[1]) == "table" then
        local inputTable = args[1]
        local messageArgs = {unpack(inputTable)}
        UTIL:Print(target, timerPrefix, unpack(messageArgs))
    else
        UTIL:Print(target, timerPrefix, ...)
    end
end

-- Is valid timer
function TIMER:ValidTimer(ply, bonus)
    if not IsValid(ply) or not ply:IsPlayer() then return false end

    if ply:IsBot() or ply:GetNWInt("inPractice", false) then return false end

    local style = self:GetStyle(ply)
    if bonus then
        return style == self:GetStyleID("Bonus")
    else
        return style ~= self:GetStyleID("Bonus")
    end
end

util.AddNetworkString("ShowPopupNotification")

-- UI popups
function SendPopupNotification(ply, title, text, duration)
    net.Start("ShowPopupNotification")

    net.WriteString(title)
    net.WriteString(text)
    net.WriteFloat(duration or 5)

    if ply then
        net.Send(ply)
    else
        net.Broadcast()
    end
end

-- Starting | Stopping | Resetting | Updating
util.AddNetworkString("Timer_Update")
util.AddNetworkString("Timer_FinalUpdate")

function SendTimerUpdate(ply, startTick, endTick, fractionalTicks)
    NETWORK:StartNetworkMessage(ply, "TimerUpdate", ply, startTick or 0, endTick or 0, fractionalTicks or 0)
end

function SendFinalTimerUpdate(ply, fractionalTicks)
    NETWORK:StartNetworkMessage(ply, "TimerFinalUpdate", ply, fractionalTicks or 0)
end

-- Pre speed stopper
function TIMER:PreSpeedStop(ply)
    local velocity = ply:GetVelocity()
    local speed = velocity:Length2D()

    if speed > BHOP.Zone.JumpZoneSpeedCap then
        ply:SetLocalVelocity(Vector(0, 0, 0))

        local tooFastMessage = Lang:Get("TooFast", { tostring(math.ceil(speed)) })
        NETWORK:StartNetworkMessageTimer(ply, "Print", {"Timer", tooFastMessage})
        SendPopupNotification(ply, "Your speed is too fast!", 5)

        return true
    end
    return false
end

-- Can set in spawn
function TIMER:SetInSpawn(bool, bonus)
    local isBonusStyle = self.Style == TIMER:GetStyleID("Bonus")
    local isPracticeStyle = self.Style == TIMER:GetStyleID("Practice")

    if isPracticeStyle then
        if self.InSpawn then
            self.InSpawn = false
        end
        return
    end

    if bonus and isBonusStyle then
        self.InSpawn = bool
    elseif not bonus and not isBonusStyle then
        self.InSpawn = bool
    end
    
    if bool then
        self.Jumps = 0
    end
end

hook.Add("SetupMove", "TrackGroundTicks", function(ply, mv, cmd)
    if not IsValid(ply) then return end

    ply.groundTicks = ply.groundTicks or 0

    if ply:IsOnGround() then
        ply.groundTicks = (ply.groundTicks or 0) + 1
    else
        ply.groundTicks = 0
    end
end)

-- Start Timer
function TIMER:StartTimer(ply)
    if not self:ValidTimer(ply) then return end
    if ply.outsideSpawn then TIMER:Disable(ply) return end

    -- Tick based
    ply.iFractionalTicks = 0
    ply.iFullTicks = 0
    ply.time = engine.TickCount()
    ply.finished = nil
    ply.wasInEndZone = false
    ply.InStartZone = false

    -- Send Start Timer | InStartZone | ScoreBoard
    NETWORK:StartNetworkMessage(ply, "UpdateSingleVar", ply, "InStartZone", ply.InStartZone)
    NETWORK:StartNetworkMessage(ply, "TIMER/Start", ply, ply.time)
    NETWORK:StartNetworkMessageTimer(player.GetAll(), "Scoreboard", {"normal", ply, ply.time})

    -- Send Timer Update
    SendTimerUpdate(ply, ply.time, 0, 0)
    ply.freezeStrafes = false

    -- Strafe Count
    self:ResetStrafeCount(ply)

    if SYNC and SYNC.ResetStatistics then
        SYNC:ResetStatistics(ply)
    end

    -- Replays
    if Replay and Replay.TrimRecording then
        Replay:TrimRecording(ply)
    end
end

-- Reset Timer
function TIMER:ResetTimer(ply)
    ply:SetNWBool("inPractice", false)
    if not self:ValidTimer(ply) then return end

    -- Don’t allow resets if groundTicks is too low
    if (ply.groundTicks or 0) < 20 then return end
    if not ply.time then return end

    -- Tick based reset
    ply.time, ply.finished = nil, nil
    ply.iFractionalTicks = 0
    ply.iFullTicks = 0
    ply.wasInEndZone = false
    ply.InSpawn = true
    ply.InStartZone = true

    -- Send Start Timer | InStartZone | ScoreBoard
    NETWORK:StartNetworkMessage(ply, "UpdateSingleVar", ply, "InStartZone", ply.InStartZone)
    NETWORK:StartNetworkMessage(ply, "TIMER/Reset", ply)
    NETWORK:StartNetworkMessageTimer(player.GetAll(), "Scoreboard", {"normal", ply, ply.time})

    SendTimerUpdate(ply, 0, 0, 0)

    local observers = {ply}
    for _, v in ipairs(player.GetHumans()) do
        if IsValid(v:GetObserverTarget()) and v:GetObserverTarget() == ply then
            table.insert(observers, v)
        end
    end

    if self:GetStyle(ply) == self:GetStyleID("Segment") and self.waypoints then 
        NETWORK:StartNetworkMessageTimer(ply, "Print", {"Timer", "Your segmented waypoints have been reset."})
        Segment:Reset(ply)
    end

    -- Jumps
    PlayerJumps[ply] = 0
    NETWORK:StartNetworkMessage(observers, "jump_update", {ply, 0})

    if Spectator and Spectator.PlayerRestart then
        Spectator:PlayerRestart(ply)
    end

    self:ResetStrafeCount(ply)

    if SYNC and SYNC.ResetStatistics then
        SYNC:ResetStatistics(ply)
    end

    -- Replay
    if Replay and Replay.StartRecording then
        Replay:StartRecording(ply)
    end
end

-- Stop Timer
function TIMER:StopTimer(ply)
    if not ply.time or ply.wasInEndZone then return end

    ply.finished = engine.TickCount()
    self:UpdateTicks(ply)

    local tickTimeDiff = TIMER:ConvertTick(ply, ply.time, ply.finished, true, nil)

    -- Send Stop Timer | InStartZone | ScoreBoard
    NETWORK:StartNetworkMessage(ply, "TIMER/Finish", ply, tickTimeDiff)
    NETWORK:StartNetworkMessageTimer(player.GetAll(), "Scoreboard", {"normal", ply, ply.finished})

	if self:GetStyle(ply) == self:GetStyleID("Segment") then 
		Segment:Reset(ply)
	end

    self:Finish(ply, tickTimeDiff)

    -- Replay
    if Replay and Replay.StopRecording then
       Replay:StopRecording(ply, tickTimeDiff, ply.record)
    end

    ply.freezeStrafes = true
    ply.wasInEndZone = true
end

-- Stop any timer thats running
function TIMER:Disable(ply)
    if not IsValid(ply) then return false end
    if ply:IsBot() then return false end

    ply.time = nil
    ply.finished = nil
    ply.bonustime = nil
    ply.bonusfinished = nil

    NETWORK:StartNetworkMessage(ply, "TIMER/Reset")

    if Replay and Replay.StartRecording then
        Replay:StartRecording(ply)
    end

    self:ResetStrafeCount(ply)

    return true
end

-- Bonus Start
function TIMER:BonusStart(ply)
    if not self:ValidTimer(ply, true) then return end
    if ply.outsideSpawn then TIMER:Disable(ply) return end

    ply.bonustime = engine.TickCount()
    ply.iFractionalTicksBonus = 0
    ply.iFullTicksBonus = 0
    ply.InStartZone = false
    ply.freezeStrafes = false

    NETWORK:StartNetworkMessage(ply, "UpdateSingleVar", ply, "InStartZone", ply.InStartZone)
    self:SetJumps(ply, 0)
    NETWORK:StartNetworkMessage(ply, "TIMER/Start", ply, 2)


    if Replay and Replay.TrimRecording then
        Replay:TrimRecording(ply)
    end

    if Spectator and Spectator.PlayerRestart then
        Spectator:PlayerRestart(ply)
    end

    if SYNC and SYNC.ResetStatistics then
        SYNC:ResetStatistics(ply)
    end

    self:ResetStrafeCount(ply)

    NETWORK:StartNetworkMessageTimer(player.GetAll(), "Scoreboard", {"bonus", ply, ply.bonustime})
end

-- Bonus Stop
function TIMER:BonusStop(ply)
    if not self:ValidTimer(ply, true) then return end

    self:UpdateTicks(ply)
    ply.bonusfinished = engine.TickCount()
    local tickTimeDiff = TIMER:ConvertTick(ply, ply.bonustime, ply.bonusfinished, true, nil)

    if Replay and Replay.StopRecording then
         Replay:StopRecording(ply, tickTimeDiff, ply.record)
    end

    NETWORK:StartNetworkMessage(ply, "TIMER/Finish", ply, tickTimeDiff)
    self:Finish(ply, tickTimeDiff)

    SendTimerUpdate(ply, ply.bonustime, ply.bonusfinished, ply.iFractionalTicksBonus)
    SendFinalTimerUpdate(ply, ply.iFractionalTicksBonus)

    ply.freezeStrafes = true

    NETWORK:StartNetworkMessageTimer(player.GetAll(), "Scoreboard", {"bonus", ply, ply.bonusfinished})
end

-- Bonus Reset
function TIMER:BonusReset(ply)
    if not self:ValidTimer(ply, true) then return end

    -- Don’t allow resets if groundTicks is too low
    if (ply.groundTicks or 0) < g_groundticks then return end

    ply.bonustime = nil
    ply.bonusfinished = nil
    ply.iFractionalTicksBonus = 0
    ply.iFullTicksBonus = 0

    NETWORK:StartNetworkMessage(ply, "TIMER/Reset", ply)

    if Replay and Replay.StartRecording then
         Replay:StartRecording(ply)
    end

    if Spectator and Spectator.PlayerRestart then
        Spectator:PlayerRestart(ply)
    end

    if SYNC and SYNC.ResetStatistics then
        SYNC:ResetStatistics(ply)
    end

    self:ResetStrafeCount(ply)

    NETWORK:StartNetworkMessageTimer(player.GetAll(), "Scoreboard", {"bonus", ply, ply.bonustime})
end

-- Timer strafe counter
function TIMER:ResetStrafeCount(ply)
    ply.Strafes = 0
    ply.TotalStrafes = 0
    ply.StrafeDirection = nil
end

-- Strafes Count
local function GetStrafes(ply, key)
    if not IsValid(ply) or not ply:Alive() then return end
    if not ply.Strafes then ply.Strafes = 0 end
    if not ply.TotalStrafes then ply.TotalStrafes = 0 end
    if ply.freezeStrafes then return end

    if key == IN_MOVELEFT or key == IN_MOVERIGHT then
        ply.Strafes = ply.Strafes + 1
        ply.TotalStrafes = ply.TotalStrafes + 1
    end
end
hook.Add("KeyRelease", "TrackStrafes", GetStrafes)

-- Combie two tables
function TIMER:ConcatTables(t1, t2)
    return table.Add(t1, t2)
end

-- When the player gets a new WR
function TIMER:WorldRecordCompletion(ply, time, currentWR, formattedTime)
    local StyleName = TIMER:StyleName(ply.style)
    local styleData = self.Styles[ply.style].Data

    styleData:SetInitialRecord(time)

    local ID_WR = "WorldRecord"
    
    local WRDifference
    if currentWR == 0 then
        WRDifference = "No previous WR"
    else
        local timeDiff = currentWR - time
       WRDifference = ("%s%s"):format(timeDiff < 0 and "-" or "", TIMER:WRConvert2(math.abs(timeDiff)))

    end

    local WRData = { StyleName, ply:Name(), nil, formattedTime, WRDifference }
    local worldRecordMessage = Lang:Get(ID_WR, WRData)
    
    local rainbowText = TIMER:Rainbow("New " .. StyleName .. " World Record! ")
    local fullMessage = TIMER:ConcatTables(rainbowText, worldRecordMessage)

    BHDATA:Broadcast("Print", { "Timer", fullMessage })
    SendPopupNotification(nil, "Notification", "New World Record by " .. ply:Name(), 2)
end

-- When the player finished
function TIMER:Finish(ply, time)
    local record = ply.record or 0
    local isBonusStyle = ply.style == self:GetStyleID("Bonus")
    local startTick = isBonusStyle and ply.bonustime or ply.time
    local endTick = isBonusStyle and ply.bonusfinished or ply.finished

    local styleID = self:GetStyle(ply) or "Unknown"
    local diff = record > 0 and time - record or nil
    local slower = diff and ((diff < 0 and "-" or "+") .. self:SecondsToClock(math.abs(diff))) or "No previous time"
    local syncvalue, syncfinish = SYNC:GetFinishingSync(ply), ""

    if syncvalue then
        syncfinish = " (With " .. syncvalue .. "% Sync)"
        ply.LastSync = syncvalue
    end

    local style = self:GetStyle(ply)
    local timescale = (style == self:GetStyleID("TAS")) and (playerTimescales[ply] or 1) or 1
    local totalSeconds = self:ConvertTick(ply, startTick, endTick, true, nil) * timescale
    local formattedTime = self:SecondsToClock(totalSeconds)
    local OldRecord = record

    MySQL:Start("SELECT * FROM timer_times WHERE map = '" .. game.GetMap() .. "' AND style = " .. ply.style .. " ORDER BY time ASC LIMIT 1", function(WR)
      local currentWR = WR and WR[1] and tonumber(WR[1].time) or 0

        MySQL:Start("SELECT COUNT(*) AS totalRecords FROM timer_times WHERE map = '" .. game.GetMap() .. "' AND style = " .. ply.style, function(TotalRecords)
            local nRec = TotalRecords and TotalRecords[1] and tonumber(TotalRecords[1]["totalRecords"]) or 0

            MySQL:Start("SELECT COUNT(*) AS Rank FROM timer_times WHERE map = '" .. game.GetMap() .. "' AND time < " .. time .. " AND style = " .. ply.style, function(Rank)
                local playerRank = Rank and Rank[1] and tonumber(Rank[1]["Rank"]) or 0
                local id = playerRank + 1

                local willBeSaved = record == 0 or time < record
                local totalRecordsDisplay = willBeSaved and (nRec + 1) or nRec

                -- Get accurate rank
                local id = playerRank + 1

                -- Prevent weird edge cases
                if id > totalRecordsDisplay then id = totalRecordsDisplay end
                if id < 1 then id = 1 end

                -- If time >= WR, you're definitely not #1, fix display
                if time > currentWR and currentWR > 0 then
                    if id == 1 then id = 2 end -- Prevent false #1 when slower than WR
                end

                local StyleName = self:StyleName(ply.style)
                local ID = "TimerFinish"

                local Data = { StyleName, ply:Name(), "#" .. id, formattedTime, slower, id .. "/" .. totalRecordsDisplay }

                if time < currentWR or currentWR == 0 then
                    self:LoadMapData()
                    timer.Simple(1, function()
                        self:PostDiscordWR(ply, time, ply.style, currentWR)
                    end)

                    self:WorldRecordCompletion(ply, time, currentWR, formattedTime)
                end

                NETWORK:StartNetworkMessageTimer(nil, "Print", { "Timer", Lang:Get(ID, Data) })

                local FinishingStatsData = { 
                    ply:Name(),
                    ply.LastSync or 0,
                    self:GetJumps(ply) or 0,
                    ply.TotalStrafes or 0
                }
                NETWORK:StartNetworkMessageTimer(nil, "Print", { "Timer", Lang:Get("FinishingStats", FinishingStatsData) })

                SendPopupNotification(nil, "Notification", "New time by " .. ply:Name(), 2)

                -- Didn't improve Bad Sounds
                if record ~= 0 and time >= record then
                     NETWORK:StartNetworkMessage(ply, "PlayBadWRRoast")
                    return
                end

                ply.record = time
                ply.SpeedRequest = ply.style

                ply:SetNWFloat("Record", ply.record)
                self:AddRecord(ply, time, OldRecord)
            end)
        end)
    end)
end

-- Timer time calculating 
function TIMER:CalculateTickTime(ply)
    local tickInterval = st()
    local timescale = ply:GetLaggedMovementValue() or 1
    return tickInterval * timescale
end

function TIMER:UpdateTicks(ply)
    local timeIncrement = self:CalculateTickTime(ply)
    ply.iFractionalTicks = (ply.iFractionalTicks or 0) + floor(timeIncrement * 10000)
    local wholeTicks = floor(ply.iFractionalTicks / 10000)
    ply.iFractionalTicks = ply.iFractionalTicks - (wholeTicks * 10000)
    ply.iFullTicks = (ply.iFullTicks or 0) + wholeTicks
end

function TIMER:ConvertTick(ply, startTick, endTick, finished, snapshot)
    local tickRate = engine.TickInterval()
    local fullTicks = endTick - startTick
    local fractionalTicks = snapshot and snapshot.iFractionalTicks or ply.iFractionalTicks or 0

    if finished and fractionalTicks > 10000 then
        fractionalTicks = 10000
    end

    local totalTicks = fullTicks + (fractionalTicks / 10000)
    return totalTicks * tickRate
end

function TIMER:SecondsToClock(seconds)
    local wholeSeconds = floor(seconds)
    local milliseconds = floor((seconds - wholeSeconds) * 1000)
    local hours = floor(wholeSeconds / 3600)
    local minutes = floor((wholeSeconds % 3600) / 60)
    local secs = wholeSeconds % 60

    if hours > 0 then
        return format("%d:%02d:%02d.%03d", hours, minutes, secs, milliseconds)
    else
        return format("%02d:%02d.%03d", minutes, secs, milliseconds)
    end
end

-- Add the new record
function TIMER:AddRecord(ply, time, old)
    local styleID = ply.style
    local styleData = self.Styles[styleID].Data

    local steamid = ply:SteamID()
    local map = game.GetMap()

    MySQL:Start(string.format([[
        INSERT INTO timer_mapplays (uid, map, completions)
        VALUES ('%s', '%s', 1)
        ON DUPLICATE KEY UPDATE completions = completions + 1
    ]], steamid, map))

    -- continue as normal
    MySQL:Start("SELECT COUNT(*) AS runCount FROM timer_times WHERE map = '" .. map .. "' AND style = " .. styleID, function(RunData)
        local runID = RunData and RunData[1] and tonumber(RunData[1]["runCount"]) or 0
        runID = runID + 1

        MySQL:Start("SELECT time FROM timer_times WHERE map = '" .. map .. "' AND uid = '" .. steamid .. "' AND style = " .. styleID, function(OldEntry)
            if OldEntry and OldEntry[1] then
                if time < OldEntry[1].time then
                    styleData:UpdateTotalTime(time, old)

                    MySQL:Start("UPDATE timer_times SET player = " .. sql.SQLStr(ply:Name()) .. ", time = " .. time .. ", date = '" .. TIMER:GetDate() .. "' WHERE map = '" .. map .. "' AND uid = '" .. steamid .. "' AND style = " .. styleID, function()
                        ply.RunID = runID
                        self:HandleRecordCompletion(ply, time, old, styleData, runID)
                    end)
                else
                    ply.RunID = runID
                    self:HandleRecordCompletion(ply, time, old, styleData, runID)
                end
            else
                styleData:UpdateTotalTime(time, nil)

                MySQL:Start("INSERT INTO timer_times (uid, player, map, style, time, points, date, tier) VALUES ('" ..
                    steamid .. "', " ..
                    sql.SQLStr(ply:Name()) .. ", '" ..
                    map .. "', " ..
                    styleID .. ", " ..
                    time .. ", 0, '" ..
                    TIMER:GetDate() .. "', " ..
                    Timer.Tier .. ")", function()
                    
                    ply.RunID = runID
                    self:HandleRecordCompletion(ply, time, old, styleData, runID)
                end)
            end
        end)
    end)
end

local function GetRainbowColor()
    local rainbowColors = {
        16711680,
        16744192,
        16776960,
        65280,
        255,
        16711935,
        65535
    }
    return rainbowColors[math.random(1, #rainbowColors)]
end

function TIMER:PostDiscordWR(ply, time, styleID, currentWR)
    if not reqwest then return end

    -- Decide which webhook to use based on style
    local webhookURL
    if styleID == TIMER:GetStyleID("Normal") or styleID == TIMER:GetStyleID("Bonus") then
        if not WEBHOOK then return end
        webhookURL = WEBHOOK
    else
        if not WEBHOOKOFF then return end
        webhookURL = WEBHOOKOFF
    end

    local playerName = ply:Nick()
    local playerSteam64 = ply:SteamID64()
    local formattedTime = TIMER:WRConvert2(time)
    local sync = (ply.LastSync or 0) .. "%"
    local jumps = TIMER:GetJumps(ply) or 0
    local strafes = ply.TotalStrafes or 0
    local topSpeed = math.floor((ply.LastSpeedData and ply.LastSpeedData[1]) or 0)
    local avgSpeed = math.floor((ply.LastSpeedData and ply.LastSpeedData[2]) or 0)

    local points = Timer.Multiplier
    local serverIP = game.GetIPAddress()
    local mapName = game.GetMap()
    local serverName = GetHostName()
    local timestamp = os.date("!%Y-%m-%d %H:%M:%S")
    local joinLink = "https://steamcommunity.com/linkfilter/?url=steam://connect/" .. serverIP
    local styleName = TIMER:StyleName(styleID) or "Unknown"

    local WRDifference
    if currentWR == 0 then
        WRDifference = "No previous WR"
    else
        local timeDiff = currentWR - time
        WRDifference = ("-%s"):format(TIMER:WRConvert2(math.abs(timeDiff)))
    end

    local runID = ply.RunID or "Unknown"

    local fields = {
        {
            name = "**Player**",
            value = string.format("[**%s**](https://steamcommunity.com/profiles/%s)", playerName, playerSteam64),
            inline = true
        },
        {
            name = "**Time**",
            value = string.format("`%s` (WR %s)", formattedTime, WRDifference),
            inline = true
        },
        {
            name = "**Additional**",
            value = string.format(
                "**Sync:** %s\n **Strafes:** %d\n **Jumps:** %d\n **Top Speed:** %d u/s\n **Avg Speed:** %d u/s\n **Run ID:** `%s`\n **Date:** %s\n **Points:** %d",
                sync, strafes, jumps, topSpeed, avgSpeed, runID, timestamp, points
            ),
            inline = false
        },
        {
            name = "**Server**",
            value = string.format("`[%s] | BunnyHop | 100-tick`", serverName),
            inline = false
        }
    }

    local compiled = {
        username = "Server Record",
        embeds = {{
            author = {
                name = "Server Record | " .. styleName .. " | " .. mapName,
                icon_url = "https://i.imgur.com/YREHNoE.png"
            },
            color = GetRainbowColor(),
            fields = fields,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            footer = { text = "Top time on server" }
        }},
        components = {{
            type = 1,
            components = {{
                type = 2,
                label = "Join Server",
                style = 5,
                url = joinLink
            }}
        }}
    }

    reqwest({
        method = "POST",
        url = webhookURL,
        body = util.TableToJSON(compiled, false),
        headers = {
            ["Content-Type"] = "application/json",
            ["User-Agent"] = "GMod-Timer/1.0",
        },
        timeout = 5,
        success = function(status, body, headers)
            UTIL:Notify(Color(0, 0, 255), "Discord", "Discord WR Webhook sent successfully! Status: " .. status)
        end,
        failed = function(err, errExt)
            UTIL:Notify(Color(0, 0, 255), "Discord", "Discord WR Webhook failed! Error: " .. tostring(err))
        end
    })
end

-- When the player finished the time
function TIMER:HandleRecordCompletion(ply, time, old, styleData)
    self:RecalculatePoints(ply.style)
    self:UpdateRank(ply)
    self:AddScore(ply)

    local id = 1
    local query = "SELECT t1.*, (SELECT COUNT(*) + 1 FROM timer_times AS t2 WHERE t2.time < t1.time AND map = '" .. 
    game.GetMap() .. "' AND style = " .. ply.style .. ") AS Rank FROM timer_times t1 WHERE t1.uid = '" .. 
    ply:SteamID() .. "' AND t1.map = '" .. game.GetMap() .. "' AND t1.style = " .. ply.style

    MySQL:Start(query, function(Rank)
        if not Rank or not Rank[1] then
            return
        end

        id = tonumber(Rank[1].Rank) or 1

        styleData:AddRecord({ply:SteamID(), Rank[1]["player"], time, self:Null(Rank[1]["date"]), nil})

        TIMER:SetRecord(ply, time, ply.style)
        NETWORK:StartNetworkMessage(ply, "TIMER/Record", ply, time, ply.style)

        if id == 1 then
            self:RecalculateInitial(ply.style)
        end

        if id <= 10 then
            self:UpdateWRs(player.GetHumans())
            self:SetRankMedal(ply, id)
        end

        if Replay and Replay.PerStyle and Replay.SetWRPosition then
            local p = Replay.PerStyle[ply.style] or 0
            if p > 0 and id <= p then
                Replay:SetWRPosition(ply.style)
            end
        end
    end)
end

function TIMER:LoadSounds()
    timer_sounds = {}

    local foundSounds = file.Find("sound/wrsfx/*", "GAME")
    for _, snd in ipairs(foundSounds) do
        local fullPath = "wrsfx/" .. snd

        resource.AddFile("sound/" .. fullPath)

        if not table.HasValue(BHOP.ExcludeWRSounds, fullPath) then
            table.insert(timer_sounds, snd)
            util.PrecacheSound(fullPath)
        end
    end
end

function TIMER:GetNextSound()
    if #timer_sounds == 0 then return "" end
    return timer_sounds[math.random(#timer_sounds)]
end

function TIMER:Broadcast()
    local soundPath = TIMER:GetNextSound()
    if soundPath == "" then return end

    NETWORK:StartNetworkMessage(nil, "WRSoundGlobal", soundPath)
end

TIMER:LoadSounds()

function TIMER:RecalculateInitial(id)
    if not self.Styles or not self.Styles[id] or not self.Styles[id].Data then
        return
    end

    local styleData = self.Styles[id].Data

    if not styleData.Records or not styleData.Records[1] or not styleData.Records[1][3] then
        styleData:SetInitialRecord(0)
        return
    end

    local initialRecord = tonumber(styleData.Records[1][3]) or 0
    styleData:SetInitialRecord(initialRecord)

    BHDATA:Broadcast("Timer", { "Initial", styleData:GetInitialRecord() })

    -- Play WR Sounds
    TIMER:Broadcast()
end

function TIMER:SendInitialRecords(ply)
    for id, _ in pairs(self.Styles) do
        local styleData = self.Styles[id].Data
        NETWORK:StartNetworkMessageTimer(ply, "Timer", { "Initial", styleData:GetInitialRecord() })
    end
end

function TIMER:LoadMapData()
    local mapName = MySQL:Escape(game.GetMap())

    MySQL:Start("SELECT multiplier, bonusmultiplier, options, tier FROM timer_map WHERE map = " .. mapName .. " LIMIT 1", function(result)
        if result and result[1] then
            Timer.Multiplier = tonumber(result[1]["multiplier"]) or 0
            Timer.BonusMultiplier = tonumber(result[1]["bonusmultiplier"]) or 0
            Timer.Options = tonumber(result[1]["options"]) or 0
            Timer.Tier = tonumber(result[1]["tier"]) or 1

            UTIL:Notify(Color(255, 255, 0), "Timer", "Loaded map data: Main Points: " .. Timer.Multiplier .. ", Bonus Points: " .. Timer.BonusMultiplier .. ", Options: " .. Timer.Options .. ", Tier: " .. Timer.Tier)
        else
            UTIL:Notify(Color(255, 0, 0), "Timer", "No entry found for map " .. mapName .. ". Using default values.")
            Timer.Multiplier = 0
            Timer.BonusMultiplier = 0
            Timer.Options = nil
            Timer.Tier = 1
        end
    end)
end

-- Load all records
function TIMER:LoadRecords()
    if not self.Styles then return end

    self:LoadMapData()

    for id, _ in pairs(self.Styles) do
        if not self.Styles[id] or not self.Styles[id].Data then
            UTIL:Notify(Color(255, 255, 0), "Timer", "Error: Missing style data for ID:", id)
            return
        end

        MySQL:Start("SELECT SUM(time) AS Sum, COUNT(time) AS nCount, AVG(time) AS nAverage FROM timer_times WHERE map = '" .. game.GetMap() .. "' AND style = " .. id, function(Query) 
            local styleData = self.Styles[id].Data
            styleData.Total = self:Assert(Query, "Sum") and tonumber(Query[1]["Sum"]) or 0
            styleData.Count = self:Assert(Query, "nCount") and tonumber(Query[1]["nCount"]) or 0
            styleData.Average = self:Assert(Query, "nAverage") and tonumber(Query[1]["nAverage"]) or 0
        end)
    end

    for id, _ in pairs(self.Styles) do
        if not self.Styles[id] or not self.Styles[id].Data then
            UTIL:Notify(Color(255, 255, 0), "Timer", "Error: Missing style data for ID:", id)
            return
        end

        MySQL:Start("SELECT * FROM timer_times WHERE map = '" .. game.GetMap() .. "' AND style = " .. id .. " ORDER BY time ASC", function(Rec) 
            local styleData = self.Styles[id].Data
            styleData.Records = {}

            if self:Assert(Rec, "uid") then
                for _, data in pairs(Rec) do
                    table.insert(styleData.Records, {
                        data["uid"], 
                        data["player"], 
                        tonumber(data["time"]), 
                        self:Null(data["date"]), 
                        tostring(self:Null(data["data"])),
                        tonumber(data["tier"]) or 1
                    })
                end
            end
        end)
    end

    for id, _ in pairs(self.Styles) do
        if not self.Styles[id] or not self.Styles[id].Data then
            UTIL:Notify(Color(255, 255, 0), "Timer", "Error: Missing style data for ID:", id)
            return
        end

        local styleData = self.Styles[id].Data
        if styleData.Records and styleData.Records[1] and styleData.Records[1][3] then
            styleData:SetInitialRecord(tonumber(styleData.Records[1][3]))
        end
    end
end

function StringToTab(szInput)
    if type(szInput) ~= "string" then
        return {}
    end

    local tab = string.Explode(" ", szInput)
    for k, v in pairs(tab) do
        if tonumber(v) then tab[k] = tonumber(v) end
    end
    return tab
end

function TIMER:GetTopSteam(style, amount)
	local list = {}
	local recordStyle = Records[style]

	if recordStyle then
		for i = 1, math.min(amount, #recordStyle) do
			list[i] = recordStyle[i].szUID
		end
	end

	return list
end

function TIMER:GetPlayerWRs(uid, style, all)
	local out = { 0, 0, 0 }
	local wrCache = WRTopCache[uid] or {}

	for _, data in ipairs(wrCache) do
		local ts = data.nStyle
		if ts then
			out[1] = out[1] + 1
			if ts == style then
				out[2] = out[2] + 1
			else
				out[3] = out[3] + 1
			end

			if all then
				out.Rest = out.Rest or {}
				out.Rest[ts] = (out.Rest[ts] or 0) + 1
			end
		end
	end

	return out
end

function TIMER:AddSpeedData(ply, tab)
    local record = ply.record or 0

    if not ply.SpeedRequest or ply.SpeedRequest <= 0 then
        ply.SpeedRequest = ply.style
    end

    local styleID = tonumber(ply.SpeedRequest)
    if not styleID or styleID <= 0 or not self.Styles[styleID] then
        return
    end

    -- Only save if player has a real time
    if record > 0 then
        -- Validate all inputs first, don't write if anything is nil!
        local avgSpeed = tonumber(tab[1])
        local topSpeed = tonumber(tab[2])
        local jumpCount = self:GetJumps(ply, 0)
        local sync = tonumber(ply.LastSync)
        local strafes = tonumber(ply.TotalStrafes)

        -- If any value is nil, bail out. Don't save!
        if not avgSpeed or not topSpeed or not jumpCount or not sync or not strafes then
            return
        end

        -- Round speeds, format string safely
        avgSpeed = math.floor(avgSpeed)
        topSpeed = math.floor(topSpeed)

        ply.LastSpeedData = { topSpeed, avgSpeed }

        local szData = string.format("%d %d %d %.2f %d", avgSpeed, topSpeed, jumpCount, sync, strafes)
        local dataSQL = sql.SQLStr(szData)

        local steamid = ply:SteamID()
        local map = game.GetMap()

        MySQL:Start(string.format([[
            UPDATE timer_times 
            SET data = %s 
            WHERE uid = '%s' AND map = '%s' AND style = %d
        ]], dataSQL, steamid, map, styleID))
    end
end

function TIMER:AddPlays()
    local mapName = MySQL:Escape(game.GetMap())

    MySQL:Start("SELECT plays FROM timer_map WHERE map = " .. mapName, function(result)
        if result and result[1] then
            local newPlays = tonumber(result[1]["plays"]) + 1
            MySQL:Start("UPDATE timer_map SET plays = " .. newPlays .. " WHERE map = " .. mapName)
            TIMER.PlayCount = newPlays
        else
            MySQL:Start("INSERT INTO timer_map (map, plays) VALUES (" .. mapName .. ", 1)")
            TIMER.PlayCount = 1
        end
    end)
end

function TIMER:RecalculatePoints(style)
    local Mult = self:GetMultiplier(style)
    local styleData = self.Styles[style].Data

    MySQL:Start("UPDATE timer_times SET points = " .. Mult .. " * (" .. styleData.Average .. " / time) WHERE map = '" .. game.GetMap() .. "' AND style = " .. style)

    local Fourth, Double = Mult / 4, Mult * 2
    MySQL:Start("UPDATE timer_times SET points = " .. Double .. " WHERE map = '" .. game.GetMap() .. "' AND style = " .. style .. " AND points > " .. Double)
    MySQL:Start("UPDATE timer_times SET points = " .. Fourth .. " WHERE map = '" .. game.GetMap() .. "' AND style = " .. style .. " AND points < " .. Fourth)
end

function TIMER:GetRecordID(time, style)
    local styleData = self.Styles[style].Data
    local records = styleData.Records

    for pos, data in ipairs(records) do
        if time <= data[3] then
            return pos
        end
    end
    return #records + 1
end

function TIMER:GetRecordList(style, page, callback)
    local pageSize = 7
    local offset = (page - 1) * pageSize

    MySQL:Start("SELECT uid, player, time, date, data FROM timer_times WHERE map = '" .. game.GetMap() .. "' AND style = " .. style .. " ORDER BY time ASC LIMIT " .. pageSize .. " OFFSET " .. offset, function(result)
        local records = {}

        if result then
            for _, row in ipairs(result) do

                local rawData = row.data
                local speedData = (rawData and rawData ~= "") and StringToTab(rawData) or {}

                table.insert(records, {
                    row.uid,
                    row.player,
                    tonumber(row.time),
                    row.date,
                    speedData
                })
            end
        end

        if callback then
            callback(records)
        end
    end)
end

function TIMER:GetRecordCount(style)
    local styleData = self.Styles[style] and self.Styles[style].Data
    if not styleData then
        return 0
    end

    return styleData:GetRecordCount()
end

function TIMER:GetMultiplier(style)
	if style == TIMER:GetStyleID("Bonus") then return Timer.BonusMultiplier end
	return Timer.Multiplier
end

function TIMER:GetAverage(style)
    local styleData = self.Styles[style] and self.Styles[style].Data
    if not styleData then return 0 end
    return styleData.Average or 0
end

function TIMER:GetPointsForMap(runTime, style)
    if runTime == 0 then return 0 end

    local multiplier = self:GetMultiplier(style)

    local averageTime = self:GetAverage(style)
    local points = multiplier * (averageTime / runTime)

    if points > multiplier * 2 then
        points = multiplier * 2
    elseif points < multiplier / 4 then
        points = multiplier / 4
    end

    return points
end

function TIMER:GetPlayerStats(ply)
    local totalTopTimes = 0
    local worldRecordCount = 0

    for styleID, styleData in pairs(self.Styles) do
        if styleData and styleData.Data then
            for _, record in ipairs(styleData.Data.Records) do
                if record[1] == ply:SteamID() then
                    totalTopTimes = totalTopTimes + record[3]
                    if record == styleData.Data.Records[1] then
                        worldRecordCount = worldRecordCount + 1
                    end
                end
            end
        end
    end

    return totalTopTimes, worldRecordCount
end

-- UI
function TIMER:SendWRList(ply, page, style, map)
    if map then
        self:SendRemoteWRList(ply, map, style, page, true)
    else
        self:GetRecordList(style, page, function(records)
            UI:SendToClient(ply, "wr", records, map, style, page, true)
        end)
    end
end

-- Get the WR
function TIMER:GetWR(style)
    local styleData = self.Styles[style] and self.Styles[style].Data
    if not styleData then
        return { "No WR", 0 }
    end

    if not styleData.Records or #styleData.Records == 0 then
        return { "No WR", 0 }
    end

    local wr = styleData.Records[1]
    if wr then
        return { wr[2], wr[3] }
    else
        return { "No WR", 0 }
    end
end

TIMER.WRCache = {}

local string_format = string.format
local math_floor = math.floor

function TIMER:WRConvert2(ns)
    if table.Count(TIMER.WRCache) > 1000 then
        UTIL:Notify(Color(255, 255, 0), "Timer", "TIMER.WRCache exceeded 1000 entries. Clearing cache...")
        TIMER.WRCache = {}
    end

    if TIMER.WRCache[ns] then
        return TIMER.WRCache[ns]
    end

    local hours = math_floor(ns / 3600)
    local minutes = math_floor(ns / 60 % 60)
    local seconds = math_floor(ns % 60)
    local milliseconds = math_floor(ns * 1000 % 1000)

    local result
    if hours > 0 then
        result = string_format("%d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
    else
        result = string_format("%02d:%02d.%03d", minutes, seconds, milliseconds)
    end

    TIMER.WRCache[ns] = result
    return result
end

-- Update the WR
function TIMER:UpdateWRs(ply)
    local wrs = {}

    for id, styleData in ipairs(self.Styles) do
        local styleID = id
        if styleID and self:IsValidStyle(styleID) then
            wrs[styleID] = self:GetWR(styleID)
        end
    end

    NETWORK:StartNetworkMessage(ply, "UpdateWR", wrs)
end

util.AddNetworkString("RequestWRList")
util.AddNetworkString("WRList")

-- Record Stats
util.AddNetworkString("SendRecordData")
util.AddNetworkString("RequestRecordStats")
util.AddNetworkString("SendGroupStats")

-- Get Record Placement
function TIMER:GetPlacement(ply, style)
    local data = self.Styles[style] and self.Styles[style].Data
    if not data then return nil end

    local steamid = ply:SteamID()

    for i, record in ipairs(data.Records or {}) do
        if record[1] == steamid then
            return "#" .. i
        end
    end

    return nil
end

-- Group Stats
function TIMER:SendGroupStats(ply, styleID)
    local wr = self:GetMapWRTime(game.GetMap(), styleID)
    if not wr or wr == 0 then return end

    local thresholds = {
        wr + 15,
        wr + 30,
        wr + 60,
        wr + 90,
        wr + 120,
    }

    local formatted = {}
    for _, t in ipairs(thresholds) do
        table.insert(formatted, self:WRConvert2(t))
    end

    net.Start("SendGroupStats")
    net.WriteUInt(styleID, 8)
    net.WriteString(self:WRConvert2(wr)) -- Base WR
    net.WriteTable(formatted)
    net.Send(ply)
end

-- Group Indexed
local function GetGroupIndex(wr, time)
    local diff = time - wr

    if diff <= 15 then return 1
    elseif diff <= 30 then return 2
    elseif diff <= 60 then return 3
    elseif diff <= 90 then return 4
    elseif diff <= 120 then return 5
    else return 6 end
end

-- Stats for Records Menu sending
function TIMER:SendRecordData(requester, target)
    if not IsValid(requester) or not IsValid(target) then return end

    local plyStyle = target.style or 1
    local steamid = target:SteamID()

    local wrTime, placementt = "N/A", "#?"
    local dataStr = nil

    local query = string.format([[
        SELECT t1.time, t1.data,
        (SELECT COUNT(*) + 1 FROM timer_times AS t2 WHERE t2.map = t1.map AND t2.style = t1.style AND t2.time < t1.time) AS Rank
        FROM timer_times AS t1
        WHERE t1.uid = '%s' AND t1.map = '%s' AND t1.style = %d LIMIT 1
    ]], steamid, game.GetMap(), plyStyle)

    MySQL:Start(query, function(result)
        if result and result[1] then
            wrTime = self:WRConvert2(result[1].time)
            placementt = "#" .. (result[1].Rank or "?")
            dataStr = result[1].data
        else
            print("[DEBUG] No record found for player:", target:Nick(), "on", game.GetMap(), "style:", plyStyle)
        end

        local topSpeed, avgSpeed = "0 u/s", "0 u/s"
        local sync, jumps, strfs = "0%", 0, 0

        if dataStr and type(dataStr) == "string" then
            local parts = string.Explode(" ", dataStr)
            topSpeed = (parts[1] and tonumber(parts[1]) or 0) .. " u/s"
            avgSpeed = (parts[2] and tonumber(parts[2]) or 0) .. " u/s"
            jumps = tonumber(parts[3]) or 0
            sync = (parts[4] and parts[4] .. "%") or "0%"
            strfs = tonumber(parts[5]) or 0
        else
            print("[DEBUG] Bad dataStr:", dataStr, "Type:", type(dataStr))
        end

        -- 🧮 Get extra stats
        TIMER:GetPlayerRunPoints(target, function(realPoints)
            MySQL:Start("SELECT completions FROM timer_mapplays WHERE uid = '" .. steamid .. "' AND map = '" .. game.GetMap() .. "'", function(result)
                local completions = result and result[1] and tonumber(result[1].completions) or 0
                local cachedPoints = Player.Points[steamid] and Player.Points[steamid][plyStyle] or realPoints or 0
                local wr = TIMER:GetMapWRTime(game.GetMap(), plyStyle) or 0
                local recordTime = target.record or 0

                local groupIndex = GetGroupIndex(wr, recordTime)

                local record = {
                    name = target:Nick(),
                    steamid = steamid,
                    time = wrTime,
                    jumps = jumps,
                    strafes = strfs,
                    points = cachedPoints,
                    gain = target.gain or "0%",
                    sync = sync,
                    speed = topSpeed .. " (avg " .. avgSpeed .. ")",
                    completions = completions,
                    map = game.GetMap(),
                    style = plyStyle,
                    placement = placementt,
                    completedGroups = groupIndex
                }

                -- Send to client live!
                net.Start("SendRecordData")
                net.WriteEntity(target)
                net.WriteTable(record)
                net.Send(requester)

                -- Also send group tier info
                TIMER:SendGroupStats(requester, plyStyle)
            end)
        end)
    end)
end

net.Receive("RequestRecordStats", function(len, ply)
    local target = net.ReadEntity()

    if not IsValid(ply) or not IsValid(target) or not target:IsPlayer() then return end
    TIMER:SendRecordData(ply, target)
end)

-- For New UI
net.Receive("RequestWRList", function(len, ply)
    local mapName = net.ReadString()
    local styleArg = net.ReadString():lower()
    local page = net.ReadInt(32)

    local foundStyleID = nil

    for index, data in ipairs(TIMER.Styles) do
        local command = data[3] and data[3][1]:lower()
        if command == styleArg then
            foundStyleID = index
            break
        end
    end

    local styleID = foundStyleID or TIMER:GetStyleID("Normal")

    if not TIMER:IsValidStyle(styleID) then return end

    local wrList = TIMER:GetRecordListForNewUI(styleID, page)

    net.Start("WRList")
    net.WriteTable({
        records = wrList,
        page = page,
        total = TIMER:GetRecordCountForNewUI(styleID)
    })
    net.Send(ply)
end)

function TIMER:GetRecordListForNewUI(style, page)
    local tab = {}
    local pagesize = 10
    local a = pagesize * page - pagesize

    local styleData = self.Styles[style].Data
    local records = styleData:GetRecords(page, pagesize)

    for _, record in ipairs(records) do
        table.insert(tab, { record[2], TIMER:WRConvert2(record[3]) })
    end

    return tab
end

function TIMER:GetRecordCountForNewUI(style)
    return self.Styles[style].Data:GetRecordCount()
end

-- Date in NY
function TIMER:GetDate()
    local serverTime = os.time()
    local isDST = os.date("*t", serverTime).isdst

    local timeZoneOffset = isDST and -4 * 3600 or -5 * 3600
    local correctedTime = serverTime + timeZoneOffset

    return os.date("%Y-%m-%d %I:%M:%S %p", correctedTime)
end

local function SendAllRecords(ply)
    if not IsValid(ply) then return end

    local recordsTable = {}

    for style, data in pairs(TIMER.Styles) do
        local styleRecords = data.Data.Records or {}

        if not recordsTable[style] then
            recordsTable[style] = {}
        end

        for i, record in ipairs(styleRecords) do
            table.insert(recordsTable[style], TIMER:WRConvert2(record[3])) 

        end
    end

    NETWORK:StartNetworkMessage(ply, "SendAllRecords", recordsTable)
end

function TIMER:GetMostPlayedMap(ply, callback)
    local steamid = MySQL:Escape(ply:SteamID())

    local query = string.format([[
        SELECT map, completions
        FROM timer_mapplays
        WHERE uid = %s
        ORDER BY completions DESC
        LIMIT 1
    ]], steamid)

    MySQL:Start(query, function(data)
        if not data or not data[1] then return callback("N/A") end
        callback(data[1].map)
    end)
end

-- Profile Stats
util.AddNetworkString("RequestProfileData")
util.AddNetworkString("SendProfileData")
util.AddNetworkString("ScoreboardProfileRequest")

function FormatPlaytime(seconds)
    seconds = math.floor(tonumber(seconds) or 0)

    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)

    return string.format("%02dh %02dm %02ds", h, m, s)
end

-- Get a player's average sync from the database
function TIMER:GetAverageSync(ply, callback)
    local steamid = MySQL:Escape(ply:SteamID())

    local query = string.format([[
        SELECT AVG(syncVal) AS avgSync FROM (
            SELECT CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(data, ' ', 4), ' ', -1) AS DECIMAL(5,2)) AS syncVal
            FROM timer_times
            WHERE uid = %s
        ) AS sub
        WHERE syncVal > 0
    ]], steamid)

    MySQL:Start(query, function(result)
        local avgSync = result and result[1] and tonumber(result[1].avgSync) or 0
        callback(avgSync)
    end)
end

-- Get a player's most recent WR map (latest record)
function TIMER:GetLastWRMap(ply, callback)
    local steamid = MySQL:Escape(ply:SteamID())

    local query = string.format([[
        SELECT map, style, time, date
        FROM timer_times
        WHERE uid = %s
        ORDER BY date DESC
        LIMIT 1
    ]], steamid)

    MySQL:Start(query, function(result)
        local lastWR = "N/A"
        if result and result[1] then
            local wr = result[1]
            lastWR = string.format("%s",
                wr.map
            )
        end
        callback(lastWR)
    end)
end

-- how many Group 1 runs a player has (within 15s of WR)
function TIMER:GetGroup1Runs(ply, style, callback)
    local steamid = MySQL:Escape(ply:SteamID())

    local query = string.format([[
        SELECT COUNT(*) AS group1count
        FROM timer_times AS t1
        JOIN (
            SELECT map, MIN(time) AS wr
            FROM timer_times
            WHERE style = %d
            GROUP BY map
        ) AS wrs ON t1.map = wrs.map
        WHERE t1.uid = %s AND t1.style = %d AND (t1.time - wrs.wr) <= 15
    ]], style, steamid, style)

    MySQL:Start(query, function(data)
        local count = (data and data[1] and tonumber(data[1].group1count)) or 0
        callback(count)
    end)
end

function TIMER:GetLastPlayedMap(ply, callback)
    if not IsValid(ply) or not callback then return end

    local steamid = MySQL:Escape(ply:SteamID())

    local query = string.format([[
        SELECT map, style, date
        FROM timer_times
        WHERE uid = %s
        ORDER BY date DESC
        LIMIT 1
    ]], steamid)

    MySQL:Start(query, function(data)
        if data and data[1] then
            local row = data[1]
            callback(string.format("%s", row.map))
        else
            callback("Never")
        end
    end)
end

function TIMER:GetTiersPlayed(ply, callback)
    local steamid = MySQL:Escape(ply:SteamID())
    local query = string.format([[
        SELECT DISTINCT tier
        FROM timer_times
        WHERE uid = %s AND tier IS NOT NULL
        ORDER BY tier ASC
    ]], steamid)

    MySQL:Start(query, function(result)
        local tiers = {}

        if result then
            for _, row in ipairs(result) do
                table.insert(tiers, tonumber(row.tier))
            end
        end

        callback(tiers)
    end)
end

function TIMER:UserGetMapsCompletedCount(ply, style, callback)
    local steamID = MySQL:Escape(ply:SteamID())
    local query = string.format([[
        SELECT COUNT(DISTINCT map) AS count
        FROM timer_times
        WHERE uid = %s AND style = %d
    ]], steamID, style)

    MySQL:Start(query, function(data)
        local count = (data and data[1] and tonumber(data[1].count)) or 0
        callback(count)
    end)
end

-- Get Group Placement
function TIMER:GetGroupPlacement(ply, callback)
    local steamID = MySQL:Escape(ply:SteamID())
    local style = ply.style

    local query = string.format([[
        SELECT t1.map, t1.time, COALESCE(m.tier, 1) AS tier
        FROM timer_times AS t1
        LEFT JOIN timer_map AS m ON t1.map = m.map
        WHERE t1.uid = %s AND t1.style = %d
    ]], steamID, style)

    MySQL:Start(query, function(results)
        if not results or #results == 0 then
            callback("Unranked")
            return
        end

        local groupSum = 0
        local groupCount = 0

        for _, row in ipairs(results) do
            local map = row.map
            local time = tonumber(row.time)
            local wr = TIMER:GetMapWRTime(map, style)

            if wr and wr > 0 and time > 0 then
                local diff = time - wr
                local group = 6 -- default (slowpoke)

                if diff <= 15 then group = 1
                elseif diff <= 30 then group = 2
                elseif diff <= 60 then group = 3
                elseif diff <= 90 then group = 4
                elseif diff <= 120 then group = 5 end

                groupSum = groupSum + group
                groupCount = groupCount + 1
            end
        end

        if groupCount == 0 then
            callback("Unranked")
            return
        end

        local avgGroup = math.Round(groupSum / groupCount)
        local groupName = {
            [1] = "Elite",
            [2] = "Expert",
            [3] = "Skilled",
            [4] = "Intermediate",
            [5] = "Casual",
            [6] = "Slowpoke"
        }

        callback(groupName[avgGroup] or "Unknown")
    end)
end

function TIMER:SendProfileData(requester, target)
    if not IsValid(requester) or not IsValid(target) then return end

    self:GetMostPlayedMap(target, function(mostPlayed)
        self:GetMapsLeft(target, target.style, function(mapsLeft, mapsPlayed, totalMaps)
            self:GetAverageSync(target, function(avgSync)
                self:GetLastWRMap(target, function(lastWR)
                    self:GetGroup1Runs(target, target.style, function(group1count)
                        self:GetLastPlayedMap(target, function(lastPlayed)
                            self:GetTiersPlayed(target, function(tiersPlay)
                                self:UserGetMapsCompletedCount(target, target.style, function(mapCompletions)
                                    self:GetGroupPlacement(target, function(groupedPlacement)

                                        local profile = {
                                            name = target:Nick(),
                                            steamid = target:SteamID(),
                                            role = Admin:GetAccessString(Admin:GetAccess(target)) or "User",
                                            wrs = target.WRCount or 0,
                                            placement = target.Placement or 0,
                                            rank = TIMER.Ranks[target.Rank] and TIMER.Ranks[target.Rank][1] or "Unranked",
                                            points = target.RankSum or 0,
                                            mapsPlayed = mapsPlayed or 0,
                                            mapsLeft = mapsLeft or 0,
                                            mapCompletions = mapCompletions or 0,
                                            sync = math.Round(avgSync, 2) .. "%",
                                            longJump = target.BestLJ or 0,
                                            playtime = FormatPlaytime(target.TotalPlayTime or 0),
                                            mapmostplayed = mostPlayed or "N/A",
                                            lastWR = lastWR or 0,
                                            group1 = group1count or 0,
                                            lastplayed = lastPlayed or 0,
                                            tierPlayed = (#tiersPlay > 0) and table.concat(tiersPlay, ", ") or "None",
                                            groupPlacement = groupedPlacement or "Unranked"
                                        }

                                        net.Start("SendProfileData")
                                        net.WriteEntity(target)
                                        net.WriteTable(profile)
                                        net.Send(requester)

                                    end)
                                end)
                            end)
                        end)
                    end)
                end)
            end)
        end)
    end)
end

net.Receive("ScoreboardProfileRequest", function(len, ply)
    local target = net.ReadEntity()

    if not IsValid(ply) or not IsValid(target) or not target:IsPlayer() then return end
    TIMER:SendProfileData(ply, target)
end)

hook.Add("PlayerInitialSpawn", "SendRecordsToClient", function(ply)
    timer.Simple(2, function()
        SendAllRecords(ply)
    end)
end)

NETWORK:GetNetworkMessage("RequestAllRecords", function(ply)
    SendAllRecords(ply)
end)