--[[

 ____  ____  _  _   __   _  _  ____    ____  _  _  ____    __     __    ___  _   
(  _ \(  __)( \/ ) /  \ / )( \(  __)  (_  _)/ )( \(  __)  (  )   / _\  / __)/ \  
 )   / ) _) / \/ \(  O )\ \/ / ) _)     )(  ) __ ( ) _)   / (_/\/    \( (_ \\_/  
(__\_)(____)\_)(_/ \__/  \__/ (____)   (__) \_)(_/(____)  \____/\_/\_/ \___/(_)  !

]]--

local hook_Add, hook_Remove = hook.Add, hook.Remove

hook_Add("Initialize", "RemoveUsedHooks", function()
    hook.Remove("PlayerTick", "TickWidgets")

    local clientHooksToRemove = {
        "RenderColorModify", "RenderBloom", "RenderToyTown", "RenderTexturize", "RenderSunbeams",
        "RenderSobel", "RenderSharpen", "RenderMaterialOverlay", "RenderMotionBlur", "RenderStereoscopy",
        "RenderSuperDoF", "SuperDOFMouseDown", "SuperDOFMouseUp", "SuperDOFPreventClicks", "RenderFrameBlend",
        "PreRenderFrameBlend", "DOFThink", "RenderBokeh", "NeedsDepthPass_Bokeh", "RenderWidgets",
        "RenderHalos", "RenderFlash", "RenderHintDisplay", "RenderVehicleBeam", "RenderPhysgunBeam",
        "CheckSchedules", "FireBullets", "AutoSaveThink", "ChatIndicatorsThink", "PlayerThink",
        "TickWidgets", "PlayerTick", "DrawTargetID", "DrawDeathNotice", "DrawPickupHistory",
        "DrawWeaponSelection", "DrawHUD", "DrawWatermark", "DrawCrosshair", "RenderEffects",
        "RenderCombineOverlay", "RenderMaterialOverlay", "RenderScreenspaceEffects", "RenderWidgets",
        "DrawHUDBackground", "DrawViewModel", "DrawPlayerHands", "MotionBlurThink", "RenderBloom",
        "RenderMotionBlur", "RenderFrameBlend", "PropertiesHover", "PropertiesHoverEntity", "AddEntityHalos"
    }

    for _, hookName in ipairs(clientHooksToRemove) do
        hook.Remove("RenderScreenspaceEffects", hookName)
        hook.Remove("RenderScene", hookName)
        hook.Remove("GUIMousePressed", hookName)
        hook.Remove("GUIMouseReleased", hookName)
        hook.Remove("PreventScreenClicks", hookName)
        hook.Remove("PostRender", hookName)
        hook.Remove("PreRender", hookName)
        hook.Remove("Think", hookName)
        hook.Remove("NeedsDepthPass", hookName)
        hook.Remove("PostDrawEffects", hookName)
        hook.Remove("HUDPaint", hookName)
        hook.Remove("HUDPaintBackground", hookName)
        hook.Remove("PreDrawViewModel", hookName)
        hook.Remove("PostDrawViewModel", hookName)
        hook.Remove("PreDrawPlayerHands", hookName)
        hook.Remove("PostDrawPlayerHands", hookName)
        hook.Remove("PreDrawHalos", hookName)
        hook.Remove("PostDrawOpaqueRenderables", hookName)
        hook.Remove("PostDrawTranslucentRenderables", hookName)
    end
end)

-- Fix skybox issuses
hook_Add("InitPostEntity", "RemoveSkyBoxOnSpecificMaps", function()
    local mapName = game.GetMap()

    local disableSkyboxMaps = {
        ["bhop_zyper"] = true,
        ["bhop_z"] = true
    }

    if disableSkyboxMaps[mapName] then
        RunConsoleCommand("r_skybox", "0")
    else
        RunConsoleCommand("r_skybox", "1")
    end
end)

-- Load client commands on player load
hook_Add("InitPostEntity", "Fpsfixes", function()
    if GetConVar("r_drawsprites"):GetInt() ~= 0 then
        RunConsoleCommand("r_drawsprites", "0")
        RunConsoleCommand("cl_interp", "0.05")
        RunConsoleCommand("cl_smoothtime", "0.05")

        -- Others
        RunConsoleCommand("lua_networkvar_bytespertick", "0")
        RunConsoleCommand("lua_matproxy", "0")
        RunConsoleCommand("r_dynamic", "0")
        RunConsoleCommand("mat_specular", "0")
        RunConsoleCommand("cl_show_splashes", "0")
        RunConsoleCommand("r_shadows", "0")
        RunConsoleCommand("r_3dsky", "0")
        RunConsoleCommand("r_lod", "2")
        RunConsoleCommand("mat_queue_mode", "-1")
        RunConsoleCommand("r_eyemove", "0")
        RunConsoleCommand("mp_decals", "0")
        RunConsoleCommand("r_drawflecks", "0")
        RunConsoleCommand("mat_bumpmap", "0")
        RunConsoleCommand("mat_motion_blur_enabled", "0")
        RunConsoleCommand("r_decalstaticprops", "0")
        RunConsoleCommand("r_cheapwaterstart", "1")
        RunConsoleCommand("r_cheapwaterend", "1")
        RunConsoleCommand("cl_ejectbrass", "0")
        RunConsoleCommand("r_teeth", "0")
        RunConsoleCommand("r_fastzreject", "-1")
        RunConsoleCommand("r_shadowrendertotexture", "0")
        RunConsoleCommand("r_drawmodeldecals", "0")
        RunConsoleCommand("r_rimlight", "0")
        RunConsoleCommand("r_eyes", "0")
        RunConsoleCommand("r_updaterefracttexture", "0")
        RunConsoleCommand("cl_phys_props_enable", "0")
        RunConsoleCommand("r_waterdrawrefraction", "0")
        RunConsoleCommand("r_WaterDrawReflection", "0")
        RunConsoleCommand("rope_smooth", "0")
        RunConsoleCommand("rope_wind_dist", "0")
        RunConsoleCommand("rope_shake", "0")
        RunConsoleCommand("mat_compressedtextures", "1")
        RunConsoleCommand("r_decal_cullsize", "20")
        RunConsoleCommand("cl_threaded_bone_setup", "1")
        RunConsoleCommand("mat_disable_fancy_blending", "1")
        RunConsoleCommand("mat_disable_lightwarp", "1")
        RunConsoleCommand("func_break_max_pieces", "0")
        RunConsoleCommand("props_break_max_pieces", "0")
        RunConsoleCommand("mat_parallaxmap", "0")
        RunConsoleCommand("mat_max_worldmesh_vertices", "0")
        RunConsoleCommand("mat_mipmaptextures", "1")
        RunConsoleCommand("r_sse2", "1")
        RunConsoleCommand("mat_disable_ps_patch", "1")
        RunConsoleCommand("mat_trilinear", "0")
        RunConsoleCommand("cl_forcepreload", "1")
        RunConsoleCommand("r_flashlightculldepth", "0")
        RunConsoleCommand("studio_queue_mode", "1")
        RunConsoleCommand("mat_diffuse", "1")
        RunConsoleCommand("snd_mix_async", "1")
        RunConsoleCommand("snd_async_fullyasync", "1")
        RunConsoleCommand("r_dynamiclighting", "0")
        RunConsoleCommand("r_waterforceexpensive", "0")
        RunConsoleCommand("sv_playerforcedupdate", "0")
        RunConsoleCommand("cl_pitchspeed", "0")
    end
end)

hook_Remove( "PreDrawHalos", "AddPhysgunHalos" )
hook_Remove( "PlayerTick", "TickWidgets" )
hook_Remove( "PreDrawHalos", "PropertiesHover" )
hook_Remove( "PostDrawEffects", "RenderHalos" )

-- Optimize garbage collection
local lastGC = SysTime()
local gcStepSize = 64

hook_Add("Think", "ManualGC", function()
    if SysTime() - lastGC >= 5 then
        collectgarbage("step", gcStepSize)
        lastGC = SysTime()
    end
end)

-- Remove these also
local GMItems = {
    "UpdateAnimation",
    "GrabEarAnimation",
    "MouthMoveAnimation",
    "DoAnimationEvent",
    "CalcViewModelView",
    "PreDrawViewModel",
    "PostDrawViewModel",
    "HUDPaint"
}

local NullPointer = function() end

for i = 1, #GMItems do
   GM[GMItems[i]] = NullPointer
end

-- Client fixes
function render.SupportsHDR()
    return false
end

function render.SupportsPixelShaders_2_0()
    return false
end

function render.SupportsPixelShaders_1_4()
    return false
end

function render.SupportsVertexShaders_2_0()
    return false
end

function render.GetDXLevel()
    return 80
end

-- Cvars
local blink_gc_memory = CreateClientConVar("blink_gc_memory", "5904.13", true, false, "Sets the amount of KB! before manually running a garbage collection.")
local blink_gc_enable = CreateClientConVar("blink_gc_enable", "1", true, false, "Activates Blink's Garbage Collection, if loaded disable, it will not load the rest of the script.")
local blink_gc_print = CreateClientConVar("blink_gc_print", "0", true, false, "Shows you your active memory being used in console.")

if not blink_gc_enable:GetBool() then return end

-- Collect garbage stuff
local function PrintMemory(message)
	if not blink_gc_print:GetBool() then return end
	MsgC(Color(115, 148, 248), message .. "\n")
end

--PrintMemory("Active Lua Memory : ".. math.Round(collectgarbage("count")/1024).. " MBytes.")
local function ClearLuaMemory()
	if not blink_gc_enable:GetBool() then return end
	local mem = collectgarbage("count")
	PrintMemory("Active Lua Memory : " .. math.Round(mem / 1024) .. " MB.")

	if mem >= math.Clamp(blink_gc_memory:GetInt(), 262144, 978944) then
		collectgarbage("collect")
		local nmem = collectgarbage("count")
		PrintMemory("Removed " .. math.Round((mem - nmem) / 1024) .. " MB from active memory.")
	end
end

--timer.Remove("Aggro_Lua_GC") -- For refreshing
timer.Create("Aggro_Lua_GC", 60, 0, ClearLuaMemory)

--ClearLuaMemory()
concommand.Add("blink_gc_luamemory", function()
	local LuaMem = collectgarbage("count")
	PrintMemory("Active Lua Memory : " .. math.Round(LuaMem / 1024) .. " MB.")
end)