--[[function ToggleStamina( ply )

	if ply.style == BHDATA.Config.Styles.Legit or ply.style == BHDATA.Config.Styles.Stamina then
		return "CommandFrictionstyles"
	else
		local bool = ply:EnableStamina( not ply.StaminaUse )

		return "CommandFrictionToggle", bool and "enabled" or "disabled"
	end
end--]]