local function includeFiles(fileList, serverOnly)
    for _, file in ipairs(fileList) do
        if SERVER then
            AddCSLuaFile(file)
        end
        if not serverOnly or SERVER then
            include(file)
        end
    end
end

local coreFiles = {
    "essential/sh_config.lua",
    "shared.lua",
    "essential/sh_movement.lua",
    "essential/sh_network.lua",
    "essential/sh_utilities.lua"
}

includeFiles(coreFiles)

local files = {
    shared = {
        "essential/timer/sh_timer.lua",
        "nonessential/sh_multi_hops.lua",
        -- "nonessential/vip/sh_paint.lua",
        "nonessential/sh_jumpstats.lua",
        -- "nonessential/sh_edgehelper.lua",
        -- "nonessential/sh_rampometer.lua",
        "nonessential/sh_unreal.lua",
        "nonessential/sh_stamina.lua"
    },
    movementFixes = {
        "nonessential/movementfixes/sh_rngfix.lua",
        -- "nonessential/movementfixes/sh_rampfix.lua",
        -- "nonessential/movementfixes/sh_boosterfix.lua",
        -- "nonessential/movementfixes/sh_headbugfix.lua",
        -- "nonessential/movementfixes/sh_eventqueuefix.lua"
    },
    clientModules = {
        "userinterface/cl_fonts.lua",
        "userinterface/cl_settings.lua",
        "userinterface/cl_themes.lua",
        "userinterface/cl_ui.lua",
        "userinterface/cl_hud.lua",
        "userinterface/cl_uiutilize.lua",
        "userinterface/cl_menu.lua",
        "essential/cl_network.lua",
        "userinterface/scoreboards/cl_default.lua",
        "userinterface/chatbox/cl_chatbox.lua",
        "essential/zones/cl_zoneeditor.lua",
        "nonessential/admin/cl_admin.lua",
        "nonessential/strafe/cl_strafehud.lua",
        "nonessential/strafe/cl_trainer.lua",
        "nonessential/strafe/cl_showkeys.lua",
        "nonessential/strafe/cl_showspeed.lua",
        "nonessential/strafe/cl_synchronizer.lua",
        -- "nonessential/cl_cheats.lua",
        -- "nonessential/cl_voice.lua",
        -- "nonessential/cl_mapcolor.lua",
        -- "nonessential/cl_netgraph.lua",
        "nonessential/fpsfixes/cl_fpsfixes.lua",
        "nonessential/fpsfixes/cl_buffthefps.lua",
        -- "nonessential/showhidden/cl_init.lua",
        -- "nonessential/showhidden/cl_lang.lua",
        -- "nonessential/bash/cl_bash.lua",
        -- "nonessential/bash/cl_menu.lua"
    },
    fpsFixesShared = {
        "nonessential/fpsfixes/sh_fpsfixes.lua",
    },
    showHiddenShared = {
        -- "nonessential/showhidden/sh_init.lua",
        -- "nonessential/showhidden/luabsp.lua"
    },
    serverOnly = {
        "essential/sv_chat.lua",
        "essential/sv_database.lua",
        "sv_playerclass.lua",
        "sv_command.lua",
        "essential/timer/sv_timer.lua",
        "essential/zones/sv_zones.lua",
        "nonessential/sv_rtv.lua",
        "nonessential/admin/sv_admin.lua",
        "nonessential/admin/sv_whitelist.lua",
        "nonessential/sv_replay.lua",
        "nonessential/sv_spectator.lua",
        "nonessential/sv_sync.lua",
        "nonessential/sv_ljstats.lua",
        "nonessential/sv_checkpoint.lua",
        "nonessential/sv_segment.lua",
        "nonessential/sv_setspawn.lua",
        -- "nonessential/showhidden/sv_init.lua",
        -- "nonessential/showhidden/sh_init.lua",
        "nonessential/movementfixes/sh_tpfix.lua"
        -- "nonessential/bash/sv_bash.lua",
        -- "nonessential/bash/sv_config.lua"
    },
    misc = {
        "nonessential/misc/cl_centerbox.lua",
        "nonessential/misc/cl_perfprinter.lua",
        "nonessential/misc/cl_peakheight.lua",
        "nonessential/misc/cl_boxgraph.lua"
    }
}

