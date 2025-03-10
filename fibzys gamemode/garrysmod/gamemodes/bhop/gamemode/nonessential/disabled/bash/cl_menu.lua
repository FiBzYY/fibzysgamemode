local ID = "claz_sm_menu"

local g_menus = {}
local g_keycodeHandler = nil

-- TODO: open menu from client-side

local function SendMenuResponse(id, action, key)
	net.Start(ID)
		net.WriteUInt(id, 32)
		net.WriteString(action)
		net.WriteString(key or "")
	net.SendToServer()
end

local function OpenMenu(m)
	local w = vgui.Create("DFrame")
	w:DockPadding(4, 4, 4, 4)
	w:SetSize(250, 350)
	w:SetMinHeight(200)
	w:SetMinWidth(150)
	w:SetTitle("")
	w:SetSizable(true)
	w:SetDraggable(true)
	w:SetDeleteOnClose(true)

	w.OnClose = function()
		g_keycodeHandler = nil
		if w._close_key then
			surface.PlaySound("buttons/button10.wav")
			SendMenuResponse(m._id, "end", w._close_key)
		end
	end

	local hotKeys = {
		[KEY_0] = function() w:Close() end,
	}

	function w.Paint(_, w, h)
		draw.RoundedBox(4, 0, 0, w, h, Color(32, 32, 32, 220))
	end

	g_keycodeHandler = function(keyCode)
		local func = hotKeys[keyCode]
		if func then func() end
	end

	local lab = vgui.Create("DLabel", w)
	lab:SetAutoStretchVertical(true)
	lab:DockMargin(2, 0, 2, 8)
	lab:SetText(m._title)
	lab:SetFont("Trebuchet18")
	lab:Dock(TOP)
	lab:SizeToContentsY()
	lab:SetWrap(true)

	local pan = vgui.Create("DScrollPanel", w)
	pan:DockMargin(0, 0, 2, 4)
	pan:Dock(FILL)

	if m._duration ~= 0 then
		local prog = vgui.Create("DProgress", w)
		prog:DockMargin(2, 2, 2, 2)
		prog:SetHeight(16)
		prog:Dock(BOTTOM)
		prog:SetFraction(0)

		prog.Think = function()
			prog:SetFraction((m._endTime - RealTime()) / m._duration)
		end
	end

	for i, item in ipairs(m._items) do
		local bt = vgui.Create("DButton")
		local text = #item.text ~= 0 and item.text or language.GetPhrase(item.key) or ""
		bt:SetPaintBackground(false)
		bt:SetFGColor(200, 200, 200, 250)
		bt:SetContentAlignment(4)
		bt:SetFont("Trebuchet18")
		bt:SetHeight(24)

		function bt.Paint(_, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(200, 200, 200, 250))
		end

		if item.key == "cancel" then
			bt:SetText("  9. " .. text)
			bt:DockMargin(2, 2, 2, 2)
			bt:Dock(BOTTOM)
			bt.DoClick = function()
				surface.PlaySound("garrysmod/ui_return.wav")
				SendMenuResponse(m._id, "cancel", "")
				w._close_key = nil
				w:Close()
			end
			hotKeys[KEY_9] = bt.DoClick
			w:Add(bt)
		else
			bt:DockMargin(2, 2, 0, 2)
			bt:Dock(TOP)
			if item.disabled then
				bt:SetText(" " .. text)
				bt:SetEnabled(false)
				if item.key == "mono" then
					bt:SetFont("DebugFixed")
				end
			else
				bt:SetText(string.format(" %2d. ", i) .. text)
				bt.DoClick = function()
					surface.PlaySound("garrysmod/ui_click.wav")
					SendMenuResponse(m._id, "select", item.key or "")
					w._close_key = nil
					w:Close()
				end
				if i < 10 then hotKeys[KEY_0 + i] = bt.DoClick end
			end
			pan:Add(bt)
		end
	end

	pan:InvalidateLayout(true)
	pan:SizeToChildren(false, true)
	w:InvalidateLayout(true)
	w:SizeToChildren(false, true)

	w:Center()
	local x, y, width, height = w:GetBounds()
	w:SetPos(4, y)

	m._frame, w._close_key = w, "user"
	g_menus[m._id] = m
end

hook.Add("PlayerButtonDown", ID, function(ply, key)
	if not g_keycodeHandler or not IsFirstTimePredicted() then return end
	g_keycodeHandler(key)
end)

local function CloseMenu(id, key)
	local m = g_menus[id]
	if not m then return end

	local w = m._frame
	if IsValid(w) then
		w._close_key = key
		w:Close()
	end

	g_menus[id] = nil
	timer.Remove(ID .. tostring(id))
end

net.Receive(ID, function()
	local id = net.ReadUInt(32)
	local action = net.ReadString()

	if action == "close" then
		CloseMenu(id)
		return
	end

	if action == "display" then
		local m = {
			_id = id,
			_duration = net.ReadUInt(32),
			_title = net.ReadString(),
			_items = {},
		}

		local size = net.ReadUInt(16)
		for i = 1, size do
			table.insert(m._items, {
				disabled = net.ReadUInt(8) ~= 0,
				key = net.ReadString(),
				text = net.ReadString(),
			})
		end

		m._endTime = m._duration ~= 0 and RealTime() + m._duration or 0
		OpenMenu(m)

		if m._duration == 0 then return end
		timer.Create(ID .. tostring(id), m._duration, 0, function()
			CloseMenu(id, "timeout")
		end)
	end
end)

--[[concommand.Add("open_claz_menu", function()
    local m = {
        _id = math.random(1, 10000),
        _duration = 0, -- No timeout
        _title = "Sample Menu",
        _items = {
            { key = "option1", text = "Option 1" },
            { key = "option2", text = "Option 2" },
            { key = "cancel", text = "Cancel" }
        },
        _endTime = 0
    }

    OpenMenu(m)
end)--]]