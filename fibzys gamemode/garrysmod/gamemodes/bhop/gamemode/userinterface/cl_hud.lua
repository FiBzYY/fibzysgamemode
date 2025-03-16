--[[

 ____  _  _   __  ____    _  _  _  _  ____  ____ 
(  _ \/ )( \ /  \(  _ \  / )( \/ )( \(    \/ ___)
 ) _ () __ ((  O )) __/  ) __ () \/ ( ) D (\___ \
(____/\_)(_/ \__/(__)    \_)(_/\____/(____/(____/ !

]]--

local selected_hud = CreateClientConVar("bhop_hud_hide", 0, true, false)
local roundedBoxEnabled = CreateConVar("bhop_roundedbox", "1", {FCVAR_ARCHIVE}, "Enable rounded box drawing")
local simpleBoxEnabled = CreateConVar("bhop_simplebox", "0", {FCVAR_ARCHIVE}, "Enable simple hud box drawing")
local sidetimer = CreateClientConVar("bhop_sidetimer", 0, true, false, "Display SideTimer Stats")
local disablespec = CreateClientConVar("bhop_disablespec", 0, true, false, "Disable Spectator Hud")
local jhudold = CreateClientConVar("bhop_jhudold", 0, true, false, "Display the old JHUD from 2020")

CreateClientConVar("bhop_default_crosshair", "1", true, false, "Enable default crosshair")

-- Shortcuts
local lp, Iv, ct, ceil, fl, fo, mc = LocalPlayer, IsValid, CurTime, math.ceil, math.floor, string.format, math.Clamp
local insert, round, hook_Add = table.insert, math.Round, hook.Add
local DrawText, DrawBoxRound, DrawBoxEx = draw.SimpleText, draw.RoundedBox, draw.RoundedBoxEx
local DrawRect = surface.DrawRect
local SetDrawColor = surface.SetDrawColor
local screenWidth, screenHeight, TickInterval = ScrW(), ScrH(), engine.TickInterval()
local velocityAlpha, velocityFadeTime, lastVelocityAboveThreshold, fadeThreshold = 255, 0.2, 0, 1
local colour_white = Color(255, 255, 255)
local startTick, endTick, fractionalTicks, timerActive = 0, 0, 0, false

local function GetClientVelocity(ply)
    local velocity = ply:GetInternalVariable("m_vecVelocity")
    if not velocity then return 0 end
    
    local speed2D = math.sqrt(velocity.x^2 + velocity.y^2)
    return speed2D
end

local function GetSpeed(vel, twoD)
    if twoD then
        vel = Vector(vel.x, vel.y, 0)
    end

    return vel:Length()
end

local function ConvertTimeMS(ns)
    if not ns or type(ns) ~= "number" or ns < 0 then
        return "000"
    end

    local milliseconds = ns % 1000
    local lastDigit = tostring(milliseconds % 10)

    return lastDigit
end

net.Receive("Timer_Update", function()
    local ply = LocalPlayer()
    startTick = net.ReadInt(32)
    endTick = net.ReadInt(32)
    fractionalTicks = net.ReadInt(32)

    if startTick > 0 and endTick == 0 then
        TIMER:ResetToCheckpoint(ply, startTick)
    end

    timerActive = startTick > 0 and (endTick == 0 or endTick > startTick)
end)

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

-- Non Ticks convert
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

-- CS:S Style
local function cCTime(ns)
	ns = ns * engine.TickInterval() / .01
    if not ns then ns = 0 end
    if ns > 3600 then
        return fo("%i:%.02i:%.02i.%.03i", fl(ns / 3600), fl(ns / 60 % 60), fl(ns % 60), (ns - math.floor(ns)) * 1000)
    elseif ns > 60 then
        return fo("%.01i:%.02i.%.03i", fl(ns / 60 % 60), fl(ns % 60), (ns - math.floor(ns)) * 1000)
    else
        return fo("%.01i.%.03i", fl(ns % 60), (ns - math.floor(ns)) * 1000)
    end
end

-- CS:S Style v2
local function cTime(ticks, fractionalTicks)
    if not ticks or type(ticks) ~= "number" or ticks < 0 then
        return "00:00.0"
    end

    local ns = (ticks + (fractionalTicks or 0) / 10000) * TickInterval

    local wholeSeconds = fl(ns)
    local milliseconds = fl((ns - wholeSeconds) * 1000)

    local hours = fl(wholeSeconds / 3600)
    local minutes = fl((wholeSeconds / 60) % 60)
    local seconds = wholeSeconds % 60

    if hours > 0 then
        return fo("%d:%.2d:%.2d.%.1d", hours, minutes, seconds, fl(milliseconds / 100))
    elseif minutes > 0 then
        return fo("%.1d:%.2d.%.1d", minutes, seconds, fl(milliseconds / 100))
    else
        return fo("%.1d.%.1d", seconds, fl(milliseconds / 100))
    end
end

local function cTimeWR(ns)
	if ns > 3600 then
		return fo( "%d:%.2d:%.2d.%.1d", fl( ns / 3600 ), fl( ns / 60 % 60 ), fl( ns % 60 ), fl( ns * 10 % 10 ) )
	elseif ns > 60 then 
		return fo( "%.1d:%.2d.%.1d", fl( ns / 60 % 60 ), fl( ns % 60 ), fl( ns * 10 % 10 ) )
	else
		return fo( "%.1d.%.1d", fl( ns % 60 ), fl( ns * 10 % 10 ) )
	end
end

-- Really Good
CreateClientConVar("bhop_jhud_gain_verygood_r", "0", true, false)
CreateClientConVar("bhop_jhud_gain_verygood_g", "255", true, false)
CreateClientConVar("bhop_jhud_gain_verygood_b", "255", true, false)
CreateClientConVar("bhop_jhud_gain_verygood_a", "255", true, false)

-- Good
CreateClientConVar("bhop_jhud_gain_good_r", "39", true, false)
CreateClientConVar("bhop_jhud_gain_good_g", "255", true, false)
CreateClientConVar("bhop_jhud_gain_good_b", "0", true, false)
CreateClientConVar("bhop_jhud_gain_good_a", "255", true, false)

-- Meh
CreateClientConVar("bhop_jhud_gain_meh_r", "39", true, false)
CreateClientConVar("bhop_jhud_gain_meh_g", "255", true, false)
CreateClientConVar("bhop_jhud_gain_meh_b", "0", true, false)
CreateClientConVar("bhop_jhud_gain_meh_a", "255", true, false)

-- Bad
CreateClientConVar("bhop_jhud_gain_bad_r", "255", true, false)
CreateClientConVar("bhop_jhud_gain_bad_g", "128", true, false)
CreateClientConVar("bhop_jhud_gain_bad_b", "0", true, false)
CreateClientConVar("bhop_jhud_gain_bad_a", "255", true, false)

-- Really Bad
CreateClientConVar("bhop_jhud_gain_verybad_r", "255", true, false)
CreateClientConVar("bhop_jhud_gain_verybad_g", "0", true, false)
CreateClientConVar("bhop_jhud_gain_verybad_b", "0", true, false)
CreateClientConVar("bhop_jhud_gain_verybad_a", "255", true, false)

local function GetGainColor(prefix)
    return Color(
        GetConVar(prefix .. "_r"):GetInt(),
        GetConVar(prefix .. "_g"):GetInt(),
        GetConVar(prefix .. "_b"):GetInt(),
        GetConVar(prefix .. "_a"):GetInt()
    )
end

function getColorForGain(gain)
    if gain > 115 then
        return GetGainColor("bhop_jhud_gain_verybad") -- Really Bad
    elseif gain > 110 then
        return GetGainColor("bhop_jhud_gain_verybad") -- Really Bad
    elseif gain > 105 then
        return GetGainColor("bhop_jhud_gain_bad") -- Bad
    elseif gain > 100 then
        return GetGainColor("bhop_jhud_gain_good") -- Good
    elseif gain >= 90 then
        return GetGainColor("bhop_jhud_gain_verygood") -- Really Good
    elseif gain >= 80 then
        return GetGainColor("bhop_jhud_gain_good") -- Good
    elseif gain >= 70 then
        return GetGainColor("bhop_jhud_gain_meh") -- Meh
    elseif gain >= 60 then
        return GetGainColor("bhop_jhud_gain_bad") -- Bad
    else
        return GetGainColor("bhop_jhud_gain_verybad") -- Really Bad
    end
end

local RECORDS = {}
net.Receive("SendAllRecords", function()
    RECORDS = net.ReadTable()
end)

local function GetCurrentPlacement(nCurrent, s)
    local timetbl = RECORDS[s]

    if not timetbl or next(timetbl) == nil then
        print("Warning: RECORDS[s] is empty or nil for style:", s)
        return 1
    end

    local c = #timetbl + 1

    for k, v in ipairs(timetbl) do
        if nCurrent < v then
            c = k
            break
        end
    end

    return c
end

HUD = {
    Ids = {
        "Counter Strike: Source",
        "Flow Network", "Simple",
        "Momentum"
    }
}

local function DarkenColor(color, factor)
    factor = mc(factor, 0, 1)
    local r = mc(color.r * (1 - factor) + 0 * factor, 0, 255)
    local g = mc(color.g * (1 - factor) + 0 * factor, 0, 255)
    local b = mc(color.b * (1 - factor) + 0 * factor, 0, 255)
    return Color(r, g, b, color.a)
end

HUD.Themes = {
    ["hud.css"] = function(pl, data)
        local baseColor = Color(20, 20, 20, 150)
        local textColor = color_white

        local velocity = fl(pl:GetVelocity():Length2D())
        local style = pl:GetNWInt("Style", 1)
        local StyleName = TIMER:StyleName(style) .. (pl:IsBot() and " Replay" or "")
        
        local personalBest = ConvertTimeWR(data.pb or 0)
        local current = data.current < 0 and 0 or data.current
        
        local currentFormatted
        if pl:IsBot() or pl:Team() == TEAM_SPECTATOR then
            currentFormatted = cTimeWR(current)
        else
            currentFormatted = cTime(current)
        end
        
        local jumps = pl.player_jumps or 0
        local activity = current > 0 and 1 or 2
        local isInPractice = pl:GetNWInt("inPractice", false)
        local isInStart = pl.InStartZone and not isInPractice
        local isFinished = pl.finishedTick or pl.bonusfinishedTick

        if isFinished or isInPractice then
            activity = 3 -- Speed Only HUD
        elseif pl:IsBot() then
            activity = 4 -- Replay HUD
        elseif current > 0 then
            activity = 1 -- Active Timer HUD
        elseif isInStart then
            activity = 2 -- Start Zone HUD
        else
            activity = 3 -- unknown state
        end
        
        local width = string.len(StyleName) < 15 and 130 or 200
        width = string.len(StyleName) < 25 and width or 260

        local heights = {124, 64, 44, 84}
        local height = heights[activity]
        local xPos = (screenWidth / 2) - (width / 2)
        local yPos = screenHeight - height - 60 - (lp():Team() == TEAM_SPECTATOR and 50 or 0)
      
        if roundedBoxEnabled:GetBool() then
            DrawBoxRound(16, xPos, yPos, width, height, baseColor)
        else
            DrawBoxRound(0, xPos, yPos, width, height, baseColor)
        end

        if activity == 1 then
            DrawText(StyleName, "HUDTimer", screenWidth / 2, yPos + 20, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            DrawText("Time: " .. currentFormatted, "HUDTimer", screenWidth / 2, yPos + 40, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            DrawText("Jumps: " .. jumps, "HUDTimer", screenWidth / 2, yPos + 60, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            DrawText("Sync: " .. (pl.sync or 0) .. "%", "HUDTimer", screenWidth / 2, yPos + 80, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            DrawText("Speed: " .. velocity, "HUDTimer", screenWidth / 2, yPos + 100, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        elseif activity == 2 then
            DrawText("In Start Zone", "HUDTimer", screenWidth / 2, yPos + 20, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            DrawText("Speed: " .. velocity, "HUDTimer", screenWidth / 2, yPos + 40, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        elseif activity == 3 then
            DrawText("Speed: " .. velocity, "HUDTimer", screenWidth / 2, yPos + 20, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        elseif activity == 4 then
            DrawText(StyleName, "HUDTimer", screenWidth / 2, yPos + 20, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            DrawText("Time: " .. currentFormatted, "HUDTimer", screenWidth / 2, yPos + 40, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            DrawText("Speed: " .. velocity, "HUDTimer", screenWidth / 2, yPos + 60, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        local wr, wrn
        local styleID = pl:GetNWInt("Style", 1)

        if not TIMER.WorldRecords or not TIMER.WorldRecords[styleID] or #TIMER.WorldRecords[styleID] == 0 or TIMER.WorldRecords[styleID][2] == 0 then 
            wr = "No time recorded"
            wrn = ""
        else 
            wr = ConvertTimeWR(TIMER.WorldRecords[styleID][2])
            wrn = "(" .. TIMER.WorldRecords[styleID][1] .. ")"
        end

        local pbText = (not data.pb or data.pb == 0) and "No time recorded" or ConvertTimeWR(data.pb)

        DrawText("WR: " .. wr .. " " .. wrn, "HUDTimerBig", 10, 6, textColor)
        DrawText("PB: " .. pbText, "HUDTimerBig", 10, 34, textColor)        
    end,

    ["hud.flow"] = function(pl, data)
        local theme = Theme:GetPreference("HUD")

        local width = 230
        local height = 95
        local xPos = 40
        local yPos = 40

        local BASE = theme["Colours"]["Secondary Colour"]
        local INNER = theme["Colours"]["Primary Colour"]
        local BAR = DynamicColors.PanelColor
        local TEXT = theme["Colours"]["Text Colour"]
        local OUTLINE = theme["Toggles"]["Outlines"] and theme["Colours"]["Outlines Colour"] or Color(0, 0, 0, 0)

        if lp():Team() ~= TEAM_SPECTATOR then
            local xPosStrafe = xPos + 5
            local heightStrafe = height + 35

            surface.SetDrawColor(BASE)
            surface.DrawRect(ScrW() - xPosStrafe - width, screenHeight - yPos - heightStrafe, width + 5, heightStrafe)
            surface.SetDrawColor(INNER)
            surface.DrawRect(ScrW() - xPosStrafe + 5 - width, screenHeight - yPos - (heightStrafe - 5), width - 5, 55)

            -- set boxes
            surface.SetDrawColor(HUDData[pl].a and BAR or INNER)
            surface.DrawRect(ScrW() - xPosStrafe + 5 - width, screenHeight - yPos - (heightStrafe - 65), (width / 2) - 5, 27)
            DrawText("A", "HUDTimer", ScrW() - xPosStrafe + 5 - width + (width / 4) - 5, screenHeight - yPos - (heightStrafe - 65) + 13, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            surface.SetDrawColor(HUDData[pl].d and BAR or INNER)
            surface.DrawRect(ScrW() - xPosStrafe + 5 - width / 2, screenHeight - yPos - (heightStrafe - 65), (width / 2) - 5, 27)
            DrawText("D", "HUDTimer", ScrW() - xPosStrafe + 5 - width / 2 + (width / 4) - 5, screenHeight - yPos - (heightStrafe - 65) + 13, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            surface.SetDrawColor(HUDData[pl].l and BAR or INNER)
            surface.DrawRect(ScrW() - xPosStrafe + 5 - width, screenHeight - yPos - (heightStrafe - 97), (width / 2) - 5, 27)
            DrawText("Mouse Left", "HUDTimer", ScrW() - xPosStrafe + 5 - width + (width / 4) - 5, screenHeight - yPos - (heightStrafe - 97) + 13, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            surface.SetDrawColor(HUDData[pl].r and BAR or INNER)
            surface.DrawRect(ScrW() - xPosStrafe + 5 - width / 2, screenHeight - yPos - (heightStrafe - 97), (width / 2) - 5, 27)
            DrawText("Mouse Right", "HUDTimer", ScrW() - xPosStrafe + 5 - width / 2 + (width / 4) - 5, screenHeight - yPos - (heightStrafe - 97) + 13, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            -- extra
            local infoY = screenHeight - yPos - (heightStrafe - 18)
            DrawText("Extras: ", "HUDTimer", ScrW() - xPosStrafe + 15 - width, infoY, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            DrawText("Strafes: " .. (HUDData[pl].strafes or 0), "HUDTimer", ScrW() - xPosStrafe + 15 - width, infoY + 20, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            -- keys
            local actionX = ScrW() - xPosStrafe - 10
            DrawText("Duck", "HUDTimer", actionX, infoY, HUDData[pl].duck and BAR or TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            DrawText("Jump", "HUDTimer", actionX - 42, infoY, HUDData[pl].jump and BAR or TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            DrawText("S", "HUDTimer", actionX - 88, infoY, HUDData[pl].s and BAR or TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            DrawText("W", "HUDTimer", actionX - 108, infoY, HUDData[pl].w and BAR or TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            DrawText('Sync: ' .. (pl.sync or 0) .. '%', "HUDTimer", actionX, infoY + 20, TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

            -- outlines
            surface.SetDrawColor(OUTLINE)
            surface.DrawOutlinedRect(ScrW() - xPosStrafe - width, screenHeight - yPos - heightStrafe, width + 5, heightStrafe)
            surface.DrawOutlinedRect(ScrW() - xPosStrafe + 5 - width, screenHeight - yPos - (heightStrafe - 5), width - 5, 55)
            surface.DrawOutlinedRect(ScrW() - xPosStrafe + 5 - width, screenHeight - yPos - (heightStrafe - 65), (width / 2) - 5, 27)
            surface.DrawOutlinedRect(ScrW() - xPosStrafe + 5 - width / 2, screenHeight - yPos - (heightStrafe - 65), (width / 2) - 5, 27)
            surface.DrawOutlinedRect(ScrW() - xPosStrafe + 5 - width, screenHeight - yPos - (heightStrafe - 97), (width / 2) - 5, 27)
            surface.DrawOutlinedRect(ScrW() - xPosStrafe + 5 - width / 2, screenHeight - yPos - (heightStrafe - 97), (width / 2) - 5, 27)

        end

		if lp():Team() == TEAM_SPECTATOR then
			local ob = pl
			if Iv(ob) and ob:IsPlayer() then
                local nStyle = ob:GetNWInt("Style", TIMER:GetStyleID("Normal"))
                local stylename = TIMER:StyleName(nStyle)
				
				local header, pla
				if ob:IsBot() then
					header = "Spectating Replay"
					pla =  ob:GetNWString("BotName", "Loading...") .. " (" .. stylename .. " style)"
				else
					header = "Spectating"
					pla = ob:Name() .. " (" .. stylename .. ")"
				end

				DrawText( header, "HUDHeaderBig", screenWidth / 2, screenHeight - 33 - 10, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER )
				DrawText( header, "HUDHeaderBig", screenWidth / 2, screenHeight - 35 - 10, Color(214, 59, 43, 255), TEXT_ALIGN_CENTER )
				DrawText( pla, "HUDHeader", screenWidth / 2, screenHeight - 18 - 40 - 10, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER )
				DrawText( pla, "HUDHeader", screenWidth / 2, screenHeight - 20 - 40 - 10, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER )
			end
		end

        local velocity = fl(pl:GetVelocity():Length2D())
        local timeLabel = "Time: "
        local pbLabel = "PB: "
        local personal = pl:IsBot() and pl.pb or data.pb
        local current = data.current

        local personalFormatted = ConvertTimeWR(personal)
        local currentFormatted = ConvertTime(current) .. ConvertTimeMS(current)

        if pl:GetNWInt("inPractice", false) then
            currentFormatted = ""
            personalFormatted = ""
            timeLabel = "Timer Disabled"
            pbLabel = "Practice mode has no timer"
        elseif current <= 0 and not pl:IsBot() then
            currentFormatted = ""
            personalFormatted = ""
            timeLabel = "Timer Disabled"
            pbLabel = "Leave the zone to start timer"
        else
        if pl.TimerFinished then
            currentFormatted = ConvertTimeWR(pl.tickTimeDiffEnd)
        elseif pl:IsBot() then
            currentFormatted = ConvertTimeWR(current)
        elseif pl:Team() == TEAM_SPECTATOR and not pl:IsBot() then
            currentFormatted = ConvertTimeWR(current)
        else
            currentFormatted = ConvertTime(current) .. ConvertTimeMS(current)
        end

        end

        surface.SetDrawColor(BASE)
        surface.DrawRect(xPos, screenHeight - yPos - 95, width, height)

	    surface.SetDrawColor(INNER)
	    surface.DrawRect(xPos + 5, screenHeight - yPos - 90, width - 10, 55)
	    surface.DrawRect(xPos + 5, screenHeight - yPos - 30, width - 10, 25)

        local cp = mc(velocity, 0, 3500) / 3500
        surface.SetDrawColor(DarkenColor(DynamicColors.PanelColor, cp))
        surface.DrawRect(xPos + 5, screenHeight - yPos - 30, cp * 220, 25)

        DrawText(timeLabel, "HUDTimer", (currentFormatted ~= "" and xPos + 12 or xPos + width / 2), screenHeight - yPos - 75, TEXT, (currentFormatted ~= "" and TEXT_ALIGN_LEFT or TEXT_ALIGN_CENTER), TEXT_ALIGN_CENTER)
        DrawText(pbLabel, "HUDTimer", (currentFormatted ~= "" and xPos + 13 or xPos + width / 2), screenHeight - yPos - 50, TEXT, (currentFormatted ~= "" and TEXT_ALIGN_LEFT or TEXT_ALIGN_CENTER), TEXT_ALIGN_CENTER)
        DrawText(velocity .. " u/s", "HUDTimer", xPos + 115, screenHeight - yPos - 18, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        DrawText(currentFormatted, "HUDTimer", xPos + width - 12, screenHeight - yPos - 75, TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        DrawText(personalFormatted, "HUDTimer", xPos + width - 12, screenHeight - yPos - 50, TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

        surface.SetDrawColor(OUTLINE)
        surface.DrawOutlinedRect(xPos, screenHeight - yPos - 95, width, height)
        surface.DrawOutlinedRect(xPos + 5, screenHeight - yPos - 90, width - 10, 55)
        surface.DrawOutlinedRect(xPos + 5, screenHeight - yPos - 30, width - 10, 25)
    end,

    ["hud.momentum"] = function(pl, data)
        local width = 200
        local height = 100
        local xPos = (screenWidth / 2) - (width / 2)
        local yPos = screenHeight - 90 - height

		local theme = Theme:GetPreference("HUD")
		local tc = theme["Colours"]["Text Colour"]
		local tc2 = theme["Colours"]["Text Colour"]
        local boxColor = Color(0, 0, 0, 100)
        local RNGfixColor = Color(0, 255, 255)
        local textColor = color_white
        local highlightColor = DynamicColors.PanelColor
        local increaseColor = DynamicColors.PanelColor
        local decreaseColor = Color(200, 0, 0)

        local sync = pl.sync
        if sync ~= 0 and type(sync) == 'number' then
            local col = sync > 93 and increaseColor or textColor
            col = sync < 90 and decreaseColor or col
            col = sync == 0 and color_white or col

            DrawText("Sync", "HUDTimerMedThick", screenWidth / 2, yPos + height + 10, textColor, TEXT_ALIGN_CENTER)
            DrawText(sync, "HUDTimerKindaUltraBig", screenWidth / 2, yPos + height + 34, col, TEXT_ALIGN_CENTER)

            local barWidth = sync / 100 * (width + 10)
            if roundedBoxEnabled:GetBool() then
                DrawBoxRound(8, xPos - 10, screenHeight - 24, barWidth, 16, col)
            else
                surface.SetDrawColor(col)
                surface.DrawRect(xPos - 10, screenHeight - 24, barWidth, 16)
            end
        end

        local function getColorJHUD(jumps)
            return jumps == 1 and color_white or highlightColor
        end

        -- Old JHUD
        if SSJStats and jhudold:GetBool() then
            local x, y = ScrW() / 2, ScrH() / 2
            local offsetY = 291

            local gain = math.Round(SSJStats.gain, 2)
            local speed = math.Round(SSJStats.speed, 0)
            local jumps = SSJStats.jumps
            DrawText(speed, "JHUDMain", x, y + offsetY, getColorJHUD(jumps), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            if jumps > 1 then
                offsetY = offsetY + 21
                DrawText("(with " .. gain .. "% gain)", "JHUDMain", x, y + offsetY, getColorForGain(gain), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end

        pl.lastTickUpdate = pl.lastTickUpdate or engine.TickCount()

        local ticksBetweenUpdates = 10
        local currentTick = engine.TickCount()

        local current = (data.current < 0 and 0 or data.current) or 0

        if (currentTick - pl.lastTickUpdate) >= ticksBetweenUpdates then
            if pl:IsBot() then
                time = cTimeWR(current)
            elseif pl:Team() == TEAM_SPECTATOR and not pl:IsBot() then
                time = ConvertTimeWR(current)
            else
                time = cTime(current)
            end

            pl.lastTickUpdate = currentTick
        end

        local personal = data.pb or 0
        local personalFormatted = ConvertTimeWR(personal) .. (data.recTp or "")
        local status = "No Timer"

        if current > 0 and not pl:GetNWInt("inPractice", false) then
            status = time or status
        end
        
        local styles = pl:GetNWInt("Style", 1)
        local worldRecord = TIMER.WorldRecords[styles]
        
        local worldRecordTime
        if worldRecord and worldRecord[2] then
            worldRecordTime = ConvertTimeWR(worldRecord[2])
        end
        
        if roundedBoxEnabled:GetBool() then
            DrawBoxRound(8, xPos, yPos, width, height, boxColor)
        else
            surface.SetDrawColor(boxColor)
            surface.DrawRect(xPos, yPos, width, height)
        end
        
        local speed = data.velocity or math.floor(pl:GetVelocity():Length2D())
        local velocity = pl:GetVelocity():Length2D()

        -- Old speed
        pl.speedcol = pl.speedcol or textColor
        pl.current = pl.current or 0 

        local diff = velocity - pl.current

        if RNGFixHudDetect then  
            pl.speedcol = RNGfixColor

            if not pl.rngFixTimer then
                pl.rngFixTimer = ct() + 0.1
            end
        elseif pl.rngFixTimer and ct() < pl.rngFixTimer then  
            pl.speedcol = RNGfixColor
        else
            pl.rngFixTimer = nil 

            if pl.current == velocity or velocity == 0 then 
                pl.speedcol = textColor
            elseif diff > -2 then 
                pl.speedcol = increaseColor
            elseif diff < -2 then
                pl.speedcol = decreaseColor
            end
        end

        DrawText(ceil(speed), "HUDTimerKindaUltraBig", ScrW() / 2, yPos - 80, (pl:GetMoveType() == MOVETYPE_NOCLIP) and tc or pl.speedcol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        DrawText(status, "HUDTimerKindaUltraBig", screenWidth / 2, yPos + 20, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        if current < 0.1 and pl.InStartZone and not pl:GetNWInt("inPractice", true) and pl:GetMoveType() ~= MOVETYPE_NOCLIP then 
            DrawText("Start Zone", "HUDTimer", screenWidth / 2, yPos - 14, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        if not pl:IsBot() and pl:GetNWInt("inPractice", true) then 
            DrawText("Practicing", "HUDTimer", screenWidth / 2, yPos - 14, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

	    if pl.finished then 
			status = cTime(pl.finished)
		    draw.SimpleText("Map Completed", "HUDTimer", ScrW() / 2, yPos - 14, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

        if pl:IsBot() then
            local timeNumber = tonumber(time) or 0

            local worldRecord = TIMER.WorldRecords[pl:GetNWInt("Style", 1)]
            local maxTime = (worldRecord and worldRecord[2]) or data.pb or 30

            local progress = math.ceil((timeNumber / maxTime) * 100)
            progress = math.Clamp(progress, 0, 100)

            DrawText("Progress: " .. progress .. "%", "HUDTimer", screenWidth / 2, yPos - 14, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        DrawText("Map: " .. game.GetMap(), "HUDTimer", 10, 8, textColor, TEXT_ALIGN_LEFT)

        local styletype = pl:GetNWInt("Style", TIMER:GetStyleID("Normal"))
        local stylename = TIMER:StyleName(styletype)

		if lp():Team() == TEAM_SPECTATOR then 
			local name = pl:Nick()
			if (pl:IsBot()) then 
				name = (stylename .. " Replay (" .. (pl:GetNWString("BotName", "Waiting...") .. ")")) or "Waiting..."
				if (pl:Nick() == "Unknown Replay") then 
					DrawText("Press E to change replay", "HUDTimer", screenWidth / 2, screenHeight - 50, tc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end
			end

			DrawText("Spectating", "HUDTimerKindaUltraBig", screenWidth / 2, 30, tc2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			DrawText(name, "HUDTimerKindaUltraBig", screenWidth / 2, 56, highlightColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

        local wr, wrn
        local styleID = pl:GetNWInt("Style", 1)
        if not TIMER.WorldRecords or not TIMER.WorldRecords[styleID] or #TIMER.WorldRecords[styleID] == 0 or TIMER.WorldRecords[styleID][2] == 0 then 
            wr = "No time recorded"
            wrn = ""
        else
            wr = ConvertTimeWR(TIMER.WorldRecords[styleID][2])
            wrn = "(" .. TIMER.WorldRecords[styleID][1] .. ")"
        end

        local pbText = data.pb == 0 and "No time recorded" or ConvertTimeWR(data.pb) .. " (You)"
        DrawText("World Record: " .. wr .. " " .. wrn, "HUDTimer", 9, 28, textColor)
        DrawText("Personal Best: " .. pbText, "HUDTimer", 10, 48, textColor)

        if TIMER.globalWR and type(TIMER.globalWR) == "string" and TIMER.globalWR ~= "N/A" then
            local playerName, time = string.match(TIMER.globalWR, "(.+)%s%-%s(.+)")

            if playerName and time then
                local formattedText = "Global: " .. time .. " (" .. playerName .. ")"
                DrawText(formattedText, "HUDTimer", screenWidth - 10, 8, textColor, TEXT_ALIGN_RIGHT)
            end
        end
    end,

    ["hud.simple"] = function(pl, data)
        local width = 200
        local height = 100
        local xPos = (screenWidth / 2) - (width / 2)
        local yPos = screenHeight - 90 - height
        local tc = color_white
        local tc2 = Color(0, 160, 200)
        local speed = math.floor(GetClientVelocity(pl))
        local current = data.current or 0
        local isInPractice = pl:GetNWInt("inPractice", false)
        
        local status = (current == 0 or isInPractice) and "Disabled" or ConvertTime(current) .. ConvertTimeMS(current)
        local jumps = pl.player_jumps or 0
        local isBot = pl:IsBot()
    
        if isBot or pl:Team() == TEAM_SPECTATOR then
            status = ConvertTimeWR(current)
        end

        if lp():Team() == TEAM_SPECTATOR then
            local name = pl:Nick()
            if isBot and pl:Nick() == "Multi-style Replay" then
                DrawText("Press E to change replay", "hud.simplefont", screenWidth / 2, screenHeight - 50, tc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                if input.IsKeyDown(KEY_E) and not lp().cane and not lp():IsTyping() then
                    lp():ConCommand("say !replay")
                    lp().cane = true
                    timer.Simple(1, function() lp().cane = false end)
                end
            end

            DrawText("Spectating", "hud.simplefont", screenWidth / 2, 30, tc2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            DrawText(name, "hud.simplefont", screenWidth / 2, 56, tc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        local sync = pl.sync or 0
        local style = pl:GetNWInt("Style", 1)
        local stylename = (current == 0 and pl.InStartZone and not isInPractice) and "Start Zone" or TIMER:StyleName(style) .. (isBot and " Replay" or "")


        local worldRecord = TIMER.WorldRecords and TIMER.WorldRecords[style]
        local wr = "No time recorded"
        local wrn = ""

        if worldRecord and worldRecord[2] then
            wr = ConvertTimeWR(worldRecord[2])
            wrn = "(" .. (worldRecord[1] or "No player") .. ")"
        end

        local personal = data.pb == 0 and "No time recorded" or ConvertTimeWR(data.pb)

        DrawText("Map: " .. game.GetMap(), "hud.simplefont", 10, 8, tc, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        DrawText("World Record: " .. wr .. " " .. wrn, "hud.simplefont", 9, 28, tc, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        DrawText("Personal Best: " .. personal, "hud.simplefont", 10, 48, tc, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        if TIMER.globalWR ~= "N/A" then
            local playerName, time = string.match(TIMER.globalWR, "(.+)%s%-%s(.+)")

            if playerName and time then
                local formattedText = "Global: " .. time .. " (" .. playerName .. ")"
                DrawText(formattedText, "hud.simplefont", screenWidth - 10, 8, textColor, TEXT_ALIGN_RIGHT)
            end
        end

        local zonestatus = "Start Zone"
        local addition = ""
        local ssjtext = ""
        local rank = pl:GetNWInt("Rank", false)

        if not pl:GetNWInt("inPractice", false) and current == 0 and pl.InStartZone then
            zonestatus = "Start Zone"

            if not pl:IsBot() then
                if rank == false or rank <= 0 then
                    ssjtext = "Unranked"
                    addition = ""
                else
                    ssjtext = "Rank: #" .. rank
                end

                speed = ""
                sync = ""
            end
        else
            if SSJStats then
                if SSJStats.speed == 1 then
                    ssjtext = speed
                    addition = ""
                else
                    local syncText = (SSJStats.gain and SSJStats.gain > 0) and (math.Round(SSJStats.gain, 2) .. "%") or ""
                    local gainText = (SSJStats.difference and SSJStats.difference > 0) and ("+" .. math.Round(SSJStats.difference, 2)) or ""

                    if syncText ~= "" or gainText ~= "" then
                        addition = " (" .. (syncText ~= "" and syncText or "") .. ((syncText ~= "" and gainText ~= "") and ", " or "") .. (gainText ~= "" and gainText or "") .. ")"
                    else
                        addition = ""
                    end

                    ssjtext = (SSJStats.speed and SSJStats.speed ~= 0 and SSJStats.speed or "")
                end
            else
                if not pl:IsBot() then
                    if rank == false or rank <= 0 then
                        ssjtext = "Unranked"
                    else
                        ssjtext = "Rank: #" .. rank
                    end
                else
                    ssjtext = ""
                end
                addition = ""
            end
        end

        if pl:GetNWInt("inPractice", false) then
            zonestatus = "Practicing"
        elseif pl.finished and not pl.status then
            status = ConvertTime(pl.finished)
            zonestatus = "Map Completed"
        end

        local boxWidth = 180
        local boxHeight = 120
        local xPos = (screenWidth / 2) - (boxWidth / 2)
        local yPos = screenHeight - 160

        if simpleBoxEnabled:GetBool() then
            DrawBoxRound(10, xPos, yPos, boxWidth, boxHeight, Color(0, 0, 0, 100))
        end

        DrawText(speed .. " u/s", "hud.simplefont", screenWidth / 2, (screenHeight / 2) - 180, tc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        DrawText("Time: " .. status, "hud.simplefont", screenWidth / 2, screenHeight - 130, tc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        DrawText(stylename, "hud.simplefont", screenWidth / 2, screenHeight - 100, tc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        DrawText(overwrite_ssj and overwrite_ssj or (ssjtext .. addition), "hud.simplefont", screenWidth / 2, screenHeight - 70, tc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        if current ~= 0 then
            DrawText(isBot and "" or "Sync: " .. sync .. "%", "hud.simplefont", screenWidth - 100, screenHeight - 70, syncColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            DrawText(isBot and "" or "Jumps: " .. jumps, "hud.simplefont", 100, screenHeight - 70, tc, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end,

    ["hud.shavit"] = function(pl, data)
        if lp():GetActiveWeapon().Primary then
            if ammo_clip ~= -1 then
                surface.SetFont("CSS_FONT")
            
                local csstext = Color(255, 176, 0, 120)
                DrawBoxRound(8, screenWidth - 352, screenHeight - 76, 318, 56, Color(0, 0, 0, 90))
                DrawText(16, "CSS_FONT", screenWidth - 270, screenHeight - 90 + 9, color_white, TEXT_ALIGN_CENTER)
                DrawText("M", "CSS_ICONS", screenWidth - 75, screenHeight - 75, color_white, TEXT_ALIGN_CENTER) 
                DrawText(420, "CSS_FONT", screenWidth - 120, screenHeight - 90 + 9, color_white, TEXT_ALIGN_RIGHT)
                DrawBoxRound(0, screenWidth - 230, screenHeight - 70, 3, 42, color_white)
            end
        end

    if lp():Team() == TEAM_SPECTATOR then
        local backgroundspec = Color(0, 0, 0, 190)
        surface.SetDrawColor(backgroundspec)
        surface.DrawRect(0, screenHeight - 116.70, screenWidth, screenHeight)

        DrawText(pl:Name() .. " (100)", "HUDTimer", screenWidth / 2, screenHeight - 60, Color(239, 74, 74), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        surface.SetDrawColor(backgroundspec)
        surface.DrawRect(0, 0, screenWidth, 100)

        DrawText("Counter-Terrorists :   0", "HUDSpecHud", screenWidth - 484, (screenHeight / 35) - 1, Color(241, 176, 13), text, TEXT_ALIGN_RIGHT)
        DrawText("Map: " .. game.GetMap(), "HUDSpecHud", screenWidth - 220, (screenHeight / 35) - 1, Color(241, 176, 13), text, TEXT_ALIGN_RIGHT)
        DrawText("Terrorists :   0", "HUDSpecHud", screenWidth - 400, (screenHeight / 18) - 1, Color(241, 176, 13), text, TEXT_ALIGN_RIGHT)
        DrawText("e", "CounterStrike", screenWidth - 220, (screenHeight / 21) - 1, Color(241, 176, 13), text, TEXT_ALIGN_RIGHT)
        DrawText("00:00", "HUDSpecHud", screenWidth - 184, (screenHeight / 17) - 1, Color(241, 176, 13), text, TEXT_ALIGN_RIGHT)
    end

     local velocity = math.floor(GetClientVelocity(pl))
     local time = "Time: "
     local pb = "Best: "
     local style = pl:GetNWInt("Style", 1)
     local stylename = TIMER:StyleName(style) .. (pl:IsBot() and "" or "")
     local personal = cTime(data.pb or 0)
     local current = data.current < 0 and 0 or data.current
     local currentf = cTime(current)

     local jumps = pl.player_jumps or 0
     local sync = pl.sync or 0

     local base = Color(0, 0, 0, 70)
    local isInPractice = pl:GetNWInt("inPractice", false)
    local isInStart = pl.InStartZone and not isInPractice
    local isFinished = pl.finished or pl.bonusfinised

    if isFinished or isInPractice then
        activity = 3 -- Speed Display
    elseif pl:IsBot() then
        activity = 4 -- Replay Mode
    elseif current > 0 then
        activity = 1 -- Normal Timer HUD
    elseif isInStart then
        activity = 2 -- In Start Zone
    else
        activity = 3 -- no timer + no start zone = practice area maybe
    end

     local box_y_css = -4
     local box_y_css2 = -8
     local text_y_css = 5
     local text_y_css2 = -22
     local text_y_css4 = 2

     local width = {162, 164, 125, 165}
     local width2 = {162, 164, 38, 165}

     width = width[activity]
     width2 = width2[activity]

     local height = {136, 95, 56, 90}
     height = height[activity]
     local activity_y = {175, 175, 175, 175}
     activity_y = activity_y[activity]

     local xPos = (screenWidth / 2) - (width / 2)
     local xPos2 = (screenWidth / 2) - (width2 / 2)
     local yPos = screenHeight - height - activity_y
     local CSRound2 = 8

     local wrtext = "WR: "

     local wr, wrn
     if not TIMER.WorldRecords or not TIMER.WorldRecords[style] or #TIMER.WorldRecords[style] == 0 then 
         wr = "No Record"
         wrn = ""
     else 
         wr = cCTime(TIMER.WorldRecords[style][2])
         wrn = "(" .. TIMER.WorldRecords[style][1] .. ")"
     end

     local pbtext
     if data.pb == 0 then 
         pbtext = "No Time"
     else 
         pbtext = cCTime(data.pb or 0)
     end

     DrawText("WR: " .. wr .. " " .. wrn, "HUDcsstop2", 19, 10, color_white, text, TEXT_ALIGN_LEFT)
     DrawText(pb .. pbtext, "HUDcsstop2", 19, 50, color_white, text, TEXT_ALIGN_LEFT)

     if activity == 1 then
         DrawText("Sync: " .. sync .. "%", "HUDcssBottom", screenWidth / 2.002, text_y_css + yPos + 79, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
     end


     if activity == 1 then
         local TimeText = "Time: " .. currentf
         local Vel = "Speed: " .. velocity
         local Scaling = TimeText
         local place = GetCurrentPlacement(ConvertTime(current), style)
         local placetext = " (#" .. place .. ")"
         local ScalingWidth, _ = surface.GetTextSize(Scaling)

         DrawBoxRound(CSRound2, screenWidth / 2 - ScalingWidth / 2 - 43, yPos + box_y_css, ScalingWidth + 87, height, base)
         DrawText(stylename, "HUDcss4", screenWidth / 2.002, text_y_css + yPos + 19, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
         DrawText(Scaling .. placetext, "HUDcssBottomTimer", screenWidth / 2, text_y_css + yPos + 39, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
         DrawText("Jumps: " .. jumps, "HUDcssBottom", screenWidth / 2, text_y_css + yPos + 59, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
         DrawText(Vel, "HUDcssBottom", screenWidth / 2.002, text_y_css + yPos + 99, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
     elseif activity == 2 then
         DrawBoxRound(CSRound2, xPos, yPos + box_y_css2, width, height, base)
         DrawText("In Start Zone", "HUDcss", screenWidth / 2.002, text_y_css2 + yPos + 44, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
         DrawText(velocity, "HUDcss", screenWidth / 2.007, text_y_css2 + yPos + 84, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
     elseif activity == 3 then
        local maxWidth = 30
        local bigScale = 60
        local velocityScale = math.min(velocity, maxWidth)

        if velocity >= 1000 then
            velocityScale = bigScale
        end

        DrawBoxRound(CSRound2, xPos2 - (velocityScale / 2), yPos + box_y_css, width2 + velocityScale, height, base)
        DrawText(velocity, "HUDcss", screenWidth / 2, text_y_css4 + yPos + 22, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
     elseif activity == 4 then
         DrawBoxRound(CSRound2, xPos, yPos + box_y_css, width, height, base)
         DrawText(stylename, "HUDcss", screenWidth / 2, text_y_css2 + yPos + 42, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
         DrawText("Time: " .. currentf, "HUDcss", screenWidth / 2, text_y_css2 + yPos + 62, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
         DrawText("Speed: " .. velocity, "HUDcss", screenWidth / 2, text_y_css2 + yPos + 82, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
      end
    end,

    -- Added
    ["hud.stellar"] = function(pl, data)
        local foregroundColor = Color(21, 21, 28)
        local backgroundColor = Color(7, 8, 13)
        local textColor = Color(255, 255, 255)
        local texts = {}

        local jumps = pl.player_jumps or 0
        local strafes = data.strafes or 0
        local sync = pl.sync or 0

        local velocity = data.velocity or math.floor(GetClientVelocity(pl)) or 0
        local personal = data.pb or 0
        local personalf = ConvertTimeWR(personal)
        local current = (data.current and data.current < 0) and 0 or data.current or 0
        local currentf = ConvertTime(current) .. ConvertTimeMS(current)
        local style = pl:GetNWInt("Style", 1)
        local stylename = TIMER:StyleName(style) .. (pl:IsBot() and "" or "")
        local sync = pl.sync or 0
        local jumps = pl.player_jumps or 0
        local isInPractice = pl:GetNWBool("inPractice", false)

        local zonestatus = currentf
        local status

        if current == 0 or isInPractice then
            status = "Disabled"
        elseif pl:IsBot() then
            status = ConvertTimeWR(current)
        elseif pl:Team() == TEAM_SPECTATOR and not pl:IsBot() then
            status = ConvertTimeWR(current)
        else
            status = ConvertTime(current) .. ConvertTimeMS(current)
        end

        insert(texts, "Time: " .. status)
        insert(texts, "")
        insert(texts, "Speed: " .. velocity .. " u/s")
        insert(texts, "Style: " .. stylename)
        insert(texts, "Jumps: " .. jumps .. " | " .. "Strafes: " .. (data.strafes or 0) .. " (" .. sync .. "%)")

        surface.SetFont("sm_mod")

        local maxWidth, totalHeight = 0, 0
        local lineSpacing = 5

        for _, text in ipairs(texts) do
            local textWidth, textHeight = surface.GetTextSize(text)
            maxWidth = math.max(maxWidth, textWidth)
            totalHeight = totalHeight + textHeight + lineSpacing
        end

        local padding = 15
        local width = maxWidth + padding * 2
        local height = totalHeight + padding * 2
        local x = (screenWidth / 2) - (width / 2)
        local y = (screenHeight / 1.1) - height

        DrawBoxEx(6, x, y, width, height, backgroundColor, false, false, true, true)
        DrawBoxEx(6, x, y - 10, width, 15, foregroundColor, true, true, false, false)

        DrawText("Map Zone", "TitleStellar", screenWidth / 2, y - 2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        local textY = y + padding + 10
        for i, text in ipairs(texts) do
            local textWidth, textHeight = surface.GetTextSize(text)
            DrawText(text, "sm_mod", screenWidth / 2, textY, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            textY = textY + textHeight + lineSpacing
        end
end
}

-- Draw table size
local function DrawTextTableSize(tab, font)
    local width, height = 0, 0

    font = font or "VerdanaUI_B"
    surface.SetFont(font)

    for i, text in pairs(tab) do
        local tempWidth, tempHeight = surface.GetTextSize(text or "")
        tempHeight = tempHeight + (tempHeight / 3)

        height = (tempHeight * i)

        if width < tempWidth then
            width = tempWidth
        end
    end

    return width, height
end

local function DrawTextTableLeft(x, y, tab, font, color)
    surface.SetFont(font or "VerdanaUI_B")
    surface.SetTextColor(color or color_white)

    for i, text in ipairs(tab) do
        local _, tempHeight = surface.GetTextSize(text or "")
        surface.SetTextPos(x, y + (i - 1) * tempHeight)
        surface.DrawText(text)
    end
end

-- Draw side bar
local function DrawSimpleSideTimer(pl, data)
    if not data then return end
    if not sidetimer:GetBool() then return end

    local personal = data.pb == 0 and "No time recorded" or ConvertTimeWR(data.pb)

    local style = pl:GetNWInt("Style", 1)
    local worldRecord = TIMER.WorldRecords and TIMER.WorldRecords[style]
    local wr = "No time recorded"
    local wrn = ""

    if worldRecord and worldRecord[2] then
        wr = ConvertTimeWR(worldRecord[2])
        wrn = "(" .. (worldRecord[1] or "No player") .. ")"
    end

    local current = data.current or 0
    local currentf = ConvertTimeWR(current)

    local timeLeft = "Time Left: " .. cTimeWR(timeLeft or "Loading...")
    local mapName = game.GetMap()

    local mapInfotier = {
        ["bhop_asko"] = {tier = 1, linear = true},
        ["bhop_newdun"] = {tier = 1, linear = false},
        ["bhop_stref_amazon"] = {tier = 2, linear = true},
    }

    local mapData = mapInfotier[mapName]
    local tierInfo = mapData and "Tier " .. mapData.tier or "Tier not found"
    local linearInfo = mapData and (mapData.linear and "Linear" or "Staged") or ""

    local mapInfo = "Map: " .. mapName .. " (" .. tierInfo
    if linearInfo ~= "" then
        mapInfo = mapInfo .. " - " .. linearInfo
    end
    mapInfo = mapInfo .. ")"

    local text = {
        timeLeft,
        mapInfo,
        "PB: " .. personal,
        "WR: " .. wr .. " " .. wrn,
        "Spectators:" .. " None",
    }

    local width, height = DrawTextTableSize(text, "HUDText")

    local offsetY = 100
    local posX, posY = (screenWidth - width - 20), (screenHeight / 2 - (height / 2)) + offsetY

    DrawTextTableLeft(posX + 2, posY + 2, text, "HUDText", Color(50, 50, 50, 255))
    DrawTextTableLeft(posX, posY, text, "HUDText", Color(255, 255, 255, 255))
end

-- JHUD --
local duration_cvar = CreateClientConVar("bhop_ssj_fadeduration", 1.5, true, false, "Controls how long in seconds pass before SSJHud fades", 0, 10)
cvars.AddChangeCallback("bhop_ssj_fadeduration", function(cvar, old, new)
	duration = tonumber(new)
end)

-- Variables
local jhudenable = CreateClientConVar("bhop_jhud", 1, true)
local last_jump = 0
local duration = duration_cvar:GetFloat()
local alpha = 255
local fade = 0

local speedColorCached = Color(255, 255, 255)
local baseColorCached = Color(255, 0, 0)

-- Utility Functions
local function getColorForSpeed(speed)
    if speed >= 278 and speed < 290 then
        return Color(0, 160, 200)          -- Color for the desired speed range
    else
        return Color(255, 255, 255)        -- Default color
    end
end

local function updateColorAlpha(color, fadeAmount)
    if color.a > 0 then
        color.a = math.Clamp(color.a - fadeAmount, 0, 255)
    end
end

-- Network Message
NETWORK:GetNetworkMessageSSJ("SSJ", function(data)
    baseColorCached = getColorForGain(data.gain)
    speedColorCached = getColorForSpeed(data.speed)

    SSJStats = data
    last_jump = ct()
    alpha = 255
end)

-- Draw Speed
local function drawSpeed(speed, color)
    DrawText(math.Round(speed, 0), "JHUDMainBIG", screenWidth / 2, screenHeight / 2 - 100, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

CreateConVar("bhop_jhud", "1", FCVAR_ARCHIVE, "Enable or disable the JHUD HUD element.")
CreateConVar("bhop_jhud_gain", "1", FCVAR_ARCHIVE, "Enable or disable Gain display on JHUD.")
CreateConVar("bhop_jhud_sync", "1", FCVAR_ARCHIVE, "Enable or disable Sync display on JHUD.")
CreateConVar("bhop_jhud_strafes", "1", FCVAR_ARCHIVE, "Enable or disable Strafe counter on JHUD.")
CreateConVar("bhop_jhud_efficiency", "1", FCVAR_ARCHIVE, "Enable or disable Efficiency on JHUD.")
CreateConVar("bhop_jhud_difference", "1", FCVAR_ARCHIVE, "Enable or disable Difference speed on JHUD.")

-- JHUD Styles
local hudStyles = {
    pyramid = function(scrW, scrH, data, fadedWhite, colorToUse)
        drawSpeed(data.speed, colorToUse)

        if data.jumps > 1 then
            if GetConVar("bhop_jhud_difference"):GetBool() then
                DrawText(math.Round(data.lastspeed, 0), "JHUDMainBIG2", scrW / 2, scrH / 2 - 140, fadedWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            if GetConVar("bhop_jhud_gain"):GetBool() then
                DrawText(math.Round(data.gain, 2) .. "%", "JHUDMainBIG2", scrW / 2, scrH / 2 - 60, fadedWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end

        if data.strafes > 0 and GetConVar("bhop_jhud_strafes"):GetBool() then
            DrawText(data.strafes, "JHUDEFF", scrW / 2, scrH / 2 - 30, fadedWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        if data.efficiency > 0 and GetConVar("bhop_jhud_efficiency"):GetBool() then
            DrawText(math.Round(data.efficiency), "JHUDEFF", scrW / 2, scrH / 2 - 168, fadedWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end,

    kawaii = function(scrW, scrH, data)
        local gainkawaii = math.Round(data.gain, 2) .. "%"

        if data.jumps == 1 then
            DrawText(data.jumps .. ": " .. data.speed, "HUDTimerUltraBig", scrW / 2, scrH / 2 - 100, speedColorCached, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        elseif data.jumps > 1 then
            local textToDraw
            if GetConVar("bhop_jhud_gain"):GetBool() then
                textToDraw = data.jumps <= 6 and (data.jumps .. ": " .. data.speed) or (data.jumps % 6 == 0 and (data.jumps .. ": " .. gainkawaii) or gainkawaii)
            else
                textToDraw = data.jumps .. ": " .. data.speed
            end
            DrawText(textToDraw, "HUDTimerUltraBig", scrW / 2, scrH / 2 - 100, baseColorCached, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end,

    claz = function(scrW, scrH, data)
        local elements = {}

        local speed = math.Round(data.speed, 2)
        local gain = math.Round(data.gain, 2) .. "%"
        local diff = math.Round(data.difference, 0)
        local efficiency = math.Round(data.efficiency, 2)
        local sync = math.Round(data.sync, 2)
        local strafes = data.strafes

        if data.jumps > 1 then
            if GetConVar("bhop_jhud_difference"):GetBool() then
                table.insert(elements, "(" .. diff .. ")")
            end
            if GetConVar("bhop_jhud_gain"):GetBool() then
                table.insert(elements, gain)
            end
            if GetConVar("bhop_jhud_efficiency"):GetBool() then
                table.insert(elements, efficiency)
            end
            if GetConVar("bhop_jhud_strafes"):GetBool() then
                table.insert(elements, strafes)
            end
            if GetConVar("bhop_jhud_sync"):GetBool() then
                table.insert(elements, sync .. "%")
            end

            local text = (data.jumps) .. ": " .. speed .. " | " .. table.concat(elements, " | ")
            DrawText(text, "ClazJHUD", scrW / 2, scrH / 2 - 100, baseColorCached, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        else
            DrawText("Pre-Speed: " .. speed, "ClazJHUD", scrW / 2, scrH / 2 - 100, speedColorCached, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
end
}

-- Main HUD Display
local jhudstyle = CreateClientConVar("bhop_jhud_style", "pyramid", true, false, "Choose a JHUD style: 'pyramid', 'kawaii', 'claz'.")

-- JHUD Display
local function JumpHudDisplay()
    if not jhudenable:GetBool() then return end

    if not SSJStats or not SSJStats.jumps then return end

    local scrW, scrH = screenWidth, screenHeight
    local data = SSJStats

    if data.gain == 0 and data.speed == 0 then return end

    if last_jump + duration < ct() then
        alpha = math.Clamp(alpha - 5, 0, 255)
    else
        alpha = 255
    end

    local hudStyle = jhudstyle:GetString()
    local fadedWhite = Color(255, 255, 255, alpha)
    
    updateColorAlpha(speedColorCached, 255 - alpha)
    updateColorAlpha(baseColorCached, 255 - alpha)

    local colorToUse = data.jumps <= 1 and speedColorCached or baseColorCached
    local hudFunction = hudStyles[hudStyle]

    if hudFunction then
        hudFunction(scrW, scrH, data, fadedWhite, colorToUse)
    end
end

Trainer = { 
    Enabled = CreateClientConVar("bhop_strafetrainer", "0", true, false, "Strafe Trainer Display"), 
    Value = function() return GetConVar("bhop_strafetrainer"):GetBool() end 
}

-- Cache
local cachedCenterX, cachedCenterY = screenWidth / 2, screenHeight / 2
local barWidth, barHeight = 240, 22
local size, halfSize, textSpacing = 4, 2, 6
local maxTrainValue = 200
local sideHeight = 68

local function GetColour(percent, velocity)
    local offset = math.abs(1 - percent)
    local whiteningRate = 0.2
    local redValue = math.min(255, 255 + (velocity * whiteningRate))

    if offset < 0.05 then return Color(0, 255, 255)
        elseif offset < 0.1 then return Color(0, 200, 0)
        elseif offset < 0.25 then return Color(220, 255, 0)
        elseif offset < 0.5 then return Color(200, 150, 0)
        else return Color(redValue, 255, 255)
    end
end

-- Strafe trainer display
local function StrafeTrainer()
    if not Trainer.Enabled:GetBool() then return end

    local lp = lp()
    if not Iv(lp) or lp:GetMoveType() == MOVETYPE_NOCLIP or not lp:KeyDown(IN_JUMP) then return end

    local velocityMagnitude = math.floor(GetClientVelocity(lp))
    
    local trainValue = tonumber(CurrentTrainValue) or 0
    local currentTrainValue = (mc and mc(trainValue, 0, 2)) or 0
    local endingVal = round(currentTrainValue * 100)
    local color = GetColour(currentTrainValue, velocityMagnitude)

    local centerX, centerY = cachedCenterX, cachedCenterY + 100
    local move = (barWidth * currentTrainValue) / 2

    SetDrawColor(color)

    DrawRect(centerX - barWidth / 2, centerY - sideHeight / 2.14, size, sideHeight)
    DrawRect(centerX + barWidth / 2 - size, centerY - sideHeight / 2.14, size, sideHeight)
    DrawRect(centerX - barWidth / 2 + move, centerY - barHeight / 2 + halfSize, size, barHeight)

    centerY = centerY + 32
    DrawRect(centerX - barWidth / 2 + halfSize, centerY, barWidth - size, size)

    SetDrawColor(color_white)
    DrawRect(centerX - halfSize / 2, centerY + size, halfSize, 14)

    local textToShow = (endingVal >= 100 and endingVal <= 105) and endingVal or 100
    DrawText(textToShow, "HUDTimer", centerX, centerY + size + textSpacing + 14, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

    centerY = centerY - 64
    SetDrawColor(color)
    DrawRect(centerX - barWidth / 2 + halfSize, centerY, barWidth - size, size)

    SetDrawColor(color_white)
    DrawRect(centerX - halfSize / 2, centerY - 14, halfSize, 14)

    local displayText = (endingVal >= 0 and endingVal <= maxTrainValue) and tostring(endingVal) or "Out of Range"
    DrawText(displayText, "HUDTimer", centerX, centerY - 14 - textSpacing, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
end
hook.Add("HUDPaint", "Trainer", StrafeTrainer)

local spechud = CreateClientConVar("bhop_hidespec", 0, true, false, "Draw spectator hud", 0, 1)
concommand.Add("bhop_hidespec_toggle", function(client, cmd, args)
	spechud:SetBool(!spechud:GetBool())
end)

-- Disable
local HUDItems = {
    CHudHealth = true,
    CHudBattery = true,
    CHudAmmo = true,
    CHudSecondaryAmmo = true,
    CHudSuitPower = true
}

function GM:HUDShouldDraw(element)
    if element == "CHudCrosshair" then
        return GetConVar("bhop_default_crosshair"):GetBool()
    end

    if HUDItems[element] then
        return false
    end

    return true
end

function GM:HUDDrawTargetID()
    return false 
end

-- Draw the HUDs
function HUD:Draw(styles, client, data)
    JumpHudDisplay()

	local theme, id = Theme:GetPreference("HUD")
	self.Themes[id](client, data)

    DrawSpecHUD()
end

-- Get World Record
local function GetWR()
    local o = Iv(lp():GetObserverTarget()) and lp():GetObserverTarget() or lp()
    local s = TIMER:GetStyle(o)

    if not TIMER.WorldRecord then return 0 end
    return TIMER.WorldRecord[s] and TIMER.WorldRecord[s].time or 0
end

function GetTimePiece(compare, style)
    local first = style or TIMER.Style
    if not first then return "" end

    local difference = compare - first
    local absn = math.abs(difference)

    if difference < 0 then
        return fo(" [ -%.2d:%.2d]", fl(absn / 60), fl(absn % 60))
    elseif difference == 0 then
        return " [WR]"
    else
        return fo(" [+%.2d:%.2d]", fl(absn / 60), fl(absn % 60))
    end
end

-- Spectator Hud
function DrawSpecHUD()
    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    if not disablespec:GetBool() then return end

    local txt = "Spectating %s (%s):"
    local SpecList = {}
    local Obs = lp:GetObserverTarget()

    lp.SpectatorList = lp.SpectatorList or {}

    if lp:Alive() and #lp.SpectatorList > 0 then
        SpecList = lp.SpectatorList
        txt = string.format(txt, "You", tostring(#lp.SpectatorList))

    elseif lp:Team() == TEAM_SPECTATOR and IsValid(Obs) then
        Obs.SpectatorList = Obs.SpectatorList or {}

        if #Obs.SpectatorList > 0 then
            SpecList = Obs.SpectatorList
            txt = string.format(txt, Obs:GetName(), tostring(#Obs.SpectatorList))
        end
    end

    local botName = nil
    if IsValid(Obs) and Obs:IsBot() then
        botName = Obs:GetName()
        txt = string.format(txt, "Replay", "Watching")

        for _, v in ipairs(player.GetAll()) do
            if IsValid(v) and v:GetObserverTarget() == Obs then
                table.insert(SpecList, v)
            end
        end
    end

    if #SpecList == 0 and not (IsValid(Obs) and Obs:IsBot()) then return end

    DrawText(txt, "ui.mainmenu.button", ScrW() - 20, ScrH() / 2 - (#SpecList * 10), color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

    local combinedList = {}
    local seenNames = {}

    for _, spectator in ipairs(SpecList) do
        if IsValid(spectator) and spectator:IsPlayer() then
            local name = spectator:GetName()
            if not seenNames[name] then
                seenNames[name] = true
                table.insert(combinedList, name)
            end
        end
    end

    for _, name in pairs(CSList or {}) do
        if not seenNames[name] then
            seenNames[name] = true
            table.insert(combinedList, name)
        end
    end

    for i = 1, #combinedList do
        local drawName = combinedList[i]

        DrawText(drawName, "ui.mainmenu.button", ScrW() - 20, ScrH() / 2 + (i * 20) - (#combinedList * 10), color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
end

-- Draw the HUD
local hudHideConVar = GetConVar("bhop_hud_hide")
function GM:HUDPaintBackground()
    local pl = LocalPlayer()
    if not Iv(pl) then return end

    if hudHideConVar:GetInt() == 1 then return end

    if pl:Team() == TEAM_SPECTATOR then
        local ob = pl:GetObserverTarget()
        if not IsValid(ob) then return end 

        local isReplay = ob:IsBot() and ob:IsPlayer()

        if Iv(ob) and ob:IsPlayer() and not isReplay then
            local style = ob:GetNWInt("Style", TIMER:GetStyleID("Normal"))
            local stylename = TIMER:StyleName(style)

            local curr = (style == TIMER:GetStyleID("Bonus")) and ob.bonustime or ob.time
            local finished = (style == TIMER:GetStyleID("Bonus")) and ob.bonusfinished or ob.finished

            local totalSeconds = 0
            if finished and finished > 0 then
                totalSeconds = (finished - curr)
            elseif curr and curr > 0 then
                totalSeconds = (engine.TickCount() - curr)
            end

            local formattedTime = ConvertTimeWR(totalSeconds)
            HUD:Draw(2, ob, {
                pos = {Xo, Yo},
                pb = select(1, TIMER:GetPersonalBest(ob, ob.style)),
                current = totalSeconds,
                curTp = formattedTime,
                recTp = 0
            })

        elseif Iv(ob) and isReplay then
            local style = ob:GetNWInt("Style", TIMER:GetStyleID("Normal"))
            local stylename = TIMER:StyleName(style)

            local curremt, record = 0, 0
            local vel = ob:GetVelocity():Length2D()

            if SpectateData and SpectateData.Contains then
                curremt = SpectateData.Start and (ct() - SpectateData.Start) or 0
                record = SpectateData.Best or 0
            else
                curremt = 0
                record = 0
            end

            local formattedTime = ConvertTimeWR(curremt)
            HUD:Draw(2, ob, {
                pos = {Xo, Yo},
                pb = record,
                current = curremt,
                curTp = GetTimePiece(curremt, style),
                recTp = GetTimePiece(record, style),
                velocity = vel
            })
        else
            --print("ERROR")
        end
    else
        local curremt = TIMER:GetTickCount()
        local vel = math.floor(GetClientVelocity(pl))

        if not HUDData[pl] then
            HUDData[pl] = {
                pos = {20, 20},
                sync = 0,
                strafes = 0,
                l = false,
                r = false,
                a = false,
                d = false,
                w = false,
                s = false,
                jump = false,
                duck = false,
                current = 0,
                pb = 0,
            }
        end

        HUD:Draw(2, pl, {
            pos = {Xo, Yo},
            pb = select(1, TIMER:GetPersonalBest(pl, pl.style)) or 0,
            current = curremt,
            curTp = GetTimePiece(curremt, style),
            recTp = GetTimePiece(PBTime, style),
            velocity = vel
        })

        DrawSimpleSideTimer(pl, {pos = {Xo, Yo}, pb = select(1, TIMER:GetPersonalBest(pl, pl.style)) or 0, current = curremt})
    end
end