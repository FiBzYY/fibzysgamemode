-- Helper function to create and spawn game_block entities
local function CreateGameBlock(position, min, max)
    local block = ents.Create("game_block")
    if not IsValid(block) then return end
    block:SetPos(position)
    block.min = min
    block.max = max
    block:Spawn()
end

__HOOK["InitPostEntity"] = function()
    -- Update specific trigger_teleport entity
    for _, ent in pairs(ents.FindByClass("trigger_teleport")) do
        if ent:GetPos() == Vector(6560, 5112, 7412) then
            ent:SetKeyValue("target", "13")
        end
    end

    -- Rename specific func_brush entity
    for _, ent in pairs(ents.FindByClass("func_brush")) do
        if ent:GetName() == "aokilv6" then
            ent:SetName("disabled")
        end
    end

    -- Create game_block entities
    local gameBlockPositions = {
        Vector(-328, 11992, 4703),
        Vector(-296, 12095, 4703),
        Vector(-655, 12151, 4703),
        Vector(-815, 11920, 4703),
        Vector(-815, 11808, 4703),
        Vector(-911, 11840, 4703),
        Vector(-1071, 11840, 4703)
    }

    local minBounds = Vector(-2, -2, -1.5)
    local maxBounds = Vector(2, 2, 1)

    for _, pos in pairs(gameBlockPositions) do
        CreateGameBlock(pos, minBounds, maxBounds)
    end
end