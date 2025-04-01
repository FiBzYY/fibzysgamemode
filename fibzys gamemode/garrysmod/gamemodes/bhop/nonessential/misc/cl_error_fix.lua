-- errors blue
local blueMaterial = CreateMaterial("BlueMaterial", "UnlitGeneric", {
    ["$basetexture"] = "color/white",
    ["$color"] = "[0 132 255]",
    ["$model"] = 1,
    ["$vertexcolor"] = 1,
    ["$vertexalpha"] = 1,
    ["$nolod"] = 1,
    ["$ignorez"] = 0,
    ["$additive"] = 0,
    ["$translucent"] = 0
})

local errorMaterialPaths = {
    "models/error/new light1",
    "debug/debugempty",
    "error",
    "dev/dev_water2"
}

local function AreTargetMaterialsPresent()
    for _, path in ipairs(errorMaterialPaths) do
        local material = Material(path)
        if material and not material:IsError() then
            return true
        end
    end
    return false
end

local function ReplaceErrorTextures()
    for _, path in ipairs(errorMaterialPaths) do
        local material = Material(path)
        if material and not material:IsError() then
            material:SetTexture("$basetexture", blueMaterial:GetTexture("$basetexture"))
            material:SetVector("$color", Vector(0 / 255, 132 / 255, 255 / 255))
            material:Recompute()
        end
    end
end

hook.Add("InitPostEntity", "ReplaceErrorAndWaterTextures", function()
    if AreTargetMaterialsPresent() then
        ReplaceErrorTextures()
    end
end)