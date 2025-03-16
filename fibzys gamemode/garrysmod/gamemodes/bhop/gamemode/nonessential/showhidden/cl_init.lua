local PREFIX_CLIPS = "ShowClips"
local PREFIX_TRIGGERS = "ShowTriggers"
local PREFIX_PROPS = "ShowProps"
local PREFIX_COLORS = {
	[PREFIX_CLIPS] =    Color(255, 0, 123, 200),
	[PREFIX_TRIGGERS] = Color(255, 192, 0, 200),
	[PREFIX_PROPS] =    Color(0, 255, 128, 200),
}

CreateClientConVar("bhop_alwaysshowtriggers", "0", true, false, "Always show triggers automatically on map load.", 0, 1)

local MaterialEnum = ShowHidden.MaterialEnum

local function ChatMessage(prefix, phrase)
	UTIL:AddMessage("Timer", language.GetPhrase(phrase))
end

local function PrintEnum(enum, prefix)
	for i = 1, enum.MAX do
		print(string.format("%3d. %s (%s)", i, language.GetPhrase(prefix .. i),
			table.KeyFromValue(enum, i)))
	end
	print("MaterialTypes: 0 - wireframe, 1 - default, 2 - solid color")
end

-- TODO: refactor this file

-- [[ ShowTriggers ]] --

local ShowHidden, TriggerType = ShowHidden, ShowHidden.TriggerType
local render, ipairs, IsValid = render, ipairs, IsValid

local TRACE_TIMEOUT = 5
local DEFAULT_TRIGGERS_COLORS = ShowHidden.DEFAULT_TRIGGERS_COLORS
local TRIGGERS_MATERIAL_NAMES = ShowHidden.TRIGGERS_MATERIAL_NAMES

local TRIGGERS_SOLID_MATERIAL = CreateMaterial("triggers_solid", "LightmappedGeneric", {
	["$basetexture"] = "color/white",
})

-- Convars
local cv_triggers = CreateClientConVar("showtriggers_enabled", "0", false, true, "Show or hide trigger brushes", 0, 1)
local cv_triggerTypes = CreateClientConVar("showtriggers_types", tostring(ShowHidden.ALL_TYPES),
true, false, "Enabled trigger types bit-mask", 0, ShowHidden.ALL_TYPES)

local g_triggerAppearTime = {}
local g_triggersCount = {}
local g_triggersColors = DEFAULT_TRIGGERS_COLORS

-- HACK: https://gist.github.com/swampservers/15f48ea3c0898a369a61e9e84e347e8d
-- TODO: fade alpha on client and set wireframe material on server
local LocalPlayer, CurTime = LocalPlayer, CurTime
hook.Add("Tick", "ShowTriggers.OverrideServer", function()
	local cutoff = CurTime() - (0.5 + (IsValid(LocalPlayer()) and LocalPlayer():Ping() / 1000 or 1))

	for ent, time in pairs(g_triggerAppearTime) do
		if not IsValid(ent) or ent:IsDormant() or time < cutoff then
			g_triggerAppearTime[ent] = nil
		else
			local triggerType = ent:GetNWInt("showtriggers_type", 0)
			if triggerType ~= 0 then
				local col = g_triggersColors[triggerType]

				ent:RemoveEffects(EF_NODRAW)
				ent:SetRenderMode(RENDERMODE_TRANSCOLOR)
				ent:SetMaterial(TRIGGERS_MATERIAL_NAMES[col.material])
				ent:SetSubMaterial(nil, TRIGGERS_MATERIAL_NAMES[col.material])
				ent:SetColor(col.color)
			end
		end
	end
end)

local function SetTriggerColor(ent, triggerType)
	local col = g_triggersColors[triggerType]
	if not col then return end

	local matName = TRIGGERS_MATERIAL_NAMES[col.material]
	local entCol = ent:GetColor()

	if matName ~= ent:GetMaterial() or col.color.r ~= entCol.r or col.color.g ~= entCol.g
	or col.color.b ~= entCol.b or col.color.a ~= entCol.a then
		g_triggerAppearTime[ent] = CurTime()
	end

	ent:RemoveEffects(EF_NODRAW)
	ent:SetRenderMode(RENDERMODE_TRANSCOLOR)
	ent:SetMaterial(matName)
	ent:SetColor(col.color)

	--[[ local text = language.GetPhrase("showtriggers.type." .. triggerType)
	debugoverlay.Cross(ent:GetPos(), 8, TRACE_TIMEOUT, col.color, true)
	debugoverlay.EntityTextAtPosition(ent:GetPos(), 1, text, TRACE_TIMEOUT) ]]
end

local function NetTriggerTypeProxy(ent, name, old, new)
	if not IsValid(ent) or ent:IsDormant() or not cv_triggers:GetBool()
	or not ShowHidden.CheckMask(cv_triggerTypes:GetInt(), new) then return end
	SetTriggerColor(ent, new)
