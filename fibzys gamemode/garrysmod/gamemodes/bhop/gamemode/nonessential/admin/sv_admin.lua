-- messest file of the gamemode rework needed!

Admin = {
    Protocol = "Admin",
    
    Level = {
        None = 0,
        Base = 1,
        Elevated = 2, 
        Moderator = 4,
        Admin = 8,
        Zoner = 9,
        Super = 16,
        Developer = 32,
        Manager = 33,
        Founder = 34,
        Owner = 64
    },
    
    AdminIDs = {
        [1] = 1,   -- Base
        [2] = 2,    -- Elevated
        [4] = 3,     -- Moderator
        [8] = 4,      -- Admin
        [9] = 5,       -- Zoner
        [16] = 6,       -- Super
        [32] = 7,        -- Developer
        [33] = 8,         -- Manager
        [34] = 9,          -- Founder
        [64] = 10           -- Owner
    }
}

Admin.LevelNames = {}

for key,id in pairs(Admin.Level) do
	Admin.LevelNames[id] = key
end

local hook_Add, sq = hook.Add, sql.Query
local AdminLoad = {}

-- BANS --
local BanSystem = "[BanSystem] "
local Bans = {steam = {}, ip = {} }

NETWORK:GetNetworkMessage("AdminChangeMovementSetting", function(ply, data)
    if not ply:IsAdmin() then return end

    local cvarName = data[1]
    local newValue = data[2]

    if newValue < 0 or newValue > 100000 then return end

    local cvar = GetConVar(cvarName)
    if cvar then
        RunConsoleCommand(cvarName, tostring(newValue))
        BHDATA:Send(ply, "Print", {"Admin", cvarName .. " updated to " .. string.format("%.6f", newValue)})
    else
        BHDATA:Send(ply, "Print", {"Admin", "Invalid ConVar: " .. cvarName})
    end
end)

AdminLoad.Levels = {}
AdminLoad.Setup = {
	{5, "Change map", Admin.Level.Zoner, { 40, 47, 100, 40 }},
	{3, "Map points", Admin.Level.Zoner, { 145, 47, 100, 40 }},
	{21, "Bonus points", Admin.Level.Zoner, { 250, 47, 100, 40 }},
	{11, "Map options", Admin.Level.Zoner, { 355, 47, 100, 40 }},
	{1, "Set zone", Admin.Level.Zoner, { 40, 97, 100, 40 }},
	{10, "Remove zone", Admin.Level.Zoner, { 145, 97, 100, 40 }},
	{2, "Cancel Zone", Admin.Level.Zoner, { 250, 97, 100, 40 }},
	{6, "Reload zones", Admin.Level.Zoner, { 355, 97, 100, 40 }},
	{9, "Zone height", Admin.Level.Zoner, { 40, 147, 100, 40 }},
	{20, "Cancel vote", Admin.Level.Zoner, { 145, 147, 100, 40 }},
	{17, "Remove time", Admin.Level.Zoner, { 40, 202, 100, 40 }},
	{18, "Remove replay", Admin.Level.Zoner, { 145, 202, 100, 40 }},
	{28, "Remove all times", Admin.Level.Developer, { 250, 147, 205, 40 }},
	{24, "Reload admins", Admin.Level.Developer, { 40, 252, 100, 40 }},
	{22, "Remove map", Admin.Level.Developer, { 145, 252, 100, 40 }},
	{7, "Set admin", Admin.Level.Manager, { 250, 252, 100, 40, true }},
	{8, "Remove admin", Admin.Level.Manager, { 355, 252, 100, 40, true }},
	{99, "Remove admin", Admin.Level.Manager, { 355, 252, 100, 40, true }},
}

local ti, tr = table.insert, table.remove

-- Loads all admins from the master server and saves their access levels in a AdminLoad table
function Admin:LoadAdmins(operator)
    if not self.Loaded then
        SQL:Prepare(
            "SELECT steam, level FROM timer_admins ORDER BY level DESC"
        ):Execute(function(data, varArg, szError)
            AdminLoad.Levels = {}
            
            if data then
                for _, item in pairs(data) do
                    AdminLoad.Levels[item["steam"]] = item["level"]
                end
            end

            if varArg then
                if operator and operator ~= "" then
                    AdminLoad.Levels[operator] = Admin.Level.Owner
                end
            end

            for _, p in pairs(player.GetHumans()) do
                Admin:CheckPlayerStatus(p, true)
            end

            Admin.Loaded = true
        end, operator)
    end
end

function Admin:GetAccess(ply)
	return AdminLoad.Levels[ply:SteamID()] or Admin.Level.None
end

function Admin:CanAccess(ply, required)
	return Admin:GetAccess(ply) >= required
end

function Admin:CanAccessID(ply, id, bypass)
	local l
	
	for _,data in pairs(AdminLoad.Setup) do
		if data[1] == id then
			l = data[3]
			break
		end
	end

	if not l then
		if bypass then return true end
		return false
	end
	return Admin:CanAccess(ply, l)
end

function Admin:IsHigherThan(a, b, eq, by)
	if not by and (not IsValid(a) or not IsValid(b)) then return false end
	local ac, bc = Admin:GetAccess(a), Admin:GetAccess(b)
	return eq and ac >= bc or ac > bc
end

function Admin:SetAccessIcon(ply, level)
	if Admin.AdminIDs[level] then
		ply:SetNWInt("AccessIcon", Admin.AdminIDs[level])
	end
end

function Admin:CheckPlayerStatus(ply, reload)
    local nAccess = Admin:GetAccess(ply)
    if nAccess >= Admin.Level.Admin then
        ply:SetUserGroup("admin")
    end

    ply:SetNWInt("PlayerRank", nAccess)

    if nAccess >= Admin.Level.Base then
        Admin:SetAccessIcon(ply, nAccess)
    end
end

-- Sends a message to the master server which then saves it in the database
function Admin:AddLog(text, steam, zoner)
	SQL:Prepare(
		"INSERT INTO timer_logging (type, data, date, adminsteam, adminname) VALUES ({0}, {1}, {2}, {3}, {4})",
		{2, text, os.date( "%Y-%m-%d %H:%M:%S", os.time()), steam, zoner}
	):Execute(function(data, var, error)
		if data then
			BHDATA:Print("Logging", "Added entry: " .. text)
		end
	end)
end

function Admin:SendLogs(ply)
    SQL:Prepare("SELECT * FROM timer_logging ORDER BY date DESC LIMIT 100")
    :Execute(function(data, var, error)
        if error then
            print("[Admin Logs] SQL ERROR: " .. tostring(error))
        end

        if not data or #data == 0 then
            return
        end

		NETWORK:StartNetworkMessage(ply, "SendAdminLogs", data)
    end)
end

