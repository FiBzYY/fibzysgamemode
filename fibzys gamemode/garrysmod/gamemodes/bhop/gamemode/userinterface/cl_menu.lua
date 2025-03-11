--[[

 _  _  ____  __ _  _  _ 
( \/ )(  __)(  ( \/ )( \
/ \/ \ ) _) /    /) \/ (
\_)(_/(____)\_)__)\____/ ! by fibzy

]]--

local activeButtonSideNav, activeButtonTopNav, f1Pressed, f4Pressed = nil, nil, false, false
local lp, Iv, DrawText, Text, hook_Add = LocalPlayer, IsValid, draw.SimpleText, draw.DrawText, hook.Add
local bhopMenuOpen = CreateConVar("bhop_menu_open", "0", FCVAR_ARCHIVE, "Tracks whether the bhop menu is open.")
local selectedTheme = GetConVar("bhop_hud") and GetConVar("bhop_hud"):GetInt() or 0
local selectedFOV = GetConVar("bhop_set_fov") and GetConVar("bhop_set_fov"):GetInt() or GetConVar("default_fov"):GetInt()

function UI:SaveSettings()
    RunConsoleCommand("bhop_hud", tostring(selectedTheme))
    RunConsoleCommand("bhop_set_fov", tostring(selectedFOV))
end

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

function UI:CreatePanel(parent, textLines)
    if not Iv(parent) then return nil end

    local pnl = vgui.Create("DPanel", parent)
    pnl:Dock(FILL)

    pnl.Paint = function(self, w, h)
        local y = 10
        local firstEntry = true

        for i, line in ipairs(textLines) do
            local font = i == 1 and "TopNavFont" or "SmallTextFont"              
            draw.SimpleText(line, font, 10, y, colors.text, TEXT_ALIGN_LEFT)

            y = y + 25

            if firstEntry then
                surface.SetDrawColor(120, 120, 120)
                surface.DrawRect(10, y, w - 20, 1)
                y = y + 15
                firstEntry = false
            end
        end
    end

    return pnl
end

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

function UI:UpdateSideNav(buttons)
    if not Iv(NavPanel) then return end

    NavPanel:Clear()
    local createdButtons = {}
    for _, btnInfo in ipairs(buttons) do
        local btn = self:CreateButton(NavPanel, btnInfo.text, TOP, {0, 0, 0, 5}, false, "ToggleButtonFont")
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

function UI:FetchAndDisplayWR()
    net.Start("RequestWRList")
    net.WriteString(game.GetMap())
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
        UI:CreateWRPanel(ContentPanel)
    else
        print("ERROR")
    end
end)