end

local function HandleVisibleTrigger(ent, show)
	if not IsValid(ent) or not ShowHidden.TRACK_TRIGGERS[ent:GetClass()] then return end

	if show == false then
		g_triggerAppearTime[ent] = nil
		return
	end

	local triggerType = ent:GetNWInt("showtriggers_type", 0)
	if triggerType == 0 or not cv_triggers:GetBool() or not ShowHidden.CheckMask(cv_triggerTypes:GetInt(), triggerType) then
		ent:AddEffects(EF_NODRAW)
		ent:SetNWVarProxy("showtriggers_type", NetTriggerTypeProxy)
	else
		SetTriggerColor(ent, triggerType)
	end
end
hook.Add("NetworkEntityCreated", "ShowHidden.HandleCreatedTrigger", HandleVisibleTrigger)
hook.Add("NotifyShouldTransmit", "ShowHidden.HandleCreatedTrigger", HandleVisibleTrigger)

local function UpdateVisibleTriggers()
	local triggers = ents.FindByClass("trigger_*")
	for _, ent in ipairs(triggers) do
		if IsValid(ent) and not ent:IsDormant() then
			HandleVisibleTrigger(ent, true)
		end
	end
end

-- Recieve triggers count from server
net.Receive("ShowHidden.ShowTriggers", function()
	local enabledTypes = cv_triggerTypes:GetInt()
	local total = 0
	local enabled = 0

	for triggerType = 1, TriggerType.MAX do
		local count = net.ReadUInt(16)
		g_triggersCount[triggerType] = count

		total = total + count
		if ShowHidden.CheckMask(enabledTypes, triggerType) then
			enabled = enabled + count
		end
	end

	g_triggersCount[0] = total
	ShowHidden.UpdateCountTooltips()

	UpdateVisibleTriggers()
	-- print("[ShowTriggers]\tEnabled triggers: " .. enabled .. " / " .. total)
end)

local function ToggleTriggers(cv, old, new)
	local enabled = cv_triggers:GetBool()
	local types = cv_triggerTypes:GetInt()
	local toggle = cv == cv_triggers:GetName()

	if not enabled and not toggle then return end
	if not enabled or types > ShowHidden.ALL_TYPES or types < 0 then types = 0 end

	net.Start("ShowHidden.ShowTriggers")
	net.WriteUInt(types, 16)
	net.SendToServer()

	if old ~= new and toggle then
		ChatMessage(PREFIX_TRIGGERS, enabled and "showtriggers.msg.enabled" or "showtriggers.msg.disabled")
	end
end

-- AUTO ENABLE SHOWTRIGGERS ON SPAWN IF bhop_alwaysshowtriggers IS 1
hook.Add("InitPostEntity", "AutoEnableShowTriggersOnSpawn", function()
    if GetConVar("bhop_alwaysshowtriggers"):GetBool() then
        RunConsoleCommand("showtriggers_enabled", "1")
    end
end)

hook.Add("OnEntityCreated", "ForceTriggersWhenSpawning", function(ent)
    if ent:IsPlayer() and ent == LocalPlayer() then
        timer.Simple(0, function()
            if GetConVar("bhop_alwaysshowtriggers"):GetBool() then
                RunConsoleCommand("showtriggers_enabled", "1")
            end
        end)
    end
end)

-- Update material and color of trigger type
local function UpdateTriggerTypeMaterial(ply, cmd, args)
	if #args < 1 then
		print("Usage: " .. cmd .. " TRIGGER_TYPE MATERIAL_TYPE \"R G B A\"")
		PrintEnum(TriggerType, "showtriggers.type.")
		return
	end

	local triggerType = math.floor(tonumber(args[1]) or 0)
	if not table.KeyFromValue(TriggerType, triggerType) then
		PrintEnum(TriggerType, "showtriggers.type.")
		return
	end

	local default = DEFAULT_TRIGGERS_COLORS[triggerType]
	local material = math.floor(math.Clamp(tonumber(args[2]) or default.material, 0, 2))
	local color = args[3] and string.ToColor(args[3]) or table.Copy(default.color)

	g_triggersColors[triggerType] = { material = material, color = color }
	UpdateVisibleTriggers()
	ShowHidden.SaveConfig()
end
concommand.Add("showtriggers_material", UpdateTriggerTypeMaterial, nil, "Sets material and color for trigger type")

