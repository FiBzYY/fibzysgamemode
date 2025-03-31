--[[~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	🔧 Bunny Hop Server Commands 🔧
		by: fibzy (www.steamcommunity.com/id/fibzy_)

		file: sv_commands.lua
		desc: 💬 Handles all server commands for the Bunny Hop gamemode.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~]]

Command = {
    Functions = {},
}

-- Cache
local lp, Iv, ct, hook_Add = LocalPlayer, IsValid, CurTime, hook.Add
local insert, explode, lower, sub = table.insert, string.Explode, string.lower, string.sub

-- New Networking
util.AddNetworkString("ChangePlayerName")
util.AddNetworkString("SendNewMapsList")
util.AddNetworkString("JHUD_SendData")
util.AddNetworkString("PAINT_SendData")
util.AddNetworkString("TRAINER_SendData")
util.AddNetworkString("bhop_set_showplayers")
util.AddNetworkString("bhop_set_water_toggle")
util.AddNetworkString("OpenDiscordLink")

function SendSSJTopToClient(ply)
    if not IsValid(ply) then return end
    if not SSJTOP or table.IsEmpty(SSJTOP) then
        return
    end

    net.Start("SSJTOP_SendData")
    net.WriteTable(SSJTOP)
    net.Send(ply)
end

-- Map brightness
local brightness = "1"
function SetMapBrightness(value)
    local ply, mult
    if value and isstring(value) then
        mult = value
    elseif value and Iv(value) then
        ply = value
    end

    if ply then
        if ply:IsBot() then return end
        ply:ConCommand("bhop_map_brightness " .. brightness)
    elseif mult then
        brightness = mult
        for _, ply in pairs(player.GetHumans()) do
            ply:ConCommand("bhop_map_brightness " .. mult)
        end
    else
        for _, ply in pairs(player.GetHumans()) do
            ply:ConCommand("bhop_map_brightness " .. brightness)
        end
    end
end
hook_Add("PlayerInitialSpawn", "SetMapBrightness", SetMapBrightness)

-- Jump Stats Menu
if SSJ then
    function SSJ:OpenMenuForPlayer(pl, data)
	    UI:SendToClient(pl, "ssj", data)
    end

    function SSJ:InterfaceResponse(pl, data)
        if not pl.SSJ then self:InitializeSSJData(pl) end
        local k = data[1]
        pl.SSJ["Settings"][k] = not pl.SSJ["Settings"][k]
        pl:SetPData("SSJ_Settings", util.TableToJSON(pl.SSJ["Settings"]))
        self:OpenMenuForPlayer(pl, k)
    end
    UI:AddListener("ssj", function(pl, data) SSJ:InterfaceResponse(pl, data) end)

    function SSJ:AddCommand()
        Command:Register({"ssj", "sj", "ssjmenu"}, function(pl)
            if not pl.SSJ then self:InitializeSSJData(pl) end
            self:OpenMenuForPlayer(pl, pl.SSJ["Settings"])
        end)
    end
    hook_Add("Initialize", "AddCommand", function() SSJ:AddCommand() end)
end

-- Name changer
local function ChangePlayerName(ply, newName)
    if not IsValid(ply) then return end
    if not newName or newName == "" then
        TIMER:Print(pl, "Invalid name! Please provide a valid name.")
        return
    end

    local maxLength = 32
    if string.len(newName) > maxLength then
        TIMER:Print(pl, "Name is too long! Maximum length is " .. maxLength .. " characters.")
        return
    end

    ply:SetNWString("CustomName", newName)
    TIMER:Print(pl, "Your name has been changed to " .. newName)
end

hook_Add("PlayerSay", "ChangeNameCommand", function(ply, text)
    if string.sub(text, 1, 11) == "!changename" then
        local newName = string.Trim(string.sub(text, 12))
        ChangePlayerName(ply, newName)
        return ""
    end
end)

hook_Add("PlayerName", "OverrideDisplayName", function(ply)
    local customName = ply:GetNWString("CustomName", nil)
    if customName and customName ~= "" then
        return customName
    end
    return nil
end)

-- New added maps
local newestMaps = {}
local function UpdateMapsList()
    newestMaps = {}

    local files, _ = file.Find("maps/*.bsp", "GAME")
    if not files then
        UTIL:Notify(Color(255, 255, 255), "Command", "Failed to open the /maps directory.")
        return
    end

    for _, mapName in ipairs(files) do
        local cleanMapName = string.StripExtension(mapName)

        local mapPath = "maps/" .. mapName
        local timeStamp = file.Time(mapPath, "GAME")

        table.insert(newestMaps, {mapName = cleanMapName, timeStamp = timeStamp})
    end

    table.sort(newestMaps, function(a, b) return a.timeStamp > b.timeStamp end)
end

