util.AddNetworkString("WRSFX_Broadcast")

local COMMANDS_TOGGLE = { "wrsfx" }
local COMMANDS_VOLUME = { "volumesfx" }

local g_sounds = {}

local function LoadSounds()
    g_sounds = file.Find("sound/wrsfx/*", "GAME")

    for i, snd in ipairs(g_sounds) do
        resource.AddFile("sound/wrsfx/" .. snd)
        util.PrecacheSound("wrsfx/" .. snd)
    end
end

function GetNextSound()
    return g_sounds[math.random(#g_sounds)] or ""
end

function WRSFX_Broadcast()
    net.Start("WRSFX_Broadcast")
    net.WriteString(GetNextSound())
    net.Broadcast()
end

Command:Register(COMMANDS_TOGGLE, function(ply, args)
    if ply:GetInfoNum("wrsfx", 0) == 0 then
        ply:ConCommand("wrsfx 1")
        Core:Send(ply, "Print", { "General", "WR sounds ON :)!" })
    else
        ply:ConCommand("wrsfx 0")
        TIMER:Send(ply, "Print", { "General", "WR sounds OFF :(!" })
    end
end)

Command:Register(COMMANDS_VOLUME, function(ply, args)
    local volume = #args == 1 and tonumber(args[1]) or nil

    if not volume or volume < 1 then
        Core:Send(ply, "Print", { "Timer", "Usage: !" .. COMMANDS_VOLUME[1] .. " 1-5" })
        return
    end

    volume = math.Clamp(math.Round(volume), 1, 5)
    ply:ConCommand("wrsfx_volume " .. tostring(volume / 5))
    TIMER:Send(ply, "Print", { "Timer", "WR sound volume set to " .. volume })
end)

LoadSounds()