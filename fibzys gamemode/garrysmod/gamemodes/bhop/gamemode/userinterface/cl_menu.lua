--[[

 _  _  ____  __ _  _  _ 
( \/ )(  __)(  ( \/ )( \
/ \/ \ ) _) /    /) \/ (
\_)(_/(____)\_)__)\____/ ! by fibzy

]]--

-- Cache
local activeButtonSideNav, activeButtonTopNav, f1Pressed, f4Pressed = nil, nil, false, false
local lp, Iv, DrawText, Text, hook_Add = LocalPlayer, IsValid, draw.SimpleText, draw.DrawText, hook.Add
local bhopMenuOpen = CreateConVar("bhop_menu_open", "0", FCVAR_ARCHIVE, "Tracks whether the bhop menu is open.")

-- Lets create the main button
function UI:CreateButton(parent, text, dock, dockMargin, isTopNav, font)
    if not Iv(parent) then return nil end

    local btn = parent:Add("DButton")
    btn:SetText("")
    
    if dock then
        btn:Dock(dock)
        btn:DockMargin(unpack(dockMargin or {0, 0, 0, 0}))
    end
    
    btn.text = text
    btn:SetFont(font or "SmallTextFont")

    local buttonHeight = 40

    btn.PerformLayout = function(self)
        if not isTopNav then 
            self:SetTall(buttonHeight)
        end
    end

    btn.Paint = function(self, w, h)
        local textColor = isTopNav and 
            ((self == activeButtonTopNav) and DynamicColors.PanelColor or colors.text) or
            ((self == activeButtonSideNav) and colors.textActive or colors.text)

        local btnColor = isTopNav and 
            (self:IsHovered() and colors.buttonHover or colors.nav) or 
            (self == activeButtonSideNav and DynamicColors.PanelColor or (self:IsHovered() and colors.buttonHover or colors.button))

        surface.SetDrawColor(btnColor)
        surface.DrawRect(0, 0, w, h)

        local alignX = isTopNav and w / 2 or w / 2 - 85
        local align = isTopNav and TEXT_ALIGN_CENTER or TEXT_ALIGN_LEFT

        if isTopNav then
            DrawText(self.text, self:GetFont(), alignX, h / 3, textColor, align, TEXT_ALIGN_CENTER)
        else
            DrawText(self.text, self:GetFont(), alignX, h / 2, textColor, align, TEXT_ALIGN_CENTER)
        end
    end

    return btn
end

-- Menu playetesters
local clickableWords = {
    ["FiBzY"] = {
        color = Color(255, 50, 50),
        url = "https://steamcommunity.com/id/fibzy_"
    },
    ["obvixus"] = {
        color = Color(50, 150, 255),
        url = "https://steamcommunity.com/id/obvixus"
    },
    ["amne"] = {
        color = Color(186, 85, 211),
        url = "https://steamcommunity.com/id/amne"
    },
    ["oiwer"] = {
        color = Color(255, 255, 0),
        url = "https://steamcommunity.com/id/beehops"
    },
    ["Brandon"] = {
        color = Color(0, 255, 0),
        url = "https://steamcommunity.com/id/usrcmd"
    },
}

local colorWords = {
    ["Cheating"] = Color(255, 100, 0),
    ["Good"] = Color(0, 255, 0),
    ["luck"] = Color(0, 255, 0),
    ["+"] = Color(0, 255, 0),
}

-- Create UI Panel
function UI:CreatePanel(parent, textLines)
    if not Iv(parent) then return nil end

    local pnl = vgui.Create("DPanel", parent)
    pnl:Dock(FILL)
    pnl.clickables = {}

    pnl.Paint = function(self, w, h)
        local y = 10
        local firstEntry = true
        self.clickables = {}

        for i, line in ipairs(textLines) do
            local font = "ui.mainmenu.button"
            local x = 10

            for word in string.gmatch(line, "%S+") do
                local spacing = " "
                local wordClean = word:gsub("[,%s]", "")

                surface.SetFont(font)
                local wordW, wordH = surface.GetTextSize(word .. spacing)

                if clickableWords[wordClean] then
                    local info = clickableWords[wordClean]
                    draw.SimpleText(word .. spacing, font, x, y, info.color, TEXT_ALIGN_LEFT)
                    table.insert(self.clickables, {x = x, y = y, w = wordW, h = wordH, url = info.url})
                elseif colorWords[wordClean] then
                    draw.SimpleText(word .. spacing, font, x, y, colorWords[wordClean], TEXT_ALIGN_LEFT)
                else
                    draw.SimpleText(word .. spacing, font, x, y, colors.text, TEXT_ALIGN_LEFT)
                end

                x = x + wordW
            end

            y = y + 25
            if firstEntry then
                surface.SetDrawColor(120, 120, 120)
                surface.DrawRect(10, y, w - 20, 1)
                y = y + 15
                firstEntry = false
            end
        end
    end

    pnl.OnMousePressed = function(self, mcode)
        local mx, my = self:CursorPos()
        for _, clickable in ipairs(self.clickables) do
            if mx >= clickable.x and mx <= clickable.x + clickable.w and
               my >= clickable.y and my <= clickable.y + clickable.h then
                gui.OpenURL(clickable.url)
            end
        end
    end

    return pnl
end

-- Made for switching each tab
function UI:SwitchPanel(panelContent, newActiveButton, isTopNav)
    if not Iv(ContentPanel) then return end

    ContentPanel:Clear()

    if type(panelContent) == "function" then
        panelContent(ContentPanel)
    else
        self:CreatePanel(ContentPanel, panelContent)
    end

    if isTopNav then
        if Iv(activeButtonTopNav) then
            activeButtonTopNav:InvalidateLayout(true)
        end
        activeButtonTopNav = newActiveButton
    else
        if Iv(activeButtonSideNav) then
            activeButtonSideNav:InvalidateLayout(true)
        end
        activeButtonSideNav = newActiveButton
    end

    if Iv(newActiveButton) then
        newActiveButton:InvalidateLayout(true)
    end
end

-- Updates the side tabs
function UI:UpdateSideNav(buttons)
    if not Iv(NavPanel) then return end

    NavPanel:Clear()
    local createdButtons = {}
    for _, btnInfo in ipairs(buttons) do
        local btn = self:CreateButton(NavPanel, btnInfo.text, TOP, {0, 0, 0, 5}, false, "ui.mainmenu.button")
        if btn then
            btn.DoClick = function()
                self:SwitchPanel(btnInfo.panelContent, btn, false)
            end
            table.insert(createdButtons, btn)
        end
    end
    if #createdButtons > 0 then
        createdButtons[1]:DoClick()
    end
end

