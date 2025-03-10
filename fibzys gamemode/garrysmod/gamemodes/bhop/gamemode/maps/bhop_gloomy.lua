local poles = {

	Vector( 65, 1842, -3 ),
	Vector( 180, 1778, -3 ),
	Vector( 292, 1737, -3 ),
	Vector( 413, 1710.01, -3 ),
	Vector( 551, 1712, -3 ),
	Vector( 659.44, 1757.48, -3 ),
	Vector( 750, 1823, -3 ),
	Vector( 846, 1905, -3 ),
	Vector( 977, 1905, -3 )

}

__HOOK[ "InitPostEntity" ] = function()

	for _,ent in pairs( ents.FindByClass( "func_breakable" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "trigger_once" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "weapon_scout" ) ) do
		ent:Remove()
	end

	local index = IndexPlatform
	local plats = BHDATA.GetMapVariable( "Platforms" )
	plats.NoWipe = true

	for _,ent in pairs( ents.FindByClass( "func_door" ) ) do
		if string.find( ent:GetName(), "move1" ) then
			ent:Remove()
		end

		if not table.HasValue( poles, ent:GetPos() ) then continue end

		ent:Fire( "Lock" )
		ent:SetKeyValue( "spawnflags", "1024" )
		ent:SetKeyValue( "speed", "0" )
		ent:SetRenderMode( RENDERMODE_TRANSALPHA )

		if ent.BHS then
			ent:SetKeyValue( "locked_sound", ent.BHS )
		else
			ent:SetKeyValue( "locked_sound", "DoorSound.DefaultMove" )
		end

		local nid = ent:EntIndex()
		index( nid )
		plats[ #plats + 1 ] = nid
	end
end

local sf, sl, tn = string.find, string.lower, tonumber
__HOOK[ "EntityKeyValue" ] = function( ent, key, value )

	if ent:GetClass() == "func_rotating" then
		if sf( sl( key ), "maxspeed" ) then
			return "0"
		elseif sf( sl( key ), "fanfriction" ) then
			return "0"
		elseif sf( sl( key ), "spawnflags" ) then
			return "1024"
		end
	end
end