__HOOK["InitPostEntity"] = function()
    -- Remove all env_sprite entities
    for _, ent in pairs(ents.FindByClass("env_sprite")) do
        ent:Remove()
    end

    -- Remove all prop entities
   --[[ local propClasses = {"prop_physics", "prop_dynamic", "prop_static", "prop_physics_multiplayer", "prop_dynamic_override"}
    for _, class in ipairs(propClasses) do
        for _, ent in pairs(ents.FindByClass(class)) do
            ent:Remove()
        end
    end--]]
end

-- Constants
local SNAME = "[spritefix] "

-- Hook to detect when an entity is created
hook.Add("OnEntityCreated", "CheckSpriteMaterial", function(ent)
    -- Check if the entity is a sprite (equivalent to checking classname "env_sprite")
    if IsValid(ent) and ent:GetClass() == "env_sprite" then
        -- Delay the check to ensure the entity is fully created
        timer.Simple(0, function()
            if IsValid(ent) then
                CheckSpriteMaterial(ent)
            end
        end)
    end
end)

-- Function to check the material of the sprite and remove it if invalid
function CheckSpriteMaterial(ent)
    -- Get the material of the sprite
    local spritemat = ent:GetModel() or ""

    -- Find the separator (slash or backslash) to process the path
    local sep = string.find(spritemat, "/") or string.find(spritemat, "\\")
    local buff = spritemat

    -- Adjust the path if necessary
    if sep then
        buff = string.sub(spritemat, 1, sep - 1)
        if buff ~= "materials" then
            spritemat = "materials/" .. spritemat
        end
    else
        spritemat = "materials/" .. spritemat
    end

    -- Check if the material file exists
    if not file.Exists(spritemat, "GAME") then
        -- Remove the entity if the material is invalid
        ent:Remove()
        -- Log the removal
        print(SNAME .. "Found env_sprite (" .. ent:EntIndex() .. ") with bad material (" .. spritemat .. "), removing...")
    end
end