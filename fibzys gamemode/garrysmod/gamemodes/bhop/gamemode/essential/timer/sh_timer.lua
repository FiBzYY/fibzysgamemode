--[[~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	⏱️ Bunny Hop Timer ⏱️
		by: fibzy (www.steamcommunity.com/id/fibzy_)

		file: essential/timer/sh_timer.lua
		desc: ⌛ Core timer for the Bunny Hop timer system.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~]]

TIMER = TIMER or {}

-- Ranks list can be changed Rankname | Color | Points
TIMER.Ranks = {
    [-1] = {"Unranked", Color(255, 255, 255), 0},
    { "Rookie", Color(255, 228, 196), 0 },
    { "Apprentice", Color(192, 192, 192), 0.077 },
    { "Brawler", Color(210, 105, 30), 0.151 },
    { "Trainee", Color(123, 104, 238), 0.222 },
    { "Scout", Color(34, 139, 34), 0.289 },
    { "Journeyman", Color(70, 130, 180), 0.415 },
    { "Adventurer", Color(255, 140, 0), 0.529 },
    { "Explorer", Color(154, 255, 154), 0.582 },
    { "Skilled", Color(255, 215, 0), 0.631 },
    { "Challenger", Color(0, 191, 255), 0.677 },
    { "Veteran", Color(255, 99, 71), 0.72 },
    { "Mastermind", Color(255, 255, 0), 0.76 },
    { "Tactician", Color(255, 160, 122), 0.797 },
    { "Strategist", Color(0, 250, 154), 0.831 },
    { "Virtuoso", Color(138, 43, 226), 0.862 },
    { "Architect", Color(173, 255, 47), 0.889 },
    { "Conqueror", Color(255, 20, 147), 0.914 },
    { "Overlord", Color(0, 0, 128), 0.935 },
    { "Baron", Color(205, 133, 63), 0.954 },
    { "Maverick", Color(255, 182, 193), 0.969 },
    { "Visionary", Color(255, 105, 180), 0.982 },
    { "Immortal", Color(255, 69, 0), 0.986 },
    { "Specter", Color(128, 0, 128), 0.91 },
    { "Celestial", Color(0, 255, 127), 0.95 },
    { "Omnipotent", Color(75, 0, 130), 0.99 },
}

-- Style list can be changed
TIMER.Styles = {
    {"Normal", "N", {"n", "normal", "auto", "autohop"}},
    {"Sideways", "SW", {"sw", "sideways", "sways"}},
    {"Half-Sideways", "HSW", {"hsw", "halfsideways", "half-sideways"}},
    {"W-Only", "W", {"wonly", "w", "wmode"}},
    {"A-Only", "A", {"aonly", "a", "amode"}},
    {"D-Only", "D", {"donly", "d", "dmode"}},
    {"SHSW", "SHSW", {"shsw", "surfhsw", "shalf-sideways"}},
    {"Legit", "L", {"scroll", "lscroll", "legit", "l"}},
    {"Easy Scroll", "E", {"escroll", "easyscroll", "easy", "e"}},
    {"Unreal", "Unreal", {"unreal", "ur"}},
    {"Swift", "Swift", {"swift", "fast", "fastmode"}},
    {"Bonus", "Bonus", {"bonus", "b"}},
    {"WTF", "WTF", {"wtf"}},
    {"Low Gravity", "LG", {"lg", "lowgrav", "lowgravity"}},
    {"High Gravity", "HG", {"hg", "highgrav", "highgravity"}},
    {"Moon Man", "MOON", {"moon", "moonman", "mm"}},
    {"Speedrun", "SR", {"speed", "speedrun", "faste"}},
    {"Backwards", "BW", {"bw", "backwards"}},
    {"Stamina", "Stamina", {"stamina", "stam"}},
    {"Segment", "Segment", {"segment"}},
    {"Practice", "Practice", {"practice"}},
    {"Auto-Strafe", "AutoStrafe", {"as", "autostrafer"}},
    {"TAS", "TAS", {"tas", "assistedtool"}},
	{"Prespeed", "pre", {"pre", "prespeed"}}
}

