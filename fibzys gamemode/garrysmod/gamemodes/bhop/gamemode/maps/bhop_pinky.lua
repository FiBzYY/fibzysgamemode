__HOOK[ "InitPostEntity" ] = function()

	for _,ent in pairs( ents.FindByClass( "func_button" ) ) do

		if ent:GetPos() == Vector( -189, -262, 68 ) then
			ent:Remove()
		end
	end
end