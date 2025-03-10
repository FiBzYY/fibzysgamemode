__HOOK[ "InitPostEntity" ] = function()

	for _,ent in pairs( ents.FindByClass( "trigger_multiple" ) ) do
		if ent:GetPos() == Vector( -64, -147, 61 ) or ent:GetPos() == Vector( -64, -288, 61 ) then
			ent:Remove()
		end
	end

	for _,ent in pairs( ents.FindByClass( "env_entity_maker" ) ) do
		ent:Remove()
	end
end