-- TODO: show targetname, filter and teleport dest? (+ outputs)
concommand.Add("showtriggers_trace", function()
	if not cv_triggers:GetBool() or cv_triggerTypes:GetInt() == 0 then return end
	local ply = LocalPlayer()
	local tr = util.TraceLine({
		start = ply:EyePos(),
		endpos = ply:EyePos() + ply:LocalEyeAngles():Forward() * 32768,
		mask = MASK_PLAYERSOLID_BRUSHONLY,
	})

	if not tr.Hit then return end
	debugoverlay.Line(tr.StartPos, tr.HitPos, TRACE_TIMEOUT)
	debugoverlay.Cross(tr.HitPos, 16, TRACE_TIMEOUT)

	local tbl = ents.FindAlongRay(tr.StartPos, tr.HitPos)
	for _, ent in ipairs(tbl) do
		if IsValid(ent) and ShowHidden.TRACK_TRIGGERS[ent:GetClass()] then
			local pos = ent:GetPos()
			local triggerType = ent:GetNWInt("showtriggers_type", 0)

			if triggerType ~= 0 then
				local color = g_triggersColors[triggerType].color
				local text = language.GetPhrase("showtriggers.type." .. triggerType)
				debugoverlay.Cross(pos, 8, TRACE_TIMEOUT, color, true)
				debugoverlay.EntityTextAtPosition(pos, 1, text, TRACE_TIMEOUT)
				print("[ShowTriggers]", text, ent, ent:GetPos())
			end
		end
	end
end, nil, "Show triggers info. Use: developer 1")

-- Convar callbacks
cvars.AddChangeCallback(cv_triggers:GetName(), ToggleTriggers, "showtriggers_enabled")
cvars.AddChangeCallback(cv_triggerTypes:GetName(), ToggleTriggers, "showtriggers_types")

-- [[ ShowClips ]] --

local BrushType = {
	PLAYER_CLIP = 1, -- Player and monster clips
	INVISIBLE = 2, -- Invisible but solid brushes
	LADDER = 3, -- Invisible ladders
	NO_DRAW = 4, -- NoDraw brushes
	SKYBOX = 5, -- SkyBox and Sky2D brushes
	MAX = 5,
}

local ALL_BRUSH_TYPES = math.pow(2, BrushType.MAX) - 1

local BRUSH_TEXTURE_NAME = {
	[BrushType.PLAYER_CLIP] =   "tools/toolsplayerclip",
	[BrushType.INVISIBLE] =     "tools/toolsinvisible",
	[BrushType.LADDER] =        "tools/toolsinvisibleladder",
	[BrushType.NO_DRAW] =       "tools/toolsnodraw",
	[BrushType.SKYBOX] =        "tools/toolsskybox",
}

local BRUSH_SEARCH_FLAGS = {
	[BrushType.PLAYER_CLIP] = { -(CONTENTS_PLAYERCLIP), SURF_NOLIGHT + SURF_NODRAW },
	[BrushType.INVISIBLE] = { CONTENTS_TRANSLUCENT + CONTENTS_GRATE, SURF_NOLIGHT + SURF_NODRAW + SURF_TRANS, "TOOLS/TOOLSINVISIBLE" },
	[BrushType.LADDER] = { CONTENTS_LADDER + CONTENTS_TRANSLUCENT + CONTENTS_GRATE, SURF_NOLIGHT + SURF_NODRAW },
	[BrushType.NO_DRAW] = { CONTENTS_SOLID, SURF_NOLIGHT + SURF_NODRAW, "TOOLS/TOOLSNODRAW" },
	[BrushType.SKYBOX] = { CONTENTS_SOLID, -SURF_SKY, "TOOLS/TOOLSSKYBOX" },
}

local DEFAULT_BRUSH_COLORS = {
	[BrushType.PLAYER_CLIP] =   { color = Color(255, 255, 255, 192), material = MaterialEnum.DEFAULT },
	[BrushType.INVISIBLE] =     { color = Color(255, 255, 255, 255), material = MaterialEnum.DEFAULT },
	[BrushType.LADDER] =        { color = Color(255, 255, 255, 255), material = MaterialEnum.DEFAULT },
	[BrushType.NO_DRAW] =       { color = Color(255, 255, 255, 128), material = MaterialEnum.DEFAULT },
	[BrushType.SKYBOX] =        { color = Color(255, 255, 255, 255), material = MaterialEnum.DEFAULT },
}

local cv_enabled = CreateClientConVar("showclips", "0", false, true, "Show or hide player-clip brushes", 0, ALL_BRUSH_TYPES)

local g_map = ShowHidden.luabsp.LoadMap(game.GetMap())
local g_brushesColors, g_brushesMaterials = DEFAULT_BRUSH_COLORS, {}
local g_brushesCount, g_brushMeshes, g_brushesDraw = {}, {}, {}

local function CreateBrushMaterial(brushType, mat)
	local name = "showclips_" .. brushType .. "_" .. mat

	if mat == MaterialEnum.WIREFRAME then
		return CreateMaterial(name, "Wireframe", {
			["$vertexalpha"] = 1,
			["$vertexcolor"] = 1,
		})
	end

	return CreateMaterial(name, "UnlitGeneric", {
		["$basetexture"] = mat == MaterialEnum.SOLID and "color/white" or BRUSH_TEXTURE_NAME[brushType],
        ["$vertexalpha"] = 1,
        ["$vertexcolor"] = 1,
	})
