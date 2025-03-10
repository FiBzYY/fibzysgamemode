local SCORE_HEIGHT = ScrH() - 118
local SCORE_WIDTH = (ScrW() / 2) + 150

local SCORE_TITLE = BHOP.ServerName
local SCORE_PLAYERS = "%s/%s Players connected"
local SCORE_CREDITS = "Gamemode by FiBzY, version " .. BHOP.Version.GM
local SCORE_SPONSORED = "Server sponsored by Crousty Cloud"

local abs = math.abs
local sin = math.sin
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

local ranks = {"VIP", "VIP+", "Moderator", "Admin", "Zone Admin", "Super Admin", "Developer", "Manager", "Founder", "Owner"}

local function CreateScoreboard()
	if (scoreboard) then
		if (scoreboard_playerrow) then
			scoreboard_playerrow:Remove()
			scoreboard_playerrow = nil
		end
		scoreboard:Remove()
		scoreboard = nil
		gui.EnableScreenClicker(false)

		return
	end

	gui.EnableScreenClicker(false)

	scoreboard = vgui.Create("EditablePanel")
		scoreboard:SetSize(SCORE_WIDTH, SCORE_HEIGHT)
		scoreboard:Center()

		scoreboard.Paint = function(self, width, height)
			SCORE_ONE = Color(32, 32, 32, 255)
			SCORE_TWO = Color(42, 42, 42, 255)
			SCORE_THREE = Color(34, 34, 38, 170)
			SCORE_ACCENT = Color(80, 30, 40, 170)
			outlines = Color(0,0,0)

			text_colour = color_white
			text_colour2 = color_white

			surface.SetDrawColor(SCORE_ONE)
			surface.DrawRect(0, 0, width, height)
			surface.SetDrawColor(outlines)

			if outlines then
				surface.DrawOutlinedRect(0, 0, width, height)
			end

			draw.SimpleText(SCORE_TITLE, "hud.title", width / 2, 12, text_colour, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

			draw.SimpleText(game.GetMap(), "hud.title", 14, 12, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

			local text = string.format(SCORE_PLAYERS, #player.GetHumans(), game.MaxPlayers()-2)
			draw.SimpleText(text, "hud.title", width - 14, 12, text_colour, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

			draw.SimpleText(SCORE_CREDITS, "hud.credits", 14, height - 20, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

			draw.SimpleText(SCORE_SPONSORED, "hud.credits", width / 2, height - 20, text_colour, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			draw.SimpleText("Click on a player's name for more options!", "hud.credits", width - 14, height - 20, text_colour, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
		end

	scoreboard.base = scoreboard:Add("DPanel")
		scoreboard.base:SetSize(SCORE_WIDTH - 28, SCORE_HEIGHT - 150)
		scoreboard.base:SetPos(14, 40)

		scoreboard.base.Paint = function(self, width, height)
			surface.SetDrawColor(SCORE_TWO)
			surface.DrawRect(0, 0, width, 22)
			surface.SetDrawColor(outlines)

			if outlines then
				surface.DrawOutlinedRect(0, 0, width, 21)
			end

			local distance = (width / 10)
			draw.SimpleText("Rank", "hud.infotext", 12, 10, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText("Player", "hud.infotext", distance * 1.5, 10, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText("Style", "hud.infotext", distance * 4.5, 10, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText("Status", "hud.infotext", distance * 5.7, 10, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText("Personal Best", "hud.infotext", distance * 8.5, 10, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText("Ping", "hud.infotext", width - 12, 10, text_colour, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		end

	local width, height = scoreboard.base:GetSize()

	local function CreatePlayerRow(pl, isBot)
		local row = vgui.Create("DButton", isBot and scoreboard.bots or scoreboard.players)

		row:SetSize(width, 40)
		row:SetText("")

		row.Paint = function(self, width, height)
			if (not IsValid(pl)) then
				scoreboard.players.AddPlayers()
				return
			end

			surface.SetDrawColor(isBot and SCORE_ACCENT or SCORE_THREE)
			surface.DrawRect(0, 0, width, height)
			surface.SetDrawColor(outlines)

			if outlines then
				surface.DrawOutlinedRect(0, 0, width, height)
			end

			local distance = (width / 10)

			local rankID = pl:GetNWInt("Rank", -1)
			local rankInfo = TIMER.Ranks[rankID] or {"User", color_white}

			draw.SimpleText(isBot and "WR Bot" or rankInfo[1], "hud.subtitle", 12, 20, isBot and text_colour or rankInfo[2], TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

			local name = isBot and pl:GetNWString("BotName", "Loading...") or pl:Nick()
			if isBot and (name ~= "Loading..." and name <= "No Replay Available") then
				local position = pl:GetNWInt("WRPos", 0)
				name = ( ("#" .. position .. " run ") or "Run ") .. "by " .. name
			end

			surface.SetFont("hud.subtitle")
			local namewidth, nameheight = surface.GetTextSize(name)

			local playerRankID = pl:GetNWInt("AccessIcon", 0)
			local playerRank = playerRankID == 0 and "User" or (ranks[playerRankID] or "Unknown")

			if playerRank ~= "User" then
				draw.SimpleText(string.upper(playerRank), "hud.subinfo2", (distance * 1.5) + namewidth + 2, 19 + nameheight / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
			end

			local nameColor = text_colour

			if pl:SteamID() == "STEAM_0:0:87749794" then
				nameColor = Color(0, 220 * abs(sin(CurTime())), 255)
			elseif pl:SteamID() == "STEAM_0:1:48688711" then
				nameColor = HSVToColor(RealTime() * 40 % 360, 1, 1)
			elseif pl:GetObserverMode() ~= OBS_MODE_NONE then
				nameColor = Color(150, 150, 150, 255)
			end

			draw.SimpleText(name, "hud.subtitle", distance * 1.5, 20, nameColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            local currentstyle = pl:GetNWInt("Style", TIMER:GetStyleID("Normal"))
            local style = TIMER:StyleName(currentstyle)
			draw.SimpleText(style, "hud.subtitle", distance * 4.5, 20, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

			local status = "Start Zone"
			local curr = style == "B" and (pl.bonustime or 0) or (pl.time or 0)
			local inPlay = style == "B" and (pl.bonustime ~= nil) or (pl.time ~= nil)
			local finished = style == "B" and (pl.bonusfinished) or (pl.finished)

			if (pl:IsBot()) then
				status = "Play the Record"
			elseif (pl:GetObserverMode() ~= OBS_MODE_NONE) then
				local tgt = pl:GetObserverTarget()

				if tgt and IsValid(tgt) and (tgt:IsPlayer() or tgt:IsBot()) then
					local nm = (tgt:IsBot() and (tgt:GetNWString("BotName", "Loading...") .. "'s Replay") or tgt:Nick())

					if (string.len(nm) > 20) then
						nm = nm:Left(20) .. "..."
					end

					status = "Spectating: " .. nm
				else
					status = "Spectating"
				end

			elseif pl:GetNWInt('inPractice', false) then
				status = "Practicing"
			elseif curr > 0 and finished ~= nil then
                status = "Finished: " .. SecondsToClock(TIMER:Convert(curr, finished))
			elseif curr > 0 then
               local runningTime = TIMER:Convert(curr, engine.TickCount())
               status = "Running: " .. SecondsToClock(runningTime)
			end

			draw.SimpleText(status, "hud.subtitle", distance * 5.7, 20, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

			local pb = con(pl:GetNWFloat("Record", 0))

			if not pl:IsBot() then
				surface.SetFont "hud.subtitle"
				local place = pl:GetNWInt("SpecialRank", 0)

				if (place == 0) then
					draw.SimpleText(pb, "hud.subtitle", distance * 8.5, 20, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				else

					local w, h = surface.GetTextSize(place)

					draw.SimpleText(pb, "hud.subtitle", distance * 8.5 + 6 + w, 20, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
					draw.SimpleText("#" .. place, "hud.subinfo", distance * 8.5, 20, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				end
			else
				draw.SimpleText(pb, "hud.subtitle", distance * 8.5, 20, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end

	 	   local colour246 = color_white
	   		 if pl:Ping() > 0 then
	    			if pl:Ping() >= 100 then
		 			   	colour246 = Color(255, 0, 0)
	       			 else
	    				if pl:Ping() >= 60 then
		  	  			colour246 = Color(255, 255, 0)
	      	  		else 
		 	  		 	colour246 = Color(0, 255, 0)
			  		end 
	   			end
			end
			if not pl:IsBot() then
			local latency = pl:Ping()
				draw.SimpleText(latency, "hud.subtitle", width - 12, 20, colour246, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			end
		end

		row.OnMousePressed = function(self)
			if (not scoreboard.moved) then
				local x, y = scoreboard:GetPos()
				scoreboard.moved = true
				scoreboard:MoveTo(x - 150, y, 0.5, 0, -1, function()
					scoreboard_playerrow = vgui.Create("EditablePanel")
					scoreboard_playerrow:SetPos(x + SCORE_WIDTH - 290 / 2, y)
					scoreboard_playerrow:SetSize(300, pl:IsBot() and 265 - 93 or 265)
					scoreboard_playerrow.pl = pl
					scoreboard_playerrow.Paint = function(self, width, height)
						surface.SetDrawColor(SCORE_ONE)
						surface.DrawRect(0, 0, width, height)
						surface.SetDrawColor(outlines)

						if outlines then
							surface.DrawOutlinedRect(0, 0, width, height)
						end

						surface.SetFont "hud.title"

						draw.SimpleText(scoreboard_playerrow.pl:IsBot() and scoreboard_playerrow.pl:GetNWString("BotName", "Loading...") or scoreboard_playerrow.pl:Nick(), "hud.title", 84, 26, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

						local rank = scoreboard_playerrow.pl:GetNWInt("AccessIcon", 0)
						rank = rank == 0 and "User" or ranks[rank]
						draw.SimpleText(scoreboard_playerrow.pl:IsBot() and "Replay" or rank, "hud.title", 84, 44, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

						draw.SimpleText("", "hud.title", 84, 56, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

						surface.DrawLine(0, 84, width, 84)

						if (not scoreboard_playerrow.pl:IsBot()) then
							if outlines then
								surface.DrawOutlinedRect(width - 110, 94, 100, 20)
							end

							local pRank = TIMER.Ranks[scoreboard_playerrow.pl:GetNWInt("Rank", -1)]
							draw.SimpleText("Rank: " .. pRank[1], "hud.subtitle", 10, 104, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
							draw.SimpleText("Points: Feature disabled.", "hud.subtitle", 10, 122, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
							draw.SimpleText("Place: Feature disabled.", "hud.subtitle", 10, 140, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
							draw.SimpleText("WRs : Feature disabled.", "hud.subtitle", 10, 158, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
						end

						surface.DrawLine(0, 177, width, 177)
					end

					local width, height = 300, 200

					scoreboard_playerrow.Avatar = scoreboard_playerrow:Add("AvatarImage")
					scoreboard_playerrow.Avatar:SetPos(10, 10)
					scoreboard_playerrow.Avatar:SetSize(64, 64)

					if (scoreboard_playerrow.pl:IsBot()) then
						scoreboard_playerrow.Avatar:SetSteamID(scoreboard_playerrow.pl:GetNWString("ProfileURI", "None"), 256)
					else
						scoreboard_playerrow.Avatar:SetPlayer(scoreboard_playerrow.pl, 256)
					end

					scoreboard_playerrow.Combo = scoreboard_playerrow:Add("DComboBox")
					scoreboard_playerrow.Combo:SetPos(width - 110, 94)
					scoreboard_playerrow.Combo:SetSize(100, 20)
					scoreboard_playerrow.Styles = {}

					if (scoreboard_playerrow.pl:IsBot()) then
						scoreboard_playerrow.Combo:SetVisible(false)
					end

					scoreboard_playerrow.Combo:AddChoice("Désactivé", 1)
					scoreboard_playerrow.Combo:ChooseOptionID(1)
					scoreboard_playerrow.Combo.Paint = function(self, width, height)
					end
					scoreboard_playerrow.Combo:SetTextColor(color_white)

					local amount = 1
					scoreboard_playerrow.butts = {}
					local function NewButton(name, y, func)
						local b = vgui.Create("DButton", scoreboard_playerrow)

						b.oy = y
						b:SetPos(amount % 2 == 0 and 150 or 10, scoreboard_playerrow.pl:IsBot() and y - 93 or y)
						b:SetSize(138, 20)
						b:SetText("")
						b.Paint = function(self, width, height)
							surface.SetDrawColor(SCORE_TWO)
							surface.DrawRect(0, 0, width, height)
							surface.SetDrawColor(outlines)

							if outlines then
								surface.DrawOutlinedRect(0, 0, width, height)
							end

							draw.SimpleText(name, "hud.subtitle", width / 2, height / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
						end
						b.OnMousePressed = function()
							func()
						end

						amount = amount + 1
						table.insert(scoreboard_playerrow.butts, b)
					end

					NewButton("Spectate", 187, function()
						RunConsoleCommand("spectate", scoreboard_playerrow.pl:SteamID(), scoreboard_playerrow.pl:Name())
					end)

					NewButton("TP", 187, function()
						RunConsoleCommand( "say", "!tp " .. scoreboard_playerrow.pl:Name())
					end)

					NewButton("Profile", 211, function()
						gui.OpenURL("http://www.steamcommunity.com/profiles/" .. (scoreboard_playerrow.pl:IsBot() and scoreboard_playerrow.pl:GetNWString("ProfileURI", "None") or scoreboard_playerrow.pl:SteamID64()))
					end)

					NewButton("Copy SteamID", 211, function()
						if (scoreboard_playerrow.pl:IsBot()) then
							SetClipboardText(util.SteamIDFrom64(scoreboard_playerrow.pl:GetNWString("ProfileURI", "None")))
						else
							SetClipboardText(scoreboard_playerrow.pl:SteamID())
						end

						UTIL:AddMessage("Server", "Player " .. (scoreboard_playerrow.pl:IsBot() and scoreboard_playerrow.pl:GetNWString("BotName", "Loading...") or scoreboard_playerrow.pl:Nick()) .. "'s SteamID has been copied to your clipboard.")
					end)

					NewButton("Voice mute", 235, function()
						local pl = scoreboard_playerrow.pl

						if (pl == LocalPlayer()) then
							UTIL:AddMessage("Server", "You can't mute yourself.")
							return
						end

						if (pl:IsBot()) then
							UTIL:AddMessage("Server", "You cannot send a private message to a replay.")
							return
						end

						UTIL:AddMessage("Server",  "Player " .. pl:Nick() .. " has been " .. (not pl:IsMuted() and "voice muted." or "un-muted."))
						pl:SetMuted(not pl:IsMuted())
					end)

					NewButton("Mute Player", 235, function()
						local pl = scoreboard_playerrow.pl

						if (pl == LocalPlayer()) then
							UTIL:AddMessage("Server", "You can't mute yourself.")
							return
						end

						if (pl:IsBot()) then
							UTIL:AddMessage("Server","You cannot send a private message to a replay.")
							return
						end

						pl.ChatMuted = not pl.ChatMuted
						UTIL:AddMessage("Server", "Player " .. pl:Name() .. " has been" .. (pl.ChatMuted and " chat muted." or " un-muted."))
					end)
				end)
			elseif (scoreboard.moved) and (scoreboard_playerrow) then
				scoreboard_playerrow.pl = pl
				scoreboard_playerrow.Avatar:SetPlayer(pl, 256)

				if (pl:IsBot()) then
					scoreboard_playerrow.Combo:SetVisible(false)
					scoreboard_playerrow:SetTall(265-93)
					scoreboard_playerrow.Avatar:SetSteamID(pl:GetNWString("ProfileURI", "None"), 256)

					for k, v in pairs(scoreboard_playerrow.butts) do
						local x, y = v:GetPos()
						v:SetPos(x, v.oy - 93)
					end
				else
					scoreboard_playerrow.Combo:SetVisible(true)
					scoreboard_playerrow:SetTall(265)

					for k, v in pairs(scoreboard_playerrow.butts) do
						local x, y = v:GetPos()
						v:SetPos(x, v.oy)
					end
				end
			end
		end

		return row
	end

	scoreboard.players = scoreboard.base:Add("DScrollPanel")
		scoreboard.players:SetSize(width, height - 30)
		scoreboard.players:SetPos(0, 20)
		scoreboard.players.list = {}
		scoreboard.players.VBar:SetSize(0,0)

		scoreboard.players.AddPlayers = function()
			for k, v in pairs(scoreboard.players.list) do
				v:Remove()
				scoreboard.players.list[k] = nil
			end

			local players = player.GetHumans()
			table.sort(players, function(a, b)
				if not a or not b then return false end
				local ra, rb = a:GetNWInt("Rank", 1), b:GetNWInt("Rank", 1)
				if ra == rb then
					return a:GetNWInt("SpecialRank", 0) > b:GetNWInt("SpecialRank", 0)
				else
					return ra > rb
				end
			end)

			for k, v in pairs(players) do
				local row = CreatePlayerRow(v)
				row:SetPos(0, #scoreboard.players.list == 0 and 0 or #scoreboard.players.list * 39)

				table.insert(scoreboard.players.list, row)
			end

			local height = 182 + (#player.GetHumans() * 39)

			if (height > SCORE_HEIGHT) then
				height = SCORE_HEIGHT
			end

			scoreboard:SetTall(height)
			scoreboard:Center()

			if (scoreboard.bots) then
				scoreboard.bots:SetPos(14, scoreboard:GetTall() - 125)
			end
		end

		scoreboard.players.AddPlayers()

		scoreboard.players.PaintOver = function(self, width, height)
			surface.SetDrawColor(color_black)

			local th = (#scoreboard.players.list * 40)-20

			if (th > height) then
				if outlines then
					surface.DrawOutlinedRect(0, 0, width, height)
				end
			end
		end

	scoreboard.bots = scoreboard:Add("DPanel")
		scoreboard.bots:SetSize(width, 79)
		scoreboard.bots:SetPos(14, scoreboard:GetTall() - 105)
		scoreboard.bots.Paint = function(s,width,height)
		end
		scoreboard.bots.list = {}

		for k, v in pairs(player.GetBots()) do
			local Replay = CreatePlayerRow(v, true)
			Replay:SetPos(0, #scoreboard.bots.list == 0 and 0 or #scoreboard.bots.list * 39)
			table.insert(scoreboard.bots.list, Replay)
		end
end

function GM:ScoreboardShow()
	CreateScoreboard()
end

function GM:ScoreboardHide()
		CreateScoreboard()
	if IsValid( scoreboard ) then 
		scoreboard:Remove() 
		scoreboard.IsClickable = false
		gui.EnableScreenClicker(false)
	end 
end
function GM:HUDDrawScoreBoard() end

hook.Add("CreateMove", "ClickableScoreBoard", function(cmd)
	if not ( IsValid(scoreboard) and scoreboard:IsVisible() ) then return end
	if not ( cmd:KeyDown(IN_ATTACK) or cmd:KeyDown(IN_ATTACK2) ) then return end
	if not scoreboard.IsClickable then 
		scoreboard.IsClickable = true
		gui.EnableScreenClicker(true)
	end

	cmd:RemoveKey(IN_ATTACK)
	cmd:RemoveKey(IN_ATTACK2)
end)