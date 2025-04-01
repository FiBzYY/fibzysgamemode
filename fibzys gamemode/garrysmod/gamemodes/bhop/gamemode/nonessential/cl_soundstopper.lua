local MUTE_ID = "bhop_mute_music"
local MAX_MUTE_RADIUS = 1250
local muteSetting = CreateClientConVar(MUTE_ID, "0", true, true, "1 = mute soundscapes; 2/3 = mute ambient_generic")
local muteDuration = CreateClientConVar(MUTE_ID .. "_duration", "7.5", true, false, "Mute if duration exceeds this in mode 2", 0)

-- Hook into EntityEmitSound
hook.Add("EntityEmitSound", MUTE_ID .. "_FilterSound", function(data)
    local mode = muteSetting:GetInt()
    if mode < 2 then return end -- Only mute in mode 2 or 3

    local soundName = string.lower(data.SoundName or "")
    local entity = data.Entity
    local radius = entity and entity:IsValid() and entity:GetInternalVariable("radius") or 0
    local duration = SoundDuration(soundName)
    local isGlobal = radius == 0 or radius > MAX_MUTE_RADIUS
    local isLooped = bit.band(entity:GetInternalVariable("spawnflags") or 0, 1) == 1
    local isLong = (duration >= 60) or (duration > muteDuration:GetFloat())

    -- .mp3s are shorter duration
    if string.sub(soundName, -4) == ".mp3" then
        duration = duration * 3
    end

    -- Mode 2: mute long + global
    if mode == 2 and isGlobal and isLong then
        return false -- blocks sound
    end

    -- Mode 3: mute global or looped sounds
    if mode == 3 and (isGlobal or isLooped) then
        return false
    end
end)