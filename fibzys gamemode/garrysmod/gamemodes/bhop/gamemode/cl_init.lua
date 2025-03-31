local function includeFiles(fileList)
    for _, file in ipairs(fileList) do
        include(file)
    end
end

local files = {
    shared = {
        "essential/sh_config.lua",
        "shared.lua",
        "sh_playerclass.lua",
        "essential/sh_movement.lua",
        "essential/sh_network.lua",
        "essential/sh_utilities.lua",
        "essential/timer/sh_timer.lua",
        "nonessential/sh_multi_hops.lua",
        "nonessential/sh_paint.lua",
        "nonessential/sh_ssjtop.lua",
        "nonessential/sh_jumpstats.lua",
        "nonessential/sh_fjt.lua",
        "nonessential/sh_edgehelper.lua",
        "nonessential/sh_rampometer.lua",
        "nonessential/sh_unreal.lua"
    },
    movementFixes = {
        "nonessential/movementfixes/sh_rngfix.lua",
        "nonessential/movementfixes/sh_rampfix.lua",
        "nonessential/movementfixes/sh_boosterfix.lua",
        "nonessential/movementfixes/sh_headbugfix.lua"
    },
    ui = {
        "userinterface/cl_fonts.lua",
        "userinterface/cl_theme.lua",
        "userinterface/cl_ui.lua",
        "userinterface/cl_hud.lua",
        "userinterface/cl_settings.lua",
        "userinterface/cl_themes.lua",
        "userinterface/cl_uiutilize.lua",
        "userinterface/cl_menu.lua",
        "userinterface/numbered/ui_mapvote.lua",
        "essential/cl_network.lua",
        "userinterface/scoreboards/cl_default.lua",
        "userinterface/chatbox/cl_chatbox.lua",
        "userinterface/cl_voice.lua",
        "userinterface/cl_mapcolor.lua",
        "userinterface/cl_netgraph.lua"
    },
    clientModules = {
        "nonessential/admin/cl_admin.lua",
        "essential/zones/cl_zoneeditor.lua",
        "nonessential/strafe/cl_trainer.lua",
        "nonessential/strafe/cl_strafehud.lua",
        "nonessential/strafe/cl_showkeys.lua",
        "nonessential/strafe/cl_showspeed.lua",
        "nonessential/strafe/cl_synchronizer.lua",
        "nonessential/cl_soundstopper.lua",
        "nonessential/cl_cheats.lua",
        "nonessential/bash/cl_bash.lua"
    },
    fpsFixes = {
        "nonessential/fpsfixes/sh_fpsfixes.lua",
        "nonessential/fpsfixes/cl_fpsfixes.lua",
        "nonessential/fpsfixes/cl_buffthefps.lua"
    },
    showHidden = {
         "nonessential/showhidden/sh_init.lua",
         "nonessential/showhidden/luabsp.lua",
         "nonessential/showhidden/cl_init.lua",
         "nonessential/showhidden/cl_lang.lua"
    },
    misc = {
        "nonessential/misc/cl_centerbox.lua",
        "nonessential/misc/cl_perfprinter.lua",
        "nonessential/misc/cl_peakheight.lua",
        "nonessential/misc/cl_boxgraph.lua",
        "nonessential/misc/cl_jumppred.lua"
    }
}

includeFiles(files.shared)
includeFiles(files.movementFixes)
includeFiles(files.ui)
includeFiles(files.clientModules)
includeFiles(files.fpsFixes)
includeFiles(files.showHidden)
includeFiles(files.misc)