-- Info for up list styles
TIMER.StyleInfo = {
    "All movement keys are allowed.",
    "You can only use the A and D keys (sideways bhop).",
    "You can only strafe with A and D while holding W.",
    "You can only move forward using the W key.",
    "You can only strafe left with the A key.",
    "You can only strafe right with the D key.",
    "A variant of Half-Sideways but surf optimized.",
    "Auto bunnyhopping is off, and stamina is active.",
    "Auto bunnyhopping is off, stamina inactive, easier scroll.",
    "You have extreme air acceleration (50000 AA) with Boost click.",
    "Movement speed is boosted significantly.",
    "Bonus maps style (may vary depending on map).",
    "Everything is chaotic and unpredictable. With Boost click",
    "Your gravity is reduced to half.",
    "Gravity is increased by 60%.",
    "Low gravity but also reduced movement speed.",
    "Timer runs faster, ideal for speedrun maps.",
    "You can only move backwards.",
    "Limited stamina, slows you down when exhausted.",
    "Segmented style for checkpoint splits.",
    "Practice mode, timer disabled.",
    "Auto-strafe enabled, automatically strafes for you.",
    "Tool-Assisted Speedrun style, intended for TAS runs.",
    "You can prespeed in the zone with noclip.",
}

-- Fun ranks
TIMER.UniqueRanks = {
    {
        "Demon",
        "Speed Demon",
        "Confused Jumper",
        "Novice Strafe",
        "Speed God",
        "Certified Legit",
        "Almost Certified",
        "Space Walker",
        "Thunderbolt",
        "Heavyweight",
        "HSW Master",
        "Strafes on Fleek"
    },
    {
        "Strafe Lord",
        "W-Key Warrior",
        "Wannabe Pro",
        "Mega Whale",
        "Spin Wizard",
        "Scroll Master",
        "Pro Scroller",
        "Lunar Jumper",
        "Insane Speedster",
        "Leadfooted",
        "SW Expert"
    }
}

-- Zone colors
TIMER.ZoneColours = {
    ["Start Zone"] = Color(255, 255, 255),
    ["End Zone"] = Color(255, 0, 0),
    ["Bonus Start"] = Color(127, 140, 141),
    ["Bonus End"] = Color(52, 73, 118),
    ["Anti-Cheat"] = Color(153, 0, 153, 100),
    ["Normal Anti-cheat"] = Color(140, 140, 140, 100),
    ["Bonus Anti-cheat"] = Color(0, 0, 153, 100),
    ["Teleport Zone Start"] = Color(200, 200, 0),
    ["Teleprot Zone End"] = Color(255, 255, 0),
    ["Booster"] = Color(115, 231, 53)
}

-- Make rainbow style text
function TIMER:Rainbow(str)
    local text = {}
    local frequency = 20
    for i = 1, #str do
        table.insert(text, HSVToColor(i * frequency % 360, 1, 1))
        table.insert(text, string.sub(str, i, i))
    end
    return text
end

-- Make color rainbow style text
function TIMER:ColorToRainbow(g, g2)
	local gs = g or Vector(127, 127, 127)
	local ge = g2 or Vector(128, 128, 128)
	local frequency = g and g2 and 1 or 2

	local currentTime = CurTime()
	local sinR = math.sin(frequency * currentTime + 0)
	local sinG = math.sin(frequency * currentTime + (g and g2 and 0 or 2))
	local sinB = math.sin(frequency * currentTime + (g and g2 and 0 or 4))

	local red = sinR * gs.x + ge.x
	local green = sinG * gs.y + ge.y
	local blue = sinB * gs.z + ge.z

	return Color(red, green, blue)
end

-- Red to black faded text
function TIMER:RedToBlackFade(str)
    local text = {}
    local length = #str
    local minRedValue = 35

    for i = 1, length do
        local fadeAmount = (length - i) / length

        local redValue = math.floor(minRedValue + (255 - minRedValue) * fadeAmount)
        local color = Color(redValue, 0, 0)

        table.insert(text, color)
        table.insert(text, string.sub(str, i, i))
    end

    return text
