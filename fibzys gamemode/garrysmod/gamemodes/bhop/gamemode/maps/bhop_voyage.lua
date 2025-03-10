__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs( ents.FindByClass("trigger_teleport") ) do
		if ent:GetPos() == Vector(0, -404.5, -136) then
			ent:Remove()
		end
	end
end