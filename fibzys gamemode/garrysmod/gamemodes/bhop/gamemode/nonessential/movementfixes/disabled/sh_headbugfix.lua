--[[

 _  _  ____   __   ____  ____  _  _   ___  ____  __  _  _ 
/ )( \(  __) / _\ (    \(  _ \/ )( \ / __)(  __)(  )( \/ )
) __ ( ) _) /    \ ) D ( ) _ () \/ (( (_ \ ) _)  )(  )  ( 
\_)(_/(____)\_/\_/(____/(____/\____/ \___/(__)  (__)(_/\_)

]]--

local Iv = IsValid
local STANDING_BBOX_MIN = Vector(-16, -16, 0)
local STANDING_BBOX_MAX = Vector(16, 16, BHOP.Move.EyeView)
local DUCKING_BBOX_MIN = Vector(-16, -16, 0)
local DUCKING_BBOX_MAX = Vector(16, 16, BHOP.Move.EyeDuck)
local hook_Add = hook.Add

local playerCollisionData = playerCollisionData or {}

local function UpdateCollisionBounds(ply)
    if not Iv(ply) or not ply:IsPlayer() then return end

    if ply:Crouching() then
        ply:SetCollisionBounds(DUCKING_BBOX_MIN, DUCKING_BBOX_MAX)
    else
        ply:SetCollisionBounds(STANDING_BBOX_MIN, STANDING_BBOX_MAX)
    end
end

hook_Add("SetupMove", "HeadBugFix_UpdateCollisionBounds", function(ply, mv, cmd)
    if not Iv(ply) or not ply:Alive() then return end

    if playerCollisionData[ply] == nil or playerCollisionData[ply] ~= ply:Crouching() then
        playerCollisionData[ply] = ply:Crouching()
        UpdateCollisionBounds(ply)
    end
end)

hook_Add("PlayerSpawn", "HeadBugFix_ResetCollisionBounds", function(ply)
    if not Iv(ply) or not ply:IsPlayer() then return end
    playerCollisionData[ply] = nil
    UpdateCollisionBounds(ply)
end)

hook_Add("PlayerInitialSpawn", "HeadBugFix_PlayerJoin", function(ply)
    if Iv(ply) then
        UpdateCollisionBounds(ply)
    end
end)

hook_Add("PlayerDisconnected", "HeadBugFix_CleanupData", function(ply)
    playerCollisionData[ply] = nil
end)