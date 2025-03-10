local sf, sl, tn = string.find, string.lower, tonumber

__HOOK[ "EntityKeyValue" ] = function( ent, key, value )

	if ent:GetClass() == "trigger_push" then
		if sf( sl( key ), "speed" ) then
			if tn( value ) == 800 then
				return "999999999"
			end
		end
	end
end