-- Lets create the main top tab menu
function UI:CreateTopNavButton(text, sideNavButtons)
    if not Iv(TopNavPanel) then return nil end

    local btn = self:CreateButton(TopNavPanel, text, LEFT, {10, 0, 10, 0}, true, "ui.mainmenu.button-bold")

    btn:SetWide(110)
    btn.DoClick = function()
        self:UpdateSideNav(sideNavButtons)
        if text == "World Records" then
            self:FetchAndDisplayWR()
        end
        if Iv(activeButtonTopNav) then
            activeButtonTopNav:InvalidateLayout(true)
        end
        activeButtonTopNav = btn
        btn:InvalidateLayout(true)
    end
    return btn
end

local function WrapText(font, text, maxWidth)
    surface.SetFont(font)
    local spaceW = surface.GetTextSize(" ")

    local words = string.Explode(" ", text)
    local lines = {}
    local currentLine = ""
    local currentWidth = 0

    for _, word in ipairs(words) do
        local wordW = surface.GetTextSize(word)

        if currentWidth + wordW > maxWidth then
            table.insert(lines, currentLine)
            currentLine = word .. " "
            currentWidth = wordW + spaceW
        else
            currentLine = currentLine .. word .. " "
            currentWidth = currentWidth + wordW + spaceW
        end
    end

    if currentLine ~= "" then
        table.insert(lines, currentLine)
    end

    return lines
end

BHOP.VersionMessage = "Fetching..."

net.Receive("SendVersionDataMenu", function()
    BHOP.VersionMessage = net.ReadString()
end)

