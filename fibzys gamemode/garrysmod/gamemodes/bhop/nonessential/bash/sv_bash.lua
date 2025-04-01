-- Bash heavily edited by fibzy

local MAXPLAYERS = game.MaxPlayers()
local BHOP_TIME = 15
local MAX_MOVE = 10000
local VECTOR_1_1_0 = Vector(1, 1, 0)

local ID = "bash2_gmod"

util.AddNetworkString(ID)
util.AddNetworkString(ID .. "_cv")
util.AddNetworkString("Bash_DebugLog")

concommand.Add("bash_reload", function(ply)
	if ply ~= NULL then return end
	print("Reloading BASH2...")
end, nil, "", FCVAR_PROTECTED)

-- Definitions
local Button = {
	Forward = 0,
	Back = 1,
	Left = 2,
	Right = 3,
}

local BT_Move = 0
local BT_Key = 1

local Moving = {
	Forward = 0,
	Back = 1,
	Left = 2,
	Right = 3,
}

local Turn_Left =  0
local Turn_Right = 1

local Reasons = {
	Gains = 1,
	ManyPerfect = 2,
	StrafeHack = 3,
	ButtonsMove = 4,
	ConsecutiveMove = 5,
	KeySwitchPositive = 6,
	KeySwitch = 7,
	StartStrafe = 8,
	EndStrafe = 9,
	AngleSnap = 10,
	IllegalYaw = 11,
	KLook = 12,
	NullConfig = 13,
	ScriptedJumps = 14,
	ScrollMacro = 15,
	ScrollCheat = 16,
	TurnRate = 17,
	TurnBypass = 18,
	PreStrafe = 19,
}

local LogLevel = {
	TEST = -1,
	LOW = 0,
	MEDIUM = 1,
	HIGH = 2,
	HIGH_KICK = 3,
	HIGH_BAN = 4,
	PERMANENT = 5,
}

local Messages = {
	[Reasons.Gains] = "has %.2f%% gains (Yawing %.1f%%, Timing %.1f%%)",
	[Reasons.ManyPerfect] = "too many perfect %s strafes in a row (%d)",
	[Reasons.StrafeHack] = "is strafe hacking",
	[Reasons.ButtonsMove] = "invalid buttons and sidemove combination (%s) x%d",
	[Reasons.ConsecutiveMove] = "has invalid consecutive movement values, (Joystick = %d, YawChanges = %d/%d) - %s",
	[Reasons.KeySwitchPositive] = "key switch positive count every frame",
	[Reasons.KeySwitch] = "key switch %s, avg: %.2f, dev: %.2f, p: %.2f%%, nullPct: %.2f%%, Timing: %.1f%%",
	[Reasons.StartStrafe] = "start strafe, avg: %.2f, dev: %.2f, Timing: %.1f%%, style: %s",
	[Reasons.EndStrafe] = "end strafe, avg: %.2f, dev: %.2f, Timing: %.1f%%, style: %s",
	[Reasons.AngleSnap] = "angle snap hack, Pct: %.2f%%, Timing: %.1f%%, Style: %s",
	[Reasons.IllegalYaw] = "is turning with illegal yaw values (%f, %f, %d, %d)",
	[Reasons.KLook] = "is using `+klook` LJ binds (x%d)",
	[Reasons.NullConfig] = "Potentially movement config (%g%%)",
	[Reasons.ScriptedJumps] = "Scripted jumps (%s) %s",
	[Reasons.ScrollMacro] = "Scroll macro (highn) %s",
	[Reasons.ScrollCheat] = "Scroll cheat (interval) %s",
	[Reasons.TurnRate] = "Acute TR formatter (%g ~ %g | spd: %d) x%d",
	[Reasons.TurnBypass] = "+left/right bypasser (%g ~ %g) x%d",
	[Reasons.PreStrafe] = "Prestrafe/fastwalk (%g) x%d",
}

local g_cfg = include("sv_config.lua")

local g_target = {}
local g_fTickRate = 1.0 / engine.TickInterval()
local g_adminsFilter = RecipientFilter(true)
local g_iScrollSamples = math.random(g_cfg.scroll_samples_min, g_cfg.scroll_samples_max)

local math, string, bit, IsValid = _G.math, _G.string, _G.bit, _G.IsValid
local engine, util, Vector, Angle = _G.engine, _G.util, _G.Vector, _G.Angle
local GetTickInterval, SysTime = _G.engine.TickInterval, _G.SysTime
local utilTraceHull, istable = _G.util.TraceHull, _G.istable
local IN_MOVELEFT, IN_MOVERIGHT, IN_LEFT, IN_RIGHT = IN_MOVELEFT, IN_MOVERIGHT, IN_LEFT, IN_RIGHT
local IN_BACK, IN_FORWARD, IN_JUMP = IN_BACK, IN_FORWARD, IN_JUMP

local MAX_FRAMES_KEYSWITCH = g_cfg.max_frames_keyswitch
local MAX_FRAMES = g_cfg.max_frames
local BAN_LENGTH = g_cfg.ban_length

-- Logs
local function Log(fmt, ...)
    local ok, res = pcall(string.format, fmt, ...)
    if not ok then
        ErrorNoHalt("Bash | string.format error: ", res)
        print("Bash |", fmt, ...)
        return
    end

    net.Start("Bash_DebugLog")
    net.WriteString(res)
    net.Broadcast()

    MsgC(
        Color(50, 150, 255), "Bash ",
        Color(255, 255, 255), "| ",
        Color(200, 200, 200), os.date("(%X) ", os.time()),
        Color(255, 255, 255), res .. "\n"
    )
end

local LogToDiscord = include("sv_discord.lua")

local function PrintToAdmins(level, fmt, ...)
	local ok, res = pcall(string.format, fmt, ...)
	if not ok then return end
	net.Start(ID)
	net.WriteInt(level or LogLevel.LOW, 8)
	net.WriteString(res)
	net.Send(g_adminsFilter)
end

local function ReasonLog(reason, level, ply, ...)
	local fmt = "'%s' " .. Messages[reason]
	PrintToAdmins(level, fmt, ply:Nick(), ...)
	Log(fmt, ply:Nick(), ...)

	if level >= g_cfg.min_log_level then
		local disco_fmt = string.gsub(Messages[reason], "x?%%%d?%.?%d?%a%%?%%?", "`%0`")
		local ok, disco_msg = pcall(string.format, disco_fmt, ...)
		if ok then LogToDiscord(ply, level, disco_msg, nil) end
	end

	-- TODO: log to the DB or file?
end

local function PrintToChat(ply, text, level)
	if not IsValid(ply) then return end
	net.Start(ID)
	net.WriteInt(level or LogLevel.LOW, 8)
	net.WriteString(text)
	net.Send(ply)
end

-- Compat

-- TODO: add CAMI support with bypass feature
local function IsPlayerAdmin(ply)
	return ply:IsSuperAdmin() or ply:IsAdmin() or ply:IsUserGroup("moderator") or ply:IsUserGroup("bash2")
end

local function CanPlayerBypass(ply)
	return istable(ply.TAS) or ply.Practice
end

local function IsTimerRunning(ply)
	return not (ply.Practice or ply.InStartZone)
end

local function IsTimerPaused(ply)
	return false
end

local function GetStyleName(ply)
    if not ply.style or not TIMER.Styles then return "Unknown" end
    return TIMER:TranslateStyle(ply.style) or "Unknown"
end

local function IsScrollStyle(ply)
	return ply.style == TIMER:GetStyleID("E") or ply.style == TIMER:GetStyleID("L") 
end

local function StripMovement(ply, move, buttons)
    local st, bt = ply.style, 0

    if st == TIMER:GetStyleID("SW") or st == TIMER:GetStyleID("W") or st == TIMER:GetStyleID("S") then
        bt, move.y = IN_MOVELEFT + IN_MOVERIGHT, 0
        if (st == 4 and move.x < 0) or (st == 14 and move.x > 0) then
			bt, move.x = bt + IN_BACK + IN_FORWARD, 0
        end
    elseif st == TIMER:GetStyleID("A") then -- A
        bt, move.x = IN_BACK + IN_FORWARD, 0
        if move.y > 0 then
            bt, move.y = bt + IN_MOVELEFT + IN_MOVERIGHT, 0
        end
    elseif st == TIMER:GetStyleID("D") then -- D
        bt, move.x = IN_BACK + IN_FORWARD, 0
        if move.y < 0 then
            bt, move.y = bt + IN_MOVELEFT + IN_MOVERIGHT, 0
        end
    elseif st == TIMER:GetStyleID("HSW") and (move.x == 0 or move.y == 0 or (move.x < 0 and move.y ~= 0)) then
        move.x, move.y = 0, 0 -- HSW - WA/WD
		bt = IN_MOVELEFT + IN_MOVERIGHT + IN_BACK + IN_FORWARD
    elseif st == TIMER:GetStyleID("SHSW") and ((move.x >= 0 and move.y >= 0) or (move.x <= 0 and move.y <= 0)) then
        move.x, move.y = 0, 0 -- SHSW
		bt = IN_MOVELEFT + IN_MOVERIGHT + IN_BACK + IN_FORWARD
    end

    return bit.band(buttons, bit.bnot(bt))
end

local function KickPlayer(ply, real_reason)
	local reason = g_cfg.kick_reason or real_reason or "Cheating"
	-- Log("!KICK! %s - %s", ply:Nick(), real_reason or reason)
	LogToDiscord(ply, LogLevel.HIGH_KICK, "Kicked for: " .. (real_reason or reason), nil)
	ply.bash2_kick = true
	ply:Kick("Kicked: " .. reason)
end

-- Bans player (length in minutes)
local function BanPlayer(ply, length, real_reason)
	local reason = g_cfg.ban_reason or real_reason or "Cheating"
	local _length = length or g_cfg.ban_length or 0
	local level = _length == 0 and LogLevel.PERMANENT or LogLevel.HIGH_BAN
	Log("!BAN! %s (%d minutes) - %s", ply:Nick(), _length, reason or "")
	RunConsoleCommand("xadmin", "ban", ply:SteamID(), _length, real_reason or reason)
	LogToDiscord(ply, level, real_reason or reason, _length * 60)
end

