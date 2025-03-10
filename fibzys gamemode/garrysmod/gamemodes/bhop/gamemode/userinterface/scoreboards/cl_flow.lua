surface.CreateFont( "ScoreboardPlayer", { font = "coolvetica", size = 24, weight = 500, antialias = true, italic = false })
surface.CreateFont( "MersText1", { font = "Tahoma", size = 16, weight = 1000, antialias = true, italic = false })
surface.CreateFont( "MersRadial", { font = "coolvetica", size = math.ceil( ScrW() / 34 ), weight = 500, antialias = true, italic = false })

local menu = nil
local con = function(ns) return SecondsToClock(ns) end

function TIMER:Convert(startTick, endTick)
    if not startTick or not endTick then
        return 0
    end

    local tickRate = engine.TickInterval()
    return (endTick - startTick) * tickRate
end

function SecondsToClock(seconds)
    seconds = tonumber(seconds) or 0
    local wholeSeconds = math.floor(seconds)
    local milliseconds = math.floor((seconds - wholeSeconds) * 1000)
    local hours = math.floor(wholeSeconds / 3600)
    local minutes = math.floor((wholeSeconds % 3600) / 60)
    local secs = wholeSeconds % 60

    if hours > 0 then
        return string.format("%d:%02d:%02d.%03d", hours, minutes, secs, milliseconds)
     else
        return string.format("%02d:%02d.%03d", minutes, secs, milliseconds)
    end
end

local function cTime(ns)
    if ns > 3600 then
        return string.format("%d:%.2d:%.2d", math.floor(ns / 3600), math.floor(ns / 60 % 60), math.floor(ns % 60))
    elseif ns > 60 then 
        return string.format("%.1d:%.2d", math.floor(ns / 60 % 60), math.floor(ns % 60))
    else
        return string.format("%.1d", math.floor(ns % 60))
    end
end


local rank_str = { "Donateur", "Mod", "Zoner", "Dev", "Founder" }
local icon = {}

icon.muted = Material( "icon32/muted.png" )

icon.access = {
	Material("icon16/heart.png"),
	Material("icon16/heart_add.png"),
	Material("icon16/report_user.png"),
	Material("icon16/shield.png"),
	"bhop/hammer.png",
	"bhop/hammer.png",
	"bhop/baguette.png"
}

icon.rank = {}

for i = 1, 10 do 
	icon.rank[i] = "bhop/icon_rank" .. tostring(i == 10 and 0 or i) .. ".png" 
end

icon.special = {}

for i = 1, 3 do 
	icon.special[i] = "bhop/icon_special" .. tostring(i) .. ".png" 
end

local function downloadMaterial(path, callback)
	local url = "https://fastdl.dotshark.dev/materials/" .. path
	http.Fetch(url, function(body, l, headers)
		if not file.Exists("bhop", "DATA") then file.CreateDir("bhop") end
		file.Write(path, body)
		callback( Material("../data/" .. path) )
		file.Delete(path)
	end)
end

hook.Add("HUDPaint", "LoadScoreboardIcons", function()
	for iconType, value in pairs(icon) do
		if isstring(value) then
			local path = value
			icon[iconType] = Material(path)
			downloadMaterial(path, function(loadedMaterial) 
				icon[iconType] = loadedMaterial 
			end)
		end

		if istable(value) then
			local iconsList = value
			for i, value in ipairs(iconsList) do
				if not isstring(value) then continue end
				local path = value
				icon[iconType][i] = Material(path) 
				downloadMaterial(path, function(loadedMaterial) 
					icon[iconType][i] = loadedMaterial 
				end)
			end
		end
	end

	hook.Remove("HUDPaint", "LoadScoreboardIcons")
end)


local function _AA( szAction, szSID )
	if not IsValid( LocalPlayer() ) then return end
	if Admin:IsAvailable() or LocalPlayer():GetNWInt( "AccessIcon", 0 ) > 2 then
		RunConsoleCommand( "say", "!admin " .. szAction .. " " .. szSID )
	else
		Link:Print( "Admin", "Please open the admin panel before trying to access scoreboard functionality." )
	end
end

