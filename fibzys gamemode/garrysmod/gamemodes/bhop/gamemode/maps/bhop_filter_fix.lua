__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if ent:GetPos() == Vector(1664, -4752, 144) then
			ent:Remove()
		end
	end
end