--- end of include
local setting_anticheats = CreateClientConVar("bhop_anticheats", "0", true, false)
local setting_gunsounds = CreateClientConVar("bhop_gunsounds", "1", true, false, "Toggle Gun Sounds", 0, 1)
local setting_hints = CreateClientConVar("bhop_hints", "5", true, false)
local customFOV = CreateClientConVar("bhop_set_fov", "90", true, true, "Set custom FOV", 1, 180)
local sounds_enabled = CreateClientConVar("bhop_wrsfx", "1", true, true, "WR sounds enabled state", 0, 1)
local sounds_volume = CreateClientConVar("bhop_wrsfx_volume", "0.4", true, false, "WR sounds volume", 0, 1)
local sounds_enabledbad = CreateClientConVar("bhop_wrsfx_bad", "1", true, false, "Bad improvement sounds", 0, 1)
local chat_sounds = CreateClientConVar("bhop_chatsounds", "0", true, false, "Play chat sounds", 0, 1)
local zone_sounds = CreateClientConVar("bhop_zonesounds", "1", true, false, "Play sound on zone left", 0, 1)
local bhop_showplayers = CreateClientConVar("bhop_showplayerslabel", "1", true, false, "Show or hide player names when looking at them")
local bhop_wepspammer = CreateClientConVar("bhop_autoshoot", "1", true, false, "Enable or disable weapon auto shoot")
local bhop_joindetails = CreateClientConVar("bhop_joindetails", "1", true, false, "Show or disable join details")

-- Cvars
CreateClientConVar("bhop_simpletextures", 0, true, false, "Toggle simple solid textures", 0, 1)
CreateClientConVar("bhop_sourcesensitivity", 0, true, false, "Toggle sensitivity adjustment")
CreateClientConVar("bhop_absolutemousesens", 0, true, false, "Toggle absolute mouse sensitivity adjustment")
CreateClientConVar("bhop_showchatbox", "1", true, false, "Toggle chatbox visibility: 1 for show, 0 for hide", 0, 1)
CreateClientConVar("bhop_nogun", "0", true, false, "Enable or disable no-gun mode")
CreateClientConVar("bhop_nosway", "1", true, false, "Enable or disable gun sway mode")
CreateClientConVar("bhop_showplayers", 1, true, false, "Shows bhop players", 0, 1)
CreateClientConVar("bhop_viewtransfrom", 0, true, false, "Shows transfrom view type", 0, 1)
CreateClientConVar("bhop_thirdperson", 0, true, false, "Shows third person view type", 0, 1)
CreateClientConVar("bhop_viewpunch", "1", true, false, "Enable or disable view punch effect")
CreateClientConVar("bhop_weaponpickup", "1", true, false, "Enable or disable weapon pickup for yourself.")
CreateClientConVar("bhop_viewinterp", "0", true, false, "Enable or disable view interpolation.")
CreateClientConVar("bhop_water_toggle", "0", true, false, "Enable or disable water reflections.")

-- So we dont need to keep calling hook.add ect...
local lp, Iv, ct, Vector, hook_Add = LocalPlayer, IsValid, CurTime, Vector, hook.Add
local abs, mc, DrawText, ts = math.abs, math.Clamp, draw.SimpleText, TEAM_SPECTATOR

-- Hulls client sided
local function AdjustClientPlayerOffsets(ply)
    if not IsValid(ply) then return end
    ply:SetHull(Vector(-16, -16, 0), Vector(16, 16, BHOP.Move.EyeView))
    ply:SetHullDuck(Vector(-16, -16, 0), Vector(16, 16, BHOP.Move.EyeDuck))
    ply:SetViewOffset(Vector(0, 0, BHOP.Move.OffsetView))
    ply:SetViewOffsetDucked(Vector(0, 0, BHOP.Move.OffsetDuck))
end

local function InitializeOffsets()
    local ply = LocalPlayer()
    if IsValid(ply) then
        AdjustClientPlayerOffsets(ply)
    end
end
hook_Add("InitPostEntity", "AdjustClientPlayerOffsets", InitializeOffsets)

hook_Add("OnEntityCreated", "AdjustPlayerOffsetsOnChange", function(ent)
    if ent == LocalPlayer() then
        timer.Simple(0, InitializeOffsets)
    end
end)
timer.Create("CheckPlayerOffsets", 1, 0, InitializeOffsets)