local function PutPlayerItem( self, pList, ply, mw )
	local btn = vgui.Create( "DButton" )
	btn.player = ply
	btn.ctime = CurTime()
	btn:SetTall( 32 )
	btn:SetText( "" )
	
	function btn:Paint( w, h )
		surface.SetDrawColor( 0, 0, 0, 0 )
		surface.DrawRect( 0, 0, w, h )

		if ply:IsBot() then
			surface.SetDrawColor(DynamicColors.PanelColor)
		else
			surface.SetDrawColor(Color(150, 150, 150))
		end

		surface.DrawOutlinedRect(0, 0, w, h)

		if IsValid( ply ) and ply:IsPlayer() then
			local s = 0

			local rankID = ply:GetNWInt("Rank", -1)
			local rankInfo = TIMER.Ranks[rankID]

			if rankInfo then
				draw.DrawText(rankInfo[1], "ScoreboardPlayer", s + 11, 9, Color(0, 0, 0), TEXT_ALIGN_LEFT)
				draw.DrawText(rankInfo[1], "ScoreboardPlayer", s + 10, 8, rankInfo[2], TEXT_ALIGN_LEFT)
			else
				draw.DrawText("Replay", "ScoreboardPlayer", s + 11, 9, Color(0, 0, 0), TEXT_ALIGN_LEFT)
				draw.DrawText("Replay", "ScoreboardPlayer", s + 10, 8, Color(255, 255, 255), TEXT_ALIGN_LEFT)
			end
			
			s = s + mw + 56
			
			local nAccess = ply:GetNWInt( "AccessIcon", 0 )
			if nAccess > 0 then
				surface.SetMaterial( icon.access[ nAccess ] )
				surface.SetDrawColor( Color( 255, 255, 255 ) )
				surface.DrawTexturedRect( s + 4, h / 2 - 8, 16, 16 )
				s = s + 20
			end

			if ply:IsMuted() or ply:GetNWBool( "AdminGag", false ) then
				surface.SetMaterial( icon.muted )
				surface.SetDrawColor( Color( 255, 255, 255 ) )
				surface.DrawTexturedRect( s + 4, h / 2 - 16, 32, 32 )
				s = s + 32
			end

			if rankID > 1 then
				surface.SetMaterial( icon.rank[ ply:GetNWInt( "Rank", 1 ) ] )
				surface.SetDrawColor( Color( 255, 255, 255 ) )
				surface.DrawTexturedRect( s + 4, h / 2 - 14, 32, 32 )
				s = s + 32
			end

			local PlayerName = ply:Name()

			if ply:IsBot() then
				local szName = ply:GetNWString("BotName", "No Time Recorded")
    
				if szName == "Awaiting playback..." then 
					szName = "Waiting for replay..."
				elseif szName == "Loading..." then
					szName = "Changement..."
				elseif szName == "No Time Recorded" then
					szName = "No Time Recorded"
				else
					szName = "by " .. szName
					local pos = ply:GetNWInt("WRPos", 0)
					if pos > 0 then
						szName = "#" .. pos .. " Run " .. szName
					else
						szName = "Run " .. szName
					end
				end

				if not self.BoxColor then 
					self.BoxColor = Color(255, 0, 0) 
				end

				PlayerName = szName
			end

			draw.DrawText( PlayerName, "ScoreboardPlayer", s + 11, 9, Color( 0, 0, 0 ), TEXT_ALIGN_LEFT )
			draw.DrawText( PlayerName, "ScoreboardPlayer", s + 10, 8, Color( 200, 200, 200 ), TEXT_ALIGN_LEFT )
			
			surface.SetFont( "ScoreboardPlayer" )
			local wt, ht = surface.GetTextSize( "TimerText" )
			local wx = 105 - wt
			local o = w - wt - (wx * 2) - menu.RecordOffset
				
			local currentstyle = ply:GetNWInt("style", TIMER:GetStyleID("Normal"))
			local styles = TIMER:StyleName(currentstyle)

			if ply:IsBot() then
				styles = "R"
			else
				if styles == "Normal" then styles = "N" end
				if styles == "Bonus" then styles = "B" end
				if styles == "Segment" then styles = "S" end
				if styles == "Auto-Strafe" then styles = "AS" end
			end

			draw.DrawText(styles .. " - " .. con(ply:GetNWFloat("Record", 0)), "ScoreboardPlayer", o + 1, 9, Color(0, 0, 0), TEXT_ALIGN_RIGHT)
			draw.DrawText(styles .. " - " .. con(ply:GetNWFloat("Record", 0)), "ScoreboardPlayer", o, 8, Color(255, 255, 255), TEXT_ALIGN_RIGHT)

			local nSpecial = ply:GetNWInt( "SpecialRank", 0 )
			if nSpecial > 0 then
				surface.SetMaterial( icon.special[nSpecial] )
				surface.SetDrawColor( Color( 255, 255, 255 ) )
				surface.DrawTexturedRect( o + 4, h / 2 - 16, 32, 32 )
			end
			
			-- Display player's ping
			draw.DrawText(tostring(ply:Ping()), "ScoreboardPlayer", w - 9, 9, Color(0, 0, 0), TEXT_ALIGN_RIGHT)
			draw.DrawText(tostring(ply:Ping()), "ScoreboardPlayer", w - 10, 8, Color(255, 255, 255), TEXT_ALIGN_RIGHT)
		end
	end

	function btn:DoClick()
		GAMEMODE:DoScoreboardActionPopup( ply )
	end
	
	pList:AddItem( btn )
