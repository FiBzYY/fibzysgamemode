local remove = {
	Vector(-4848, -1268, -56),
	Vector(-1680.5, -2324, -84),
	Vector(5320.5, -2736, 20),
	Vector(-4876, 1898, 31),
	Vector(-4156, 1896, 98.72),
	Vector(-4118, -1924, -44)
}

__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs(ents.FindByClass("trigger_teleport")) do
		if(ent:GetPos() == Vector(543.5, -980, -84)) then
			ent:SetKeyValue("target","level18")
		end
		if(table.HasValue(remove,ent:GetPos())) then
			ent:Remove()
		end
	end
end