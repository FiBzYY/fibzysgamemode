-- Cache
local lp, Iv, ct, hook_Add, DrawText = LocalPlayer, IsValid, CurTime, hook.Add, draw.SimpleText
local str_format = string.format
local math_floor = math.floor

PRIMARY = color_white
SECONDARY = color_white
TRI = color_white
ACCENT = color_white
TEXT = color_white 
OUTLINE = color_white

-- Ranks
local ranks = {"VIP", "VIP+", "Moderator", "Admin", "Zone Admin", "Super Admin", "Developer", "Manager", "Founder", "Owner"}

timeLeft = 0

-- Time left
NETWORK:GetNetworkMessage("RTVTimeLeft", function(_, data)
    timeLeft = data[1]
end)

local scoreboard
local con = function(ns) return SecondsToClock(ns) end

-- Time to ticks
function TIMER:Convert(startTick, endTick)
    if not startTick or not endTick then
        return 0
    end

    local tickRate = engine.TickInterval()
    return (endTick - startTick) * tickRate
end

-- Seconds to ticks
function SecondsToClock(seconds)
    seconds = tonumber(seconds) or 0
    local wholeSeconds = math_floor(seconds)
    local milliseconds = math_floor((seconds - wholeSeconds) * 100)
    local hours = math_floor(wholeSeconds / 3600)
    local minutes = math_floor((wholeSeconds % 3600) / 60)
    local secs = wholeSeconds % 60

    if hours > 0 then
        return str_format("%d:%02d:%02d.%02d", hours, minutes, secs, milliseconds)
    else
        return str_format("%02d:%02d.%02d", minutes, secs, milliseconds)
    end
end

-- Time display
local function cTime(ns)
    if ns > 3600 then
        return str_format("%d:%.2d:%.2d", math_floor(ns / 3600), math_floor(ns / 60 % 60), math_floor(ns % 60))
    elseif ns > 60 then 
        return str_format("%.1d:%.2d", math_floor(ns / 60 % 60), math_floor(ns % 60))
    else
        return str_format("%.1d", math_floor(ns % 60))
    end
end

local lp, Iv, ct, ceil, fl, fo, mc = LocalPlayer, IsValid, CurTime, math.ceil, math.floor, string.format, math.Clamp
local function ConvertTimeWR(ticks, fractionalTicks)
    if not ticks or type(ticks) ~= "number" or ticks < 0 then
        return "00:00.000"
    end

    local ns = (ticks + (fractionalTicks or 0) / 10000)
    local wholeSeconds = fl(ns)
    local milliseconds = fl((ns - wholeSeconds) * 1000)

    local hours = fl(wholeSeconds / 3600)
    local minutes = fl((wholeSeconds / 60) % 60)
    local seconds = wholeSeconds % 60

    if hours > 0 then
        return fo("%d:%.2d:%.2d.%.3d", hours, minutes, seconds, milliseconds)
    else
        return fo("%.2d:%.2d.%.3d", minutes, seconds, milliseconds)
    end
end

-- Draw a star
local function drawStar(size, posX, posY, color, radius, innerRadius, pointStretch)
    radius = radius or 50
    innerRadius = innerRadius or 200
    pointStretch = pointStretch or 1.5
    color = color or Color(255, 255, 255, 255)

    render.ClearStencil()
    render.SetStencilEnable(true)
    render.SetStencilWriteMask(255)
    render.SetStencilTestMask(255)
    render.SetStencilFailOperation(STENCILOPERATION_REPLACE)
    render.SetStencilPassOperation(STENCILOPERATION_ZERO)
    render.SetStencilZFailOperation(STENCILOPERATION_ZERO)
    render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_NEVER)
    render.SetStencilReferenceValue(1)

    local star = {}
    local points = 5
    local angleStep = math.pi / points

    for i = 0, points * 2 - 1 do
        local baseRadius = (i % 2 == 0) and radius * pointStretch or innerRadius
        local scaledRadius = baseRadius * size

        local angle = i * angleStep + math.pi / 2
        local px = posX + math.cos(angle) * scaledRadius
        local py = posY + math.sin(angle) * scaledRadius
        table.insert(star, {x = px, y = py})
    end

    draw.NoTexture()
    surface.SetDrawColor(255, 255, 255, 255)
    surface.DrawPoly(star)

    render.SetStencilFailOperation(STENCILOPERATION_ZERO)
    render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
    render.SetStencilZFailOperation(STENCILOPERATION_ZERO)
    render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
    render.SetStencilReferenceValue(1)

    draw.NoTexture()
    surface.SetDrawColor(color.r, color.g, color.b, color.a)
    surface.DrawPoly(star)

    render.SetStencilEnable(false)
    render.ClearStencil()
end

-- Cycle
local cycleText = {"Welcome", "Velocity"}
local cycleText2 = {"Bunny Hop", BHOP.Version.GM}
local cycleDelay = 5
local lastUpdateTime = 0
local currentTextIndex = 1

local function UpdateCycleText(ply)
    if Iv(ply) then
        local speed = math.Round(ply:GetVelocity():Length2D())
        if speed > 33 then
            cycleText[1] = "Velocity (" .. speed .. " u/s)"
        end
        cycleText[2] = BHOP.ServerName
    end