end

local function ListPlayers( self, pList, mw )
	local players = player.GetAll()
	table.sort( players, function( a, b )
		if not a or not b then return false end
		local ra, rb = a:GetNWInt( "Rank", 1 ), b:GetNWInt( "Rank", 1 )
		if ra == rb then
			return a:GetNWInt( "SpecialRank", 0 ) > b:GetNWInt( "SpecialRank", 0 )
		else
			return ra > rb
		end
	end )

	for k,v in pairs( pList:GetCanvas():GetChildren() ) do
		if IsValid( v ) then
			v:Remove()
		end
	end

	for k,ply in pairs( players ) do
		PutPlayerItem( self, pList, ply, mw )
	end
		
	pList:GetCanvas():InvalidateLayout()
end

local function CreateTeamList( parent, mw )
	local pList
	
	local pnl = vgui.Create("DPanel", parent)
	pnl:DockPadding(8, 8, 8, 8)
	
	function pnl:Paint(w, h) 
		surface.SetDrawColor(GUIColor.LightGray)
		surface.DrawRect(2, 2, w - 4, h - 4)
	end

	pnl.RefreshPlayers = function()
		ListPlayers(self, pList, mw)
	end

	local headp = vgui.Create("DPanel", pnl)
	headp:DockMargin(0, 0, 0, 4)
	headp:Dock(TOP)
	function headp:Paint() end

	local rank = vgui.Create("DLabel", headp)
	rank:SetText("Rank")
	rank:SetFont("ScoreboardPlayer")
	rank:SetTextColor(GUIColor.Header)
	rank:SetWidth(50)
	rank:Dock(LEFT)
	
	local player = vgui.Create("DLabel", headp)
	player:SetText("User")
	player:SetFont("ScoreboardPlayer")
	player:SetTextColor(GUIColor.Header)
	player:SetWidth(70)
	player:DockMargin(mw + 14, 0, 0, 0)
	player:Dock(LEFT)
	
	local ping = vgui.Create("DLabel", headp)
	ping:SetText("Ping")
	ping:SetFont("ScoreboardPlayer")
	ping:SetTextColor(GUIColor.Header)
	ping:SetWidth(50)
	ping:DockMargin(0, 0, 0, 0)
	ping:Dock(RIGHT)

	local timer = vgui.Create("DLabel", headp)
	timer:SetText("Record")
	timer:SetFont("ScoreboardPlayer")
	timer:SetTextColor(GUIColor.Header)
	timer:SetWidth(80)
	timer:DockMargin(0, 0, 80 + menu.RecordOffset, 0)
	timer:Dock(RIGHT)
	
	pList = vgui.Create("DScrollPanel", pnl)
	pList:Dock(FILL)

	local canvas = pList:GetCanvas()
	function canvas:OnChildAdded(child)
		child:Dock(TOP)
		child:DockMargin(0, 0, 0, 4)
	end

	return pnl
end