end

-- Timer
TIMER.TickInterval = engine.TickInterval()
TIMER.TickCount = engine.TickCount()

function TIMER:GetMode(client)
	return (client.mode and client.mode or 1)
end

function TIMER:GetStyle(client)
    return client.style and client.style or 1
end

function TIMER:GetPersonalBest(client, style)
    style = style or self:GetStyle(client)

    if not client.personalbest or not client.personalbest[style] then 
        return false 
    else 
        return unpack(client.personalbest[style])
    end
end

function TIMER:TranslateMode(mode)
	if (mode == 1) then
		return ""
	elseif (mode == 2) then
		return "Bonus"
	else
		return "Bonus " .. (mode - 1)
	end
end

function TIMER:SetRecord(ply, recordTime, style)
    ply.personalbest = ply.personalbest or {}
    ply.personalbest[style] = {recordTime, style}
end

function TIMER:TranslateStyle(style, _id)
    if not self.Styles[style] then
        return "Unknown"
    end
    return self.Styles[style][_id or 1]
end

function TIMER:GetFullStateByStyleMode(style, mode)
	local nmode = self:TranslateMode(math.abs(mode))
	local style_name = self:TranslateStyle(math.abs(style))

	if (mode < 0) then 
		return nmode .. (nmode == "" and "" or " ") .. "Segmented " .. style_name
	else 
		return (nmode == "") and style_name or (nmode .. " " .. style_name)
	end
end

function TIMER:GetFullState(client)
	local style = self:GetStyle(client)
	local mode = self:TranslateMode(math.abs(self:GetMode(client)))
	local style_name = self:TranslateStyle(math.abs(style))

	if (self:GetMode(client) < 0) then 
		return mode .. (mode ~= "" and " " or "")  .. "Segmented " .. style_name
	else 
		return (mode == "") and style_name or (mode .. " " .. style_name)
	end
end

function TIMER:IsTAS(style)
	return (style < 0)
end

function TIMER:StyleName(nID)
    return self:TranslateStyle(nID)
end

function TIMER:IsValidStyle(nstyle)
    return self.Styles[nstyle] ~= nil
end

function TIMER:GetStyleID(command)
    command = command:lower()

    for id, styleData in ipairs(self.Styles) do
        for _, cmdName in ipairs(styleData[3]) do
            if cmdName:lower() == command then
                return id
            end
        end
    end

    return 0
end

-- Old GetTime
function TIMER:GetTime(client)
    if not client.time then
        return 0
    end

    if client.finished then
        return client.finished - client.time
    end

    local currentTicks = TIMER.TickCount
    local elapsedTicks = currentTicks - client.time

    return elapsedTicks * engine.TickInterval()
end

function TIMER:GetRank(client, _style)
    _style = _style or self:GetStyle(client)

    return (client.brank and client.brank[_style]) and client.brank[_style] or {false, -1}
end

function TIMER:TranslateRank(rank)
    return self.Ranks[rank] or "Unknown"
end

-- Sync Calculation
function TIMER:GetSync(client)
    if (not self.SyncMonitored[client]) then 
        return 0 
    end

    if SERVER then 
        local x = math.Round((((self.SyncB[client] / self.SyncTick[client]) * 100) + ((self.SyncA[client] / self.SyncTick[client]) * 100)) / 2, 2)
        if x ~= x then 
            return 0 
        else 
            return x 
        end
    else 
        return client.sync
    end
end

function TIMER:GetJumps(client)
    if PlayerJumps and PlayerJumps[client] then 
        return PlayerJumps[client]
    else 
        return 0 
    end 
end

function TIMER:SetJumps(ply, jumpCount)
    if not PlayerJumps[ply] then
        PlayerJumps[ply] = 0
    end
    PlayerJumps[ply] = jumpCount
end

TickInterval = engine.TickInterval()