-- Main Menu
function UI:CreateMenu()
    if Iv(Frame) then
        if not Frame:IsVisible() then
            Frame:SetVisible(true)
            Frame:MakePopup()
        else
            Frame:SetVisible(false)
        end
        return
    end

    local roundedBoxEnabled = GetConVar("bhop_roundedbox"):GetInt() == 1
    Frame = vgui.Create("DFrame")

    local scale = 0.96
    local baseW, baseH = 1000, 700
    local newW, newH = baseW * scale, baseH * scale
    local offset = 60

    Frame:SetSize(newW, newH)
    Frame:Center()
    Frame:SetTitle("")
    Frame:ShowCloseButton(false)
    Frame:SetDraggable(false)
    Frame:MakePopup()

    Frame.Paint = function(self, w, h)
        surface.SetDrawColor(colors.background)
        if roundedBoxEnabled then
            draw.RoundedBox(10, 0, 0, w - 5, h - 5, colors.background)
        else
            surface.DrawRect(0, 0, w - 5, h - 5)
        end
    end

    TopNavPanel = vgui.Create("DPanel", Frame)
    TopNavPanel:SetHeight(30)
    TopNavPanel:DockMargin(0, -12, 0, 13)
    TopNavPanel:Dock(TOP)

    TopNavPanel.Paint = function(self, w, h)
        surface.SetDrawColor(colors.nav)
        if roundedBoxEnabled then
            draw.RoundedBoxEx(8, 0, 0, w, h, colors.nav, true, true, false, false)
        else
            surface.DrawRect(0, 0, w, h)
        end
    end

    -- Gamemode Info tab
    local InfoButton = self:CreateTopNavButton("Info", {
        { 
            text = "Overview", 
            panelContent = {
                "Information Overview",
                "Gamemode: FiBzY",
                "",
                "Play Testers:",
                "FiBzY",
                "(dev) Tested base gamemode insuring it works correctly.",
                "obvixus",
                "Tested for errors and bugs most help.",
                "amne",
                "Also tested for gamemode bugs.",
                "oiwer",
                "Playtested boosterfix bugs and other problems.",
                "Brandon",
                "Gave input on FPS problems and UI changes.",
            }, 
            isActive = true 
        },
        { 
            text = "Details", 
            panelContent = {
                "Information",
                "Gamemode: Bunny Hop",
                "Version: " .. BHOP.Version.GM,
                "Developed by: FiBzY",
                "Description: Master your jumps and gain momentum by bunny hopping through various maps!",
                "",
                "Last updated: " .. BHOP.Version.LastUpdated,
                "Up-to Date Check: " .. BHOP.VersionMessage
            }
        },
        { 
            text = "Server Info", 
            panelContent = {
                "Stats", 
                "Server Name: " .. BHOP.ServerName,
                "",
                "Map: " .. game.GetMap(),
                "Max Players: " .. game.MaxPlayers() - #player.GetBots(),
                "Current Players: " .. #player.GetAll() - #player.GetBots(),
                "Tickrate: " .. string.format("%.2f",  1 / engine.TickInterval())
            }
        }
    })

    -- Gameplay Tab
    local GameplayButton = self:CreateTopNavButton("Gameplay", {
        { text = "Rules", panelContent = {
            "Rules",
            "1. Cheating is not allowed.",
            "2. No exploiting the gamemode or lua.",
            "3. No DDoS attacks against the server or players.",
            "4. Profanity is mostly allowed, but not directed at users."
        }, isActive = true },

        { text = "Tutorial", panelContent = {
            "1. Movement Basics:",
            "Use W to move forward, and A or D to strafe left or right.",
            "While strafing, move your mouse in the same direction to gain speed.",
            "Practice moving in a smooth, side-to-side motion to maintain momentum.",
            "",
            "2. Auto-Hop:",
            "In this gamemode, you don't need to scroll or spam jump.",
            "Just hold Space to continuously hop, allowing you to focus on strafing.",
            "",
            "3. Advanced Techniques:",
            "Mastering strafing is key to building speed. Try changing between A + mouse left and D + mouse right.",
            "Avoid sharp or jerky movements, as smooth strafes will help you maintain speed.",
            "",
            "4. Improvement Tips:",
            "Watch experienced players and learn from their movements.",
            "Use practice mode to master tricky sections.",
            "Keep an eye on your speed and aim to improve it with each run.",
            "",
            "Good luck, and most importantly, have fun!"
        } },

        { text = "Tips", panelContent = {
            "Tips",
            "When strafing left + A, move your mouse to the left.",
            "When strafing right + D, move your mouse to the right.",
            "This strafing technique helps maintain and build speed."
        } },

        { text = "World Records", panelContent = function() self:FetchAndDisplayWR() end },
        { text = "Ranks", panelContent = function(parent) self:CreateRankPanel(parent) end },

        { 
            text = "Styles", 
            panelContent = function(parent)
            local scrollPanel = vgui.Create("DScrollPanel", parent)
            scrollPanel:Dock(FILL)
            local vBar = scrollPanel:GetVBar()
            UI:MenuScrollbar(vBar)

            local container = vgui.Create("DPanel", scrollPanel)
            container:Dock(TOP)
            container:SetTall(50)
            container.Paint = function(self, w, h)
                draw.SimpleText("Styles", "ui.mainmenu.button", 10, 10, color_white, TEXT_ALIGN_LEFT)
                surface.SetDrawColor(120, 120, 120)
                surface.DrawRect(10, 35, w - 20, 1)
            end

            local styleList = vgui.Create("DIconLayout", scrollPanel)
            styleList:Dock(FILL)
            styleList:SetSpaceY(5)
            styleList:SetSpaceX(5)
            styleList:DockMargin(10, 0, 10, 10)

            for index, data in ipairs(TIMER.Styles) do
                local styleName = data[1]
                local command = data[3][1]
                local description = TIMER.StyleInfo[index] or "No description added."

                local btn = styleList:Add("DButton")
                btn:SetText("")

                local textWrapW = 250
                local descLines = WrapText("ui.mainmenu.button", description, textWrapW)
                local buttonHeight = 20 + (#descLines * 15) + 10

                btn:SetSize(350, math.max(50, buttonHeight))

                btn.Paint = function(self, w, h)
                    local hoverCol = self:IsHovered() and Color(60, 60, 60, 255) or Color(40, 40, 40, 255)
                    draw.RoundedBox(0, 0, 0, w, h, hoverCol)
                    draw.SimpleText(styleName, "ui.mainmenu.button", 10, 5, color_white, TEXT_ALIGN_LEFT)

                    local yOffset = 25
                    for _, line in ipairs(descLines) do
                        draw.SimpleText(line, "ui.mainmenu.button", 10, yOffset, Color(200, 200, 200), TEXT_ALIGN_LEFT)
                        yOffset = yOffset + 44
                    end
                end

                btn.DoClick = function()
                    lp():ConCommand("say !" .. command)
    
                    if Iv(Frame) then
                        Frame:SetVisible(false)
                        Frame:Remove()
                    end

                    RunConsoleCommand("bhop_menu_open", "0")
                end
            end
        end
    },
    })

    -- If we want scrollable or not
    local function createPanelWithScrollOrNot(parent, panelHeight)
        local availableHeight = parent:GetTall()

        if panelHeight > availableHeight then
            local scrollPanel = vgui.Create("DScrollPanel", parent)
            scrollPanel:Dock(FILL)
            scrollPanel.Paint = function(self, w, h)
                surface.SetDrawColor(colors.content)
                surface.DrawRect(0, 0, w, h)
            end
            return scrollPanel
        else
            local container = vgui.Create("DPanel", parent)
            container:Dock(FILL)
            container.Paint = function(self, w, h)
                surface.SetDrawColor(colors.content)
                surface.DrawRect(0, 0, w, h)
            end
            return container
        end
    end

    -- Settings Tab
    local SettingsButton = self:CreateTopNavButton("Settings", {
    { text = "Settings", panelContent = function(parent)
        local scrollPanel = vgui.Create("DScrollPanel", parent)
        scrollPanel:Dock(FILL)

        scrollPanel.Paint = function(self, w, h)
            surface.SetDrawColor(colors.content)
            surface.DrawRect(0, 0, w, h)
        end

        local vBar = scrollPanel:GetVBar()
        UI:MenuScrollbar(vBar)

        local container = vgui.Create("DPanel", scrollPanel)
        container:SetSize(parent:GetWide() - 20, 830)
        container:SetPos(0, 0)
        container.Paint = function(self, w, h)
            surface.SetDrawColor(colors.content)
            surface.DrawRect(0, 0, w, h)
        end

        local x, y = 10, 0
        self:CreatePanel(container, {"Settings"})

        y = y + 45
        self:CreateToggle(container, y, "bhop_disablespec", "Spectator Hud", "This will enable or disable the spectator hud.")
        y = y + offset
        self:CreateToggle(container, y, "bhop_weaponpickup", "Weapons Pickup", "This will enable or disable weapon pickup.")
        y = y + offset
        self:CreateToggle(container, y, "bhop_flipweapons", "Flip Weapons", "Flips your weapons to the left side.")
        y = y + offset
        self:CreateToggle(container, y, "bhop_showkeys", "Show Keys", "This displays the keys hud.")
        y = y + offset
        self:CreateToggle(container, y, "bhop_showchatbox", "Chatbox Visibility", "Enables or disables chatbox completely.")
        y = y + offset
        self:CreateToggle(container, y, "bhop_timer_prefix_rainbow", "Rainbow Timer Chat", "Enables or disables rainbow timer prefix.")
        y = y + offset
        self:CreateToggle(container, y, "bhop_smoothnoclip", "Smooth Noclip", "Enables or disables noclip smoothing.", { default = 1, off = 0 })
        y = y + offset
        self:CreateToggle(container, y, "bhop_nosway", "Weapon Sway", "Controls how weapon view models move.")
        y = y + offset
        self:CreateToggle(container, y, "bhop_autoshoot", "Auto Shoot", "Enables or disables weapon auto spammer.")
        y = y + offset
        self:CreateToggle(container, y, "bhop_alwaysshowtriggers", "Always Show Triggers", "Enables or disables showtriggers on spawn.")
        y = y + offset
        self:CreateToggle(container, y, "bhop_joindetails", "Join Details", "Enables or disables joining details in chat.")
        y = y + offset
        self:CreateInputBox(container, y, "bhop_hints", 5, "Hints Time", "How long you want hints to display in minutes.")
        y = y + offset

        local ConvarDefaults = {
            ["bhop_anticheats"] = "0",
            ["bhop_gunsounds"] = "1",
            ["bhop_hints"] = "5",
            ["bhop_set_fov"] = "90",
            ["bhop_wrsfx"] = "1",
            ["bhop_wrsfx_volume"] = "0.4",
            ["bhop_wrsfx_bad"] = "1",
            ["bhop_chatsounds"] = "0",
            ["bhop_zonesounds"] = "1",
            ["bhop_showplayerslabel"] = "1",
            ["bhop_autoshoot"] = "1",
            ["bhop_joindetails"] = "1",
            ["bhop_simpletextures"] = "0",
            ["bhop_sourcesensitivity"] = "0",
            ["bhop_absolutemousesens"] = "0",
            ["bhop_showchatbox"] = "1",
            ["bhop_nogun"] = "0",
            ["bhop_nosway"] = "1",
            ["bhop_showplayers"] = "1",
            ["bhop_viewtransfrom"] = "0",
            ["bhop_thirdperson"] = "0",
            ["bhop_viewpunch"] = "1",
            ["bhop_weaponpickup"] = "1",
            ["bhop_viewinterp"] = "0",
            ["bhop_water_toggle"] = "0"
        }

        self:CreateResetAllButton(container, y, ConvarDefaults, "Reset All Settings", "This will restore all your bhop settings to default.")
    end, isActive = true },

    -- Graphics Tab
    { text = "Graphics", panelContent = function(parent)
        local scrollPanel = vgui.Create("DScrollPanel", parent)
        scrollPanel:Dock(FILL)

        scrollPanel.Paint = function(self, w, h)
            surface.SetDrawColor(colors.content)
            surface.DrawRect(0, 0, w, h)
        end

        local vBar = scrollPanel:GetVBar()
        UI:MenuScrollbar(vBar)

        local container = vgui.Create("DPanel", scrollPanel)
        container:SetSize(parent:GetWide() - 20, 1000)
        container:SetPos(0, 0)
        container.Paint = function(self, w, h)
            surface.SetDrawColor(colors.content)
            surface.DrawRect(0, 0, w, h)
        end

        local x, y = 10, 0
        self:CreatePanel(container, {"Graphics"})

        y = y + 45
        self:CreateToggle(container, y, "gmod_mcore_test", "Gmod Multi Core", "This may improve performance by utilizing multiple cores.")
        y = y + offset
        self:CreateToggle(container, y, "mat_antialias", "Antialias", "This may improve performance by disabling antialias.", { default = 8, off = 0 })
        y = y + offset
        self:CreateToggle(container, y, "bhop_enablefpsboost", "Fps Boost", "This may improve performance by running commands to improve fps.", { default = 1, off = 0 })
        y = y + offset
        self:CreateToggle(container, y, "bhop_showzones", "Display Zones", "Show or hide the timer zones.")
        y = y + offset
        self:CreateInputBox(container, y, "bhop_thickness", 1, "Zones Thickness", "How thick you want the zones to be.")
        y = y + offset
        self:CreateToggle(container, y, "bhop_flatzones", "Display Flat Zones", "Change to flat zones zones.")
        y = y + offset
        self:CreateToggle(container, y, "bhop_wireframe", "Zones Wireframe", "Shows zones in wireframe.")
        y = y + offset
        self:CreateToggle(container, y, "bhop_anticheats", "Show AC Zones", "Show or hide the anti-cheat timer zones.")
        y = y + offset
        self:CreateToggle(container, y, "bhop_showplayers", "Show Players", "Show or hide the players.")
        y = y + offset
        self:CreateToggle(container, y, "bhop_showplayerslabel", "Show Players Labels", "Show or hide the player labels.")
        y = y + offset
        self:CreateToggle(container, y, "r_WaterDrawReflection", "Toggle Reflection", "This may improve performance by toggling off reflection.", { default = 1, off = 0 })
        y = y + offset
        self:CreateToggle(container, y, "r_WaterDrawRefraction", "Toggle Refraction", "This may improve performance by toggling off refraction.", { default = 1, off = 0 })
        y = y + offset
        self:CreateToggle(container, y, "bhop_map_fog", "Map Fog", "This may make it easier to see by disabling map fog.")
        y = y + offset
        self:CreateToggle(container, y, "bhop_nogun", "No gun toggle", "This will allow you to use guns without seeing them.")
        y = y + offset
        self:CreateToggle(container, y, "bhop_fullbright", "Full bright toggle", "This will allow you to see the map in full bright when flashlight is pressed.")
        y = y + offset
        self:CreateToggle(container, y, "bhop_enable_map_colors", "Custom map colors", "Enables or disables the custom map color changes.")
    end },

      -- SSJ Tab
      { text = "SSJ", panelContent = function(parent)
        local scrollPanel = vgui.Create("DScrollPanel", parent)
        scrollPanel:Dock(FILL)

        local vBar = scrollPanel:GetVBar()
        UI:MenuScrollbar(vBar)

        local container = vgui.Create("DPanel", scrollPanel)
        container:SetSize(parent:GetWide() - 20, 650)
        container:SetPos(0, 0)
        container.Paint = function(self, w, h)
            surface.SetDrawColor(colors.content)
            surface.DrawRect(0, 0, w, h)
        end

        local x, y = 10, 0
        self:CreatePanel(container, {"SSJ"})
    
        surface.SetDrawColor(120, 120, 120)
        surface.DrawRect(10, y + 35, container:GetWide() - 20, 1)

        y = y + 45
        self:CreateToggle(container, y, "bhop_showssj", "Display SSJ", "Enables or disables show jump stats in chat.", { default = 1, off = 0 })
        y = y + offset
        self:CreateToggle(container, y, "bhop_showpre", "Display Prestrafe", "Enables or disables prestrafe in chat.", { default = 1, off = 0 })
        y = y + offset
        self:CreateToggle(container, y, "bhop_fjt", "Display FJT", "Enables or disables the strafe ground tick.")
        y = y + offset
        self:CreateToggle(container, y, "bhop_showfjthud", "First jump tick HUD", "Enables or disables jump tick HUD.")
        y = y + offset
        self:CreateInputBoxText(container, y, "bhop_jhud_style", "claz", "JHUD Choose a Style", "JHUD style picker 'jcs', 'kawaii', 'claz', 'old'")
        y = y + offset
        self:CreateToggle(container, y, "bhop_jhud", "Display JHUD", "Enables or disables SSJ HUD.")
        y = y + offset
        self:CreateToggle(container, y, "bhop_jhudold", "Display JHUD Old", "Enables or disables the older SSJ MMod HUD from 2020.")
        y = y + offset
        self:CreateInputBox(container, y, "bhop_ssj_fadeduration", 1.5, "SSJ Fade Duration", "How long until the SSJ HUD fades out.")
        y = y + offset
        self:CreateToggle(container, y, "bhop_center_speed", "Display center speed", "Enables or disables the center speed.")
    end },

    -- Strafe Trainer Tab
    { text = "Strafe Trainer", panelContent = function(parent)
        local x, y = 10, 0
        self:CreatePanel(parent, {"Strafe Trainer"})
        y = y + 45
        self:CreateToggle(parent, y, "bhop_strafetrainer", "Display Strafe Trainer", "Enables or disables show strafe trainer.")
        y = y + offset
        self:CreateInputBox(parent, y, "bhop_strafetrainer_interval", 10, "Update rate", "Update rate in ticks.", 1, 100)
        y = y + offset
        self:CreateToggle(parent, y, "bhop_strafetrainer_ground", "Ground Update", "Should update on ground.")
        y = y + offset
        self:CreateToggle(parent, y, "bhop_strafesync", "Strafe Synchronizer", "Enables or disables show strafe synchronizer.")
    end },

    -- Auto Tab
    { text = "Audio", panelContent = function(parent)

        local scrollPanel = vgui.Create("DScrollPanel", parent)
        scrollPanel:Dock(FILL)

        local vBar = scrollPanel:GetVBar()
        UI:MenuScrollbar(vBar)

        local container = vgui.Create("DPanel", scrollPanel)
        container:SetSize(parent:GetWide() - 20, 650)
        container:SetPos(0, 0)
        container.Paint = function(self, w, h)
            surface.SetDrawColor(colors.content)
            surface.DrawRect(0, 0, w, h)
        end

        local x, y = 10, 0
        self:CreatePanel(container, {"Audio"})
        y = y + 45
        self:CreateToggle(container, y, "bhop_chatsounds", "Chat Sounds", "Enables or disables chat sounds on messages.")
        y = y + offset
        self:CreateToggle(container, y, "bhop_timerchatsound", "Chat Timer Sounds", "Enables or disables chat timer sounds on messages.")
        y = y + offset
        self:CreateToggle(container, y, "bhop_ui_sounds", "UI Sounds", "Enables or disables UI sounds in menus.")
        y = y + offset
        self:CreateToggle(container, y, "bhop_mute_music", "Disable Map Music", "Use if you want to disable music on all maps.")
        y = y + offset
        self:CreateToggle(container, y, "bhop_gunsounds", "Gun Sounds", "Enables or disables weapon sounds.")
        y = y + offset
        self:CreateInputBoxText(container, y, "bhop_footsteps", "on", "Footsteps", "Options: 'off', 'local', 'spectate', 'all'.")
        y = y + offset
        self:CreateToggle(container, y, "bhop_zonesounds", "Zone sounds", "Enables or disables zone sounds on leave.")
        y = y + offset
        self:CreateToggle(container, y, "bhop_wrsfx", "WR Sounds", "Enables or disables the World Record sounds.")
        y = y + offset
        self:CreateInputBox(container, y, "bhop_wrsfx_volume", "0.4", "WR Sounds Volume", "Customize your WR sound volume, 1 is loud 0.4 is default.")
        y = y + offset
        self:CreateToggle(container, y, "bhop_wrsfx_bad", "Bad Improvement Sounds", "Enables or disables the bad improvement sounds.")
    end },

    -- Controls Tab
    { text = "Controls", panelContent = function(parent)
        local x, y = 10, 0
        self:CreatePanel(parent, {"Controls"})
        y = y + 45
        self:CreateToggle(parent, y, "bhop_viewtransfrom", "View Transfrom View", "Enables or disables transfrom viewing.")
        y = y + offset
        self:CreateToggle(parent, y, "bhop_thirdperson", "Third Person View", "Enables or disables the third person view.")
        y = y + offset
        self:CreateToggle(parent, y, "bhop_viewinterp", "View Interpolation", "Enables or disables interpolation view.")
        y = y + offset
        self:CreateToggle(parent, y, "bhop_viewpunch", "View Punch", "Enables or disables view punch.")
        y = y + offset
        self:CreateToggle(parent, y, "bhop_sourcesensitivity", "CS:S Sensitivity", "Enables or disables CS:S Sensitivity. (3.125% Slower)")
    end }
    })
    
    -- Now lets to Interface Tab
    local InterfaceButton = self:CreateTopNavButton("User Interface", {

        -- Themes
        { text = "Themes", panelContent = function(parent)
            local x, y = 10, 0
            self:CreatePanel(parent, {"Themes"})
            y = y + 45
            local options = {
                ["hud.css"] = "CS:S Kawaii",
                ["hud.flow"] = "Flow Network",
                ["hud.momentum"] = "Momentum Hud",
                ["hud.simple"] = "Simple HUD",
                ["hud.stellar"] = "Stellar Mod HUD",
                ["hud.shavit"] = "CS:S Shavit HUD"
            }

            self:CreateCustomDropdown(parent, y, "Select HUD Theme", "Choose a style for your HUD you want to use", options)

            y = y + 300
            self:CreateThemeToggle(parent, y, 0, "Disable UI")
        end, isActive = true },

        -- UI Layouts
        { text = "Layouts", panelContent = function(parent)
            local scrollPanel = vgui.Create("DScrollPanel", parent)
            scrollPanel:Dock(FILL)

            local vBar = scrollPanel:GetVBar()
            UI:MenuScrollbar(vBar)
            local x, y = 10, 0

            local container = vgui.Create("DPanel", scrollPanel)
            container:SetSize(parent:GetWide() - 20, 650)
            container:SetPos(0, 0)
            container.Paint = function(self, w, h)
                surface.SetDrawColor(colors.content)
                surface.DrawRect(0, 0, w, h)
            end

            surface.SetDrawColor(120, 120, 120)
            surface.DrawRect(10, y + 35, container:GetWide() - 20, 1)

            self:CreatePanel(container, {"Layouts"})
            y = y + 45
            self:CreateToggle(container, y, "bhop_sidetimer", "Side Timer", "Enables or disables side timer.")
            y = y + offset
            self:CreateToggle(container, y, "bhop_show_notifications", "Pop-up Notifications", "Enables or disables pop-up notifications.")
            y = y + offset
            self:CreateToggle(container, y, "bhop_roundedbox", "Rounded Boxes", "Enables or disables rounded boxes.")
            y = y + offset
            self:CreateToggle(container, y, "bhop_simplebox", "Simple HUD Boxes", "Enables or disables simple HUD boxes.")
            y = y + offset
            self:CreateToggle(container, y, "bhop_rainbowtext", "Rainbow HUD", "Enables or disables rainbow HUD text.")
            y = y + offset
            self:CreateToggle(container, y, "bhop_chatbox", "Custom Chatbox", "Enables or disables the custom chat box.")
            y = y + offset
            self:CreateToggle(container, y, "bhop_netgraph", "Net Graph", "Enables or disables the custom net graph.")
            y = y + offset
            self:CreateToggle(container, y, "bhop_ramp_o_meter", "Ramp-o-Meter", "Enables or disables the ramp meter.")
            y = y + offset
            self:CreateToggle(container, y, "bhop_rampometer_percent", "Ramp-o-Meter Percent", "If you want to see the meter in percentage.")
            y = y + offset
            self:CreateToggle(container, y, "bhop_bash2_screen", "Bash2 Screen Logs", "If you want to see Bash2 logs on screen.")
        end },

        -- Colors to pick
        { text = "Colors", panelContent = function(parent)
        local x, y = 10, 0
            self:CreatePanel(parent, {"Colors"})
            y = y + 45
            self:CreateToggle(parent, y, "bhop_use_custom_color", "Use a soild color", "Enables or disables soild color for UI.")
            y = y + offset
            self:ColorBox(parent, y, "bhop_color", "Main Color", "Color for all UI highlights.")
            y = y + 80
        end },

        -- Preset themes
        { text = "Presets", panelContent = function(parent)
            local x, y = 10, 0
            self:CreatePanel(parent, {"Presets Picker"})
            y = y + 45

            local optionsnui = {
                ["nui.kawaii"] = "Kawaii",
                ["nui.css"] = "CS:S"
            }

            self:CreateCustomDropdownPreset(parent, y, "Select Nui Theme", "Choose a style for your nui you want to use", optionsnui)

            y = y + 80

            local optionsnsb = {
                ["default"] = "Default",
                ["kawaii"] = "Kawaii",
                ["flow"] = "Flow Network"
            }

            self:CreateCustomDropdownSB(parent, y, "bhop_scoreboard", "Select Scoreboard", "Choose a style for your scoreboard you want to use", optionsnsb)
        end },

        -- Misc stuff
        { text = "Misc", panelContent = function(parent)
            local x, y = 10, 0
            self:CreatePanel(parent, {"Miscellaneous"})
            y = y + 45
            self:CreateToggle(parent, y, "bhop_boxgraph", "Box Graph", "Enables or disables box graph angles.")
            y = y + offset
            self:CreateToggle(parent, y, "bhop_graphminecraft", "Box Graph Minecaft", "Enables or disables box graph angles minecraft style.")
            y = y + offset
            self:CreateToggle(parent, y, "bhop_centerbox_pos", "Center Box Postion", "Enables or disables a box under the player.")
            y = y + offset
            self:CreateToggle(parent, y, "bhop_landing_prediction", "Landing Prediction", "Enables or disables landing prediction display.")
            y = y + offset
            self:CreateToggle(parent, y, "bhop_showpeakheight", "Show Peak Height", "Enables or disables the peak height display.")
            y = y + offset
            self:CreateToggle(parent, y, "bhop_perfprinter", "Perfect Printer", "Enables or disables the jump tracker for scrolling.")
            y = y + offset           
        end },
    })

    -- Admin Tab
    if lp():IsAdmin() then
        local AdminButton = self:CreateTopNavButton("Admin", {
            { text = "Users", panelContent = function(parent)
                local x, y = 10, 0
                self:CreatePanel(parent, {"Admin user management"})
                self:UpdatePlayerList(parent)
            end, isActive = true },

            -- Show all logs
            { text = "Logs", panelContent = function(parent)
                local x, y = 10, 0
                self:CreatePanel(parent, {"View server logs"})

                if lp():GetNWInt("PlayerRank", 0) == 64 then
                    UI.CurrentLogsPanel = parent

                    -- request the logs
                    NETWORK:StartNetworkMessage(nil, "RequestAdminLogs")

                    UI:UpdateServerLogs(parent, {})
                else
                    local noAccess = vgui.Create("DLabel", parent)
                    noAccess:SetText("You don’t have access to see logs.")
                    noAccess:SetFont("ui.mainmenu.button")
                    noAccess:SetColor(Color(255, 80, 80))
                    noAccess:SetPos(10, 40)
                    noAccess:SizeToContents()
                end
            end },

            { text = "Timer", panelContent = function(parent)
                local x, y = 10, 0
                self:CreatePanel(parent, {"Admin Timer"})

                if lp():GetNWInt("PlayerRank", 0) == 64 or 9 then
                    UI:UpdateAdminSettings(parent)
                else
                    local noAccess = vgui.Create("DLabel", parent)
                    noAccess:SetText("You don’t have timer access to this.")
                    noAccess:SetFont("ui.mainmenu.button")
                    noAccess:SetColor(Color(255, 80, 80))
                    noAccess:SetPos(10, 40)
                    noAccess:SizeToContents()
                end
            end },

            -- Admin Settings
            { text = "Settings", panelContent = function(parent)
                local x, y = 10, 0
                self:CreatePanel(parent, {"Admin settings"})

                y = y + 45
                if lp():GetNWInt("PlayerRank", 0) == 64 or 9 then
                    self:CreateInputBoxSettings(parent, y, "bhop_settings_zonecap", 290, "Zone speed cap", "Changes speed cap in start zones.")
                    y = y + 60
                    self:CreateInputBoxSettings(parent, y, "bhop_admin_mapmultiplier", 15, "Set map points", "Sets or changes the points for the map.")
                    y = y + 60
                    self:CreateInputBox(parent, y, "bhop_snap_grid_size", 2, "Set Snap Grid Size", "Sets the snapping of the live zone placement.")
                else
                    local noAccess = vgui.Create("DLabel", parent)
                    noAccess:SetText("You don’t have settings access to this.")
                    noAccess:SetFont("ui.mainmenu.button")
                    noAccess:SetColor(Color(255, 80, 80))
                    noAccess:SetPos(10, 40)
                    noAccess:SizeToContents()
                end
            end },

            -- Movement Settings
            { text = "Movement Settings", panelContent = function(parent)
                local x, y = 10, 0
                self:CreatePanel(parent, {"Movement configurations"})
                y = y + 45

                if lp():GetNWInt("PlayerRank", 0) == 64 then
                    self:CreateInputBoxSettings(parent, y, "bhop_settings_cap", 100, "Airaccel rate", "Changes movements airaccel rate.")
                    y = y + offset
                    self:CreateInputBoxSettings(parent, y, "bhop_settings_mv", 32.4, "Speed Cap", "Changes movement speed air cap.")
                    y = y + offset
                    self:CreateInputBoxSettings(parent, y, "bhop_settings_maxspeed", 250, "Max speed", "Changes movements max speed cap.")
                    y = y + offset
                    self:CreateInputBoxSettings(parent, y, "bhop_settings_jumppower", 290, "Jump Height", "Changes movements jump height.")
                    y = y + offset
                    self:CreateInputBoxSettings(parent, y, "bhop_movement_crouchboosting", 1, "Crouch Boosting", "Enables Crouch Boosting.")
                    y = y + offset
                    self:CreateInputBoxSettings(parent, y, "bhop_movement_rngfix", 1, "RNGFix", "Enables RNGFix (Recommended keep on).")
                    y = y + offset
                    self:CreateInputBoxSettings(parent, y, "bhop_movement_rampfix", 1, "Ramp Fix", "Enables Surf Ramp Fix (Recommended keep on).")
                else
                    local noAccess = vgui.Create("DLabel", parent)
                    noAccess:SetText("You don’t have access to change movement settings.")
                    noAccess:SetFont("ui.mainmenu.button")
                    noAccess:SetColor(Color(255, 80, 80))
                    noAccess:SetPos(10, 40)
                    noAccess:SizeToContents()
                end
            end },
        })
    end
    
    ContentPanel = vgui.Create("DPanel", Frame)
    ContentPanel:Dock(FILL)
    ContentPanel.Paint = function(self, w, h)
        surface.SetDrawColor(colors.content)
        surface.DrawRect(0, 0, w, h)
    end

    NavPanel = vgui.Create("DPanel", Frame)
    NavPanel:SetWidth(200)
    NavPanel:Dock(LEFT)
    NavPanel:DockMargin(-5, 0, 0, 0)
    NavPanel.Paint = function(self, w, h)
        surface.SetDrawColor(colors.sideNav)
        surface.DrawRect(0, 0, w, h)
    end

    -- Draw Close X
    local CloseButton = vgui.Create("DButton", Frame)
    CloseButton:SetText("")
    CloseButton:SetSize(24, 24)
    CloseButton:SetPos(Frame:GetWide() - 28, 4)
    CloseButton.Paint = function(self, w, h)
        surface.SetDrawColor(0, 0, 0, 0)
        surface.DrawRect(0, 0, w, h)

        local xColor = self:IsHovered() and Color(255, 50, 50) or colors.text

        draw.SimpleText("X", "ui.mainmenu.desc", w / 2, h / 2, xColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    CloseButton.DoClick = function()
        Frame:Close()
        activeButtonTopNav = nil
        activeButtonSideNav = nil
        RunConsoleCommand("bhop_menu_open", "0")
    end

    -- Draw player avatar and name
    BuildCircularAvatarPic(Frame, Frame:GetWide() - 144, 8, 22, lp():SteamID64())

    local steamID64 = lp():SteamID64()
    local profileURL = "https://steamcommunity.com/profiles/" .. steamID64

    local playerNameLabel = vgui.Create("DLabel", Frame)
    playerNameLabel:SetText(lp():Nick())
    playerNameLabel:SetFont("ui.mainmenu.button-bold")
    playerNameLabel:SetTextColor(Color(0, 150, 255))
    playerNameLabel:SizeToContents()
    playerNameLabel:SetPos(Frame:GetWide() - 136 + 36 + 10, 22)
    playerNameLabel:SetCursor("hand")
    playerNameLabel:SetMouseInputEnabled(true)

    playerNameLabel.OnMousePressed = function()
        gui.OpenURL(profileURL)
    end

    playerNameLabel.OnCursorEntered = function()
        playerNameLabel:SetTextColor(Color(255, 50, 50))
    end
    playerNameLabel.OnCursorExited = function()
        playerNameLabel:SetTextColor(Color(0, 150, 255))
    end

    InfoButton:DoClick()
end

-- Update points
local cachedSum = nil
NETWORK:GetNetworkMessage("UpdatePointsSum", function(_, data)
    local pointsSum = math.Round(data[1])

    if Iv(lp()) then
        lp().Sum = pointsSum
    else
        cachedSum = pointsSum
    end
end)

-- Load Points on start
hook.Add("InitPostEntity", "AssignCachedPointsSum", function()
    if cachedSum and Iv(lp()) then
        lp().Sum = cachedSum
        cachedSum = nil
    end
end)

-- Rank Panel List
function UI:CreateRankPanel(parent)
    if not Iv(parent) then return end

    local panelWidth = parent:GetWide()
    local rankCount = #TIMER.Ranks
    local halfRankCount = math.ceil(rankCount / 2)
    local rankDisplayLeft = {}
    local rankDisplayRight = {}

    for i = 1, halfRankCount do
        local rank = TIMER.Ranks[i]
        table.insert(rankDisplayLeft, {rank[1], rank[2], i})
    end
    for i = halfRankCount + 1, rankCount do
        local rank = TIMER.Ranks[i]
        table.insert(rankDisplayRight, {rank[1], rank[2], i})
    end

    local pnl = vgui.Create("DPanel", parent)
    pnl:Dock(FILL)
    pnl.Paint = function(self, w, h)
        local y = 10

        Text("Ranks", "ui.mainmenu.button", 15, y, colors.text, TEXT_ALIGN_LEFT)
        surface.SetDrawColor(120, 120, 120)
        surface.DrawRect(15, y + 25, w - 30, 1)
        y = y + 50

        Text("Displaying " .. rankCount .. " Ranks", "ui.mainmenu.button", 15, y - 10, Color(200, 200, 200), TEXT_ALIGN_LEFT)
        y = y + 25

        -- DO TO: Finish Dropdowns here for pl.mode

        local tableMargin = 20
        local tableX, tableY = tableMargin, y
        local tableWidth, tableHeight = w - (tableMargin * 2), 40 + (rankCount * 14)

        surface.SetDrawColor(38, 38, 38)
        surface.DrawRect(tableX, tableY, tableWidth, tableHeight)

        local titleHeight = 30
        surface.SetDrawColor(32, 32, 32)
        surface.DrawRect(tableX, tableY, tableWidth, titleHeight)

        Text("Rank", "ui.mainmenu.button", tableX + 10, tableY + 10 - 3, Color(200, 200, 200), TEXT_ALIGN_LEFT)
        Text("Name", "ui.mainmenu.button", tableX + 100, tableY + 10 - 3, Color(200, 200, 200), TEXT_ALIGN_LEFT)

        Text("Rank", "ui.mainmenu.button", tableX + 10 + 340, tableY + 10 - 3, Color(200, 200, 200), TEXT_ALIGN_LEFT)
        Text("Name", "ui.mainmenu.button", tableX + 100  + 345, tableY + 10 - 3, Color(200, 200, 200), TEXT_ALIGN_LEFT)

        surface.SetDrawColor(150, 150, 150, 50)
        surface.DrawRect(tableX, tableY + titleHeight, tableWidth, 1)
        tableY = tableY + titleHeight + 10

        local yLeft, yRight = tableY, tableY
        local xLeft, xRight = tableX + 10, tableX + (tableWidth / 2) + 10

        if rankCount == 0 then
            Text("No Ranks Found", "ui.mainmenu.button", tableX + 10, tableY, Color(255, 0, 0), TEXT_ALIGN_LEFT)
        else
            for i, rank in ipairs(rankDisplayLeft) do
                local rankName, rankColor, rankNumber = rank[1], rank[2], rank[3]
                Text(rankNumber .. ".", "ui.mainmenu.button", xLeft, yLeft, Color(255, 255, 255), TEXT_ALIGN_LEFT)
                Text(rankName, "ui.mainmenu.button", xLeft + 90, yLeft, rankColor, TEXT_ALIGN_LEFT)
                yLeft = yLeft + 25
            end

            for i, rank in ipairs(rankDisplayRight) do
                local rankName, rankColor, rankNumber = rank[1], rank[2], rank[3]
                Text(rankNumber .. ".", "ui.mainmenu.button", xRight, yRight, Color(255, 255, 255), TEXT_ALIGN_LEFT)
                Text(rankName, "ui.mainmenu.button", xRight + 90, yRight, rankColor, TEXT_ALIGN_LEFT)
                yRight = yRight + 25
            end
        end

        local statsY = math.max(yLeft, yRight) + 20
        surface.SetDrawColor(32, 32, 32)
        surface.DrawRect(tableX, statsY, tableWidth, 30)

        Text("Your Stats:", "ui.mainmenu.button", tableX + 10, statsY + 10 - 3, Color(200, 200, 200), TEXT_ALIGN_LEFT)

        TIMER.ranking = {}

        if TIMER.ranking then
            local playerRank = lp():GetNWInt("Rank", 0)
            local playerPoints = lp().Sum or 0

            Text("Rank: " .. playerRank, "ui.mainmenu.button", tableX + 150, statsY + 10 - 3, Color(255, 255, 255), TEXT_ALIGN_LEFT)
            Text("Total Points: " .. playerPoints, "ui.mainmenu.button", tableX + 250, statsY + 10 - 3, Color(255, 255, 255), TEXT_ALIGN_LEFT)
        else
            Text("Waiting for Ranking stats...", "ui.mainmenu.button", tableX + 150, statsY + 10 - 3, Color(255, 0, 0), TEXT_ALIGN_LEFT)
        end
    end

    return pnl
end

UI.StyleLookup = {}

function UI:FetchAndDisplayWR(styleID)
    local style = styleID or "N"
    net.Start("RequestWRList")
    net.WriteString(game.GetMap())
    net.WriteString(style)
    net.WriteInt(1, 32) -- page default to 1
    net.SendToServer()
end

net.Receive("WRList", function()
    local data = net.ReadTable()
    local records = data.records
    local page = data.page
    local total = data.total

    UI.WRList = {}
    for i, record in ipairs(records) do
        table.insert(UI.WRList, {record[1], record[2]})
    end

    if Iv(ContentPanel) then
        ContentPanel:Clear()
        UI:CreateWRPanel(ContentPanel)
    else
        print("ERROR: ContentPanel missing!")
    end
end)

-- WR List Menu
UI.StyleLookup = {}
UI.SelectedStyle = "n"

function UI:FetchAndDisplayWR(styleID)
    local style = styleID or "n"
    UI.SelectedStyle = style
    net.Start("RequestWRList")
    net.WriteString(game.GetMap())
    net.WriteString(style)
    net.WriteInt(1, 32)
    net.SendToServer()
end

net.Receive("WRList", function()
    local data = net.ReadTable()
    local records = data.records
    local page = data.page
    local total = data.total

    UI.WRList = {}
    for i, record in ipairs(records) do
        table.insert(UI.WRList, {record[1], record[2]})
    end

    if Iv(ContentPanel) then
        ContentPanel:Clear()
        UI:CreateWRPanel(ContentPanel)
    end
end)

function UI:CreateWRPanel(parent)
    if not Iv(parent) then return end

    local playerName = lp():Nick()
    local panelWidth = parent:GetWide()
    local recordCount = #UI.WRList or 0
    local lastPlace = recordCount

    local pnl = vgui.Create("DPanel", parent)
    pnl:Dock(FILL)

    local combo = vgui.Create("DComboBox", pnl)
    combo:SetPos(panelWidth - 200, 45)
    combo:SetSize(180, 22)

    UI.StyleLookup = {}
    local selectedIndex = 0

    for index, data in ipairs(TIMER.Styles) do
        local styleName = data[1]
        local command = data[3][1]
        UI.StyleLookup[command] = index

        combo:AddChoice(styleName, { id = index, cmd = command })

        if command == UI.SelectedStyle then
            selectedIndex = index
        end
    end

    if selectedIndex > 0 then
        combo:ChooseOptionID(selectedIndex)
    else
        combo:SetValue("Select Style")
    end

    combo.OnSelect = function(panel, index, value, data)
        UI.SelectedStyle = data.cmd
        UI:FetchAndDisplayWR(data.cmd)
    end

    local styleNameForMsg = "Unknown Style"
    for index, data in ipairs(TIMER.Styles) do
        local command = data[3][1]
        if command == UI.SelectedStyle then
            styleNameForMsg = data[1]
            break
        end
    end

    pnl.Paint = function(self, w, h)
        local y = 10

        Text("World Records", "ui.mainmenu.button", 15, y, colors.text, TEXT_ALIGN_LEFT)
        surface.SetDrawColor(120, 120, 120)
        surface.DrawRect(15, y + 25, w - 30, 1)
        y = y + 50

        Text("Displaying " .. lastPlace .. "/" .. recordCount .. " times", "ui.mainmenu.button", 15, y - 10, Color(200, 200, 200), TEXT_ALIGN_LEFT)
        y = y + 25

        local tableMargin = 20
        local tableX, tableY = tableMargin, y
        local tableWidth = w - (tableMargin * 2)
        local boxHeight = (recordCount == 0) and (30 + 40) or (40 + (recordCount * 25))

        surface.SetDrawColor(38, 38, 38)
        surface.DrawRect(tableX, tableY, tableWidth, boxHeight)

        local titleHeight = 30
        surface.SetDrawColor(32, 32, 32)
        surface.DrawRect(tableX, tableY, tableWidth, titleHeight)

        Text("Place", "ui.mainmenu.button", tableX + 10, tableY + 10 - 3, Color(200, 200, 200), TEXT_ALIGN_LEFT)
        Text("Name", "ui.mainmenu.button", tableX + 80, tableY + 10 - 3, Color(200, 200, 200), TEXT_ALIGN_LEFT)
        Text("Time", "ui.mainmenu.button", tableX + tableWidth - 60, tableY + 10 - 3, Color(200, 200, 200), TEXT_ALIGN_RIGHT)

        surface.SetDrawColor(150, 150, 150, 50)
        surface.DrawRect(tableX, tableY + titleHeight, tableWidth, 1)
        tableY = tableY + titleHeight + 10

        if recordCount == 0 then
            Text("No records found for '" .. styleNameForMsg .. "' style", "ui.mainmenu.button", tableX + 10, tableY, Color(255, 0, 0), TEXT_ALIGN_LEFT)
        else
            for i, record in ipairs(UI.WRList or {}) do
                local recordName = record[1]
                local recordTime = record[2]

                local textColorName = (i == 1) and Color(0, 255, 255) or (recordName == playerName and Color(200, 200, 200) or Color(255, 255, 255))

                Text(tostring(i), "ui.mainmenu.button", tableX + 10, tableY, color_white, TEXT_ALIGN_LEFT)
                Text(recordName, "ui.mainmenu.button", tableX + 80, tableY, textColorName, TEXT_ALIGN_LEFT)
                Text(recordTime, "ui.mainmenu.button", tableX + tableWidth - 30, tableY, color_white, TEXT_ALIGN_RIGHT)
                tableY = tableY + 25
            end
        end
    end

    return pnl
end

-- Command for opening Menu
concommand.Add("bhop_menu", function()
    if not GetConVar("bhop_menu_open"):GetBool() then
        UI:CreateMenu()
        RunConsoleCommand("bhop_menu_open", "1")
    else
        if Iv(Frame) then
            RunConsoleCommand("bhop_menu_open", "0")
        end
    end
end)

-- IsValid?
local function Iv(obj)
    return obj ~= nil and obj:IsValid()
end

-- Network Menu
net.Receive("OpenBhopMenu", function()
    if not Iv(Frame) then
        UI:CreateMenu()
        RunConsoleCommand("bhop_menu_open", "1")
    else
        Frame:SetVisible(not Frame:IsVisible())
        if Frame:IsVisible() then
            Frame:MakePopup()
            RunConsoleCommand("bhop_menu_open", "1")
        else
            RunConsoleCommand("bhop_menu_open", "0")
        end
    end
end)

-- Open WR List
net.Receive("OpenWorldRecords", function()
    if not Iv(Frame) then
        UI:CreateMenu()
        RunConsoleCommand("bhop_menu_open", "1")
    end
    local wrButton = UI:CreateTopNavButton("World Records", {})
    if wrButton then
        wrButton:DoClick()
    end
end)