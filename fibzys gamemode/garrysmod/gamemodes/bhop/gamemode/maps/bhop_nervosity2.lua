__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs( ents.FindByClass( "func_brush" ) ) do
		ent:Remove()
	end
end