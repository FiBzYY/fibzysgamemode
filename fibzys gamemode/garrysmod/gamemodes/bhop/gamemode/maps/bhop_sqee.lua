local teleportPositionsToRemove = {
    Vector(4792, -456, -4489.5),
    Vector(4792, -696, -4489.5),
    Vector(4792, -936, -4489.5),
    Vector(4792, -1176, -4489.5),
    Vector(4792, -1416, -4489.5)
}

__HOOK["InitPostEntity"] = function()
    for _, ent in pairs(ents.FindByClass("trigger_teleport")) do
        if table.HasValue(teleportPositionsToRemove, ent:GetPos()) then
            ent:Remove()
        end
    end
end