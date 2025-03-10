local ID = "claz_sm_menu"
util.AddNetworkString(ID)

local MenuMeta = {}
MenuMeta.__index = MenuMeta

local g_menus = {}
local g_lastId = 0

function MenuMeta:SetTitle(title)
	self._title = title
end

function MenuMeta:AddItem(key, text, disabled)
	table.insert(self._items, {
		key = key or "", text = text or "", disabled = disabled,
	})
end

function MenuMeta:Display(ply, duration)
	self._endTime = duration ~= 0 and RealTime() + duration or 0
	self._ply = ply

	net.Start(ID)
	net.WriteUInt(self._id, 32)
	net.WriteString("display")
	net.WriteUInt(duration, 32)
	net.WriteString(self._title)
	net.WriteUInt(#self._items, 16)
	for i, item in ipairs(self._items) do
		net.WriteUInt(item.disabled and 1 or 0, 8)
		net.WriteString(item.key)
		net.WriteString(item.text)
	end
	net.Send(ply)

	g_menus[self._id] = self
end

function MenuMeta:Close()
	net.Start(ID)
	net.WriteUInt(self._id, 32)
	net.WriteString("close")
	net.Send(self._ply)

	g_menus[self._id] = nil
end

function MenuMeta:Callback(ply, action, key)
	if not self._callback or ply ~= self._ply then return end
	return self._callback(self, ply, action, key)
end

net.Receive(ID, function(len, ply)
	if len < 48 then return end

	local id = net.ReadUInt(32)
	local m = g_menus[id]

	if not m then return end

	local action = net.ReadString()
	local key = net.ReadString()

	m:Callback(ply, action, key)
end)

local function SourceModMenu(callback)
	g_lastId = g_lastId + 1

	local m = {
		_callback = callback,
		_status = "",
		_title = "",
		_items = {},
		_id = g_lastId,
	}

	return setmetatable(m, MenuMeta)
end

return SourceModMenu
