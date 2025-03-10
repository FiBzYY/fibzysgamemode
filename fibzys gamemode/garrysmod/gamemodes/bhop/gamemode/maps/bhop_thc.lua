local teles = {
	Vector( -6315, 7093, 75.5 ),
	Vector( -7006, 7059, 80 ),
	Vector( -7477, 7067, 80 ),
	Vector( -8199, 7151, 80 )
}

local movers = {
	Vector( -6315, 7093, 75.5 ),
	Vector( -7006, 7059, 80 ),
	Vector( -7477, 7067, 80 ),
	Vector( -8199, 7151, 80 ),
	Vector( -8707, 7090, 18 )
}

__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if table.HasValue( teles, ent:GetPos() ) then
			ent:Remove()
		end
	end

	for _,ent in pairs( ents.FindByClass( "func_movelinear" ) ) do
		if table.HasValue( movers, ent:GetPos() ) then
			ent:Remove()
		end
	end

	for _,ent in pairs( ents.FindByClass( "path_track" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "env_laser" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "func_tanktrain" ) ) do
		ent:Remove()
	end
end