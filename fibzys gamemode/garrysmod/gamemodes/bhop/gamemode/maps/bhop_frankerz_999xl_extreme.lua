__HOOK[ "InitPostEntity" ] = function()

	local opt = BHDATA.GetMapVariable( "Options" )

	local list = BHDATA.GetMapVariable( "OptionList" )

	opt = bit.bor( opt, list.NoSpeedLimit )
	
	BHDATA.SetMapVariable( "Options", opt )

	BHDATA.ReloadMapOptions()
end