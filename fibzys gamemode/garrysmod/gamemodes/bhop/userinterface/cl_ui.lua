UI = UI or {}
DATA = DATA or {}

UI.ActiveNumberedUIPanel = false

-- Cache
local Iv, lp = LocalPlayer, LocalPlayer
local activeNotifications = {}
local DrawText = draw.SimpleText

CreateClientConVar("bhop_show_notifications", 1, true, false, "Enable or disable the pop-up notifications", 0, 1)

-- Notifications
function ShowPopupNotification(title, text, duration)
    if not GetConVar("bhop_show_notifications"):GetBool() then return end

    local tempLabel = vgui.Create("DLabel")
    tempLabel:SetFont("hud.subtitle")
    tempLabel:SetText(text)
    tempLabel:SizeToContents()

    local textWidth = math.min(tempLabel:GetWide() + 40, ScrW() - 20)
    tempLabel:Remove()

    local notification = vgui.Create("DNotify")
    notification:SetSize(textWidth, 50)
    notification:SetPos(ScrW() - textWidth - 10, 10)
    notification:SetLife(duration or 5)

    local fullPanel = vgui.Create("DPanel", notification)
    fullPanel:SetSize(notification:GetWide(), notification:GetTall())
    fullPanel:SetBackgroundColor(Color(0, 0, 0, 200))

    local titleBar = vgui.Create("DPanel", fullPanel)
    titleBar:SetSize(fullPanel:GetWide(), 20)
    titleBar:Dock(TOP)
    titleBar:SetBackgroundColor(Color(35, 35, 35))

    local titleLabel = vgui.Create("DLabel", titleBar)
    titleLabel:Dock(LEFT)
    titleLabel:DockMargin(10, 0, 0, 0)
    titleLabel:SetText(title)
    titleLabel:SetTextColor(UTIL.Colour["Timer"])
    titleLabel:SetFont("hud.subtitle")
    titleLabel:SizeToContents()

    local bgPanel = vgui.Create("DPanel", fullPanel)
    bgPanel:Dock(FILL)
    bgPanel:SetBackgroundColor(Color(42, 42, 42))

    local label = vgui.Create("DLabel", bgPanel)
    label:Dock(FILL)
    label:SetText(text)
    label:SetTextColor(Color(255, 255, 255))
    label:SetFont("hud.subtitle")
    label:SetContentAlignment(5)

    notification:AddItem(fullPanel)

    timer.Simple(duration or 5, function()
        if IsValid(notification) then
            notification:Remove()
        end
    end)
end

net.Receive("ShowPopupNotification", function()
    local title = net.ReadString()
    local text = net.ReadString()
    local duration = net.ReadFloat()

    ShowPopupNotification(title, text, duration)
end)

local theme = theme.getTheme(THEME_UI).settings.scheme 

UI_PRIMARY = theme["Primary"]
UI_SECONDARY = theme["Secondary"]
UI_TRI = theme["Tri"]
UI_ACCENT = theme["Accent"]
UI_TEXT1 = theme["Main Text"]
UI_TEXT2 = theme["Secondary Text"]
UI_HIGHLIGHT = theme["Highlight"]

-- Allow changing of these variables 
hook.Add("theme.update", "UpdateUIVariables", function(type, theme)
	theme = theme.settings.scheme 

	UI_PRIMARY = theme["Primary"]
	UI_SECONDARY = theme["Secondary"]
	UI_TRI = theme["Tri"]
	UI_ACCENT = theme["Accent"]
	UI_TEXT1 = theme["Main Text"]
	UI_TEXT2 = theme["Secondary Text"]
	UI_HIGHLIGHT = theme["Highlight"]
end)

