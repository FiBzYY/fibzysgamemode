__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if ent:GetPos() == Vector( 4312, 3600, -3780 ) then
			ent:Remove()
		end
	end
end