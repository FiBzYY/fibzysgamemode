print("first")
-- Convert time to ticks
local function ConvertTime(ticks, fractionalTicks)
    if not ticks or type(ticks) ~= "number" or ticks < 0 then
        return "00:00.00"
    end

    local ns = (ticks + (fractionalTicks or 0) / 10000) * TickInterval
    local wholeSeconds = fl(ns)
    local milliseconds = fl((ns - wholeSeconds) * 1000)

    local hours = fl(wholeSeconds / 3600)
    local minutes = fl((wholeSeconds / 60) % 60)
    local seconds = wholeSeconds % 60

    milliseconds = fl(milliseconds / 10)

    if hours > 0 then
        return fo("%d:%.2d:%.2d.%.2d", hours, minutes, seconds, milliseconds)
    else
        return fo("%.2d:%.2d.%.2d", minutes, seconds, milliseconds)
    end
end

-- Replay Trail
local trailConfig = {
    ["blue"] = CreateClientConVar("bhop_trail_blue", "1", true, false, "Set trail color to blue when faster than trail speed.", 0, 1),
    ["range"] = CreateClientConVar("bhop_trail_range", "500", true, false, "Increase trail visibility range.", 0, 1),
    ["ground"] = CreateClientConVar("bhop_trail_ground", "0", true, false, "Show trails only when on the ground.", 0, 1),
    ["vague"] = CreateClientConVar("bhop_trail_vague", "0", true, false, "Make trails more transparent.", 0, 1),
    ["label"] = CreateClientConVar("bhop_trail_label", "0", true, false, "Hide trail labels.", 0, 1),
    ["hud"] = CreateClientConVar("bhop_trail_hud", "0", true, false, "Hide trail HUD.", 0, 1)
}

local function UpdateSettings()
    for _, ent in ipairs(ents.FindByClass("ent_point")) do
        ent:LoadConfig()
    end
end

for _, cvar in pairs(trailConfig) do
    cvars.AddChangeCallback(cvar:GetName(), function()
        UpdateSettings()
    end)
end

function GetTrailConfig(name)
    return trailConfig[name]:GetBool()
end

local st, lp, Iv, ey, ler, con, gt, near, col, cw, cd, rat, fr, lst = SysTime, LocalPlayer, IsValid, EyeAngles, Lerp, ConvertTime, TIMER.GetTimeDifference, { pos = Vector() }, { r = 255, g = 0, b = 0, a = 80 }, Color( 255, 255, 255 ), Color( 40, 40, 40 ), 100, 150
local tac, tal = TEXT_ALIGN_CENTER, TEXT_ALIGN_LEFT
local DrawMat, DrawBeam, DrawText = render.SetMaterial, render.DrawBeam, draw.DrawText
local CamStart, CamEnd = cam.Start3D2D, cam.End3D2D
local tickRate = (0.1 / engine.TickInterval())


hook.Add( "HUDPaint", "PaintBotRoute", function()
print("loadhud")
	if IsValid( near.ent ) and near.ent.vis and not near.ent.nohud then

	print("loadhudin")
		local e, dh, h = near.ent, ScrH() / 2, 18
		local d1 = "Bot " .. e.drawvel .. " (Delta: " .. math.Round( lp():GetVelocity():Length2D() - e:GetPosVel() ) .. " u/s)"
		DrawText( e.drawid, "HUDTimer", 33, dh + 1, cd, tal, tac )
		DrawText( e.drawid, "HUDTimer", 32, dh, cw, tal, tac )
		DrawText( d1, "HUDTimer", 33, dh + h * 1 + 1, cd, tal, tac )
		DrawText( d1, "HUDTimer", 32, dh + h * 1, cw, tal, tac )
		
		local d2, d3 = "Bot Time: " .. con( e.time ) .. gt( e.time ), "Your times:"
		DrawText( d2, "HUDTimer", 33, dh + h * 2 + 1, cd, tal, tac )
		DrawText( d2, "HUDTimer", 32, dh + h * 2, cw, tal, tac )
		
		local tc = #e.times
		if tc > 0 then
			DrawText( d3, "HUDTimer", 33, dh + h * 4 + 1, cd, tal, tac )
			DrawText( d3, "HUDTimer", 32, dh + h * 4, cw, tal, tac )
			
			for i = 1, tc do
				local ti = e.times[ i ].Text
				DrawText( ti, "HUDTimer", 33, dh + h * (4 + i) + 1, cd, tal, tac )
				DrawText( ti, "HUDTimer", 32, dh + h * (4 + i), cw, tal, tac )
			end
		end
	end
end )

