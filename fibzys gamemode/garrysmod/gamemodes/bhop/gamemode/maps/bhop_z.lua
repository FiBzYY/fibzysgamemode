__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs( ents.FindByClass( "sky_camera" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "func_dustmotes" ) ) do
		ent:Remove()
	end	
end