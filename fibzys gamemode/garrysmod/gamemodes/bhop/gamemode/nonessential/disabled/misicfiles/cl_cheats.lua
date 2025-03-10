-- Full bright flashlight / No Fog
local Cheats = {}

Cheats.Fullbright = false
Cheats.Enabled = CreateClientConVar("bhop_skybox", "0", true, false, "Enable or disable custom skybox effects (0 = off, 1 = on)")
Cheats.Mode = CreateClientConVar("bhop_skybox_mode", "rainbow", true, false, "Choose the skybox color mode: 'rainbow', 'black', or 'white'.")
Cheats.Speed = CreateClientConVar("bhop_skybox_speed", "40", true, false, "Speed for the rainbow skybox animation.")
Cheats.Fullbright = false

function Cheats.ToggleFullbright(supress)
	Cheats.Fullbright = not Cheats.Fullbright

	if not supress then
		ULIT:Print("Fullbright is on ", Color(255, 0, 0), Cheats.Fullbright and "ON" or "OFF")
	end
end

hook.Add("PreRender", "Fullbright", function()
	if not Cheats.Fullbright then
		render.SetLightingMode(0)
		return
	end

	render.SetLightingMode(1)
	render.SuppressEngineLighting(false)
end)

hook.Add("PostRender", "Fullbright", function()
	render.SetLightingMode(0)
	render.SuppressEngineLighting(false)
end)

hook.Add("PreDrawHUD", "Fullbright_hudfix", function()
	render.SetLightingMode(0)
end)

hook.Add("PreDrawEffects", "Fullbright_effectfix", function()
	if not Cheats.Fullbright then return end

	render.SetLightingMode(0)
end)

hook.Add("PostDrawEffects", "Fullbright_effectfix", function()
	if not Cheats.Fullbright then return end

	render.SetLightingMode(0)
end)

hook.Add("PreDrawOpaqueRenderables", "Fullbright_opaquefix", function()
	if not Cheats.Fullbright then return end

	render.SetLightingMode(0)
end)

hook.Add("PostDrawTranslucentRenderables", "Fullbright_transluscentfix", function()
	if not Cheats.Fullbright then return end

	render.SetLightingMode(0)
end)

hook.Add("SetupWorldFog", "Fullbright_forcebrightworld", function()
	if not Cheats.Fullbright then return end

	render.SuppressEngineLighting(true)
	render.SetLightingMode(1)
	render.SuppressEngineLighting(false)
end)

hook.Add("PlayerBindPress", "Fullbright_flashlight", function(_, bind)
	local isValidBind = string.StartWith(bind, "impulse 100")

	if isValidBind then
		local bindingKey = input.LookupBinding(bind, true)
		local keyCode = input.GetKeyCode(bindingKey)
		local justReleased = input.WasKeyReleased(keyCode)

		if (isValidBind and not justReleased) then
			Cheats.ToggleFullbright(true)
			return true
		end
	end
end)

net.Receive("ToggleFullbright", function()
	local shouldEnable = net.ReadBool()

	if shouldEnable then
		if not Cheats.Fullbright then
			Cheats.ToggleFullbright(true)
		end
	else
		if Cheats.Fullbright then
			Cheats.ToggleFullbright(true)
		end
	end
end)

local removeFogConVar = CreateClientConVar("remove_fog", "0", true, false, "Toggle fog removal on maps")
local function RemoveFog()
	if removeFogConVar:GetBool() then
		render.FogMode(MATERIAL_FOG_NONE)
	end
end

hook.Add("SetupWorldFog", "RemoveFogSetupWorldFog", function()
	if removeFogConVar:GetBool() then return true end
end)

hook.Add("SetupSkyboxFog", "RemoveFogSetupSkyboxFog", function()
	if removeFogConVar:GetBool() then return true end
end)

hook.Add("RenderScreenspaceEffects", "RemoveFogRenderScreenspaceEffects", function()
	RemoveFog()
end)

cvars.AddChangeCallback("remove_fog", function(convar_name, value_old, value_new)
	if tobool(value_new) then
		hook.Add("SetupWorldFog", "RemoveFogSetupWorldFog", function() return true end)
		hook.Add("SetupSkyboxFog", "RemoveFogSetupSkyboxFog", function() return true end)
		hook.Add("RenderScreenspaceEffects", "RemoveFogRenderScreenspaceEffects", RemoveFog)
	else
		hook.Remove("SetupWorldFog", "RemoveFogSetupWorldFog")
		hook.Remove("SetupSkyboxFog", "RemoveFogSetupSkyboxFog")
		hook.Remove("RenderScreenspaceEffects", "RemoveFogRenderScreenspaceEffects")
	end
end)

if removeFogConVar:GetBool() then
	hook.Add("SetupWorldFog", "RemoveFogSetupWorldFog", function() return true end)
	hook.Add("SetupSkyboxFog", "RemoveFogSetupSkyboxFog", function() return true end)
	hook.Add("RenderScreenspaceEffects", "RemoveFogRenderScreenspaceEffects", RemoveFog)
end

-- skybox colors overwrite
function Cheats:DrawCustomSkybox()
    if not Cheats.Enabled:GetBool() then return end

    local mode = Cheats.Mode:GetString():lower()

    if mode == "rainbow" then
        local skybox_speed = Cheats.Speed:GetFloat()
        local col = HSVToColor(RealTime() * skybox_speed % 360, 1, 1)
        render.Clear(col.r / 1.3, col.g / 1.3, col.b / 1.3, 255)
    elseif mode == "black" then
        render.Clear(0, 0, 0, 255)
    elseif mode == "white" then
        render.Clear(255, 255, 255, 255)
    else
        render.Clear(0, 0, 0, 255)
    end
end

hook.Add("PostDraw2DSkyBox", "DrawCustomSkybox", function()
    Cheats:DrawCustomSkybox()
end)

-- static props
local staticPropsToggle = CreateClientConVar("bhop_staticprops", "1", true, false, "Toggles static props visibility")
local function ToggleStaticProps()
    local value = staticPropsToggle:GetBool()
    if value then
        RunConsoleCommand("r_drawstaticprops", "1")
    else
        RunConsoleCommand("r_drawstaticprops", "0")
    end
end

cvars.AddChangeCallback("bhop_staticprops", function(_, oldValue, newValue)
    ToggleStaticProps()
end)

ToggleStaticProps()