NETWORK:GetNetworkMessage("RequestAdminLogs", function(ply)
    Admin:SendLogs(ply)
end)

function Admin:SetMapTier(ply, tier)
    if not Admin:CanAccess(ply, Admin.Level.Zoner) then
        return BHDATA:Send(ply, "Print", {"Admin", "You don't have access to use this command!"})
    end

    if not tier or tier < 1 or tier > 8 then
        return BHDATA:Send(ply, "Print", {"Admin", "Please enter a valid tier number between 1 and 8."})
    end

    local map = MySQL:Escape(game.GetMap())

    MySQL:Start("SELECT map FROM timer_map WHERE map = " .. map, function(result)
        if result and result[1] then
            MySQL:Start("UPDATE timer_map SET tier = " .. tier .. " WHERE map = " .. map)
        else
            MySQL:Start("INSERT INTO timer_map (map, multiplier, tier, plays, options) VALUES (" .. map .. ", " .. (Timer.Multiplier or 15) .. ", " .. tier .. ", 0, NULL)")
        end

        RTV:LoadData()
        RTV:UpdateMapListVersion()

        Admin:AddLog("Updated tier to " .. tier .. " for map " .. game.GetMap(), ply:SteamID(), ply:Name())
        BHDATA:Send(ply, "Print", {"Admin", "Tier for current map set to Tier " .. tier})
    end)
end

function Admin:GenerateRequest(caption, title, default, ret)
	return {Caption = caption, Title = title, Default = default, Return = ret}
end

function Admin:FindPlayer(id)
	local t = nil
	
	for _,p in pairs(player.GetHumans()) do
		if tostring(p:SteamID()) == tostring(id) then
			t = p
			break
		end
	end
	
	return t
end

-- Not finish for my gamemode
function Admin:SetVIP(ply, type, tag, name, chat, remaining, id)
	ply.IsVIP = true
	ply.VIPID = id
	
	ply:SetNWInt("VIPStatus", 1)
end

local tabNames = nil
function Admin:GetAccessString(level)
	if tabNames then
		return tabNames[level]
	end
	
	tabNames = {}
	for name,level in pairs(Admin.Level) do
		tabNames[level] = name
	end
	
	return tabNames[level]
end

function Admin.CommandProcess(ply, args)
    if not Admin:CanAccess(ply, Admin.Level.Elevated) then
        return BHDATA:Send(ply, "Print", {"Notification", "You don't have access to Admin."})
    end

    if #args == 0 then
        Admin:CreateWindow(ply)
    else
        local id, acess = args[1], Admin:GetAccess(ply)
        local steamIDMessage = "Please enter a valid Steam ID like this: !admin " .. id .. " STEAM_0:ID"

        local function handleButton(buttonID)
            if not args[2] then
                return BHDATA:Send(ply, "Print", {"Admin", steamIDMessage})
            end
            Admin:HandleButton(ply, {-2, buttonID, args.Upper[2]})
        end

        local commands = {
            ["spectator"] = {access = Admin.Level.Admin, id = 12},
            ["strip"] = {access = Admin.Level.Admin, id = 23}
        }

        local command = commands[id]
        if command and nAccess >= command.access then
            handleButton(command.id)
        else
            BHDATA:Send(ply, "Print", {"Admin", "This is not a valid subcommand of " .. args.Key .. "."})
        end
    end
end

function Admin:CreateWindow(ply)
    local access = Admin:GetAccess(ply)
    local tab = {
        Title = "Admin Panel",
        Width = 360,
        Height = 320,
    }

    if access < Admin.Level.Elevated then return end
    if access > Admin.Level.Admin then tab.Width = tab.Width + 105 end

    table.insert(tab, {Type = "DButton", Close = true, Modifications = {["SetPos"] = {tab.Width - 25, 8 }, ["SetSize"] = { 16, 16 }, ["SetText"] = { "X" }} })
    if AdminLoad.RequiresSteamInput then
        table.insert(tab, {Type = "DTextEntry", Label = "PlayerSteam", Modifications = {["SetPos"] = { 10, 10 }, ["SetSize"] = { 200, 25 }, ["SetText"] = {"Enter Steam ID"} } })
    end

    for _, item in ipairs(AdminLoad.Setup) do
        if item[3] and item[4] and access >= item[3] then
            local data = item[4]
            local mod = {
                ["SetPos"] = { data[1], data[2] },
                ["SetSize"] = { data[3], data[4] },
                ["SetText"] = { item[2] }
            }
            table.insert(tab, {Type = "DButton", Identifier = item[1], Require = item[5], Modifications = mod})
        end
    end

    BHDATA:Send(ply, "Admin", { "GUI", "Admin", tab })

    if AdminLoad.RequiresSteamInput then
        BHDATA:Send(ply, "Admin", {"GUIData", "Store", {"PlayerSteam", "Steam ID"} })
    end
end

function Admin:HandleClient(ply, args)
	local nID = tonumber(args[1])
	if nID == 1 then
		Admin:VIPPanelCall(ply, args)
	elseif nID == -1 then
		Admin:HandleRequest(ply, args)
	elseif nID == -2 then
		Admin:HandleButton(ply, args)
	end
end

