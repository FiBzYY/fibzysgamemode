UTIL = UTIL or {}

local normalmat = Material(BHOP.Zone.ZoneMaterial)

-- Zone drawing wireframe support, and flat zone support
function UTIL:DrawZoneTypes(min, max, colour, normal, pos, thickness, flatzone)
    if not colour or not min or not max then return end

    local vec = Vector
    local drawbeams = render.DrawBeam
    local overlap = 0.5

    -- Fix missing spaces
    local function ExtendBeam(p1, p2)
        if not p1 or not p2 then return p1, p2 end
        local direction = (p2 - p1):GetNormalized()
        return p1 - direction * overlap, p2 + direction * overlap
    end

    local set1_1 = vec(min.x, min.y, min.z)
    local set1_2 = vec(min.x, max.y, min.z)
    local set1_3 = vec(max.x, max.y, min.z)
    local set1_4 = vec(max.x, min.y, min.z)

    local set2_1 = vec(min.x, min.y, max.z)
    local set2_2 = vec(min.x, max.y, max.z)
    local set2_3 = vec(max.x, max.y, max.z)
    local set2_4 = vec(max.x, min.y, max.z)

    if flatzone then
        render.SetMaterial(normalmat)

        local s1, e1 = ExtendBeam(set1_1, set1_2)
        local s2, e2 = ExtendBeam(set1_2, set1_3)
        local s3, e3 = ExtendBeam(set1_3, set1_4)
        local s4, e4 = ExtendBeam(set1_4, set1_1)

        drawbeams(s1, e1, thickness, 0, 1, colour)
        drawbeams(s2, e2, thickness, 0, 1, colour)
        drawbeams(s3, e3, thickness, 0, 1, colour)
        drawbeams(s4, e4, thickness, 0, 1, colour)

    elseif normal then
        render.SetMaterial(normalmat)

        local s1, e1 = ExtendBeam(set1_1, set1_2)
        local s2, e2 = ExtendBeam(set1_2, set1_3)
        local s3, e3 = ExtendBeam(set1_3, set1_4)
        local s4, e4 = ExtendBeam(set1_4, set1_1)

        local s5, e5 = ExtendBeam(set2_1, set2_2)
        local s6, e6 = ExtendBeam(set2_2, set2_3)
        local s7, e7 = ExtendBeam(set2_3, set2_4)
        local s8, e8 = ExtendBeam(set2_4, set2_1)

        local s9,  e9  = ExtendBeam(set1_1, set2_1)
        local s10, e10 = ExtendBeam(set1_2, set2_2)
        local s11, e11 = ExtendBeam(set1_3, set2_3)
        local s12, e12 = ExtendBeam(set1_4, set2_4)

        drawbeams(s1, e1, thickness, 0, 1, colour)
        drawbeams(s2, e2, thickness, 0, 1, colour)
        drawbeams(s3, e3, thickness, 0, 1, colour)
        drawbeams(s4, e4, thickness, 0, 1, colour)
        drawbeams(s5, e5, thickness, 0, 1, colour)
        drawbeams(s6, e6, thickness, 0, 1, colour)
        drawbeams(s7, e7, thickness, 0, 1, colour)
        drawbeams(s8, e8, thickness, 0, 1, colour)
        drawbeams(s9, e9, thickness, 0, 1, colour)
        drawbeams(s10, e10, thickness, 0, 1, colour)
        drawbeams(s11, e11, thickness, 0, 1, colour)
        drawbeams(s12, e12, thickness, 0, 1, colour)

    else
        render.DrawWireframeBox(pos, Angle(0, 0, 0), min, max, colour, true)
    end
end

cache_player_names = {}

-- Get players name
function UTIL:GetPlayerName(x)
	if type(x) == 'string' then 
		x = util.SteamIDTo64(x)
	end 

    if cache_player_names[x] then 
        return cache_player_names[x]
    else 
		cache_player_names[x] = "Loading..."
		
        steamworks.RequestPlayerInfo(x, function(name)
            cache_player_names[x] = name 
		end)
		
        return cache_player_names[x]
    end 
end 

-- Networked chat messages
if CLIENT then 
	NETWORK:GetNetworkMessage("ChatMessage", function(c, data)
		local pref = data[1]
		local msg = data[2]
		UTIL:AddMessage(pref, unpack(msg))
	end)

	NETWORK:GetNetworkMessage("ConsoleMessage", function(c, data)
		local pref = data[1]
		local msg = data[2]
		UTIL:AddConsoleMessage(pref, unpack(msg))
	end)