end

local function UpdateCycleText2(ply)
    if Iv(ply) then
        local speed = math.Round(ply:GetVelocity():Length2D())
        if speed > 33 then
            cycleText2[1] = "Velocity (" .. speed .. " u/s)"
        end
        cycleText2[2] = BHOP.ServerName
    end
end

local blur = Material("pp/blurscreen")

-- Blur HUD
local function ChessnutBlur(panel, layers, density, alpha)
    local x, y = panel:LocalToScreen(0, 0)
    surface.SetDrawColor(255, 255, 255, alpha)
    surface.SetMaterial(blur)
    for i = 1, 3 do
        blur:SetFloat("$blur", (i / layers) * density)
        blur:Recompute()
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(-x, -y, ScrW(), ScrH())
    end
end

-- Scoreboard
local function CreateScoreboard(shouldHide)
    if shouldHide then
        if not scoreboard then return end 
        CloseDermaMenus()
        scoreboard:Remove()
        scoreboard = nil
        gui.EnableScreenClicker(false)
        return
    end

    if scoreboard then return end 

    local WIDTH = 950
    local HEIGHT = 525

    if ScrW() < WIDTH then 
        WIDTH = ScrW() * 0.9
        HEIGHT = ScrH() * 0.5 
    end

    gui.EnableScreenClicker(false)

    scoreboard = vgui.Create("EditablePanel")
    scoreboard:SetSize(WIDTH, HEIGHT)
    scoreboard:Center()
    scoreboard.spectators = {}

    local height = 54 
    local x = 6
    local width = WIDTH - (x * 2)
    
    function scoreboard:Paint(w, h)
        -- Themes
		self.theme = Theme:GetPreference("Scoreboard")
		self.themec = self.theme["Colours"]
        self.themet = self.theme["Toggles"]
        
        PRIMARY = self.themec["Primary Colour"]
        SECONDARY = self.themec["Secondary Colour"]
        TRI = self.themec["Tri Colour"]
        ACCENT = self.themec["Accent Colour"]
        TEXT = self.themec["Text Colour"]
        OUTLINE = self.themec["Outlines Colour"]

        surface.SetDrawColor(TRI)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(PRIMARY)
        surface.DrawRect(x, x, w - (x * 2), (height * 2) + x)

        local curTime = CurTime()
        if curTime - lastUpdateTime >= cycleDelay then
            lastUpdateTime = curTime
            currentTextIndex = currentTextIndex % 2 + 1
            UpdateCycleText(lp())
        end

        local y = (height + x + x) / 2

        DrawText(cycleText[currentTextIndex], "ui.mainmenu.title2", w / 2, y, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        DrawText(game.GetMap(), "ui.mainmenu.button", x + x, y, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        if timeLeft > 0 then
            local timeString = cTime(timeLeft)
    
            DrawText("Timeleft: " .. timeString, "ui.mainmenu.button", w - x - 10, y, textColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end

        local lst = ""
        for k, v in pairs(self.spectators) do 
            lst = lst .. v:Nick() .. ", "
        end
        
        if string.EndsWith(lst, ", ") then 
            lst = string.sub(lst, 1, #lst - 2)
        else 
            lst = "None"
        end

        DrawText("Spectators: " .. lst, "ui.mainmenu.button", x + 2, h - (height / 3) - (x / 2) + 1, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        DrawText("Players: " .. #player.GetHumans() .. "/" .. game.MaxPlayers() - 2, "ui.mainmenu.button", w - x - 2, h - (height / 3) - (x / 2) + 1, TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        
        if curTime - lastUpdateTime >= cycleDelay then
            lastUpdateTime = curTime
            currentTextIndex = currentTextIndex % 2 + 1
            UpdateCycleText2(lp())
        end

        DrawText(cycleText2[currentTextIndex], "ui.mainmenu.button", w - x - 465, h - (height / 3) - (x / 2) + 1, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- Replays
    scoreboard.bots = scoreboard:Add("DPanel")
    scoreboard.bots:SetPos(x * 2, height + x)
    scoreboard.bots:SetSize(width - (x * 2), height)
    scoreboard.bots.list = {}

    scoreboard.specs = scoreboard:Add("DPanel")
    scoreboard.specs:SetPos(x, HEIGHT - 34)
    scoreboard.specs:SetSize(width, 34)
    scoreboard.specs.Paint = function() end 

    local function createDermaMenu(v, a)
        local b = PRIMARY
        local col = Color(b.r + 5, b.g + 5, b.b + 5, 255)
        local col2 = Color(b.r + 10, b.g + 10, b.b + 10, 255)

        local menu = a or DermaMenu()
        menu:SetDrawBorder(false)
        menu:SetDrawColumn(false)
        menu:SetMinimumWidth(200)
        menu.Paint = function(s, w, h) 
            surface.SetDrawColor(s:IsHovered() and col or col2)
            surface.DrawRect(0, 0, w, h)
        end

        if not a then 
            menu:AddOption("Spectate", function()
                lp():ConCommand("say !spectate " .. v:Name())
            end)
        end 

        menu:AddOption("Copy SteamID", function() 
            SetClipboardText(v:IsBot() and v.steamid or v:SteamID())
            UTIL:AddMessage("Server", v:Nick(), "'s steamid copied to clipboard.")
        end)

        menu:AddOption("Goto Profile", function() 
            gui.OpenURL("http://www.steamcommunity.com/profiles/" .. (v:IsBot() and util.SteamIDTo64(v.steamid) or v:SteamID64()))
        end)

        if not v:IsBot() then 
            menu:AddSpacer()
            menu:AddOption("Mute Player", function() end)
            menu:AddOption("Gag Player", function() end)
            menu:AddSpacer()
            menu:AddOption("Kick Player", function() end)
            menu:AddOption("Ban Player", function() end)
        end

        for i = 1, menu:ChildCount() do 
            local item = menu:GetChild(i)
            if item.SetTextColor then 
                function item:Paint(w, h) 
                    surface.SetDrawColor(self:IsHovered() and col or col2)
                    surface.DrawRect(0, 0, w, h)
                end
                item:SetTextColor(TEXT)
                item:SetFont("ui.mainmenu.button")
                item:SetIsCheckable(false)
            end
        end

        if not a then 
            menu:Open()
        end
    end

    function scoreboard.specs:OnMousePressed()
        local b = PRIMARY
        local col = Color(b.r + 5, b.g + 5, b.b + 5, 255)
        local col2 = Color(b.r + 10, b.g + 10, b.b + 10, 255)

        local smenu = DermaMenu()
        self.lst = {}

        smenu:SetDrawBorder(false)
        smenu:SetDrawColumn(false)
        smenu:SetMinimumWidth(200)
        smenu.Paint = function(s, w, h) 
            surface.SetDrawColor(s:IsHovered() and col or col2)
            surface.DrawRect(0, 0, w, h)
        end

        for k, v in pairs(scoreboard.spectators) do 
            local x = smenu:AddSubMenu(v:Nick(), function() 
                createDermaMenu(v, self.lst[k])
            end)

            createDermaMenu(v, x)
        end 

        for i = 1, smenu:ChildCount() do 
            local item = smenu:GetChild(i)
            if item.SetTextColor then 
                function item:Paint(w, h) 
                    surface.SetDrawColor(self:IsHovered() and col or col2)
                    surface.DrawRect(0, 0, w, h)
                end
                item:SetTextColor(TEXT)
                item:SetFont("ui.mainmenu.button")
                item:SetIsCheckable(false)
            end
        end
        smenu:Open()
    end

    local gap = x / 2

    -- Draw replays
    function scoreboard.bots:Paint(w, h)
        surface.SetDrawColor(ACCENT)
        surface.DrawRect(0, 0, (w / 2) - gap, h)
        surface.DrawRect((w / 2) + gap, 0, (w / 2), h)

        for k, v in pairs(self.list) do
            local x = (k - 1) * (w / 2) + (gap * (k - 1))
            local W = w / 2

            if Iv(v) then
                local botName = v:Nick()

                local replayCreatorName = v:GetNWString("BotName", "No Time Recorded")
                local botStyle = v:Nick()
                local botRecord = v:GetNWFloat("Record", 0)

                local botDisplayName
                if replayCreatorName ~= "No Time Recorded" then
                    botDisplayName = botStyle .. " by " .. replayCreatorName
                else
                    botDisplayName = botStyle
                end

                if botRecord == 0 then
                    botRecord = "No Record"
                else
                    botRecord = ConvertTimeWR(botRecord)
                end

                DrawText(botDisplayName, "ui.mainmenu.button", x + 10, h / 2, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                DrawText(botRecord, "ui.mainmenu.button", x + W - 50, h / 2, TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end
        end
    end

    function scoreboard.bots:Think() 
        if self:IsHovered() then 
            self:SetCursor("hand")
        end
    end

    function scoreboard.bots:OnMousePressed()
        local cx, cy = self:CursorPos()
        local w, h = self:GetSize()
        for k, v in pairs(self.list) do 
            local x = (k) * (w / 2) + (gap * (k - 1))
            local x1 = (k - 1) * (w / 2) + (gap * (k - 1))
            local clicked = (x > cx and cx > x1)
            if clicked then 
                createDermaMenu(v)
            end
        end
    end

    for k, v in pairs(player.GetBots()) do
        table.insert(scoreboard.bots.list, v)
    end

    local py = (height * 2) + x + x + x
    local ph = HEIGHT - py - (height / 1.5)

    scoreboard.players = scoreboard:Add("DPanel")
    scoreboard.players:SetPos(x, py)
    scoreboard.players:SetSize(width, ph)

    local line = x - 2
    function scoreboard.players:Paint(w, h)
        surface.SetDrawColor(PRIMARY)
        surface.DrawRect(0, 0, w, h)
        draw.RoundedBox(100, (w / 2) - (line / 2), x, line, h - (x * 2), TRI)
    end

    local disabled = false
    function DisableMoving()
        disabled = false 
    end

    -- Player info
    function CreatePlayerInfo(pan, ply)
        local w = pan:GetWide()
        if ply:IsBot() then return end
        local p = pan:Add("DPanel")
        p:SetPos(0, #pan.list * 34)
        p:SetSize(w, 34)

        local tw = w - (x * 2)
        surface.SetFont("ui.mainmenu.button")
        
        local nm = ply:Nick()
        if string.len(nm) > 16 then
            nm = nm:Left(16) .. "..."
        end
        local nx, nh = surface.GetTextSize(nm)

        function p:Paint(pw, phh)
            if not Iv(ply) then 
                return ScoreboardRefresh()
            end 
            if p:IsHovered() or p:IsChildHovered() then 
                surface.SetDrawColor(SECONDARY)
                surface.DrawRect(0, 0, pw, phh)
                self:SetCursor("hand")
            end

            ph = 34 

            local pRank = ""
            DrawText("#" .. ply:GetNWInt("Placement", 0) .. " | ", "ui.mainmenu.button", x, ph / 2, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            local lw, lh = surface.GetTextSize("#" .. ply:GetNWInt("WRCount", 0) .. " | ")
			local adminList = BHOP.Server.AdminList
			local font = "ui.mainmenu.button"
			local placementText = "#" .. ply:GetNWInt("Placement", 0) .. " | "
			local placementW, _ = surface.GetTextSize(placementText)

			DrawText(placementText, font, x, ph / 2, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

			if adminList[ply:SteamID()] then
				DrawText(BHOP.OwnerRank or "Owner", font, x + placementW, ph / 2, Color(255, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			else
				local rankID = ply:GetNWInt("Rank", -1)
				local rankInfo = TIMER.Ranks[rankID]
				if rankInfo then
					DrawText(rankInfo[1], font, x + placementW, ph / 2, rankInfo[2], TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				else
					DrawText("Unknown Rank", font, x + placementW, ph / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				end
			end

			local rainbowColors = {
				Color(255, 0, 0), Color(255, 165, 0),
				Color(255, 255, 0), Color(0, 255, 0),
				Color(0, 0, 255), Color(75, 0, 130),
				Color(148, 0, 211)
			}

			local adminList = BHOP.Server.AdminList

			local function DrawRainbowWithTag(name, posX, posY, colors, font)
				surface.SetFont(font)

				-- Unicode tag support
				local tag = BHOP.UniTag
				local tagStart, tagEnd = string.find(name, tag, 1, true)
				local offset = 0
				local colorIndex = 1

				local beforeTag = tagStart and string.sub(name, 1, tagStart - 1) or name
				for i = 1, #beforeTag do
					local char = beforeTag:sub(i, i)
					local charWidth = surface.GetTextSize(char)
					surface.SetTextColor(colors[colorIndex]:Unpack())
					surface.SetTextPos(posX + offset, posY)
					surface.DrawText(char)
					offset = offset + charWidth
					colorIndex = (colorIndex % #colors) + 1
				end

				if tagStart then
					local tagWidth = surface.GetTextSize(tag)
					surface.SetTextColor(255, 255, 255)
					surface.SetTextPos(posX + offset, posY)
					surface.DrawText(tag)
					offset = offset + tagWidth

					local afterTag = string.sub(name, tagEnd + 1)
					for i = 1, #afterTag do
						local char = afterTag:sub(i, i)
						local charWidth = surface.GetTextSize(char)
						surface.SetTextColor(colors[colorIndex]:Unpack())
						surface.SetTextPos(posX + offset, posY)
						surface.DrawText(char)
						offset = offset + charWidth
						colorIndex = (colorIndex % #colors) + 1
					end
				end
			end

			if adminList[ply:SteamID()] then
				local name = ply:Nick()
				DrawRainbowWithTag(name, x + (w * 0.25), ph / 3.3, rainbowColors, font)
			else
				DrawText(ply:Nick(), font, x + (w * 0.25), ph / 2, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end

            local currentstyle = ply:GetNWInt("style", TIMER:GetStyleID("Normal"))
            local styles = TIMER:StyleName(currentstyle)
            
            if styles == "Normal" then styles = "N" end
            if styles == "Bonus" then styles = "B" end
            if styles == "Segment" then styles = "S" end                     
            if styles == "Auto-Strafe" then styles = "AS" end
            if styles == "Low Gravity" then styles = "LG" end
            if styles == "Easy Scroll" then styles = "E" end
            if styles == "Half-Sideways" then styles = "HSW" end                     
            if styles == "Stamina" then styles = "STAM" end  
            if styles == "Legit" then styles = "L" end
            if styles == "Moon Man" then styles = "MM" end
            if styles == "High Gravity" then styles = "HG" end

            DrawText(styles, "ui.mainmenu.button", x + (w * 0.6), ph / 2, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            DrawText(ConvertTimeWR(ply:GetNWFloat("Record", 0)), "ui.mainmenu.button", x + (w * 0.75), ph / 2, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            DrawText(ply:Ping(), "ui.mainmenu.button", x + (w * 0.92), ph / 2, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            local textX = nx + (w * 0.23) + x + x + 17
            local textY = ph / 2
            local starSize = 0.04
            local starX = textX + 20
            local starY = textY

            drawStar(starSize, starX, starY, Color(255, 215, 0, 255), 50, 200, 1.5)
            DrawText(ply:GetNWInt("WRCount", 0), "hud.subinfo", nx + (w * 0.28) + x + x + 24, ph / 2, Color(255, 215, 0, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            if self.hasextended then 
            local eX, eY = 150 - 34 + x, ph + x + x + 4
            local cos, sin, rad = math.cos, math.sin, math.rad
            local function CreateCirclePoints(radius)
                local circle = {}
                local cos, sin, rad = math.cos, math.sin, math.rad

                for i = 0, 360, 1 do
                    local t = rad(i)
                    table.insert(circle, {
                        x = radius + cos(t) * radius,
                        y = radius + sin(t) * radius
                    })
                end
                return circle
            end

            -- Avatar
            local function BuildCircularAvatar(base, x, y, radius, steamid64)
                if base.avatarPanel then return end

                local pan = base:Add('DPanel')
                pan:SetPos(x, y)
                pan:SetSize(radius * 2, radius * 2)
                pan.mask = radius
                pan.circle = CreateCirclePoints(radius)

                pan.avatar = pan:Add('AvatarImage')
                pan.avatar:SetPaintedManually(true)
                pan.avatar:SetSize(radius * 2, radius * 2)
                pan.avatar:SetSteamID(steamid64, 184)

                function pan:Paint(w, h)
                    render.ClearStencil()
                    render.SetStencilEnable(true)
                    render.SetStencilWriteMask(1)
                    render.SetStencilTestMask(1)
                    render.SetStencilFailOperation(STENCILOPERATION_REPLACE)
                    render.SetStencilPassOperation(STENCILOPERATION_ZERO)
                    render.SetStencilZFailOperation(STENCILOPERATION_ZERO)
                    render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_NEVER)
                    render.SetStencilReferenceValue(1)

                    draw.NoTexture()
                    surface.SetDrawColor(255, 255, 255, 255)
                    surface.DrawPoly(self.circle)

                    render.SetStencilFailOperation(STENCILOPERATION_ZERO)
                    render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
                    render.SetStencilZFailOperation(STENCILOPERATION_ZERO)
                    render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
                    render.SetStencilReferenceValue(1)

                    self.avatar:SetPaintedManually(false)
                    self.avatar:PaintManual()
                    self.avatar:SetPaintedManually(true)

                    render.SetStencilEnable(false)
                    render.ClearStencil()
                end

                base.avatarPanel = pan
            end

                if self.hasextended then 
                    local eX, eY = 150 - 34 + x, ph + x + x + 4

                    if self.hasextended and not self.avatarPanel then
                        BuildCircularAvatar(self, x, ph + x, 50, util.SteamIDTo64(ply:SteamID()))
                    end
                end
                
                -- Timer updates
                local status = "In start zone"
                local curr = styles == "B" and ply.bonustime or ply.time
                local finished = styles == "B" and ply.bonusfinished or ply.finished

                if ply:GetObserverMode() ~= OBS_MODE_NONE then
                    local tgt = ply:GetObserverTarget()

                    if tgt and Iv(tgt) and (tgt:IsPlayer() or tgt:IsBot()) then
                        local nm = tgt:IsBot() and (tgt:GetNWString("BotName", "Loading...") .. " Replay") or tgt:Nick()

                        if string.len(nm) > 26 then
                            nm = nm:Left(26) .. "..."
                        end

                        status = "Spectating: " .. nm
                    else
                        status = "Spectating"
                    end
                elseif ply:GetNWInt('inPractice', false) then
                    status = "Practicing"
                elseif finished and finished > 0 then
                    status = "Finished: " .. SecondsToClock(TIMER:Convert(curr, finished))
                elseif curr and curr > 0 then
                    local runningTime = TIMER:Convert(curr, engine.TickCount())
                    status = "Running: " .. SecondsToClock(runningTime)
                end

                local textColor = lp():IsAdmin() and Color(0, 255, 0) or Color(255, 0, 0)
                local textToShow = lp():IsAdmin() and "Admin" or "Player"
            
                if lp():IsAdmin() then
                    DrawText("Playing", "ui.mainmenu.button", eX, eY, Color(0, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
            
                DrawText(status, "ui.mainmenu.button", tw + x, eY, TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end
        end

        local eX, eY = 150 - 34 + x, ph + x + x + 4

        -- Buttons
        local function Sleek(parent, x, y, width, height, col, col22, title, fu)
            center = center == nil and true or false
            local f = parent:Add('DButton')
            f:SetPos(x, y)
            f:SetSize(width, height)
            f:SetText('')
            f.title = title
        
            function f:Paint(width, height)
                local b = col
                local col = Color(b.r + 5, b.g + 5, b.b + 5, 255)
                local col2 = Color(b.r + 10, b.g + 10, b.b + 10, 255)
                surface.SetDrawColor(self:IsHovered() and col or col2)
                surface.DrawRect(0, 0, width, height)
                DrawText(self.title, 'ui.mainmenu.button', width / 2, height / 2, col22, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            
            f.OnMousePressed = fu
            return f
        end

        local img = p:Add("DImage")
        img:SetPos(nx + (w * 0.25) + x + x, 12)
        img:SetSize(12, 12)

        function p:Think()
            if self.extended and not self.buttons then 
                local baseY = 150 - 30 - (2 * x)
                local baseX = eX
                local offsetX = 150 + 4
                local offsetY = 34

                self.stat = Sleek(p, baseX, baseY, 150, 30, PRIMARY, color_white, "View Statistics", function() 
                    UTIL:AddMessage("Server", "That feature has not been added yet.")
                end)

                self.prof = Sleek(p, baseX + offsetX, baseY, 180, 30, PRIMARY, color_white, "Teleport To", function()
                    lp():ConCommand("say !goto " .. ply:Name())
                end)

                self.spec = Sleek(p, baseX, baseY - offsetY, 150, 30, PRIMARY, color_white, "Spectate", function() 
                    lp():ConCommand("say !spectate " .. ply:Name())
                end)

                self.profile = Sleek(p, baseX + offsetX, baseY - offsetY, 180, 30, PRIMARY, color_white, "View Profile", function()
                    gui.OpenURL("http://www.steamcommunity.com/profiles/" .. ply:SteamID64())
                end)

                self.buttons = true 
            end
        end

        function p:OnMousePressed(keyCode)
            if keyCode == 108 then 
                createDermaMenu(ply)
                return
            end 
            self.hasextended = true 
            if disabled then return end 
            if not self.extended then 
                disabled = true 
                self:SizeTo(-1, 150, 0.5, 0, -1, DisableMoving)

                local foundself = false 
                for k, v in pairs(pan.list) do 
                    local x, y = v:GetPos()
                    if v ~= self then 
                        if foundself then  
                            v:MoveTo(-1, y + 150 - 34, 0.5, 0)
                        end
                    else 
                        foundself = true 
                    end
                end 

                self.extended = true 
            else 
                disabled = true
                self:SizeTo(-1, 34, 0.5, 0, -1, DisableMoving)

                local foundself = false 
                for k, v in pairs(pan.list) do 
                    local x, y = v:GetPos()
                    if v ~= self then 
                        if foundself then  
                            v:MoveTo(-1, y - 150 + 34, 0.5, 0)
                        end
                    else 
                        foundself = true 
                    end
                end 

                self.extended = false
            end
        end

        return p 
    end

    scoreboard.players.normal = scoreboard.players:Add("DScrollPanel")
    scoreboard.players.normal:SetPos(x, x)
    scoreboard.players.normal:SetSize((width / 2) - (line / 2) - (x * 2), ph - (x * 2))
    scoreboard.players.normal.list = {}

    function scoreboard.players.normal:Paint(w, h) end

    scoreboard.players.bonus = scoreboard.players:Add("DScrollPanel")
    scoreboard.players.bonus:SetPos(x + (width / 2) + (line / 2), x)
    scoreboard.players.bonus:SetSize((width / 2) - (line / 2) - (x * 2), ph - (x * 2))
    scoreboard.players.bonus.list = {}
    function scoreboard.players.bonus:Paint(w, h) end

    ScoreboardRefresh()

    scoreboard.players.normal.VBar:SetWide(0)
    scoreboard.players.bonus.VBar:SetWide(0)
end 

local insert = table.insert

-- Refresh
function ScoreboardRefresh()
    if not scoreboard then return end 

    for k, v in pairs(scoreboard.players.bonus.list) do v:Remove() end 
    for k, v in pairs(scoreboard.players.normal.list) do v:Remove() end 
    scoreboard.players.bonus.list, scoreboard.players.normal.list = {}, {}

    scoreboard.spectators = {}

    for i, ply in ipairs(player.GetAll()) do
        if ply:Team() == TEAM_SPECTATOR then 
            table.insert(scoreboard.spectators, ply)
        else
            local currentstyle = ply:GetNWInt("style", TIMER:GetStyleID("Normal"))

            if currentstyle == TIMER:GetStyleID("Normal") then
                local p = CreatePlayerInfo(scoreboard.players.normal, ply)
                table.insert(scoreboard.players.normal.list, p)

            elseif currentstyle == TIMER:GetStyleID("Bonus") then
                local p = CreatePlayerInfo(scoreboard.players.bonus, ply)
                table.insert(scoreboard.players.bonus.list, p)
            else
                local p = CreatePlayerInfo(scoreboard.players.normal, ply)
                table.insert(scoreboard.players.normal.list, p)
            end
        end
    end
end

function GM:HUDDrawScoreBoard() end

-- Clickers
hook_Add("CreateMove", "ClickableScoreBoard", function(cmd)
    if not (Iv(scoreboard) and scoreboard:IsVisible()) then return end
    if not (cmd:KeyDown(IN_ATTACK) or cmd:KeyDown(IN_ATTACK2)) then return end
    if not scoreboard.IsClickable then 
        scoreboard.IsClickable = true
        gui.EnableScreenClicker(true)
    end

    cmd:RemoveKey(IN_ATTACK)
    cmd:RemoveKey(IN_ATTACK2)
end)

-- Kawaii Scoreboard
local SCORE_HEIGHT = ScrH() - 118
local SCORE_WIDTH = (ScrW() / 2) + 150

local SCORE_TITLE = BHOP.ServerName
local SCORE_PLAYERS = "%s/%s Players connected"
local SCORE_CREDITS = "Gamemode by FiBzY"
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

local function CreateScoreboardKawaii()
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
			SCORE_ACCENT = DynamicColors.PanelColor -- Color(80, 30, 40, 170)
			outlines = Color(32, 32, 32)

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
			draw.SimpleText("Rank", "hud.subinfo", 12, 10, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText("Player", "hud.subinfo", distance * 1.5, 10, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText("Style", "hud.subinfo", distance * 4.5, 10, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText("Status", "hud.subinfo", distance * 5.7, 10, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText("Personal Best", "hud.subinfo", distance * 8.5, 10, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText("Ping", "hud.subinfo", width - 12, 10, text_colour, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
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

			draw.SimpleText(isBot and "WR Replay" or rankInfo[1], "hud.subtitle", 12, 20, isBot and text_colour or rankInfo[2], TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

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

			local adminColors = {
				["Owner"] = function() return HSVToColor(RealTime() * 40 % 360, 1, 1) end, -- rainbow
				["Manager"] = function() return Color(255, 100, 100) end,
				["Admin"] = function() return Color(100, 200, 255) end
			}

			local nameColor = text_colour

			if BHOP.Server.AdminList[pl:SteamID()] then
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
				status = "View to see Record"
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
				local place = pl:GetNWInt("WRCount", 0)
                local WRCount = pl:GetNWInt("Placement", 0)

				if (place == 0) then
					draw.SimpleText(pb, "hud.subtitle", distance * 8.5, 20, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				else

					local w, h = surface.GetTextSize(place)

					draw.SimpleText(pb, "hud.subtitle", distance * 8.5 + 6 + w, 20, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    drawStar(0.04, distance * 7.9, 20, Color(255, 215, 0, 255), 50, 200, 1.5)
					draw.SimpleText(place, "hud.subinfo", distance * 8, 20, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
					draw.SimpleText("#" .. WRCount, "hud.subinfo", distance * 8.5, 20, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
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
							draw.SimpleText("Points: " .. (LocalPlayer().Sum or 0), "hud.subtitle", 10, 122, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
							draw.SimpleText("Place: #" .. pl:GetNWInt("Placement", 0) , "hud.subtitle", 10, 140, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
							draw.SimpleText("WRs : " .. pl:GetNWInt("WRCount", 0), "hud.subtitle", 10, 158, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
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

					scoreboard_playerrow.Combo:AddChoice("Disactive", 1)
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
					return a:GetNWInt("WRCount", 0) > b:GetNWInt("WRCount", 0)
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

-- Flow
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

local rank_str = {"Donator", "Mod", "Zoner", "Dev", "Founder"}
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

local function _AA(szAction, szSID)
	if not IsValid( LocalPlayer() ) then return end
	if Admin:IsAvailable() or LocalPlayer():GetNWInt( "AccessIcon", 0 ) > 2 then
		RunConsoleCommand( "say", "!admin " .. szAction .. " " .. szSID )
	else
		--TIMER:Print("Admin", "Please open the admin panel before trying to access scoreboard functionality.")
	end
end

local function PutPlayerItem(self, pList, ply, mw)
	local btn = vgui.Create( "DButton" )
	btn.player = ply
	btn.ctime = CurTime()
	btn:SetTall(32)
	btn:SetText("")
	
	if not IsValid(ply) then return end

	function btn:Paint(w, h)
		surface.SetDrawColor(0, 0, 0, 0)
		surface.DrawRect(0, 0, w, h)

		if ply:IsBot() then
			surface.SetDrawColor(DynamicColors.PanelColor)
		else
			surface.SetDrawColor(Color(150, 150, 150))
		end

		surface.DrawOutlinedRect(0, 0, w, h)

		if IsValid(ply) and ply:IsPlayer() then
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

			draw.DrawText(PlayerName, "ScoreboardPlayer", s + 11, 9, Color(0, 0, 0), TEXT_ALIGN_LEFT)

			local ColorSpec = ply:GetNWInt("Spectating", 0) == 1 and Color(180, 180, 180) or Color(255, 255, 255)

			draw.DrawText(PlayerName, "ScoreboardPlayer", s + 10, 8, ColorSpec, TEXT_ALIGN_LEFT)
			
			surface.SetFont("ScoreboardPlayer")
			local wt, ht = surface.GetTextSize("TimerText")
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

			-- Display player's ping
			draw.DrawText(tostring(ply:Ping()), "ScoreboardPlayer", w - 9, 9, Color(0, 0, 0), TEXT_ALIGN_RIGHT)
			draw.DrawText(tostring(ply:Ping()), "ScoreboardPlayer", w - 10, 8, Color(255, 255, 255), TEXT_ALIGN_RIGHT)
		end
	end

	function btn:DoClick()
		GAMEMODE:DoScoreboardActionPopup(ply)
	end
	
	pList:AddItem(btn)
end

local function ListPlayers(self, pList, mw)
	local players = player.GetAll()
	table.sort( players, function(a, b)
		if not a or not b then return false end
		local ra, rb = a:GetNWInt( "Rank", 1 ), b:GetNWInt("Rank", 1)
		if ra == rb then
			return a:GetNWInt("Placement", 0) > b:GetNWInt("Placement", 0)
		else
			return ra > rb
		end
	end )

	for k,v in pairs(pList:GetCanvas():GetChildren()) do
		if IsValid( v ) then
			v:Remove()
		end
	end

	for k,ply in pairs(players) do
		PutPlayerItem(self, pList, ply, mw)
	end
		
	pList:GetCanvas():InvalidateLayout()
end

local function CreateTeamList(parent, mw)
	local pList
	
	local pnl = vgui.Create("DPanel", parent)
	pnl:DockPadding(8, 8, 8, 8)
	
	function pnl:Paint(w, h) 
		surface.SetDrawColor(Color(42, 42, 42))
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
	rank:SetTextColor(Color(150, 150, 150))
	rank:SetWidth(50)
	rank:Dock(LEFT)
	
	local player = vgui.Create("DLabel", headp)
	player:SetText("User")
	player:SetFont("ScoreboardPlayer")
	player:SetTextColor(Color(150, 150, 150))
	player:SetWidth(70)
	player:DockMargin(mw + 14, 0, 0, 0)
	player:Dock(LEFT)
	
	local ping = vgui.Create("DLabel", headp)
	ping:SetText("Ping")
	ping:SetFont("ScoreboardPlayer")
	ping:SetTextColor(Color(150, 150, 150))
	ping:SetWidth(50)
	ping:DockMargin(0, 0, 0, 0)
	ping:Dock(RIGHT)

	local timer = vgui.Create("DLabel", headp)
	timer:SetText("Record")
	timer:SetFont("ScoreboardPlayer")
	timer:SetTextColor(Color(150, 150, 150))
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

function CreateScoreboardFlow(close)
	if close then
		if IsValid(menu) then
			menu:SetVisible(false)
			menu.IsClickable = false
			gui.EnableScreenClicker(false)
		end
		return
	else
		menu = vgui.Create("DFrame")
		menu:SetSize(ScrW() * 0.5 - 20, ScrH() * 0.8 - 20)
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
			surface.SetDrawColor(Color(32, 32, 32))
			surface.DrawRect(0, 0, menu:GetWide(), menu:GetTall())
		end

		menu.Credits = vgui.Create("DPanel", menu)
		menu.Credits:Dock(TOP)
		menu.Credits:DockPadding(8, 6, 8, 0)
		
		function menu.Credits:Paint()
		end

		local name = Label( (BHOP.ServerName):format("bhop"), menu.Credits )
		name:Dock(LEFT)
		name:SetFont("FlowRadial")
		name:SetTextColor(Color(255, 255, 255))
		
		function name:PerformLayout()
			surface.SetFont(self:GetFont())
			local w, h = surface.GetTextSize(self:GetText())
			self:SetSize(w, h)
		end

		local cred = vgui.Create( "DButton", menu.Credits )
		cred:Dock(RIGHT)
		cred:SetFont("FlowText")
		cred:SetText("Version " .. BHOP.Version.GM .. "\nGamemode by FiBzY")
		cred.PerformLayout = name.PerformLayout
		cred:SetTextColor(Color(255, 255, 255))
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
		players:SetTextColor(Color(255, 255, 255))
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
		timeleft:SetTextColor(Color(255, 255, 255))

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
		map:SetTextColor(Color(255, 255, 255))
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

hook.Add("CreateMove", "ClickableScoreBoard", function(cmd)
    local scoreboardType = GetConVar("bhop_scoreboard"):GetString():lower()

    local board
    if scoreboardType == "flow" then
        board = menu
    else
        board = scoreboard
    end

    if not (IsValid(board) and board:IsVisible()) then return end
    if not (cmd:KeyDown(IN_ATTACK) or cmd:KeyDown(IN_ATTACK2)) then return end

    if not board.IsClickable then 
        board.IsClickable = true
        gui.EnableScreenClicker(true)
    end

    cmd:RemoveKey(IN_ATTACK)
    cmd:RemoveKey(IN_ATTACK2)
end)

function GM:DoScoreboardActionPopup(ply)
	if not IsValid(ply) then return end
	local actions, open = vgui.Create("DarkMenu"), true

	if ply != LocalPlayer() then	
		if not ply:IsBot() then
			local nAccess = ply:GetNWInt("AccessIcon", 0)
			if nAccess > 0 then
				local admin = actions:AddOption("User is a " .. rank_str[nAccess])
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
					UTIL:AddMessage("Server", ply:Name() .. " has been " .. (ply.ChatMuted and "chat muted" or "chat unmuted"))
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
		surface.SetDrawColor(Color(32, 32, 32)) 
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

local scoreboardpicker = CreateClientConVar("bhop_scoreboard", "default", true, false, "Choose scoreboard style: default, kawaii or flow")

-- Load both kawaii and default, flow
function GM:ScoreboardShow()
    local scoreboardType = scoreboardpicker:GetString():lower()
    
    if scoreboardType == "default" then
        CreateScoreboard()
    elseif scoreboardType == "kawaii" then
        CreateScoreboardKawaii()
    elseif scoreboardType == "flow" then
        CreateScoreboardFlow(false)
    end
end

function GM:ScoreboardHide()
    local scoreboardType = scoreboardpicker:GetString():lower()
    
    if scoreboardType == "default" then
        CreateScoreboard(true)
    elseif scoreboardType == "kawaii" then
        CreateScoreboardKawaii(true)
    elseif scoreboardType == "flow" then
        CreateScoreboardFlow(true)
    end
end