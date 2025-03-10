__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs( ents.FindByClass( "func_dustmotes" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "env_smokestack" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "water_lod_control" ) ) do
		ent:Remove()
	end	
end