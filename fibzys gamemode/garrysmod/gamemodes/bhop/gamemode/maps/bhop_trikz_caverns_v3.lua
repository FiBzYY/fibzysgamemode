__HOOK["InitPostEntity"] = function()
	for _,ent in pairs(ents.FindByClass("func_breakable")) do
		ent:Remove()
	end

	timer.Simple(1,function()
		for _,ent in pairs(ents.FindByClass("func_door")) do
			if(tonumber(ent:GetNWInt("Platform",0)) == 0) then
				ent:Fire("Open")
				ent:Remove()
			end
			if(ent.BHSp > 100) then
				ent:Fire("Unlock")
				ent:SetKeyValue("speed",ent.BHSp)
				ent:Fire("Open")
				ent:Remove()
			end
			if(ent:GetPos() == Vector(1567, 4270, 418)) then
				ent:Fire("Unlock")
				ent:SetKeyValue("speed",ent.BHSp)
				ent:Fire("Open")
				ent:Remove()
			end
		end
		for _,ent in pairs(ents.FindByClass("func_areaportal")) do
			ent:Fire("Open","",0)
		end
	end)
end