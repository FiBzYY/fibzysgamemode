-- Changing textures on maps
local mapColor = {
    ["bhop_0000"] = "255 0 0",
    ["bhop_overline"] = "0 255 0"
}

local matBloomScale = {
    ["bhop_0000"] = 0.5,
    ["bhop_overline"] = 1.0
}

local allPlayers = player.GetAll()
local enableMapColors = CreateConVar("bhop_enable_map_colors", "0", FCVAR_ARCHIVE, "Enable or disable map color overwrites")

local function ApplyMapColorChanges()
    local gameMap = game.GetMap()
    if enableMapColors:GetBool() then
        local color = mapColor[gameMap]
        if color then
            for _, ply in ipairs(allPlayers) do
                ply:ConCommand("bhop_map_color " .. color)
            end
        end

        local bloomScale = matBloomScale[gameMap]
        if bloomScale then
            for _, ply in ipairs(allPlayers) do
                ply:ConCommand("mat_bloomscale " .. bloomScale)
            end
        end
    end
end
timer.Create("mapColorTimer", 2, 1, ApplyMapColorChanges)

hook.Add("InitPostEntity", "map_color_fixes", function()
    ApplyMapColorChanges()

    local mapName = game.GetMap()
    if enableMapColors:GetBool() then
        if mapName == "bhop_overline" or mapName == "bhop_overline_fpsfix" then
            local mat = Material("base0/blackblue")
            if mat ~= nil then
                mat:SetVector("$color", Vector(0.3, 0.3, 0.3))
            end
        elseif mapName == "bhop_lunti" then
            local mat = Material("ryan_dev/85")
            if mat ~= nil then
                mat:SetVector("$color", Vector(0.6, 0.6, 0.6))
            end
        elseif mapName == "bhop_dom" then
            local mat1 = Material("base_floor/clang_floor")
            local mat2 = Material("cncr04sp2/metal/yelhaz2dif")
            if mat1 ~= nil then
                mat1:SetVector("$color", Vector(0.3, 0.3, 0.3))
            end
            if mat2 ~= nil then
                mat2:SetVector("$color", Vector(0.4, 0.3, 0.3))
            end
        elseif mapName == "bhop_alt_univaje" then
            local mat = Material("neon/green")
            if mat ~= nil then
                mat:SetVector("$color", Vector(1, 0, 0))
            end
        elseif mapName == "bhop_ares" then
            local mat = Material("dev/dev_measuregeneric43")
            if mat ~= nil then
                mat:SetVector("$color", Vector(0, 1, 0.3))
            end
        end
    end
end)

cvars.AddChangeCallback("bhop_enable_map_colors", function(cvar, oldValue, newValue)
    ApplyMapColorChanges()
end)

hook.Add("PlayerInitialSpawn", "ApplyMapColorsOnSpawn", function(ply)
    ApplyMapColorChanges()
end)

local cc = {
    ["$pp_colour_addr"] = 0,
    ["$pp_colour_addg"] = 0,
    ["$pp_colour_addb"] = 0,
    ["$pp_colour_brightness"] = 0,
    ["$pp_colour_contrast"] = 1,
    ["$pp_colour_colour"] = 1.2,
    ["$pp_colour_mulr"] = 0,
    ["$pp_colour_mulg"] = 0,
    ["$pp_colour_mulb"] = 0
}

concommand.Add("bhop_map_brightness", function(ply, cmd, args)
    cc["$pp_colour_contrast"] = tonumber(args[1]) or 1
end)

hook.Add("RenderScreenspaceEffects", "MapBrightness", function()
    if cc["$pp_colour_contrast"] == 1 then return end
    DrawColorModify(cc)
end)

function GM:PostProcessPermitted()
    return false
end

local enableScreenEffect = CreateConVar("bhop_darken_screen_effect", "0", FCVAR_ARCHIVE, "Enable or disable the darken screen effect.")

hook.Add("RenderScreenspaceEffects", "DarkenScreenButKeepWhites_Subtle", function()
    if not enableScreenEffect:GetBool() then return end

    local colorModSettings = {
        ["$pp_colour_addr"] = 0, 
        ["$pp_colour_addg"] = 0,
        ["$pp_colour_addb"] = 0,         
        ["$pp_colour_brightness"] = -0.02,
        ["$pp_colour_contrast"] = .8,
        ["$pp_colour_colour"] = 0.9,
        ["$pp_colour_mulr"] = 0,   
        ["$pp_colour_mulg"] = 0,  
        ["$pp_colour_mulb"] = 0,  
    }

    DrawColorModify(colorModSettings)
end)