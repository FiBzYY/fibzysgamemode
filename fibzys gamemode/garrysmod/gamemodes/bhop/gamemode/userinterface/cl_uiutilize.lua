local lp, Iv, DrawText, Text, hook_Add = LocalPlayer, IsValid, draw.SimpleText, draw.DrawText, hook.Add
logs = logs or {}

-- Menu colors
colors = {
    background = Color(33, 33, 33),
    nav = Color(33, 33, 33),
    sideNav = Color(40, 40, 40),
    content = Color(43, 43, 43),
    button = Color(40, 40, 40),
    buttonIsActive = Color(0, 162, 201),
    toggleButton = Color(62, 62, 62),
    text = Color(255, 255, 255),
    textActive = Color(255, 255, 255),
    textTopActive = DynamicColors.PanelColor,
    box = Color(75, 75, 75),
    boxActive = Color(70, 90, 100),
    infoText = Color(120, 120, 120),
    hightlight = Color(0, 255, 255)
}

function UI:CreateCustomDropdown(parent, y, themeID, labelText, themeOptions)
    local pnl = vgui.Create("DPanel", parent)
    pnl:SetSize(parent:GetWide(), 80)
    pnl:SetPos(0, y)

    pnl.Paint = function(self, w, h)
        draw.RoundedBox(0, 10, 5, w - 20, 70, Color(42, 42, 42, 250))
        draw.SimpleText(labelText, "ToggleButtonFontTitle", 20, 15, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    local dropdownButton = vgui.Create("DButton", pnl)
    dropdownButton:SetPos(20, 40)
    dropdownButton:SetSize(200, 25)
    dropdownButton:SetText("")
    
    local selectedTheme = Settings:GetValue('selected.hud', "hud.css")
    local selectedText = themeOptions[selectedTheme] or "Select an option"

    local dropdownOpen = false

    dropdownButton.Paint = function(self, w, h)
        local bgColor = self:IsHovered() and Color(50, 50, 50, 255) or Color(35, 35, 35, 255)
        draw.RoundedBox(0, 0, 0, w, h, bgColor)

        draw.SimpleText(selectedText, "hud.subtitle", 10, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        surface.SetDrawColor(200, 200, 200, 255)
        draw.NoTexture()
        surface.DrawPoly({
            { x = w - 20, y = h / 2 - 4 },
            { x = w - 10, y = h / 2 - 4 },
            { x = w - 15, y = h / 2 + 4 }
        })
    end

    local dropdownMenu = vgui.Create("DPanel", parent)
    dropdownMenu:SetSize(200, 25 * table.Count(themeOptions))
    dropdownMenu:SetPos(dropdownButton:LocalToScreen(20, 110))
    dropdownMenu:SetVisible(false)

    dropdownMenu.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(25, 25, 25, 255))
    end

    local yOffset = 0
    for id, name in pairs(themeOptions) do
        local option = vgui.Create("DButton", dropdownMenu)
        option:SetSize(200, 25)
        option:SetPos(0, yOffset)
        option:SetText("")

        option.Paint = function(self, w, h)
            local bgColor = self:IsHovered() and Color(60, 60, 60, 255) or Color(35, 35, 35, 255)
            draw.RoundedBox(0, 0, 0, w, h, bgColor)
            draw.SimpleText(name, "hud.subtitle", 10, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        option.DoClick = function()
            selectedText = name
            dropdownOpen = false
            dropdownMenu:SetVisible(false)
            selectedTheme = id

            if id == 0 then
                Settings:SetValue('selected.hud', "disabled")
                Theme:DisableHUD()
                RunConsoleCommand("bhop_hud_hide", "1")
            else
                Settings:SetValue('selected.hud', id)
                RunConsoleCommand("bhop_hud_hide", "0")
            end

            parent:InvalidateLayout(true)
        end

        yOffset = yOffset + 25
    end

    dropdownButton.DoClick = function()
        dropdownOpen = not dropdownOpen
        dropdownMenu:SetVisible(dropdownOpen)
    end

    return pnl, dropdownButton, dropdownMenu
end

function UI:CreateCustomDropdownPreset(parent, y, themeID, labelText, themeOptions)
    local pnl = vgui.Create("DPanel", parent)
    pnl:SetSize(parent:GetWide(), 80)
    pnl:SetPos(0, y)

    pnl.Paint = function(self, w, h)
        draw.RoundedBox(0, 10, 5, w - 20, 70, Color(42, 42, 42, 250))
        draw.SimpleText(labelText, "ToggleButtonFontTitle", 20, 15, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    local dropdownButton = vgui.Create("DButton", pnl)
    dropdownButton:SetPos(20, 40)
    dropdownButton:SetSize(200, 25)
    dropdownButton:SetText("")
    
    local selectedTheme = Settings:GetValue('selected.nui', "nui.css")
    local selectedText = themeOptions[selectedTheme] or "Select an option"

    local dropdownOpen = false

    dropdownButton.Paint = function(self, w, h)
        local bgColor = self:IsHovered() and Color(50, 50, 50, 255) or Color(35, 35, 35, 255)
        draw.RoundedBox(0, 0, 0, w, h, bgColor)

        draw.SimpleText(selectedText, "hud.subtitle", 10, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        surface.SetDrawColor(200, 200, 200, 255)
        draw.NoTexture()
        surface.DrawPoly({
            { x = w - 20, y = h / 2 - 4 },
            { x = w - 10, y = h / 2 - 4 },
            { x = w - 15, y = h / 2 + 4 }
        })
    end

    local dropdownMenu = vgui.Create("DPanel", parent)
    dropdownMenu:SetSize(200, 25 * table.Count(themeOptions))
    dropdownMenu:SetPos(dropdownButton:LocalToScreen(20, 110))
    dropdownMenu:SetVisible(false)

    dropdownMenu.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(25, 25, 25, 255))
    end

    local yOffset = 0
    for id, name in pairs(themeOptions) do
        local option = vgui.Create("DButton", dropdownMenu)
        option:SetSize(200, 25)
        option:SetPos(0, yOffset)
        option:SetText("")

        option.Paint = function(self, w, h)
            local bgColor = self:IsHovered() and Color(60, 60, 60, 255) or Color(35, 35, 35, 255)
            draw.RoundedBox(0, 0, 0, w, h, bgColor)
            draw.SimpleText(name, "hud.subtitle", 10, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        option.DoClick = function()
            selectedText = name
            dropdownOpen = false
            dropdownMenu:SetVisible(false)
            selectedTheme = id

            if id == 0 then
                Settings:SetValue('selected.hud', "disabled")
            else
                Settings:SetValue('selected.nui', id)
            end

            parent:InvalidateLayout(true)
        end

        yOffset = yOffset + 25
    end

    dropdownButton.DoClick = function()
        dropdownOpen = not dropdownOpen
        dropdownMenu:SetVisible(dropdownOpen)
    end

    return pnl, dropdownButton, dropdownMenu
end

function UI:CreateThemeToggle(parent, y, themeID, labelText)
    local pnl = vgui.Create("DPanel", parent)
    pnl:SetSize(parent:GetWide(), 80)
    pnl:SetPos(0, y)

    pnl.Paint = function(self, w, h)
        local isActive = (selectedTheme == themeID)

        if themeID == 0 then
            local boxColor = isActive and Color(50, 205, 50) or Color(255, 69, 0)
            local knobColor = Color(255, 255, 255)

            draw.RoundedBox(8, w - 60, 20, 50, 20, boxColor)

            if isActive then
                draw.RoundedBox(8, w - 30, 20, 20, 20, knobColor)
            else
                draw.RoundedBox(8, w - 60, 20, 20, 20, knobColor)
            end
        else
            local boxColor = colors.box or Color(120, 120, 120)
            local activeBoxColor = DynamicColors.PanelColor or Color(255, 255, 255)

            surface.SetDrawColor(boxColor)
            surface.DrawOutlinedRect(w - 50, 10, 30, 30, 2)

            if isActive then
                surface.SetDrawColor(activeBoxColor)
                surface.DrawRect(w - 46, 14, 22, 22)
            end
        end
    end

    pnl.OnMousePressed = function()
        selectedTheme = themeID
        
        if themeID == 0 then
            Settings:SetValue('selected.hud', "disabled")
            Theme:DisableHUD() -- DO TO
            RunConsoleCommand("bhop_hud_hide", "1")
        else
            Settings:SetValue('selected.hud', themeID)
            RunConsoleCommand("fibzy_hud", tostring(themeID))
            RunConsoleCommand("bhop_hud_hide", "0")
        end

        parent:InvalidateLayout(true)
    end

    local lbl = vgui.Create("DLabel", parent)
    lbl:SetPos(10, y + 8)
    lbl:SetText(labelText)
    lbl:SetTextColor(colors.text)
    lbl:SetFont("ToggleButtonFontTitle")
    lbl:SizeToContents()

    local infoLbl = vgui.Create("DLabel", parent)
    infoLbl:SetPos(10, y + 28)
    infoLbl:SetText("Enable HUD for " .. labelText)
    infoLbl:SetTextColor(colors.infoText)
    infoLbl:SetFont("SmallTextFont")
    infoLbl:SizeToContents()

    return pnl, lbl, infoLbl
end

function UI:CreateInputBox(parent, y, command, defaultVal, labelText, infoText, minVal, maxVal)
    local pnl = vgui.Create("DPanel", parent)
    pnl:SetSize(parent:GetWide(), 80)
    pnl:SetPos(0, y)
    pnl.Paint = function(self, w, h)
        surface.SetDrawColor(0, 0, 0, 0)
        surface.DrawRect(0, 0, w, h)
    end

    local boxSize = 31
    minVal = minVal or 0.1
    maxVal = maxVal or 10

    local cvarValue = GetConVar(command) and GetConVar(command):GetInt() or defaultVal

    local inputBox = vgui.Create("DTextEntry", pnl)
    inputBox:SetPos(pnl:GetWide() - 50, 0)
    inputBox:SetSize(boxSize, boxSize)
    inputBox:SetNumeric(true)
    inputBox:SetText(tostring(cvarValue))

    inputBox:SetFont("ToggleButtonFont")

    inputBox.Paint = function(self, w, h)
        surface.SetDrawColor(colors.toggleButton)
        surface.DrawRect(0, 0, w, h)
        self:DrawTextEntryText(Color(255, 255, 255), Color(30, 130, 255), Color(255, 255, 255))
    end

    inputBox.OnChange = function(self)
        local value = tonumber(self:GetValue()) or minVal
        if value < minVal then
            self:SetText(tostring(minVal))
        elseif value > maxVal then
            self:SetText(tostring(maxVal))
        end
    end

    inputBox.OnEnter = function(self)
        local newValue = math.Clamp(tonumber(self:GetValue()) or minVal, minVal, maxVal)
        lp():ConCommand(command .. " " .. tostring(newValue)) 
    end

    local lbl = vgui.Create("DLabel", parent)
    lbl:SetPos(10, y + 8)
    lbl:SetText(labelText)
    lbl:SetTextColor(colors.text)
    lbl:SetFont("ToggleButtonFont")
    lbl:SizeToContents()

    local infoLbl = vgui.Create("DLabel", parent)
    infoLbl:SetPos(10, y + 28)
    infoLbl:SetText(infoText)
    infoLbl:SetTextColor(colors.infoText)
    infoLbl:SetFont("SmallTextFont")
    infoLbl:SizeToContents()

    return pnl, lbl, infoLbl, inputBox
end

function UI:CreateInputBoxText(parent, y, command, defaultVal, labelText, infoText)
    local pnl = vgui.Create("DPanel", parent)
    pnl:SetSize(parent:GetWide(), 80)
    pnl:SetPos(0, y)
    pnl.Paint = function(self, w, h)
        surface.SetDrawColor(0, 0, 0, 0)
        surface.DrawRect(0, 0, w, h)
    end

    local boxSize = 31
    local cvarValue = GetConVar(command) and GetConVar(command):GetString() or "pyramid"

    local inputBox = vgui.Create("DTextEntry", pnl)
    inputBox:SetPos(pnl:GetWide() - 60, 15)
    inputBox:SetSize(boxSize + 20, boxSize)
    inputBox:SetText(cvarValue)
    inputBox:SetFont("ToggleButtonFont")

    inputBox.Paint = function(self, w, h)
        surface.SetDrawColor(colors.toggleButton)
        surface.DrawRect(0, 0, w, h)
        self:DrawTextEntryText(Color(255, 255, 255), Color(30, 130, 255), Color(255, 255, 255))
    end

    inputBox.OnEnter = function(self)
        local newValue = self:GetValue() or "pyramid"
        lp():ConCommand(command .. " " .. newValue)
    end

    local lbl = vgui.Create("DLabel", parent)
    lbl:SetPos(10, y + 8)
    lbl:SetText(labelText)
    lbl:SetTextColor(colors.text)
    lbl:SetFont("ToggleButtonFont")
    lbl:SizeToContents()

    local infoLbl = vgui.Create("DLabel", parent)
    infoLbl:SetPos(10, y + 28)
    infoLbl:SetText(infoText)
    infoLbl:SetTextColor(colors.infoText)
    infoLbl:SetFont("SmallTextFont")
    infoLbl:SizeToContents()

    return pnl, lbl, infoLbl, inputBox
end

function UI:CreateDropdown(parent, y, labelText, optionsWithCommands, defaultText)
    local pnl = vgui.Create("DPanel", parent)
    pnl:SetSize(parent:GetWide(), 80)
    pnl:SetPos(0, y)

    pnl.Paint = function(self, w, h)
    end

    local lbl = vgui.Create("DLabel", pnl)
    lbl:SetPos(10, 10)
    lbl:SetText(labelText)
    lbl:SetTextColor(colors.text)
    lbl:SetFont("ToggleButtonFont")
    lbl:SizeToContents()

    local dropdown = vgui.Create("DComboBox", pnl)
    dropdown:SetPos(10, 40)
    dropdown:SetSize(parent:GetWide() - 200, 30)
    dropdown:SetValue(defaultText)
    dropdown:SetFont("ToggleButtonFont")

    dropdown.Paint = function(self, w, h)
        surface.SetDrawColor(50, 50, 50)
        surface.DrawRect(0, 0, w, h)
    end

    dropdown.OnSelect = function(_, index, value)
        dropdown:SetValue(value)
        print("Selected option: " .. value)

        local command = optionsWithCommands[value]
        if command then
            lp():ConCommand(command)
        end
    end

    dropdown.OnMenuOpened = function(self, menu)
        for _, option in ipairs(menu:GetCanvas():GetChildren()) do
            option:SetFont("ToggleButtonFont")
            option.Paint = function(self, w, h)
                if self:IsHovered() then
                    surface.SetDrawColor(100, 100, 100)
                else
                    surface.SetDrawColor(60, 60, 60)
                end
                surface.DrawRect(0, 0, w, h)
 
                self:DrawTextEntryText(Color(255, 255, 255), Color(150, 150, 150), Color(255, 255, 255))
            end
        end
    end

    for option, _ in pairs(optionsWithCommands) do
        dropdown:AddChoice(option)
    end

    return pnl, lbl, dropdown
end

function UI:CreateColorPicker(parent, y, labelText, defaultColor)
    local pnl = vgui.Create("DPanel", parent)
    pnl:SetSize(parent:GetWide(), 80)
    pnl:SetPos(0, y)

    pnl.Paint = function(self, w, h)
    end

    local lbl = vgui.Create("DLabel", pnl)
    lbl:SetPos(10, 10)
    lbl:SetText(labelText)
    lbl:SetTextColor(colors.text)
    lbl:SetFont("ToggleButtonFont")
    lbl:SizeToContents()

    local colorBox = vgui.Create("DPanel", pnl)
    colorBox:SetPos(80, 10)
    colorBox:SetSize(200, 30)
    colorBox.Paint = function(self, w, h)
        surface.SetDrawColor(defaultColor)
        surface.DrawRect(0, 0, w, h)
    end

    colorBox.OnMousePressed = function()
        local colorPicker = vgui.Create("DFrame")
        colorPicker:SetTitle("Pick a Color")
        colorPicker:SetSize(300, 350)
        colorPicker:Center()
        colorPicker:MakePopup()

        local colorMixer = vgui.Create("DColorMixer", colorPicker)
        colorMixer:SetPos(10, 30)
        colorMixer:SetSize(280, 280)
        colorMixer:SetPalette(true)
        colorMixer:SetAlphaBar(false)
        colorMixer:SetWangs(true)
        colorMixer:SetColor(defaultColor)

        colorMixer.ValueChanged = function(self, color)
            defaultColor = color
            colorBox.Paint = function(self, w, h)
                surface.SetDrawColor(color)
                surface.DrawRect(0, 0, w, h)
            end
        end
    end

    return pnl, lbl, colorBox
end

function UI:CreateToggle(parent, y, command, labelText, infoText, toggleValues)
    local pnl = vgui.Create("DPanel", parent)
    pnl:SetSize(parent:GetWide(), 80)
    pnl:SetPos(0, y)

    local convar = GetConVar(command)
    local defaultValue = toggleValues and toggleValues.default or 8
    local offValue = toggleValues and toggleValues.off or 0

    pnl.Paint = function(self, w, h)
        local isActive = false

        if convar then
            isActive = (convar:GetInt() ~= offValue)
        end

        local boxColor = colors.box
        surface.SetDrawColor(boxColor)
        surface.DrawOutlinedRect(w - 50, 10, 30, 30, 2)

        if isActive then
            surface.SetDrawColor(DynamicColors.PanelColor)
            surface.DrawRect(w - 46, 14, 22, 22)
        end
    end

    pnl.OnMousePressed = function()
        if convar then
            local currentValue = convar:GetInt()
            local newValue = (currentValue == offValue) and defaultValue or offValue
            RunConsoleCommand(command, tostring(newValue))
        else
            print("[UI] Warning: ConVar '" .. command .. "' does not exist!")
        end

        parent:InvalidateLayout(true)
    end

    local lbl = vgui.Create("DLabel", parent)
    lbl:SetPos(10, y + 8)
    lbl:SetText(labelText)
    lbl:SetTextColor(colors.text)
    lbl:SetFont("ToggleButtonFontTitle")
    lbl:SizeToContents()

    local infoLbl = vgui.Create("DLabel", parent)
    infoLbl:SetPos(10, y + 28)
    infoLbl:SetText(infoText)
    infoLbl:SetTextColor(colors.infoText)
    infoLbl:SetFont("SmallTextFont")
    infoLbl:SizeToContents()

    return pnl, lbl, infoLbl
end

local cos, sin, rad = math.cos, math.sin, math.rad

function UI:CreateFOVSlider(parent, x, y)
    local slider = vgui.Create("DNumSlider", parent)
    slider:SetPos(x - 300, y)
    slider:SetSize(parent:GetWide() - 20, 50)
    slider:SetText("FOV")
    slider:SetMin(90)
    slider:SetMax(120)
    slider:SetDecimals(0)
    slider:SetValue(selectedFOV)
    slider.Label:SetTextColor(colors.text)
    slider.TextArea:SetTextColor(colors.text)
    slider.TextArea:SetFont("SmallTextFont")

    slider.Slider.Paint = function(self, w, h)
        surface.SetDrawColor(0, 0, 0, 0)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawRect(15, h / 2 - 2, w - 20, 4)
    end

    slider.Slider.Knob.Paint = function(self, w, h)
        local radius = 8

        render.ClearStencil()
        render.SetStencilEnable(true)
        render.SetStencilWriteMask(255)
        render.SetStencilTestMask(255)
        render.SetStencilFailOperation(STENCILOPERATION_REPLACE)
        render.SetStencilPassOperation(STENCILOPERATION_ZERO)
        render.SetStencilZFailOperation(STENCILOPERATION_ZERO)
        render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_NEVER)
        render.SetStencilReferenceValue(1)

        local circle = {}
        for i = 0, 360, 1 do
            local t = math.rad(i)
            circle[#circle + 1] = {
                x = w / 2 + math.cos(t) * radius,
                y = h / 2 + math.sin(t) * radius
            }
        end

        draw.NoTexture()
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawPoly(circle)

        render.SetStencilFailOperation(STENCILOPERATION_ZERO)
        render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
        render.SetStencilZFailOperation(STENCILOPERATION_ZERO)
        render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
        render.SetStencilReferenceValue(1)

        draw.NoTexture()
        surface.SetDrawColor(30, 130, 255, 255)
        surface.DrawPoly(circle)

        render.SetStencilEnable(false)
        render.ClearStencil()
    end

    slider.Label:SetPos(slider:GetX() + 10, slider:GetY() + 5)

    slider.OnValueChanged = function(self, value)
        selectedFOV = math.Round(value)

        RunConsoleCommand("bhop_set_fov", tostring(selectedFOV))
        UI:SaveSettings()
    end

    local infoLbl = vgui.Create("DLabel", parent)
    infoLbl:SetPos(x, y - 4)
    infoLbl:SetText("Adjust the field of view slider")
    infoLbl:SetTextColor(colors.infoText)
    infoLbl:SetFont("SmallTextFont")
    infoLbl:SizeToContents()

    return slider, infoLbl
end

function UI:CreateRoundedBoxToggle(parent, y, labelText)
    local pnl = vgui.Create("DPanel", parent)
    pnl:SetSize(parent:GetWide(), 60)
    pnl:SetPos(0, y)

    pnl.Paint = function(self, w, h)
        local conVar = GetConVar("bhop_roundedbox")
        local isActive = conVar and conVar:GetBool() or false
        local boxColor = colors.box

        surface.SetDrawColor(boxColor)
        surface.DrawOutlinedRect(w - 30, 0, 20, 20, 2)
        if isActive then
            surface.SetDrawColor(colors.boxActive)
            surface.DrawRect(w - 26, 4, 12, 12)
        end
    end

    pnl.OnMousePressed = function()
        if GetConVar("bhop_roundedbox") then
            local newValue = not GetConVar("bhop_roundedbox"):GetBool()
            RunConsoleCommand("bhop_roundedbox", newValue and "1" or "0")
            parent:InvalidateLayout(true)
        end
    end

    local lbl = vgui.Create("DLabel", parent)
    lbl:SetPos(10, y + 2)
    lbl:SetText(labelText)
    lbl:SetTextColor(colors.text)
    lbl:SetFont("ToggleButtonFont")
    lbl:SizeToContents()

    local infoLbl = vgui.Create("DLabel", parent)
    infoLbl:SetPos(10, y + 18)
    infoLbl:SetText("Disables or enables rounded boxes")
    infoLbl:SetTextColor(colors.infoText)
    infoLbl:SetFont("SmallTextFont")
    infoLbl:SizeToContents()

    return pnl, lbl, infoLbl
end

local RankNames = {
    [0] = "Player", [1] = "Base",
    [2] = "Elevated", [4] = "Moderator",
    [8] = "Admin", [9] = "Zoner",
    [16] = "Super Admin", [32] = "Developer",
    [33] = "Manager", [34] = "Founder",
    [64] = "Owner"
}

local rankColors = {
    ["Developer"] = Color(255, 0, 255),
    ["Admin"] = Color(255, 0, 0),
    ["Moderator"] = Color(0, 255, 0),
    ["Player"] = Color(255, 255, 255),
}

function UI:UpdatePlayerList(parent)
    if not Iv(parent) then return end

    if Iv(self.PlayerListPanel) then
        self.PlayerListPanel:Remove()
    end

    self.PlayerListPanel = vgui.Create("DPanel", parent)
    self.PlayerListPanel:Dock(FILL)
    self.PlayerListPanel:DockMargin(0, 50, 0, 0)
    self.PlayerListPanel.Paint = function(self, w, h)
        surface.SetDrawColor(0, 0, 0, 0)
    end

    local headerPanel = vgui.Create("DPanel", self.PlayerListPanel)
    headerPanel:Dock(TOP)
    headerPanel:SetHeight(30)
    headerPanel:DockMargin(10, 0, 10, 0)
    headerPanel.Paint = function(self, w, h)
        surface.SetDrawColor(32, 32, 32)
        surface.DrawRect(0, 0, w, h)

        local leftWidth = w * 0.4
        local middleWidth = w * 0.4

        DrawText("Name", "SmallTextFont", 10, h / 2, colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        DrawText("SteamID", "SmallTextFont", leftWidth + 10, h / 2, colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        DrawText("Rank", "SmallTextFont", leftWidth + middleWidth + 10, h / 2, colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local players = player.GetAll()
    for _, ply in ipairs(players) do
        if ply:IsBot() then continue end
        
        local plyName = ply:Nick()
        local plySteamID = ply:SteamID()
        local playerRank = ply:GetNWInt("PlayerRank", 0)
        local rankName = RankNames[playerRank] or "Player"
        local rankColor = rankColors[rankName] or Color(255, 255, 255)

        local playerPanel = vgui.Create("DPanel", self.PlayerListPanel)
        playerPanel:Dock(TOP)
        playerPanel:SetHeight(40)
        playerPanel:DockMargin(10, 10, 10, 0)
        
        playerPanel.Paint = function(self, w, h)
            local leftWidth = w * 0.4
            local middleWidth = w * 0.4

            surface.SetDrawColor(0, 0, 0, 0) 
            surface.DrawRect(0, 0, w, h)

            DrawText(plyName, "SmallTextFont", 10, h / 2, colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            DrawText(plySteamID, "SmallTextFont", leftWidth + 10, h / 2, colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            DrawText(rankName, "SmallTextFont", leftWidth + middleWidth + 10, h / 2, rankColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            surface.SetDrawColor(255, 255, 255, 100)
            surface.DrawLine(0, h - 1, w, h - 1)
        end
    end
end

function UI:UpdateServerLogs(parent)
    if not Iv(parent) then return end

    if Iv(self.PlayerListPanel) then
        self.PlayerListPanel:Remove()
    end

    self.PlayerListPanel = vgui.Create("DPanel", parent)
    self.PlayerListPanel:Dock(FILL)
    self.PlayerListPanel:DockMargin(0, 50, 0, 0) 
    self.PlayerListPanel.Paint = function(self, w, h)
        surface.SetDrawColor(0, 0, 0, 0)
    end

    local headerPanel = vgui.Create("DPanel", self.PlayerListPanel)
    headerPanel:Dock(TOP)
    headerPanel:SetHeight(30)
    headerPanel:DockMargin(10, 0, 10, 0)
    headerPanel.Paint = function(self, w, h)
        surface.SetDrawColor(32, 32, 32)
        surface.DrawRect(0, 0, w, h)

        DrawText("Logs Listing", "SmallTextFont", 10, h / 2, colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local scrollPanel = vgui.Create("DScrollPanel", self.PlayerListPanel)
    scrollPanel:Dock(FILL)
    scrollPanel:DockMargin(10, 5, 10, 10)

    if logs and #logs > 0 then
        for _, log in ipairs(logs) do
            local logPanel = vgui.Create("DPanel", scrollPanel)
            logPanel:Dock(TOP)
            logPanel:SetHeight(25)
            logPanel:DockMargin(0, 5, 0, 0)

            logPanel.Paint = function(self, w, h)
                surface.SetDrawColor(42, 42, 42)
                surface.DrawRect(0, 0, w, h)
                DrawText(log, "SmallTextFont", 10, h / 2, colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        end
    else
        local emptyLabel = vgui.Create("DLabel", scrollPanel)
        emptyLabel:SetText("No logs available yet.")
        emptyLabel:SetFont("SmallTextFont")
        emptyLabel:SizeToContents()
        emptyLabel:Dock(TOP)
        emptyLabel:DockMargin(10, 10, 10, 0)
    end
end

function CreateCustomButton(parent, buttonText, onClickFunc)
    local button = vgui.Create("DButton", parent)
    button:SetText("")
    button:SetSize(100, 30)

    button.Paint = function(self, w, h)
        local bgColor = self:IsHovered() and Color(32, 32, 32) or Color(100, 100, 100)
        surface.SetDrawColor(bgColor)
        surface.DrawRect(0, 0, w, h)

        DrawText(buttonText, "SmallTextFont", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    button.DoClick = onClickFunc

    return button
end

function CreateSettingRow(labelText, buttonText, parentPanel, onClickFunc)
    local rowPanel = vgui.Create("DPanel", parentPanel)
    rowPanel:Dock(TOP)
    rowPanel:SetHeight(40)
    rowPanel:DockMargin(10, 10, 10, 0)
    rowPanel.Paint = function(self, w, h)
        surface.SetDrawColor(0, 0, 0, 0) 
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(255, 255, 255, 100)
        surface.DrawLine(0, h - 1, w, h - 1)
    end

    local label = vgui.Create("DLabel", rowPanel)
    label:SetText(labelText)
    label:SetFont("SmallTextFont")
    label:Dock(LEFT)
    label:SetWidth(200)
    label:DockMargin(10, 0, 0, 0)
    label:SetTextColor(colors.text)

    local button = CreateCustomButton(rowPanel, buttonText, onClickFunc)
    button:Dock(RIGHT)
    button:SetWidth(100)
end

function UI:CreateInputBoxSettings(parent, y, command, defaultVal, labelText, infoText, minVal, maxVal)
    local pnl = vgui.Create("DPanel", parent)
    pnl:SetSize(parent:GetWide(), 80)
    pnl:SetPos(0, y)
    pnl.Paint = function(self, w, h)
        surface.SetDrawColor(0, 0, 0, 0)
        surface.DrawRect(0, 0, w, h)
    end

    local boxSize = 50
    minVal = minVal or 0
    maxVal = maxVal or 1000000

    local inputBox = vgui.Create("DTextEntry", pnl)
    inputBox:SetPos(pnl:GetWide() - 60, 0)
    inputBox:SetSize(boxSize, boxSize)
    inputBox:SetNumeric(true)
    inputBox:SetText(tostring(defaultVal))
    inputBox:SetFont("ToggleButtonFont")

    inputBox.Paint = function(self, w, h)
        surface.SetDrawColor(colors.toggleButton)
        surface.DrawRect(0, 0, w, h)
        self:DrawTextEntryText(Color(255, 255, 255), Color(30, 130, 255), Color(255, 255, 255))
    end

    if command == "bhop_admin_mapmultiplier" then
        net.Start("RequestMapMultiplier")
        net.SendToServer()
    end

    net.Receive("ReceiveMapMultiplier", function()
        local actualMultiplier = net.ReadFloat()
        inputBox:SetText(tostring(actualMultiplier))
    end)

    inputBox.OnChange = function(self)
        local value = tonumber(self:GetValue()) or minVal
        if value < minVal then
            self:SetText(tostring(minVal))
        elseif value > maxVal then
            self:SetText(tostring(maxVal))
        end
    end

    inputBox.OnEnter = function(self)
        local newValue = math.Clamp(tonumber(self:GetValue()) or minVal, minVal, maxVal)
        self:SetText(tostring(newValue))

        if command == "bhop_admin_mapmultiplier" then
            net.Start("AdminChangeMapMultiplier")
            net.WriteFloat(newValue)
            net.SendToServer()
        else
            net.Start("AdminChangeMovementSetting")
            net.WriteString(command)
            net.WriteFloat(newValue)
            net.SendToServer()
        end
    end

    local lbl = vgui.Create("DLabel", parent)
    lbl:SetPos(10, y + 8)
    lbl:SetText(labelText)
    lbl:SetTextColor(colors.text)
    lbl:SetFont("ToggleButtonFont")
    lbl:SizeToContents()

    local infoLbl = vgui.Create("DLabel", parent)
    infoLbl:SetPos(10, y + 28)
    infoLbl:SetText(infoText)
    infoLbl:SetTextColor(colors.infoText)
    infoLbl:SetFont("SmallTextFont")
    infoLbl:SizeToContents()

    return pnl, lbl, infoLbl, inputBox
end

function UI:UpdateAdminSettings(parent)
    if not Iv(parent) then return end

    if Iv(self.PlayerListPanel) then
        self.PlayerListPanel:Remove()
    end

    self.PlayerListPanel = vgui.Create("DPanel", parent)
    self.PlayerListPanel:Dock(FILL)
    self.PlayerListPanel:DockMargin(0, 50, 0, 0)
    self.PlayerListPanel.Paint = function(self, w, h)
        surface.SetDrawColor(0, 0, 0, 0)
    end

    local headerPanel = vgui.Create("DPanel", self.PlayerListPanel)
    headerPanel:Dock(TOP)
    headerPanel:SetHeight(30)
    headerPanel:DockMargin(10, 0, 10, 0)
    headerPanel.Paint = function(self, w, h)
        surface.SetDrawColor(32, 32, 32)
        surface.DrawRect(0, 0, w, h)
        DrawText("Settings", "SmallTextFont", 10, h / 2, colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        DrawText("Options", "SmallTextFont", w * 0.5 + 290, h / 2, colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    CreateSettingRow("Normal Start", "Set Start", self.PlayerListPanel, function()
        net.Start("AdminHandleRequest")
        net.WriteInt(1, 8)
        net.WriteInt(0, 8)
        net.SendToServer()
    end)

    CreateSettingRow("Normal End", "Set End", self.PlayerListPanel, function()
        net.Start("AdminHandleRequest")
        net.WriteInt(1, 8)  
        net.WriteInt(1, 8)
        net.SendToServer()
    end)

    CreateSettingRow("Bonus Start", "Set Start", self.PlayerListPanel, function()
        net.Start("AdminHandleRequest")
        net.WriteInt(1, 8)  
        net.WriteInt(2, 8)
        net.SendToServer()
    end)

    CreateSettingRow("Bonus End", "Set End", self.PlayerListPanel, function()
        net.Start("AdminHandleRequest")
        net.WriteInt(1, 8)  
        net.WriteInt(3, 8)
        net.SendToServer()
    end)

    CreateSettingRow("Change Map", "Change", self.PlayerListPanel, function() 
        UI:OpenChangeMapUI() 
    end)
end

function UI:OpenChangeMapUI()
    local frame = vgui.Create("DFrame")
    frame:SetTitle("Change Map")
    frame:SetSize(300, 150)
    frame:Center()
    frame:MakePopup()

    local label = vgui.Create("DLabel", frame)
    label:SetText("Map Name:")
    label:SetFont("SmallTextFont")
    label:Dock(TOP)
    label:SetHeight(30)
    label:DockMargin(10, 10, 10, 0)
    label:SetTextColor(colors.text)

    local mapInput = vgui.Create("DTextEntry", frame)
    mapInput:Dock(TOP)
    mapInput:SetHeight(30)
    mapInput:DockMargin(10, 0, 10, 0)

    local buttonPanel = vgui.Create("DPanel", frame)
    buttonPanel:Dock(BOTTOM)
    buttonPanel:SetHeight(40)
    buttonPanel:DockMargin(10, 10, 10, 0)
    buttonPanel.Paint = function(self, w, h)
        surface.SetDrawColor(0, 0, 0, 0)
    end

    local enterButton = vgui.Create("DButton", buttonPanel)
    enterButton:SetText("Enter")
    enterButton:Dock(LEFT)
    enterButton:SetWidth(100)
    enterButton.DoClick = function()
        local mapName = mapInput:GetValue()
        if mapName ~= "" then
            net.Start("AdminChangeMap")
            net.WriteString(mapName)
            net.SendToServer()
            frame:Close()
        else
            print("ERROR")
        end
    end

    local closeButton = vgui.Create("DButton", buttonPanel)
    closeButton:SetText("Close")
    closeButton:Dock(RIGHT)
    closeButton:SetWidth(100)
    closeButton.DoClick = function()
        frame:Close()
    end
end

local cos, sin, rad = math.cos, math.sin, math.rad
function BuildCircularAvatarPic(base, x, y, radius, steamid64)
    local pan = base:Add('DPanel')
    pan:SetPos(x, y)
    pan:SetSize(radius * 2, radius * 2)
    pan.mask = radius

    pan.avatar = pan:Add('AvatarImage')
    pan.avatar:SetSize(pan:GetWide(), pan:GetTall())
    pan.avatar:SetSteamID(steamid64, 184)
    pan.avatar:SetPaintedManually(true)

    function pan:Paint(w, h)
        render.ClearStencil()
        render.SetStencilEnable(true)

        render.SetStencilWriteMask(1)
        render.SetStencilTestMask(1)
        render.SetStencilFailOperation(STENCILOPERATION_REPLACE)
        render.SetStencilPassOperation(STENCILOPERATION_KEEP)
        render.SetStencilZFailOperation(STENCILOPERATION_KEEP)
        render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_NEVER)
        render.SetStencilReferenceValue(1)

        local circle = {}
        for i = 0, 360, 5 do
            local t = rad(i)
            circle[#circle + 1] = {x = w / 2 + cos(t) * self.mask, y = h / 2 + sin(t) * self.mask}
        end

        draw.NoTexture()
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawPoly(circle)

        render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)

        self.avatar:SetPaintedManually(false)
        self.avatar:PaintManual()
        self.avatar:SetPaintedManually(true)

        render.SetStencilEnable(false)
        render.ClearStencil()
    end
end

local sin, rad = math.sin, math.rad
local maxColorValue, halfMaxValue = 255, 127.5

function DrawRainbowText(text, font, x, y)
    local frequency = 1 
    local phase = RealTime() * frequency
    local colorOffset = 360 / #text

    for i = 1, #text do
        local letter = text:sub(i, i)
        local angle = (i - 1) * colorOffset + phase

        local r = sin(rad(angle)) * halfMaxValue + halfMaxValue
        local g = sin(rad(angle + 120)) * halfMaxValue + halfMaxValue
        local b = sin(rad(angle + 240)) * halfMaxValue + halfMaxValue
        local textColor = Color(r, g, b)

        DrawText(letter, font, x, y, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        x = x + surface.GetTextSize(letter)
    end
end