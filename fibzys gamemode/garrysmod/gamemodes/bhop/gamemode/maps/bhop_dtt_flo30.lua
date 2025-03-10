__HOOK["InitPostEntity"] = function()
	for _,ent in pairs(ents.FindByClass("trigger_teleport")) do
		local p = ent:GetPos()
		if(p.y == 127.5 && p.z == 172.5 && (p.x < -216 && p.x > -232)) then
			ent:Remove()
		end
	end
end