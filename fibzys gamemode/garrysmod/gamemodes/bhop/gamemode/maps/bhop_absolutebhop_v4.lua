__HOOK[ "InitPostEntity" ] = function()

	for _,ent in pairs( ents.FindByClass( "func_door" ) ) do
		if ent:GetName() == "ture" then
			ent:Remove()
		end
	end
end