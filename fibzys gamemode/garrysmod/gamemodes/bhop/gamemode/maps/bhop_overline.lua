__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs( ents.FindByClass( "point_viewcontrol" ) ) do
		ent:Remove()
	end

	for _,ent in pairs( ents.FindByClass( "filter_damage_type" ) ) do
		ent:Remove()
	end
end