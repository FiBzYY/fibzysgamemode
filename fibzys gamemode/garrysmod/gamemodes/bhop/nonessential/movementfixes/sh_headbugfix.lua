--[[

 _  _  ____   __   ____  ____  _  _   ___  ____  __  _  _ 
/ )( \(  __) / _\ (    \(  _ \/ )( \ / __)(  __)(  )( \/ )
) __ ( ) _) /    \ ) D ( ) _ () \/ (( (_ \ ) _)  )(  )  ( 
\_)(_/(____)\_/\_/(____/(____/\____/ \___/(__)  (__)(_/\_)

]]--

local Iv, hook_Add = IsValid, hook.Add
local STANDING_BBOX_MIN = Vector(-16, -16, 0)
local STANDING_BBOX_MAX = Vector(16, 16, BHOP.Move.EyeView)
local DUCKING_BBOX_MIN = Vector(-16, -16, 0)
local DUCKING_BBOX_MAX = Vector(16, 16, BHOP.Move.EyeDuck)

local playerCollisionData = playerCollisionData or {}

local function UpdateCollisionBounds(ply, mv)
    if not Iv(ply) or not ply:IsPlayer() then return end

    local ducked = mv:KeyDown(IN_DUCK) or ply:Crouching()
    if ducked and playerCollisionData[ply] ~= "duck" then
        ply:SetCollisionBounds(DUCKING_BBOX_MIN, DUCKING_BBOX_MAX)
        ply:SetHullDuck(DUCKING_BBOX_MIN, DUCKING_BBOX_MAX)
        playerCollisionData[ply] = "duck"
    elseif not ducked and playerCollisionData[ply] ~= "stand" then
        ply:SetCollisionBounds(STANDING_BBOX_MIN, STANDING_BBOX_MAX)
        ply:SetHull(STANDING_BBOX_MIN, STANDING_BBOX_MAX)
        playerCollisionData[ply] = "stand"
    end
end

hook_Add("SetupMove", "HeadBugFixUpdateCollisionBounds", function(ply, mv, cmd)
    if not Iv(ply) or not ply:Alive() or not IsFirstTimePredicted() then return end
    UpdateCollisionBounds(ply, mv)
end)

hook_Add("PlayerSpawn", "HeadBugFixResetCollisionBounds", function(ply)
    if not Iv(ply) or not ply:IsPlayer() then return end
    playerCollisionData[ply] = nil
end)

hook_Add("PlayerInitialSpawn", "HeadBugFixPlayerJoin", function(ply)
    if Iv(ply) then
        playerCollisionData[ply] = nil
    end
end)

hook_Add("PlayerDisconnected", "HeadBugFixCleanupData", function(ply)
    playerCollisionData[ply] = nil
end)