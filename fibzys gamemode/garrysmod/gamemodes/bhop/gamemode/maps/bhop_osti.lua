__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs(ents.FindByClass("func_door")) do
		local pos = ent:GetPos()
		if(pos.x == -1873 && pos.z == 1137) then
			ent:Remove()
		end
	end
end