local teleportArea = {
    { Vector(-1455, 1336, 160), Vector(-1104, 1431, 164) },
    { Vector(408, 2192, -32), Vector(1368, 2672, -16) }
}

local targetRemovePositions = {
    Vector(-1248, 1384.01001, 268),
    Vector(880, 2432, 100)
}

local function CreateTeleporterEntity(minVec, maxVec, targetPos, targetAng)
    local teleporter = ents.Create("ent_teleport")
    if not IsValid(teleporter) then return end
    teleporter:SetPos((minVec + maxVec) / 2)
    teleporter.min = minVec
    teleporter.max = maxVec
    teleporter.targetpos = targetPos
    teleporter.targetang = targetAng
    teleporter:Spawn()
end

__HOOK["InitPostEntity"] = function()
    --Zones.styleForce = TIMER:StyleID("Legit")
    Zones.StepSize = 16

    local target, target2 = nil, nil
    for _, ent in pairs(ents.FindByClass("trigger_teleport")) do
        local entPos = ent:GetPos()
        if entPos == targetRemovePositions[1] then
            ent:Remove()
            target = ents.FindByName(ent:GetSaveTable().target)[1]
        elseif entPos == targetRemovePositions[2] then
            ent:Remove()
            target2 = ents.FindByName(ent:GetSaveTable().target)[1]
        end
    end

    if IsValid(target) then
        CreateTeleporterEntity(teleportArea[1][1], teleportArea[1][2], target:GetPos(), target:GetAngles())
    end

    if IsValid(target2) then
        CreateTeleporterEntity(teleportArea[2][1], teleportArea[2][2], target2:GetPos(), target2:GetAngles())
    end
end