-- Utils
local function ResetBashData(data)
	data.iKeyPressesThisStrafe = {}
	data.iReleaseTickAtLastEndStrafe = {}
	data.iLastButtons = {}
	data.iButtons = {}
	data.iIllegalTurn = {}
	data.iIllegalTurn_IsTiming = {}
	data.cvarCheckedCount = {}
	data.cvarChangedCount = {}
	data.cvar = {}

	data.sLastIllegalReason = "unknown"
	data.fLastCheckTime = SysTime()
	data.fLastAngles = Angle()
	data.fLastPosition = Vector()
	data.fLastMove = Vector()
	data.fAngleDifference = Angle()
	data.fLastAngleDifference = Angle()
	data.MOTDTestAngles = Angle()
	data.bMOTDTest = false
	data.bIsTurning = false
	data.bCheckedYet = false
	data.bTouchesFuncRotating = false
	data.mLastMoveType = MOVETYPE_NONE
	data.iLastTurnDir = Turn_Left
	data.flRawGain = 0.0
	data.lastTurnBind = 0
	data.lastTurnBindTick = 0
	data.iKLookUses = 0
	data.iLastKLook = 0
	data.nextTurnTick = 0
	data.bFirstSixJumps = false
	data.iStrafesDone = 0

	data.iInsertPressCount = 0

	data.strafeTick = 0
	data.iLastTurnTick_Recorded_StartStrafe = 0
	data.iLastTurnTick_Recorded_EndStrafe = 0
	data.iLastStopTurnTick = 0
	data.iCmdNum = 0
	data.iLastTeleportTick = 0
	data.iTimingTickCount = 0
	data.iJump = 0
	data.iYawTickCount = 0
	data.iTicksOnGround = 0
	data.iRunCmdsPerSecond = 0
	data.iBadSeconds = 0
	data.iLastTurnTick = 0
	data.iIllegalYawCount = 0
	data.iPlusLeftCount = 0
	data.iIllegalSidemoveCount = 0
	data.iLastIllegalSidemoveCount = 0
	data.iLastInvalidButtonCount = 0
	data.iYawChangeCount = 0
	data.InvalidButtonSidemoveCount = 0
	data.iIllegalTurn_CurrentFrame = 0
	data.iStartStrafe_CurrentFrame = 0
	data.iStartStrafe_PerfCount = 0
	data.iEndStrafe_PerfCount = 0
	data.iEndStrafe_CurrentFrame = 0
	data.iStartStrafe_LastRecordedTick = 0
	data.iEndStrafe_LastRecordedTick = 0

	local function initStrafeData()
		return {
			Button = 0,
			TurnDirection = 0,
			MoveDirection = 0,
			Difference = 0,
			Tick = 0,
			IsTiming = false,
		}
	end
	data.bStartStrafe_IsRecorded = {}
	data.bEndStrafe_IsRecorded = {}
	data.iStartStrafe_Stats = {}
	data.iEndStrafe_Stats = {}
	for idx = 0, MAX_FRAMES - 1 do
		data.bStartStrafe_IsRecorded[idx] = false
		data.bEndStrafe_IsRecorded[idx] = false
		data.iStartStrafe_Stats[idx] = initStrafeData()
		data.iEndStrafe_Stats[idx] = initStrafeData()
	end

	data.bKeySwitch_IsRecorded = {}
	data.iKeySwitch_Stats = {}
	data.iKeySwitch_CurrentFrame = { [BT_Key] = 0, [BT_Move] = 0 }
	data.iKeySwitch_LastRecordedTick = { [BT_Key] = 0, [BT_Move] = 0 }
	for idx = 0, MAX_FRAMES_KEYSWITCH - 1 do
		data.bKeySwitch_IsRecorded[idx] = {}
		data.iKeySwitch_Stats[idx] = {}
		data.iKeySwitch_Stats[idx].Button = {}
		data.iKeySwitch_Stats[idx].Difference = {}
		data.iKeySwitch_Stats[idx].IsTiming = {}
		for btype = 0, 1 do -- BT_Move, BT_Key
			data.bKeySwitch_IsRecorded[idx][btype] = false
			data.iKeySwitch_Stats[idx].Button[btype] = 0
			data.iKeySwitch_Stats[idx].Difference[btype] = 0
			data.iKeySwitch_Stats[idx].IsTiming[btype] = false
		end
	end

	data.iLastPressTick = {}
	data.iLastPressTick_Recorded = {}
	data.iLastPressTick_Recorded_KS = {}
	data.iLastReleaseTick = {}
	data.iLastReleaseTick_Recorded = {}
	data.iLastReleaseTick_Recorded_KS = {}
	for bt = 0, 3 do -- Button enum
		data.iLastPressTick[bt] = {}
		data.iLastPressTick_Recorded[bt] = {}
		data.iLastPressTick_Recorded_KS[bt] = {}
		data.iLastReleaseTick[bt] = {}
		data.iLastReleaseTick_Recorded[bt] = {}
		data.iLastReleaseTick_Recorded_KS[bt] = {}
	end

	data.fPreviousOptimizedAngle = 0
	data.iSteadyAngleStreakPre = 0
	data.iSteadyAngleStreak = 0
	data.iPerfAngleStreak = 0
	data.iScrollReleaseTick = engine.TickCount()
	data.iScrollGroundTicks = 0
	data.iScrollAirTicks = 0
	data.bScrollPreviousGround = true
	data.iScrollPreviousButtons = 0
	data.iScrollCurrentJump = 1
	data.scrollHistory = {}
	data.scrollStats = {
		Scrolls = 0,
		BeforeGround = 0,
		AfterGround = 0,
		AverageTicks = 0,
		PerfectJump = false,
	}

	return data
end

local function GetBashData(client)
	if not client.bash2_data then
		client.bash2_data = ResetBashData({})
	end
	return client.bash2_data
end

local function StandardDeviation(arr, size, mean, countZeroes)
    local sd = 0
    countZeroes = countZeroes == nil or countZeroes

    for i = 1, size do
        if countZeroes or arr[i] ~= 0 then
            sd = sd + math.pow((arr[i] or 0) - mean, 2)
        end
    end

    return math.sqrt(sd / size)
end

local function GetAverage(arr, size, countZeroes)
    local total = 0
    countZeroes = countZeroes == nil or countZeroes

    if size == 0 then return 0 end

    for i = 1, size do
        if countZeroes or (arr[i] or 0) ~= 0 then
            total = total + (arr[i] or 0)
        end
    end

    return total / size
end

local function IsInLeftRight(data)
	local isYawing, buttons = false, data.iRealButtons
	if bit.band(buttons, IN_LEFT) ~= 0  then isYawing = not isYawing end
	if bit.band(buttons, IN_RIGHT) ~= 0 then isYawing = not isYawing end
	return not (data.cvar.cl_yawspeed < 50.0 or isYawing == false)
end

local function GetGainPercent(data)
	if data.strafeTick == 0 then return 0.0 end

	local coeffsum = data.flRawGain
	coeffsum = coeffsum / data.strafeTick
	coeffsum = coeffsum * 100.0
	coeffsum = math.floor(coeffsum * 100.0 + 0.5) / 100.0

	return coeffsum
end

-- MOTD

-- TODO: call this function?
local function OnVGUIMenu(client)
	local data = GetBashData(client)
	if not data.bMOTDTest then return end
	data.MOTDTestAngles = client:EyeAngles()

	timer.Simple(0.1, function()
		if not IsValid(client) then return end
		local ang = client:EyeAngles()
		if math.abs(data.MOTDTestAngles[2] - ang[2]) > 50.0 then
			ReasonLog(Reasons.StrafeHack, LogLevel.HIGH_KICK, client)
		end
		data.bMOTDTest = false
	end)
end

local function PerformMOTDTest(client)
	local target = g_target[client]
	if not IsValid(target) then return end

	GetBashData(target).bMOTDTest = true

	target:SendLua([[Derma_Message("You are moving suspiciously!", "Suspicious movements", "#close")]])
	-- target:SendLua([[local x = gui.EnableScreenClicker x(true) timer.Simple(3, function() x(false) end)]])
end

-- ButtonDown checks
local KEY_INSERT = KEY_INSERT

local function LogPlayerButtonDowns(data)
	if data.iCmdNum % 100 == 0 and data.iInsertPressCount ~= 0 then
		PrintToAdmins(LogLevel.LOW, "%s pressed INSERT key %d times", data.ply:Nick(), data.iInsertPressCount)
		data.iInsertPressCount = 0
	end
end

local function PlayerButtonDown(ply, bt)
	if bt == KEY_INSERT and g_cfg.log_insert_press then
		local data = GetBashData(ply)
		data.iInsertPressCount = data.iInsertPressCount + 1
	end
end
hook.Add("PlayerButtonDown", ID, PlayerButtonDown)

local g_nextBindLogTime = SysTime()

net.Receive(ID, function(len, ply)
	if len < 4 then return end
	local id = net.ReadUInt(4)
	local time = SysTime()

	if id == 1 and len >= 12 and g_nextBindLogTime < time then
		local bind = net.ReadString()
		PrintToAdmins(LogLevel.LOW, "%s pressed invalid bind: %s", ply:Nick(), bind)
		g_nextBindLogTime = time + 0.1
	end
end)

-- Convar checks
local g_convarIds = {}

local function updateConvar(client, cv, value, fmt)
	local data = GetBashData(client)
	data.cvarCheckedCount[cv] = data.cvarCheckedCount[cv] + 1
	if value == data.cvar[cv] then return end
	data.cvarChangedCount[cv] = data.cvarChangedCount[cv] + 1
	data.cvar[cv] = value

	if data.cvarChangedCount[cv] > 1 then
		local val = tonumber(value)
		if not isnumber(val) then fmt, val = "%s", tostring(value) end
		PrintToAdmins(LogLevel.LOW, "%s changed '%s' ConVar to " .. fmt, client:Nick(), cv, val)
	end
end

local g_convarActions = {
	["cl_yawspeed"] = function(client, cv, value)
		local data = GetBashData(client)
		data.cvarCheckedCount[cv] = data.cvarCheckedCount[cv] + 1
		if data.cvar[cv] ~= value then
			data.cvarChangedCount[cv] = data.cvarChangedCount[cv] + 1
			data.cvar[cv] = value
		end
		if value < 0 then
			-- KickPlayer(client, "`cl_yawspeed` cannot be negative")
		end
	end,
	["m_yaw"] = function(client, cv, value)
		updateConvar(client, cv, value, "%.4f")
	end,
	["m_filter"] = function(client, cv, value)
		updateConvar(client, cv, not (0.0 <= value and value < 1.0), "%d")
	end,
	["m_customaccel"] = function(client, cv, value)
		updateConvar(client, cv, value, "%d")
	end,
	["sensitivity"] = function(client, cv, value)
		updateConvar(client, cv, value, "%2.2f")
	end,
	["joystick"] = function(client, cv, value)
		updateConvar(client, cv, not (0 <= value and value < 1), "%d")
	end,
}

do
	local idx = 1
	for i, cvar in RandomPairs(g_cfg.convars) do
		g_convarIds[idx] = cvar
		idx = idx + 1
	end
end

