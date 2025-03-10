__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs( ents.FindByClass( "game_player_equip" ) ) do
		ent:Remove()
	end
end