__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs( ents.FindByClass( "sky_camera" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "func_wall_toggle" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "env_sprite" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "prop_dynamic" ) ) do
		ent:Remove()
	end
	
	for _,ent in pairs( ents.FindByClass( "logic_timer" ) ) do
		ent:Remove()
	end
	
	for _,ent in pairs( ents.FindByClass( "logic_case" ) ) do
		ent:Remove()
	end

end