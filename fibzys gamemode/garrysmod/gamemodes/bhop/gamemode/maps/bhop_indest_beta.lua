-- Fix lag on Indest

hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("env_entity_maker")) do
		ent:Remove()
	end
end)
