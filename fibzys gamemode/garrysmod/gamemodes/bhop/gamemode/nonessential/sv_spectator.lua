Spectator = {}
Spectator.Modes = {
	OBS_MODE_IN_EYE,
	OBS_MODE_CHASE,
	OBS_MODE_ROAMING
}

local AFK = {}
local afkMinutes = 25
local afkKickMinutes = 999
local adminBypass = false
local adminNotify = false
local hook_Add = hook.Add

hook_Add("PlayerInitialSpawn", "AFKSpawn", function(ply)
    ply.AFK = {
        Away = false,
        LastActivity = CurTime()
    }
end)

hook_Add("PlayerSay", "PlayerTyped", function(ply)
    ply.AFK.LastActivity = CurTime()
    if ply.AFK.Away then
        AFK:SetAFK(ply, false)
    end
end)

hook_Add("KeyPress", "KeyPressed", function(ply)
    ply.AFK.LastActivity = CurTime()
    if ply.AFK.Away then
        AFK:SetAFK(ply, false)
    end
end)

local function IsImmune(ply)
    return adminBypass and Admin and Admin.CanAccess and Admin:CanAccess(ply, Admin.Level.Moderator)
end

function AFK:SetAFK(ply, afk)
    ply.AFK.Away = afk
    ply:SetNWBool("afk", afk)

    if afk then
		NETWORK:StartNetworkMessageTimer(ply, "Print", { "RTV", "You are AFK." })
    else
		NETWORK:StartNetworkMessageTimer(ply, "Print", { "RTV", "You are no longer AFK." })
    end
end

function AFK:CheckAFK()
    for _, ply in ipairs(player.GetHumans()) do
        local idleTime = CurTime() - ply.AFK.LastActivity
        if not ply.AFK.Away and not IsImmune(ply) and idleTime > (afkMinutes * 60) then
            print(ply:Nick() .. " idle for " .. idleTime .. "s, marking AFK.")
            AFK:SetAFK(ply, true)
        end
    end

    RTV:CheckVotes()
end

function AFK:KickAFK()
    if player.GetCount() < game.MaxPlayers() then return end

    for _, ply in ipairs(player.GetHumans()) do
        local idleTime = CurTime() - ply.AFK.LastActivity
        if ply.AFK.Away and not IsImmune(ply) and idleTime > (afkKickMinutes * 60) then
            ply:Kick("You were kicked from the server for being AFK too long")
        end
    end
end

local function AFKController()
    AFK:CheckAFK()
    AFK:KickAFK()
end
timer.Create("AFKTimer", 60, 0, AFKController)

function Spectator:GetAFK()
    local tab = {}

    for _,ply in ipairs(player.GetHumans()) do
        if ply.AFK.Away then
            table.insert(tab, ply)
        end
    end

    return #tab
end

local function GetAlive()
    local d = {}

    for k,v in pairs(player.GetAll()) do
        if v:Team() == 1 and v:Alive() then
            table.insert(d, v)
        end
    end

    return d
end

local function PlayerPressKey(ply, key)
	if not IsValid( ply ) then return end
	if ply:IsBot() then return end

	if ply:Team() != TEAM_SPECTATOR then return end

	if not ply.SpectateID then ply.SpectateID = 1 end
	if not ply.SpectateType then ply.SpectateType = 1 end
	if key == IN_ATTACK then
		local ar = GetAlive()
		ply.SpectateType = 1
		ply.SpectateID = ply.SpectateID + 1
		Spectator:Mode( ply, true )
		Spectator:Change( ar, ply, true )
	elseif key == IN_ATTACK2 then
		local ar = GetAlive()
		ply.SpectateType = 1
		ply.SpectateID = ply.SpectateID - 1
		Spectator:Mode( ply, true )
		Spectator:Change( ar, ply, false )
	elseif key == IN_RELOAD then
		local ar = GetAlive()
		if #ar == 0 then
			ply.SpectateType = #Spectator.Modes
			Spectator:Mode( ply, true )
		else
			local bRespec = ply.SpectateType == #Spectator.Modes
			ply.SpectateType = ply.SpectateType + 1 > #Spectator.Modes and 1 or ply.SpectateType + 1
			Spectator:Mode( ply, nil, bRespec )
		end
	end
end
hook_Add("KeyPress", "SpectatorKey", PlayerPressKey)

function Spectator:Change(ar, ply, forward)
	local previous = ply:GetObserverTarget()
	
	if #ar == 1 then
		ply.SpectateID = forward and ply.SpectateID - 1 or ply.SpectateID + 1
		return
	end

	if not ar[ply.SpectateID] then
		ply.SpectateID = forward and 1 or #ar
		if not ar[ ply.SpectateID ] then
			return Command.Spectate( ply )
		end
	end

	ply:SpectateEntity( ar[ply.SpectateID] )
	Spectator:Checks(ply, previous)
end