-- Calls when a button is pressed
function Admin:HandleButton(ply, args)
	local ID, Steam = tonumber(args[2]), tostring(args[3])
	if not Admin:CanAccessID(ply, ID) then
		return BHDATA:Send(ply, "Print", {"Admin", "You don't have access to use this functionality." })
	end
	
	if ID == 1 then
		if Zones:CheckSet(ply, true, ply.ZoneExtra) then return end
		if Steam == "Extra" then ply.ZoneExtra = true end
		
		local tabQuery = {
			Caption = "What kind of zone do you want to set?",
			Title = "Select zone type"
		}

		for name,id in pairs(Zones.Type) do
			table.insert(tabQuery, { name, {ID, id} })
		end
		
		table.insert(tabQuery, {"Close", {}})
		
		if not ply.ZoneExtra then
			table.insert(tabQuery, { "Add Extra", {ID, -10 } })
		else
			table.insert(tabQuery, { "Stop Extra", {ID, -20 } })
		end
		
		BHDATA:Send(ply, "Admin", {"Query", tabQuery })
	elseif ID == 2 then
		if Zones:CheckSet(ply) then
			Zones:CancelSet(ply, true)
		else
			BHDATA:Send(ply, "Print", {"Admin", Lang:Get("ZoneNoEdit")})
		end
	elseif ID == 3 then
		local tabRequest = Admin:GenerateRequest("Enter the map points. This is the points value of the map", "Map Points", tostring(Timer.Multiplier), ID)
		BHDATA:Send( ply, "Admin", { "Request", tabRequest } )
	elseif ID == 5 then
		local tabRequest = Admin:GenerateRequest("Enter the map to change", "Change map", game.GetMap(), ID)
		BHDATA:Send( ply, "Admin", { "Request", tabRequest } )
	elseif ID == 6 then
		Zones:Reload()
		BHDATA:Send( ply, "Print", { "Admin", Lang:Get("AdminOperationComplete") })
	elseif ID == 8 then
		-- removes all admin access from the specified Steam ID
		SQL:Prepare(
			"DELETE FROM timer_admins WHERE steam = {0}",
			{Steam}
		):Execute(function(data, arg, error)
			if data then
				if IsValid(arg) then
					if arg:GetNWInt( "AccessIcon", 0 ) > 0 then
						arg:SetNWInt( "AccessIcon", 0 )
					end
					
					AdminLoad.Levels[arg:SteamID()] = arg.VIPLevel
				end
				
				BHDATA:Send(ply, "Print", { "Admin", Lang:Get("AdminOperationComplete") })
			else
				BHDATA:Send(ply, "Print", { "Admin", Lang:Get("AdminErrorCode", {error}) })
			end
		end, Admin:FindPlayer(Steam))
	elseif ID == 9 then
		local tabQuery = {
			Caption = "Which zone do you want to edit height of?",
			Title = "Select zone"
		}

		for _,zone in pairs(Zones.Entities) do
			if IsValid( zone ) then
				table.insert( tabQuery, { Zones:GetName(zone.zonetype) .. " (" .. zone:EntIndex() .. ")", { ID, zone:EntIndex() } } )
			end
		end
		
		table.insert(tabQuery, { "Close", {} })
		
		BHDATA:Send(ply, "Admin", { "Query", tabQuery})
	elseif ID == 10 then
		local tabQuery = {
			Caption = "Select the zone that you want to remove.",
			Title = "Remove zone"
		}
		
		for _,zone in pairs(Zones.Entities) do
			if IsValid(zone) then
				local extra = ""
				if zone.zonetype == Zones.Type.LegitSpeed then
					extra = " (" .. zone.speed .. ")"
				end
				
				table.insert(tabQuery, {Zones:GetName(zone.zonetype) .. " (" .. zone:EntIndex() .. ")" .. extra, { ID, zone:EntIndex()}})
			end
		end
		
		table.insert(tabQuery, { "Close", {} })
		
		BHDATA:Send(ply, "Admin", { "Query", tabQuery })
	elseif ID == 11 then
		local tabQuery = {
			Caption = "Please click map required options. Select values that you want to add.",
			Title = "Map options"
		}
		
		for name,zone in pairs(Zones.Options) do
			local szAdd = bit.band(Timer.Options, zone) > 0 and " (On)" or " (Off)"
			table.insert( tabQuery, { name .. szAdd, { ID, zone } } )
		end
		
		table.insert(tabQuery, { "Save", { ID, -1 } })
		table.insert(tabQuery, { "Cancel", {} })
		
		BHDATA:Send(ply, "Admin", { "Query", tabQuery})
	elseif ID == 13 then
		local target = Admin:FindPlayer(Steam)
		
		if IsValid( target ) then
			if Admin:IsHigherThan(target, ply, true) then
				return BHDATA:Send(ply, "Print", { "Admin", Lang:Get("AdminHierarchy")})
			end
			
			target.AdminMute = not target.AdminMute
			BHDATA:Broadcast("Manage", { "Mute", target:SteamID(), target.AdminMute})
			BHDATA:Send(ply, "Print", { "Admin", "You have " .. (target.AdminMute and "muted " or "unmuted ") .. target:Name() .. "!" } )
		else
			BHDATA:Send(ply, "Print", { "Admin", "Couldn't find a valid player with Steam ID: " .. Steam } )
		end
	elseif ID == 17 then
		if not ply.RemovingTimes then
			ply.RemovingTimes = true
			BHDATA:Send(ply, "Admin", { "Edit", ID } )
			BHDATA:Send(ply, "Print", { "Admin", "You are now editing times. Type !wr and select an item to remove it. Press this option again to disable it." } )
		else
			ply.RemovingTimes = nil
			BHDATA:Send(ply, "Admin", { "Edit", nil } )
			BHDATA:Send(ply, "Print", { "Admin", "You have left time editing mode." } )
		end
	elseif ID == 18 then
		local tabRequest = Admin:GenerateRequest( "Are you sure you want to remove a current Replay? Type the ID of the target style to confirm. (This cannot be un-done)", "Confirm removal", "No", ID )
		BHDATA:Send(ply, "Admin", { "Request", tabRequest } )
	elseif ID == 20 then
		RTV.CancelVote = not RTV.CancelVote
		BHDATA:Send(ply, "Print", { "Admin", "The map vote is now set to " .. (not RTV.CancelVote and "not " or "") .. "be cancelled!" } )
	elseif ID == 21 then
		local tabRequest = Admin:GenerateRequest( "Enter the bonus points. This is the points value of the bonus", "Bonus Points", tostring( Timer.BonusMultiplier ), ID )
		BHDATA:Send(ply, "Admin", { "Request", tabRequest } )
	elseif ID == 22 then
		local tabRequest = Admin:GenerateRequest( "Enter the name of the map to be removed.\nWARNING: This will remove all saved data of the map, including times!", "Completely remove map", "", ID )
		BHDATA:Send(ply, "Admin", { "Request", tabRequest } )
	elseif ID == 26 then
		Zones.Editor[ply].Steps = true
		
		local tabRequest = Admin:GenerateRequest( "Please enter the maximum speed the player will be able to get after entering this zone.\nNote: The player will keep this speed until entering a new zone.", "Enter speed limit for zone", "480", ID )
		BHDATA:Send(ply, "Admin", { "Request", tabRequest } )
	elseif ID == 27 then
		if ply.Spectating then
			return BHDATA:Send(ply, "Print", { "Admin", "You must be outside of spectator mode in order to change this setting in order to avoid suspicion."})
		end
		
		ply.Incognito = not ply.Incognito
		BHDATA:Send( ply, "Print", { "Admin", "Your incognito mode is now " .. (ply.Incognito and "enabled" or "disabled") } )
	elseif ID == 28 then
		local tabRequest = Admin:GenerateRequest( "Enter the ID of the style of which all times are to be removed.\nWARNING: This will remove all times permanently!", "Remove all times for mode", "No", ID )
		BHDATA:Send(ply, "Admin", { "Request", tabRequest})
	elseif ID == 32 then
		local now = ply:GetNWInt("AccessIcon", 0)
		if now > 0 then
			ply:SetNWInt("AccessIcon", 0)
		else
			local access = Admin:GetAccess( ply )
			if access >= Admin.Level.Base then
				Admin:SetAccessIcon(ply, access)
			end
		end
		
		BHDATA:Send(ply, "Print", { "Admin", "Your admin incognito mode is now " .. (now > 0 and "enabled" or "disabled")})
	end
