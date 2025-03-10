-- Remove lag at third stage
hook.Add("InitPostEntity", "MapInitPostEntity", function()
	for _, ent in pairs(ents.FindByClass("func_smokevolume")) do
		ent:Remove()
	end
end)

-- Fix power jumps
hook.Add("EntityKeyValue", "MapEntityKeyValue", function(ent, key, value)
	if ent:GetClass() == "trigger_multiple" and key == "OnTrigger" and value == "!activator,AddOutput,gravity -10,0,-1" then
			return "!activator,AddOutput,gravity -12,0,-1"
	end
end)