function Spectator:Mode(ply, cancel, respec)
    if not IsValid(ply) then
        return
    end

    if not Spectator.Modes[ply.SpectateType] then
        return
    end

    if not ply:Alive() and ply:Team() ~= TEAM_SPECTATOR then
        ply:SetTeam(TEAM_SPECTATOR)
    end

    if not ply.Spectate then
        return
    end

    ply:Spectate(Spectator.Modes[ply.SpectateType])
    BHDATA:Send(ply, "Spectate", {"Mode", ply.SpectateType })

    if ply.SpectateType ~= #Spectator.Modes and respec then
        Spectator:Checks(ply)
    end
end

function Spectator:End(ply, watching)
	if not IsValid( watching ) or ply.Incognito then return end
	Spectator:Notify( watching, ply, true )
	Spectator:NotifyWatchers( watching, ply )
end

function Spectator:New(ply)
	local ar = GetAlive()
	if #ar == 0 then
		ply.SpectateType = #Spectator.Modes
		Spectator:Mode(ply, true)
	else
		ply.SpectateType = 1
		
		if not ply.SpectateID then ply.SpectateID = 1 end
		if not ar[ ply.SpectateID ] then ply.SpectateID = 1 end
		
		ply:Spectate( Spectator.Modes[ ply.SpectateType ] )
		ply:SpectateEntity( ar[ ply.SpectateID ] )
		BHDATA:Send( ply, "Spectate", { "Mode", ply.SpectateType } )
		Spectator:Checks( ply )
	end
end

function Spectator:NewById(ply, szSteam, bSwitch, szName)
	local ar = GetAlive()
	local target = { ID = nil, Ent = nil }
	local bBot = szSteam == "NULL"
	
	for id,p in pairs( ar ) do
		if (bBot and p:IsBot() and szName and p:Name() == szName) or (tostring( p:SteamID() ) == tostring( szSteam )) then
			target.Ent = p
			target.ID = id
			break
		end
	end
	
	if target.Ent then
		local previous = bSwitch and ply:GetObserverTarget() or nil
		
		ply.SpectateType = 1
		ply.SpectateID = target.ID
		ply:Spectate( Spectator.Modes[ ply.SpectateType ] )
		ply:SpectateEntity( target.Ent )
		BHDATA:Send( ply, "Spectate", { "Mode", ply.SpectateType } )
		
		Spectator:Checks( ply, previous )
	else
		BHDATA:Send( ply, "Print", { "Spectator", Lang:Get( "SpectateTargetInvalid" ) } )
	end
end

function Spectator:Checks( ply, previous )
	if ply.Incognito then
		local target = ply:GetObserverTarget()
		if IsValid( target ) then
			return Spectator:NotifyWatchers( target )
		else
			return false
		end
	end

	local current = ply:GetObserverTarget()
	if IsValid(current) then
		if current:IsBot() then
			Spectator:NotifyBot(current)
		else
			Spectator:Notify(current, ply)
		end
	end

	if IsValid(previous) then
		Spectator:Notify(previous, ply, true)
	end
end

function Spectator:Notify(target, ply, bLeave)
	if bLeave then
		Spectator:NotifyWatchers(target)
		return BHDATA:Send(target, "Spectate", { "Viewer", true, ply:Name(), ply:SteamID()})
	else
		BHDATA:Send(target, "Spectate", {"Viewer", false, ply:Name(), ply:SteamID()})
	end
	
	Spectator:NotifyWatchers(target)
end

function Spectator:NotifyBot(Replay)
    Spectator:NotifyWatchers(Replay)
end

function Spectator:PlayerRestart(ply)
	local nTimer = ply.bonustime or ply.time

	local Watchers = {}
	for _, p in ipairs(player.GetHumans()) do
		if p.Spectating and not p.Incognito and p:GetObserverTarget() == ply then
			table.insert(Watchers, p)
		end
	end

	BHDATA:Send(Watchers, "Spectate", {
		"Timer",
		false,
		nTimer,
		(ply.record and ply.record > 0) and ply.record or nil,
		CurTime(),
		"Save"
	})
	
	ply.Watchers = Watchers
end

function Spectator:NotifyWatchers(ply, ending)
	local SpectatorList, Watchers, Incognitos = {}, {}, {}

	for _, p in ipairs(player.GetHumans()) do
		if not p.Spectating or (IsValid(ending) and p == ending) then continue end
		
		local ob = p:GetObserverTarget()
		if IsValid(ob) and ob == ply then
			if p.Incognito then
				table.insert(Incognitos, p)
			else
				table.insert(Watchers, p)
				table.insert(SpectatorList, p:Name())
			end
		end
	end

	if #SpectatorList == 0 then SpectatorList = nil end

	local nTimer = ply.bonustime or ply.time
	local data

	if ply:IsBot() then
		data = Replay:GenerateNotify(ply.Style, SpectatorList)
		if not data then return end
	else
		data = { "Timer", false, nTimer, (ply.record and ply.record > 0) and ply.record or nil, CurTime(), SpectatorList }
	end

	if #Watchers > 0 then
		BHDATA:Send(Watchers, "Spectate", data)
	end

	if #Incognitos > 0 then
		BHDATA:Send(Incognitos, "Spectate", data)
	end

	ply.Watchers = Watchers
end

function Spectator:GetAlive()
	return GetAlive()
end