local function SendNewMapsList(ply)
    local maxMapsToShow = 25
    UpdateMapsList()

    net.Start("SendNewMapsList")
    net.WriteInt(math.min(#newestMaps, maxMapsToShow), 16)

    for i = 1, math.min(#newestMaps, maxMapsToShow) do
        local mapInfo = newestMaps[i]
        net.WriteString(mapInfo.mapName)
        net.WriteInt(mapInfo.timeStamp, 32)
    end

    net.Send(ply)
end

concommand.Add("bhop_newmaps", function(ply)
    if not Iv(ply) or not ply:IsPlayer() then return end
    SendNewMapsList(ply)
end)

function Command:Register(aliases, func, description, syntax)
    for _, alias in ipairs(aliases) do
        self.Functions[alias] = {func, description or "No description available", syntax or "No syntax available"}
    end
end

-- Main command triggers
function Command:Trigger(pl, szCommand, szText)
    local mainCommand, commandArgs = szCommand, {}
    if string.find(szCommand, " ", 1, true) then
        local splitData = explode(" ", szCommand)
        mainCommand = splitData[1]
        commandArgs.Upper = {}
        for i = 2, #splitData do
           insert(commandArgs, splitData[i])
           insert(commandArgs.Upper, explode(" ", szText)[i])
        end
    end

    local szFunc = self.Functions[mainCommand] and self.Functions[mainCommand][1]
    commandArgs.Key = mainCommand

    if szFunc then
        return szFunc(pl, commandArgs)
    else
        TIMER:Print(pl, "This command doesn't exist.")
        return nil
    end
end

-- Restart Player
function Command:PerformRestart(pl, currentFOV)
    if pl.Spectating then
        pl:SetTeam(1)
        pl.Spectating = false
        pl:SetNWInt("Spectating", 0)
        pl:UnSpectate()
    end

    if pl.style == TIMER:GetStyleID("Segment") and styleID ~= TIMER:GetStyleID("Segment") then
        Segment:Reset(pl)
        Segment:Exit(pl)
    end

    if pl:Team() ~= TEAM_SPECTATOR then
        local szWeapon = IsValid(pl:GetActiveWeapon()) and pl:GetActiveWeapon():GetClass() or "weapon_crowbar"
        pl.ReceiveWeapons = not not szWeapon
        pl:Spawn()
        TIMER:ResetTimer(pl)
        pl.ReceiveWeapons = nil

        if szWeapon and pl:HasWeapon(szWeapon) then
            pl:SelectWeapon(szWeapon)
        end

        if pl.WeaponsFlipped then
            TIMER:Print(pl, "Client", {"WeaponFlip", true})
            SendPopupNotification(pl, "Notification", "Weapons have been flipped.", 2)
        end
    else
        TIMER:Print(pl, Lang:Get("SpectateRestart"))
    end

    if currentFOV and IsValid(pl) then
        pl:SetFOV(currentFOV)
    end
end

function Command:Restart(pl)
    self:PerformRestart(pl)
end

-- Reload the map
local authorizedSteamID = "STEAM_0:1:48688711"
concommand.Add("reload_map", function(ply, cmd, args)
    if Iv(ply) and ply:SteamID() ~= authorizedSteamID then
        SendPopupNotification(ply, "Notification", "You do not have permission to use this command.", 2)
        return
    end

    if Replay and Replay.Save then
        Replay:Save(true)
    end

    local currentMap = game.GetMap()
    SendPopupNotification(nil, "Notification", "Reloading map: " .. currentMap .. " in 1 second to save data.", 2)

    timer.Simple(1, function()
        game.ConsoleCommand("changelevel " .. currentMap .. "\n")
    end)
end)

-- Nominate
function Command.Nominate(ply, _, varArgs)
    if not varArgs[1] then return end
    if not RTV:MapExists(varArgs[1]) then return NETWORK:StartNetworkMessageTimer(ply, "Print", {"Notification", Lang:Get("MapInavailable", {varArgs[1]})}) end
    if varArgs[1] == game.GetMap() then return NETWORK:StartNetworkMessageTimer(ply, "Print", {"Notification", Lang:Get("NominateOnMap")}) end
    if not RTV:IsAvailable(varArgs[1]) then return NETWORK:StartNetworkMessageTimer(ply, "Print", {"Notification", "Sorry, this map isn't available on the server itself. Please contact an admin!"}) end

    RTV:Nominate(ply, varArgs[1])
end

-- Style commands
function Command.Style(pl, _, varArgs)
    if not varArgs or not varArgs[1] then
        return
    end

    local styleID = tonumber(varArgs[1]) or TIMER:GetStyleID(varArgs[1])
    if styleID == 0 then
        return
    end

    if pl.style == styleID then
        if pl.style == TIMER:GetStyleID("Bonus") then
            return Command:Restart(pl)
        else
            return NETWORK:StartNetworkMessageTimer(pl, "Print", {"Timer", Lang:Get("StyleEqual", {TIMER:TranslateStyle(pl.style)})})
        end
    end

    if pl.style == TIMER:GetStyleID("Segment") and styleID ~= TIMER:GetStyleID("Segment") then
        Segment:Reset(pl)
        Segment:Exit(pl)
    end

    if styleID == TIMER:GetStyleID("Bonus") and not Zones.BonusPoint then
        return NETWORK:StartNetworkMessageTimer(pl, "Print", {"Timer", Lang:Get("styleBonusNone")})
    elseif styleID == TIMER:GetStyleID("Bonus") then
        TIMER:ResetTimer(pl)
    elseif pl.Style == TIMER:GetStyleID("Bonus") then
        TIMER:BonusReset(pl)
    elseif pl:GetNWInt("inPractice", false) then
        pl.time = nil
        NETWORK:StartNetworkMessageTimer(pl, "Timer", {"Start", pl.time})
    end

    TIMER:LoadStyle(pl, styleID)
    pl.style = styleID
end

-- Goto spectator
local function ToggleSpectate(pl, cmd, args)
    local targetPlayerID = args[1]
    
    if pl.Spectating then
        local target = pl:GetObserverTarget()
        Command:PerformRestart(pl)

        pl.Spectating = false
        pl:SetNWInt("Spectating", 0)
        Spectator:End(pl, target)
    else
        pl:SetNWInt("Spectating", 1)
        pl.Spectating = true
        TIMER:ResetTimer(pl)
        GAMEMODE:PlayerSpawnAsSpectator(pl)

        if targetPlayerID then
            Spectator:NewById(pl, targetPlayerID)
        else
            Spectator:New(pl)
        end
    end
end
concommand.Add("spectate", ToggleSpectate)

-- Remove weapons
concommand.Add("drop", function(pl)
    if not Iv(pl) then return end

    if not pl.Spectating and not pl:IsBot() then
        pl:StripWeapons()
    else
        NETWORK:StartNetworkMessageTimer(pl, "Print", {"Notification", Lang:Get("SpectateWeapon")})
    end
end)

-- Style UI Clicker
local styleIDs = {
    [1] = TIMER:GetStyleID("Normal"),
    [2] = TIMER:GetStyleID("Sideways"),
    [3] = TIMER:GetStyleID("HSW"),
    [4] = TIMER:GetStyleID("W"),
    [5] = TIMER:GetStyleID("A"),
    [6] = TIMER:GetStyleID("L"),
    [7] = TIMER:GetStyleID("E"),
    [8] = TIMER:GetStyleID("Unreal"),
    [9] = TIMER:GetStyleID("Swift"),
    [10] = TIMER:GetStyleID("Bonus"),
    [11] = TIMER:GetStyleID("WTF"),
    [12] = TIMER:GetStyleID("LG"),
    [13] = TIMER:GetStyleID("Backwards"),
    [14] = TIMER:GetStyleID("Stamina"),
    [15] = TIMER:GetStyleID("Segment"),
    [16] = TIMER:GetStyleID("AS"),
    [17] = TIMER:GetStyleID("MM"),
    [18] = TIMER:GetStyleID("HG"),
    [19] = TIMER:GetStyleID("SPEED"),
    [20] = TIMER:GetStyleID("Prespeed")
}

UI:AddListener("style", function(client, data)
    local selectedStyleKey = tonumber(data[1])
    if not selectedStyleKey then return end

    local styleID = styleIDs[selectedStyleKey]
    if styleID then
        Command.Style(client, nil, {styleID})
    else
        NETWORK:StartNetworkMessageTimer(client, "Print", {"Timer", "Invalid style selected."})
        SendPopupNotification(client, "Notification", "Invalid style selected.", 2)
    end
end)

-- FoV changer
function GiveWeaponWithFOV(pl, weaponClass)
    local currentFOV = pl:GetFOV()

    if pl.Spectating or pl:Team() == TEAM_SPECTATOR then
        NETWORK:StartNetworkMessageTimer(pl, "Print", {"Notification", Lang:Get("SpectateWeapon")})
    else
        local bFound = false
        for _, ent in pairs(pl:GetWeapons()) do
            if ent:GetClass() == "weapon_" .. weaponClass then
                bFound = true
                break
            end
        end

        if not bFound then
            pl.WeaponPickup = true
            pl:Give("weapon_" .. weaponClass)
            pl:SelectWeapon("weapon_" .. weaponClass)
            pl.WeaponPickup = nil

            NETWORK:StartNetworkMessageTimer(pl, "Print", {"Notification", Lang:Get("PlayerGunObtain", {weaponClass})})
            SendPopupNotification(pl, "Notification", "You have got a new weapon.", 2)
        else
            NETWORK:StartNetworkMessageTimer(pl, "Print", {"Notification", Lang:Get("PlayerGunFound", {weaponClass})})
        end

        if Iv(pl) then
            pl:SetFOV(currentFOV)
        end
    end
end

-- Listed all commands
function Command:Init()
    local commands = {
        {
            {"changelevel"},
            function(pl, args)
                if not pl:IsAdmin() or not args[1] then
                    TIMER:Print(pl, Lang:Get("MapChangeSyntax"))
                    return
                end

                local targetMap = args[1]
                if not string.find(targetMap, "bhop_") then
                    targetMap = "bhop_" .. targetMap
                end

                if Replay and Replay.Save then
                    Replay:Save(true)
                end

                SendPopupNotification(nil, "Notification", "Changing map to: " .. targetMap .. " in 1 second to save data.", 2)

                game.ConsoleCommand("changelevel " .. targetMap .. "\n")
            end,
            "Change the current map to the specified map (Admin only)",
            "<mapname>"
        },

        -- Admin Menu
        {
            {"admin"},
            function(pl, args)
                if Admin and Admin.CommandProcess then
                    Admin.CommandProcess(pl, args)
                else
                    pl:ChatPrint("Admin addon is not installed or is missing.")
                end
            end,
            "Admin command",
            "<arguments>"
        },

        -- Themes Menu
        {
            {"theme", "themeeditor", "themes"},
            function(pl)
                pl:ConCommand("bhop_thememanager")
            end,
            "Opens the theme manager",
            "[subcommand]"
        },

        -- Restart
        {
        {"restart", "r", "respawn"},
        function(pl)
            local currentFOV = pl.GetFOV and pl:GetFOV() or nil
            self:PerformRestart(pl, currentFOV)
            SendPopupNotification(pl, "Notification", "Your timer has been restarted.", 2)
        end,
        "Restart or respawn the player",
        "[subcommand]"
        },

        -- JHUD Menu
        {
            {"jhud", "jumphud"},
            function(pl, args)
                if not IsValid(pl) then return end
                net.Start("JHUD_SendData")
                net.Send(pl)
            end,
            "Jhud Menu command",
            "<arguments>"
        },

        -- Strafe Trainer Menu
        {
            {"strafetrainer", "strafetrainermenu"},
            function(pl, args)
                if not IsValid(pl) then return end
                net.Start("TRAINER_SendData")
                net.Send(pl)
                TIMER:Print(pl, "Strafe Trainer Menu has been opened!")
            end,
            "Paint Menu command",
            "<arguments>"
        },

        -- Paint Menu
        {
            {"paint", "paintmenu"},
            function(pl, args)
                if not IsValid(pl) then return end
                net.Start("PAINT_SendData")
                net.Send(pl)
                TIMER:Print(pl, "Paint Menu has been opened!")
            end,
            "Paint Menu command",
            "<arguments>"
        },

        -- Booster Fix
        {
            {"boosterfix", "bfix"},
            function(pl, args)
                local pFix = pl.Boosterfix
                pFix.Enabled = not pFix.Enabled
                pl:SetPData("BoosterFix", pFix.Enabled and "1" or "0")

                TIMER:Print(pl, "You have " .. (pFix.Enabled and "enabled" or "disabled") .. " Consistent Boosterfix.") 
            end,
            "Booster Fix command",
            "<arguments>"
        },

        -- Show or Hide Players
        {
        {"show", "hide", "showplayers", "hideplayers"},
        function(pl, args)
            local key = args.Key and string.lower(args.Key) or ""

            if string.sub(key, 1, 4) == "show" then
                net.Start("bhop_set_showplayers")
                net.WriteBool(true)
                net.Send(pl)
                TIMER:Print(pl, "Players Enabled. You can now see players!")
            elseif string.sub(key, 1, 4) == "hide" then
                net.Start("bhop_set_showplayers")
                net.WriteBool(false)
                net.Send(pl)
                TIMER:Print(pl, "Players Disabled. Players are now hidden!")
            else
                TIMER:Print(pl, "Invalid command. Use show/hide")
            end
        end,
        "Hide or show players",
        "[subcommand]"
        },

        -- Water Command
        {
        { "water", "fixwater", "reflection", "refraction" },
        function(pl, args)
            net.Start("bhop_set_water_toggle")
            net.Send(pl)
        end,
        "Hide or show water",
        "[subcommand]"
        },

        -- Spectate
        {
            {"spectate", "spec", "watch", "view"},
            function(pl, _, varArgs)
                varArgs = varArgs or {}

                if pl.Spectating and varArgs[1] then
                    Spectator:NewById(pl, varArgs[1], true, varArgs[2])
                elseif pl.Spectating then
                    local target = pl:GetObserverTarget()
                    self:PerformRestart(pl)
                    pl.Spectating = false
                    pl:SetNWInt("Spectating", 0)
                    Spectator:End(pl, target)
                else
                    pl:SetNWInt("Spectating", 1)
                    pl.Spectating = true
                    TIMER:ResetTimer(pl)
                    GAMEMODE:PlayerSpawnAsSpectator(pl)
                    if varArgs[1] then
                        Spectator:NewById(pl, varArgs[1], nil, varArgs[2])
                    else
                        Spectator:New(pl)
                    end
                end
            end,
            "Toggle spectate mode or spectate a specific player",
            "[playerID]"
        },

        -- Noclip
        {
            {"noclip", "freeroam", "clip", "wallhack"},
            function(pl, _, varArgs)
                if not pl:GetNWInt("inPractice") and (pl.timeTick or pl.bonustimeTick) then
                    TIMER:Print(pl, "Your timer has been stopped due to the use of Noclip.")
                    SendPopupNotification(pl, "Notification", "Your timer has been stopped due to the use of Noclip.", 2)

                    pl:StopAnyTimer()
                    pl:SetNWInt("inPractice", true)
                    pl:ConCommand("noclip")
                elseif not pl:GetNWInt("inPractice") then
                    TIMER:Print(pl, "You cannot use Noclip in the Start Zone.")
                    return
                end
                pl:ConCommand("noclip")
            end,
            "Toggle noclip mode",
            "[subcommand]"
        },

        -- Showtriggers
        {
            {"showtriggers", "st", "maptriggers"},
            function(pl, _, varArgs)
                local currentValue = pl:GetInfoNum("showtriggers_enabled", 0)

                if currentValue == 0 then
                    pl:ConCommand("showtriggers_enabled 1")
                    TIMER:Print(pl, "ShowTriggers Enabled. You can now see triggers.")
                else
                    pl:ConCommand("showtriggers_enabled 0")
                    TIMER:Print(pl, "ShowTriggers Disabled. Triggers are now hidden.")
                end
            end,
            "Toggle triggers",
            "[subcommand]"
        },

        -- Showclips
        {
            {"showclips", "clips", "mapclips"},
            function(pl, _, varArgs)
                local currentValue = pl:GetInfoNum("showclips", 0)

                if currentValue == 0 then
                    pl:ConCommand("showclips 1")
                    TIMER:Print(pl, "ShowClips Enabled. You can now see clips.")
                else
                    pl:ConCommand("showclips 0")
                    TIMER:Print(pl, "ShowClips Disabled. clips are now hidden.")
                end
            end,
            "Toggle triggers",
            "[subcommand]"
        },

        -- Goto Player
        {
            {"tp", "tpto", "goto", "teleport", "tele"},
            function(pl, args)
                if not pl:GetNWInt("inPractice", false) then
                    TIMER:Print(pl, "You must disable your timer, use noclip, or enable checkpoints to allow teleportation first.")
                    return
                end

                if #args > 0 then
                    local searchTerm = string.lower(args[1])
                    for _, p in pairs(player.GetAll()) do
                        if string.find(string.lower(p:Name()), searchTerm, 1, true) then
                            pl:SetPos(p:GetPos())
                            pl:SetEyeAngles(p:EyeAngles())
                            pl:SetLocalVelocity(Vector(0, 0, 0))
                            TIMER:Print(pl, "You have been teleported to " .. p:Name())
                            return
                        end
                    end
                    TIMER:Print(pl, "Could not find a valid player with search terms: " .. args[1])
                else
                    TIMER:Print(pl, "Could not find a valid player with search terms")
                end
            end,
            "Teleport to a player",
            "<playername>"
        },

        -- Goto Start
        {
            {"start", "gostart", "gotostart", "tpstat"},
            function(pl, args)
                if pl:GetNWInt("inPractice", false) then
                    local vPoint = Zones:GetCenterPoint(Zones.Type["Normal Start"])
                    if vPoint then
                        pl:SetPos(vPoint)
                        BHDATA:Send(pl, "Print", { "Timer", Lang:Get("PlayerTeleport", { "the normal start zone" }) })
                        SendPopupNotification(pl, "Notification", "Teleported the normal end zone.", 2)
                    else
                        BHDATA:Send(pl, "Print", { "Timer", Lang:Get("MiscZoneNotFound", { "normal end" }) })
                    end
                else
                    BHDATA:Send(pl, "Print", { "Timer", "You have to disable your timer first, either use noclip or enable checkpoints to allow for teleport." })
                end
            end,
            "Go to end zone",
            "[subcommand]"
        },

        -- Goto End
        {
            {"end", "goend", "gotoend", "tpend"},
            function(pl, args)
                if pl:GetNWInt("inPractice", false) then
                    local vPoint = Zones:GetCenterPoint(Zones.Type["Normal End"])
                    if vPoint then
                        pl:SetPos(vPoint)
                        BHDATA:Send(pl, "Print", { "Timer", Lang:Get("PlayerTeleport", { "the normal end zone" }) })
                        SendPopupNotification(pl, "Notification", "Teleported the normal end zone.", 2)
                    else
                        BHDATA:Send(pl, "Print", { "Timer", Lang:Get("MiscZoneNotFound", { "normal end" }) })
                    end
                else
                    BHDATA:Send(pl, "Print", { "Timer", "You have to disable your timer first, either use noclip or enable checkpoints to allow for teleport." })
                end
            end,
            "Go to end zone",
            "[subcommand]"
        },

        -- Goto Bonus Start
        {
            {"bonusstart", "gobstart", "gotobonusstart", "tpbonustart"},
            function(pl, args)
                if pl:GetNWInt("inPractice", false) then
                    local vPoint = Zones:GetCenterPoint(Zones.Type["Bonus Start"])
                    if vPoint then
                        pl:SetPos(vPoint)
                        BHDATA:Send(pl, "Print", { "Timer", Lang:Get("PlayerTeleport", { "the bonus start zone" }) })
                        SendPopupNotification(pl, "Notification", "Teleported the normal end zone.", 2)
                    else
                        BHDATA:Send(pl, "Print", { "Timer", Lang:Get("MiscZoneNotFound", { "normal end" }) })
                    end
                else
                    BHDATA:Send(pl, "Print", { "Timer", "You have to disable your timer first, either use noclip or enable checkpoints to allow for teleport." })
                end
            end,
            "Go to end zone",
            "[subcommand]"
        },

        -- Goto Bonus End
        {
            {"bonusend", "gobend", "gotobend", "tptobend", "bend"},
            function(pl, args)
                if pl:GetNWInt("inPractice", false) then
                    local vPoint = Zones:GetCenterPoint(Zones.Type["Bonus End"])
                    if vPoint then
                        pl:SetPos(vPoint)
                        BHDATA:Send(pl, "Print", { "Timer", Lang:Get("PlayerTeleport", { "the bonus end zone" }) })
                        SendPopupNotification(pl, "Notification", "Teleported the normal end zone.", 2)
                    else
                        BHDATA:Send(pl, "Print", { "Timer", Lang:Get("MiscZoneNotFound", { "normal end" }) })
                    end
                else
                    BHDATA:Send(pl, "Print", { "Timer", "You have to disable your timer first, either use noclip or enable checkpoints to allow for teleport." })
                end
            end,
            "Go to end zone",
            "[subcommand]"
        },

        -- RTV
        {
            {"rtv", "vote", "votemap"},
            function(pl, args)
                if #args > 0 then
                    local subcmd = string.lower(args[1])
                    if (subcmd == "who" or subcmd == "list") and RTV and RTV.Who then
                        RTV:Who(pl)
                    elseif (subcmd == "check" or subcmd == "left") and RTV and RTV.Check then
                        RTV:Check(pl)
                    elseif subcmd == "revoke" and RTV and RTV.Revoke then
                        RTV:Revoke(pl)
                    elseif subcmd == "extend" and Admin and Admin.VIPProcess then
                        Admin.VIPProcess(pl, {"extend"})
                    else
                        TIMER:Print(pl, subcmd .. " is an invalid subcommand for rtv. Valid: who, list, check, left, revoke, extend")
                    end
                else
                    if RTV and RTV.Vote then
                        RTV:Vote(pl)
                    else
                        TIMER:Print(pl, "RTV system is not installed.")
                    end
                end
            end,
            "Rock the vote commands",
            "[subcommand]"
        },

        -- Revoke RTV
        {
            {"revoke"},
            function(pl, args)
                RTV:Revoke(pl)
            end,
            "Revoke Rock the vote",
            "[subcommand]"
        },

        -- Revote
        {
            {"revote", "openrtv"},
            function(pl, args)
                if not RTV.VotePossible then
                    TIMER:Print(pl, "There is no active vote.")
                else
                    local RTVSend = {}
                    for _, map in pairs(RTV.Selections) do
                        table.insert(RTVSend, RTV:GetMapData(map))
                    end
                    UI:SendToClient(false, "MapVote", "revote", RTVSend)
                    UI:SendToClient(false, "MapVote", "update", RTV.MapVoteList)
                end
            end,
            "Re-open the RTV voting menu",
            "[subcommand]"
        },

        -- Time Left
        {
            {"timeleft", "time", "remaining"},
            function(pl)
                TIMER:Print(pl, Lang:Get("TimeLeft", {TIMER:Convert(RTV.MapEnd - CurTime())}))
            end,
            "Displays the time left for the current map",
            ""
        },

        -- Show HUD
        {
            {"showgui", "showhud", "hidegui", "hidehud", "togglegui", "togglehud"},
            function(pl, args)
                TIMER:Print(pl, "Client", {"GUIVisibility", string.sub(args.Key, 1, 4) == "hide" and 0 or (string.sub(args.Key, 1, 4) == "show" and 1 or -1)})
            end,
            "Toggle GUI visibility",
            ""
        },

        -- Nominate
        {
            {"nominate", "rtvmap", "playmap", "maps"},
           function(ply, args)
                if args[1] then
                    Command.Nominate(ply, nil, args)
                else
                    UI:SendToClient(ply, "nominate", {RTV.MapListVersion})
                end
            end,
            "Nominate a map for the next round",
            "[mapname]"
        },

        -- WR List
        {
            {"wr", "wrlist", "records"},
            function(ply, args)
                local stylename, page = ply.style, 1
                if #args > 0 then
                    TIMER:SendRemoteWRList(ply, args[1], stylename, page)
                else
                    TIMER:GetRecordList(stylename, page, function(wrList)
                        UI:SendToClient(ply, "wr", wrList, stylename, page, TIMER:GetRecordCount(stylename))
                    end)
                end
            end,
            "Displays world records or record list",
            "<style> [page]"
        },

        -- Discord Link
        {
            {"discord", "opendiscord"},
            function(ply, args)
                net.Start("OpenDiscordLink")
                net.Send(ply)
            end,
            "Displays world records or record list",
            "<style> [page]"
        },
        -- Normal WR
        --[[{
            {"nwr", "normalwr", "wrnormal"},
            function(ply, args)
                local nStyle, page = TIMER:GetStyleID("N"), 1
                if #args > 0 then
                    TIMER:SendRemoteWRList(ply, args[1], nStyle, page)
                else
                    TIMER:GetRecordList(nStyle, page, function(records)
                        UI:SendToClient(ply, "wr", records, nStyle, page, TIMER:GetRecordCount(nStyle))
                    end)
                end
            end,

            "Displays normal world records or record list",
            "<style> [page]"
        },--]]

        -- Style WR 
        {
            {"wr", "records", "worldrecords"},
            function(ply, args)
            local styleAliases = {
                ["n"] = "N",
                ["sw"] = "SW",
                ["hsw"] = "HSW",
                ["w"] = "W",
                ["lg"] = "LG",
                ["bonus"] = "Bonus",
                ["stamina"] = "Stamina" }

                local styleArg = args[1] and args[1]:lower() or "n"
                local styleName = styleAliases[styleArg] or "N"
                local styleID = TIMER:GetStyleID(styleName)
                local page = tonumber(args[2]) or 1

                TIMER:GetRecordList(styleID, page, function(records)
                    UI:SendToClient(ply, "wr", records, styleID, page, TIMER:GetRecordCount(styleID))
                end)
            end,

            "Displays normal world records or record list",
            "<style> [page]"
        },

        -- Style Menu
        {
            {"style", "mode", "bhop", "styles", "modes"},
            function(pl)
                UI:SendToClient(pl, "style", {})
            end,
            "Opens the style selection menu",
            ""
        },

        -- Main Menu
        {
            {"menu", "options", "mainmenu"},
            function(pl)
                UI:SendToClient(pl, "menu", {})
            end,
            "Opens the main bhop menu",
            "[subcommand]"
        },

        -- Segment
        {
            {"segment", "segmented", "tas", "seg"},
            function(client)
                if (client.style ~= TIMER:GetStyleID("Segment")) then
                    Command.Style(client, nil, { TIMER:GetStyleID("Segment")})
                    BHDATA:Send(client, "Print", {"Timer", "To reopen the segment menu at any time, use this command again."})
                    SendPopupNotification(client, "Notification", "To reopen the segment menu at any time, use this command again.", 2)
                end

                UI:SendToClient(client, "segment")
            end,
            "Activate segmented mode and open the segment menu",
            "[subcommand]"
        },

        -- Give weapons
        {
            {"glock", "usp", "knife", "p90", "deagle", "scout", "awp", "crowbar"},
            function(pl, args)
                     GiveWeaponWithFOV(pl, args.Key)
            end,
            "Gives the player a specific weapon",
            "<weapon>"
        },

        -- Remove weapons
        {
            {"g", "remove", "strip", "stripweapons"},
            function(pl)
                if not pl.Spectating and not pl:IsBot() then
                    pl:StripWeapons()
                    SendPopupNotification(pl, "Notification", "Striped your weapons", 2)
                else
                    NETWORK:StartNetworkMessageTimer(pl, "Print", {"Notification", Lang:Get("SpectateWeapon")})
                end
            end,
            "Remove all weapons from the player",
            "[subcommand]"
        },

        -- Save Replay
        {
            {"replaysave", "saverun", "savereplay", "replay save"},
            function(pl)
                if not pl:IsAdmin() then
                    TIMER:Print(pl, "You do not have permission to save replays.")
                    return
                end

                if Replay and Replay.Save then
                    Replay:Save(true)
                end

                TIMER:Print(pl, "Replay has been saved.")
                SendPopupNotification(nil, "Notification", "Replay has been saved!", 2)
            end,
            "Save the current replay data (Admin only)",
            "[subcommand]"
        },

        -- Long Jump
        {
        {"lj", "ljstats"}, 
        function(pl)
            if not pl.ljen then 
                pl.ljen = true
                TIMER:Print(pl, "LJStats Enabled.")
            else
                pl.ljen = false
                TIMER:Print(pl, "LJStats Disabled.")
            end
        end,
        "Enable or disable LJ stats.", 
        "[subcommand]"
        },

        -- SSJTop
        {
         {"ssjtop", "topssj", "speedjump", "leaderboard"},
        function(pl)
            SendSSJTopToClient(pl)
        end,
        "Enable or disable LJ stats.", 
        "[subcommand]"
        },

        -- Wr Sounds
        {
        {"wrsounds", "wrsound"}, 
        function(pl)
            if not IsValid(pl) then return end

            if pl:GetInfoNum("bhop_wrsfx", 0) == 0 then
                pl:ConCommand("bhop_wrsfx 1")
                NETWORK:StartNetworkMessageTimer(pl, "Print", { "Notification", "WR sounds ON :)" })
            else
                pl:ConCommand("bhop_wrsfx 0")
                NETWORK:StartNetworkMessageTimer(pl, "Print", { "Notification", "WR sounds OFF :(" })
            end
        end,
        "Toggle WR sound effects on/off",
        "[subcommand]"
        },

        {
        {"runs", "setrun", "replay", "replayset"},
        function(pl, args)
            local list = Replay:GetMultiBots()

            if not args[1] then
                if #list > 0 then
                    return NETWORK:StartNetworkMessageTimer(pl, "Print", { "Notification", "Runs on these styles are recorded and playable: " .. string.Implode(", ", list) .. " (Use !replay Style to start a playback.)" })
                else
                    return NETWORK:StartNetworkMessageTimer(pl, "Print", { "Notification", "There are no other replays available for playback." })
                end
            end

            local style = tonumber(args[1])
            if not style then
                local stylename = string.Implode(" ", args):lower()
                stylename = string.Trim(stylename)
    
                local styleID = nil

                for id, _ in pairs(TIMER.Styles) do
                    if string.lower(TIMER:StyleName(id)) == stylename then
                        styleID = id
                        break
                    end
                end

                if not styleID or not TIMER:IsValidStyle(styleID) then
                    return NETWORK:StartNetworkMessageTimer(pl, "Print", { "Notification", "You have entered an invalid style name. Use the exact name shown on !styles or use their ID." })
                end

                style = styleID
            end

            local Change = Replay:ChangeMultiBot(style)
            if string.len(Change) > 10 then
                NETWORK:StartNetworkMessageTimer(pl, "Print", { "Notification", Change })
            else
                NETWORK:StartNetworkMessageTimer(pl, "Print", { "Notification", Lang:Get("BotMulti" .. Change) })
            end
        end,
        "Replay commands",
        "[subcommand]"
        },

        -- Map/Points
        {
            {"map", "points"}, 
            function(pl, args)
                if #args > 0 then
                    if not args[1] then return end
                    if RTV:MapExists(args[1]) then
                        local data = RTV:GetMapData(args[1])
                        BHDATA:Send(pl, "Print", { "Notification", Lang:Get("MapInfo", { data[1], data[2] or 0, "No more details available", "" }) })
                    else
                        BHDATA:Send(pl, "Print", { "Notification", Lang:Get("MapInavailable", { args[1] }) })
                    end
                else
                    local nMult, bMult = Timer.Multiplier or 0, Timer.BonusMultiplier or 0
                    local szBonus = Zones.BonusPoint and " (Bonus has a multiplier of " .. bMult .. ")" or ""
                    local nPoints = TIMER:GetPointsForMap(pl.record, pl.style)
                    local szPoints = "You have " .. math.floor(nPoints) .. "/" .. nMult .. " points"

                    BHDATA:Send(pl, "Print", { "Notification", Lang:Get("MapInfo", { game.GetMap(), Timer.Multiplier or 1, szPoints, szBonus }) })
                end
            end,
            "Toggle WR sound effects on/off",
            "[subcommand]"
        },

        -- Kick
       {
            {"kick", "kicplayer"},
            function(pl, args)
                if not IsValid(pl) or not pl:IsAdmin() then
                    if IsValid(pl) then TIMER:Print(pl, "You do not have permission to use this command.") end
                    return
                end

                if #args < 1 then
                    TIMER:Print(pl, "Usage: !kick <SteamID/Name> [reason]")
                    return
                end

                local target = args[1]
                local reason = table.concat(args, " ", 2) or "No reason provided"
                local targetPlayer = nil

                for _, ply in ipairs(player.GetAll()) do
                    if string.find(string.lower(ply:Nick()), string.lower(target), 1, true) then
                        targetPlayer = ply
                        break
                    end
                end

                if not IsValid(targetPlayer) and string.match(target, "^STEAM_[0-5]:[01]:%d+$") then
                    for _, ply in ipairs(player.GetAll()) do
                        if ply:SteamID() == target then
                            targetPlayer = ply
                            break
                        end
                    end
                end

                if IsValid(targetPlayer) then
                    targetPlayer:Kick("Kicked by Admin: " .. reason)
        
                    if UTIL and UTIL.Notify then
                        UTIL:Notify(Color(255, 0, 0), "BanSystem", "Player " .. targetPlayer:Nick() .. " has been kicked. Reason: " .. reason)
                    else
                        PrintMessage(HUD_PRINTTALK, "[BanSystem] Player " .. targetPlayer:Nick() .. " has been kicked. Reason: " .. reason)
                    end
                else
                    TIMER:Print(pl, "Player not found.")
                end
            end,
            "Kick player",
            "[subcommand]"
        },
    }

    for _, cmd in ipairs(commands) do
        self:Register(unpack(cmd))
    end

    for id, styleData in ipairs(TIMER.Styles) do
        local aliases = styleData[3]

        self:Register(aliases, function(pl)
            Command.Style(pl, nil, {tostring(id)})
        end, "Switch to style: " .. styleData[1], "<styleID>")
    end
end

UI:AddListener("nominate", function(client, data)
    local mapName = data[1]
    if mapName then
        Command.Nominate(client, nil, {mapName})
    end
end)

-- Player Say
function GM:PlayerSay(pl, text, team)
    local command = lower(text:Trim())

    if command == "rtv" then
        if RTV and RTV.Vote then
            RTV:Vote(pl)
        else
            pl:ChatPrint("RTV system is not installed.")
        end
        return ""
    end

    local prefix = sub(command, 1, 1)
    if prefix == "!" or prefix == "/" then
        local commandStripped = lower(sub(command, 2))

        if Command and Command.Trigger then
            local reply = Command:Trigger(pl, commandStripped, text)
            return type(reply) == "string" and reply or ""
        end
    end

    if Admin and Admin.HandleTeamChat then
        return not team and text or Admin:HandleTeamChat(pl, text, text)
    end

    return text
end

-- UI spectate
NETWORK:GetNetworkMessage("ToggleSpectateMode", function(client, data)
    local targetPlayerID = data[1]

    if client.Spectating then
        local target = client:GetObserverTarget()
        Command:PerformRestart(client)
        client.Spectating = false
        client:SetNWInt("Spectating", 0)
        Spectator:End(client, target)
    else
        client:SetNWInt("Spectating", 1)
        client.Spectating = true
        TIMER:ResetTimer(client)

        GAMEMODE:PlayerSpawnAsSpectator(client)

        if targetPlayerID then
            Spectator:NewById(client, targetPlayerID)
        else
            Spectator:New(client)
        end
    end
end)

-- Clickers
util.AddNetworkString("OpenBhopMenu")
util.AddNetworkString("OpenWorldRecords")

function GM:ShowHelp(pl)
    net.Start("OpenBhopMenu")
    net.Send(pl)
end

function GM:ShowTeam(pl)
    NETWORK:StartNetworkMessage(pl, "OpenSpectateDialog", {})
end

Command:Init()