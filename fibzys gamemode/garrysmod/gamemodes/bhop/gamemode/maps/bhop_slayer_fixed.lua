-- Remove doors on bonus
hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("func_door")) do
		if ent:GetPos() == Vector(2628, -1005, -2309) or ent:GetPos() == Vector(2337, -3007, -2309) or ent:GetPos() == Vector(-1272, -2841, -2309) or ent:GetPos() == Vector(-610.98, 261.03, -2847) then
			ent:Remove()
		end
	end

	for _, ent in pairs(ents.FindByClass("weapon_scout")) do
		ent:Remove()
	end
end)