function GM:ScoreboardShow()
	if IsValid( menu ) then
		menu:SetVisible(true)
		
		if menu.Players then
			menu.Players:RefreshPlayers()
		end
	else
		menu = vgui.Create("DFrame")
		menu:SetSize(ScrW() * 0.5, ScrH() * 0.8)
		menu:Center()
		menu:SetKeyboardInputEnabled(false)
		menu:SetDeleteOnClose(false)
		menu:SetDraggable(false)
		menu:ShowCloseButton(false)
		menu:SetTitle("")
		menu:DockPadding(4, 4, 4, 4)
		menu.RecordOffset = ((ScrW() - 1280) / 64) * 8
		
		function menu:PerformLayout()
			menu.Players:SetWidth(self:GetWide())
		end

		function menu:Paint()
			surface.SetDrawColor(GUIColor.DarkGray)
			surface.DrawRect(0, 0, menu:GetWide(), menu:GetTall())
		end

		menu.Credits = vgui.Create("DPanel", menu)
		menu.Credits:Dock(TOP)
		menu.Credits:DockPadding(8, 6, 8, 0)
		
		function menu.Credits:Paint()
		end

		local name = Label( (BHOP.ServerName):format("bhop"), menu.Credits )
		name:Dock(LEFT)
		name:SetFont("MersRadial")
		name:SetTextColor(GUIColor.Header)
		
		function name:PerformLayout()
			surface.SetFont(self:GetFont())
			local w, h = surface.GetTextSize(self:GetText())
			self:SetSize(w, h)
		end

		local cred = vgui.Create( "DButton", menu.Credits )
		cred:Dock(RIGHT)
		cred:SetFont("MersText1")
		cred:SetText("Version " .. BHOP.Version.GM .. "\nGamemode by FiBzY")
		cred.PerformLayout = name.PerformLayout
		cred:SetTextColor(GUIColor.White)
		cred:SetDrawBackground( false )
		cred:SetDrawBorder( false )
		cred.DoClick = function()
			gui.OpenURL( "http://steamcommunity.com/id/fibzy_/" )
		end

		function menu.Credits:PerformLayout()
			surface.SetFont(name:GetFont())
			local w,h = surface.GetTextSize(name:GetText())
			self:SetTall(h)
		end

		menu.ServerInfos = vgui.Create("DPanel", menu)
		menu.ServerInfos:Dock(BOTTOM)
		menu.ServerInfos:SetTall(30)
		menu.ServerInfos:DockPadding(8, 3, 8, 0)
		
		function menu.ServerInfos:Paint()
		end

		local players = vgui.Create("DLabel", menu.ServerInfos)
		players:Dock(LEFT)
		players:SetFont("ScoreboardPlayer")
		players.NumSlots = game.MaxPlayers() - 2
		players:SetTextColor(GUIColor.White)
		players.PerformLayout = name.PerformLayout

		function players:Think()
			if menu.IsClickable then
				self:SetText( player.GetCount() - 2 .. "/" .. self.NumSlots .. " players (2 replays)" )
			else
				self:SetText("")
			end
		end

		local timeleft = vgui.Create("DLabel", menu.ServerInfos)
		timeleft:SetFont("ScoreboardPlayer")
		timeleft:SetTextColor(GUIColor.White)

		function timeleft:Think()
			local left = 500 - CurTime()
			if not menu.IsClickable then
				self:SetText("Click to interact with the scoreboard")
			elseif left > 0 then
				self:SetText("Vote starts in " .. string.ToMinutesSeconds(left) .. "s" )
			else
				self:SetText("Voting in progress")
			end
		end

		function timeleft:PerformLayout()
			surface.SetFont( self:GetFont() )
			local w, h = surface.GetTextSize( self:GetText() )
			self:SetPos(ScrW() * 0.24 - w * 0.5, 3)
			self:SetSize(w, h)
		end

		local map = vgui.Create("DButton", menu.ServerInfos)
		map:Dock(RIGHT)
		map:SetFont("ScoreboardPlayer")
		map:SetTextColor(GUIColor.White)
		map:SetDrawBackground(false)
		map:SetDrawBorder(false)
		map.PerformLayout = name.PerformLayout

		function map:Think()
			if menu.IsClickable then
				self:SetText( game.GetMap() )
			else
				self:SetText("")
			end
		end

		function map:DoClick()
			SetClipboardText( game.GetMap() )
		end

		surface.SetFont("ScoreboardPlayer")
		local mw,mh = surface.GetTextSize("Retrieving...")
		
		menu.Players = CreateTeamList(menu, mw)
		menu.Players:Dock(FILL)
		
		if menu.Players then
			menu.Players:RefreshPlayers()
		end
	end
