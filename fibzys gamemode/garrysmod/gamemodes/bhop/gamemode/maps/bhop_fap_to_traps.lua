__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs( ents.FindByClass( "ambient_generic" ) ) do
		ent:Remove()
	end
end