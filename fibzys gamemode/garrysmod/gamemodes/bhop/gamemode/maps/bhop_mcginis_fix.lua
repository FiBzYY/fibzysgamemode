local tmrPositions = {
    Vector(-6080, -1296, -1413.93),
    Vector(-6408, -1296, -1413.93),
    Vector(-6808, -1296, -1413.93),
    Vector(-6896, -1472, -1413.93),
    Vector(-6896, -1728, -1413.93),
    Vector(-6896, -2048, -1413.93),
    Vector(-6896, -2320, -1413.93),
}

local teleportPositionsToRemove = {
    Vector(10240.1, -14144, -4816),
    Vector(10240.1, -14336, -4816)
}

local trainPositionsToRemove = {
    Vector(10240.1, -14144, -4824),
    Vector(10240.1, -14336, -4824)
}

local function RemoveEntitiesByClassAndPosition(className, positions)
    for _, ent in pairs(ents.FindByClass(className)) do
        if IsValid(ent) and table.HasValue(positions, ent:GetPos()) then
            ent:Remove()
        end
    end
end

local function RemoveEntitiesByNamePattern(className, pattern)
    for _, ent in pairs(ents.FindByClass(className)) do
        if IsValid(ent) and string.find(ent:GetName(), pattern, 1, true) then
            ent:Remove()
        end
    end
end

local function OpenEntitiesByClass(className)
    for _, ent in pairs(ents.FindByClass(className)) do
        if IsValid(ent) then
            ent:Fire("Open")
        end
    end
end

local function RemoveEntitiesByClass(className)
    for _, ent in pairs(ents.FindByClass(className)) do
        if IsValid(ent) then
            ent:Remove()
        end
    end
end

__HOOK["InitPostEntity"] = function()
    -- Remove game_player_equip entities
    RemoveEntitiesByClass("game_player_equip")

    -- Remove specific trigger_teleport entities
    RemoveEntitiesByClassAndPosition("trigger_teleport", teleportPositionsToRemove)

    -- Remove specific func_tanktrain entities
    RemoveEntitiesByClassAndPosition("func_tanktrain", trainPositionsToRemove)

    -- Remove path_track entities with "train" in their name
    RemoveEntitiesByNamePattern("path_track", "train")

    -- Remove trigger_multiple entities at specific positions
    RemoveEntitiesByClassAndPosition("trigger_multiple", tmrPositions)

    -- Open all func_door entities
    OpenEntitiesByClass("func_door")
end

__HOOK["EntityKeyValue"] = function(ent, key, value)
    if IsValid(ent) and ent:GetClass() == "func_door" and string.lower(key) == "wait" and tonumber(value) == 4 then
        return "-1"  -- Override the "wait" value for specific func_door entities
    end
end