end

local function UpdateBrushMaterial(brushType, mat, color)
	local material = CreateBrushMaterial(brushType, mat)
	material:SetFloat("$alpha", color.a / 255)
	material:SetVector("$color", color:ToVector())
	g_brushesMaterials[brushType] = material
end

local function LoadBrushes(brushTypes, cb)
	if table.Count(g_brushMeshes) == 0 then
		ChatMessage(PREFIX_CLIPS, "showclips.msg.lags")
	end

	timer.Simple(0.1, function()
		-- Handle errors
		local ok, err = pcall(function()
			for brushType = 1, BrushType.MAX do
				if bit.band(brushTypes, bit.lshift(1, brushType - 1)) ~= 0 and not g_brushMeshes[brushType] then
					local flags = BRUSH_SEARCH_FLAGS[brushType]
					g_brushMeshes[brushType], g_brushesCount[brushType] =
						g_map:GetBrushesMeshFiltered(flags[1], flags[2], flags[3], true)
				end
			end
		end)
		if not ok then g_brushMeshes[brushType] = {} end
		cb(ok, err)
	end)
end

local function DrawClipBrushes()
	render.OverrideDepthEnable(true, true)
	for brushType, _ in pairs(g_brushesDraw) do
		render.SetMaterial(g_brushesMaterials[brushType])
		g_brushMeshes[brushType]:Draw()
	end
	render.OverrideDepthEnable(false)
end

local function ToggleClipBrushes(cv, old, new)
	local types = cv_enabled:GetInt()
	if types > ALL_BRUSH_TYPES or types < 0 then types = 0 end

	if types == 0 then
		hook.Remove("PostDrawOpaqueRenderables", "bhop_showclips")
		if old == "1" then
			ChatMessage(PREFIX_CLIPS, "showclips.msg.disabled")
		end
	else
		LoadBrushes(types, function(ok, err)
			if not ok then
				ChatMessage(PREFIX_CLIPS, "showclips.msg.error")
				print("[ShowClips]\tError:", err)
				cv_enabled:SetInt(0)
				return
			end

			for brushType = 1, BrushType.MAX do
				if bit.band(types, bit.lshift(1, brushType - 1)) ~= 0 then
					local mat = g_brushesColors[brushType]
					UpdateBrushMaterial(brushType, mat.material, mat.color)
					g_brushesDraw[brushType] = true

					--[[ print("[ShowClips]", string.format("Enabled %d brushes of type %s (%d)",
						g_brushesCount[brushType], table.KeyFromValue(BrushType, brushType), brushType)) ]]
				else
					g_brushesDraw[brushType] = nil
				end
			end

			hook.Add("PostDrawOpaqueRenderables", "bhop_showclips", DrawClipBrushes)
			ShowHidden.UpdateCountTooltips()

			if types == BrushType.PLAYER_CLIP then
				ChatMessage(PREFIX_CLIPS, "showclips.msg.enabled")
			end
		end)
	end
end

local function UpdateBrushTypeMaterial(ply, cmd, args)
	if #args < 1 then
		print("Usage: " .. cmd .. " BRUSH_TYPE MATERIAL_TYPE \"R G B A\"")
		PrintEnum(BrushType, "showclips.type.")
		return
	end

	local brushType = math.floor(tonumber(args[1]) or 0)
	if not BRUSH_SEARCH_FLAGS[brushType] then
		PrintEnum(BrushType, "showclips.type.")
		return
	end

	local default = DEFAULT_BRUSH_COLORS[brushType]
	local material = math.floor(math.Clamp(tonumber(args[2]) or default.material, 0, 2))
	local color = args[3] and string.ToColor(args[3]) or table.Copy(default.color)

	g_brushesColors[brushType] = { material = material, color = color }
	UpdateBrushMaterial(brushType, material, color)
	ShowHidden.SaveConfig()
end
concommand.Add("showclips_material", UpdateBrushTypeMaterial, nil, "Sets material and color for brush type")

-- Convar callbacks
cvars.AddChangeCallback(cv_enabled:GetName(), ToggleClipBrushes, "showclips")

-- [[ ShowProps ]] --

local DEFAULT_PROPS_COLOR = { color = Color(127, 255, 255, 192), material = MaterialEnum.WIREFRAME }

local g_propsColor = DEFAULT_PROPS_COLOR
local g_propsMaterial, g_staticProps

local cv_props = CreateClientConVar("showprops", "0", false, true, "Toggle static props collision meshes", 0, 1)