print("sec")

net.Receive("Trailer", function()
    lst = net.ReadUInt(8)
    fr = net.ReadUInt(12)
    local ratio = net.ReadDouble()
    rat = math.Clamp(ratio, 80, ratio)

    -- 🔍 DEBUG LOG
    print("[Trailer] Received net message ✅")
    print("[Trailer] lst (style):", lst)
    print("[Trailer] fr (frame ref):", fr)
    print("[Trailer] ratio:", ratio)
end)


local function DrawCol( e, c, n )
	if e.blue and n > 1 then
		c.r = 0
		c.g = ler( n - 1, 0, 255 )
		c.b = 255
	else
		c.r = ler( 2 * n - 1, 255, 0 )
		c.g = ler( n * 2, 0, 255 )
		c.b = 0
	end

	c.a = e.alpha and 5 or 80
end

function ENT:LoadConfig()
	self.blue     = GetTrailConfig("blue")
	self.range    = GetTrailConfig("range")
	self.ground   = GetTrailConfig("ground")
	self.alpha    = GetTrailConfig("vague")
	self.nolandmark = GetTrailConfig("label")
	self.nohud    = GetTrailConfig("hud")
end

function ENT:GetPosVel()
	return self.estvel or self:GetVel()
end

function ENT:Initialize()
	print("[TrailInit] 🚀 Initializing ent_point...")
	
	self.tcol = cw
	self.col = table.Copy(col)
	self.mat = Material("flow/timer.png")
	self.lastc = 1e10
	self.prev = 0

	local id = self:GetID()
	print("[TrailInit] 🔍 ID:", id)

	self.queueid = id > 1 and (id - 1) / 100 + 1 or id
	self.drawid = "- Landmark " .. self.queueid .. " -"
	self.drawvel = "Velocity: " .. self:GetVel() .. " u/s"
	self.style = 1
	self.time = math.Clamp(id - fr, 0, id) / rat
	print("[TrailInit] 🕓 Time:", self.time)
	print("[TrailInit] 🎯 QueueID:", self.queueid)

	self.neighbors = {}
	self.times = {}
	self.groundpos = {}

	local calc = self:GetPos()
	print("[TrailInit] 📍 Position:", calc)

	for i = 1, 9 do
		local func = self["GetNeighbor" .. i]
		self.Neighbor = func
		local vec = self:Neighbor()

		if vec != Vector(0, 0, 0) then
			print("[TrailInit] 🤝 Neighbor #" .. i .. " →", vec)
			self.neighbors[#self.neighbors + 1] = vec

			if not self.estvel then
				self.estvel = math.Round((vec - calc):Length2D() * tickRate)
				print("[TrailInit] ⚡ Est. Velocity:", self.estvel)
			end
		end
	end

	self.neighborc = #self.neighbors
	print("[TrailInit] 📦 Total Neighbors:", self.neighborc)

	if self.estvel then
		self.drawvel = "Velocity: " .. self.estvel .. " u/s"
	end

	-- Find next point
	for _, e in pairs(ents.FindByClass("ent_point")) do
		if e.queueid == self.queueid + 1 and e.style == self.style then
			print("[TrailInit] ✅ Found Next Point for QueueID:", self.queueid)
			self.nextpoint = e
			break
		end
	end

	-- Ground check
	for i = 0, self.neighborc do
		local vec = self.neighbors[i]
		if i == 0 then
			vec = self:GetPos()
		elseif not vec then
			continue
		end

		local r = util.QuickTrace(vec, Vector(0, 0, -16), player.GetAll())
		if r.Hit then
			print("[TrailInit] 🏁 Ground Hit at:", vec)
			self.groundpos[#self.groundpos + 1] = vec
		end
	end

	print("[TrailInit] ✅ Finished Initialize for ID:", id)
end


function ENT:Think()

	print("test")
	if lst != self.style then
		self.vis = nil
		self.draw = nil
		return
	else
		if not self.draw then
			self:LoadConfig()
		end

		self.draw = true
	end

	local dist, prev = (self:GetPos() - lp():GetPos()):Length(), self.vis
	self.vis = (not self.range and true or (dist < math.Clamp( lp():GetVelocity():Length() * 2, 1000, 5000 )))

	if self.vis and not prev then
		hook.Add( "PostDrawTranslucentRenderables", "RenderRoute" .. self:EntIndex(), function()
			if Iv( self ) then
				self:DrawAll()
			end
		end )
	elseif not self.vis and prev then
		hook.Remove( "PostDrawTranslucentRenderables", "RenderRoute" .. self:EntIndex() )
	end

	if not self.nextpoint and self.queueid then
		for _,e in pairs( ents.FindByClass( "game_point" ) ) do
			if e.queueid == self.queueid + 1 and e.style == self.style then
				self.nextpoint = e
				break
			end
		end
	end

	if dist < (near.pos - lp():GetPos()):Length() then
		local e = near.ent
		if Iv( e ) and e != self and e.rect then
			local dat = {
				Vel = lp():GetVelocity():Length2D(),
				Time = e.rect
			}

			local add = #e.times == 0
			for at,tab in pairs( e.times ) do
				if dat.Time < tab.Time then
					add = at
					break
				end
			end

			if add and dat.Vel > 80 then
				if add == true then add = 1 end

				dat.DiffVel = e:GetPosVel() - dat.Vel
				dat.DiffTime = dat.Time - e.time
				dat.Text = "- " .. con( dat.Time ) .. " [" .. (dat.DiffTime > 0 and "+" or "-") .. con( math.abs( dat.DiffTime ) ) .. "] (Bot Velocity " .. (dat.DiffVel > 0 and "+" or "") .. math.Round( dat.DiffVel ) .. " u/s)"

				table.insert( e.times, add, dat )

				if #e.times > 4 then
					table.remove( e.times, #e.times )
				end
			end
		end

		near.ent = self
		near.pos = self:GetPos()
	end

	if near.ent == self then
		local comp = math.abs( dist - self.prev )
		if comp < self.lastc then
			self.lastc = comp

			local _,t = gt( 0 )
			self.rect = t != 0 and t
		end
	else
		self.lastc = 1e10
	end

	self.prev = dist
end

function ENT:Draw() end
function ENT:DrawAll()

	print("test")
	if lst == 0 or not self.draw then return end

	DrawCol( self, self.col, (lp():GetVelocity():Length2D() - self:GetPosVel() + 500) / 500 )
	DrawMat( self.mat )

	if self.ground then
		for i = 1, #self.groundpos do
			DrawBeam( self.groundpos[ i ], self.groundpos[ i ] + Vector( 0, 0, 32 ), 1, 0, 1, self.col )
		end
	else
		if self.neighbors[ 1 ] then
			DrawBeam( self:GetPos(), self.neighbors[ 1 ], 3, 0, 1, self.col )
		end

		for i = 1, self.neighborc - 1 do
			DrawBeam( self.neighbors[ i ], self.neighbors[ i + 1 ], 3, 0, 1, self.col )
		end

		if Iv( self.nextpoint ) then
			DrawBeam( self.neighbors[ self.neighborc ], self.nextpoint:GetPos(), 3, 0, 1, self.col )
		end
	end

	if not self.nolandmark then
		local a = Angle( 0, ey().y - 90, 90 )
		a:RotateAroundAxis( a:Right(), 0 )

		CamStart( self:GetPos() + a:Up() * 0, a, 0.2 )
		DrawText( self.drawid, "HUDFont", 1, -49, cd, tac )
		DrawText( self.drawid, "HUDFont", 0, -50, self.tcol, tac )
		DrawText( self.drawvel, "HUDFont", 1, -31, cd, tac )
		DrawText( self.drawvel, "HUDFont", 0, -32, self.tcol, tac )
		CamEnd()
	end
end
