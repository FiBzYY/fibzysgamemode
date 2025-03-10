__HOOK["InitPostEntity"] = function()
    -- Remove all env_sun entities
    for _, ent in pairs(ents.FindByClass("env_sun")) do
        ent:Remove()
    end

    -- List of common prop classes to remove
    local propClasses = {
        "prop_physics",
        "prop_dynamic",
        "prop_static",
        "prop_physics_multiplayer",
        "prop_physics_override",
        "prop_ragdoll"
    }

    -- Remove all prop entities
    for _, class in ipairs(propClasses) do
        for _, ent in pairs(ents.FindByClass(class)) do
            ent:Remove()
        end
    end
end