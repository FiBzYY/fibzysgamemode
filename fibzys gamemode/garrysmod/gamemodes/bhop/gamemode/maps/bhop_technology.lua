__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs(ents.FindByClass("func_door")) do
		if(table.HasValue(doors,v:GetPos())) then
			v:Remove()
		end
	end
end