-- Hint Messages
local timerColor = UTIL.Colour["Timer"]
local hints = {
    { color_white, "You can toggle the menu with !menu and F1" },
    { color_white, "You can toggle anti-cheat visibility with ", timerColor, "!anticheats" },
    { color_white, "You can edit the style of your HUD with ", timerColor, "!theme" },
    { color_white, "You can edit the delay between these hints with ", timerColor, "bhop_hints <delay>", color_white, " in your console. 0 will stop hints completely." },
    { color_white, "Report bugs or issues using !discord to stay updated with the community." },
    { color_white, "Struggling on the map? Check out easier styles with ", timerColor, "!styles." },
    { color_white, "Low FPS? Try the x64 beta version of Garry's Mod with ", timerColor, "gmod_mcore_test 1", color_white, " for better performance." },
    { color_white, "Support the server and get Lifetime VIP for $10! Use !donate for details (Custom model/name/chat/tag)." },
    { color_white, "Want a cleaner screen? Hide other players with ", timerColor, "!hide." },
    { color_white, "Don't forget to join our community on Discord! Type ", timerColor, "!discord", color_white, " to get the link." }
}

local hintIndex = 1
local totalHints = #hints

local function ShowNextHint()
    if setting_hints:GetInt() == 0 then return end

    UTIL:AddMessage("Hint", unpack(hints[hintIndex]))
    hintIndex = (hintIndex % totalHints) + 1
end

local function UpdateHintTimer()
    local hintDelay = setting_hints:GetInt() * 60
    
    if hintDelay > 0 then
        if not timer.Exists("HintTimer") then
            timer.Create("HintTimer", hintDelay, 0, ShowNextHint)
        else
            timer.Adjust("HintTimer", hintDelay)
        end
    else
        timer.Remove("HintTimer")
    end
end

cvars.AddChangeCallback("bhop_hints", function()
    UpdateHintTimer()
end)

hook_Add("InitPostEntity", "AutoStartHintTimer", function()
    UpdateHintTimer()
end)

net.Receive("SendConnectionCount", function()
    if bhop_joindetails:GetBool() then
        local nick = net.ReadString()
        local connectionCount = net.ReadInt(32)
        UTIL:AddMessage("Server", nick .. " has connected " .. connectionCount .. " times!")
    end
end)

local function JoinDetails()
    if bhop_joindetails:GetBool() then
        local currentMonth = os.date("%b")

        if currentMonth == "Oct" then
            UTIL:AddMessage("Server", "Happy Halloween from fibzy!")
        end

        UTIL:AddMessage("Server", "Gamemode loaded (" .. BHOP.Version.GM .. ").")
    end
end
hook_Add("InitPostEntity", "JoinDetails", JoinDetails)

-- Apply settings dynamically
local function ApplySettings()
    RunConsoleCommand("hud_saytext_time", GetConVar("bhop_showchatbox"):GetBool() and "12" or "0")
end
cvars.AddChangeCallback("bhop_showchatbox", ApplySettings)

-- Chatbox visibility
local function UpdateChatboxVisibility()
    local showChatbox = not GetConVar("bhop_showchatbox"):GetBool()

    if not showChatbox then
        RunConsoleCommand("hud_saytext_time", "12")

        timer.Simple(0.1, function()
            UTIL:AddMessage("Settings", "Chatbox is now visible!")
        end)
    else
        RunConsoleCommand("hud_saytext_time", "0")
        UTIL:AddMessage("Settings", "Chatbox is now hidden!")
    end
end

cvars.AddChangeCallback("bhop_showchatbox", UpdateChatboxVisibility)
hook.Add("PlayerInitialSpawn", "SetChatboxVisibility", UpdateChatboxVisibility)

-- Discord
net.Receive("OpenDiscordLink", function()
    gui.OpenURL(BHOP.DicordLink)
end)

-- Interp switcher with easy toggling
concommand.Add("bhop_interp", function()
    local currentInterp = math.Round(GetConVar("cl_interp"):GetFloat(), 3)
    local newInterp = currentInterp == 0.01 and "0.05" or "0.01"

    RunConsoleCommand("cl_interp", newInterp)
    UTIL:AddMessage("Settings", "Switched to cl_interp " .. newInterp .. (newInterp == "0.05" and " for smoother visuals." or " for better input responsiveness."))
end)

-- Base FOV ConVar reference
local baseFOVConVar = GetConVar("bhop_set_fov")

function GM:AdjustMouseSensitivity(fDefault)
    local ply = LocalPlayer()
    if not IsValid(ply) then return fDefault end

    local baseFOV = 75
    local currentFOV = ply:GetFOV()

    return GetConVar("bhop_sourcesensitivity"):GetBool() and 0.96875 or fDefault