end

-- responses from Derma requests or Queries
function Admin:HandleRequest(ply, args)
	local ID, Value = tonumber(args[2]), args[3]
	if ID != 17 then
		Value = tostring(Value)
	end
	
	if not Admin:CanAccessID(ply, ID, ID > 50) then
		return BHDATA:Send(ply, "Print", { "Admin", "You don't have access to use this functionality."})
	end
	
	if ID == 1 then
		local Type = tonumber(Value)
		if Type == -10 then
			return Admin:HandleButton(ply, { -2, ID, "Extra" })
		elseif Type == -20 then
			ply.ZoneExtra = nil
			return Admin:HandleButton(ply, { -2, ID })
		end
		
		Zones:StartSet( ply, Type )
	elseif ID == 3 then
		local Points = tonumber(Value)
		if not Points then
			return BHDATA:Send(ply, "Print", { "Admin", Lang:Get("AdminInvalidFormat", { Value, "Number" }) })
		end

		local mapName = MySQL:Escape(game.GetMap())
		local nOld = Timer.Multiplier or 0
		Timer.Multiplier = Points

		MySQL:Start("SELECT map FROM timer_map WHERE map = " .. mapName, function(result)
			if result and result[1] then
				MySQL:Start("UPDATE timer_map SET multiplier = " .. Timer.Multiplier .. " WHERE map = " .. mapName)
			else
				MySQL:Start("INSERT INTO timer_map (map, multiplier, bonusmultiplier, plays, options) VALUES (" .. mapName .. ", " .. Timer.Multiplier .. ", NULL, 0, NULL)")
			end
		end)

		for i = TIMER:GetStyleID("Normal"), TIMER:GetStyleID("Bonus") do
			TIMER:RecalculatePoints(i)
		end

		TIMER:LoadRecords()
		for _, p in pairs(player.GetHumans()) do
			TIMER:UpdateRank(p)
		end

		RTV:UpdateMapListVersion()

		BHDATA:Send(ply, "Print", { "Admin", Lang:Get("AdminSetValue", { "Multiplier", Timer.Multiplier }) })
		Admin:AddLog("Changed map points on " .. game.GetMap() .. " from " .. nOld .. " to " .. Points, ply:SteamID(), ply:Name())
	elseif ID == 5 then
		BHDATA:Unload()
		RunConsoleCommand("changelevel", Value)
	elseif ID == 9 then
		local index, find = tonumber(Value), false
		
		for _,zone in pairs(Zones.Entities) do
			if IsValid(zone) and zone:EntIndex() == index then
				ply.ZoneData = {zone.zonetype, zone.min, zone.max}
				find = true
				break
			end
		end
		
		if not find then
			BHDATA:Send(ply, "Print", { "Admin", "Couldn't find selected entity. Please try again."})
		else
			local nHeight = math.Round(ply.ZoneData[3].z - ply.ZoneData[2].z)
			local tabRequest = Admin:GenerateRequest( "Enter new desired height (Default is 128)", "Change height", tostring( nHeight ), 90 )
			BHDATA:Send(ply, "Admin", { "Request", tabRequest })
		end
	elseif ID == 90 then
		local nValue = tonumber(Value)
		if not nValue then
			return BHDATA:Send(ply, "Print", { "Admin", Lang:Get("AdminInvalidFormat", { Value, "Number" }) })
		end

		local OldPos1 = "'" .. util.TypeToString(ply.ZoneData[2]) .. "'"
		local OldPos2 = "'" .. util.TypeToString(ply.ZoneData[3]) .. "'"
    
		local nMin = ply.ZoneData[2].z
		ply.ZoneData[3].z = nMin + nValue

		local mapName = MySQL:Escape(game.GetMap())
		local newPos1 = MySQL:Escape(util.TypeToString(ply.ZoneData[2]))
		local newPos2 = MySQL:Escape(util.TypeToString(ply.ZoneData[3]))

		MySQL:Start("UPDATE timer_zones SET pos1 = " .. newPos1 .. ", pos2 = " .. newPos2 .. " WHERE map = " .. mapName .. " AND type = " .. ply.ZoneData[1] .. " AND pos1 = " .. OldPos1 .. " AND pos2 = " .. OldPos2 .. "", function(result)
			if result then
				UTIL:Notify(Color(0, 255, 0), "Database", "Zone updated successfully.")
			else
				UTIL:Notify(Color(255, 0, 0), "Database", "Failed to update zone.")
			end
		end)

		ReloadZonesOnMapLoad()
		BHDATA:Send(ply, "Print", { "Admin", Lang:Get("AdminOperationComplete") })
		elseif ID == 10 then
			local index, find, type = tonumber(Value), false, nil

			for _, zone in pairs(Zones.Entities) do
				if IsValid(zone) and zone:EntIndex() == index then
					if zone.zonetype == Zones.Type.LegitSpeed and zone.speed then
						zone.deltype = zone.zonetype .. zone.speed
					end

					local delType = zone.deltype or zone.zonetype
					local mapName = MySQL:Escape(game.GetMap())
					local pos1 = MySQL:Escape(util.TypeToString(zone.min))
					local pos2 = MySQL:Escape(util.TypeToString(zone.max))

					local query = "DELETE FROM timer_zones WHERE map = " .. mapName ..
					" AND type = " .. delType ..
					" AND pos1 = " .. pos1 ..
					" AND pos2 = " .. pos2 .. " LIMIT 1"

					MySQL:Start(query, function(result)
						if result then
							UTIL:Notify(Color(0, 255, 0), "Database", "Zone removed successfully.")
                    
							for k, v in pairs(Zones.Cache) do
								if v.Type == delType and v.P1 == zone.min and v.P2 == zone.max then
									Zones.Cache[k] = nil
								end
							end

							Zones:ClearEntities()
							Zones:Reload()

						else
							UTIL:Notify(Color(255, 0, 0), "Database", "Failed to remove zone.")
						end
					end)

					type = zone.zonetype
					find = true
					break
				end
			end

			if not find then
				BHDATA:Send(ply, "Print", {"Admin", "Couldn't find selected entity. Please try again."})
			else
				BHDATA:Send(ply, "Print", {"Admin", Lang:Get("AdminOperationComplete")})
				Admin:AddLog("Admin removed zone of type " .. Zones:GetName(nType), ply:SteamID(), ply:Name())
			end
		elseif ID == 11 then
			local nValue = tonumber(Value)
			if not nValue then
				return BHDATA:Send(ply, "Print", { "Admin", Lang:Get("AdminInvalidFormat", { Value, "Number" }) })
			end

			if nValue > 0 then
				local has = bit.band(Timer.Options, nValue) > 0
				Timer.Options = has and bit.band(Timer.Options, bit.bnot(nValue)) or bit.bor(Timer.Options, nValue)
				Zones:MapChecks()
				Admin:HandleButton(ply, { -2, ID })
			else
				local szValue = Timer.Options == 0 and "NULL" or Timer.Options
				local mapName = MySQL:Escape(game.GetMap())

				MySQL:Start("SELECT map FROM timer_map WHERE map = " .. mapName, function(Check)
					if Check and Check[1] then
						MySQL:Start("UPDATE timer_map SET options = " .. szValue .. " WHERE map = " .. mapName)
					else
						MySQL:Start("INSERT INTO timer_map (map, multiplier, options) VALUES (" .. mapName .. ", " .. Timer.Multiplier .. ", " .. szValue .. ")")
					end

					Admin:AddLog("Admin changed map options to " .. szValue, ply:SteamID(), ply:Name())
					BHDATA:Send(ply, "Print", { "Admin", Lang:Get("AdminSetValue", { "Options", Timer.Options }) })
				end)
			end
	elseif ID == 16 then
		local split = string.Explode(";", Value)
		if #split != 2 then
			return BHDATA:Send(ply, "Print", { "Admin", Lang:Get( "AdminMisinterpret", {Value})})
		end
		
		local target = Admin:FindPlayer(ply.AdminTarget)
		local length, reason, name = tonumber(split[1]), split[2], "Offline Player"
		
		if not nLength then
			return BHDATA:Send(ply, "Print", { "Admin", Lang:Get( "AdminInvalidFormat", { split[ 1 ], "Number" } ) })
		end
		
		if util.SteamIDTo64(ply.AdminTarget or "") == "0" then
			return BHDATA:Send(ply, "Print", { "Admin", Lang:Get( "AdminInvalidFormat", { ply.AdminTarget, "Steam ID" } ) })
		end
		
		if IsValid( target ) then
			name = target:Name()
			target.DCReason = "Banned by admin"
			target:Kick( "[Banned " .. (length == 0 and "permanently" or "for " .. length .. " minutes") .. "] Reason: " .. reason )
		end
		
		Admin:AddBan(ply.AdminTarget, name, length, reason, ply:SteamID(), ply:Name())
		Admin:AddLog("Admin banned player " .. ply.AdminTarget .. " (" .. length .. " mins) for reason: " .. reason, ply:SteamID(), ply:Name())
		
		if not IsValid(target) then
			name = ply.AdminTarget
		end
		
		BHDATA:Broadcast("Print", { "General", Lang:Get( "AdminPlayerBan", {name, length, reason} ) })
		BHDATA:Send(ply, "Print", { "Admin", "You have banned " .. name .. " for reason: " .. reason .. " (Length: " .. length .. ")" })
	elseif ID == 17 then
		ply.TimeRemoveData = Value
		local tabRequest = Admin:GenerateRequest("Are you sure you want to remove " .. Value[4] .. "'s #" .. Value[2] .. " time? (Type Yes to confirm)", "Confirm removal", "No", 170)
		BHDATA:Send( ply, "Admin", { "Request", tabRequest } )
	elseif ID == 170 then
		if Value ~= "Yes" then
			return BHDATA:Send(ply, "Print", { "Admin", "Time removal operation has been cancelled!"})
		end

		local d = ply.TimeRemoveData
		if not d then return end

		local style, Rank, uid = tonumber(d[1]), tonumber(d[2]), MySQL:Escape(tostring(d[3]))
		local mapName = MySQL:Escape(game.GetMap())

		MySQL:Start("DELETE FROM timer_times WHERE map = " .. mapName .. " AND style = " .. style .. " AND uid = " .. uid .. "", function()
			TIMER:LoadRecords()

			local i = Replay:GetInfo(style)
			if i and i.Style and i.SteamID and i.Style == style and i.SteamID == uid then
				MySQL:Start("DELETE FROM timer_replays WHERE map = " .. mapName .. " AND style = " .. style .. " AND uid = " .. uid .. "", function()
					if Replay:Exists(i.Style) then
						for _, b in pairs(player.GetBots()) do
							if b.Style == i.Style then
								b.DCReason = "Replay time was removed"
								b:Kick("Replay time was removed")
							end
						end
					end

					Replay:ClearStyle(style)

					local stylename = (style == TIMER:GetStyleID("Normal")) and ".txt" or ("_" .. style .. ".txt")
					local replayFilePath = "timer/replays/data_" .. game.GetMap() .. stylename
					if file.Exists(replayFilePath, "DATA") then
						file.Delete(replayFilePath)
					end
				end)
			end
		end)

		for _, p in pairs(player.GetHumans()) do
			if IsValid(p) and p:SteamID() == uid then
				TIMER:LoadBest(p)
				break
			end
		end

		ply.TimeRemoveData = nil
		BHDATA:Send(ply, "Print", { "Admin", d[4] .. "'s #" .. Rank .. " time has been deleted and records have been reloaded!" })
	elseif ID == 18 then
		local style = tonumber(Value)
		if not style then
			return BHDATA:Send(ply, "Print", { "Admin", "Replay removal operation has been cancelled!" })
		end

		if not BHDATA:IsValidStyle(style) then
			return BHDATA:Send(ply, "Print", { "Admin", "Invalid style entered!" })
		end

		local mapName = MySQL:Escape(game.GetMap())

		for _, b in pairs(player.GetBots()) do
			if b.Style == nStyle then
				b.DCReason = "Replay was deleted"
				b:Kick("Replay deleted")
			end
		end

		local stylename = (style == TIMER:GetStyleID("Normal")) and ".txt" or ("_" .. style .. ".txt")
		local replayFilePath = "timer/replays/data_" .. game.GetMap() .. stylename
		if file.Exists(replayFilePath, "DATA") then
			file.Delete(replayFilePath)
		end

		MySQL:Start("DELETE FROM timer_replays WHERE map = " .. mapName .. " AND style = " .. style, function()
			Replay:ClearStyle(style)
			BHDATA:Send(ply, "Print", { "Admin", "Replay for style " .. style .. " has been successfully removed!" })
		end)
	elseif ID == 19 then
		local frame = tonumber(Value)
		if not frame then
			return BHDATA:Send(ply, "Print", { "Admin", Lang:Get( "AdminInvalidFormat", { Value, "Number" } ) })
		end
		
		local tabData = Replay:GetFramePosition(ply.AdminBotStyle)
		if frame >= tabData[2] then
			frame = tabData[2] - 2
		elseif frame < 1 then
			frame = 1
		end
		
		local info = Replay:GetInfo(ply.AdminBotStyle)
		local current = (frame / tabData[ 2 ]) * info.Time
		info.Start = CurTime() - current
		
		Replay:SetInfoData(ply.AdminBotStyle, info)
		Replay:SetFramePosition(ply.AdminBotStyle, frame)
	elseif ID == 21 then
		local Points = tonumber(Value)
		if not Points then
			return BHDATA:Send(ply, "Print", { "Admin", Lang:Get("AdminInvalidFormat", { Value, "Number" }) })
		end

		local mapName = MySQL:Escape(game.GetMap())
		local old = Timer.BonusMultiplier or 0
		Timer.BonusMultiplier = Points

		MySQL:Start("SELECT map FROM timer_map WHERE map = " .. mapName, function(result)
			if result and result[1] then
				MySQL:Start("UPDATE timer_map SET bonusmultiplier = " .. Timer.BonusMultiplier .. " WHERE map = " .. mapName)
			else
				MySQL:Start("INSERT INTO timer_map (map, multiplier, bonusmultiplier, plays, options) VALUES (" .. mapName .. ", " .. Timer.Multiplier .. ", " .. Timer.BonusMultiplier .. ", 0, NULL)")
			end
		end)

		TIMER:RecalculatePoints(TIMER:GetStyleID("Bonus"))
		TIMER:LoadRecords()
		for _, p in pairs(player.GetHumans()) do
			TIMER:UpdateRank(p)
		end

		Admin:AddLog("Changed bonus multiplier on " .. game.GetMap() .. " from " .. old .. " to " .. Points, ply:SteamID(), ply:Name())
		BHDATA:Send(ply, "Print", { "Admin", Lang:Get("AdminSetValue", { "Bonus points", Timer.BonusMultiplier }) })
	elseif ID == 22 then
		if not RTV:MapExists(Value) then
			BHDATA:Send(ply, "Print", { "Admin", "The entered map '" .. Value .. "' is not on the nominate list, and thus cannot be deleted as it contains no info." })
		else
			local mapName = MySQL:Escape(Value)

			MySQL:Start("DELETE FROM timer_replays WHERE map = " .. mapName)
			MySQL:Start("DELETE FROM timer_map WHERE map = " .. mapName)
			MySQL:Start("DELETE FROM timer_times WHERE map = " .. mapName)
			MySQL:Start("DELETE FROM timer_zones WHERE map = " .. mapName)

			local basePath = "timer/replays/data_" .. Value .. ".txt"
			if file.Exists(basePath, "DATA") then
				file.Delete(basePath)
			end

			for i = 1, 8 do
				local stylePath = "timer/replays/data_" .. Value .. "_" .. i .. ".txt"
				if file.Exists(stylePath, "DATA") then
					file.Delete(stylePath)
				end
			end

			BHDATA:Send(ply, "Print", { "Admin", "All found info for '" .. Value .. "' has been deleted!" })
			Admin:AddLog("Fully removed map " .. Value, ply:SteamID(), ply:Name())
		end
	elseif ID == 26  then
		local nValue = tonumber(Value)
		if not nValue then
			return BHDATA:Send(ply, "Print", { "Admin", Lang:Get( "AdminInvalidFormat", { Value, "Number" } ) })
		end
		
		Zones:FinishSet(ply, nValue)
	elseif ID == 28 then
		local nStyle = tonumber(Value)
		if not nStyle then
			return BHDATA:Send(ply, "Print", { "Admin", "Time deletion operation has been cancelled!" })
		end
		
		if not BHDATA:IsValidStyle( nStyle ) then
			return BHDATA:Send(ply, "Print", { "Admin", "Invalid style entered!" } )
		end
		
		MySQL:Start("DELETE FROM timer_times WHERE map = '" .. game.GetMap() .. "' AND style = " .. nStyle)
		TIMER:LoadRecords()
		
		for _,p in pairs(player.GetHumans()) do
			if IsValid(p) then
				TIMER:LoadBest(p)
				break
			end
		end
	elseif ID == 29 then
		if Value == "" then
			return BHDATA:Send(ply, "Print", { "Admin", "Oborting notification because text was empty." })
		else
			Value = "[" .. Admin:GetAccessString( Admin:GetAccess( ply ) ) .. "] " .. ply:Name() .. ": " .. Value
		end
		
		if IsValid(ply.AdminTarget) then
			BHDATA:Send(ply.AdminTarget, "Admin", { "Message", Value })
		else
			BHDATA:Broadcast("Admin", { "Message", Value })
		end
		
		ply.AdminTarget = nil
	elseif ID == 30 then
		local target = Admin:FindPlayer(Value)
		
		if IsValid(target) then
			local source = Admin:FindPlayer(ply.AdminTarget)
			if not IsValid(source) then
				return BHDATA:Send(ply, "Print", { "Admin", "The source entity was lost or disconnected."})
			end
			
			source:SetPos(target:GetPos())
			BHDATA:Send(ply, "Print", { "Admin", source:Name() .. " has been teleported to " .. target:Name() })
		else
			BHDATA:Send(ply, "Print", { "Admin", "Couldn't find a valid target player with Steam ID: " .. Steam })
		end
	end
