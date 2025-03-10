__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs(ents.FindByClass("trigger_teleport")) do
		if(ent:GetPos() == Vector(10368, -556, -192)) then
			ent:Remove()
		end
		if(ent:GetPos() == Vector(10368, -532, -192)) then
			ent:Remove()
		end
	end
	for _,ent in pairs(ents.FindByClass("func_wall_toggle")) do
		ent:Remove()
	end
end