function TIMER:SetStart(ply, timeType)
    ply.TimerFinished = false

    local tick = engine.TickCount()
    if timeType == 0 then
        self.TickStart = nil
        self.BonusTickStart = nil
    elseif timeType == 1 then
        self.TickStart = tick
    elseif timeType == 2 then
        self.BonusTickStart = tick
    end
end

function TIMER:SetFinish(ply)
    if not self.TickStart and not self.BonusTickStart then return end

    ply.TimerFinished = true
    local tick = engine.TickCount()

    if self.TickStart then
        self.TickEnd = tick
    elseif self.BonusTickStart then
        self.BonusTickEnd = tick
    end
end

function TIMER:Reset(ply)
    if not IsValid(ply) then return end

    self.TickStart = nil
    self.TickEnd = nil
    self.BonusTickStart = nil
    self.BonusTickEnd = nil
    ply.TimerFinished = false
end

-- Networked Timer Start | Finish | Reset
NETWORK:GetNetworkMessage("TIMER/Start", function(_, data)
    local timeType = data[2]
    local ply = data[1]
    TIMER:SetStart(ply, timeType)

    if ResetStrafes then ResetStrafes() end
end)

NETWORK:GetNetworkMessage("TIMER/Finish", function(_, data)
    local ply = data[1]
    local tickTimeDiff = data[2]

    ply.tickTimeDiffEnd = tickTimeDiff

    TIMER:SetFinish(ply)
end)

NETWORK:GetNetworkMessage("TIMER/Reset", function(_, data)
    local ply = data[1]
    TIMER:Reset(ply)

    if ResetStrafes then ResetStrafes() end
end)

function TIMER:SetRankScalar(nNormal, nAngled)
    for n, data in pairs(TIMER.Ranks) do
        if n >= 0 then
            data[3] = nNormal * n
            data[4] = nAngled * n
        end
    end
end

-- Main timer tick count for display
function TIMER:GetTickCount(ply)
    ply = ply or LocalPlayer()

    if not IsValid(ply) then
        return 0
    end

    local tickCount = engine.TickCount()
    local style = TIMER:GetStyle(ply)

    local timescale = 1 -- (style == TIMER:GetStyleID("TAS")) and GetConVar("bhop_timescale"):GetFloat() or 1

    if ply.TimerFinished then
        if self.BonusTickEnd then
            return (self.BonusTickEnd - self.BonusTickStart) * timescale
        elseif self.TickEnd then
            return (self.TickEnd - self.TickStart) * timescale
        else
            return 0
        end
    end

    local startTick = self.BonusTickStart or self.TickStart or 0
    if startTick == 0 then return 0 end

    local ticksElapsed = tickCount - startTick
    if ticksElapsed < 0 then ticksElapsed = 0 end

    if style == TIMER:GetStyleID("Segment") or style == TIMER:GetStyleID("TAS") then
        local totalSegmentTime = 0

        for _, segmentTime in ipairs(self.CompletedSegments or {}) do
            totalSegmentTime = totalSegmentTime + segmentTime
        end

        if not ply.TimerFinished then
            totalSegmentTime = totalSegmentTime + (ticksElapsed * timescale)
        end

        return totalSegmentTime
    else
        return ticksElapsed * timescale
    end
end

-- Reset the checkpoint
function TIMER:ResetToCheckpoint(ply, checkpointTick)
    self.TickStart = checkpointTick
    self.TickEnd = nil
    self.BonusTickStart = nil
    self.BonusTickEnd = nil
    self.CompletedSegments = nil
    ply.TimerFinished = false
    timerActive = true

    fractionalTicks = 0
end

-- Syncing for spectator
function TIMER:Sync(server)
    if type(server) ~= "number" then return end
    difference = CurTime() - server
end

function TIMER:GetDifference()
    return difference
end

function TIMER:SyncPlayer(serverTick)
    difference = engine.TickCount() - serverTick
end

-- Tick based
function TIMER:GetDifferencePlayer()
    return difference * engine.TickInterval()
end

TopVel = TopVel or 0
TotalVel = TotalVel or 0
CurrentVel = CurrentVel or 0