end

NETWORK:GetNetworkMessage("AdminSetRank", function(ply, data)
    if not IsValid(ply) or not ply:IsAdmin() then return end

    local szSteam = data[1]
    local szLevel = data[2]
    local nType = tonumber(2) or 1
    local nAccess = Admin.Level.None

    -- Find matching level by name
    for name, level in pairs(Admin.Level) do
        if string.lower(name) == string.lower(szLevel) then
            nAccess = level
            break
        end
    end

    if nAccess == Admin.Level.None then
        return BHDATA:Send(ply, "Print", { "Admin", Lang:Get("AdminMisinterpret", { szLevel }) })
    end

    local function UpdateAdminStatus(bUpdate, sqlArg, adminPly)
        local function UpdateAdminCallback(data, varArg, szError)
            local targetAdmin, targetData = varArg[1], varArg[2]

            if data then
                Admin:LoadAdmins()
                BHDATA:Send(targetAdmin, "Print", { "Admin", Lang:Get("AdminOperationComplete") })
                Admin:AddLog("Updated admin with identifier [" .. targetData[1] .. "] to level " .. targetData[2] .. " and type " .. targetData[3], targetAdmin:SteamID(), targetAdmin:Name())
            else
                BHDATA:Send(targetAdmin, "Print", { "Admin", Lang:Get("AdminErrorCode", { szError }) })
            end
        end

        if bUpdate then
            SQL:Prepare("UPDATE timer_admins SET level = {1}, type = {2} WHERE id = {0}", sqlArg)
            :Execute(UpdateAdminCallback, { adminPly, sqlArg })
        else
            SQL:Prepare("INSERT INTO timer_admins (steam, level, type) VALUES ({0}, {1}, {2})", sqlArg)
            :Execute(UpdateAdminCallback, { adminPly, sqlArg })
        end
    end

    SQL:Prepare("SELECT id FROM timer_admins WHERE steam = {0} ORDER BY level DESC LIMIT 1", { szSteam })
    :Execute(function(data, varArg, szError)
        local updateFunc, adminPly, sqlArg = varArg[1], varArg[2], varArg[3]
        local bUpdate = false

		if TIMER:Assert(data, "id") then
			bUpdate = true
			sqlArg[1] = data[1]["id"]
		end

        updateFunc(bUpdate, sqlArg, adminPly)
    end, { UpdateAdminStatus, ply, { szSteam, nAccess, nType } })
end)