end

function GM:DoScoreboardActionPopup( ply )
	if not IsValid( ply ) then return end
	local actions, open = vgui.Create("DarkMenu"), true

	if ply != LocalPlayer() then	
		if not ply:IsBot() then
			local nAccess = ply:GetNWInt( "AccessIcon", 0 )
			if nAccess > 0 then
				local admin = actions:AddOption("User is a " .. rank_str[ nAccess ])
				admin:SetMaterial(icon.access[nAccess])
				actions:AddSpacer()
			end
		
			local mute = actions:AddOption(ply:IsMuted() and "Unmute" or "Mute")
			mute:SetIcon("icon16/sound_mute.png")
			function mute:DoClick()
				if IsValid(ply) then
					ply:SetMuted(!ply:IsMuted())
				end
			end
			
			local chatmute = actions:AddOption(ply.ChatMuted and "Unmute chat" or "Mute chat")
			chatmute:SetIcon("icon16/keyboard_delete.png")
			function chatmute:DoClick()
				if IsValid(ply) then
					ply.ChatMuted = not ply.ChatMuted
					Link:Print( "General", ply:Name() .. " has been " .. (ply.ChatMuted and "chat muted" or "chat unmuted") )
				end
			end
			
			local profile = actions:AddOption("View users profile")
			profile:SetIcon("icon16/vcard.png")
			function profile:DoClick()
				if IsValid(ply) then
					ply:ShowProfile()
				end
			end
		else
			local Replay = actions:AddOption("This is a replay")
			Replay:SetIcon("icon16/control_end.png")
			actions:AddSpacer()
			
			local szURI = ply:GetNWString( "ProfileURI", "None" )
			if szURI != "None" then
				local uri = actions:AddOption("Open user profile")
				uri:SetIcon("icon16/vcard.png")
				function uri:DoClick()
					gui.OpenURL( "http://steamcommunity.com/profiles/" .. szURI )
				end
			end
		end
		
		local spec = actions:AddOption("View Player")
		spec:SetIcon("icon16/eye.png")
		function spec:DoClick()
			if IsValid(ply) then
				RunConsoleCommand( "spectate", ply:SteamID(), ply:Name() )
			end
		end
		
		if IsValid( LocalPlayer() ) and LocalPlayer().Style and LocalPlayer().Style == _C.Style.Practice then
			local tpto = actions:AddOption("Teleport to a player")
			tpto:SetIcon("icon16/lightning_go.png")
			function tpto:DoClick()
				if IsValid(ply) then
					RunConsoleCommand( "say", "!tp " .. ply:Name() )
				end
			end
		end
	else
		open = false
	end
	
	if open and IsValid( LocalPlayer() ) and LocalPlayer():IsAdmin() then
		actions:AddSpacer()

		local Option1 = actions:AddOption("Copy Name")
		Option1:SetIcon("icon16/page_copy.png")
		function Option1:DoClick()
			local name = ply:IsBot() and ply:GetNWString("BotName", "Inconnu") or ply:Name()
			SetClipboardText( name )
		end
		
		local Option3 = actions:AddOption("Copy SteamID")
		Option3:SetIcon("icon16/page_copy.png")
		function Option3:DoClick()
			local steamID = ply:IsBot() and ply:GetNWString("NSteamID", "NONE") or ply:SteamID()
			SetClipboardText( steamID )
		end

		actions:AddSpacer()
		
		local Option4 = actions:AddOption("Specate the player")
		Option4:SetIcon("icon16/eye.png")
		function Option4:DoClick()
			_AA( "spectator", ply:SteamID() )
		end
		
		local Option4a = actions:AddOption("Remove weapons from user")
		Option4a:SetIcon("icon16/delete.png")
		function Option4a:DoClick()
			_AA( "strip", ply:SteamID() )
		end
		
		local Option4b = actions:AddOption("Monitor sync")
		Option4b:SetIcon("icon16/eye.png")
		function Option4b:DoClick()
			_AA( "monitor", ply:SteamID() )
		end
		
		local Option5 = actions:AddOption((ply.ChatMuted and "Un" or "M") .. "ute the player")
		Option5:SetIcon("icon16/keyboard_" .. (not ply.ChatMuted and "delete" or "add") .. ".png")
		function Option5:DoClick()
			_AA( "mute", ply:SteamID() )
		end
		
		local muted = ply:GetNWBool( "AdminGag", false )
		local Option6 = actions:AddOption((muted and "Ung" or "G") .. "ag the player")
		Option6:SetIcon("icon16/sound" .. (not muted and "_mute" or "") .. ".png")
		function Option6:DoClick()
			_AA( "gag", ply:SteamID() )
		end
		
		local Option7 = actions:AddOption("Kick player")
		Option7:SetIcon("icon16/door_out.png")
		function Option7:DoClick()
			_AA( "kick", ply:SteamID() )
		end
		
		local Option8 = actions:AddOption("Ban user")
		Option8:SetIcon("icon16/report_user.png")
		function Option8:DoClick()
			_AA( "ban", ply:SteamID() )
		end
	end

	if open then
		actions:Open()
	end
