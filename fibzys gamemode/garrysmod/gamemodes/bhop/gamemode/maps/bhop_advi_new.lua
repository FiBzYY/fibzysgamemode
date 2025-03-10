-- Remove all annoying sounds
hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("ambient_generic")) do
		ent:Remove()
	end
end)
