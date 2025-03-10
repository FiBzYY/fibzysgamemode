__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs( ents.FindByClass( "game_player_equip" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "trigger_multiple" ) ) do
		if ent:GetPos() == ent:GetPos() == Vector( 1528, -712, 147 ) then
			ent:Remove()
		end
	end

	for _,ent in pairs( ents.FindByClass( "trigger_multiple" ) ) do
		if ent:GetPos() == Vector( -264, 384, 232 ) or ent:GetPos() == Vector( 2304, -256, 512 ) then
			ent:Remove()
		end
	end

	for _,ent in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if ent:GetPos() == Vector( -58.49, 267, 129 ) or ent:GetPos() == Vector( 2327.47, -32.36, 417 ) then
			ent:Remove()
		end
	end

	for _,ent in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if ent:GetPos() == Vector( 1528, -712, 145) then
			ent:Remove()
		end
	end
end