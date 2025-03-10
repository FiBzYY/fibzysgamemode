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
end