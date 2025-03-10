__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if ent:GetPos() == Vector( 84, 1769.5, 657.5 ) then
			ent:Remove()
		end
	end
end