local function UpdatePropsMaterial(mat, color)
	if mat == MaterialEnum.SOLID then
		g_propsMaterial = CreateMaterial("showprops_" .. mat, "UnlitGeneric", {
			["$basetexture"] = "color/white",
			["$vertexalpha"] = 1,
			["$vertexcolor"] = 1,
		})
	else
		g_propsMaterial = CreateMaterial("showprops_" .. mat, "Wireframe", {
			["$vertexalpha"] = 1,
			["$vertexcolor"] = 1,
			["$ignorez"] = mat == MaterialEnum.DEFAULT and 1 or 0
		})
	end
	g_propsMaterial:SetFloat("$alpha", color.a / 255)
	g_propsMaterial:SetVector("$color", color:ToVector())
end

local function GetModelCollisionMesh(model)
	-- TODO: add support for SOLID_BBOX
	-- TODO: ignore ERROR models?
    local ent = ents.CreateClientProp(model)
    ent:Spawn()
    local phys = ent:GetPhysicsObject()
    if not IsValid(phys) then return nil end
    local m = Mesh()
    m:BuildFromTriangles(phys:GetMesh())
    ent:Remove()
    return m
end

local function LoadStaticProps(cb)
	if not g_staticProps then
		ChatMessage(PREFIX_PROPS, "showclips.msg.lags")
	end

	timer.Simple(0.1, function()
		-- Handle errors
		local ok, err = pcall(function()
			if not g_map.static_props then
				g_map:LoadStaticProps()
			end

			local modelToMesh = {}
			g_staticProps = {}
			for _, lump in ipairs(g_map.static_props) do
				for i, prop in ipairs(lump.entries) do
					if prop.Solid ~= SOLID_VPHYSICS then do return end end
					local obj = modelToMesh[prop.PropType] or GetModelCollisionMesh(prop.PropType)
					if not obj then do return end end

					local matrix = Matrix()
					if prop.Origin then matrix:Translate(prop.Origin) end
					if prop.Angles then matrix:Rotate(prop.Angles) end
					if prop.Scale then matrix:Scale(Vector(prop.Scale, prop.Scale, prop.Scale)) end

					table.insert(g_staticProps, { obj, matrix })
					modelToMesh[prop.PropType] = obj
				end
			end
		end)
		if not ok then g_staticProps = {} end
		cb(ok, err)
	end)
end

local function DrawStaticProps()
	render.OverrideDepthEnable(true, true)
	render.SetMaterial(g_propsMaterial)
    for _, model in pairs(g_staticProps) do
		cam.PushModelMatrix(model[2])
		model[1]:Draw()
		cam.PopModelMatrix()
    end
	render.OverrideDepthEnable(false)
end

local function ToggleStaticProps(cv, old, new)
	local enable = cv_props:GetBool()

	if enable then
		LoadStaticProps(function(ok, err)
			if not ok then
				ChatMessage(PREFIX_PROPS, "showclips.msg.error")
				print("[ShowProps]\tError:", err)
				cv_props:SetInt(0)
				return
			end

			UpdatePropsMaterial(g_propsColor.material, g_propsColor.color)
			hook.Add("PostDrawOpaqueRenderables", "bhop_showprops", DrawStaticProps)
			ShowHidden.UpdateCountTooltips()

			ChatMessage(PREFIX_PROPS, "showclips.props.enabled")
		end)
	else
		hook.Remove("PostDrawOpaqueRenderables", "bhop_showprops")
		ChatMessage(PREFIX_PROPS, "showclips.props.disabled")
	end
end

local function ChangePropsMaterial(ply, cmd, args)
	if #args < 1 then
		print("Usage: " .. cmd .. " MATERIAL_TYPE \"R G B A\"")
		return
	end

	local default = DEFAULT_PROPS_COLOR
	local material = math.floor(math.Clamp(tonumber(args[1]) or default.material, 0, 2))
	local color = args[2] and string.ToColor(args[2]) or table.Copy(default.color)

	g_propsColor = { material = material, color = color }
	UpdatePropsMaterial(material, color)
	ShowHidden.SaveConfig()
end
concommand.Add("showprops_material", ChangePropsMaterial, nil, "Sets material and color for static props")

cvars.AddChangeCallback(cv_props:GetName(), ToggleStaticProps, "showclips")

-- [[ Config ]] --

function ShowHidden.SaveConfig()
	file.Write("showhidden.json", util.TableToJSON({
		triggers = g_triggersColors,
		brushes = g_brushesColors,
		props = g_propsColor,
	}, false))
end

local function sanitizeColor(col, default)
	return {
		material = math.floor(math.Clamp(tonumber(col.material) or default.material, 0, 2)),
		color = istable(col.color) and Color(
			math.floor(math.Clamp(tonumber(col.color.r) or default.color.r, 0, 255)),
			math.floor(math.Clamp(tonumber(col.color.g) or default.color.g, 0, 255)),
			math.floor(math.Clamp(tonumber(col.color.b) or default.color.b, 0, 255)),
			math.floor(math.Clamp(tonumber(col.color.a) or default.color.a, 0, 255))
		) or table.Copy(default.color),
	}
