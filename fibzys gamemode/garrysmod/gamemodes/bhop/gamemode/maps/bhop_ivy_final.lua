hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("prop_door_rotating")) do
		ent:Remove()
	end
end)