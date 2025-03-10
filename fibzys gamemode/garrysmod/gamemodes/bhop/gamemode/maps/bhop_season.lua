__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "func_door" ) ) do
		v:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "func_dustmotes" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "prop_static" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "prop_dynamic" ) ) do
		ent:Remove()
	end
end