end

function ShowHidden.LoadConfig()
	local cfg = util.JSONToTable(file.Read("showhidden.json", "DATA") or "") or {}

	cfg.triggers = istable(cfg.triggers) and cfg.triggers or {}
	cfg.brushes = istable(cfg.brushes) and cfg.brushes or {}
	g_triggersColors, g_brushesColors = {}, {}

	for _, t in pairs(TriggerType) do
		local default, col = DEFAULT_TRIGGERS_COLORS[t], cfg.triggers[t]
		g_triggersColors[t] = istable(col) and sanitizeColor(col, default) or table.Copy(default)
	end
	for _, t in pairs(BrushType) do
		local default, col = DEFAULT_BRUSH_COLORS[t], cfg.brushes[t]
		g_brushesColors[t] = istable(col) and sanitizeColor(col, default) or table.Copy(default)
	end
	g_propsColor = istable(cfg.props) and sanitizeColor(cfg.props, DEFAULT_PROPS_COLOR)
		or table.Copy(DEFAULT_PROPS_COLOR)
end

ShowHidden.LoadConfig()

-- [[ GUI ]] --

local MAT_ALPHA_GRID = Material("gui/alpha_grid.png", "noclamp")

local g_configMenu = nil

local PANEL_MATCOLOR = {}

function PANEL_MATCOLOR:Init()
	self.Material = nil
	self.AutoSize = false
	self:SetColor(color_white)

	self:SetMouseInputEnabled(true)
	self:SetKeyboardInputEnabled(false)
end

function PANEL_MATCOLOR:SetMaterial(mat, color, triggerType)
	local name = "ShowHidden2_" .. mat .. "_" .. (triggerType or "")
	local texture = "color/white" -- MaterialEnum.SOLID
	if triggerType and mat == MaterialEnum.DEFAULT then
		texture = triggerType < 0 and BRUSH_TEXTURE_NAME[-triggerType] or "tools/toolstrigger"
	end

	if mat == MaterialEnum.WIREFRAME or (not triggerType and mat == MaterialEnum.DEFAULT) then
		self.Material = CreateMaterial(name, "Wireframe", { ["$vertexalpha"] = 1 })
	else
		self.Material = CreateMaterial(name, "UnlitGeneric", {
			["$basetexture"] = texture,
			["$vertexalpha"] = 1,
		})
	end
	self.Color = color
	self.Material:SetFloat("$alpha", self.Color.a / 255)
	self.Material:SetVector("$color", self.Color:ToVector())

	self:SetTooltip(string.format(language.GetPhrase("showhidden.material_tooltip"),
		language.GetPhrase("showhidden.mat." .. mat), string.FromColor(color)))
end

function PANEL_MATCOLOR:Paint(w, h)
	surface.SetMaterial(MAT_ALPHA_GRID)
	surface.SetDrawColor(color_white:Unpack())
	surface.DrawTexturedRectUV(0, 0, w, h, 0, 0, w / 128, h / 128)

	if self.Material then
		surface.SetMaterial(self.Material)
		surface.SetDrawColor(self.Color:Unpack())
		surface.DrawTexturedRect(0, 0, w, h)
	end

	surface.SetDrawColor(color_black:Unpack())
	self:DrawOutlinedRect()
	return true
end

vgui.RegisterTable(PANEL_MATCOLOR, "Material")

local function getColMatValues(triggerType)
	if not triggerType then
		return table.Copy(DEFAULT_PROPS_COLOR), table.Copy(g_propsColor), "#showclips.props"
	elseif triggerType < 0 then
		return table.Copy(DEFAULT_BRUSH_COLORS[-triggerType]),
			table.Copy(g_brushesColors[-triggerType]), "#showclips.type." .. -triggerType
	end
	return table.Copy(DEFAULT_TRIGGERS_COLORS[triggerType]),
		table.Copy(g_triggersColors[triggerType]), "#showtriggers.type." .. triggerType
end

