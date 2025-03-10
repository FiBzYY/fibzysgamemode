local teleportPositionsToRemove = {
    Vector(-9712, 4815.97, 592.5),
    Vector(-12768, 3040, -8151.5),
    Vector(-12768, 1312, -8151.5),
    Vector(-12768, 2464, -8151.5),
    Vector(-12768, 1888, -8151.5),
    Vector(-12768, 736, -8151.5),
    Vector(-12768, 160, -8151.5),
    Vector(-2584.01, 13448, -1167.5),
    Vector(-2752.22, 14216, -1296),
    Vector(-2920.01, 14216, -1255.5),
    Vector(-2920.01, 13448, -1255.5)
}

__HOOK["InitPostEntity"] = function()
    for _, ent in pairs(ents.FindByClass("trigger_teleport")) do
        if table.HasValue(teleportPositionsToRemove, ent:GetPos()) then
            ent:Remove()
        end
    end
end