NETWORK:GetNetworkMessage("AdminChangeMapMultiplier", function(ply, data)
    if not ply:IsAdmin() then
        ply:ChatPrint("You don't have permission to change the map multiplier!")
        return
    end

    local Points = data[1]

    if not Points or Points <= 0 then
        ply:ChatPrint("Invalid multiplier value!")
        return
    end

    local mapName = MySQL:Escape(game.GetMap())
    local nOld = Timer.Multiplier or 0
    Timer.Multiplier = Points

    MySQL:Start("SELECT map FROM timer_map WHERE map = " .. mapName, function(result)
        if result and result[1] then
            MySQL:Start("UPDATE timer_map SET multiplier = " .. Timer.Multiplier .. " WHERE map = " .. mapName)
        else
            MySQL:Start("INSERT INTO timer_map (map, multiplier, options) VALUES (" .. mapName .. ", " .. Timer.Multiplier .. ", NULL)")
        end
    end)

    for i = TIMER:GetStyleID("Normal"), TIMER:GetStyleID("Bonus") do
        TIMER:RecalculatePoints(i)
    end

    TIMER:LoadRecords()

    for _, p in pairs(player.GetHumans()) do
        TIMER:UpdateRank(p)
    end

    RTV:UpdateMapListVersion()

    BHDATA:Send(ply, "Print", { "Admin", "Map multiplier updated to " .. Timer.Multiplier })
    Admin:AddLog("Changed map multiplier on " .. game.GetMap() .. " from " .. nOld .. " to " .. Points, ply:SteamID(), ply:Name())
end)

