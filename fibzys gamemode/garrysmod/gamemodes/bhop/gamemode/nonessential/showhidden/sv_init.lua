local ShowHidden, TriggerType = ShowHidden, ShowHidden.TriggerType

-- [[ ShowTriggers ]] --

local TRACK_TRIGGERS = ShowHidden.TRACK_TRIGGERS
local TRACK_OUTPUTS = {
	["OnStartTouch"] = true,
	["OnEndTouch"] = true,
	["OnTrigger"] = true,
}

-- TODO: create module for reading entities' outputs
-- TODO: diff 1-hop and bhop platforms?

local g_triggers = {}
local g_savedOutputs = {}
local g_platformTargetNames = {}
local g_filtersCache = {}
local g_lateCreation = false

util.AddNetworkString("ShowHidden.ShowTriggers")

-- Save some map triggers' outputs for later checks
local function RecordOutputs(ent, key, value)
	if not IsValid(ent) or not TRACK_OUTPUTS[key] or not TRACK_TRIGGERS[ent:GetClass()] then return end

	local outputs = g_savedOutputs[ent]
	if not outputs then
		outputs = {}
		g_savedOutputs[ent] = outputs
	end

	-- args = [ target, input, value, delay, repeat ]
	local args = string.Explode(",", value, false)
	if args[2] ~= "AddOutput" then return end

	outputs[key] = outputs[key] or {}
	table.insert(outputs[key], args[3])

	local delay = tonumber(args[4]) or 0
	local k, v = unpack(string.Explode(" ", args[3], false))

	if delay > 0 and delay < 0.1 and (k == "targetname" or k == "classname") then
		g_platformTargetNames[k .. " " .. v] = true
	end
end
hook.Add("EntityKeyValue", "ShowTriggers.RecordOutputs", RecordOutputs)

-- Returns is current filter name is platform filter
local function CheckPlatformFilter(name)
	if g_filtersCache[name] ~= nil then return g_filtersCache[name] end
	local result = false

	for i, ent in ipairs(ents.FindByName(name)) do
		if g_platformTargetNames["targetname " .. (ent:GetInternalVariable("m_iFilterName") or "")] then
			result = true
			break
		end
		if g_platformTargetNames["classname " .. (ent:GetInternalVariable("m_iFilterClass") or "")] then
			result = true
			break
		end
	end

	g_filtersCache[name] = result
	return result
end

-- Adds trigger to table and makes it visible
local function AddTrigger(ent, triggerType)
	local col = ShowHidden.DEFAULT_TRIGGERS_COLORS[triggerType]

	ent:RemoveEffects(EF_NODRAW)
	ent:SetRenderMode(RENDERMODE_TRANSCOLOR)
	ent:SetMaterial(ShowHidden.TRIGGERS_MATERIAL_NAMES[col.material])
	ent:SetColor(col.color)
	ent:SetNWInt("showtriggers_type", triggerType)

	table.insert(g_triggers[triggerType], ent)
end

-- Recognizes trigger type
local function CheckTrigger(ent)
	local class = ent:GetClass()
	if not TRACK_TRIGGERS[class] then return end

	if string.StartWith(class, "trigger_teleport") then
		local filter = ent:GetInternalVariable("m_iFilterName")
		if filter == "" then
			-- Normal reset teleport
			AddTrigger(ent, TriggerType.TELEPORT)
		elseif CheckPlatformFilter(filter) then
			-- This teleport used for bhop platforms
			AddTrigger(ent, TriggerType.PLATFORM)
		else
			-- Other teleports with filter
			AddTrigger(ent, TriggerType.TELE_FILTER)
		end
		-- SetNWVector of destination
	elseif class == "trigger_push" then
		AddTrigger(ent, TriggerType.PUSH)
	elseif g_savedOutputs[ent] then
		local outputs = g_savedOutputs[ent]

		for _, arg in ipairs(outputs["OnStartTouch"] or {}) do
			if arg == "gravity 40" then
				AddTrigger(ent, TriggerType.ANTIPRE)
			end
		end

		for _, arg in ipairs(outputs["OnEndTouch"] or {}) do
			if string.find(arg, "gravity -") then
				AddTrigger(ent, TriggerType.GRAVITY)
			elseif string.find(arg, "basevelocity") then
				AddTrigger(ent, TriggerType.BASEVEL)
			elseif string.find(arg, "targetname") then
				AddTrigger(ent, TriggerType.PLATFORM)
			end
		end

		-- Many maps use OnTrigger event
		for _, arg in ipairs(outputs["OnTrigger"] or {}) do
			if string.find(arg, "targetname") then
				AddTrigger(ent, TriggerType.PLATFORM)
			end
		end
	else
		AddTrigger(ent, TriggerType.OTHER) -- Unclassified triggers
	end
