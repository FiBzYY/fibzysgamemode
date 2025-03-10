__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs( ents.FindByClass( "prop_dynamic" ) ) do
		ent:Remove()
	end
end