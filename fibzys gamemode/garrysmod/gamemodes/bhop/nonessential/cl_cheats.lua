local BhopCheats = {
    Fullbright = false,
    RemoveFog = CreateClientConVar("bhop_map_fog", "0", true, false, "Toggle fog removal on maps"),
    Skybox = {
        Enabled = CreateClientConVar("bhop_skybox", "0", true, false, "Enable or disable custom skybox effects (0 = off, 1 = on)"),
        Mode = CreateClientConVar("bhop_skybox_mode", "rainbow", true, false, "Choose the skybox color mode: 'rainbow', 'black', or 'white'."),
        Speed = CreateClientConVar("bhop_skybox_speed", "40", true, false, "Speed for the rainbow skybox animation.")
    }
}

CreateClientConVar("bhop_fullbright", "0", true, false, "Enable Fullbright toggle using the flashlight key (1 = enabled, 0 = disabled)")

-- Toggle Fullbright
function BhopCheats:ToggleFullbright(silent)
    self.Fullbright = not self.Fullbright

    if not silent then
		ULIT:Print("Fullbright is on ", Color(255, 0, 0), Cheats.Fullbright and "ON" or "OFF")
    end
end

hook.Add("PreRender", "Bhop_Fullbright", function()
    if not BhopCheats.Fullbright then return render.SetLightingMode(0) end
    render.SetLightingMode(1)
    render.SuppressEngineLighting(true)
end)

hook.Add("PostRender", "Bhop_Fullbright_Reset", function()
    render.SetLightingMode(0)
    render.SuppressEngineLighting(false)
end)

hook.Add("PreDrawHUD", "Bhop_Fullbright_HudFix", function()
    render.SetLightingMode(0)
end)

hook.Add("PreDrawEffects", "Bhop_Fullbright_EffectFix", function()
    if BhopCheats.Fullbright then
        render.SetLightingMode(0)
    end
end)

hook.Add("SetupSkyboxFog", "Bhop_NoFog", function()
   if render.GetRenderTarget() ~= nil then return end

    if not BhopCheats.RemoveFog:GetBool() then return end

    render.FogMode(MATERIAL_FOG_NONE)
    render.FogStart(99999)
    render.FogEnd(99999)
    render.FogMaxDensity(0)
    return true
end)

hook.Add("RenderScreenspaceEffects", "Bhop_NoFog_Render", function()
    if not BhopCheats.RemoveFog:GetBool() then
        render.FogMode(MATERIAL_FOG_NONE)
    end
end)

cvars.AddChangeCallback("bhop_map_fog", function(_, _, newVal)
    if not tobool(newVal) then
        hook.Add("SetupWorldFog", "Bhop_NoFog", function() return true end)
        hook.Add("SetupSkyboxFog", "Bhop_NoFog_Skybox", function() return true end)
        hook.Add("RenderScreenspaceEffects", "Bhop_NoFog_Render", function()
            render.FogMode(MATERIAL_FOG_NONE)
        end)
    else
        hook.Remove("SetupWorldFog", "Bhop_NoFog")
        hook.Remove("SetupSkyboxFog", "Bhop_NoFog_Skybox")
        hook.Remove("RenderScreenspaceEffects", "Bhop_NoFog_Render")
    end
end)

CreateClientConVar("bhop_fullbright", "0", true, false, "Enable Fullbright toggle using the flashlight key")

hook.Add("PlayerBindPress", "Bhop_FlashlightToggle", function(ply, bind, pressed)
    if GetConVar("bhop_fullbright"):GetBool() and bind:lower() == "impulse 100" and pressed then
        BhopCheats:ToggleFullbright(true)
        return true
    end
end)

-- Custom Skybox Handling
function BhopCheats:DrawSkybox()
    if not self.Skybox.Enabled:GetBool() then return end

    local mode = self.Skybox.Mode:GetString():lower()
    local speed = self.Skybox.Speed:GetFloat()
    
    if mode == "rainbow" then
        local col = HSVToColor(RealTime() * speed % 360, 1, 1)
        render.Clear(col.r / 1.3, col.g / 1.3, col.b / 1.3, 255)
    elseif mode == "black" then
        render.Clear(0, 0, 0, 255)
    elseif mode == "white" then
        render.Clear(255, 255, 255, 255)
    else
        render.Clear(0, 0, 0, 255)
    end
end

hook.Add("PostDraw2DSkyBox", "Bhop_DrawCustomSkybox", function()
    BhopCheats:DrawSkybox()
end)

-- Networking for Fullbright Toggle
net.Receive("Bhop_ToggleFullbright", function()
    local enable = net.ReadBool()
    if enable ~= BhopCheats.Fullbright then
        BhopCheats:ToggleFullbright(true)
    end
end)