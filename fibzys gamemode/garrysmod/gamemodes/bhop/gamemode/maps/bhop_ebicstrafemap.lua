__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs( ents.FindByClass( "env_fire_tiny_smoke" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "env_smokestack" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "prop_physics" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "prop_static" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "env_cubemap" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "water_lod_control" ) ) do
		ent:Remove()
	end
end