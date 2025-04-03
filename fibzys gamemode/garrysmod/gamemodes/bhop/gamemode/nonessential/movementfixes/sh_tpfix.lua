local HEIGHT = 62
local BOTTOM_PAD = 2
local TOP_PAD = 0.01
local FIXED_TELEPORTS = {}
local Iv = IsValid

local MIN_BOUNDS = Vector(-16, -16, -BOTTOM_PAD)
local MAX_BOUNDS = Vector(16, 16, TOP_PAD)

local function CheckAndFixTeleport(targetEnt)
    if not Iv(targetEnt) or FIXED_TELEPORTS[targetEnt] then return end

    local origin = targetEnt:GetPos()
    origin.z = origin.z + HEIGHT / 2

    local traceDown = util.TraceHull({
        start = origin,
        endpos = origin - Vector(0, 0, HEIGHT / 2 + 5),
        mins = MIN_BOUNDS,
        maxs = MAX_BOUNDS,
        mask = MASK_PLAYERSOLID_BRUSHONLY
    })

    local traceUp = util.TraceHull({
        start = origin,
        endpos = origin + Vector(0, 0, HEIGHT / 2 + 5),
        mins = MIN_BOUNDS,
        maxs = MAX_BOUNDS,
        mask = MASK_PLAYERSOLID_BRUSHONLY
    })

    local moveUp, moveDown = 0, 0

    if traceDown.Hit then
        local dist = origin.z - traceDown.HitPos.z
        if dist < HEIGHT / 2 then moveUp = HEIGHT / 2 - dist end
    end

    if traceUp.Hit then
        local dist = traceUp.HitPos.z - origin.z
        if dist < HEIGHT / 2 then moveDown = HEIGHT / 2 - dist end
    end

    if moveUp > 0 and moveDown > 0 then
    elseif moveUp > 0 then
        targetEnt:SetPos(targetEnt:GetPos() + Vector(0, 0, moveUp))
    elseif moveDown > 0 then
        targetEnt:SetPos(targetEnt:GetPos() - Vector(0, 0, moveDown))
    end

    FIXED_TELEPORTS[targetEnt] = true
end

local preTeleportVelocity = {}
local function OnPlayerTeleportedFix(ent, input, activator, caller)
    if input ~= "teleported" then return end
    
    if not Iv(ent) then return end
    if not Iv(activator) or not activator:IsPlayer() then return end
    
    preTeleportVelocity[activator] = activator:GetVelocity()
end
hook.Add("AcceptInput", "OnPlayerTeleportedFix", OnPlayerTeleportedFix)

local function TPFix_HandleNewTeleports()
    for _, ent in ipairs(ents.FindByClass("trigger_teleport")) do
        ent:Fire("AddOutput", "OnStartTouch !activator:teleported:0:0:-1")
        ent:Fire("AddOutput", "OnEndTouch !activator:teleported:0:0:-1")
    end
end
hook.Add("InitPostEntity", "TPFix_HandleNewTeleports", TPFix_HandleNewTeleports)

hook.Add("InitPostEntity", "TPFix_RestoreVelocity", function(ply, mv)
    for _, ent in ipairs(ents.GetAll()) do
        if ent:GetClass() == "info_teleport_destination" or ent:GetClass() == "trigger_teleport" and not ent:GetClass() == "trigger_multiple" then
            CheckAndFixTeleport(ent)
        end
    end
end)