__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if ent:GetPos() == Vector( -4460, 4313, 5337 ) then
			ent:Remove()
		end
	end

	for _,ent in pairs( ents.FindByClass( "func_rotating" ) ) do
		if ent:GetPos() == Vector( 9841, 6043, -5289 ) or ent:GetPos() == Vector( 9841, 7647, -5289 ) then
			ent:Remove()
		end
	end

	for _,ent in pairs( ents.FindByClass( "func_button" ) ) do
		if ent:GetPos() == Vector( 9809, 9058.5, -5279 ) or ent:GetPos() == Vector( 10787.5, 9325.5, -5335 ) then
			ent:Remove()
		end
	end

	for _,ent in pairs( ents.FindByClass( "func_door" ) ) do
		if ent:GetPos() == Vector( 11269.5, 8894, -5480 ) then
			ent:Fire( "Open" )
		end
	end
end

local sf, sl, tn = string.find, string.lower, tonumber

__HOOK[ "EntityKeyValue" ] = function( ent, key, value )

	if ent:GetClass() == "func_rotating" then
		if sf( sl( key ), "maxspeed" ) then
			return "0"
		elseif sf( sl( key ), "fanfriction" ) then
			return "0"
		elseif sf( sl( key ), "spawnflags" ) then
			return "1024"
		end
	elseif ent:GetClass() == "func_door" then
		if sf( sl( key ), "wait" ) then
			if tn( value ) == 6 then
				return "-1"
			end
		end
	end
end