local function OpenMaterialPicker(triggerType, cb)
	local props, clip = not triggerType, false
	if triggerType then clip = triggerType < 0 end
	local default, initial, text = getColMatValues(triggerType)
	local current = table.Copy(initial)

	local mixer = nil
	local matPanels = {}

	local function update(material, color)
		local new = {
			material = material or current.material,
			color = color or current.color,
		}
		new.color = ColorAlpha(new.color, new.color.a)

		if current.material == new.material and current.color == new.color then return end
		current = new

		mixer:SetColor(new.color)
		mixer:SetBaseColor(new.color)
		for mat, matPan in ipairs(matPanels) do
			matPan:SetMaterial(mat, new.color, triggerType)
		end

		if isfunction(cb) then cb(new.material, new.color) end
	end

	local pan = vgui.Create("DPanel")
	pan:SetPaintBorderEnabled(false)
	pan:SetPaintBackgroundEnabled(false)
	pan:DockPadding(4, 4, 4, 4)
	pan:SetSize(300, 300)

	function pan:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(127, 127, 127, 127))
		surface.SetDrawColor(0, 255, 0, 255)
		surface.DrawOutlinedRect(300 - 3 - 36 * (current.material + 1), 5, 34, 34, 1)
    end

	local m = DermaMenu()
	m:AddPanel(pan)

	local mats = vgui.Create("DPanel", pan)
	mats:SetPaintBackground(false)
	mats:SetHeight(32)
	mats:DockMargin(2, 2, 2, 6)
	mats:Dock(TOP)

	for _, material in pairs(MaterialEnum) do
		local mat = vgui.CreateFromTable(PANEL_MATCOLOR, mats)
		mat:SetMaterial(material, current.color, triggerType)
		mat:SetSize(32, 32)
		mat:Dock(RIGHT)
		mat:DockMargin(4, 0, 0, 0)
		mat:SetTooltip("#showhidden.mat." .. material)
		mat.DoClick = function() update(material, nil) end
		matPanels[material] = mat
	end

	local matLab = vgui.Create("DLabel", mats)
	matLab:SetText(text)
	matLab:Dock(FILL)
	matLab:SetTextColor(color_black)
	matLab:SetContentAlignment(6) -- right center

	mixer = vgui.Create("DColorMixer", pan)
	mixer:Dock(FILL)
	mixer:SetPalette(true)
	mixer:SetAlphaBar(true)
	mixer:SetWangs(true)
	mixer:SetColor(current.color)
	mixer:SetBaseColor(current.color)
	mixer:DockMargin(2, 2, 2, 2)
	mixer.ValueChanged = function(self, color)
		update(nil, color)
	end

	local buttons = vgui.Create("DPanel", pan)
	buttons:SetPaintBackground(false)
	buttons:SetHeight(24)
	buttons:DockMargin(2, 6, 2, 2)
	buttons:Dock(BOTTOM)

	local def = buttons:Add("DButton")
	def:SetText("#default")
	def:Dock(LEFT)
	def:DockMargin(0, 0, 4, 0)
	def.DoClick = function() update(default.material, default.color) end

	local reset = buttons:Add("DButton")
	reset:SetText("#showhidden.reset")
	reset:Dock(LEFT)
	reset.DoClick = function() update(initial.material, initial.color) end

	local close = buttons:Add("DButton")
	close:SetText("#close")
	close:Dock(RIGHT)
	close.DoClick = function()
		m:Hide()
		m:Remove()
	end

	m:Open()
	return m
end