function UI:NumberedUIPanel(title, ...)
	-- Options
	local options = {...}

	-- Let's create our panel
	local pan = vgui.Create("DPanel")

	-- Page options
	pan.hasPages = #options > 7 and true or false
	pan.page = 1

	-- Positioning and Sizing
	local width = 225
	local height = 125 + ((pan.hasPages and 9 or #options) * 20)
	pan.trueHeight = height
	local xPos, yPos = 20, (ScrH() / 2) - (height / 2)

	-- Set up
	pan:SetSize(width, height)
	pan:SetPos(xPos, yPos)
	pan.title = title
	pan.options = options

	-- Our theme
	local theme, id = Theme:GetPreference("NumberedUI")
	pan.themec = theme["Colours"]
	pan.themet = theme["Toggles"]
	pan.themeid = id

	-- Remove other numbered panel if open
	if (self.ActiveNumberedUIPanel) then
		self.ActiveNumberedUIPanel:Exit()
	end

	-- Check if there's a toggleable boolean in the options, and if there is set a prefix.
	-- Also lets get the largest option by name length here as well.
	local largest = ""
	for index, option in pairs(pan.options) do
		if (option.bool ~= nil) then
			local o1 = option.customBool and option.customBool[1] or "ON"
			local o2 = option.customBool and option.customBool[2] or "OFF"
			option.defname = option.name
			option.name = option.name .. ": " .. (option.bool and o1 or o2) .. " "
		end

		largest = (#option.name > #largest) and option.name or largest
	end

	-- Get width of largest option
	surface.SetFont(pan.themeid == "nui.css" and "hud.numberedui.css2" or "hud.numberedui.kawaii1")
	local w, y = surface.GetTextSize(largest)

	-- Set the panels width larger than default if the text width goes beyond it.
	if (w > 180) then
		pan:SetWide(w + 40)
	end

	-- Paint the panel
	-- Todo: Themes, the style should be changeable
	pan.Paint = function(self, width, height)
		-- Our theme
		local theme, id = Theme:GetPreference("NumberedUI")
		self.themec = theme["Colours"]
		self.themet = theme["Toggles"]
		self.themeid = id

		-- Options we gotta print
		local start = 1 + ((self.page - 1) * 7)
		local finish = ((self.page - 1) * 7) + 7

		-- Counter Strike: Source 
		if (self.themeid == "nui.css") then 
			-- Colours
			local base = self.themec["Primary Colour"]
			local title = Color(255, 165, 0) -- self.themec["Title Colour"]
			local text = color_white

			-- Print the box
			draw.RoundedBox(16, 0, 0, width, height, base)

			-- Title
			draw.SimpleText(self.title, "hud.numberedui.css1", 10, 15, title, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

			-- Options
			local i = 1
			for index = start, finish do
				-- No option
				if (not self.options[index]) then break end

				local option = self.options[index]
				draw.SimpleText(i .. ". " .. option.name, "hud.numberedui.css2", 10, 28 + (i * 25), option.col and option.col or text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				i = i + 1
			end

			-- Index
			local index = self.hasPages and 7 or #self.options

			-- Exit
			draw.SimpleText("0. Exit", "hud.numberedui.css2", 10, 35 + ((index + (self.hasPages and 3 or 1)) * 25), title, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

			-- Pages?
			if (self.hasPages) then
				draw.SimpleText("8. Previous", "hud.numberedui.css2", 10, 35 + ((index + 1) * 25), title, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				draw.SimpleText("9. Next", "hud.numberedui.css2", 10, 35 + ((index + 2) * 25), title, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end
		elseif (self.themeid == "nui.kawaii") then
			-- Colours
			local base = self.themec["Primary Colour"]
			local base2 = self.themec["Secondary Colour"]
			local text = self.themec["Text Colour"]
			local title = self.themec["Title Colour"]

			surface.SetDrawColor(base)
			surface.DrawRect(0, 0, width, height)

			surface.SetDrawColor(62, 62, 62)
			surface.DrawOutlinedRect(0, 0, width, height, 5)

			draw.SimpleText(
				self.title,
				"hud.titlekawaii",
				width / 2, 20,
				title,
				TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER
			)

			-- Line
			surface.SetDrawColor(Color(255, 255, 255)) -- white line
			surface.DrawRect(10, 35, width - 20, 1)

			-- Options
			local i = 1
			for index = start, finish do
				if not self.options[index] then break end

				local option = self.options[index]
				draw.SimpleText(
					i .. ". " .. option.name,
					"hud.numberedui.kawaii1",
					10, 35 + (i * 25),
					option.col or text,
					TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER
				)
				i = i + 1
			end

			local index = self.hasPages and 7 or #self.options
			draw.SimpleText(
				"0. Exit",
				"hud.numberedui.kawaii1",
				10, 35 + ((index + (self.hasPages and 3 or 1)) * 25),
				text,
				TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER
			)

			if self.hasPages then
				draw.SimpleText("8. Previous", "hud.numberedui.kawaii1", 10, 35 + ((index + 1) * 25), text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				draw.SimpleText("9. Next", "hud.numberedui.kawaii1", 10, 35 + ((index + 2) * 25), text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end
		end
	end
 
	-- Think
	pan.keylimit = false
	pan.Think = function(self)
		local key = -1

		-- Get current key down
		for id = 1, 10 do
			if input.IsKeyDown(id) then
				key = id - 1
				break
			end
		end

		-- Check if player is typing
		if (lp and IsValid(lp()) and lp():IsTyping()) or gui.IsConsoleVisible() then
			key = -1 
		end

		-- Call custom function set by the option
		if (key > 0) and (key <= 9) and (not self.keylimit) then
			if (key == 8) and (self.hasPages) then
				if (self.page == 1) then 
					self:OnPrevious(self.page == 1)
				else
					self.page = (self.page == 1 and 1 or self.page - 1)
					self:OnPrevious()
				end
			elseif (key == 9) and (self.hasPages) then
				local max = math.ceil(#self.options / 7)
				self.page = self.page == max and self.page or self.page + 1
				self:OnNext(self.page == max)
				self:UpdateLongestOption()
			else
				local pageAddition = (self.page - 1) * 7
				if (not self.options[key + pageAddition]) or (not self.options[key + pageAddition]["function"]) then
					return end

				self.options[key + pageAddition]["function"]()
			end

			-- Reset delay
			self.keylimit = true
			timer.Simple(self.keydelay or 0.25, function()
				-- Bug fix
				if not IsValid(self) then return end
				self.keylimit = false
			end)
		elseif (key == 0) then
			self:OnExit()
			self:Exit()
		end

		-- Call an extra think function if one is set
		self:OnThink()
	end

	-- Update Title
	function pan:UpdateTitle(title)
		self.title = title
	end

	-- Update option
	function pan:UpdateOption(optionId, title, colour, f)
		if (not self.options[optionId]) then
			return end

		if (title) then
			self.options[optionId]["name"] = title
		end

		if (colour) then
			self.options[optionId]["col"] = colour
		end

		if (f) then
			self.options[optionId]["function"] = f
		end
	end

	-- Update option bool
	function pan:UpdateOptionBool(optionId)
		if (not self.options[optionId]) or (self.options[optionId].bool == nil) then
			return end

		self.options[optionId].bool = (not self.options[optionId].bool)

		-- Name
		local o1 = self.options[optionId].customBool and self.options[optionId].customBool[1] or "ON"
		local o2 = self.options[optionId].customBool and self.options[optionId].customBool[2] or "OFF"
		self.options[optionId].name = self.options[optionId].defname .. ": (" .. (self.options[optionId].bool and o1 or o2) .. ") "
	end

	-- On Think
	-- This should just be overwritten if you need to use it.
	function pan:OnThink()
	end

	-- Exit
	function pan:Exit()
		UI.ActiveNumberedUIPanel = false
		self:Remove()
		pan = nil
	end

	-- On Exit
	function pan:OnExit()
	end

	-- Select option
	function pan:SelectOption(id)
		self.options[id]["function"]()
	end

	-- Set custom delay
	function pan:SetCustomDelay(delay)
		self.keydelay = delay
	end

	-- Force next/previous
	function pan:ForceNextPrevious(bool)
		self.hasPages = true
		self:SetTall(75 + 180)

		local posx, posy = self:GetPos()
		self:SetPos(posx, ScrH() / 2 - ((75 + 180) / 2))
	end

	-- Revert 
	function pan:RemoveNextPrevious()
		self.hasPages = false 
		self:SetTall(self.trueHeight)
		local posx, posy = self:GetPos()
		self:SetPos(posx, ScrH() / 2 - ((self.trueHeight) / 2))
	end

	-- Update longest option
	function pan:UpdateLongestOption()
		local largest = ""

		local start = 1 + ((self.page - 1) * 7)
		local finish = ((self.page - 1) * 7) + 7
		for index = start, finish do
			if (not self.options[index]) then 
				break 
			end

			local option = self.options[index]
			largest = (#option.name > #largest) and option.name or largest
		end

		-- Get width of largest option
		surface.SetFont(self.themeid == "nui.css" and "hud.numberedui.css2" or "hud.numberedui.kawaii1")
		local width_largest = select(1, surface.GetTextSize(largest))
		print(width_largest)

		-- Set the panels width larger than default if the text width goes beyond it.
		if (width_largest > 160) then
			self:SetWide(width_largest + 40)
		end
	end

	-- On Next
	-- This should be overwritten if you need to use it
	function pan:OnNext()
	end

	function pan:OnPrevious()
		self:UpdateLongestOption()
	end

	-- Set Active Numbered UI Panel
	-- This is important, as if another numbered UI panel was opened, there would be overlap.
	self.ActiveNumberedUIPanel = pan

	-- Return
	return pan
end

function UI:BasePanel(width, height, x, y, p, shouldntPopup, base)
	local ui = vgui.Create(base or "EditablePanel", p or nil)
	ui:SetSize(width, height)

	if not shouldntPopup then 
		ui:MakePopup()
	end 

	if (not x) or (not y) then
		ui:Center()
	else 
		ui:SetPos(x, y)
	end

	ui.theme = Theme:GetPreference("NumberedUI") 
	ui.themec, ui.themet = ui.theme["Colours"], ui.theme["Toggles"]
	function ui:Paint(width, height)
		self.theme = Theme:GetPreference("NumberedUI") 
		self.themec, self.themet = self.theme["Colours"], self.theme["Toggles"]

		local primary = self.themec["Primary Colour"]
		local outlines = self.themet["Outlines"]
		local outline_col = self.themec["Outlines Colour"]

		surface.SetDrawColor(primary)
		surface.DrawRect(0, 0, width, height)

		if (outlines) then
			surface.SetDrawColor(outline_col)
			surface.DrawOutlinedRect(0, 0, width, height)
		end

		self:CPaint(width, height)
	end

	function ui:CPaint(width, height)
	end

	return ui
end

function UI:DrawBanner(panel, title)
	local _Paint = panel.Paint 

	function panel:Paint(width, height)
		_Paint(self, width, height)

		surface.SetDrawColor(self.themec["Secondary Colour"])
		surface.DrawRect(0, 0, width, 30)

		if (self.themet["Outlines"]) then 
			surface.SetDrawColor(self.themec["Outlines Colour"])
			surface.DrawOutlinedRect(0, 0, width, 30)
		end

		draw.SimpleText(title, "hud.title", 10, 6, self.themec["Text Colour 2"], TEXT_ALIGN_LEFT)
	end
end

function UI:AddCloseButton(panel)
	local _Paint = panel.Paint 

	function panel:Paint(width, height)
		_Paint(self, width, height)

		draw.SimpleText("x", "hud.title", width - 20, 5, self.themec["Text Colour 2"], TEXT_ALIGN_LEFT)
	end

	function panel:OnExit()
		gui.EnableScreenClicker(false)
	end

	panel._close = panel:Add("DButton")
	panel._close:SetSize(15, 15)
	panel._close:SetPos(panel:GetWide() - 20, 8)
	panel._close:SetText("")
	panel._close.Paint = function() end
	panel._close.OnMousePressed = function(self)
		panel:OnExit()
		panel:Remove()
		panel = nil 
	end
end

function UI:TextBox(parent, x, y, width, height, outlines, bg)
	local textbox = parent:Add("DTextEntry")
	textbox.col = UI_TEXT1
	textbox:RequestFocus()
	textbox:SetSize(width, height)

	local xP, yP = parent:GetPos()
	textbox:SetPos(x,y)
	textbox:SetFont("ui.mainmenu.button")

	function textbox:Paint(width, height)
		if (bg) then 
			surface.SetDrawColor(bg)
			surface.DrawRect(0, 0, width, height)
		end

		if (outlines) then 
			surface.SetDrawColor(UI_TEXT1)
			surface.DrawOutlinedRect(0, 0, width, height)
		end 

		self:DrawTextEntryText(self.col, Color(30, 130, 255), Color(255, 255, 255))
		self:CPaint(width, height)
	end

	function textbox:CPaint() end

	return textbox
end

function UI:BuildSimpleButton(self, name, func, x, y, w, h)
	local butt = self:Add("DButton")
	butt:SetPos(x, y)
	butt:SetSize(w, h)
	butt:SetText("")

	local selectedNUI = Settings:GetValue("selected.nui") or "nui.kawaii"
	local nuiTheme, themeId = Theme:GetPreference("NumberedUI", selectedNUI)
	local themeColors = nuiTheme["Colours"]

	butt.Paint = function(pan, width, height)
		local nuiTheme, themeId = Theme:GetPreference("NumberedUI", Settings:GetValue("selected.nui") or "nui.kawaii")
		local themeColors = nuiTheme["Colours"]

		if themeId == "nui.css" then
			local base = themeColors["Primary Colour"]
			local textColor = color_white
			local hoverColor = themeColors["Secondary Colour"]

			draw.RoundedBox(0, 0, 0, width, height, pan:IsHovered() and hoverColor or base)
			DrawText(name, "hud.numberedui.css2", width / 2, height / 2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		elseif themeId == "nui.kawaii" then
		    surface.SetDrawColor(pan:IsHovered() and Color(38, 38, 38) or self.themec["Secondary Colour"])
		    surface.DrawRect(0, 0, width, height)
		    DrawText(name, "ui.mainmenu.button", width / 2, height / 2, self.themec["Text Colour"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end

	butt.OnMousePressed = function()
		func()
	end

	return butt
end

function UI:ScrollablePanel(parent, x, y, width, height, data)
	local ui = parent:Add("DScrollPanel")

	local top = parent:Add("DPanel")
	top:SetPos(x, y)
	top:SetSize(width, 20)

	function top:Paint(width, height)
		local col = UI_TRI
		local text = UI_TEXT2
		surface.SetDrawColor(Color(100,100,100))
		surface.DrawRect(0, height - 2, width, 1)

		for k, v in pairs(data[1]) do 
			local x = (width / data[2]) * data[3][k]

			local align = TEXT_ALIGN_LEFT
			if k == #data[1] and (#data[1] ~= 1) then 
				align = TEXT_ALIGN_RIGHT
				x = width - (ui.scrollbar and 16 or 0) - 20
			end 

			draw.SimpleText(v, "hud.smalltext",  10+x, 0, text, align, TEXT_ALIGN_TOP)
		end
	end

	local sortbutts = {}
	local lastsorted = {1, 0}
	for k, v in pairs(data[1]) do 
		local x = (width / data[2]) * data[3][k]

		sortbutts[k] = top:Add("DButton")
		sortbutts[k]:SetPos(x, 0)
		sortbutts[k]:SetWide(100)
		sortbutts[k].Paint = function() end
		sortbutts[k]:SetText("")
		sortbutts[k].OnMousePressed = function()
			if ui.nosort then return end
			local copied = table.Copy(ui.contents)
			for k, v in pairs(ui.contents) do 
				ui.contents[k]:Remove()
				ui.contents[k] = nil 
			end

			if (lastsorted[1] == k) and (lastsorted[2] == 0) then 
				table.sort(copied, function(a, b)
					lastsorted = {k, 1}
					return (tonumber(a.data[k]) and tonumber(a.data[k]) or a.data[k]) > (tonumber(b.data[k]) and tonumber(b.data[k]) or b.data[k])
				end)
			else 
				table.sort(copied, function(a, b)
					lastsorted = {k, 0}
					return (tonumber(a.data[k]) and tonumber(a.data[k]) or a.data[k]) < (tonumber(b.data[k]) and tonumber(b.data[k]) or b.data[k])
				end)
			end

			for k, v in pairs(copied) do
				UI:MapScrollable(ui, v.data, v.custom, v.onClick)
			end
		end
	end

	ui:SetSize(width, height - 21)
	ui:SetPos(x, y + 21)

	local vbar = ui:GetVBar()
	vbar:SetHideButtons(true)

	function vbar:Paint(width, height)
	end

	function vbar.btnUp:Paint(width, height)
	end

	function vbar.btnDown:Paint(width, height)
	end

	function vbar.btnGrip:Paint(width, height)
		local col = Color(100,100,100)
		surface.SetDrawColor(col)
		surface.DrawRect(1, 0, width - 1, height)
	end

	local old = ui.SetVisible 
	function ui:SetVisible(arg)
		old(self, arg)
		top:SetVisible(arg)
	end 

	return ui, top
end

function UI:Scrollable(base, height, hoverCol, data, custom)
	if (not base.contents) then 
		base.contents = {}
	end

	local ui = base:Add("DButton")
	ui:SetPos(0, height * #base.contents)
	ui:SetSize(base:GetWide(), height)
	ui:SetText("")
	ui.data = data
	ui.custom = custom 
	ui.hoverCol = hoverCol
	ui.height = height
	ui.hoverFade = 0 
	ui.fcol = false 

	local initialy = height / 2
	
	if not base:GetParent().themec then 
		base:GetParent().themec = base:GetParent():GetParent().themec
	end

	function ui:Paint(width, height)
		local accent = UI_ACCENT
		accent = Color(accent.r, accent.g, accent.b, self.hoverFade)

		if ((hoverCol) and (self.isHovered)) or self.fcol then 
			surface.SetDrawColor(self.fcol and self.fcol or accent)
			surface.DrawRect(0, 0, width - (base.scrollbar and 16 or 0), height)
		end 

		local text = UI_TEXT1
		for k, v in pairs(data) do
			local x = (width / #data) * (k - 1)
			if (custom) then 
				x = (width / custom[1]) * custom[2][k]
			end

			local align = TEXT_ALIGN_LEFT
			if k == #data and (#data ~= 1) then 
				x = width - (base.scrollbar and 16 or 0) - 20
				align = TEXT_ALIGN_RIGHT
			end 

			if type(v) == 'table' then 
				if v[1] == 'name' then 
					draw.SimpleText(UTIL:GetPlayerName(v[2]), "ui.mainmenu.button", 10 + x, initialy, text, align, TEXT_ALIGN_CENTER)
				else 
					draw.SimpleText(v[1], "ui.mainmenu.button", 10 + x, initialy, v[2], align, TEXT_ALIGN_CENTER)
				end 
			else
				draw.SimpleText(v, "ui.mainmenu.button", 10 + x, initialy, text, align, TEXT_ALIGN_CENTER)
			end
		end

		self:CPaint(width, height)
	end

	function ui:CPaint()
	end

	function ui:SetColor(cust)
		if cust then 
			self.fcol = cust 
		else 
			self.fcol = Color(UI_ACCENT.r, UI_ACCENT.g, UI_ACCENT.b, 75)
		end 
	end 

	function ui:RemoveColor()
		self.fcol = false 
	end 

	function ui:Think()
		if self.isHovered and not self:IsHovered() then 
			self.hoverFade = 0 
		elseif self.isHovered and self.hoverFade < 75 then 
			self.hoverFade = self.hoverFade + 0.75
		end 

		self.isHovered = self:IsHovered()
	end

	table.insert(base.contents, ui)

	if (#base.contents * height) > base:GetTall() then 
		base.scrollbar = true
	end

	return ui
end

function UI:MapScrollable(base, data, custom, onClick)
	local ui = self:Scrollable(base, 40, true, data, custom)
	ui.onClick = onClick

	function ui:OnMousePressed()
		onClick(self, data)
	end

	function ui:SizeToAndAdjustOthers(w, h, t, d, revert)
		local inith = self:GetTall()

		self:SizeTo(w, h, t, 0)
		self.inith = inith 
		
		if not revert then 
			self.adjusted = true 
		end

		local foundSelf = false 
		local movedReverted = false
		for k, v in pairs(base.contents) do 
			if v == self then 
				foundSelf = true 
				continue
			elseif v.adjusted then 
				if not foundSelf then 
					v:SizeTo(w, v.inith, t, d)
				else end
				v.adjusted = false
			end

			if foundSelf then
				local x, y = v:GetPos() 
				v:MoveTo(w, y + h - inith, t, 0)
			end
		end
	end

	return ui
end

function UI:SearchBox(parent, x, y, width, height, outlines, bg, search)
	local box = self:TextBox(parent, x, y, width, height, outlines, bg)
	box:SetFont("hud.title2.1")

	function box:CPaint(width, height)
		if (not self.changed) then
			local text = parent.themec["Text Colour"]
			draw.SimpleText("Search...", "hud.title2.1", 3, height / 2, text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
	end

	box:SetUpdateOnType(true)
	function box:OnValueChange(value)
		box.changed = true
		search(value)
	end

	return box
end

function UI:ScrollableUIPanel(title, desc, search, data, should_search)
	local width = 600
	local height = 510
	local base = self:BasePanel(width, height)

	self:DrawBanner(base, title)

	self:AddCloseButton(base)

	function base:CPaint(width, height)
		local text = base.themec["Text Colour"]

		draw.SimpleText(desc, "hud.title2.1", 10, 50, text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText("Hint: You can press the titles to sort by them.", "hud.smalltext", 10, height - 10, text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	base.ScrollPanel = self:ScrollablePanel(base, 10, 70, width - 20, height - 90, data)

	if (not should_search) then 
		base.SearchBox = UI:SearchBox(base, width - 160, 37, 150, 26, true, false, search)
	end

	function base:Exit()
		if base.OnExit then 
			base:OnExit()
		end
		
		base:Remove()
		base = nil
		gui.EnableScreenClicker(false)
	end

	return base
end

function UI:SimpleInputBox(title, callback, close)
	local width = 300
	local height = 115
	local base = self:BasePanel(width, height)

	self:DrawBanner(base, title)

	if (close) then 
		self:AddCloseButton(base)
	end

	local b = UI_PRIMARY
	local col = Color(b.r + 5, b.g + 5, b.b + 5, 255)
	local box = self:TextBox(base, 10, 40, width - 20, 30, false, col)
	box:SetFont("hud.title2.1")

	local b = base:Add("DButton")
	b:SetPos(10, 75)
	b:SetSize(width - 20, 30)
	b:SetText("")
	function b:Paint(w,h)
		surface.SetDrawColor(base.themec["Tri Colour"])
		surface.DrawRect(0, 0, w, h)
		draw.SimpleText("Confirm", "hud.title2.1", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	function b:OnMousePressed()
		callback(box:GetText())
		base:Remove()
	end

	function base:GetOutput()
		return self.output or false 
	end
	
	return base
end

function UI:BuildSimpleButton(self, name, func, x, y, w, h)
	local butt = self:Add('DButton')
	butt:SetPos(x, y)
	butt:SetSize(w, h)
	butt:SetText("")
	butt.Paint = function(pan, width, height)
		surface.SetDrawColor(pan:IsHovered() and self.themec["Tri Colour"] or self.themec["Secondary Colour"])
		surface.DrawRect(0, 0, width, height)
		draw.SimpleText(name, "ui.mainmenu.button", width / 2, height / 2, self.themec["Text Colour"], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	butt.OnMousePressed = function(pan)
		func()
	end

	return butt
end

function UI:DialogBox(title, answers, yes, no)
	answers = answers or {"Yes", "No"}
	local width = 320 
	local height = 60 
	local base = self:BasePanel(width, height)
	self:DrawBanner(base, title)

	local fyes = function() yes() base:Remove() gui.EnableScreenClicker(false) end
	local fno = function() no() base:Remove() gui.EnableScreenClicker(false) end
	local yesbutt = self:BuildSimpleButton(base, answers[1], fyes, 0, 30, width / 2, 30)
	local nobutt = self:BuildSimpleButton(base, answers[2], fno, width / 2, 30, width / 2, 30)

	return base
end

function UI:NumberInput(parent, x, y, width, height, default, min, max, title, allowDecimals, callback, disable) 
	local entry = parent:Add('DNumberWang')
    entry:SetPos(x, y)
    entry:SetSize(width, height)
    entry:SetFont("ui.mainmenu.button")
	entry:SetTextColor(UI_TEXT1)
	entry:HideWang()

    function entry:Paint(width, height)
        local b = UI_PRIMARY
		local col = Color(b.r + 5, b.g + 5, b.b + 5, 255)
        surface.SetDrawColor(col)
        surface.DrawRect(0, 0, width, height, 2)

        surface.SetFont("ui.mainmenu.button")
        local w, h = surface.GetTextSize(self:GetText())

        draw.SimpleText(title, "ui.mainmenu.button", w+6, height / 2, Color(200, 200, 200), UI_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_LEFT)
		self:DrawTextEntryText(UI_TEXT1, Color(30, 130, 255), Color(255, 255, 255))
    end

	entry.min = min 
	entry.max = max 
    entry:SetMin(min)
    entry:SetMax(max)

    if allowDecimals then 
        entry:SetDecimals(3)
	else 
		entry:SetDecimals(0)
	end 

	entry:SetValue(default)

	if not disable then 
		entry:SetUpdateOnType(true)
	else 
		entry:SetUpdateOnType(false)
	end 

    function entry:OnValueChange(newVal)
		newVal = tonumber(newVal)

		if not newVal then return end 
		
		if newVal > self.max then 
			newVal = self.max 
			entry:SetValue(self.max)
			entry:SetText(self.max)
		elseif newVal < self.min then 
            newVal = self.min
			entry:SetValue(self.min)
			entry:SetText(self.min)
        end 

        callback(newVal)
	end 
	
	return entry 
end 

function UI:TextEntry(parent, x, y, width, height, default, len, callback)
	local b = UI_PRIMARY
	local col = Color(b.r + 5, b.g + 5, b.b + 5, 255)
	local entry = self:TextBox(parent, x, y, width, height, false, col)

	entry:SetText(default)
	entry:SetUpdateOnType(true)
	function entry:OnValueChange(var)
		if #var > len then 
			var = var:Left(len)
			entry:SetText(var)
		end 

		callback(var)
	end 

	return entry
end 

function UI:SteamID(parent, x, y, width, height, default, len, callback)
	local entry = self:TextEntry(parent, x, y, width, height, default, len, callback)

	function entry:OnValueChange(var)
		if #var > len then 
			var = var:Left(len)
			entry:SetText(var)
		end 

		if Admin:ValidSteamID(var:upper()) then 
			self.col = Color(0, 200, 0)
		else 
			self.col = Color(200, 0, 0)
		end

		callback(var)
	end 
	
	return entry 
end 

function UI:CheckBox(parent, x, y, size, default, callback)
	local pan = vgui.Create('DButton', parent)
	pan:SetPos(x, y)
	pan:SetSize(size, size)
	pan:SetText("")
	pan.checked = default 

	function pan:OnMousePressed()
		self.checked = (not self.checked)
		callback(self.checked)
	end 

	local b = UI_PRIMARY
	local col = Color(b.r + 25, b.g + 25, b.b + 25, 255)
	function pan:Paint(width, height)
		surface.SetDrawColor(col)
		surface.DrawOutlinedRect(0, 0, width, height, 4)

		if self.checked then 
			surface.DrawRect(6, 6, width - 12, height - 12)
		end 
	end 
end 

local function CP_Callback(id)
    return function() UI:SendCallback("checkpoints", {id}) end
end

-- Checkpoint UI
UI:AddListener("checkpoints", function(_, data)
    local update = data[1] or false

    if update and UI.checkpoints and UI.checkpoints.title then
        if update == "angles" then
            UI.checkpoints:UpdateOptionBool(7)
            return
        elseif update == "close" then 
            UI.checkpoints:Exit()
            UI.checkpoints = nil 
            return
        end

        local current = data[2]
        local all = data[3] or nil

        if not current or not all or current == 0 or all == 0 then
            UI.checkpoints:UpdateTitle("Checkpoints")
            return
        end

        UI.checkpoints:UpdateTitle("Checkpoint: " .. current .. " / " .. all)
    elseif not UI.checkpoints or not UI.checkpoints.title then
        local options = {
            {["name"] = "Save checkpoint", ["function"] = CP_Callback("save")},
            {["name"] = "Teleport to checkpoint", ["function"] = CP_Callback("tp")},
            {["name"] = "Previous checkpoint", ["function"] = CP_Callback("prev")},
            {["name"] = "Next checkpoint", ["function"] = CP_Callback("next")},
            {["name"] = "Delete checkpoint", ["function"] = CP_Callback("del")},
            {["name"] = "Reset checkpoints", ["function"] = CP_Callback("reset")}
        }

        local title = "Checkpoints"
        if update == "newpan" then 
            local current = data[2]
            local all = data[3] or nil

            if all then 
                title = "Checkpoint: " .. current .. " / " .. all
            end
        end

        if update == "close" then return end

        UI.checkpoints = UI:NumberedUIPanel(title, unpack(options))
    end
end)

local function SSJ_Callback(key)
    return function() UI:SendCallback("ssj", {key}) end
end

-- SSJ MENU UI
UI:AddListener("ssj", function(_, data)
    local data = data[1] or false

    if tonumber(data) and UI.ssj then
        UI.ssj:UpdateOptionBool(tonumber(data))

        UI.ssj:UpdateTitle("SSJ Menu") 
    elseif (not UI.ssj) or (not UI.ssj.title) and (not tonumber(data)) then
        UI.ssj = UI:NumberedUIPanel("SSJ Menu",
            {["name"] = "Toggle", ["function"] = SSJ_Callback(1), ["bool"] = data[1]},
            {["name"] = "Mode", ["function"] = SSJ_Callback(2), ["bool"] = data[2], ["customBool"] = {"All", "6th"}},
            {["name"] = "Speed Difference", ["function"] = SSJ_Callback(3), ["bool"] = data[3]},
            {["name"] = "Height Difference", ["function"] = SSJ_Callback(4), ["bool"] = data[4]},
            {["name"] = "Observers Stats", ["function"] = SSJ_Callback(5), ["bool"] = data[5]},
            {["name"] = "Gain Percentage", ["function"] = SSJ_Callback(6), ["bool"] = data[6]},
            {["name"] = "Strafes Per Jump", ["function"] = SSJ_Callback(7), ["bool"] = data[7]},
            {["name"] = "Show JSS", ["function"] = SSJ_Callback(8), ["bool"] = data[8]},
            {["name"] = "Show Eff", ["function"] = SSJ_Callback(9), ["bool"] = data[9]},
            {["name"] = "Show Sync", ["function"] = SSJ_Callback(10), ["bool"] = data[10]},
            {["name"] = "Show Last Speed", ["function"] = SSJ_Callback(11), ["bool"] = data[11]},
            {["name"] = "Show Yaw", ["function"] = SSJ_Callback(12), ["bool"] = data[12]},
            {["name"] = "Show Time", ["function"] = SSJ_Callback(13), ["bool"] = data[13]},
            {["name"] = "Show Pre-Speed", ["function"] = SSJ_Callback(14), ["bool"] = data[14]}
        )
    end
end)

local function STYLE_Callback(key)
    key = tonumber(key)
    if not key then return end
    return function() UI:SendCallback("style", {key}) end
end

-- Style MENU UI
UI:AddListener("style", function(_, data)
    data = data[1] or false
    local currentStyle = LocalPlayer():GetNWInt("Style", 1)

    if tonumber(data) and UI.style then
        UI.style:UpdateOptionBool(tonumber(data))
    elseif (not UI.style) or (not UI.style.title) and (not tonumber(data)) then
        local styles = {
            "Normal", "Sideways", "Half-Sideways", "W-Only", "A-Only", "Legit", "Easy Scroll",
            "Unreal", "Swift", "Bonus", "WTF", "Low Gravity", "Backwards", "Stamina", 
            "Segment", "Auto-Strafe", "Moon Man", "High Gravity", "Speedrun", "Prespeed"
        }

        local options = {}
        for i, name in ipairs(styles) do
            options[#options + 1] = {
                ["name"] = name,
                ["col"] = (currentStyle == i) and Color(0, 150, 255) or Color(255, 255, 255),
                ["function"] = STYLE_Callback(i),
                ["bool"] = data[i]
            }
        end

        UI.style = UI:NumberedUIPanel("Choose a style", unpack(options))
    end
end)

local function Nominate_Callback(mapName)
    return function() 
        UI:SendCallback("nominate", {mapName}) 
    end
end

Cache = Cache or {
    M_Data = {},
    M_Version = 0,
    M_Name = "timer/bhop.txt"
}

function Cache:M_Load()
    local data = file.Read(self.M_Name, "DATA")
    if not data then return end

    self.M_Version = tonumber(data:sub(1, 5))
    if not self.M_Version then return end

    local remain = util.Decompress(data:sub(6))
    if not remain then return end

    local tab = util.JSONToTable(remain)
    if tab then
        self.M_Data = tab
        self:M_Update()
    end
end

function Cache:M_Save(varList, nVersion, bOpen)
    self.M_Data = varList or {}
    self.M_Version = nVersion
    self:M_Update()

    if #self.M_Data > 0 then
        local data = util.Compress(util.TableToJSON(self.M_Data))
        if data then
            file.Write(self.M_Name, string.format("%.5d", nVersion) .. data)
            print("File Saved:", self.M_Name)
            if bOpen then UI:SendCallback("nominate", {nVersion}) end
        end
    elseif UI.nominate then
        UI.nominate:Exit()
    end
end

function Cache:M_Update()
    for _, d in ipairs(self.M_Data) do
        d[2] = tonumber(d[2])
    end
end

local function VerifyList()
    if file.Exists(Cache.M_Name, "DATA") then Cache:M_Load() end
end
hook.Add("Initialize", "LoadDatas", VerifyList)

UI:AddListener("nominate_list", function(_, data)
    if data and #data > 0 and type(data[1]) == "table" and data[1].name then
        Cache.M_Data = data
    elseif data and #data > 0 and type(data[1]) == "table" then
        Cache.M_Data = data[1]
    end
end)

-- Nominate MENU UI
UI:AddListener("nominate", function(_, data)
    local sortMode = data[2] or 1

    if #Cache.M_Data == 0 then
        UI.nominate = UI:NumberedUIPanel("Nominate", {["name"] = "No maps available", ["function"] = function() end})
        return
    end

    table.sort(Cache.M_Data, function(a, b)
        if sortMode == 1 then
            return a.name:lower() < b.name:lower() 
        else
            if a.points == b.points then
                return a.name:lower() < b.name:lower()
            else
                return a.points > b.points
            end
        end
    end)

    local currentMap = game.GetMap()
    local options = {}

    for _, mapItem in ipairs(Cache.M_Data) do
        if mapItem and mapItem.name then
            if not (mapItem.name == currentMap and (mapItem.points or 0) <= 0) then
                options[#options + 1] = {
                    ["name"] = mapItem.name .. " (" .. (mapItem.points or 0) .. " points)",
                    ["col"] = (mapItem.name == currentMap) and Color(0, 150, 255) or Color(255, 255, 255),
                    ["function"] = Nominate_Callback(mapItem.name)
                }
            end
        end
    end

    if UI.nominate and UI.nominate.title then
        UI.nominate.options = options
        UI.nominate:UpdateTitle("Nominate (" .. #options .. " maps)")
    else
        UI.nominate = UI:NumberedUIPanel("Nominate (" .. #options .. " maps)", unpack(options))
    end
end)

local function SEGMENT_Callback(id)
    return function() UI:SendCallback("segment", {id})
        surface.PlaySound("garrysmod/ui_click.wav")
    end
end

-- Segment MENU UI
UI:AddListener("segment", function(_, data)
    if data and data[1] and UI.segment and UI.segment.title then
        UI.segment:Exit()
        return
    end

    if data and data[1] then return end

	UI.segment = UI:NumberedUIPanel("Segment Menu",
		{["name"] = "Set Checkpoint", ["function"] = SEGMENT_Callback("set")},
		{["name"] = "Goto Checkpoint", ["function"] = SEGMENT_Callback("goto")},
		{["name"] = "Previous checkpoint", ["function"] = SEGMENT_Callback("remove")},
		{["name"] = "Reset Checkpoint", ["function"] = SEGMENT_Callback("reset")}
	)
end)

UI:AddListener("menu", function()
    RunConsoleCommand("bhop_menu")
end)

-- Change Log
hook.Add("InitPostEntity", "Bhop_Changelog", function()
    if Iv(lp()) then
        local lastchange = lp():GetPData("Bhop_Changelog", false)

        if (not lastchange) or (tonumber(lastchange) ~= 7.04) then
            UI:NumberedUIPanel("Change Log",
                {["name"] = "[+] Added !revote command as requested."},
                {["name"] = "[+] Confirmation is now needed when resetting waypoints."},
                {["name"] = "[*] Fixed segment menu and checkpoints menu."},
                {["name"] = "[+] Added showkeys and strafe trainer addons."},
                {["name"] = "[*] Fixed UI conflicts."},
                {["name"] = "[*] Fixed TIMER:Print() messages."},
                {["name"] = "[*] Segment style waypoints display and fixes."},
                {["name"] = "[*] Timer display and updates."},
                {["name"] = "[+] Added custom themes for chat timer SSJ colors."}
            )

            lp():SetPData("Bhop_Changelog", 7.04)
        end
    end
end)

function UI:WRConvert(ns)
    local floor = math.floor
    local format = string.format

    if ns > 3600 then
        return format("%d:%.2d:%.2d.%.3d", floor(ns / 3600), floor(ns / 60 % 60), floor(ns % 60), floor(ns * 1000 % 1000))
    else
        return format("%.2d:%.2d.%.3d", floor(ns / 60 % 60), floor(ns % 60), floor(ns * 1000 % 1000))
    end
end

--[[-------------------------------------------------------------------------
	World Records
	1. [#1] FiBzY (00:23.432, 34 jumps, strafes 23, sync 76%)
---------------------------------------------------------------------------]]
local function WR_OnPress(Index, szMap, nStyle, Item, Speed)
    return function()
        if Admin.EditType and Admin.EditType == 17 and (game.GetMap() == szMap) then
            Admin:ReqAction(Admin.EditType, {nStyle, Index, Item[1], Item[2]})
            return
        end

        if Speed then
            local place = Index
            local time = UI:WRConvert(Item[3] or 0)
            local pl = Item[2] or "0"
            local id = Item[1] or "0"
            local date = Item[4] or "0"
            local style = TIMER:StyleName(nStyle) or "0"

            local jumps = Speed[3] or 0
            local topvel = Speed[1] or 0
            local avgvel = Speed[2] or 0
            local sync = (Speed[4] or 0) .. "%"
            local strafes = (Speed[5] or 0)

            local str = string.format(
                "Player %s (%s) achieved #%s on %s on %s style (at: %s) with a time of %s. (Average Vel: %s u/s, Top Vel: %s u/s, Jumps: %s, Sync: %s, Strafes: %s)",
                pl, id, place, szMap, style, date, time, avgvel, topvel, jumps, sync, strafes
            )
            UTIL:AddMessage("Timer", str)
        end
    end
end

function StringToTab(tab)
    if isstring(tab) then
        local splitTab = {}
        for value in string.gmatch(tab, "%S+") do
            table.insert(splitTab, tonumber(value) or 0)
        end
        tab = splitTab
    end

    if not istable(tab) then
        print("[WARNING] StringToTab() received invalid data!")
        return {}
    end

    return tab
end

UI:AddListener("wr", function(_, data)
    local wrList = data[1]
    local recordStyle = data[2]
    local page = data[3]
    local recordsTotal = data[4]
    local map = data[5] or game.GetMap()

    if recordsTotal == 0 then
        UI.WR = UI:NumberedUIPanel(TIMER:StyleName(recordStyle) .. " Records (#" .. recordsTotal .. ")", {
            ["name"] = "There are no records yet!",
            ["function"] = function() end
        })
        UI.WR:ForceNextPrevious(false)
        return
    end

    if (page ~= 1) and (UI.WR) and (UI.WR.title) then
        for k, v in ipairs(wrList) do
            local parsedSpeedData = {}
            if isstring(v[5]) then
                parsedSpeedData = StringToTab(v[5])
            elseif istable(v[5]) then
                parsedSpeedData = v[5]
            end

            local jumps = parsedSpeedData[3] or 0
            local strafes = parsedSpeedData[5] or 0
            local sync = parsedSpeedData[4] or 0
            UI.WR.options[k] = {
                ["name"] = ("[#" .. k .. "] " .. v[2] .. " (" .. UI:WRConvert(v[3]) .. ", " .. jumps .. " jumps, " .. strafes .. " strafes, " .. sync .. "% sync)"),
                ["function"] = WR_OnPress(k, map, recordStyle, v, parsedSpeedData)
            }
        end

        UI.WR.page = UI.WR.page + 1
        UI.WR:UpdateLongestOption()

        return
    end

    local options = {}
    for k, v in ipairs(wrList) do
        local parsedSpeedData = {}
        if isstring(v[5]) then
            parsedSpeedData = StringToTab(v[5])
        elseif istable(v[5]) then
            parsedSpeedData = v[5]
        end

        local jumps = parsedSpeedData[3] or 0
        local strafes = parsedSpeedData[5] or 0
        local sync = parsedSpeedData[4] or 0
        options[k] = {
            ["name"] = ("[#" .. k .. "] " .. v[2] .. " (" .. UI:WRConvert(v[3]) .. ", " .. jumps .. " jumps, " .. strafes .. " strafes, " .. sync .. "% sync)"),
            ["function"] = WR_OnPress(k, map, recordStyle, v, parsedSpeedData)
        }
    end

    UI.WR = UI:NumberedUIPanel(TIMER:StyleName(recordStyle) .. " Records (#" .. recordsTotal .. ")", unpack(options))
    UI.WR:ForceNextPrevious(true)
    UI.WR.recordCount = recordsTotal
    UI.WR.style = recordStyle
    UI.WR.map = map or game.GetMap()

    function UI.WR:OnNext(hitMax)
        if (hitMax) and ((self.page * 7) < self.recordCount) then
            TIMER:Send("WRList", {self.page + 1, self.style, self.map})
        end
    end
end)

-- SSJ Top Menu
local function CreateSSJTopMenu(data)
    if IsValid(SSJTopFrame) then SSJTopFrame:Remove() end

    SSJTopFrame = vgui.Create("DFrame")
    SSJTopFrame:SetSize(400, 500)
    SSJTopFrame:SetTitle("")
    SSJTopFrame:SetDraggable(false)
    SSJTopFrame:ShowCloseButton(false)
    SSJTopFrame:Center()
    SSJTopFrame:MakePopup()
    
    SSJTopFrame.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(35, 35, 35, 255))
        draw.RoundedBox(0, 0, 0, w, 30, Color(32, 32, 32, 255))
        draw.SimpleText("SSJTOP Leaderboard", "hud.subtitle", w / 2, 15, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local closeButton = vgui.Create("DButton", SSJTopFrame)
    closeButton:SetSize(30, 30)
    closeButton:SetPos(SSJTopFrame:GetWide() - 35, 0)
    closeButton:SetText("")

    closeButton.Paint = function(self, w, h)
        local color = self:IsHovered() and Color(200, 50, 50, 255) or Color(150, 50, 50, 255)
        draw.SimpleText("X", "hud.subtitle", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    closeButton.DoClick = function()
        SSJTopFrame:Remove()
    end

    local scrollPanel = vgui.Create("DScrollPanel", SSJTopFrame)
    scrollPanel:SetSize(380, 420)
    scrollPanel:SetPos(10, 70)

    local listCanvas = vgui.Create("DPanel", scrollPanel)
    listCanvas:SetSize(380, 420)
    listCanvas.Paint = nil

	local sortedData = {}
	for steamID64, ssjData in pairs(data) do
		local playerName = UTIL:GetPlayerName(steamID64)
		table.insert(sortedData, {playerName, ssjData.normal or 0, ssjData.duck or 0, steamID64})
	end

    table.sort(sortedData, function(a, b)
        return (a[2] > b[2]) or (a[2] == b[2] and a[3] > b[3])
    end)

    listCanvas:SetTall(#sortedData * 25)

    local headerPanel = vgui.Create("DPanel", SSJTopFrame)
    headerPanel:SetSize(380, 30)
    headerPanel:SetPos(10, 40)

    headerPanel.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(42, 42, 42, 255))
        draw.SimpleText("#", "hud.subtitle", 10, h / 2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("Player", "hud.subtitle", 50, h / 2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("Normal", "hud.subtitle", 220, h / 2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("Ducked", "hud.subtitle", 300, h / 2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

	for rank, info in ipairs(sortedData) do
		local entry = vgui.Create("DButton", listCanvas)
		entry:SetSize(360, 25)
		entry:SetPos(10, (rank - 1) * 25)
		entry:SetText("") -- Remove default button label

		local isAdmin = LocalPlayer():IsAdmin()

		entry.Paint = function(self, w, h)
			local bgColor = rank % 2 == 0 and Color(70, 70, 70, 200) or Color(60, 60, 60, 200)
			if self:IsHovered() and isAdmin then
				bgColor = Color(100, 40, 40, 220)
			end

			draw.RoundedBox(4, 0, 0, w, h, bgColor)

			local textColor = (info[1] == LocalPlayer():Nick()) and Color(0, 150, 255) or Color(255, 255, 255)

			draw.SimpleText(rank, "hud.subtitle", 10, h / 2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(info[1], "hud.subtitle", 50, h / 2, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(math.Round(info[2], 2), "hud.subtitle", 220, h / 2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(math.Round(info[3], 2), "hud.subtitle", 300, h / 2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

			if isAdmin then
				draw.SimpleText("X", "hud.subtitle", w - 20, h / 2, Color(255, 50, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end

		if isAdmin then
			entry.DoClick = function()
				local confirm = vgui.Create("DFrame")
				confirm:SetSize(300, 140)
				confirm:Center()
				confirm:SetTitle("")
				confirm:MakePopup()
				confirm:ShowCloseButton(false)

				confirm.Paint = function(self, w, h)
					surface.SetDrawColor(colors.box)
					surface.DrawOutlinedRect(0, 0, w, h, 2)
					surface.SetDrawColor(colors.toggleButton)
					surface.DrawRect(2, 2, w - 4, h - 4)
					draw.SimpleText("Delete SSJ record for:", "ui.mainmenu.button", w / 2, 30, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
					draw.SimpleText(info[1], "ui.mainmenu.button", w / 2, 55, Color(255, 0, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end

				-- Confirm
				local yesBtn = vgui.Create("DButton", confirm)
				yesBtn:SetText("")
				yesBtn:SetSize(120, 30)
				yesBtn:SetPos(30, 90)
				yesBtn.Paint = function(self, w, h)
					surface.SetDrawColor(colors.box)
					surface.DrawOutlinedRect(0, 0, w, h, 2)
					surface.SetDrawColor(self:IsHovered() and Color(0, 255, 0) or colors.toggleButton)
					surface.DrawRect(2, 2, w - 4, h - 4)
					draw.SimpleText("Yes", "ui.mainmenu.button", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end
				yesBtn.DoClick = function()
					net.Start("SSJTOP_RemoveRecord")
					net.WriteString(info[1])
					net.WriteString(info[4] or "")
					net.SendToServer()

					confirm:Close()
				end

				local noBtn = vgui.Create("DButton", confirm)
				noBtn:SetText("")
				noBtn:SetSize(120, 30)
				noBtn:SetPos(150, 90)
				noBtn.Paint = function(self, w, h)
					surface.SetDrawColor(colors.box)
					surface.DrawOutlinedRect(0, 0, w, h, 2)
					surface.SetDrawColor(self:IsHovered() and Color(100, 100, 100) or colors.toggleButton)
					surface.DrawRect(2, 2, w - 4, h - 4)
					draw.SimpleText("Cancel", "ui.mainmenu.button", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end
				noBtn.DoClick = function()
					confirm:Close()
				end
			end

		end
	end
end

-- SSJTop Data
local function RequestSSJTop()
    net.Start("SSJTOP_SendData")
    net.SendToServer()
end

net.Receive("SSJTOP_SendData", function()
    local ssjData = net.ReadTable()
    CreateSSJTopMenu(ssjData)
end)

concommand.Add("ssjtop_menu", RequestSSJTop)

local function ColorToText(col)
    return string.format("R:%d G:%d B:%d A:%d", col.r, col.g, col.b, col.a or 255)
end

-- JHUD Menu
function OpenBhopJHUDMenu()
    local wide, tall = ScrW() * 0.4, ScrH() * 0.45
    local frameColor = Color(42, 42, 42, 255)
    local headerColor = Color(30, 30, 30, 255)

    local frame = vgui.Create("DFrame")
    frame:SetSize(wide, tall)
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:MakePopup()
    frame.Paint = function(self, w, h)
        surface.SetDrawColor(frameColor)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(headerColor)
        surface.DrawRect(0, 0, w, 40)

        draw.SimpleText("JHUD Menu", "TopNavFont", w / 2, 20, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local closeButton = vgui.Create("DButton", frame)
    closeButton:SetSize(24, 24)
    closeButton:SetPos(wide - 34, 8)
    closeButton:SetText("")
    closeButton.Paint = function(self, w, h)
        if self:IsHovered() then
            surface.SetDrawColor(255, 0, 0, 200)
        else
            surface.SetDrawColor(255, 255, 255, 200)
        end
        surface.DrawLine(6, 6, w - 6, h - 6)
        surface.DrawLine(w - 6, 6, 6, h - 6)
    end
    closeButton.DoClick = function()
        frame:Close()
    end

    local scrollPanel = vgui.Create("DScrollPanel", frame)
    scrollPanel:Dock(FILL)
    scrollPanel:DockMargin(8, 25, 8, 8)

    local vBar = scrollPanel:GetVBar()
    vBar:SetWide(6)
    vBar.Paint = function(self, w, h) surface.SetDrawColor(40, 40, 40) surface.DrawRect(0, 0, w, h) end
    vBar.btnUp.Paint = function(self, w, h) surface.SetDrawColor(60, 60, 60) surface.DrawRect(0, 0, w, h) end
    vBar.btnDown.Paint = function(self, w, h) surface.SetDrawColor(60, 60, 60) surface.DrawRect(0, 0, w, h) end
    vBar.btnGrip.Paint = function(self, w, h) surface.SetDrawColor(255, 255, 255) surface.DrawRect(0, 0, w, h) end

    local header = vgui.Create("DPanel", scrollPanel)
    header:SetTall(40)
    header:Dock(TOP)
    header.Paint = function(self, w, h)
        draw.SimpleText("Settings", "TopNavFont", 5, 5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        surface.SetDrawColor(255, 255, 255, 100)
        surface.DrawLine(0, h - 5, w, h - 5)
    end

    local container = vgui.Create("DPanel", scrollPanel)
    container:Dock(TOP)
    container:SetTall(400)
    container.Paint = function(self, w, h)
        surface.SetDrawColor(frameColor)
        surface.DrawRect(0, 0, w, h)
    end

    local y = 10
    local function AddToggle(cmd, label, desc)
        local pnl, lbl, info = UI:CreateToggle(container, y, cmd, label, desc, { default = 1, off = 0 })
        timer.Simple(0.01, function()
            if IsValid(pnl) then
                pnl:SetWide(container:GetWide())
            end
        end)
        y = y + 60
    end

    AddToggle("bhop_jhud", "Enable JHUD", "Enable or disable the JHUD display.")
    AddToggle("bhop_jhud_gain", "Enable Gain", "Enable or disable Gain display on JHUD.")
    AddToggle("bhop_jhud_sync", "Enable Sync", "Enable or disable Sync display on JHUD.")
    AddToggle("bhop_jhud_strafes", "Enable Strafes", "Enable or disable Strafe counter on JHUD.")
    AddToggle("bhop_jhud_efficiency", "Enable Efficiency", "Enable or disable Efficiency on JHUD.")
    AddToggle("bhop_jhud_difference", "Enable Difference", "Enable or disable difference speed on JHUD.")

    container:SetTall(y + 30)

    local colorHeader = vgui.Create("DPanel", scrollPanel)
    colorHeader:SetTall(40)
    colorHeader:Dock(TOP)
    colorHeader.Paint = function(self, w, h)
        draw.SimpleText("Colors", "TopNavFont", 5, 5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        surface.SetDrawColor(255, 255, 255, 100)
        surface.DrawLine(0, h - 5, w, h - 5)
    end

    local colorContainer = vgui.Create("DPanel", scrollPanel)
    colorContainer:Dock(TOP)
    colorContainer:SetTall((60 * 5) + 30)
    colorContainer.Paint = function() end

    local y = 10
    local function AddToggleColor(cmd, label, desc)
        local pnl, lbl, info = UI:ColorBox(colorContainer, y, cmd, label, desc)
        timer.Simple(0.01, function()
            if IsValid(pnl) then
                pnl:SetWide(colorContainer:GetWide())
            end
        end)
        y = y + 60
    end

    AddToggleColor("bhop_jhud_gain_verygood", "Change Gain Really Good Color", "Changes color for REALLY good gain.")
    AddToggleColor("bhop_jhud_gain_good", "Change Good Gain Color", "Changes color for good gain.")
    AddToggleColor("bhop_jhud_gain_meh", "Change Gain Meh Color", "Changes color for meh gain.")
    AddToggleColor("bhop_jhud_gain_bad", "Change Gain Bad Color", "Changes color for bad gain.")
    AddToggleColor("bhop_jhud_gain_verybad", "Change Gain Really Bad Color", "Changes color for REALLY bad gain.")

end
concommand.Add("bhop_jhudmenu", OpenBhopJHUDMenu)

net.Receive("JHUD_SendData", function()
    RunConsoleCommand("bhop_jhudmenu")
end)

-- Strafe Trainer menu
function OpenBhopTrainerMenu()
    local wide, tall = ScrW() * 0.4, ScrH() * 0.45
    local frameColor = Color(42, 42, 42, 255)
    local headerColor = Color(30, 30, 30, 255)

    local frame = vgui.Create("DFrame")
    frame:SetSize(wide, tall)
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:MakePopup()
    frame.Paint = function(self, w, h)
        surface.SetDrawColor(frameColor)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(headerColor)
        surface.DrawRect(0, 0, w, 40)

        draw.SimpleText("Strafe Trainer Menu", "TopNavFont", w / 2, 20, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local closeButton = vgui.Create("DButton", frame)
    closeButton:SetSize(24, 24)
    closeButton:SetPos(wide - 34, 8)
    closeButton:SetText("")
    closeButton.Paint = function(self, w, h)
        if self:IsHovered() then
            surface.SetDrawColor(255, 0, 0, 200)
        else
            surface.SetDrawColor(255, 255, 255, 200)
        end
        surface.DrawLine(6, 6, w - 6, h - 6)
        surface.DrawLine(w - 6, 6, 6, h - 6)
    end
    closeButton.DoClick = function()
        frame:Close()
    end

    local scrollPanel = vgui.Create("DScrollPanel", frame)
    scrollPanel:Dock(FILL)
    scrollPanel:DockMargin(8, 25, 8, 8)

    local vBar = scrollPanel:GetVBar()
    vBar:SetWide(6)
    vBar.Paint = function(self, w, h) surface.SetDrawColor(40, 40, 40) surface.DrawRect(0, 0, w, h) end
    vBar.btnUp.Paint = function(self, w, h) surface.SetDrawColor(60, 60, 60) surface.DrawRect(0, 0, w, h) end
    vBar.btnDown.Paint = function(self, w, h) surface.SetDrawColor(60, 60, 60) surface.DrawRect(0, 0, w, h) end
    vBar.btnGrip.Paint = function(self, w, h) surface.SetDrawColor(255, 255, 255) surface.DrawRect(0, 0, w, h) end

    local header = vgui.Create("DPanel", scrollPanel)
    header:SetTall(40)
    header:Dock(TOP)
    header.Paint = function(self, w, h)
        draw.SimpleText("Settings", "TopNavFont", 5, 5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        surface.SetDrawColor(255, 255, 255, 100)
        surface.DrawLine(0, h - 5, w, h - 5)
    end

    local container = vgui.Create("DPanel", scrollPanel)
    container:Dock(TOP)
    container:SetTall(400)
    container.Paint = function(self, w, h)
        surface.SetDrawColor(frameColor)
        surface.DrawRect(0, 0, w, h)
    end

    local y = 10
    local function AddToggle(cmd, label, desc)
        local pnl, lbl, info = UI:CreateToggle(container, y, cmd, label, desc, { default = 1, off = 0 })
        timer.Simple(0.01, function()
            if IsValid(pnl) then
                pnl:SetWide(container:GetWide())
            end
        end)
        y = y + 60
    end

    AddToggle("bhop_strafetrainer", "Enable Kawaii Strafe Trainer", "Enable or disable the kawaii strafe trainer display.")
    AddToggle("bhop_strafetrainercss", "Enable CS:S Strafe Trainer", "Enable or disable the CS:S strafe trainer display.")

    container:SetTall(y + 30)

    local colorHeader = vgui.Create("DPanel", scrollPanel)
    colorHeader:SetTall(40)
    colorHeader:Dock(TOP)
    colorHeader.Paint = function(self, w, h)
        draw.SimpleText("Colors", "TopNavFont", 5, 5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        surface.SetDrawColor(255, 255, 255, 100)
        surface.DrawLine(0, h - 5, w, h - 5)
    end

    local colorContainer = vgui.Create("DPanel", scrollPanel)
    colorContainer:Dock(TOP)
    colorContainer:SetTall((60 * 5) + 30)
    colorContainer.Paint = function() end

    local y = 10
    local function AddToggleColor(cmd, label, desc)
        local pnl, lbl, info = UI:ColorBox(colorContainer, y, cmd, label, desc)
        timer.Simple(0.01, function()
            if IsValid(pnl) then
                pnl:SetWide(colorContainer:GetWide())
            end
        end)
        y = y + 60
    end

    AddToggleColor("bhop_trainer_verygood", "Change Really Good Color", "Changes color for REALLY good offests.")
    AddToggleColor("bhop_trainer_good", "Change Good Color", "Changes color for good offests.")
    AddToggleColor("bhop_trainer_ok", "Change Ok Color", "Changes color for Ok offests.")
    AddToggleColor("bhop_trainer_meh", "Change Meh Color", "Changes color for Meh offests.")
    AddToggleColor("bhop_trainer_bad", "Change Bad Color", "Changes color for Bad offests.")
end
concommand.Add("bhop_strafetrainermenu", OpenBhopTrainerMenu)

net.Receive("TRAINER_SendData", function()
    RunConsoleCommand("bhop_strafetrainermenu")
end)