includeFiles(files.shared)
includeFiles(files.movementFixes)
includeFiles(files.fpsFixesShared)
-- includeFiles(files.showHiddenShared)

if SERVER then
    for _, file in ipairs(files.clientModules) do
        AddCSLuaFile(file)
    end
    for _, file in ipairs(files.misc) do
        -- AddCSLuaFile(file)
    end
end

if CLIENT then
    includeFiles(files.clientModules)
    -- includeFiles(files.misc)
end

if SERVER then
    includeFiles(files.serverOnly, true)
end

util.AddNetworkString("MovementData")

-- Cvars
CreateConVar("bhop_version", tostring(BHOP.Version.GM), {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Version number")
CreateConVar("bhop_prediction", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Prediction enabled")
CreateConVar("bhop_remove_dustmotes", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Toggle remove func_dustmotes")

local nextNameChange = 0
local IsWhitelisted = true

local hook_Add = hook.Add
local lp = LocalPlayer
local Iv = IsValid
local ct = CurTime

-- Host name updater
local function ChangeName()
    if not BHOP.EnableCycle then
        return
    end

    local whitelistText = IsWhitelisted and "- whitelist" or ""
    local name = table.Random(BHOP.ServerNames)
    local new_hostname = BHOP.ServerName .. " " .. whitelistText .. " | " .. name

    game.ConsoleCommand("hostname \"" .. new_hostname .. "\"\n")

    SetGlobalString("ServerName", new_hostname)
end

hook_Add("Initialize", "BHOP_RandomNameOnLoad", function()
    if BHOP.EnableCycle then
        ChangeName()
    end
end)

timer.Create("HostnameThink", 30, 0, function()
    if BHOP.EnableCycle then
        ChangeName()
    end
end)

local timerName = "MapReloadTimer"
local interval = 4 * 60 * 60

-- Reload map for long hours
local function ReloadMap()
    local currentMap = game.GetMap()
    RunConsoleCommand("changelevel", currentMap)
end
timer.Create(timerName, interval, 0, ReloadMap)

hook_Add("Initialize", "PrintBhopVersion", function()
    UTIL:Notify(Color(255, 0, 255), "Gamemode", "Bhop Gamemode Version: " .. string.format("%.2f", GetConVar("bhop_version"):GetFloat()))
end)

-- Banned users list
local format = string.format
local bannedPlayers = {
    ["STEAM_0:0:47491394"] = true,  -- henwi
    ["STEAM_0:0:74583369"] = true,   -- rq
    ["STEAM_0:1:70037803"] = true,    -- cat
    ["STEAM_0:0:53974417"] = true,     -- justa
    ["STEAM_0:0:53053491"] = true,      -- sad
    ["STEAM_0:1:205142"] = true,         -- vehnex
    ["STEAM_0:0:64764232"] = true         -- nilf
}

function IsPlayerBanned(steamID)
    return bannedPlayers[steamID] or false
end

-- Family sharing bans
function GM:PlayerAuthed(ply, steamID, uniqueID)
    if not ply:IsFullyAuthenticated() then
        UTIL:Notify(Color(255, 0, 255), "CheckFamilySharing", string.format("[Family Sharing] Player %s is not fully authenticated yet.", ply:Nick()))
        return
    end

    local lenderSteamID64 = ply:OwnerSteamID64()

    if lenderSteamID64 ~= ply:SteamID64() then
        local lenderSteamID = util.SteamIDFrom64(lenderSteamID64)
        UTIL:Notify(Color(255, 0, 255), "CheckFamilySharing", string.format("[Family Sharing] %s | %s is using a family-shared account from %s", ply:Nick(), ply:SteamID(), lenderSteamID))

        if IsPlayerBanned(lenderSteamID) then
            ply:Kick("Your main account is banned.")
        end
    end
end

-- Get players location
local locationCacheFile = "locations.txt"
local function LoadLocationCache()
    if not file.Exists(locationCacheFile, "DATA") then
        return {}
    end

    local data = file.Read(locationCacheFile, "DATA")
    return util.JSONToTable(data) or {}
end

local function SaveLocationCache(cache)
    file.Write(locationCacheFile, util.TableToJSON(cache))
end

local locationCache = LoadLocationCache()

local function FetchCountryFromAPI(ply, sanitizedIP)
    local apiURL = "https://ipapi.co/" .. sanitizedIP .. "/json/"

    HTTP({
        url = apiURL,
        method = "GET",
        success = function(code, body)
            if code == 200 then
                local jsonResponse = util.JSONToTable(body)
                if jsonResponse and jsonResponse.country_name then
                    local countryName = jsonResponse.country_name

                    locationCache[sanitizedIP] = countryName
                    SaveLocationCache(locationCache)

                    ply:SetNWString("country_name", countryName)

                    local connectMessage = Lang:Get("Connect", { ply:Nick(), ply:SteamID(), countryName })
                    BHDATA:Broadcast("Print", { "Server", connectMessage })
                end
            end
        end
    })
end

function UTIL:GetPlayerCountryByIP(ply)
    local ip = ply:IPAddress() or "localhost"
    local sanitizedIP = string.match(ip, "^([%d%.]+)")

    if not sanitizedIP or sanitizedIP == "127.0.0.1" or sanitizedIP == "localhost" then
        ply:SetNWString("country_name", "Local Network")

        local connectMessage = Lang:Get("Connect", { ply:Nick(), ply:SteamID(), "Local Network" })
        BHDATA:Broadcast("Print", { "Server", connectMessage })
        return
    end

    if locationCache[sanitizedIP] then
        local cachedCountry = locationCache[sanitizedIP]
        ply:SetNWString("country_name", cachedCountry)

        local connectMessage = Lang:Get("Connect", { ply:Nick(), ply:SteamID(), cachedCountry })
        BHDATA:Broadcast("Print", { "Server", connectMessage })
    else
        FetchCountryFromAPI(ply, sanitizedIP)
    end
end

local hasLoadedStartup = false

local function Startup()
    if not hasLoadedStartup then
	    TIMER:Boot()
        hasLoadedStartup = true
    end
end
hook_Add("Initialize", "Startup", Startup)

-- player spawn call
function GM:PlayerSpawn(ply)
    TIMER:Spawn(ply)
end

-- initial spawn call
function GM:PlayerInitialSpawn(ply)
    TIMER:Load(ply)
end

-- Remove hooks
function GM:CanPlayerSuicide() return false end
function GM:PlayerShouldTakeDamage() return false end
function GM:GetFallDamage() return false end
function GM:PlayerCanHearPlayersVoice() return true end
function GM:IsSpawnpointSuitable() return true end
function GM:PlayerSpawnObject() return false end
function GM:GravGunPunt() return false end
function GM:PhysgunPickup() return false end
function GM:PlayerDeathThink(ply) end
function GM:PlayerSetModel() end

-- Testing command
concommand.Add("_imvalid", function(ply, cmd, args)
    if not Iv(ply) then return end

    collectgarbage("collect")
end)

function GM:PlayerCanPickupWeapon(ply, weapon)
    if ply.WeaponStripped or ply:HasWeapon(weapon:GetClass()) or ply:IsBot() then return false end

    local primaryAmmoType = weapon:GetPrimaryAmmoType()
    local initialAmmo = 420

    hook_Add("WeaponEquip", "SetPlayerAmmoOnPickup", function(wep, player)
        if player == ply and wep == weapon then
            ply:SetAmmo(initialAmmo, primaryAmmoType)
            hook.Remove("WeaponEquip", "SetPlayerAmmoOnPickup")
        end
    end)
    return true
end

-- Remove dustmotes
hook_Add("InitPostEntity", "ToggleDustMotesRemoval", function()
    if GetConVar("bhop_remove_dustmotes"):GetBool() then
        for _, ent in pairs(ents.FindByClass("func_dustmotes")) do
            if IsValid(ent) then
                ent:Remove()
            end
        end

        for _, ent in pairs(ents.FindByClass("ambient_generic")) do
            if IsValid(ent) then
                ent:Remove()
            end
        end
    end
end)

function GM:EntityTakeDamage(ent, dmg)
    if ent:IsPlayer() then 
        dmg:SetDamage(0)
        return true
    end
    return false
end