local function OpenConfigMenu()
	local w = vgui.Create("DFrame")
	w:SetSize(250, 300)
	w:DockPadding(2, 24, 2, 2)
	w:SetTitle("#showhidden.title")
	w:SetDeleteOnClose(true)
    w:ShowCloseButton(false)
	w:SetDraggable(true)
	w:SetSizable(true)

	function w:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(42, 42, 42))
    end

    local closeBt = vgui.Create("DImageButton", w)
    closeBt:SetPos(250 - 20, 4)
    closeBt:SetSize(16, 16)
    closeBt:SetImage("icon16/cross.png")
    closeBt.DoClick = function()
        w:Close()
    end

	local function addSwitch(triggerType, parent)
		local default, col, text, enab = getColMatValues(triggerType)
		if not triggerType then
			enab = cv_props:GetBool()
		elseif triggerType < 0 then
			enab = ShowHidden.CheckMask(cv_enabled:GetInt(), -triggerType)
		else
			enab = ShowHidden.CheckMask(cv_triggerTypes:GetInt(), triggerType)
		end

		local pan = vgui.Create("DPanel", parent)
		pan:SetPaintBackground(false)
		pan:SetHeight(24)
		pan:DockMargin(2, 2, 2, 2)
		pan:Dock(TOP)

		local mat = vgui.CreateFromTable(PANEL_MATCOLOR, pan)
		mat:SetMaterial(col.material, col.color, triggerType)
		mat:SetSize(24, 24)
		mat:DockMargin(0, 0, 4, 0)
		mat:Dock(LEFT)

		local function update(material, color)
			mat:SetMaterial(material, color, triggerType)

			if not triggerType then
				g_propsColor.material, g_propsColor.color = material, color
				UpdatePropsMaterial(material, color)
			elseif triggerType < 0 then
				g_brushesColors[-triggerType].material = material
				g_brushesColors[-triggerType].color = color
				UpdateBrushMaterial(-triggerType, material, color)
			else
				g_triggersColors[triggerType].material = material
				g_triggersColors[triggerType].color = color
				UpdateVisibleTriggers()
			end
		end

		mat.DoClick = function()
			OpenMaterialPicker(triggerType, update)
		end
		mat.DoRightClick = function()
			update(default.material, default.color)
		end

		local check = pan:Add("DCheckBoxLabel")
		check:SetText(text)
		check:SetChecked(enab)
		check:DockMargin(0, 4, 0, 4)
		check:Dock(FILL)
		check:SetTextColor(color_white)

		if not triggerType then
			check:SetConVar(cv_props:GetName())
			return pan
		end

		check.OnChange = function(self, checked)
			local types = triggerType < 0 and cv_enabled:GetInt() or cv_triggerTypes:GetInt()
			local cv = triggerType < 0 and cv_enabled or cv_triggerTypes
			cv:SetInt(checked and bit.bor(types, bit.rol(1, math.abs(triggerType) - 1))
				or bit.band(types, bit.bnot(bit.rol(1, math.abs(triggerType) - 1))))
		end

		return pan
	end

	local function panelPaint(pan, w, h)
		draw.RoundedBox(4, 0, 0, w, h, Color(32, 32, 32))
	end

	local clipsPan = w:Add("DPanel")
	clipsPan:DockPadding(2, 2, 2, 2)
	clipsPan:DockMargin(2, 2, 2, 2)
	clipsPan:Dock(TOP)
	clipsPan.Paint = panelPaint

	local brushes = {}
	for brushType = 1, BrushType.MAX do
		brushes[brushType] = addSwitch(-brushType, clipsPan)
	end

	local trigPan = w:Add("DPanel")
	trigPan:DockPadding(2, 2, 2, 2)
	trigPan:DockMargin(2, 2, 2, 2)
	trigPan:Dock(TOP)
	trigPan.Paint = panelPaint

	local enabTrig = trigPan:Add("DCheckBoxLabel")
	enabTrig:SetText("#showtriggers.gui.enable")
	enabTrig:SetChecked(cv_triggers:GetBool())
	enabTrig:SetConVar(cv_triggers:GetName())
	enabTrig:SizeToContents()
	enabTrig:DockMargin(30, 8, 2, 8)
	enabTrig:SetTextColor(color_white)
	enabTrig:Dock(TOP)

	local trigs = {}
	for triggerType = 1, TriggerType.MAX do
		trigs[triggerType] = addSwitch(triggerType, trigPan)
	end

	local propsPan = w:Add("DPanel")
	propsPan:DockPadding(2, 2, 2, 2)
	propsPan:DockMargin(2, 2, 2, 2)
	propsPan:SetHeight(32)
	propsPan:Dock(TOP)
	propsPan.Paint = panelPaint

	local enabProps = addSwitch(nil, propsPan)

	local close = w:Add("DButton")
	close:SetText("#close")
	close:Dock(TOP)
	close:DockMargin(2, 4, 2, 4)
	close.DoClick = function() w:Close() end

	function w.UpdateCountTooltips()
		enabProps:SetTooltip(language.GetPhrase("showhidden.count") .. (g_staticProps and #g_staticProps or "N/A"))
		enabTrig:SetTooltip(language.GetPhrase("showhidden.count") .. (g_triggersCount[0] or "N/A"))

		local enab = cv_triggers:GetBool()
		for triggerType = 1, TriggerType.MAX do
			trigs[triggerType]:SetTooltip(language.GetPhrase("showhidden.count") .. (g_triggersCount[triggerType] or "N/A"))
			trigs[triggerType]:SetEnabled(enab)
		end

		for brushType = 1, BrushType.MAX do
			local count = g_brushesCount[brushType] -- g_brushMeshes[brushType] and #g_brushMeshes[brushType] or g_brushesCount[brushType]
			brushes[brushType]:SetTooltip(language.GetPhrase("showhidden.count") .. (count or "N/A"))
		end
	end

	w.OnClose = function()
		g_configMenu = nil
		UpdateVisibleTriggers()
		ShowHidden.SaveConfig()
	end

	clipsPan:InvalidateLayout(true)
	clipsPan:SizeToChildren(false, true)
	trigPan:InvalidateLayout(true)
	trigPan:SizeToChildren(false, true)
	w:InvalidateLayout(true)
	w:SizeToChildren(false, true)
	w:SetTall(w:GetTall() + 2)
	w.UpdateCountTooltips()

	w:Center()
	local x, y = w:GetPos()
	w:SetPos(4, y)
	w:MakePopup()
	g_configMenu = w
	return w
end

function ShowHidden.UpdateCountTooltips()
	if g_configMenu then g_configMenu.UpdateCountTooltips() end
end

concommand.Add("showhidden", OpenConfigMenu, nil, "Open PlayerClips and ShowTriggers settings menu")