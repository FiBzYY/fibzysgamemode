local PLAYER = FindMetaTable( "Player" )

PLAYER.MainSetJumps = PLAYER.SetJumps

function PLAYER:SetJumps( nValue )
	self:MainSetJumps( nValue )
	self:SetName( "jump2" )
end