end

function GM:ScoreboardHide()
	if IsValid( menu ) then 
		menu:Close() 
		menu.IsClickable = false
		gui.EnableScreenClicker(false)
	end 
end
function GM:HUDDrawScoreBoard() end

hook.Add("CreateMove", "ClickableScoreBoard", function(cmd)
	if not ( IsValid(menu) and menu:IsVisible() ) then return end
	if not ( cmd:KeyDown(IN_ATTACK) or cmd:KeyDown(IN_ATTACK2) ) then return end
	if not menu.IsClickable then 
		menu.IsClickable = true
		gui.EnableScreenClicker(true)
	end
	cmd:RemoveKey(IN_ATTACK)
	cmd:RemoveKey(IN_ATTACK2)
end)

local DarkMenu = {
	AddOption = function(self, strText, funcFunction)
		local pnl = vgui.Create( "DMenuOption", self )
		pnl:SetMenu( self )
		pnl:SetText( strText )
		pnl:SetTextColor( Color(255, 255, 255) )
		pnl.Paint = self.OptionPaint
		if ( funcFunction ) then pnl.DoClick = funcFunction end
	
		self:AddPanel( pnl )
	
		return pnl
	end,

	OptionPaint = function(panel, w, h)
		if ( panel.m_bBackground && ( panel.Hovered || panel.Highlight) ) then
			local margin, outline = 2, 1
			surface.SetDrawColor(Color( 255, 255, 0))
			surface.DrawRect(margin, margin, w - margin * 2, h - margin * 2)

			surface.SetDrawColor(255, 255, 255, 100)
			surface.DrawRect(margin, margin, w - margin * 2, outline)
			surface.DrawRect(margin, h - margin - outline, w - margin * 2, outline)
			surface.DrawRect(margin, margin + outline, outline, h - 2 * margin - 2 * outline)
			surface.DrawRect(w - margin - outline, margin + outline, outline, h - 2 * margin - 2 * outline)
		end
	end,

	AddSpacer = function(self, strText, funcFunction)
		local pnl = vgui.Create( "DPanel", self )
		pnl.Paint = function( p, w, h )
			surface.SetDrawColor(255, 255, 255, 100)
			surface.DrawRect( 0, 0, w, h )
		end
	
		pnl:SetTall( 1 )
		self:AddPanel( pnl )
	
		return pnl
	end,

	Paint = function(self, w, h)
		surface.SetDrawColor(GUIColor.DarkGray) 
		surface.DrawRect(0, 0, w, h)

		local outline = 1
		surface.SetDrawColor(255, 255, 255, 100)
		surface.DrawRect(0, 0, w, outline)
		surface.DrawRect(0, h - outline, w, outline)
		surface.DrawRect(0, outline, outline, h - 2 * outline)
		surface.DrawRect(w - outline, outline, outline, h - 2 * outline)
	end
}

vgui.Register("DarkMenu", DarkMenu, "DMenu")