end

local function SendTriggersCount(ply)
	net.Start("ShowHidden.ShowTriggers")

	for triggerType = 1, TriggerType.MAX do
		net.WriteUInt(#g_triggers[triggerType] or 0, 16)
	end

	if ply then
		net.Send(ply)
	else
		net.Broadcast()
	end
end

local function ShowTriggersForPlayer(ply, types)
	for triggerType, triggers in pairs(g_triggers) do
		local hide = not ShowHidden.CheckMask(types, triggerType)

		for _, trig in ipairs(triggers) do
			if IsValid(trig) then
				trig:SetPreventTransmit(ply, hide)
			end
		end
	end
end

-- Find all supported triggers
local function InitTriggers()
	for _, ent in ipairs(ents.FindByClass("trigger_*")) do
		if IsValid(ent) then CheckTrigger(ent) end
	end
	g_lateCreation = true
end

local function ClearTriggers()
	g_platformTargetNames = {}
	g_filtersCache = {}
	g_savedOutputs = {}
	g_triggers = {}
	g_lateCreation = false

	for _, triggerType in pairs(TriggerType) do
		g_triggers[triggerType] = {}
	end
end

local function FixTriggers()
	InitTriggers()
	SendTriggersCount()

	for _, ply in ipairs(player.GetHumans()) do
		-- TODO: read player's enabled trigger types?
		local show = (ply:GetInfoNum("showtriggers_enabled", 0) == 1)
		ShowTriggersForPlayer(ply, show and ShowHidden.ALL_TYPES or 0)
	end
end

hook.Add("InitPostEntity", "ShowTriggers.InitTriggers", InitTriggers)
hook.Add("PreCleanupMap", "ShowTriggers.ClearTriggers", ClearTriggers)
hook.Add("PostCleanupMap", "ShowTriggers.InitTriggers", FixTriggers)

ClearTriggers() -- FIXME: It will clear outputs on lua refresh
if ShowHidden.Refresh then FixTriggers() end

hook.Add("OnEntityCreated", "ShowTriggers.NewTrigger", function(ent)
	if g_lateCreation and ent:IsValid() and TRACK_TRIGGERS[ent:GetClass()] and ent:GetNWInt("showtriggers_type", 0) == 0 then
		timer.Simple(0.1, function() -- wait for keyvalues
			if IsValid(ent) then CheckTrigger(ent) end
		end)
	end
end)

hook.Add("EntityRemoved", "ShowTriggers.RemoveTrigger", function(ent)
	if not g_lateCreation or not IsValid(ent) or not TRACK_TRIGGERS[ent:GetClass()] then return end

	for _, triggers in pairs(g_triggers) do
		g_savedOutputs[ent] = nil
		table.RemoveByValue(triggers, ent)
	end
end)

-- Disable triggers visibility for players by default
local function InitSpawnHideTriggers(ply)
	if not IsValid(ply) or ply:IsBot() then return end
	ShowTriggersForPlayer(ply, 0) -- Hide all triggers
end
hook.Add("PlayerInitialSpawn", "ShowTriggers.PlayerInitialSpawn", InitSpawnHideTriggers)

local lastTriggerRequest = {}

net.Receive("ShowHidden.ShowTriggers", function(len, ply)
    if len < 16 or not IsValid(ply) then return end

    local curTime = CurTime()
    lastTriggerRequest[ply] = lastTriggerRequest[ply] or 0

    -- Throttle: Prevent execution if called too soon
    if curTime - lastTriggerRequest[ply] < 1 then
        ply:ChatPrint("Please wait before using this again.") -- Optional feedback
        return
    end

    lastTriggerRequest[ply] = curTime -- Update last request time

    local types = net.ReadUInt(16)
    ShowTriggersForPlayer(ply, types)
    SendTriggersCount(ply)
end)

-- [[ Chat commands ]] --

local function OpenMenu(ply)
	ply:ConCommand("showhidden")
end

local function ShowClips(ply) ply:ConCommand("showclips 1") end
local function HideClips(ply) ply:ConCommand("showclips 0") end
local function ToggleClips(ply)
	ply:ConCommand("showclips " .. (ply:GetInfoNum("showclips", 0) == 0 and "1" or "0"))
end

local function ShowTriggers(ply) ply:ConCommand("showtriggers_enabled 1") end
local function HideTriggers(ply) ply:ConCommand("showtriggers_enabled 0") end
local function ToggleTriggers(ply)
	ply:ConCommand("showtriggers_enabled " .. (ply:GetInfoNum("showtriggers_enabled", 0) == 1 and "0" or "1"))
end

local function ShowProps(ply) ply:ConCommand("showprops 1") end
local function HideProps(ply) ply:ConCommand("showprops 0") end
local function ToggleProps(ply)
	ply:ConCommand("showprops " .. (ply:GetInfoNum("showprops", 0) == 1 and "0" or "1"))
end

local CHAT_COMMANDS = {
	[OpenMenu] =        { "showhidden", "clipsmenu", "triggersmenu", "showclipsmenu", "showtriggersmenu" },

	[ToggleClips] =     { "playerclips", "clips", "toggleclips" },
	[ShowClips] =       { "showclips", "showclip"},
	[HideClips] =       { "hideclips", "hideclip" },

	[ToggleTriggers] =  { "triggers", "trigger", "toggletriggers" },
	[ShowTriggers] =    { "showtriggers", "showtrigger" },
	[HideTriggers] =    { "hidetriggers", "hidetrigger" },

	[ToggleProps] =     { "staticprops", "togglestaticprops" },
	[ShowProps] =       { "showprops", "showstaticprops" },
	[HideProps] =       { "hideprops", "hidestaticprops" },
}

local function FallbackChatCommandHandler(ply, str)
	local prefix = str[1]
	if prefix == "!" or prefix == "/" then
		local cmd = string.Explode(" ", string.lower(string.sub(str, 2)))[1]

		for func, commands in pairs(CHAT_COMMANDS) do
			if table.HasValue(commands, cmd) then
				func(ply)
				return ""
			end
		end
	end
end

function AddChatCommands()
	if istable(Command) and isfunction(Command.Register) then
		-- FLOW v7
		for func, commands in pairs(CHAT_COMMANDS) do
			Command:Register(commands, func)
		end
	elseif istable(BHDATA) and isfunction(BHDATA.AddCmd) then
		-- FLOW v8
		for func, commands in pairs(CHAT_COMMANDS) do
			BHDATA.AddCmd(commands, func)
		end
	else
		-- Default fallback
		print("[ShowHidden]\tAdd chat commands")
		hook.Add("PlayerSay", "ShowHidden.PlayerSay", FallbackChatCommandHandler)
	end
end

hook.Add("PostGamemodeLoaded", "ShowHidden.AddChatCommands", AddChatCommands)
if ShowHidden.Refresh then AddChatCommands() end