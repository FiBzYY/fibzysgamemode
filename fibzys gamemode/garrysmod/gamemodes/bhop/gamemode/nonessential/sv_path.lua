-- DO TO:

local Trailing = {}
Trailing.Protocol = util.AddNetworkString( "Trailer" )
Trailing.PointSize = Vector( 1, 1, 1 ) / 2
Trailing.LoadedStyles = {}

util.AddNetworkString( "Trailer" )

function Trailing.HideAllFromPlayer( ply, manual )
	for _,ent in pairs( ents.FindByClass( "ent_point" ) ) do
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
	local ox, _, _, _, _, info = Replay.HandleSpecialBot(nil, "Fetch", nil, nStyle)

	print("[CreateOnStyle] Got data?", ox and "✅" or "❌", "| Style:", nStyle)

	if info then
		PrintTable(info)
	else
		print("[CreateOnStyle] ❌ No Replay Info found.")
	end

	if not ox or not info then return end

	-- Check if they're already spawned
	local fr = info and info.Time and #ox / info.Time or 0
	print("[CreateOnStyle] Calculated Frame Ratio (fr):", fr)

	if info.Time and info.Time == Trailing.LoadedStyles[ nStyle ] then
		-- Make sure they can really load
		for _,ent in pairs( ents.FindByClass( "ent_point" ) ) do
			if ent.Style == nStyle then
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
	for _,ent in pairs( ents.FindByClass( "ent_point" ) ) do
		if ent.Style == nStyle then
			ent:Remove()
			print("test")
		end
	end

	-- Loop over the table in steps of 100
	for i = 1, #ox, 100 do
		-- Creates the entity
		local ent = ents.Create( "ent_point" )
		ent:SetPos( Vector( ox[ i ][1], ox[ i ][2], ox[ i ][3] ) )
		ent.min = ent:GetPos() - Trailing.PointSize
		ent.max = ent:GetPos() + Trailing.PointSize
		ent.Style = nStyle
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
	local list = ents.FindByClass( "ent_point" )
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

function Trailing.MainCommand(ply, args)
    if not args or #args == 0 then
        return NETWORK:StartNetworkMessageTimer(ply, "Print", {
            "Timer",
            "Vous devez fournir un nom de Style ou un Style ID pour pouvoir l'utiliser."
        })
    end

    local argStr = string.Trim(tostring(args[1])):lower()

    if argStr == "hide" then
        Trailing.HideAllFromPlayer(ply, true)
        return NETWORK:StartNetworkMessageTimer(ply, "Print", {
            "Timer",
            "Tous les trails des bots ont été masqués."
        })
    end

    local styleID = tonumber(argStr)
    if styleID and not TIMER:IsValidStyle(styleID) then
        return NETWORK:StartNetworkMessageTimer(ply, "Print", {
            "Timer",
            "Le Style ID fourni n'est pas valide. Essayez un autre ID ou nom de style."
        })
    end

    if not styleID then
        styleID = TIMER:GetStyleID(argStr)
        if styleID == 0 then
            return NETWORK:StartNetworkMessageTimer(ply, "Print", {
                "Timer",
                "Le nom de style est invalide. Essayez un style existant comme 'hsw' ou 'normal'."
            })
        end
    end

    local res = Trailing.CreateOnStyle(ply, styleID)
    local styleName = TIMER:StyleName(styleID)

    if res == 0 then
        NETWORK:StartNetworkMessageTimer(ply, "Print", {
            "Timer",
            "Trail du bot **" .. styleName .. "** généré et affiché."
        })
    elseif res == 1 then
        NETWORK:StartNetworkMessageTimer(ply, "Print", {
            "Timer",
            "Trail du bot **" .. styleName .. "** déjà généré, il vient d'être affiché."
        })
    else
        NETWORK:StartNetworkMessageTimer(ply, "Print", {
            "Timer",
            "Aucune rediffusion trouvée pour le style **" .. styleName .. "**. Réessayez plus tard."
        })
    end
end

Command:Register(
    {"trail"},
    Trailing.MainCommand
)