NETWORK:GetNetworkMessage("RequestMapMultiplier", function(ply)
    if not ply:IsAdmin() then return end

    local currentMultiplier = Timer.Multiplier or 0
    NETWORK:StartNetworkMessage(ply, "ReceiveMapMultiplier", currentMultiplier)
end)

NETWORK:GetNetworkMessage("AdminHandleRequest", function(ply, data)
    local ID = data[1]
    local ZoneType = data[2]

    if ID == 1 then
        Admin:HandleRequest(ply, {-1, 1, ZoneType})
    end
end)

NETWORK:GetNetworkMessage("AdminChangeMap", function(ply, data)
    if not ply:IsAdmin() then
        return
    end

    local mapName = data[1]
    if not mapName or mapName == "" then return end
    if not file.Exists("maps/" .. mapName .. ".bsp", "GAME") then return end

    BHDATA:Unload()
    RunConsoleCommand("changelevel", mapName)
end)

local function SaveBans()
    UTIL:Notify(Color(0, 255, 0), "BanSystem", BanSystem .. "Bans are now saved to the database.")
end

local function LoadBans()
    Bans = { steam = {}, ip = {} }

    MySQL:Start("SELECT * FROM timer_bans", function(result)
        if not result then
            UTIL:Notify(Color(255, 0, 0), "BanSystem", BanSystem .. " Failed to load ban list from database.")
            return
        end

        for _, row in ipairs(result) do
            local banEntry = {
                reason = row.reason or "No reason",
                expires = tonumber(row.unban_time) or 0,
                admin = row.admin or "Console"
            }

            if row.steamid and row.steamid ~= "" then
                Bans.steam[string.upper(row.steamid)] = banEntry
            end

            if row.ip and row.ip ~= "" then
                Bans.ip[row.ip] = banEntry
            end
        end

        UTIL:Notify(Color(255, 0, 0), "BanSystem", BanSystem .. " Loaded " .. table.Count(Bans.steam) .. " SteamID bans and " .. table.Count(Bans.ip) .. " IP bans.")
    end)
end

local function IsPlayerBanned(steamID)
    steamID = string.upper(steamID)

    Bans.steam = Bans.steam or {}

    local banData = Bans.steam[steamID]
    if not banData then return false end

    if banData.expires == 0 then
        return true, banData.reason
    end

    if os.time() > banData.expires then
        Bans.steam[steamID] = nil
        SaveBans()
        return false
    end

    return true, banData.reason
end

local function IsPlayerCfgBanned(steamID)
    return BHOP.Banlist[steamID] or false
end

local function IsIPBanned(ip)
    if not ip then return false end

    Bans.ip = Bans.ip or {}

    local banData = Bans.ip[ip]
    if not banData then return false end

    if banData.expires == 0 then return true, banData.reason end

    if os.time() > banData.expires then
        Bans.ip[ip] = nil
        SaveBans()
        return false
    end

    return true, banData.reason
end

local function IsIPBanned(ip)
    local banData = Bans.ip[ip]
    if not banData then return false end

    if banData.expires == 0 then return true, banData.reason end

    if os.time() > banData.expires then
        Bans.ip[ip] = nil
        SaveBans()
        return false
    end

    return true, banData.reason
end

hook.Add("CheckPassword", "BanCheck", function(steamID64, ip, sv_password, cl_password, name)
    local steamID = util.SteamIDFrom64(steamID64)
    UTIL:Notify(Color(255, 0, 0), "BanSystem", (BanSystem .. " Checking ban status for SteamID: " .. steamID .. " | IP: " .. ip .. " | Name: " .. name))

    -- Check IP bans
    local isIPBanned, ipReason = IsIPBanned(ip)
    if isIPBanned then
        UTIL:Notify(Color(255, 0, 0), "BanSystem", BanSystem .. " IP " .. ip .. " is banned. Reason: " .. ipReason)
        return false, "You are banned from this server: " .. ipReason
    end

    -- Check config bans
	local banData = IsPlayerCfgBanned(steamID)
	if banData then
		UTIL:Notify(Color(255, 0, 0), "BanSystem", BanSystem .. " SteamID " .. steamID .. " is banned via config.")
		return false, "You are banned from this server: " .. banData.reason
	end

    -- Steam bans from live ban system
    local isSteamBanned, steamReason = IsPlayerBanned(steamID)
    if isSteamBanned then
        UTIL:Notify(Color(255, 0, 0), "BanSystem", BanSystem .. " SteamID " .. steamID .. " is banned. Reason: " .. steamReason)
        return false, "You are banned from this server: " .. steamReason
    end

    -- Server password check
    if sv_password ~= "" and cl_password ~= sv_password then
        UTIL:Notify(Color(255, 0, 0), "BanSystem", BanSystem .. " " .. name .. " failed password check!")
        return false, "Incorrect server password!"
    end

    return true
end)

