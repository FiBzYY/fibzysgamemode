__HOOK[ "EntityKeyValue" ] = function(ent,key,value)
	if(string.sub(key,1,2) == "On" && string.find(value,"ShowHudHint")) then
		ent.r = true
	end
	if(key == "OnMapSpawn" && value == "command,Command,exec bhopmist4.cfg,0,-1") then
		return ""
	end
end

__HOOK[ "InitPostEntity" ] = function()
	ents.FindByName("timer2")[1]:Remove()
	for _,ent in pairs(ents.FindByName("d1")) do
		ent:Remove()
	end
	for _,ent in pairs(ents.FindByName("d2")) do
		ent:Remove()
	end
	for _,ent in pairs(ents.FindByName("d3")) do
		ent:Remove()
	end
	for _,ent in pairs(ents.FindByClass("trigger_multiple")) do
		if(ent.r) then
			ent:Remove()
		end
	end
	for _,ent in pairs(ents.FindByClass("point_servercommand")) do
		ent:Remove()
	end
end