end

local view = {}
local cameraDistance = 7
local thirdPersonDist = 100

local view = {}
local CalcTab = { origin = Vector(0, 0, 0), last = 1 }
local DuckDiff = 16

-- Main View change
function GM:CalcView(ply, origin, angles, fov)
    local viewTransform = GetConVar("bhop_viewtransfrom"):GetBool()
    local thirdPerson = GetConVar("bhop_thirdperson"):GetBool()
    local viewPunch = GetConVar("bhop_viewpunch"):GetBool()
    local ViewInterp = GetConVar("bhop_viewinterp"):GetBool()

    if not ply:Alive() then
        angles.r = 0
        view.origin = origin
        view.angles = angles
        view.fov = fov
        return view
    end

    if not viewPunch then
        angles.r = 0
    end

    local offsetVector = Vector(-cameraDistance, 0, 0)
    offsetVector:Rotate(angles)

    -- View Interpolation
    if not ply:IsOnGround() and ViewInterp then
        local frameTime = FrameTime()
        local estimatedZ = CalcTab.origin.z + ply:GetVelocity().z * frameTime
        local posDiff = math.abs(origin.z - estimatedZ)

        if posDiff - CalcTab.last > DuckDiff and posDiff - CalcTab.last < DuckDiff * 2 then
            origin.z = estimatedZ
            posDiff = 0
        end

        CalcTab.last = posDiff
    end

    CalcTab.origin = origin
    CalcTab.angles = angles
    CalcTab.fov = fov

    if thirdPerson then
        local trace = util.TraceHull({
            start = origin,
            endpos = origin - angles:Forward() * thirdPersonDist,
            mins = Vector(-10, -10, -10),
            maxs = Vector(10, 10, 10),
            filter = ply
        })

        view.origin = trace.HitPos + trace.HitNormal * 5
        view.angles = angles
        view.fov = fov
        view.drawviewer = true
    elseif viewTransform then
        view.origin = origin + offsetVector
        view.angles = angles
        view.fov = fov
        view.drawviewer = false
    else
        view.origin = origin
        view.angles = angles
        view.fov = fov
        view.drawviewer = false
    end

    return view
end

concommand.Add("bhop_togglethirdperson", function(ply)
    local cvar = GetConVar("bhop_thirdperson")
    cvar:SetBool(not cvar:GetBool())
end)

concommand.Add("bhop_togglematrix", function(ply)
    local cvar = GetConVar("bhop_viewtransfrom")
    cvar:SetBool(not cvar:GetBool())
end)

-- Networked FoV Changer
net.Receive("SyncFOV", function()
    LocalPlayer():SetFOV(net.ReadInt(32), 0.2)
end)

-- Adjust FOV when switching weapons
hook_Add("PlayerSwitchWeapon", "CustomFOVSwitchWeapon", function(ply)
    if IsValid(ply) and ply:IsPlayer() then
        ply:SetFOV(GetConVar("bhop_set_fov"):GetInt(), 104)
    end
end)

-- Sync FOV with the server
local function SyncCustomFOVWithServer()
    net.Start("SyncFOV")
    net.WriteInt(GetConVar("bhop_set_fov"):GetInt(), 32)
    net.SendToServer()
end

-- Auto-sync on FOV change
cvars.AddChangeCallback("bhop_set_fov", function()
    SyncCustomFOVWithServer()
end)

-- Sync FOV on player join
hook_Add("InitPostEntity", "SendFOVStateOnJoin", SyncCustomFOVWithServer)

-- Hide local player model
hook_Add("ShouldDrawLocalPlayer", "HideLocalPlayerModel", function()
    return false
end)

-- Suppress join/leave chat messages
hook_Add("ChatText", "SuppressMessages", function(_, _, _, szID)
    return szID == "joinleave"
end)

