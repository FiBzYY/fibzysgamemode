local UNIQUE_ID = "mute_map_music"
local MAX_RADIUS = 1250 -- greater means global

--[[ convar modes:
	0: allow music (mute disabled)
	1: mute soundscapes only (reconnect required)
	2: mute soundscapes + mute looped or (global and long) ambient_generic sounds 
	3: mute soundscapes + mute looped or any global ambient_generic sounds
	global sound is: plays everywhere or radius > MAX_RADIUS
	long sound is: duration = 60 or duration > maxDuration
]]

local shouldMute = CreateClientConVar(UNIQUE_ID, "0", true, true, 
	"1 = mute soundscapes (after reconnect); 2,3 = also mute ambient_generic")
local maxDuration = CreateClientConVar(UNIQUE_ID .. "_duration", "7.5", true, false,
	"in mode 2: mute if greater", 0)
local fadeTime = GetConVar("soundscape_fadetime"):GetInt()
local muteFromStart = shouldMute:GetBool()

cvars.AddChangeCallback(UNIQUE_ID, function(_, old, val)
	local mute = (val ~= "0")
	if mute then
		RunConsoleCommand("stopsound")
		timer.Simple(fadeTime, function()
			RunConsoleCommand("stopsound")
		end)
	else
		muteFromStart = false
	end
end)

hook.Add("PostCleanupMap", UNIQUE_ID, function()
	if not shouldMute:GetBool() then return end

	if not muteFromStart then
		timer.Simple(fadeTime, function()
			RunConsoleCommand("stopsound")
		end)
	end
	
	if shouldMute:GetInt() > 1 then
		timer.Simple(0.01, function()
			RunConsoleCommand("stopsound")
		end)
	end
end)

hook.Add("InitPostEntity", UNIQUE_ID, function()
	if shouldMute:GetInt() > 1 then
		timer.Simple(0.01, function()
			RunConsoleCommand("stopsound")
		end)
	end
end)

local function MuteAmbientSounds()
    if not shouldMute:GetBool() then return end

    if shouldMute:GetInt() < 2 then return end

    for _, ent in ipairs(ents.FindByClass("ambient_generic")) do
        local radius = ent:GetInternalVariable("radius") or 0
        local looped = ent:GetInternalVariable("spawnflags") or 0
        local sound = ent:GetInternalVariable("message") or ""

        local isGlobal = radius == 0 or radius > MAX_RADIUS
        local isLooped = bit.band(looped, 1) == 1

        if isLooped or (isGlobal and shouldMute:GetInt() == 3) then
            ent:Fire("StopSound")
        end

        local duration = SoundDuration(sound)
        local soundLower = string.lower(sound) -- string.lower result
        local ext = #sound > 3 and string.sub(soundLower, #sound - 3) or ""

        if ext == ".mp3" then
            duration = duration * 3
        end

        if (duration == 180 and isGlobal) or (duration > maxDuration:GetFloat() and isGlobal) then
            ent:Fire("StopSound")
        end
    end
end

hook.Add("Think", UNIQUE_ID .. "_MuteAmbient", function()
	if shouldMute:GetInt() > 1 then
		MuteAmbientSounds()
	end
end)