function UI:CreateTopNavButton(text, sideNavButtons)
    if not Iv(TopNavPanel) then return nil end

    local btn = self:CreateButton(TopNavPanel, text, LEFT, {15, 0, 15, 0}, true, "TopNavFont")

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

    Frame:SetSize(940, 600)
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
    TopNavPanel:SetHeight(20)
    TopNavPanel:Dock(TOP)
    TopNavPanel:DockMargin(0, 0, 0, 15)
    TopNavPanel.Paint = function(self, w, h)
        surface.SetDrawColor(colors.nav)
        if roundedBoxEnabled then
            draw.RoundedBoxEx(8, 0, 0, w, h, colors.nav, true, true, false, false)
        else
            surface.DrawRect(0, 0, w, h)
        end
    end

    local InfoButton = self:CreateTopNavButton("Info", {
        { 
            text = "Overview", 
            panelContent = {
                "Information Overview", 
                "Gamemode by FiBzY", 
                "Play Testers: FiBzY"
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
                "Last updated: " .. BHOP.Version.LastUpdated
            }
        },
        { 
            text = "Server Info", 
            panelContent = {
                "Stats", 
                "Server Name: " .. BHOP.ServerName, 
                "Map: " .. game.GetMap(), 
                "Max Players: " .. game.MaxPlayers() - #player.GetBots(), 
                "Current Players: " .. #player.GetAll() - #player.GetBots(), 
                "Tickrate: " .. string.format("%.2f",  1 / engine.TickInterval())
            }
        }
    })

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
            "Mastering strafing is key to building speed. Try chaning between A + mouse left and D + mouse right.",
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

        { text = "Styles", panelContent = {
            "Styles",
            "Normal, 1000 AA",
            "Sideways, 1000 AA",
            "HSW, 1000 AA",
            "W-Only, 1000 AA",
            "Legit, 150 AA",
            "Unreal, 50000 AA",
            "Segment, 1000 AA",
            "Auto-Strafe, 1000 AA"
        } },
    })

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

    local SettingsButton = self:CreateTopNavButton("Settings", {
    { text = "Settings", panelContent = function(parent)
        local scrollPanel = vgui.Create("DScrollPanel", parent)
        scrollPanel:Dock(FILL)

        scrollPanel.Paint = function(self, w, h)
            surface.SetDrawColor(colors.content)
            surface.DrawRect(0, 0, w, h)
        end

        local vBar = scrollPanel:GetVBar()

        vBar:SetWide(8)

        vBar.Paint = function(self, w, h)
            surface.SetDrawColor(40, 40, 40)
            surface.DrawRect(0, 0, w, h)
        end

        vBar.btnUp.Paint = function(self, w, h)
            surface.SetDrawColor(60, 60, 60)
            surface.DrawRect(0, 0, w, h)
        end
        vBar.btnDown.Paint = function(self, w, h)
            surface.SetDrawColor(60, 60, 60)
            surface.DrawRect(0, 0, w, h)
        end

        vBar.btnGrip.Paint = function(self, w, h)
            surface.SetDrawColor(255, 255, 255)
            surface.DrawRect(0, 0, w, h)
        end

        local container = vgui.Create("DPanel", scrollPanel)
        container:SetSize(parent:GetWide() - 20, 1400)
        container:SetPos(0, 0)
        container.Paint = function(self, w, h)
            surface.SetDrawColor(colors.content)
            surface.DrawRect(0, 0, w, h)
        end

        local x, y = 10, 0
        self:CreatePanel(container, {"Settings"})

        y = y + 45
        self:CreateToggle(container, y, "bhop_disablespec", "Disable Spectator Hud", "This will disable the spectator hud.")
        y = y + 60
        self:CreateToggle(container, y, "bhop_weaponpickup", "Disable weapons pickup", "Enables or disables weapon pickup.")
        y = y + 60
        self:CreateToggle(container, y, "bhop_flipweapons", "Flip Weapons", "Flips your weapons to the left side.")
        y = y + 60
        self:CreateToggle(container, y, "bhop_gunsounds ", "Gun Sounds", "Enables or disables weapon sounds.")
        y = y + 60
        self:CreateToggle(container, y, "bhop_showkeys", "Show Keys", "This displays the keys hud.")
        y = y + 60
        self:CreateToggle(container, y, "bhop_showchatbox", "Enable Chatbox", "Disables or enables chatbox completely.")
        y = y + 60
        self:CreateToggle(container, y, "bhop_timer_prefix_rainbow", "Enable Rainbow Timer", "Disables or enables rainbow timer prefix.")
        y = y + 60
        self:CreateToggle(container, y, "bhop_smoothnoclip", "Enable Smooth Noclip", "Disables or enables noclip smoothing.")
        y = y + 60
        self:CreateToggle(container, y, "bhop_weaponsway", "Enable Weapon Sway", "Controls how weapon view models move.")
    end, isActive = true },

    { text = "Graphics", panelContent = function(parent)
        local scrollPanel = vgui.Create("DScrollPanel", parent)
        scrollPanel:Dock(FILL)

        scrollPanel.Paint = function(self, w, h)
            surface.SetDrawColor(colors.content)
            surface.DrawRect(0, 0, w, h)
        end

        local vBar = scrollPanel:GetVBar()
        vBar:SetWide(8)

        vBar.Paint = function(self, w, h)
            surface.SetDrawColor(40, 40, 40)
            surface.DrawRect(0, 0, w, h)
        end

        vBar.btnUp.Paint = function(self, w, h)
            surface.SetDrawColor(60, 60, 60)
            surface.DrawRect(0, 0, w, h)
        end
        vBar.btnDown.Paint = function(self, w, h)
            surface.SetDrawColor(60, 60, 60)
            surface.DrawRect(0, 0, w, h)
        end

        vBar.btnGrip.Paint = function(self, w, h)
            surface.SetDrawColor(255, 255, 255)
            surface.DrawRect(0, 0, w, h)
        end

        local container = vgui.Create("DPanel", scrollPanel)
        container:SetSize(parent:GetWide() - 20, 1200)
        container:SetPos(0, 0)
        container.Paint = function(self, w, h)
            surface.SetDrawColor(colors.content)
            surface.DrawRect(0, 0, w, h)
        end

        local x, y = 10, 0
        self:CreatePanel(container, {"Graphics"})

        y = y + 45
        self:CreateToggle(container, y, "gmod_mcore_test", "Gmod Multi Core", "This may improve performance by utilizing multiple cores.")
        y = y + 60
        self:CreateToggle(container, y, "mat_antialias", "Disable Antialias", "This may improve performance by disabling antialias.", { default = 8, off = 0 })
        y = y + 60
        self:CreateToggle(container, y, "bhop_showzones", "Show Zones", "Hide or show the timer zones.")
        y = y + 60
        self:CreateInputBox(container, y, "bhop_thickness", 1, "Zones Thickness", "How thick you want the zones to be.")
        y = y + 60
        self:CreateToggle(container, y, "bhop_anticheats", "Show AC Zones", "Hide or show the anti-cheat timer zones.")
        y = y + 60
        self:CreateToggle(container, y, "bhop_showplayers", "Show Players", "Hide or show the players.")
        y = y + 60
        self:CreateToggle(container, y, "r_WaterDrawReflection", "Toggle Reflection", "This may improve performance by toggling off reflection.")
        y = y + 60
        self:CreateToggle(container, y, "r_WaterDrawRefraction", "Toggle Refraction", "This may improve performance by toggling off refraction.")
        y = y + 60
        self:CreateToggle(container, y, "bhop_remove_fog", "Disable Map Fog", "This may make it easier to see by disabling map fog.")
        y = y + 60
        self:CreateInputBox(container, y, "bhop_skybox_speed", 40, "Skybox Speed Cycle", "This will allow you to change the skybox speed cycle.")
        y = y + 60
        self:CreateToggle(container, y, "bhop_nogun", "No gun toggle", "This will allow you to use guns without seeing them.")
    end },

      { text = "SSJ", panelContent = function(parent)
        local scrollPanel = vgui.Create("DScrollPanel", parent)
        scrollPanel:Dock(FILL)

        local vBar = scrollPanel:GetVBar()
        vBar:SetWide(8)

        vBar.Paint = function(self, w, h)
            surface.SetDrawColor(40, 40, 40)
            surface.DrawRect(0, 0, w, h)
        end

        vBar.btnUp.Paint = function(self, w, h)
            surface.SetDrawColor(60, 60, 60)
            surface.DrawRect(0, 0, w, h)
        end
        vBar.btnDown.Paint = function(self, w, h)
            surface.SetDrawColor(60, 60, 60)
            surface.DrawRect(0, 0, w, h)
        end

        vBar.btnGrip.Paint = function(self, w, h)
            surface.SetDrawColor(255, 255, 255)
            surface.DrawRect(0, 0, w, h)
        end

        local container = vgui.Create("DPanel", scrollPanel)
        container:SetSize(parent:GetWide() - 20, 1200)
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
        self:CreateToggle(container, y, "bhop_showssj", "SSJ Enable", "Disables or enables show jump stats." ,{ default = 1, off = 0 })
        y = y + 60
        self:CreateToggle(container, y, "bhop_showpre", "Prestrafe", "Disable or enable prestrafe.")
        y = y + 60
        self:CreateToggle(container, y, "bhop_chatfjt", "First jump tick", "Disable or enable jump tick.")
        y = y + 60
        self:CreateToggle(container, y, "bhop_showfjthud", "First jump tick HUD", "Disable or enable jump tick HUD.")
        y = y + 60
        self:CreateInputBoxText(container, y, "bhop_jhud_style", "claz", "JHUD Choose a Style", "JHUD style picker 'pyramid', 'kawaii', 'claz', 'old'")
        y = y + 60
        self:CreateToggle(container, y, "bhop_jhud", "JHUD Enable", "Disable or enable SSJ HUD.")
        y = y + 60
        self:CreateToggle(container, y, "bhop_jhudold", "JHUD Old Enable", "Disable or enable the older SSJ HUD from 2020.")
        y = y + 60
        self:CreateInputBox(container, y, "bhop_ssj_fadeduration", 1.5, "SSJ Fade Duration", "How long until the SSJ HUD fades out.")
        y = y + 60
        self:CreateToggle(container, y, "bhop_fjt", "Show FJT", "Disable or enable the strafe ground tick.")
        y = y + 60
        self:CreateToggle(container, y, "bhop_center_speed", "Display center speed", "Disable or enable the center speed.")
    end },

        { text = "Strafe Trainer", panelContent = function(parent)
            local x, y = 10, 0
            self:CreatePanel(parent, {"Strafe Trainer"})
            y = y + 45
            self:CreateToggle(parent, y, "bhop_strafetrainer", "Strafe Trainer Enable", "Disables or enables show strafe trainer.")
            y = y + 60
            self:CreateInputBox(parent, y, "bhop_strafetrainer_interval", 10, "Update rate", "Update rate in ticks.", 1, 100)
            y = y + 60
            self:CreateToggle(parent, y, "bhop_strafetrainer_ground", "Ground", "Should update on ground.")
            y = y + 60
            self:CreateToggle(parent, y, "bhop_strafesync", "Strafe Synchronizer", "Disables or enables show strafe synchronizer.")
        end },

        { text = "Audio", panelContent = function(parent)
            local x, y = 10, 0
            self:CreatePanel(parent, {"Audio"})
            y = y + 45
            self:CreateToggle(parent, y, "bhop_mute_music", "Disable Map Music", "Use if you want to disable music on all maps.")
            y = y + 60
            self:CreateToggle(parent, y, "bhop_footsteps", "Disable Footsteps", "Disable or enable footsteps.")
            y = y + 60
            self:CreateToggle(parent, y, "bhop_wrsfx", "Disable WR Sounds", "Disable or enable World Record sounds.")
            y = y + 60
            self:CreateInputBox(parent, y, "bhop_wrsfx_volume", 0.4, "WR Sounds Volume", "Customize your WR sound volume.")
        end },

        { text = "Controls", panelContent = function(parent)
            local x, y = 10, 0
            self:CreatePanel(parent, {"Controls"})
            y = y + 45
            self:CreateToggle(parent, y, "bhop_viewtransfrom", "View Transfrom View", "Disable or enable transfrom viewing.")
            y = y + 60
            self:CreateToggle(parent, y, "bhop_thirdperson", "Third Person View", "Disable or enable third person view.")
            y = y + 60
            self:CreateToggle(parent, y, "bhop_viewinterp", "View Interpolation", "Disable or enable interpolation view.")
            y = y + 60
            self:CreateToggle(parent, y, "bhop_viewpunch", "Enable View Punch", "Disable or enable view punch.")
        end },

        --[[{ text = "FOV", panelContent = function(parent)
            local x, y = 10, 0
            self:CreatePanel(parent, {"FOV"})
            y = y + 45
            self:CreateToggle(parent, y, "bhop_morefov", "Enable more FOV", "For FOV 100+ and higher.")
            y = y + 75
            self:CreateFOVSlider(parent, x, y)
        end }--]]
    })
    local InterfaceButton = self:CreateTopNavButton("User Interface", {
        { text = "Themes", panelContent = function(parent)
            local x, y = 10, 0
            self:CreatePanel(parent, {"Themes"})
            y = y + 45
           self:CreateCustomDropdown(parent, y, "hud.main", "Select HUD Theme", {
                ["hud.css"] = "CS:S Kawaii",
                ["hud.flow"] = "Flow Network",
                ["hud.momentum"] = "Momentum Hud",
                ["hud.simple"] = "Simple HUD",
                ["hud.stellar"] = "Stellar Mod HUD"
            })
            y = y + 300
            self:CreateThemeToggle(parent, y, 0, "Disable UI")
        end, isActive = true },

        { text = "Layouts", panelContent = function(parent)
            local x, y = 10, 0
            self:CreatePanel(parent, {"Layouts"})
            y = y + 45
            self:CreateToggle(parent, y, "bhop_sidetimer", "Enable Side Timer", "Disables or enables side timer.")
            y = y + 60
            self:CreateToggle(parent, y, "bhop_show_notifications", "Enable Pop-up Notifications", "Disables or enables pop-up notifications.")
            y = y + 60
            self:CreateToggle(parent, y, "bhop_roundedbox", "Enable Rounded Boxes", "Disables or enables rounded boxes.")
            y = y + 60
            self:CreateToggle(parent, y, "bhop_simplebox", "Enable Simple HUD Boxes", "Disables or enables simple HUD boxes.")
            y = y + 60
            self:CreateToggle(parent, y, "bhop_chatbox", "Enable Custom Chatbox", "Disables or enables the custom chat box.")
        end },

        { text = "Presets", panelContent = function(parent)
            local x, y = 10, 0
            self:CreatePanel(parent, {"Presets Picker"})
            y = y + 45
           self:CreateCustomDropdownPreset(parent, y, "nui.kawaii", "Set nui theme", {
                ["nui.kawaii"] = "Kawaii",
                ["nui.css"] = "CS:S"
            })

            y = y + 75
           --[[self:CreateCustomDropdownPreset(parent, y, "nui.kawaii", "Set HUD preset", {
            ["nui.kawaii"] = "Kawaii",
            ["nui.css"] = "CS:S"
            })--]]

           --[[[ self:CreateDropdown(parent, y, "Set HUD preset", {["Default"] = "change_preset Default", ["White"] = "change_preset White", ["Grey"] = "change_preset Grey", ["Blur"] = "change_preset Blur"}, "Choose Preset...")
            y = y + 75
           self:CreateDropdown(parent, y, "Set scoreboard theme", {["Default"] = "change_scoreboard Default", ["Kawaii"] = "change_scoreboard Kawaii"}, "Choose Theme...")
            y = y + 75
           self:CreateDropdown(parent, y, "Set scoreboard preset", {["Default"] = "scoreboard Default", ["Kawaii"] = "scoreboard Kawaii"}, "Choose Preset...")
            y = y + 75
           self:CreateDropdown(parent, y, "Set zones preset", {["Default"] = "change_zones_preset Default", ["Kawaii"] = "change_zones_preset Kawaii"}, "Choose Preset...")
            y = y + 75
           self:CreateDropdown(parent, y, "Set scoreboard style", {["Default"] = "bhop_scoreboard_style Default", ["Kawaii"] = "bhop_scoreboard_style Kawaii"}, "Choose Style...")--]]
        end },
    })

    if lp():IsAdmin() then
        local AdminButton = self:CreateTopNavButton("Admin", {
            { text = "Users", panelContent = function(parent)
                local x, y = 10, 0
                self:CreatePanel(parent, {"Admin user management"})
                self:UpdatePlayerList(parent)
            end, isActive = true },

            { text = "Logs", panelContent = function(parent)
                local x, y = 10, 0
                self:CreatePanel(parent, {"View server logs"})

                UI:UpdateServerLogs(parent)
            end },

            { text = "Timer", panelContent = function(parent)
                local x, y = 10, 0
                self:CreatePanel(parent, {"Admin Timer"})

                UI:UpdateAdminSettings(parent)
            end },

            { text = "Settings", panelContent = function(parent)
                local x, y = 10, 0
                self:CreatePanel(parent, {"Admin settings"})
                y = y + 45
                self:CreateInputBoxSettings(parent, y, "bhop_settings_zonecap", 290, "Zone speed cap", "Changes speed cap in start zones.")
                y = y + 60
                self:CreateInputBoxSettings(parent, y, "bhop_admin_mapmultiplier", 15, "Set map points", "Sets or changes the points for the map.")
            end },

            { text = "Movement Settings", panelContent = function(parent)
                local x, y = 10, 0
                self:CreatePanel(parent, {"Movement configurations"})
                y = y + 45
                self:CreateInputBoxSettings(parent, y, "bhop_settings_cap", 100, "Airaccel rate", "Changes movements airaccel rate.")
                y = y + 60
                self:CreateInputBoxSettings(parent, y, "bhop_settings_mv", 32.4, "Speed Cap", "Changes movement speed air cap.")
                y = y + 60
                self:CreateInputBoxSettings(parent, y, "bhop_settings_maxspeed", 250, "Max speed", "Changes movements max speed cap.")
                y = y + 60
                self:CreateInputBoxSettings(parent, y, "bhop_settings_jumppower", 290, "Jump Height", "Changes movements jump height.")
                y = y + 60
                self:CreateInputBoxSettings(parent, y, "bhop_movement_crouchboosting", 1, "Crouch Boosting", "Enables Crouch Boosting.")
                y = y + 60
                self:CreateInputBoxSettings(parent, y, "bhop_movement_rngfix", 1, "RNGFix", "Enables RNGFix (Recommended keep on).")
                y = y + 60
                self:CreateInputBoxSettings(parent, y, "bhop_movement_rampfix", 1, "Ramp Fix", "Enables Surf Ramp Fix (Recommended keep on).")
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

    local CloseButton = vgui.Create("DButton", Frame)
    CloseButton:SetText("")
    CloseButton:SetSize(24, 24)
    CloseButton:SetPos(Frame:GetWide() - 28, 4)
    CloseButton.Paint = function(self, w, h)
        local btnColor = self:IsHovered() and colors.buttonHover or colors.button
        surface.SetDrawColor(Color(0, 0, 0, 0))
        surface.DrawRect(0, 0, w, h)
        DrawText("X", "DermaDefaultBold", w / 1.8, h / 2, colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    CloseButton.DoClick = function()
        Frame:Close()
        activeButtonTopNav = nil
        activeButtonSideNav = nil
        RunConsoleCommand("bhop_menu_open", "0")
    end

    local roundedBox = vgui.Create("DPanel", Frame)
    roundedBox:SetSize(100 + 20, 40)
    roundedBox:SetPos(Frame:GetWide() - 140 - 10, 12)
    roundedBox:SetBackgroundColor(Color(32, 32, 32, 0))
    roundedBox.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(36, 36, 36, 255))
    end

    BuildCircularAvatarPic(Frame, Frame:GetWide() - 140, 14, 18, lp():SteamID64())

    local playerNameLabel = vgui.Create("DLabel", Frame)
    playerNameLabel:SetText(lp():Nick())
    playerNameLabel:SetFont("SmallTextFont")
    playerNameLabel:SetTextColor(Color(255, 255, 255))
    playerNameLabel:SizeToContents()
    playerNameLabel:SetPos(Frame:GetWide() - 140 + 36 + 10, 24)

    InfoButton:DoClick()
end

local cachedSum = nil
net.Receive("UpdatePointsSum", function()
    local pointsSum = net.ReadInt(32)

    if Iv(lp()) then
        lp().nSum = pointsSum
    else
        cachedSum = pointsSum
    end
end)

hook_Add("InitPostEntity", "AssignCachedPointsSum", function()
    if cachedSum and Iv(lp()) then
        lp().nSum = cachedSum

        cachedSum = nil
    end
end)

function UI:CreateRankPanel(parent)
    if not Iv(parent) then
        return
    end

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

        local boxPadding = 5
        local boxX = 5
        local boxY = y - boxPadding
        local boxWidth = w - 10
        local boxHeight = 13 * rankCount + 70

        surface.SetDrawColor(42, 42, 42)
        surface.DrawRect(boxX, boxY, boxWidth, boxHeight)

        Text("Ranks", "SmallTextFont", 10, y, colors.text, TEXT_ALIGN_LEFT)
        surface.SetDrawColor(120, 120, 120)
        surface.DrawRect(10, y + 25, w - 20, 1)
        y = y + 35

        local yLeft = y
        local yRight = y
        local xLeft = 10
        local xRight = panelWidth / 2 - 100
        for i, rank in ipairs(rankDisplayLeft) do
            local rankName, rankColor, rankNumber = rank[1], rank[2], rank[3]

            Text(rankNumber .. ".", "SmallTextFont", xLeft, yLeft, Color(255, 255, 255), TEXT_ALIGN_LEFT)

            local numWidth = surface.GetTextSize(rankNumber .. ".")

            if rankNumber == rankCount then
                DrawRainbowText(rankName, "SmallTextFont", xLeft + numWidth + 5, yLeft + 8)
            else
                Text(rankName, "SmallTextFont", xLeft + numWidth + 5, yLeft, rankColor, TEXT_ALIGN_LEFT)
            end

            yLeft = yLeft + 25
        end

        for i, rank in ipairs(rankDisplayRight) do
            local rankName, rankColor, rankNumber = rank[1], rank[2], rank[3]

            Text(rankNumber .. ".", "SmallTextFont", xRight, yRight, Color(255, 255, 255), TEXT_ALIGN_LEFT)

            local numWidth = surface.GetTextSize(rankNumber .. ".")
            if rankNumber == rankCount then
                DrawRainbowText(rankName, "SmallTextFont", xRight + numWidth + 5, yRight + 8)
            else
                Text(rankName, "SmallTextFont", xRight + numWidth + 5, yRight, rankColor, TEXT_ALIGN_LEFT)
            end

            yRight = yRight + 25
        end

        local rankingX = w - 200
        local rankingY = 10
        Text("Stats", "SmallTextFont", rankingX, rankingY, colors.text, TEXT_ALIGN_LEFT)
        surface.SetDrawColor(255, 255, 255, 50)
        surface.DrawRect(rankingX, rankingY + 25, 280, 1)
        rankingY = rankingY + 35

        TIMER.ranking = {}

        if TIMER.ranking then
            local rank = lp():GetNWInt("Rank", 0)
            Text("Rank: " .. rank, "SmallTextFont", rankingX, rankingY, colors.text, TEXT_ALIGN_LEFT)
            rankingY = rankingY + 25

            local wrText = "Points: "
            Text(wrText, "SmallTextFont", rankingX, rankingY, colors.text, TEXT_ALIGN_LEFT)

            local wrTextWidth = surface.GetTextSize(wrText)
            local wrColor = (TIMER.ranking == "Starter") and Color(255, 255, 255) or colors.buttonIsActive

            local rankPoints = lp().nSum or 0
            local rankPointsText = tostring(rankPoints)

            Text(rankPointsText, "SmallTextFont", rankingX + wrTextWidth, rankingY, wrColor, TEXT_ALIGN_LEFT)
        else
            Text("Waiting for Ranking stats...", "SmallTextFont", rankingX, rankingY, Color(255, 0, 0), TEXT_ALIGN_LEFT)
        end

    end
    return pnl
end

function UI:CreateWRPanel(parent)
    if not Iv(parent) then
        return
    end

    local playerName = lp():Nick()
    local panelWidth = parent:GetWide()

    local pnl = vgui.Create("DPanel", parent)
    pnl:Dock(FILL)
    pnl.Paint = function(self, w, h)
        local y = 10

        local boxPadding = 5
        local boxX = 5
        local boxY = y - boxPadding
        local boxWidth = w - 10
        local boxHeight = 25 * (#UI.WRList or 0) + 140

        surface.SetDrawColor(42, 42, 42)
        surface.DrawRect(boxX, boxY, boxWidth, boxHeight)

        Text("World Records", "SmallTextFont", 10, y, colors.text, TEXT_ALIGN_LEFT)
        surface.SetDrawColor(120, 120, 120)
        surface.DrawRect(10, y + 25, w - 20, 1)
        y = y + 35

        if not UI.WRList or #UI.WRList == 0 then
            Text("No Records Made", "SmallTextFont", 10, y, Color(255, 0, 0), TEXT_ALIGN_LEFT)
        else
            for i, record in ipairs(UI.WRList or {}) do
                local recordName = record[1]

                local textColor
                if i == 1 then
                    textColor = Color(55, 122, 151)
                elseif recordName == playerName then
                    textColor = Color(122, 122, 122)
                else
                    textColor = colors.text
                end

                Text(i .. ". " .. record[1] .. " - " .. record[2], "SmallTextFont", 10, y, textColor, TEXT_ALIGN_LEFT)
                y = y + 25
            end
        end

        local globalsX = w - 300
        local globalsY = 10
        Text("Globals", "SmallTextFont", globalsX, globalsY, colors.text, TEXT_ALIGN_LEFT)

        surface.SetDrawColor(255, 255, 255)
        surface.DrawRect(globalsX, globalsY + 25, 280, 1)

        globalsY = globalsY + 35

        if TIMER.map and TIMER.globalWR then
            Text("Map: " .. TIMER.map, "SmallTextFont", globalsX, globalsY, colors.text, TEXT_ALIGN_LEFT)
            globalsY = globalsY + 25

            local wrText = "Global WR: "
            Text(wrText, "SmallTextFont", globalsX, globalsY, colors.text, TEXT_ALIGN_LEFT)

            local wrTextWidth = surface.GetTextSize(wrText)
            local wrColor = (TIMER.globalWR == "N/A") and Color(255, 0, 0) or colors.buttonIsActive

            Text(TIMER.globalWR, "SmallTextFont", globalsX + wrTextWidth, globalsY, wrColor, TEXT_ALIGN_LEFT)

            globalsY = globalsY + 25

            local yourWRText = "Your WR's: "
            Text(yourWRText .. LocalPlayer():GetNWInt("SpecialRank", 0), "SmallTextFont", globalsX, globalsY, colors.text, TEXT_ALIGN_LEFT)
        else
            Text("Waiting for Global WR...", "SmallTextFont", globalsX, globalsY, Color(255, 0, 0), TEXT_ALIGN_LEFT)
        end
    end

    return pnl
end

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

local function Iv(obj)
    return obj ~= nil and obj:IsValid()
end

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