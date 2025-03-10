__HOOK[ "InitPostEntity" ] = function()
	TIMER:SetLeftBypass( true )

	for _,ent in pairs( ents.FindByClass( "ambient_generic" ) ) do
		ent:Remove()
	end
end