end

-- Colors and prefix names
UTIL.Colour = {
	["Timer"] = Color(0, 132, 255),
	["Timer Info"] = Color(0, 132, 255),
	["General"] = Color(52, 152, 219),
	["Admin"] = Color(244, 66, 66),
	["Notification"] = Color(231, 76, 60),
	["Radio"] = Color(230, 126, 34),
	["VIP"] = Color(174, 0, 255),
	["Server"] = Color(255, 101, 0),
	["AntiCheat"] = Color(186, 85, 211),
	["Hint"] = Color(0, 200, 200),
	["Settings"] = Color(255, 200, 255),
	["Paint"] = Color(0, 0, 255),
 	["RTV"] = Color(255, 0, 255),
  	["EdgeHelper"] = Color(255, 105, 180),
  	["SSJTop"] = Color(255, 105, 180),    

	["White"] = Color(255, 255, 255),
	["Green"] = Color(107, 142, 35),
	["Red"] = Color(255, 0, 0)
}

-- Messages for client
function UTIL:AddMessage(prefix, ...)
	if not prefix then 
		chat.AddText(color_white, ...)
		return
	end

	local c = self.Colour[prefix]
	chat.AddText(c, prefix, Color(200, 200, 200), " | ", color_white, ...)
end

-- Console messages
function UTIL:AddConsoleMessage(prefix, ...)
	if not prefix then 
		MsgC(color_white, ...)
		return
	end

	local c = self.Colour[prefix]
	MsgC(c, prefix, Color(200, 200, 200), " | ", color_white, ...)
end

if SERVER then 
	function UTIL:Print(target, prefix, ...)
		local msg = {...} 
		NETWORK:StartNetworkMessage(target, "ChatMessage", prefix, msg)
	end

	function UTIL:AddConsole(target, prefix, ...)
		local msg = {...} 
		NETWORK:StartNetworkMessage(target, "ConsoleMessage", prefix, msg)
	end
end

function UTIL:SendMessage(target, prefix, ...)
    if SERVER then
        self:Print(target, prefix, ...)
    elseif CLIENT then
        self:AddMessage(prefix, ...)
    end
end

function UTIL:SendConsoleMessage(target, prefix, ...)
    if SERVER then
        self:AddConsole(target, prefix, ...)
    elseif CLIENT then
        self:AddConsoleMessage(prefix, ...)
    end
end

local blur = Material("pp/blurscreen")

-- Blur HUD
function UTIL:DrawBlurRect(x, y, w, h, rep, c)
	for i = 1, rep do 
		surface.SetMaterial(blur)	
		surface.SetDrawColor(c or Color(255, 255, 255, 255))
		blur:SetFloat("$blur", 3)
		render.UpdateScreenEffectTexture()
		surface.SetMaterial(blur)
		surface.DrawTexturedRect(x, y, w, h)
	end
end

-- Server side notify
function UTIL:Notify(c, p, m)
    MsgC(c, p, color_white, " | ", m, "\n")
end

function UTIL:FindValueInTable(var, tab)
	for k, v in pairs(tab) do 
		if var == v then 
			return k 
		end 
	end 

	return false 
end 

function UTIL:FindValueInTable(var, tab)
	for k, v in pairs(tab) do 
		if var == v then 
			return k 
		end 
	end 
	return false 
end 

