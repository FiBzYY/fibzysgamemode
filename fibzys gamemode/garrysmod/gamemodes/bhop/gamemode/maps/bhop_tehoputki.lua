__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs( ents.FindByClass( "env_soundscape" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "func_dustmotes" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "func_dustcloud" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "func_smokevolume" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "point_spotlight" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "func_rotating" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "env_lightglow" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "prop_static" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "light_spot" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "env_cubemap" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "move_rope" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "water_lod_control" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "env_smokestack" ) ) do
		ent:Remove()
	end
end