function TIMER:GetSpeedData()
    local AvgVel = (CurrentVel > 0) and (TotalVel / CurrentVel) or 0
    return {TopVel, AvgVel}
end

-- Track speeds
local function SpeedTracker(ply, mv)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    local Speed = mv:GetVelocity():Length2D() or 0

    if Speed > TopVel then
        TopVel = Speed
    end

    TotalVel = TotalVel + Speed
    CurrentVel = CurrentVel + 1
end
hook.Add("Move", "SpeedTracker", SpeedTracker)

-- Convert to ticks
local fo, fl = string.format, math.floor
local floor, format = math.floor, string.format

function TIMER:Convert(ticks)
    if not ticks or type(ticks) ~= "number" or ticks < 0 then
        return "00:00.000"
    end

    local ns = ticks * engine.TickInterval()
    local wholeSeconds = floor(ns)
    local milliseconds = floor((ns - wholeSeconds) * 1000)
    local hours = floor(wholeSeconds/3600)
    local minutes = floor((wholeSeconds % 3600) / 60)
    local seconds = wholeSeconds % 60

    if hours > 0 then
        return format("%d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
    else
        return format("%02d:%02d.%03d", minutes, seconds, milliseconds)
    end
end

-- Normal Convert Time
function TIMER:ConvertTime(ns)
    if ns > 3600 then
        return fo("%d:%.2d:%.2d.%.3d", fl(ns/3600), fl(ns/60 % 60), fl(ns % 60), fl(ns * 1000 % 1000))
    else
        return fo("%.2d:%.2d.%.3d", fl(ns/60 % 60), fl(ns % 60), fl(ns * 1000 % 1000))
    end
end

-- Networked
if CLIENT then
    local lp, format = LocalPlayer, string.format

    -- Style
    NETWORK:GetNetworkMessage("UpdateSingleVar", function(client, data)
        if not data then
            return
        end

        local pl = data[1]
        local key = data[2]
        local value = data[3]

        if key == "style" then
            if type(value) ~= "number" then
                value = 1
            end
            pl.style = tonumber(value) or 1
        else
            pl[key] = value
        end
    end)

    -- Time
    NETWORK:GetNetworkMessage("UpdateMultiVar", function(client, data)
        local pl = data[1]
        local keys = data[2]
        local values = data[3]
        local tick = game.TickCount()

        for k, v in pairs(keys) do
            if v == 'time' then 
                pl[v] = type(values[k]) == 'number' and tick - values[k] or values[k]
            else
                pl[v] = values[k]
            end
        end
    end)

    -- WR
    NETWORK:GetNetworkMessage("UpdateWR", function(client, data)
        TIMER.WorldRecords = data[1] or 0
    end)

    -- Sync
    NETWORK:GetNetworkMessage("Sync", function(client, data)
        local pl = data[1]
        local a = data[2]
        local b = data[3]
        local sync = data[4]

        pl.async = math.Round(a, 2)
        pl.bsync = math.Round(b, 2)
        pl.sync = math.Round(sync, 2)
    end)

    -- Global WR
    NETWORK:GetNetworkMessage("SendWRData", function(client, data)
        TIMER.map = data[2]
        TIMER.globalWR = data[3]
    end)

    -- Spectate Hud
	concommand.Add("spectate_dialog", function()
		UI.SpecDialog = UI:DialogBox(string.format("Do you wish to %s spectator mode?", LocalPlayer():Team() == TEAM_SPECTATOR and "leave" or "enter"), false, function()  
			LocalPlayer():ConCommand("spectate")
		end, function() 
		end)
	end)

    NETWORK:GetNetworkMessage("OpenSpectateDialog", function(client, data)
	    UI.SpecDialog = UI:DialogBox(string.format("Do you wish to %s spectator mode?", LocalPlayer():Team() == TEAM_SPECTATOR and "leave" or "enter"), false, function()  
			    LocalPlayer():ConCommand("spectate")
		    end, function() 
	    end)
    end)
end