-- Full chat control
function GM:OnPlayerChat(ply, szText, bTeam, bDead)
    local tab = {}

    if Iv(ply) and ply:IsPlayer() then
        local nAccess = ply:GetNWInt("AccessIcon", 0)
        local RANK = TIMER:GetRank(ply)
        local STYLE = TIMER:GetStyle(ply)

        if ply:SteamID() == "STEAM_0:1:48688711" then -- fibzy
            local fadeText = TIMER:RedToBlackFade(TIMER.UniqueRanks[1][1])
            for _, v in ipairs(fadeText) do
                tab[#tab + 1] = v
            end

            tab[#tab + 1] = color_white
            tab[#tab + 1] = " | "

            local rankID = ply:GetNWInt("Rank", -1)
            local rankData = TIMER.Ranks[rankID]
            if rankData then
                tab[#tab + 1] = rankData[2] -- Rank Color
                tab[#tab + 1] = rankData[1] -- Rank Text
            end

            tab[#tab + 1] = color_white
            tab[#tab + 1] = " | "

            local r = TIMER:Rainbow("FiBzY")
            for _, v in pairs(r) do
                tab[#tab + 1] = v
            end
        else
            local rankID = ply:GetNWInt("Rank", -1)
            local rankData = TIMER.Ranks[rankID]
            if rankData then
                tab[#tab + 1] = rankData[2] -- Rank Color
                tab[#tab + 1] = rankData[1] -- Rank Text
            end

            tab[#tab + 1] = color_white
            tab[#tab + 1] = " | "
            tab[#tab + 1] = DynamicColors.PanelColor -- Color(98, 176, 255)
            tab[#tab + 1] = ply:Name()
        end
    else
        tab[#tab + 1] = "Console"
    end

    tab[#tab + 1] = color_white
    tab[#tab + 1] = ": "
    tab[#tab + 1] = szText

    chat.AddText(unpack(tab))

    if chat_sounds:GetBool() then
       surface.PlaySound("common/talk.wav")
    end

    return true
end

-- Play Zone sound
net.Receive("ZoneExitSound", function()
    if zone_sounds:GetBool() then
        surface.PlaySound("timer/start.mp3")
    end
end)

local function SetEntityVisibility(classNames, shouldDraw)
    for _, className in ipairs(classNames) do
        for _, ent in ipairs(ents.FindByClass(className)) do
            ent:SetNoDraw(not shouldDraw)
        end
    end
end

-- Handle ConVar change for visibility
local function VisibilityCallback(_, _, newValue)
    local shouldDraw = tonumber(newValue) == 1
    SetEntityVisibility({ "env_spritetrail", "beam" }, shouldDraw)
end
cvars.AddChangeCallback("bhop_showplayers", VisibilityCallback)

-- Toggle show players ConVar
concommand.Add("bhop_showplayers_toggle", function()
    local cvar = GetConVar("bhop_showplayers")
    if cvar then
        RunConsoleCommand("bhop_showplayers", cvar:GetInt() == 0 and "1" or "0")
    end
end)

net.Receive("bhop_set_showplayers", function()
    local shouldShow = net.ReadBool()
    RunConsoleCommand("bhop_showplayers", shouldShow and "1" or "0")
end)

-- Hide players based on ConVar
hook_Add("PrePlayerDraw", "PlayerVisibilityCheck", function(ply)
    local showPlayers = GetConVar("bhop_showplayers"):GetInt()
    local thirdPerson = GetConVar("bhop_thirdperson"):GetInt()

    if thirdPerson == 1 or showPlayers == 1 then
        return
    end

    return true
end)

concommand.Add("bhop_watertoggle", function()
    local toggle = GetConVar("bhop_water_toggle"):GetInt() == 0 and 1 or 0
    RunConsoleCommand("bhop_water_toggle", toggle)

    RunConsoleCommand("r_waterdrawrefraction", toggle)
    RunConsoleCommand("r_waterdrawreflection", toggle)
end)

cvars.AddChangeCallback("bhop_water_toggle", function(_, _, newValue)
    local value = tonumber(newValue)
    RunConsoleCommand("r_waterdrawrefraction", value)
    RunConsoleCommand("r_waterdrawreflection", value)
end)

net.Receive("bhop_set_water_toggle", function()
    local cvar = GetConVar("bhop_water_toggle")
    local current = cvar:GetInt()
    local new = current == 0 and 1 or 0

    RunConsoleCommand("bhop_water_toggle", tostring(new))

    RunConsoleCommand("r_waterdrawrefraction", new)
    RunConsoleCommand("r_waterdrawreflection", new)

    if new == 1 then
        UTIL:AddMessage("Settings", "Enabled Water reflections/refractions.")
    else
        UTIL:AddMessage("Settings", "Disabled Water reflections/refractions.")
    end
end)

-- Optimize on client boot
function GM:Initialize()
    if BHDATA and BHDATA.Optimize then
        BHDATA:Optimize()
    end
end

-- Remove dirty hooks efficiently
function GM:InitPostEntity()
    hook.Remove("PostDrawOpaqueRenderables", "PlayerMarkers")
    hook.Remove("PlayerTick", "TickWidgets")
end

-- Toggle Anticheats
concommand.Add("_toggleanticheats", function()
    local acs = GetConVar("bhop_anticheats")
    acs:SetInt(acs:GetInt() == 1 and 0 or 1)
end)

function GM:EntityEmitSound(data)
    if GetConVar("bhop_gunsounds"):GetInt() == 0 then
        local snd = string.lower(data.OriginalSoundName or "")

        if string.find(snd, "wrsfx/") or string.find(snd, "timer/") then
            return
        end

        if string.find(snd, "footstep") or 
           string.find(snd, "step") or 
           string.find(snd, "run") or 
           string.find(snd, "walk") then
            return
        end

        return false
    end
end

-- Toggle Gun Sounds
concommand.Add("_togglegunsounds", function()
    local gunshots = GetConVar("bhop_gunsounds")
    if not gunshots then return end

    gunshots:SetInt(gunshots:GetInt() == 1 and 0 or 1)
end)

-- Flip Weapons
local fp = CreateClientConVar("bhop_flipweapons", 0, true, false, "Flips weapon view models.", 0, 1)

cvars.AddChangeCallback("bhop_flipweapons", function(_, _, new)
    local bool = new == "1"
    local ply = LocalPlayer()
    if IsValid(ply) then
        for _, wep in pairs(ply:GetWeapons()) do
            if IsValid(wep) then
                wep.ViewModelFlip = not bool
            end
        end
    end
end)

hook_Add("HUDWeaponPickedUp", "flipweps", function(wep)
    wep.ViewModelFlip = not fp:GetBool()
end)

local function SendWeaponPickupState()
    local pickupState = GetConVar("bhop_weaponpickup"):GetBool()
    net.Start("ToggleWeaponPickup")
    net.WriteBool(pickupState)
    net.SendToServer()
end

cvars.AddChangeCallback("bhop_weaponpickup", function(_, _, new)
    SendWeaponPickupState()
end, "bhop_weppickup_callback")

concommand.Add("bhop_toggle_weppickup", function()
    local currentState = GetConVar("bhop_weaponpickup"):GetBool()
    RunConsoleCommand("bhop_weaponpickup", currentState and "0" or "1")
end)

function GM:CalcViewModelView(weapon, viewmodel, op, oa, p, a)
    local sway = GetConVar("bhop_nosway"):GetBool()
    local noGun = GetConVar("bhop_nogun"):GetBool()
    local viewTransform = GetConVar("bhop_viewtransfrom"):GetBool()

    if not sway then
        return op, oa
    end

    if noGun and IsValid(weapon) then
        return Vector(-5000, -5000, -5000), a
    end

    local newPos, newAng = p, a

    if viewTransform then
        local offsetVector = Vector(-cameraDistance, 0, 0)
        offsetVector:Rotate(a)
        newPos = newPos + offsetVector
    end

    newAng.r = 0

    return newPos, newAng
end

local oldbts = {}
hook.Add("StartCommand", "WepSpamer", function(ply, cmd)
    if not bhop_wepspammer:GetBool() then return end

    if not IsValid(ply) or not ply:Alive() or ply:Team() == TEAM_SPECTATOR then return end

    local buttons = cmd:GetButtons()
    oldbts[ply] = oldbts[ply] or 0

    if bit.band(oldbts[ply], IN_ATTACK) ~= 0 and bit.band(buttons, IN_ATTACK) ~= 0 then
        cmd:RemoveKey(IN_ATTACK)
    end

    oldbts[ply] = cmd:GetButtons()
end)

-- Map Colors and Brightness
CreateConVar("bhop_enable_map_colors", "0", FCVAR_ARCHIVE, "Enable or disable map color overwrites")
local colorSettings = {
    ["$pp_colour_addr"] = 0,
    ["$pp_colour_addg"] = 0,
    ["$pp_colour_addb"] = 0,
    ["$pp_colour_brightness"] = 0,
    ["$pp_colour_contrast"] = 1,
    ["$pp_colour_colour"] = 1.2,
    ["$pp_colour_mulr"] = 0,
    ["$pp_colour_mulg"] = 0,
    ["$pp_colour_mulb"] = 0
}

concommand.Add("bhop_map_brightness", function(_, _, args)
    colorSettings["$pp_colour_contrast"] = tonumber(args[1]) or 1
end)

hook_Add("RenderScreenspaceEffects", "MapBrightness", function()
    if colorSettings["$pp_colour_contrast"] ~= 1 then
        DrawColorModify(colorSettings)
    end
end)

hook_Add("PostProcessPermitted", "DisablePostProcessing", function()
    return false
end)

-- LJ Stats --
local drawLJ = false
local dist = 0
local syncs = {}
local speed = {}
local sync = 0
local jumptype = ""

local bgColor = Color(42, 42, 42, 255)
local textColor = Color(255, 255, 255, 255)
local headerColor = Color(32, 32, 32, 255)
local lineColor = Color(255, 255, 255, 255)

net.Receive("LJStats", function()
    timer.Remove("LJStatsHide")
    jumptype = net.ReadString()
    dist = net.ReadInt(16)
    syncs = net.ReadTable()
    speed = net.ReadTable()
    sync = net.ReadInt(16) / 100
    drawLJ = true

    timer.Create("LJStatsHide", 5, 1, function()
        drawLJ = false
    end)
end)

hook.Add("HUDPaintBackground", "DrawStats", function()
    if drawLJ then
        surface.SetFont("HUDFont")
        local nw, _ = surface.GetTextSize(" Strafe   Speed   Sync ")
        nw = nw + 30
        local h = (20 * #syncs) + 90

        local x = 30
        local y = ScrH() / 2 - h / 2

        draw.RoundedBox(0, x, y, nw, h, bgColor)

        draw.RoundedBoxEx(0, x, y, nw, 30, headerColor, true, true, false, false)
        draw.SimpleText("[" .. jumptype .. "] " .. dist .. " units", "HUDFont", x + 10, y + 5, textColor, 0, 0)
        draw.SimpleText("Sync: " .. sync .. "%", "HUDFont", x + 10, y + 30, textColor, 0, 0)

        surface.SetDrawColor(lineColor)
        surface.DrawRect(x, y + 55, nw, 2)

        draw.SimpleText("Strafe   Speed   Sync", "HUDFont", x + 10, y + 60, textColor, 0, 0)

        for k, v in ipairs(syncs) do
            local rowY = y + 60 + k * 20
            draw.SimpleText(string.format("%2d           %3d        %d%%", k, speed[k], v), "HUDFont", x + 10, rowY, textColor, 0, 0)
        end
    end
end)

-- Client WR sounds
net.Receive("WRSounds", function(len)
    if not sounds_enabled:GetBool() then return end
    local soundPath = "wrsfx/" .. net.ReadString()

    lp():EmitSound(soundPath, 75, 100, sounds_volume:GetFloat())
end)

-- Bad improvement
net.Receive("BadImprovement", function()
    if not sounds_enabledbad:GetBool() then return end

    if BHOP.ExcludeWRSounds and #BHOP.ExcludeWRSounds > 0 then
        local soundPath = BHOP.ExcludeWRSounds[math.random(1, #BHOP.ExcludeWRSounds)]
        lp():EmitSound(soundPath, 75, 100)
    end
end)

--[[ -- Replay Trail
local trailConfig = {
    ["blue"] = CreateClientConVar("sl_trail_blue", "1", true, false, "Set trail color to blue when faster than trail speed.", 0, 1),
    ["range"] = CreateClientConVar("sl_trail_range", "500", true, false, "Increase trail visibility range.", 0, 1),
    ["ground"] = CreateClientConVar("sl_trail_ground", "0", true, false, "Show trails only when on the ground.", 0, 1),
    ["vague"] = CreateClientConVar("sl_trail_vague", "0", true, false, "Make trails more transparent.", 0, 1),
    ["label"] = CreateClientConVar("sl_trail_label", "0", true, false, "Hide trail labels.", 0, 1),
    ["hud"] = CreateClientConVar("sl_trail_hud", "0", true, false, "Hide trail HUD.", 0, 1)
}

local function UpdateSettings()
    for _, ent in ipairs(ents.FindByClass("game_point")) do
        ent:LoadConfig()
    end
end

for _, cvar in pairs(trailConfig) do
    cvars.AddChangeCallback(cvar:GetName(), function()
        UpdateSettings()
    end)
end

function GetTrailConfig(name)
    return trailConfig[name]:GetBool()
end]]--

-- Show Player labels
local Markers = Markers or {}
local function ValidLP()
    local ply = LocalPlayer()
    return IsValid(ply) and ply or nil
end

function SetPlayerMarkers(list)
    Markers = {}
    if list then
        for _, id in ipairs(list) do
            local ply = Entity(id)
            if IsValid(ply) then
                Markers[ply] = true
            end
        end
    end
end

local function DrawTargetIDs()
    if not Markers then return end
    if not bhop_showplayers:GetBool() then return end

    local lpc = lp()
    if not Iv(lpc) then return end

    if not Players or ct() - LastCheck > 2 then
        Players = player.GetAll()
        LastCheck = ct()
    end

    local pos = lpc:GetPos()

    for i = #Players, 1, -1 do
        local ply = Players[i]

        if not Iv(ply) or not ply:Alive() then
            table.remove(Players, i)
            continue
        end

        if ply == lpc then continue end

        local ppos = ply:GetPos()
        local diff = (ppos - pos):Length()

        if diff < 1000 then
            local alpha = math.Clamp(255 - (diff / 1000) * 255, 50, 255)
            local pos2d = Vector(ppos.x, ppos.y, ppos.z + 70):ToScreen()

            if pos2d.visible then
                local label = ply:IsBot() and "" or "Player: " .. ply:Name()
                draw.SimpleText(label, "HUDTimerMedThick", pos2d.x, pos2d.y, 
                    Color(DynamicColors.PanelColor.r, DynamicColors.PanelColor.g, DynamicColors.PanelColor.b, alpha), 
                    TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end

        if Markers[ply] then
            local pos2d = Vector(ppos.x, ppos.y, ppos.z + 100):ToScreen()
            if pos2d.visible then
                surface.SetDrawColor(DynamicColors.PanelColor.r, DynamicColors.PanelColor.g, DynamicColors.PanelColor.b, 255)
                surface.DrawTexturedRect(pos2d.x - 8, pos2d.y, 16, 16)
            end
        end
    end
end
hook.Add("HUDPaint", "TargetIDDraw", DrawTargetIDs)

local abb = 0

local function IsPlayerCfgBanned(steamID)
    return BHOP.Banlist[steamID] or false
end

hook.Add("HUDPaint", "byeuser", function()
    local lp = LocalPlayer()
    if not IsValid(lp) then return end

    local steamID = lp:SteamID()
    local banData = IsPlayerCfgBanned(steamID)

    if banData then
        abb = abb + 1
        local randomColor = DynamicColors.PanelColor

        -- Spam sound
        local sounds = {
            "buttons/button10.wav",
            "vo/npc/male01/hacks01.wav",
            "vo/npc/male01/no01.wav",
            "vo/npc/Barney/ba_ohshit03.wav",
            "ambient/alarms/klaxon1.wav"
        }

        if abb % 10 == 0 then
            local sfx = sounds[math.random(#sounds)]
            surface.PlaySound(sfx)
        end

        for i = 0, abb do
            draw.SimpleText("haha nice try!", "ui.mainmenu.title2", math.random(0, ScrW()), math.random(0, ScrH()), randomColor)
        end
    end
end)