local function BanPlayerBySteamID(steamID, length, reason, admin)
    steamID = string.upper(steamID)
    local adminName = IsValid(admin) and admin:Nick() or "Owner"
    local banTime = os.time()
    local unbanTime = length == 0 and 0 or banTime + length

    -- Cache in RAM
    Bans.steam[steamID] = {
        reason = reason,
        expires = unbanTime,
        admin = adminName
    }

    -- Insert into MySQL
    local q = string.format(
        "INSERT INTO timer_bans (steamid, reason, admin, ban_time, unban_time) VALUES ('%s', '%s', '%s', %d, %d)",
        MySQL:Escape(steamID),
        MySQL:Escape(reason),
        MySQL:Escape(adminName),
        banTime,
        unbanTime
    )

    MySQL:Start(q)

    UTIL:Notify(Color(255, 0, 0), "BanSystem", BanSystem .. "SteamID " .. steamID .. " has been banned for " .. length .. " seconds.")
end

local MAX_BAN_TIME = 315360000
local function BanIP(ip, length, reason, admin)
    if not ip or ip == "" then return end
    local adminName = IsValid(admin) and admin:Nick() or "Owner"

    if length > MAX_BAN_TIME then
        length = MAX_BAN_TIME
    end

    local banTime = length == 0 and 0 or os.time() + length

    Bans.ip[ip] = {
        reason = reason or "No reason provided",
        expires = banTime,
        admin = adminName
    }

    SaveBans()
	UTIL:Notify(Color(255, 0, 0), "BanSystem", BanSystem .. "IP " .. ip .. " has been banned for " .. length .. " seconds. Reason: " .. reason .. " by " .. adminName)
end

local function BanPlayer(ply, length, reason, admin)
    local steamID = ply:SteamID()
    local ip = ply:IPAddress():match("^(%d+%.%d+%.%d+%.%d+)")

    BanPlayerBySteamID(steamID, length, reason, admin)
    BanIP(ip, length, reason, admin)
    
    ply:Kick("Banned: " .. (reason or "No reason provided") .. " by " .. (IsValid(admin) and admin:Nick() or "Owner"))
end

local function UnbanPlayer(steamID)
    steamID = string.upper(steamID)

    if Bans.steam[steamID] then
        Bans.steam[steamID] = nil
        MySQL:Start("DELETE FROM timer_bans WHERE steamid = '" .. MySQL:Escape(steamID) .. "'")
        UTIL:Notify(Color(0, 255, 0), "BanSystem", BanSystem .. "Unbanned SteamID: " .. steamID)
    else
        UTIL:Notify(Color(255, 0, 0), "BanSystem", BanSystem .. "No ban found for SteamID: " .. steamID)
    end
end

local function UnbanIP(ip)
    if not ip or ip == "" then
		UTIL:Notify(Color(255, 0, 0), "BanSystem", BanSystem .. "ERROR: No IP provided to unban!")
        return
    end

    if Bans.ip[ip] then
        Bans.ip[ip] = nil
        SaveBans()
		UTIL:Notify(Color(255, 0, 0), "BanSystem", BanSystem .. "Unbanned IP: " .. ip)
    else
		UTIL:Notify(Color(255, 0, 0), "BanSystem", BanSystem .. "No IP ban found for " .. ip)
    end
end

concommand.Add("ban_player", function(ply, cmd, args)
    if #args < 2 then
		UTIL:Notify(Color(255, 0, 0), "BanSystem", BanSystem .. "Usage: ban_player <SteamID/Name> <length in minutes> <reason>")
        return
    end

    local target = args[1]
    local length = tonumber(args[2]) or 0
    local reason = table.concat(args, " ", 3) or "No reason provided"

    if string.match(target, "^STEAM_[0-5]:[01]:%d+$") then
        BanPlayerBySteamID(target, length * 60, reason, ply)
    else
        local targetPlayer = player.GetByName(target)
        if IsValid(targetPlayer) then
            BanPlayer(targetPlayer, length * 60, reason, ply)
        else
			UTIL:Notify(Color(255, 0, 0), "BanSystem", BanSystem .. "Player not found.")
        end
    end
end)

concommand.Add("ban_ip", function(ply, cmd, args)
    if #args < 2 then
		UTIL:Notify(Color(255, 0, 0), "BanSystem", BanSystem .. "Usage: ban_ip <IP> <length in minutes> <reason>")
        return
    end
    BanIP(args[1], tonumber(args[2]) * 60, table.concat(args, " ", 3), ply)
end)

concommand.Add("unban_player", function(_, _, args)
    local steamID = args[1]

    if not steamID or steamID == "" then
		UTIL:Notify(Color(255, 0, 0), "BanSystem", BanSystem .. "Usage: unban_player <SteamID>")
        return
    end

    UnbanPlayer(steamID)
end)

concommand.Add("unban_ip", function(_, _, args)
    local ip = args[1]

    if not ip then
		UTIL:Notify(Color(255, 0, 0), "BanSystem", BanSystem .. "Usage: unban_ip <IP>")
        return
    end

    UnbanIP(ip)
end)

concommand.Add("kick_player", function(pl, cmd, args)
    if not IsValid(pl) or not pl:IsAdmin() then
        if IsValid(pl) then UTIL:Notify(Color(255, 0, 0), "BanSystem", BanSystem .. "You do not have permission to use this command.") end
        return
    end

    if #args < 1 then
        pl:ChatPrint("Usage: kick_player <SteamID/Name> [reason]")
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
        UTIL:Notify(Color(255, 0, 0), "BanSystem", "Player not found.")
    end
end)

hook_Add("Initialize", "LoadBansOnStart", function()
    LoadBans()
end)

hook_Add("ShutDown", "SaveBansOnShutdown", function()
    SaveBans()
end)

hook.Add("PlayerInitialSpawn", "CheckBannedPlayer", function(ply)
    timer.Simple(3, function()
        if not IsValid(ply) then return end

        local steamID = ply:SteamID()
        local ip = ply:IPAddress() and ply:IPAddress():match("^(%d+%.%d+%.%d+%.%d+)") or "0.0.0.0"

        local isSteamBanned, steamReason = IsPlayerBanned(steamID)
        if isSteamBanned then
            ply:Kick("You are banned from this server: " .. steamReason)
            return
        end

        local isIPBanned, ipReason = IsIPBanned(ip)
        if isIPBanned then
            ply:Kick("You are banned from this server: " .. ipReason)
            return
        end
    end)
end)