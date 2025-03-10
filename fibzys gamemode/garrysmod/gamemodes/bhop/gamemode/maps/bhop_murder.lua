local brushes = {
	"b1",
	"b2",
	"b3",
	"b4",
	"b5",
	"b6",
	"b8",
	"b7"
}

local teleports = {
	"d1_t",
	"d2_t",
	"d3_t",
	"d4_t",
	"d5_t",
	"d6_t",
	"d7_t",
	"d8_t"
}

__HOOK[ "InitPostEntity" ] = function()	
	for _,ent in pairs(ents.FindByClass("func_brush")) do
		if(table.HasValue(brushes,ent:GetName())) then
			ent:Remove()
		end
	end	

	for _,ent in pairs(ents.FindByClass("trigger_teleport")) do
		if(table.HasValue(teleports,ent:GetName())) then
			ent:Remove()
		end
	end	
end