-- Find a player
function UTIL:FindPlayer(name)
	name = string.lower(name)
	players = {}

	for player_id, player_ent in pairs(player.GetAll()) do 
		local player_name = string.lower(player_ent:Name())
		if string.match(player_name, string.PatternSafe(name)) ~= nil then 
			table.insert(players, player_ent)
		end
	end

	if (#players == 0) then 
		return false 
	end 

	return (#players == 1 and players[1] or players)
end

function GetDefaultSetting(name, fallback)
    return tostring(BHOP.DefaultSettings[name] or fallback)
end

-- to create convars (client)
function UTIL:CreateSetting(name, fallback, archive, replicated, help, min, max)
    return CreateClientConVar(name, GetDefaultSetting(name, fallback), archive or true, replicated or false, help, min, max)
end

-- Color changes
DynamicColors = {
    TextColor = Color(255, 255, 255),
    TextColorJhud = Color(255, 255, 255),
    PanelColor = Color(255, 255, 255),
    RankColors = {}
}

if CLIENT then
    CreateClientConVar("bhop_use_custom_color", "0", true, false, "Enable custom static color")
    CreateClientConVar("bhop_color", "0 255 0", true, false, "Custom RGB color as string (like 255 0 0)")
end

function GeneratePlayerColors(ply)
    if CLIENT then
        if GetConVar("bhop_use_custom_color"):GetBool() then
            local colStr = GetConVar("bhop_color"):GetString()
            local r, g, b = string.match(colStr, "(%d+)%s+(%d+)%s+(%d+)")
            r, g, b = tonumber(r) or 255, tonumber(g) or 255, tonumber(b) or 255

            local customColor = Color(math.Clamp(r, 0, 255), math.Clamp(g, 0, 255), math.Clamp(b, 0, 255))

            DynamicColors.TextColor = customColor
            DynamicColors.PanelColor = customColor
            DynamicColors.TextColorJhud = customColor
            DynamicColors.RankColors = {}
            return
        end

        local hue = math.Clamp(tonumber(math.random(0, 359)) or 0, 0, 359)
        local neonSaturation = 1
        local neonValue = 0.9
        DynamicColors.TextColor = HSVToColor(hue, neonSaturation, neonValue)
        DynamicColors.PanelColor = HSVToColor(hue, neonSaturation * 0.9, neonValue * 0.8)

        local jhudHue = hue
        if (hue >= 0 and hue <= 60) or (hue >= 300 and hue <= 359) then
            jhudHue = 120
        end
        DynamicColors.TextColorJhud = HSVToColor(jhudHue, neonSaturation, neonValue)
        DynamicColors.RankColors = {}
    end
end

hook.Add("Initialize", "AssignPlayerColors", function()
    timer.Simple(0.2, function()
        GeneratePlayerColors(ply)
    end)
end)

if SERVER then
    util.AddNetworkString("SendDynamicColor")

    hook.Add("PlayerInitialSpawn", "SetupDynamicColor", function(ply)
        ply.DynamicColor = Color(255, 255, 255) 
    end)

    net.Receive("SendDynamicColor", function(len, ply)
        local r = net.ReadUInt(8)
        local g = net.ReadUInt(8)
        local b = net.ReadUInt(8)
        ply.DynamicColor = Color(r, g, b)
    end)
end

-- Color Sender
if CLIENT then
    hook.Add("Initialize", "SendColorToServer", function()
        timer.Simple(1, function()
            GeneratePlayerColors(LocalPlayer())

            local col = DynamicColors.TextColor or Color(255, 255, 255)
            net.Start("SendDynamicColor")
            net.WriteUInt(col.r, 8)
            net.WriteUInt(col.g, 8)
            net.WriteUInt(col.b, 8)
            net.SendToServer()
        end)
    end)
end

-- Math --
FLT_EPSILON = 1.192092896e-07

function GetVectorLength(v)
    return math.sqrt(v[1] * v[1] + v[2] * v[2] + v[3] * v[3])
end

function VectorClone(vec)
    return {vec[1], vec[2], vec[3]}
end

-- VectorScale should modify vec directly
function VectorScale(vec, scale)
    vec[1] = vec[1] * scale
    vec[2] = vec[2] * scale
    vec[3] = vec[3] * scale
    return vec
end

function DotProduct(vec1, vec2)
    return vec1[1] * vec2[1] + vec1[2] * vec2[2] + vec1[3] * vec2[3]
end

-- Convert angles to vectors
function AngleVectors(angles, forward, right, up)
    local angle
    local sr, sp, sy, cr, cp, cy

    angle = angles[2] * (math.pi * 2 / 360)
    sy = math.sin(angle)
    cy = math.cos(angle)

    angle = angles.p * (math.pi * 2 / 360)
    sp = math.sin(angle)
    cp = math.cos(angle)

    angle = angles.r * (math.pi * 2 / 360)
    sr = math.sin(angle)
    cr = math.cos(angle)

    if forward then
        forward[1] = cp * cy
        forward[2] = cp * sy
        forward[3] = -sp
    end

    if right then
        right[1] = (-1 * sr * sp * cy) + (-1 * cr * -sy)
        right[2] = (-1 * sr * sp * sy) + (-1 * cr * cy)
        right[3] = -1 * sr * cp
    end

    if up then
        up[1] = (cr * sp * cy) + (-sr * -sy)
        up[2] = (cr * sp * sy) + (-sr * cy)
        up[3] = cr * cp
    end
end

function DotProductVector(vec1, vec2)
    return vec1:Dot(vec2)
end

function VectorMA(startVec, scale, dirVec, destVec)
    destVec[1] = startVec[1] + dirVec[1] * scale
    destVec[2] = startVec[2] + dirVec[2] * scale
    destVec[3] = startVec[3] + dirVec[3] * scale
end

function VectorCopy(fromVec, toVec)
    toVec[1] = fromVec[1]
    toVec[2] = fromVec[2]
    toVec[3] = fromVec[3]
end

function VectorToArray(vec)
    return {vec[1], vec[2], vec[3]}
end

function IsEqual(a, b)
    return a[1] == b[1] and a[2] == b[2] and a[3] == b[3]
end

function CloseEnough(a, b, eps)
    eps = eps or FLT_EPSILON
    return math.abs(a[1] - b[1]) <= eps
        and math.abs(a[2] - b[2]) <= eps
        and math.abs(a[3] - b[3]) <= eps
end

function RSqrt(a)
    return 1 / math.sqrt(a)  -- no sse so we do this
end

function VectorNormalize(vec)
    local sqrlen = vec[1] * vec[1] + vec[2] * vec[2] + vec[3] * vec[3] + FLT_EPSILON

    local invlen = RSqrt(sqrlen)

    vec[1] = vec[1] * invlen
    vec[2] = vec[2] * invlen
    vec[3] = vec[3] * invlen

    return sqrlen * invlen
end

function VectorNormalizeFallback(vec)
    local length = math.sqrt(vec[1] * vec[1] + vec[2] * vec[2] + vec[3] * vec[3])

    if length ~= 0.0 then
        vec[1] = vec[1] / length
        vec[2] = vec[2] / length
        vec[3] = vec[3] / length
    else
        vec[1], vec[2], vec[3] = 0, 0, 1
    end

    return length
end

function VectorSubtract(a, b, result)
    result[1] = a[1] - b[1]
    result[2] = a[2] - b[2]
    result[3] = a[3] - b[3]
end

function VectorAdd(a, b, result)
    result[1] = a[1] + b[1]
    result[2] = a[2] + b[2]
    result[3] = a[3] + b[3]
end

function CrossProduct(a, b)
    return a[2] * b[3] - a[3] * b[2],
           a[3] * b[1] - a[1] * b[3],
           a[1] * b[2] - a[2] * b[1]
end

function RandomVector(minVal, maxVal)
    return math.random() * (maxVal - minVal) + minVal,
           math.random() * (maxVal - minVal) + minVal,
           math.random() * (maxVal - minVal) + minVal
end

function MIN(a, b)
    return a < b and a or b
end

function VectorMultiply(a, b, result)
    result[1] = a[1] * b[1]
    result[2] = a[2] * b[2]
    result[3] = a[3] * b[3]
end

function VectorDivide(a, b, result)
    assert(b[1] ~= 0, "Division by zero at x")
    assert(b[2] ~= 0, "Division by zero at y")
    assert(b[3] ~= 0, "Division by zero at z")

    result[1] = a[1] / b[1]
    result[2] = a[2] / b[2]
    result[3] = a[3] / b[3]
end

function IsVectorZero(vec)
    return vec[1] == 0 and vec[2] == 0 and vec[3] == 0
end

function SimpleSpline(value)
    return value * value * (3 - 2 * value)
end

-- Movement UTIL --
HullDuck = Vector(16, 16, 45)
HullStand = Vector(16, 16, 62)

VEC_DUCK_VIEW = Vector(0, 0, 47)
VEC_VIEW = Vector(0, 0, 64)
VEC_HULL_MIN = Vector(-16, -16, 0)
VEC_HULL_MAX = Vector(16, 16, 62)
VEC_DUCK_HULL_MIN = Vector(-16, -16, 0)
VEC_DUCK_HULL_MAX = Vector(16, 16, 45)

-- Crouching functions
function FullyDucked(ply)
    return ply:KeyDown(IN_DUCK) and ply:IsFlagSet(FL_DUCKING)
end

function Ducking(ply)
    return ply:KeyDown(IN_DUCK) and not ply:IsFlagSet(FL_DUCKING)
end

function UnDucking(ply)
    return not ply:KeyDown(IN_DUCK) and ply:IsFlagSet(FL_DUCKING)
end

function NotDucked(ply)
    return not Ducking(ply) and not FullyDucked(ply) and not UnDucking(ply)
end

-- Normalize Angle
function normalizeAngle(angle)
    while angle > 180 do
        angle = angle - 360
    end

    while angle < -180 do
        angle = angle + 360
    end
    return angle
end