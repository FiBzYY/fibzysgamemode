local Trailing = {}

Trailing.Protocol = util.AddNetworkString( "Trailer" )
Trailing.PointSize = Vector( 1, 1, 1 ) / 2
Trailing.LoadedStyles = {}

function Trailing.HideAllFromPlayer( ply, manual )
	for _,ent in pairs( ents.FindByClass( "game_point" ) ) do
		ent:SetPreventTransmit( ply, true )
	end

	if manual then
		net.Start( "Trailer" )
		net.WriteUInt( 0, 8 )
		net.Send( ply )
	end
end
hook.Add( "PlayerInitialSpawn", "PreventEntityTransmission", Trailing.HideAllFromPlayer )

function Trailing.CreateOnStyle( ply, nStyle )
	local ox, _, _, _, _, info = Replay.HandleSpecialBot( nil, "Fetch", nil, nStyle )
	if not ox or not info then return end

	-- Check if they're already spawned
	local fr = info and info.Time and #ox / info.Time or 0
	if info.Time and info.Time == Trailing.LoadedStyles[ nStyle ] then
		-- Make sure they can really load
		for _,ent in pairs( ents.FindByClass( "game_point" ) ) do
			if ent.style == nStyle then
				ent:SetPreventTransmit( ply, false )
			end
		end

		-- And update the style
		net.Start( "Trailer" )
		net.WriteUInt( nStyle, 8 )
		net.WriteUInt( 0, 12 )
		net.WriteDouble( fr )
		net.Send( ply )

		-- Also success! But differently
		return 1
	end

	-- Remove existing game_point entities by the same style
	for _,ent in pairs( ents.FindByClass( "game_point" ) ) do
		if ent.style == nStyle then
			ent:Remove()
		end
	end

	-- Loop over the table in steps of 100
	for i = 1, #ox, 100 do
		-- Creates the entity
		local ent = ents.Create( "game_point" )
		ent:SetPos( Vector( ox[ i ][1], ox[ i ][2], ox[ i ][3] ) )
		ent.min = ent:GetPos() - Trailing.PointSize
		ent.max = ent:GetPos() + Trailing.PointSize
		ent.style = nStyle
		ent.id = i
		ent.neighbors = {}

		-- Set the point velocity
		if info and info.Time and ox[ i + 1 ] then
			ent.vel = (Vector( ox[ i + 1 ][1], ox[ i + 1 ][2], ox[ i + 1 ][3] ) - ent:GetPos()) * fr
		end

		-- Get the neighbors
		for j = i + 10, i + 90, 10 do
			if ox[ j ] then
				ent.neighbors[ #ent.neighbors + 1 ] = Vector( ox[ j ][1], ox[ j ][2], ox[ j ][3] )
			end
		end

		-- And create it
		ent:Spawn()
	end

	-- And hide the newly created entities from everyone
	local list = ents.FindByClass( "game_point" )
	for _,p in pairs( player.GetHumans() ) do
		if p != ply then
			for _,ent in pairs( list ) do
				ent:SetPreventTransmit( p, true )
			end
		end
	end

	-- Allow the points to be drawn
	net.Start( "Trailer" )
	net.WriteUInt( nStyle, 8 )
	net.WriteUInt( 0, 12 )
	net.WriteDouble( fr )
	net.Send( ply )

	-- Save the loaded values
	Trailing.LoadedStyles[ nStyle ] = info.Time

	-- Success!
	return 0
end

function Trailing.MainCommand( ply, args )
	if !args or (#args == 0) then
		Core:Send(ply, "Print", {"Timer", "Vous devez fournir un nom de Style ou un Style ID pour pouvoir l'utiliser."})
	return end

	local textFormat = string.lower(tostring(args[1]))
	if (textFormat == "hide") then
		Trailing.HideAllFromPlayer( ply, true )
    Core:Send(ply, "Print", {"Timer", "Tous les Replay trails ont été masquées"})
	return end

	local styleID = tonumber(args[1])
  local convertedArgs = table.concat(args, " ")
	if styleID and !TIMER:IsValidStyle(styleID) then
    return Core:Send(ply, "Print", {"Timer", "Le Style ID fourni n'est pas valide, veuillez fournir un valide Style ID ou nom pour l'utiliser."})
  elseif convertedArgs and !TIMER:GetStyleID(convertedArgs) then
    return Core:Send(ply, "Print", {"Timer", "Le nom de Style fourni n'est pas valide, veuillez fournir un valide Style ID ou nom pour l'utiliser."})
	end

	if !styleID and convertedArgs then
		styleID = TIMER:GetStyleID(convertedArgs)
	end

	local res = Trailing.CreateOnStyle( ply, styleID )
	if (res == 0) then
    Core:Send(ply, "Print", {"Timer", "Le trail du Replay " .. TIMER:StyleName(styleID) .. " a été généré et est maintenant affiché"})
	elseif (res == 1) then
    Core:Send(ply, "Print", {"Timer", "Le trail du Replay " .. TIMER:StyleName(styleID) .. " a été affiché"})
	else
    Core:Send(ply, "Print", {"Timer", "Il ne semble pas y avoir de rediffusion ou de trail disponible pour ce style, veuillez réessayer plus tard"})
	end
end

Command:Register({"trail", "trailbot", "bottrail", "botroute", "routecopy", "route", "router", "routing", "path", "botpath"}, Trailing.MainCommand)