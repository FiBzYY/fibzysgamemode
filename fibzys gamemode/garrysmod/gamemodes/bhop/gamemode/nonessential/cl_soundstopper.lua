local MUTE_ID = "bhop_mute_music"
local MAX_MUTE_RADIUS = 1250 -- Higher means global sounds are muted

--[[ ~ ConVar Modes:
    0 - Allow music (mute disabled)
    1 - Mute soundscapes only (requires reconnect)
    2 - Mute soundscapes + long/global ambient_generic sounds
    3 - Mute soundscapes + all global or looped ambient_generic sounds

    Global sound: plays everywhere or radius > MAX_MUTE_RADIUS
    Long sound: duration = 60 or duration > maxMuteDuration ~
]]

local muteSetting = CreateClientConVar(MUTE_ID, "0", true, true, "1 = mute soundscapes; 2/3 = mute ambient_generic")
local muteDuration = CreateClientConVar(MUTE_ID .. "_duration", "7.5", true, false, "Mute if duration exceeds this in mode 2", 0)

local fadeTime = GetConVar("soundscape_fadetime"):GetInt()
local isMuted = muteSetting:GetBool()

local function StopAllSounds()
    RunConsoleCommand("stopsound")
    timer.Simple(fadeTime, function() RunConsoleCommand("stopsound") end)
end

cvars.AddChangeCallback(MUTE_ID, function(_, old, new)
    isMuted = new ~= "0"
    if isMuted then StopAllSounds() end
end)

hook.Add("PostCleanupMap", MUTE_ID, function()
    if not muteSetting:GetBool() then return end
    StopAllSounds()
end)

hook.Add("InitPostEntity", MUTE_ID, function()
    if muteSetting:GetInt() > 1 then StopAllSounds() end
end)

local FindByClass = ents.FindByClass
local bit_band = bit.band
local string_lower = string.lower
local string_sub = string.sub
local SoundDuration = SoundDuration

local function MuteAmbientSounds()
    if muteSetting:GetInt() < 2 then return end

    for _, ent in ipairs(FindByClass("ambient_generic")) do
        local radius = ent:GetInternalVariable("radius") or 0
        local flags = ent:GetInternalVariable("spawnflags") or 0
        local sound = ent:GetInternalVariable("message") or ""

        local isGlobal = (radius == 0 or radius > MAX_MUTE_RADIUS)
        local isLooped = (bit_band(flags, 1) == 1)

        if isLooped or (isGlobal and muteSetting:GetInt() == 3) then
            ent:Fire("StopSound")
        end

        local duration = SoundDuration(sound)
        local ext = #sound > 3 and string_sub(string_lower(sound), -4) or ""

        if ext == ".mp3" then
            duration = duration * 3
        end

        if (duration == 180 and isGlobal) or (duration > muteDuration:GetFloat() and isGlobal) then
            ent:Fire("StopSound")
        end
    end
end

hook.Add("Think", MUTE_ID .. "_MuteAmbient", function()
    if muteSetting:GetInt() > 1 then MuteAmbientSounds() end
end)