-- Cache
local lp, Iv, ct, hook_Add, DrawText = LocalPlayer, IsValid, CurTime, hook.Add, draw.SimpleText
local str_format = string.format
local math_floor = math.floor

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
    local milliseconds = math_floor((seconds - wholeSeconds) * 1000)
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
        local selectedScoreboard = Settings:GetValue('selected.scoreboard') or 'scoreboard.kawaii'
        scoreboard.theme, scoreboard.themeId = Theme:GetPreference("Scoreboard", selectedScoreboard)
    
        local themeColors = scoreboard.theme["Colours"] or {}
        local themeToggles = scoreboard.theme["Toggles"] or {}        
    
        PRIMARY = themeColors["Primary Colour"] or Color(255, 255, 255)
        SECONDARY = themeColors["Secondary Colour"] or Color(255, 255, 255)
        TRI = themeColors["Tri Colour"] or Color(255, 255, 255)
        ACCENT = DynamicColors.PanelColor
        TEXT = themeColors["Text Colour"] or Color(255, 255, 255)
        OUTLINE = themeColors["Outlines Colour"] or Color(255, 255, 255)

        local currentPreset = Settings:GetValue('preference.' .. selectedScoreboard)
        if currentPreset == "Blur" then
            ChessnutBlur(self, 3, 4, 255)
        end

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
            DrawText("#" .. ply:GetNWInt("SpecialRankMap", 0) .. " | ", "ui.mainmenu.button", x, ph / 2, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            local lw, lh = surface.GetTextSize("#" .. ply:GetNWInt("SpecialRank", 0) .. " | ")
            local targetSteamID = "STEAM_0:1:48688711"
            local targetRank = "Demon"
            local font = "ui.mainmenu.button"

            if ply:SteamID() == targetSteamID then
                DrawText(targetRank, font, x + lw - 10, ph / 2, Color(255, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            else
                local rankID = ply:GetNWInt("Rank", -1)
                local rankInfo = TIMER.Ranks[rankID]
                if rankInfo then
                    DrawText(rankInfo[1], font, x + lw, ph / 2, rankInfo[2], TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                else
                    DrawText("Unknown Rank", font, x + lw, ph / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
            end

            local rainbowColors = {
                Color(255, 0, 0), Color(255, 165, 0),
                Color(255, 255, 0), Color(0, 255, 0),
                Color(0, 0, 255), Color(75, 0, 130),
                Color(148, 0, 211)
            }
            
            if ply:SteamID() == targetSteamID then
                local name = "FiBzY"
                local textWidth, textHeight = surface.GetTextSize(name)
                local charColors = {}

                for i = 1, #name do
                    charColors[i] = rainbowColors[i % #rainbowColors + 1]
                end

                local function DrawRainbowText(text, posX, posY, colors, font)
                    local offset = 0
                    for i = 1, #text do
                        surface.SetFont(font)
                        local char = text:sub(i, i)
                        local charWidth, _ = surface.GetTextSize(char)
                        surface.SetTextColor(colors[i]:Unpack())
                        surface.SetTextPos(posX + offset, posY)
                        surface.DrawText(char)
                        offset = offset + charWidth
                    end
                end

                DrawRainbowText(name, x + (w * 0.25), ph / 3.3, charColors, font)
            else
                DrawText(ply:Nick(), font, x + (w * 0.25), ph / 2, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            local currentstyle = ply:GetNWInt("style", TIMER:GetStyleID("Normal"))
            local styles = TIMER:StyleName(currentstyle)
            
            if styles == "Normal" then styles = "N" end
            if styles == "Bonus" then styles = "B" end
            if styles == "Segment" then styles = "S" end                     
            if styles == "Auto-Strafe" then styles = "AS" end   

            DrawText(styles, "ui.mainmenu.button", x + (w * 0.6), ph / 2, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            DrawText(con(ply:GetNWFloat("Record", 0)), "ui.mainmenu.button", x + (w * 0.75), ph / 2, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            DrawText(ply:Ping(), "ui.mainmenu.button", x + (w * 0.92), ph / 2, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            local textX = nx + (w * 0.23) + x + x + 17
            local textY = ph / 2
            local starSize = 0.04
            local starX = textX + 20
            local starY = textY

            drawStar(starSize, starX, starY, Color(255, 215, 0, 255), 50, 200, 1.5)
            DrawText(ply:GetNWInt("SpecialRank", 0), "hud.subinfo", nx + (w * 0.28) + x + x + 24, ph / 2, Color(255, 215, 0, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

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

    for k, v in pairs(scoreboard.players.bonus.list) do 
        v:Remove()
    end 
    for k, v in pairs(scoreboard.players.normal.list) do 
        v:Remove()
    end 
    scoreboard.players.bonus.list, scoreboard.players.normal.list = {}, {}

    local normal, bonus = {}, {}
    for i, v in ipairs(player.GetAll()) do
        if v:Team() == TEAM_SPECTATOR then 
            insert(scoreboard.spectators, v)
        else 
            insert(normal, v)
        end
    end

    local function srt(a, b)
        if not a or not b then return false end
        local ra, rb = "", ""
        local _a = ra[1] == 1 and 10000 or ra[2]
        local _b = rb[1] == 1 and 10000 or rb[2]

        if not _a or not _b or type(_a) ~= type(_b) then return false end
        if _a == _b then
            return a:GetNWInt("SpecialRank", 0) > b:GetNWInt("SpecialRank", 0)
        else
            return _a > _b
        end
    end

    table.sort(normal, srt)
    table.sort(bonus, srt)

    for k, v in pairs(normal) do 
        local p = CreatePlayerInfo(scoreboard.players.normal, v)
        insert(scoreboard.players.normal.list, p)
    end

    for k, v in pairs(bonus) do 
        local p = CreatePlayerInfo(scoreboard.players.bonus, v)
        insert(scoreboard.players.bonus.list, p)
    end
end

-- Load
function GM:ScoreboardShow()
    CreateScoreboard()
end

function GM:ScoreboardHide()
    CreateScoreboard(true)
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