local function QueryForCvars(client, data)
	data.cvarCheckedCount, data.cvarChangedCount = {}, {}
	net.Start(ID .. "_cv")
	net.WriteUInt(#g_convarIds, 8)
	for idx, cv in ipairs(g_convarIds) do
		data.cvarCheckedCount[cv], data.cvarChangedCount[cv] = 0, 0
		net.WriteString(cv)
	end
	net.Send(client)
end

net.Receive(ID .. "_cv", function(len, ply)
	if len < 40 then return end
	local idx = net.ReadUInt(8)
	local val = net.ReadFloat()
	local cv = g_convarIds[idx]

	if not cv then return end
	if g_convarActions[cv] then
		g_convarActions[cv](ply, cv, val)
	else
		updateConvar(ply, cv, val, "%g")
	end
end)

local function InitConvars(client)
	if not IsValid(client) or client:IsBot() then return end
	local data = GetBashData(client)

	data.cvar = {
		["cl_yawspeed"] = 210.0,
		["in_usekeyboardsampletime"] = 1,
		["m_yaw"] = 0.0,
		["m_filter"] = false,
		["m_rawinput"] = true,
		["m_customaccel"] = 0,
		["m_customaccel_max"] = 0.0,
		["m_customaccel_scale"] = 0.0,
		["m_customaccel_exponent"] = 1,
		["sensitivity"] = 0.0,
		["zoom_sensitivity_ratio"] = 0.0,
		["joystick"] = false,
		["joy_yawsensitivity"] = 0.0,
	}

	QueryForCvars(client, data)
end

local function GetConvarValue(client, cv)
	return GetBashData(client).cvar[cv]
end

local BashStats = {}

function BashStats.EndStrafes(client)
    local target = g_target[client]
    if not IsValid(target) then
        return PrintToChat(client, "Selected player no longer ingame.")
    end

    local data = GetBashData(target)
    local array, size = {}, 0
    local buttons = { [0] = 0, [1] = 0, [2] = 0, [3] = 0 }

    for idx = 0, MAX_FRAMES - 1 do
        if data.bEndStrafe_IsRecorded[idx] == true then
            table.insert(array, data.iEndStrafe_Stats[idx].Difference)
            local j = data.iEndStrafe_Stats[idx].Button
            buttons[j] = buttons[j] + 1
            size = size + 1
        end
    end

    if size == 0 then 
        PrintToChat(client, string.format("Player '%s' has no end strafe stats.", target:Nick())) 
        return 
    end

    local mean, sd = 0, 0
    if size > 0 then
        mean = GetAverage(array, size)
        sd = StandardDeviation(array, size, mean)
    end

    local menu = SourceModMenu(BashStats.BackMenuHandler)
    menu:SetTitle(string.format("[BASH] End Strafe stats: %s\nAverage: %.2f | Deviation: %.2f\nA: %d, D: %d, W: %d, S: %d",
        target:Nick(), mean, sd, buttons[2], buttons[3], buttons[0], buttons[1]))

    local menuCols = g_cfg.menu_cols or 10
    local sDisplay = ""
    for idx = 1, size do
        sDisplay = sDisplay .. string.format("%2d ", array[idx])
        if (idx % menuCols == 0) or (idx == size) then
            menu:AddItem("", sDisplay, false)
            sDisplay = ""
        end
    end

    menu:SetExitButton(true)
    menu:Display(client, 0)
end

function BashStats.KeySwitchesMenu(menu, ply, action, key)
	if action == "select" then
		if key == "move" then
			BashStats.KeySwitches_Move(ply)
		elseif key == "key" then
			BashStats.KeySwitches_Keys(ply)
		end
	end
	if action == "cancel" then
		ShowBashStats(ply, g_target[ply])
	end
	if action == "end" then menu:Close() end
end

function BashStats.KeySwitchesMenu_Move(menu, ply, action, key)
	if action == "cancel" then
		BashStats.KeySwitches(ply)
	end
	if action == "end" then menu:Close() end
end

function BashStats.KeySwitches_Move(client)
    local target = g_target[client]
    if not IsValid(target) then
        return PrintToChat(client, "Selected player no longer ingame.")
    end

    local data = GetBashData(target)
    local array, size, nullCount = {}, 0, 0

    for idx = 0, MAX_FRAMES_KEYSWITCH - 1 do
        if data.bKeySwitch_IsRecorded[idx][BT_Move] == true then
            table.insert(array, data.iKeySwitch_Stats[idx].Difference[BT_Move])
            size = size + 1
            if data.iKeySwitch_Stats[idx].Difference[BT_Key] == 0 then
                nullCount = nullCount + 1
            end
        end
    end

    local mean, sd, pctNulls = 0, 0, 0
    if size > 0 then
        mean = GetAverage(array, size)
        sd = StandardDeviation(array, size, mean)
        pctNulls = (nullCount / size) * 100
    end

    local menu = SourceModMenu(BashStats.KeySwitchesMenu_Move)
    menu:SetTitle(string.format("[BASH] Sidemove Switch stats: %s\nAverage: %.2f | Deviation: %.2f\nNulls: %g%%",
        target:Nick(), mean, sd, pctNulls))

    local menuCols = g_cfg.menu_cols or 10
    local sDisplay = ""
    for idx = 1, size do
        sDisplay = sDisplay .. string.format("%2d ", array[idx])
        if (idx % menuCols == 0) or (idx == size) then
            menu:AddItem("", sDisplay, false) 
            sDisplay = ""
        end
    end

    menu:SetExitButton(true)
    menu:Display(client, 0)
end

function BashStats.KeySwitches_Keys(client)
	local target = g_target[client]
	if not IsValid(target) then
		return PrintToChat(client, "Selected player no longer ingame.")
	end

	local data = GetBashData(target)
	local array, size, positiveCount, nullCount = {}, 0, 0, 0
	for idx = 0, MAX_FRAMES_KEYSWITCH - 1 do
		if data.bKeySwitch_IsRecorded[idx][BT_Key] == true then
			array[idx] = data.iKeySwitch_Stats[idx].Difference[BT_Key]
			size = size + 1
			if data.iKeySwitch_Stats[idx].Difference[BT_Key] >= 0 then
				positiveCount = positiveCount + 1
			end
			if data.iKeySwitch_Stats[idx].Difference[BT_Key] == 0 then
				nullCount = nullCount + 1
			end
		end
	end
	local mean = GetAverage(array, size)
	local sd   = StandardDeviation(array, size, mean)
	local pctPositive = positiveCount / size * 100
	local pctNulls = nullCount / size * 100

	local menu = SourceModMenu(BashStats.KeySwitchesMenu_Move)
	menu:SetTitle(string.format("[BASH] Key Switch stats: %s\nAverage: %.2f | Deviation: %.2f\nPositive: %.2f%% | Nulls: %g%%",
		target:Nick(), mean, sd, pctPositive, pctNulls))
	local sDisplay = ""
	for idx = 0, size - 1 do
		sDisplay = string.format("%s%2d ", sDisplay, array[idx])
		if (idx + 1) % g_cfg.menu_cols == 0 or (size - idx == 1) then
			menu:AddItem("mono", sDisplay, true)
			sDisplay = ""
		end
	end
	menu:AddItem("cancel")
	menu:Display(client, 0)
end

function BashStats.KeySwitches(client)
	local menu = SourceModMenu(BashStats.KeySwitchesMenu)
	menu:SetTitle("[BASH] Select key switch type")
	menu:AddItem("move", "Movement")
	menu:AddItem("key",  "Buttons")
	menu:AddItem("cancel")
	menu:Display(client, 0)
end

local function Bash_Stats_Command(client, cmd, args)
	if not IsValid(client) then return end

	if #args == 0 then
		local target = client:GetObserverMode() == OBS_MODE_NONE and client or client:GetObserverTarget()
		if IsValid(target) then ShowBashStats(client, target) end
		return
	end

	local sArg = args[1]

	if sArg[1] == "#" then
		sArg = string.Replace(sArg, "#", "")
		local target = Player(tonumber(sArg, 10) or -1)
		if IsValid(target) then
			ShowBashStats(client, target)
			return
		else
			PrintToChat(client, string.format("No player with userid '%s'.", sArg))
		end
	end

	for i, target in ipairs(player.GetHumans()) do
		if string.find(target:Nick(), sArg) then
			ShowBashStats(client, target)
			return
		end
	end

	PrintToChat(client, string.format("No player found with '%s' in their name.", sArg))
end
concommand.Add("bash_stats", Bash_Stats_Command)

local function Bash_Toggle_Admin_Mode(client, cmd, args)
	if not IsValid(client) then return end

	local enabled = client:GetPData(ID .. "_admin", "0") == "1"
	PrintToChat(client, string.format("Admin mod is %s", enabled and "disabled" or "enabled"))
	if enabled then
		g_adminsFilter:RemovePlayer(client)
		client:RemovePData(ID .. "_admin")
	else
		g_adminsFilter:AddPlayer(client)
		client:SetPData(ID .. "_admin", "1")
	end
end
concommand.Add("bash_admin", Bash_Toggle_Admin_Mode)

-- CUserCmd
local function GetDirection(client)
    local vel = client:GetAbsVelocity()
    local yaw = client:EyeAngles().yaw

    local diff = math.deg(math.atan2(vel.y, vel.x))

    if vel.x < 0.0 then
        if vel.y > 0.0 then
            diff = diff + 180.0
        else
            diff = diff - 180.0
        end
    end

    if diff < 0.0 then diff = diff + 360.0 end
    if yaw < 0.0 then yaw = yaw + 360.0 end
    diff = diff - yaw

    local flipped = false
    if diff < 0.0 then
        flipped = true
        diff = -diff
    end

    if diff > 180.0 then
        flipped = not flipped
        diff = math.abs(diff - 360.0)
    end

    if diff > -0.1 and diff < 67.5 then
        return Moving.Forward
    elseif diff > 67.5 and diff < 112.5 then
        return flipped and Moving.Right or Moving.Left
    elseif diff > 112.5 and diff <= 180.0 then
        return Moving.Back
    end

    return 0
end

local Button_Opposites = {
	[Button.Forward] = Button.Back,
	[Button.Back] = Button.Forward,
	[Button.Left] = Button.Right,
	[Button.Right] = Button.Left,
}
local function GetOppositeButton(button)
	return Button_Opposites[button] or -1
end

local function GetDesiredButton(client, dir)
	local moveDir = GetDirection(client)

	if dir == Turn_Left then
		if moveDir == Moving.Forward then
			return Button.Left
		elseif moveDir == Moving.Back then
			return Button.Right
		elseif moveDir == Moving.Left then
			return Button.Back
		elseif moveDir == Moving.Right then
			return Button.Forward
		end
	elseif dir == Turn_Right then
		if moveDir == Moving.Forward then
			return Button.Right
		elseif moveDir == Moving.Back then
			return Button.Left
		elseif moveDir == Moving.Left then
			return Button.Forward
		elseif moveDir == Moving.Right then
			return Button.Back
		end
	end

	return 0
end

local function GetDesiredTurnDir(client, button, opposite)
	local direction = GetDirection(client)
	local desiredTurnDir = -1

	-- if holding a and going forward then look for left turn
	if button == Button.Left and direction == Moving.Forward then
		desiredTurnDir = Turn_Left

		-- if holding d and going forward then look for right turn
	elseif button == Button.Right and direction == Moving.Forward then
		desiredTurnDir = Turn_Right

		-- if holding a and going backward then look for right turn
	elseif button == Button.Left and direction == Moving.Back then
		desiredTurnDir = Turn_Right

		-- if holding d and going backward then look for left turn
	elseif button == Button.Right and direction == Moving.Back then
		desiredTurnDir = Turn_Left

		-- if holding w and going left then look for right turn
	elseif button == Button.Forward and direction == Moving.Left then
		desiredTurnDir = Turn_Right

		-- if holding s and going left then look for left turn
	elseif button == Button.Back and direction == Moving.Left then
		desiredTurnDir = Turn_Left

		-- if holding w and going right then look for left turn
	elseif button == Button.Forward and direction == Moving.Right then
		desiredTurnDir = Turn_Left

		-- if holding s and going right then look for right turn
	elseif button == Button.Back and direction == Moving.Right then
		desiredTurnDir = Turn_Right
	end

	if opposite == true then
		if desiredTurnDir == Turn_Right then
			return Turn_Left
		else
			return Turn_Right
		end
	end

	return desiredTurnDir
end

local function IsSurfing(ply)
	return false -- TODO
end

local function WithinThreshold(f1, f2, threshold)
	return math.abs(f1 - f2) <= threshold
end

local function IsLegalMoveType(client, water)
	return client:GetMoveType() == MOVETYPE_WALK and not client:IsFlagSet(FL_ATCONTROLS)
		and (water == false or client:WaterLevel() < 2)
end

local function ResetPlayerMove(move, cmd)
	move.x, move.y, move.z = 0, 0, 0
	cmd:SetForwardMove(0)
	cmd:SetSideMove(0)
	cmd:SetUpMove(0)
end

local function OnTeleported(ply)
    if IsValid(ply) and not ply:IsBot() and ply:Alive() then
        local data = GetBashData(ply)
        data.iLastTeleportTick = data.iCmdNum
    end
end

local function Bash_tele()
    for _, ent in ipairs(ents.FindByClass("trigger_teleport")) do
        ent:Fire("AddOutput", "OnStartTouch !activator:teleported:0:0:-1")
        ent:Fire("AddOutput", "OnEndTouch !activator:teleported:0:0:-1")
    end
end
hook.Add("InitPostEntity", "Bash_tele", Bash_tele)

hook.Add("AcceptInput", "OnTeleported", function(ent, input, activator)
    if input == "teleported" and IsValid(activator) and activator:IsPlayer() then
        OnTeleported(activator)
    end
end)

local function OnPlayerJump(client, data)
    data.iJump = data.iJump + 1

    if data.iJump == 6 then
        local gainPct = GetGainPercent(data)
        local yawPct = (data.iYawTickCount / data.strafeTick) * 100.0
        local timingPct = (data.iTimingTickCount / data.strafeTick) * 100.0
        local spj = data.iStrafesDone / (data.bFirstSixJumps and 5.0 or 6.0)

        if data.strafeTick > 300 and gainPct > 85.0 and yawPct < 60.0 then
            ReasonLog(Reasons.Gains, LogLevel.MEDIUM, client, gainPct, yawPct, timingPct, spj)

            if gainPct == 100.0 and timingPct == 100.0 then
                BanPlayer(client, BAN_LENGTH, string.format("%g%% gains", gainPct))
            end
        end

        data.iJump = 0
        data.flRawGain = 0.0
        data.strafeTick = 0
        data.iYawTickCount = 0
        data.iTimingTickCount = 0
        data.iStrafesDone = 0
        data.bFirstSixJumps = false
    end
end

local function OnPlayerHitGround(client, inWater, onFloater)
	local ent = client:GetGroundEntity()
	GetBashData(client).bTouchesFuncRotating = (not inWater and not onFloater and ent:GetClass() == "func_rotating")
end
hook.Add("OnPlayerHitGround", ID, OnPlayerHitGround)

local function UpdateButtons(data, vel, buttons)
	data.iLastButtons[BT_Move] = data.iButtons[BT_Move]
	data.iButtons[BT_Move] = 0
	if vel.x > 0 then
		data.iButtons[BT_Move] = bit.bor(data.iButtons[BT_Move], bit.lshift(1, Button.Forward))
	elseif vel.x < 0 then
		data.iButtons[BT_Move] = bit.bor(data.iButtons[BT_Move], bit.lshift(1, Button.Back))
	end
	if vel.y > 0 then
		data.iButtons[BT_Move] = bit.bor(data.iButtons[BT_Move], bit.lshift(1, Button.Right))
	elseif vel.y < 0 then
		data.iButtons[BT_Move] = bit.bor(data.iButtons[BT_Move], bit.lshift(1, Button.Left))
	end

	data.iLastButtons[BT_Key] = data.iButtons[BT_Key]
	data.iButtons[BT_Key] = 0
	if bit.band(buttons, IN_MOVELEFT) ~= 0 then
		data.iButtons[BT_Key] = bit.bor(data.iButtons[BT_Key], bit.lshift(1, Button.Left))
	end
	if bit.band(buttons, IN_MOVERIGHT) ~= 0 then
		data.iButtons[BT_Key] = bit.bor(data.iButtons[BT_Key], bit.lshift(1, Button.Right))
	end
	if bit.band(buttons, IN_FORWARD) ~= 0 then
		data.iButtons[BT_Key] = bit.bor(data.iButtons[BT_Key], bit.lshift(1, Button.Forward))
	end
	if bit.band(buttons, IN_BACK) ~= 0 then
		data.iButtons[BT_Key] = bit.bor(data.iButtons[BT_Key], bit.lshift(1, Button.Back))
	end
end

local function UpdateAngles(data, ang)
	data.fAngleDifference = Angle()
	for i = 1, 2 do
		local diff = ang[i] - data.fLastAngles[i]
		if diff > 180 then
			diff = diff - 360
		elseif diff < -180 then
			diff = diff + 360
		end
		data.fAngleDifference[i] = diff
	end
end

local StyleInfo = {
    mv = 32.4,
    cap = 100,
    maxspeed = 250
}

local function UpdateGains(data, vel, angles, buttons)
    local ply = data.ply

    if not IsValid(ply) or not ply:Alive() then return end
    if ply:GetMoveType() ~= MOVETYPE_WALK or (ply:IsFlagSet(FL_ONGROUND) and not bit.band(buttons, IN_JUMP)) then return end

    data.strafeTick = (data.strafeTick or 0) + 1

    -- Reset when standing on ground long enough
    if ply:OnGround() then
        if data.iTicksOnGround > BHOP_TIME then
            data.iJump = 0
            data.strafeTick = 0
            data.flRawGain = 0.0
            data.iYawTickCount = 0
            data.iTimingTickCount = 0
        end

        data.iTicksOnGround = (data.iTicksOnGround or 0) + 1
    else
        if data.iTicksOnGround ~= 0 then
            OnPlayerJump(ply, data)
        end

        if ply:GetMoveType() == MOVETYPE_WALK and ply:WaterLevel() < 2 and not ply:IsFlagSet(FL_ATCONTROLS) then
            local isYawing = false
            if bit.band(buttons, IN_LEFT) ~= 0 then isYawing = not isYawing end
            if bit.band(buttons, IN_RIGHT) ~= 0 then isYawing = not isYawing end
            if not (data.cvar and data.cvar.cl_yawspeed < 50 or not isYawing) then
                data.iYawTickCount = (data.iYawTickCount or 0) + 1
            end

            if IsTimerRunning(ply) then
                data.iTimingTickCount = (data.iTimingTickCount or 0) + 1
            end

            local velocity = ply:GetAbsVelocity() or Vector(0, 0, 0)
            velocity[3] = 0

            local input = { forward = 0, side = 0 }
            if bit.band(buttons, IN_FORWARD) ~= 0 then input.forward = 3 end
            if bit.band(buttons, IN_BACK) ~= 0 then input.forward = -3 end
            if bit.band(buttons, IN_MOVERIGHT) ~= 0 then input.side = 3 end
            if bit.band(buttons, IN_MOVELEFT) ~= 0 then input.side = -3 end

            local yawAngle = math.rad(angles[2])
            local lookVector = Vector(math.cos(yawAngle), math.sin(yawAngle), 0)
            local sideVector = Vector(math.cos(yawAngle - math.pi / 2), math.sin(yawAngle - math.pi / 2), 0)

            local accel = (lookVector * (input.forward * 0.3)) + (sideVector * (input.side * 2))
            if accel:IsZero() then return end
            accel:Normalize()

            local wishvel = accel * StyleInfo.maxspeed
            wishvel[3] = 0
            local wishspeed = wishvel:Length()

            if wishspeed > StyleInfo.maxspeed then
                wishvel:Mul(StyleInfo.maxspeed / wishspeed)
            end

            local currentGain = velocity:Dot(wishvel:GetNormalized())
            if wishspeed > 0 then
                if currentGain < StyleInfo.mv then
                    local gaincoeff = (StyleInfo.mv - math.abs(currentGain)) / StyleInfo.mv
                    gaincoeff = math.floor(gaincoeff * 100 + 0.5) / 100
                    data.flRawGain = (data.flRawGain or 0) + gaincoeff
                end
            end
        end

        data.iTicksOnGround = 0
    end
end

local function RecordKeySwitch(data, button, oppositeButton, btype, caller)
    local client = data.ply
    local fr = data.iKeySwitch_CurrentFrame[btype]

    data.iKeySwitch_Stats[fr] = data.iKeySwitch_Stats[fr] or {}
    data.iKeySwitch_Stats[fr].Button = data.iKeySwitch_Stats[fr].Button or {}
    data.iKeySwitch_Stats[fr].Difference = data.iKeySwitch_Stats[fr].Difference or {}
    data.iKeySwitch_Stats[fr].IsTiming = data.iKeySwitch_Stats[fr].IsTiming or {}

    data.iKeySwitch_Stats[fr].Button[btype] = button
    data.iKeySwitch_Stats[fr].Difference[btype] = data.iLastPressTick[button][btype] - data.iLastReleaseTick[oppositeButton][btype]
    data.iKeySwitch_Stats[fr].IsTiming[btype] = IsTimerRunning(client)
    data.bKeySwitch_IsRecorded[btype][fr] = true
    data.iKeySwitch_LastRecordedTick[btype] = data.iCmdNum

    data.iLastPressTick_Recorded_KS[button][btype] = data.iLastPressTick[button][btype]
    data.iLastReleaseTick_Recorded_KS[oppositeButton][btype] = data.iLastReleaseTick[oppositeButton][btype]
    data.iKeySwitch_CurrentFrame[btype] = (fr + 1) % MAX_FRAMES_KEYSWITCH

    if data.iKeySwitch_CurrentFrame[btype] == 0 then
        local array, size, positiveCount, timingCount, nullCount = {}, 0, 0, 0, 0

        for idx = 0, MAX_FRAMES_KEYSWITCH - 1 do
            if data.bKeySwitch_IsRecorded[btype][idx] then
                table.insert(array, data.iKeySwitch_Stats[idx].Difference[btype])
                size = size + 1

                if btype == BT_Key and data.iKeySwitch_Stats[idx].Difference[BT_Key] >= 0 then
                    positiveCount = positiveCount + 1
                end

                if data.iKeySwitch_Stats[idx].Difference[btype] == 0 then
                    nullCount = nullCount + 1
                end

                if data.iKeySwitch_Stats[idx].IsTiming[btype] then
                    timingCount = timingCount + 1
                end
            end
        end

        local mean = GetAverage(array, size)
        local sd = StandardDeviation(array, size, mean)
        local nullPct = (nullCount / MAX_FRAMES_KEYSWITCH)
        local positivePct = (positiveCount / MAX_FRAMES_KEYSWITCH)
        local timingPct = (timingCount / MAX_FRAMES_KEYSWITCH)

        if sd <= 0.25 or nullPct >= 0.95 then
            if btype == BT_Key and positiveCount == MAX_FRAMES_KEYSWITCH then
                ReasonLog(Reasons.KeySwitchPositive, LogLevel.LOW, client)
            end

            local level = nullPct >= 0.95 and LogLevel.HIGH_KICK or LogLevel.MEDIUM
            ReasonLog(Reasons.KeySwitch, level, client, btype == BT_Key and "Key" or "Move",
                mean, sd, positivePct * 100, nullPct * 100, timingPct * 100)

            if nullPct >= 0.95 and g_cfg.kick_for_nulls then
                timer.Simple(10, function()
                    if not IsValid(client) or client.bash2_kick then return end
                    KickPlayer(client, string.format("Potential movement config abuse (%.2f%% nulls)", nullPct * 100))
                end)
            end
        end
    end
end

local function RecordStartStrafe(data, button, turnDir, caller)
	local client = data.ply
	local moveDir = GetDirection(client)
	local fr = data.iStartStrafe_CurrentFrame

	data.iStartStrafe_CurrentFrame = (data.iStartStrafe_CurrentFrame + 1) % MAX_FRAMES
	data.iLastPressTick_Recorded[button][BT_Move] = data.iLastPressTick[button][BT_Move]
	data.iLastTurnTick_Recorded_StartStrafe	= data.iLastTurnTick
	data.iStartStrafe_LastRecordedTick		= data.iCmdNum
	data.bStartStrafe_IsRecorded[fr]		= true
	data.iStartStrafe_Stats[fr] = {
		Difference		= data.iLastPressTick[button][BT_Move] - data.iLastTurnTick,
		IsTiming		= IsTimerRunning(client),
		Tick			= data.iCmdNum,
		TurnDirection	= turnDir,
		MoveDirection	= moveDir,
		Button			= button,
	}

	if data.iStartStrafe_Stats[fr].Difference == 0 and not IsInLeftRight(data) then
		data.iStartStrafe_PerfCount = data.iStartStrafe_PerfCount + 1
	else
		data.iStartStrafe_PerfCount = 0
	end
	if data.iStartStrafe_PerfCount >= g_cfg.min_perfect_strafes then
		ReasonLog(Reasons.ManyPerfect, LogLevel.HIGH, client, "start", data.iStartStrafe_PerfCount)
	end

	if data.iStartStrafe_CurrentFrame == 0 then
		local array, size, timingCount = {}, 0, 0

		for idx = 0, MAX_FRAMES - 1 do
			if data.bStartStrafe_IsRecorded[idx] == true then
				array[idx] = data.iStartStrafe_Stats[idx].Difference
				size = size + 1
				if data.iStartStrafe_Stats[idx].IsTiming == true then
					timingCount = timingCount + 1
				end
			end
		end

		local mean = GetAverage(array, size)
		local sd   = StandardDeviation(array, size, mean)
		-- print("Start starfe", client, mean, sd, size, caller)

		if sd < g_cfg.max_log_sd then
			local sStyle = GetStyleName(client)
			local timingPct = timingCount / MAX_FRAMES * 100
			local level = LogLevel.MEDIUM
			if sd <= g_cfg.max_ban_sd and timingPct >= g_cfg.min_ban_timing then
				level = LogLevel.HIGH_BAN
			end
			ReasonLog(Reasons.StartStrafe, level, client, mean, sd, timingPct, sStyle)
			if level == LogLevel.HIGH_BAN then
				BanPlayer(client, BAN_LENGTH, "Start strafe dev " .. sd)
			end
		end
	end
end

local function RecordEndStrafe(data, button, turnDir, caller)
	local client = data.ply
	local moveDir = GetDirection(client)
	local fr = data.iEndStrafe_CurrentFrame

	data.iEndStrafe_CurrentFrame = (data.iEndStrafe_CurrentFrame + 1) % MAX_FRAMES
	data.iLastReleaseTick[button][BT_Move] = data.iLastReleaseTick[button][BT_Move] or 0
	data.iReleaseTickAtLastEndStrafe[button] = data.iLastReleaseTick[button][BT_Move]
	data.iLastReleaseTick_Recorded[button][BT_Move] = data.iLastReleaseTick[button][BT_Move]
	data.iEndStrafe_LastRecordedTick	= data.iCmdNum
	data.bEndStrafe_IsRecorded[fr]		= true
	data.iEndStrafe_Stats[fr] = {
		IsTiming		= IsTimerRunning(client),
		Tick			= data.iCmdNum,
		TurnDirection	= turnDir,
		MoveDirection	= moveDir,
		Button			= button,
	}

	local difference = data.iLastReleaseTick[button][BT_Move] - data.iLastStopTurnTick
	data.iLastTurnTick_Recorded_EndStrafe = data.iLastStopTurnTick
	if data.iLastTurnTick > data.iLastStopTurnTick then
		difference = data.iLastReleaseTick[button][BT_Move] - data.iLastTurnTick
		data.iLastTurnTick_Recorded_EndStrafe = data.iLastTurnTick
	end
	data.iEndStrafe_Stats[fr].Difference = difference

	if difference == 0 and not IsInLeftRight(data) then
		data.iEndStrafe_PerfCount = data.iEndStrafe_PerfCount + 1
	else
		data.iEndStrafe_PerfCount = 0
	end
	if data.iEndStrafe_PerfCount >= g_cfg.min_perfect_strafes then
		ReasonLog(Reasons.ManyPerfect, LogLevel.HIGH, client, "end", data.iEndStrafe_PerfCount)
	end

	if data.iEndStrafe_CurrentFrame == 0 then
		local array, size, timingCount = {}, 0, 0

		for idx = 0, MAX_FRAMES - 1 do
			if data.bEndStrafe_IsRecorded[idx] == true then
				array[idx] = data.iEndStrafe_Stats[idx].Difference
				size = size + 1

				if data.iEndStrafe_Stats[idx].IsTiming == true then
					timingCount = timingCount + 1
				end
			end
		end

		local mean = GetAverage(array, size)
		local sd   = StandardDeviation(array, size, mean)
		-- print("End starfe", client, mean, sd, size)

		if sd < g_cfg.max_log_sd then
			local sStyle = GetStyleName(client)
			local timingPct = timingCount / MAX_FRAMES * 100
			local level = LogLevel.MEDIUM
			if sd <= g_cfg.max_ban_sd and timingPct >= g_cfg.min_ban_timing then
				level = LogLevel.HIGH_BAN
			end
			ReasonLog(Reasons.EndStrafe, level, client, mean, sd, timingPct, sStyle)
			if level == LogLevel.HIGH_BAN then
				BanPlayer(client, BAN_LENGTH, "End strafe dev " .. sd)
			end
		end
	end

	data.iKeyPressesThisStrafe[BT_Move] = 0
	data.iKeyPressesThisStrafe[BT_Key]  = 0
end

local function CheckForWOnlyHack(data)
	-- Player turned more than 13 degrees in 1 tick
	if math.abs(data.fAngleDifference.yaw - data.fLastAngleDifference.yaw) > 13 and
		data.fAngleDifference[1] ~= 0.0 and (data.iCmdNum - data.iLastTeleportTick) > 200
	then
		data.iIllegalTurn[data.iIllegalTurn_CurrentFrame] = true
		-- PrintToAdmins(LogLevel.LOW, "%N: %.1f", client, FloatAbs(data.fAngleDifference - data.fLastAngleDifference))
	else
		data.iIllegalTurn[data.iIllegalTurn_CurrentFrame] = false
		-- GetTurnDirectionName(data.iLastTurnDir, sTurn, sizeof(sTurn))
		-- PrintToAdmins(LogLevel.LOW, "No: Diff: %.1f, Btn: %d, Gain: %.1f", FloatAbs(data.fAngleDifference - data.fLastAngleDifference), data.iButtons[BT_Move] & (1 << GetOppositeButton(GetDesiredButton(client, data.iLastTurnDir))), GetGainPercent(client))
	end

	data.iIllegalTurn_IsTiming[data.iIllegalTurn_CurrentFrame] = IsTimerRunning(data.ply)
	data.iIllegalTurn_CurrentFrame = (data.iIllegalTurn_CurrentFrame + 1) % MAX_FRAMES

	if data.iIllegalTurn_CurrentFrame == 0 then
		local illegalCount, timingCount = 0, 0
		for idx = 0, MAX_FRAMES - 1 do
			if data.iIllegalTurn[idx] == true then
				illegalCount = illegalCount + 1
			end
			if data.iIllegalTurn_IsTiming[idx] == true then
				timingCount = timingCount + 1
			end
		end

		local illegalPct = illegalCount / MAX_FRAMES * 100.0
		local timingPct = timingCount / MAX_FRAMES * 100.0

		if illegalPct > g_cfg.min_wonly_pct then
			local client = data.ply
			local sStyle = GetStyleName(client)
			ReasonLog(Reasons.AngleSnap, LogLevel.HIGH, client, illegalPct, timingPct, sStyle)
		end
	end
end

local function CheckForTurn(data)
	local yaw = data.fAngleDifference.yaw
	if yaw == 0.0 and data.bIsTurning == true then
		data.iLastStopTurnTick = data.iCmdNum
		data.bIsTurning		= false
	elseif yaw > 0 then
		if data.iLastTurnDir == Turn_Right then
			-- Turned left
			data.iLastTurnTick = data.iCmdNum
			data.iLastTurnDir  = Turn_Left
			data.bIsTurning	= true
		end
	elseif yaw < 0 then
		if data.iLastTurnDir == Turn_Left then
			-- Turned right
			data.iLastTurnTick = data.iCmdNum
			data.iLastTurnDir  = Turn_Right
			data.bIsTurning	= true
		end
	end
end

local function CheckForEndKey(data)
	for idx = 0, 3 do
		if  bit.band(data.iLastButtons[BT_Move] or 0, bit.lshift(1, idx)) ~= 0 and
			bit.band(data.iButtons[BT_Move], bit.lshift(1, idx)) == 0
		then
			data.iLastReleaseTick[idx][BT_Move] = data.iCmdNum
		end

		if  bit.band(data.iLastButtons[BT_Key] or 0, bit.lshift(1, idx)) ~= 0 and
			bit.band(data.iButtons[BT_Key], bit.lshift(1, idx)) == 0
		then
			data.iLastReleaseTick[idx][BT_Key] = data.iCmdNum
		end
	end
end

local function CheckForStartKey(data)
	for idx = 0, 3 do
		if  bit.band(data.iLastButtons[BT_Move] or 0, bit.lshift(1, idx)) == 0 and
			bit.band(data.iButtons[BT_Move], bit.lshift(1, idx)) ~= 0
		then
			data.iLastPressTick[idx][BT_Move] = data.iCmdNum
		end

		if  bit.band(data.iLastButtons[BT_Key] or 0, bit.lshift(1, idx)) == 0 and
			bit.band(data.iButtons[BT_Key], bit.lshift(1, idx)) ~= 0
		then
			data.iLastPressTick[idx][BT_Key] = data.iCmdNum
		end
	end
end

local function CheckForTeleport(data, pos)
	local distance = math.pow(pos.x - data.fLastPosition.x, 2)
		+ math.pow(pos.y - data.fLastPosition.y, 2)
		+ math.pow(pos.z - data.fLastPosition.z, 2)

	if distance > 1225.0 then -- 35*35
		data.iLastTeleportTick = data.iCmdNum
	end
end

local function IsValidMove(move)
	local x = math.abs(move)
	return x == 0 or x == MAX_MOVE or x == MAX_MOVE*.75 or x == MAX_MOVE*.50 or x == MAX_MOVE*.25
end

local function IsMoveUnSync(buttons, move, negative, positive)
	local both, abs = bit.band(buttons, negative + positive), math.abs(move)
	local a, b, c = MAX_MOVE*.25, MAX_MOVE*0.5, MAX_MOVE*.75

	if both == 0 or both == (negative + positive) then
		if move ~= 0.0 and abs ~= a and abs ~= b and abs ~= c then return false end
	elseif (both == negative and move ~= -MAX_MOVE and move ~= -b and move ~= -c)
		or (both == positive and move ~= MAX_MOVE and move ~= b and move ~= c)
	then return false end

	return (move == 0 and (both == negative or both == positive))
		or (move < 0 and bit.band(buttons, negative) == 0) or (move > 0 and bit.band(buttons, positive) == 0)
		-- or (move > 0 and bit.band(buttons, negative) ~= 0) or (move < 0 and bit.band(buttons, positive) ~= 0)
		-- or (move ~= 0 and (both == 0 or both == (negative + positive)))
end

local function CheckForIllegalMovement(data, vel, buttons)
    local sidemove = vel[2]
    local bInvalid = false
    local resetMove = false
    local deltaYaw = data.fAngleDifference.yaw

    data.iLastInvalidButtonCount = data.InvalidButtonSidemoveCount

    local fMaxMove = tonumber(GetConVar("cl_sidespeed"):GetString()) or 400.0

    if sidemove > 0 and bit.band(buttons, IN_MOVELEFT) ~= 0 then
        bInvalid = true
        data.sLastIllegalReason = 1
    elseif sidemove > 0 and bit.band(buttons, bit.bor(IN_MOVELEFT, IN_MOVERIGHT)) == bit.bor(IN_MOVELEFT, IN_MOVERIGHT) then
        bInvalid = true
        data.sLastIllegalReason = 2
    elseif sidemove < 0 and bit.band(buttons, IN_MOVERIGHT) ~= 0 then
        bInvalid = true
        data.sLastIllegalReason = 3
    elseif sidemove < 0 and bit.band(buttons, bit.bor(IN_MOVELEFT, IN_MOVERIGHT)) == bit.bor(IN_MOVELEFT, IN_MOVERIGHT) then
        bInvalid = true
        data.sLastIllegalReason = 4
    elseif sidemove == 0.0 and (bit.band(buttons, bit.bor(IN_MOVELEFT, IN_MOVERIGHT)) == IN_MOVELEFT or bit.band(buttons, bit.bor(IN_MOVELEFT, IN_MOVERIGHT)) == IN_MOVERIGHT) then
        bInvalid = true
        data.sLastIllegalReason = 5
    elseif sidemove ~= 0.0 and bit.band(buttons, bit.bor(IN_MOVELEFT, IN_MOVERIGHT)) == 0 then
        bInvalid = true
        data.sLastIllegalReason = 6
    end

    if bInvalid then
        data.InvalidButtonSidemoveCount = data.InvalidButtonSidemoveCount + 1
    else
        data.InvalidButtonSidemoveCount = 0
    end

    if data.InvalidButtonSidemoveCount >= 4 then
        vel[1] = 0.0
        vel[2] = 0.0
        vel[3] = 0.0
        resetMove = true
    end

    if data.InvalidButtonSidemoveCount == 0 and data.iLastInvalidButtonCount >= 10 then
        ReasonLog(Reasons.ButtonsMove, LogLevel.HIGH, data.ply, data.sLastIllegalReason, data.iLastInvalidButtonCount)
    end

    if math.floor(vel[1] * 100.0) % 625 ~= 0 or math.floor(vel[2] * 100.0) % 625 ~= 0 then
        data.iIllegalSidemoveCount = data.iIllegalSidemoveCount + 1
        vel[1], vel[2], vel[3] = 0.0, 0.0, 0.0
        resetMove = true

        if math.abs(deltaYaw) > 0 then
            data.iYawChangeCount = data.iYawChangeCount + 1
        end
    elseif (math.abs(vel[1]) ~= fMaxMove and vel[1] ~= 0.0) or (math.abs(vel[2]) ~= fMaxMove and vel[2] ~= 0.0) then
        data.iIllegalSidemoveCount = data.iIllegalSidemoveCount + 1

        if math.abs(deltaYaw) > 0 then
            data.iYawChangeCount = data.iYawChangeCount + 1
        end
    else
        data.iIllegalSidemoveCount = 0
    end

    if data.iIllegalSidemoveCount >= 4 then
        vel[1], vel[2], vel[3] = 0.0, 0.0, 0.0
        resetMove = true
    end

    if data.iIllegalSidemoveCount == 0 then
        if data.iLastIllegalSidemoveCount >= 10 then
            local ratio = data.iYawChangeCount / data.iLastIllegalSidemoveCount
            local bBan = ratio > g_cfg.min_yaw_change_ratio and data.cvar.joystick == false
            local level = bBan and LogLevel.HIGH_BAN or LogLevel.HIGH
            ReasonLog(Reasons.ConsecutiveMove, level, data.ply, data.cvar.joystick and 1 or 0,
                data.iYawChangeCount, data.iLastIllegalSidemoveCount, bBan and "BAN" or "SUSPECT")
        end

        data.iYawChangeCount = 0
    end

    data.iLastIllegalSidemoveCount = data.iIllegalSidemoveCount

    return resetMove
end

local function CheckForIllegalTurning(data, vel)
    local buttons = data.iRealButtons or 0
    local iLR = bit.band(buttons, IN_LEFT + IN_RIGHT)

    if iLR ~= 0 then
        data.iPlusLeftCount = data.iPlusLeftCount + 1
    end

    if data.iCmdNum % 100 == 0 then
        if data.iIllegalYawCount > 30 and data.iPlusLeftCount == 0 then
            ReasonLog(Reasons.IllegalYaw, LogLevel.HIGH, data.ply, data.cvar.m_yaw, data.cvar.sensitivity,
                data.cvar.m_customaccel, data.iIllegalYawCount, data.cvarChangedCount["m_yaw"], data.cvar.joystick)
        end
        data.iIllegalYawCount = 0
        data.iPlusLeftCount = 0
    end

    -- Don't bother checking if they aren't turning
    if math.abs(data.fAngleDifference[2]) < 0.01 then return end

    -- calculate illegal turns when player cvars have been checked
    if data.cvarCheckedCount["m_customaccel"] == 0 or data.cvarCheckedCount["m_filter"] == 0 or
       data.cvarCheckedCount["m_yaw"] == 0 or data.cvarCheckedCount["sensitivity"] == 0 then return end

    -- for teleporting
    if data.iCmdNum - data.iLastTeleportTick < 100 then return end

    -- high sensitivity detections
    if math.abs(data.fAngleDifference[2]) > 20.0 or math.abs(data.cvar.sensitivity * data.cvar.m_yaw) > 0.8 then return end

    -- zoomed-in players from triggering the anticheat
    local fovStart = data.ply:GetInternalVariable("m_iFOVStart")
    if fovStart and fovStart ~= 90 then return end

    -- rotating block false positives
    if data.bTouchesFuncRotating then return end

    if data.iIllegalSidemoveCount > 0 then return end

    local fMaxMove = (10000 and 400.0) or (ENGINE_CSGO and 450.0) or 0
    if math.abs(vel[1]) ~= fMaxMove and math.abs(vel[2]) ~= fMaxMove then return end

    local my = data.fAngleDifference[1]
    local mx = data.fAngleDifference[2]
    local fCoeff = 0

    -- if turning is illegal
    if (data.cvar.m_yaw == 0.0 or data.cvar.sensitivity == 0.0) and iLR == 0 then
        data.iIllegalYawCount = data.iIllegalYawCount + 1
    elseif data.cvar.m_customaccel <= 0 or data.cvar.m_customaccel > 3 then
        fCoeff = data.cvar.sensitivity
    elseif data.cvar.m_customaccel == 1 or data.cvar.m_customaccel == 2 then
        local raw_mouse_movement_distance = math.sqrt(mx * mx + my * my)
        local accelerated_sensitivity = math.pow(raw_mouse_movement_distance, data.cvar["m_customaccel_exponent"]) *
                                        data.cvar["m_customaccel_scale"] + data.cvar.sensitivity

        if accelerated_sensitivity > 0.0001 and accelerated_sensitivity > data.cvar["m_customaccel_max"] then
            accelerated_sensitivity = data.cvar["m_customaccel_max"]
        end

        fCoeff = accelerated_sensitivity
        if data.cvar.m_customaccel == 2 then
            fCoeff = fCoeff * data.cvar.m_yaw
        end
    else
        fCoeff = data.cvar.sensitivity
        return
    end

    if ENGINE_CSS and data.cvar.m_filter then
        fCoeff = fCoeff / 4
    end

    local fTurn = mx / (data.cvar.m_yaw * fCoeff)
    local fRounded = math.Round(fTurn)

    if math.abs(fRounded - fTurn) > 0.1 then
        data.fIList[data.iCurrentIFrame] = fTurn
        data.iCurrentIFrame = (data.iCurrentIFrame + 1) % 20
        data.iIllegalYawCount = data.iIllegalYawCount + 1
    end
end

local function ClientPressedKey(data, button, btype)
    data.iKeyPressesThisStrafe[btype] = (data.iKeyPressesThisStrafe[btype] or 0) + 1

    if btype == BT_Move then
        local turnDir = GetDesiredTurnDir(data.ply, button, false)

        if data.iLastTurnDir == turnDir and 
           data.iStartStrafe_LastRecordedTick ~= data.iCmdNum and
           data.iLastPressTick[button] and data.iLastPressTick[button][BT_Move] ~= data.iLastPressTick_Recorded[button][BT_Move] and
           data.iLastTurnTick ~= data.iLastTurnTick_Recorded_StartStrafe 
        then
            local difference = data.iLastTurnTick - data.iLastPressTick[button][BT_Move]
            if difference >= -15 and difference <= 15 then
                RecordStartStrafe(data, button, turnDir, "ClientPressedKey")
            end
        end
    end

    local oppositeButton = GetOppositeButton(button)
    local difference = (data.iLastPressTick[button] and data.iLastPressTick[button][btype] or 0) - 
                       (data.iLastReleaseTick[oppositeButton] and data.iLastReleaseTick[oppositeButton][btype] or 0)

    if difference <= 15 and 
       data.iKeySwitch_LastRecordedTick[btype] ~= data.iCmdNum and
       data.iLastReleaseTick[oppositeButton] and data.iLastReleaseTick[oppositeButton][btype] ~= data.iLastReleaseTick_Recorded_KS[oppositeButton][btype] and
       data.iLastPressTick[button] and data.iLastPressTick[button][btype] ~= data.iLastPressTick_Recorded_KS[button][btype] 
    then
        RecordKeySwitch(data, button, oppositeButton, btype, "ClientPressedKey")
    end
end

local function ClientReleasedKey(data, button, btype)
    if btype == BT_Move then
        local turnDir = GetDesiredTurnDir(data.ply, button, true)

        if (data.iLastTurnDir == turnDir or not data.bIsTurning) and
           data.iEndStrafe_LastRecordedTick ~= data.iCmdNum and
           (data.iLastReleaseTick_Recorded[button] and data.iLastReleaseTick_Recorded[button][BT_Move]) ~= 
           (data.iLastReleaseTick[button] and data.iLastReleaseTick[button][BT_Move]) and
           data.iLastTurnTick_Recorded_EndStrafe ~= data.iLastTurnTick
        then
            local difference = data.iLastTurnTick - (data.iLastReleaseTick[button] and data.iLastReleaseTick[button][BT_Move] or 0)
            if difference >= -15 and difference <= 15 then
                RecordEndStrafe(data, button, turnDir, "ClientReleasedKey")
            end
        end
    end

    if btype == BT_Key then
        local oppositeButton = GetOppositeButton(button)
        
        local lastRelease = data.iLastReleaseTick[button] and data.iLastReleaseTick[button][BT_Key] or 0
        local lastPress = data.iLastPressTick[oppositeButton] and data.iLastPressTick[oppositeButton][BT_Key] or 0

        if (lastRelease - lastPress) <= 15 and
           data.iKeySwitch_LastRecordedTick[BT_Key] ~= data.iCmdNum and
           (data.iLastReleaseTick[button] and data.iLastReleaseTick[button][btype]) ~= 
           (data.iLastReleaseTick_Recorded_KS[button] and data.iLastReleaseTick_Recorded_KS[button][btype]) and
           (data.iLastPressTick[oppositeButton] and data.iLastPressTick[oppositeButton][btype]) ~= 
           (data.iLastPressTick_Recorded_KS[oppositeButton] and data.iLastPressTick_Recorded_KS[oppositeButton][btype])
        then
            RecordKeySwitch(data, oppositeButton, button, btype, "ClientReleasedKey")
        end
    end
end

local function ClientTurned(data, turnDir)
    local button = GetDesiredButton(data.ply, turnDir)
    local oppositeButton = GetOppositeButton(button)

    if bit.band(data.iButtons[BT_Move], oppositeButton) == 0 and
       data.iEndStrafe_LastRecordedTick ~= data.iCmdNum and
       (data.iReleaseTickAtLastEndStrafe[oppositeButton] or 0) ~= (data.iLastReleaseTick[oppositeButton] and data.iLastReleaseTick[oppositeButton][BT_Move] or 0) and
       data.iLastTurnTick_Recorded_EndStrafe ~= data.iLastTurnTick
    then
        local difference = data.iLastTurnTick - (data.iLastReleaseTick[oppositeButton] and data.iLastReleaseTick[oppositeButton][BT_Move] or 0)
        if difference >= -15 and difference <= 15 then
            RecordEndStrafe(data, oppositeButton, turnDir, "ClientTurned")
        end
    end

    if bit.band(data.iButtons[BT_Move], button) ~= 0 and
       data.iStartStrafe_LastRecordedTick ~= data.iCmdNum and
       (data.iLastPressTick_Recorded[button] and data.iLastPressTick_Recorded[button][BT_Move]) ~= 
       (data.iLastPressTick[button] and data.iLastPressTick[button][BT_Move]) and
       data.iLastTurnTick_Recorded_StartStrafe ~= data.iLastTurnTick
    then
        local difference = data.iLastTurnTick - (data.iLastPressTick[button] and data.iLastPressTick[button][BT_Move] or 0)
        if difference >= -15 and difference <= 15 then
            RecordStartStrafe(data, button, turnDir, "ClientTurned")
        end
    end

    CheckForWOnlyHack(data)
end

local function ClientStoppedTurning(data)
    local turnDir = data.iLastTurnDir
    local button = GetDesiredButton(data.ply, turnDir)

    if bit.band(data.iButtons[BT_Move], button) == 0 and
       data.iEndStrafe_LastRecordedTick ~= data.iCmdNum and
       (data.iReleaseTickAtLastEndStrafe[button] or 0) ~= (data.iLastReleaseTick[button] and data.iLastReleaseTick[button][BT_Move] or 0) and
       data.iLastTurnTick_Recorded_EndStrafe ~= data.iLastStopTurnTick
    then
        local difference = data.iLastStopTurnTick - (data.iLastReleaseTick[button] and data.iLastReleaseTick[button][BT_Move] or 0)
        if difference >= -15 and difference <= 15 then
            RecordEndStrafe(data, button, turnDir, "ClientStoppedTurning")
        end
    end
end

-- Scroll
local ScrollState = {
	Nothing = 0,
	Landing = 1,
	Jumping = 2,
	Pressing = 3,
	Releasing = 4,
}

local function ResetScrollStats(data)
	data.iScrollReleaseTick = engine.TickCount()
	data.iScrollAirTicks = 0
	data.scrollStats = {
		Scrolls = 0,
		BeforeGround = 0,
		AfterGround = 0,
		AverageTicks = 0,
		PerfectJump = false,
	}
end

local VECTOR_0_0_m32768 = Vector(0, 0, 32768)
local function GetGroundDistance(ply)
	if IsValid(ply:GetGroundEntity()) then return 0 end
	local pos = ply:GetPos()
    local tr = util.TraceLine({
        start = pos,
        endpos = pos + VECTOR_0_0_m32768,
        mask = MASK_PLAYERSOLID_BRUSHONLY,
    })
	return tr.Hit and (pos.z - tr.HitPos.z) or 0
end

local function GetSampledJumps(data)
	if #data.scrollHistory == 0 then return 0 end
	local iSize = #data.scrollHistory
	local iEnd = iSize >= g_iScrollSamples and iSize - g_iScrollSamples or 0
	return iSize - iEnd
end

local function GetPerfectJumps(data)
	local iPerfs = 0
	local iSize = #data.scrollHistory
	local iEnd = iSize >= g_iScrollSamples and iSize - g_iScrollSamples or 0
	local iTotalJumps = iSize - iEnd

	for i = iSize, iEnd + 1, -1 do
		if data.scrollHistory[i].PerfectJump then
			iPerfs = iPerfs + 1
		end
	end

	if iTotalJumps == 0 then
		return 0
	end

	return math.floor((iPerfs / iTotalJumps) * 100)
end

local function GetScrollStatsFormatted(data)
	local buffer = string.format("%d%% perfs, %d sampled jumps: {", GetPerfectJumps(data), GetSampledJumps(data))
	local iSize = #data.scrollHistory
	local iEnd = iSize >= g_iScrollSamples and iSize - g_iScrollSamples or 0

	for i = iSize, iEnd + 1, -1 do
		buffer = string.format("%s %d%s,", buffer, data.scrollHistory[i].Scrolls,
			data.scrollHistory[i].PerfectJump and "!" or "")
	end

	-- if buffer[#buffer] == "," then buffer[#buffer] = " " end
	return buffer .. "}"
end

function BashStats.ScrollStatsMenu(menu, client, action, key)
	if action == "select" then
		BashStats.ScrollStats(client, key == "full")
	end
	if action == "cancel" then
		ShowBashStats(client, g_target[client])
	end
	if action == "end" then menu:Close() end
end

function BashStats.ScrollStats(client, full)
	local target = g_target[client]
	if not IsValid(target) then
		return PrintToChat(client, "Selected player no longer ingame.")
	end

	local data = GetBashData(target)
	local iPerfs = GetPerfectJumps(data)
	local iSize = #data.scrollHistory
	local iEnd = iSize >= g_iScrollSamples and iSize - g_iScrollSamples or 0
	local iSampled = iSize - iEnd

	if iSampled == 0 then
		PrintToChat(client, target:Nick() .. " does not have recorded jump stats.")
	end

	local menu = SourceModMenu(BashStats.ScrollStatsMenu)
	menu:SetTitle(string.format("[BASH] Scroll stats: %s\nPerfs: %d | Sampled: %d / %d | # %d",
		target:Nick(), iPerfs, iSampled, g_iScrollSamples, data.iScrollCurrentJump))
	if full then
		menu:AddItem("short", "Show short stats...")
		menu:AddItem("", "#(perf) cnt before/after avg_ticks", true)
		for i = iSize, iEnd + 1, -1 do
			local x = data.scrollHistory[i]
			local row = string.format("%2d%s%3d %3d/%3d %10g", i, x.PerfectJump and "!" or ".",
				x.Scrolls, x.BeforeGround, x.AfterGround, x.AverageTicks)
			menu:AddItem("mono", row, true)
		end
	else
		menu:AddItem("full", "Show detailed stats...")
		local sDisplay, idx = "", 1
		for i = iSize, 1, -1 do
			local jump = data.scrollHistory[i]
			sDisplay = string.format("%s%2d%s", sDisplay, jump.Scrolls or -1, jump.PerfectJump and "!" or " ")
			if idx % g_cfg.menu_cols == 0 or i == 1 then
				menu:AddItem("mono", sDisplay, true)
				sDisplay = ""
			end
			idx = idx + 1
		end
	end
	menu:AddItem("cancel")
	menu:Display(client, 0)
end

local function AnalyzeScrollStats(data)
	local iPerfs = GetPerfectJumps(data)

	local iVeryHighNumber = 0
	local iSameAsNext = 0
	local iCloseToNext = 0
	local iBadIntervals = 0
	local iLowBefores = 0
	local iLowAfters = 0
	local iSameBeforeAfter = 0

	for i = data.iScrollCurrentJump - g_iScrollSamples + 1, data.iScrollCurrentJump - 1 do
		-- TODO: Cache iNextScrolls for the next time this code is ran
		local stats = data.scrollHistory[i]
		local iCurScrolls = stats.Scrolls

		if i < g_iScrollSamples then
			local iNextScrolls = data.scrollHistory[i + 1].Scrolls
			if iCurScrolls == iNextScrolls then iSameAsNext = iSameAsNext + 1 end
			if math.abs(math.max(iCurScrolls, iNextScrolls) - math.min(iCurScrolls, iNextScrolls)) <= 2 then
				iCloseToNext = iCloseToNext + 1
			end
		end

		if iCurScrolls >= 17 then iVeryHighNumber = iVeryHighNumber + 1 end
		if stats.AverageTicks <= 2 then iBadIntervals = iBadIntervals + 1 end
		if stats.BeforeGround <= 1 then iLowBefores = iLowBefores + 1 end
		if stats.AfterGround <= 1 then iLowAfters = iLowAfters + 1 end
		if stats.BeforeGround == stats.AfterGround then iSameBeforeAfter = iSameBeforeAfter + 1 end
	end

	local level, reason, pattern, msg = LogLevel.MEDIUM, Reasons.ScriptedJumps, "", ""
	local fIntervals = iBadIntervals / g_iScrollSamples
	local bTriggered = true

	-- Ugly code below, I know.
	if iPerfs >= 91 then
		level, pattern = LogLevel.HIGH_BAN, "over sample size"
	elseif iPerfs >= 87 and (iSameAsNext >= 13 or iCloseToNext >= 18) then
		msg = string.format("(same %d | close %d) ", iSameAsNext, iCloseToNext)
		level, pattern = LogLevel.HIGH_BAN, "consistent"
	elseif iPerfs >= 85 and iSameAsNext >= 13 then
		level, pattern, msg = LogLevel.HIGH_BAN, "very consistent", string.format("(same %d) ", iSameAsNext)
	elseif iPerfs >= 80 and iSameAsNext >= 15 then
		level, pattern, msg = LogLevel.HIGH_KICK, "inhumanly", string.format("(same %d) ", iSameAsNext)
	elseif iPerfs >= 75 and iVeryHighNumber >= 4 and iSameAsNext >= 3 and iCloseToNext >= 10 then
		msg = string.format("(high %d | same %d | close %d) ", iVeryHighNumber, iSameAsNext, iCloseToNext)
		level, pattern = LogLevel.HIGH_KICK, "inhumanly #2"
	elseif iPerfs >= 85 and iCloseToNext >= 16 then
		level, pattern, msg = LogLevel.HIGH_KICK, "randomized", string.format("(close %d) ", iCloseToNext)
	elseif iPerfs >= 40 and iLowBefores >= 45 then
		pattern, msg = "no bf", string.format("(bf %d) ", iLowBefores)
	elseif iPerfs >= 55 and iSameBeforeAfter >= 25 then
		msg = string.format("(bf %d | af %d | bfaf %d) ", iLowBefores, iLowAfters, iSameBeforeAfter)
		level, pattern = LogLevel.HIGH, "bf=af"
	elseif iPerfs >= 40 and iLowAfters >= 45 then
		level, pattern, msg = LogLevel.LOW, "no af", string.format("(af %d) ", iLowAfters)
	elseif iVeryHighNumber >= 15 and (iCloseToNext >= 13 or iPerfs >= 80) then
		reason, level, msg = Reasons.ScrollMacro, LogLevel.HIGH_KICK, string.format("(close %d) ", iCloseToNext)
	elseif fIntervals > 0.75 then
		reason, msg = Reasons.ScrollCheat, string.format("(intervals: %.2f) ", fIntervals)
	else
		bTriggered = false
	end

	if bTriggered then
		local sScrollStats = GetScrollStatsFormatted(data)
		if reason == Reasons.ScriptedJumps then
			ReasonLog(reason, level, data.ply, pattern, msg .. sScrollStats)
		else
			ReasonLog(reason, level, data.ply, msg .. sScrollStats)
		end

		if level == LogLevel.HIGH_KICK then
			KickPlayer(data.ply, "Scripted jumps")
		elseif level == LogLevel.HIGH_BAN then
			BanPlayer(data.ply, BAN_LENGTH, "Scripted jumps: " .. pattern)
		end

		-- Hard reset stats after logging, to prevent spam
		ResetScrollStats(data)
		data.iScrollCurrentJump = 1
		data.scrollHistory = {}
	end
end

local function CollectScrollStats(data, bOnGround, buttons, fAbsVelocityZ)
	local iGroundState = ScrollState.Nothing
	local iButtonState = ScrollState.Nothing
	local curJump = data.iScrollCurrentJump

	if bOnGround and not data.bScrollPreviousGround then
		iGroundState = ScrollState.Landing
	elseif not bOnGround and data.bScrollPreviousGround then
		iGroundState = ScrollState.Jumping
	end

	local inJump = bit.band(buttons, IN_JUMP) > 0
	if inJump and bit.band(data.iScrollPreviousButtons, IN_JUMP) == 0 then
		iButtonState = ScrollState.Pressing
	elseif not inJump and bit.band(data.iScrollPreviousButtons, IN_JUMP) > 0 then
		iButtonState = ScrollState.Releasing
	end

	local iTicks = engine.TickCount()
	if iButtonState == ScrollState.Pressing then
		data.scrollStats.Scrolls = data.scrollStats.Scrolls + 1
		data.scrollStats.AverageTicks = data.scrollStats.AverageTicks + (iTicks - data.iScrollReleaseTick)

		if bOnGround then
			if inJump then
				data.scrollStats.PerfectJump = not data.bScrollPreviousGround
			end
		else
			local fDistance = GetGroundDistance(data.ply)
			if fDistance < 33.0 then
				if fAbsVelocityZ > 0.0 and curJump > 1 then
					-- 'Inject' data into the previous recorded jump
					local iAfter = data.scrollHistory[curJump - 1].AfterGround
					data.scrollHistory[curJump - 1].AfterGround = iAfter + 1
				elseif fAbsVelocityZ < 0.0 then
					data.scrollStats.BeforeGround = data.scrollStats.BeforeGround + 1
				end
			end
		end
	elseif iButtonState == ScrollState.Releasing then
		data.iScrollReleaseTick = iTicks
	end

	if not bOnGround and data.iScrollAirTicks > g_cfg.ticks_not_count_air then
		return ResetScrollStats(data)
	end
	data.iScrollAirTicks = data.iScrollAirTicks + 1

	if iGroundState == ScrollState.Landing then
		local iScrolls = data.scrollStats.Scrolls
		if iScrolls == 0 then return ResetScrollStats(data) end

		if data.iScrollGroundTicks < g_cfg.ticks_not_count_jump then
			data.scrollHistory[curJump] = {
				Scrolls = iScrolls,
				BeforeGround = data.scrollStats.BeforeGround,
				AfterGround = 0,
				AverageTicks = (data.scrollStats.AverageTicks / iScrolls),
				PerfectJump = data.scrollStats.PerfectJump,
			}
			-- FIXME: use ring buffer instead
			if curJump > g_cfg.scroll_max_history then
				local arr = {}
				for i = curJump - g_iScrollSamples, curJump do
					table.insert(arr, data.scrollHistory[i])
				end
				data.scrollHistory, curJump = arr, #arr
			end

			data.iScrollCurrentJump = curJump + 1
		end

		data.iScrollGroundTicks = 0
		ResetScrollStats(data)
	elseif iGroundState == ScrollState.Jumping and curJump > 1 and (curJump - 1) % g_iScrollSamples == 0 then
		AnalyzeScrollStats(data)
	end
end

function CheckScrollHacks(client, data, buttons)
	local bOnGround = client:IsOnGround() or client:WaterLevel() >= 2

	if bOnGround then
		data.iScrollGroundTicks = data.iScrollGroundTicks + 1
	end

	local fAbsVelocity = client:GetAbsVelocity()
	local fSpeed = fAbsVelocity:Length2D()

	-- Player isn't really playing but is just trying to make the anticheat go nuts.
	if fSpeed > 225.0 and IsLegalMoveType(client, false) then
		CollectScrollStats(data, bOnGround, buttons, fAbsVelocity.z)
	else
		ResetScrollStats(data)
	end

	data.bScrollPreviousGround = bOnGround
	data.iScrollPreviousButtons = buttons
end

-- Main
local function StripTurnBinds(client, cmd)
    if not cmd then return end
    
    local data = GetBashData(client)
    local ang = cmd:GetViewAngles()
    local turn = client:KeyDown(IN_RIGHT)

    if client:KeyDown(IN_LEFT) ~= turn then
        if data.lastTurn ~= nil and data.lastTurn ~= turn and data.iCmdNum < data.nextTurnTick then
            ang.yaw = data.fLastAngles.yaw or ang.yaw

            cmd:RemoveKey(IN_LEFT)
            cmd:RemoveKey(IN_RIGHT)

            cmd:SetViewAngles(ang)
            print("StripTurnBinds executed")
        else
            data.nextTurnTick = data.iCmdNum + g_cfg.turn_bind_delay
            data.lastTurn = turn
        end
    end
end
hook.Add("StartCommand", "StripTurnBinds", StripTurnBinds)

local function OnPlayerRunCmd(client, cmd)
    if client:IsBot() or not client:Alive() then return end

    local data = GetBashData(client)
    local angles = cmd:GetViewAngles()
    
    local vel = Vector()
    vel[1] = cmd:GetForwardMove()
    vel[2] = cmd:GetSideMove()
    vel[3] = cmd:GetUpMove()

    local buttons = StripMovement(client, vel, cmd:GetButtons())
    local bCheck = true
    data.iRealButtons = buttons

    if IsTimerPaused(client) or CanPlayerBypass(client) then
        bCheck = false
    end

    UpdateButtons(data, vel, buttons)
    UpdateAngles(data, angles)

    if bCheck then
        if data.bCheckedYet == false then
            data.bCheckedYet = true
            data.fLastCheckTime = CurTime()
        end

        if client:GetMoveType() ~= MOVETYPE_NONE then
            data.mLastMoveType = client:GetMoveType()
        end

        data.iRunCmdsPerSecond = data.iRunCmdsPerSecond + 1

        if CurTime() - data.fLastCheckTime >= 1.0 then
            if data.iRunCmdsPerSecond / g_fTickRate <= 0.95 then
                data.iBadSeconds = data.iBadSeconds + 1

                if data.iBadSeconds >= 3 then
                    client:SetMoveType(MOVETYPE_NONE)
                end
            else
                if client:GetMoveType() == MOVETYPE_NONE then
                    client:SetMoveType(data.mLastMoveType)
                end

                data.iBadSeconds = 0
            end

            data.fLastCheckTime = CurTime()
            data.iRunCmdsPerSecond = 0
        end
    end

    CheckForTeleport(data, client:GetPos())
    CheckForEndKey(data)
    CheckForTurn(data)
    CheckForStartKey(data)

    if bCheck and not (client:IsFlagSet(FL_INWATER) and client:OnGround()) and client:GetMoveType() == MOVETYPE_WALK then
        for idx = 0, 3 do
            if data.iLastReleaseTick[idx][BT_Move] == data.iCmdNum then
                ClientReleasedKey(data, idx, BT_Move)
            end
            if data.iLastReleaseTick[idx][BT_Key] == data.iCmdNum then
                ClientReleasedKey(data, idx, BT_Key)
            end
        end

        if data.iLastTurnTick == data.iCmdNum then
            ClientTurned(data, data.iLastTurnDir)
        end
        if data.iLastStopTurnTick == data.iCmdNum then
            ClientStoppedTurning(data)
        end

        for idx = 0, 3 do
            if data.iLastPressTick[idx][BT_Move] == data.iCmdNum then
                ClientPressedKey(data, idx, BT_Move)
            end
            if data.iLastPressTick[idx][BT_Key] == data.iCmdNum then
                ClientPressedKey(data, idx, BT_Key)
            end
        end
    end

    if bCheck then
        if CheckForIllegalMovement(data, vel, buttons) then
            ResetPlayerMove(vel, cmd)
        end
        CheckForIllegalTurning(data, vel, cmd:GetMouseX())
        UpdateGains(data, vel, angles, buttons)

        if g_cfg.do_scroll_checks and IsScrollStyle(client) then
            CheckScrollHacks(client, data, buttons)
        end
        if g_cfg.log_insert_press then
            LogPlayerButtonDowns(data)
        end
    end

    if data.bTouchesFuncRotating and not client:OnGround() then
        data.bTouchesFuncRotating = false
    end

    data.fLastMove = vel
    data.fLastAngles = angles
    data.fLastPosition = client:GetPos()
    data.fLastAngleDifference = Vector(data.fAngleDifference[1], data.fAngleDifference[2], data.fAngleDifference[3])
    data.iCmdNum = data.iCmdNum + 1
end
hook.Add("StartCommand", ID, OnPlayerRunCmd)

-- Init
local function OnClientPutInServer(ply)
	ply.bash2_data = ResetBashData({ ply = ply })
	g_target[ply] = ply

	if ply:GetPData(ID .. "_admin", "0") == "1" then
		g_adminsFilter:AddPlayer(ply)
	end

	InitConvars(ply)
end
hook.Add("PlayerInitialSpawn", ID, OnClientPutInServer)

local function OnPlayerDisconnected(client)
	g_adminsFilter:RemovePlayer(client)
end
hook.Add("PlayerDisconnected", ID, OnPlayerDisconnected)

do -- Init players after lua autorefresh
	for i, ply in ipairs(player.GetAll()) do
		OnClientPutInServer(ply)
	end
end

local function Initialize()
	-- TODO
end
hook.Add("Initialize", ID, Initialize)
