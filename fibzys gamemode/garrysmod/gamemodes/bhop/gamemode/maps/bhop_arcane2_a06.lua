__HOOK[ "InitPostEntity" ] = function()

	for _,ent in pairs( ents.FindByClass( "func_illusionary" ) ) do
		if ent:GetPos() == Vector( -15368, 14720, 15424 ) then
			ent:Remove()
		end
	end
end