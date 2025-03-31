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
    hightlight = Color(0, 255, 255),
    scrollbar = Color(60, 60, 60),
    scrollbarbackground = Color(40, 40, 40)
}

local function ConVarExists(name)
    return GetConVar(name) ~= nil
end

function UI:MenuScrollbar(vBar, barColor, btnColor, gripColor)
    vBar:SetWide(8)

    vBar.Paint = function(self, w, h)
        surface.SetDrawColor(barColor or colors.scrollbarbackground)
        surface.DrawRect(0, 0, w, h)
    end

    vBar.btnUp.Paint = function(self, w, h)
        surface.SetDrawColor(btnColor or colors.scrollbar)
        surface.DrawRect(0, 0, w, h)
    end

    vBar.btnDown.Paint = function(self, w, h)
        surface.SetDrawColor(btnColor or colors.scrollbar)
        surface.DrawRect(0, 0, w, h)
    end

    vBar.btnGrip.Paint = function(self, w, h)
        surface.SetDrawColor(gripColor or Color(255, 255, 255))
        surface.DrawRect(0, 0, w, h)
    end
end

function UI:ColorBox(parent, y, convarName, labelText, infoText)
    local pnl = vgui.Create("DPanel", parent)
    pnl:SetSize(parent:GetWide(), 90)
    pnl:SetPos(0, y)

    local colStr = GetConVar(convarName):GetString()
    local r, g, b = string.match(colStr, "(%d+)%s+(%d+)%s+(%d+)")
    local color = Color(tonumber(r) or 255, tonumber(g) or 255, tonumber(b) or 255)

    pnl.Paint = function(self, w, h)
        surface.SetDrawColor(colors.box)
        surface.DrawOutlinedRect(w - 60, 15, 36, 36, 2)
        surface.SetDrawColor(color)
        surface.DrawRect(w - 56, 19, 28, 28)
    end

    pnl.OnMousePressed = function()
        local frame = vgui.Create("DFrame")
        frame:SetSize(300, 260)
        frame:Center()
        frame:SetTitle("")
        frame:ShowCloseButton(false)
        frame:MakePopup()
        frame.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(30, 30, 30, 255))
            draw.SimpleText("Pick a Color", "ui.mainmenu.button", w / 2, 10, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        end

        local mixer = vgui.Create("DColorMixer", frame)
        mixer:SetSize(280, 200)
        mixer:SetPos(10, 40)
        mixer:SetPalette(true)
        mixer:SetAlphaBar(false)
        mixer:SetWangs(true)
        mixer:SetColor(color)
        mixer.ValueChanged = function(_, newColor)
            color = newColor
            RunConsoleCommand(convarName, newColor.r .. " " .. newColor.g .. " " .. newColor.b)
        end

        local close = vgui.Create("DButton", frame)
        close:SetSize(20, 20)
        close:SetPos(frame:GetWide() - 28, 8)
        close:SetText("")
        close.Paint = function(self, w, h)
            surface.SetDrawColor(self:IsHovered() and Color(255, 0, 0) or Color(200, 200, 200))
            surface.DrawLine(5, 5, w - 5, h - 5)
            surface.DrawLine(w - 5, 5, 5, h - 5)
        end
        close.DoClick = function()
            frame:Close()
        end
    end

    local lbl = vgui.Create("DLabel", parent)
    lbl:SetPos(10, y + 10)
    lbl:SetText(labelText)
    lbl:SetTextColor(colors.text)
    lbl:SetFont("ui.mainmenu.button")
    lbl:SizeToContents()

    local infoLbl = vgui.Create("DLabel", parent)
    infoLbl:SetPos(10, y + 34)
    infoLbl:SetText(infoText)
    infoLbl:SetTextColor(colors.infoText)
    infoLbl:SetFont("ui.mainmenu.button")
    infoLbl:SizeToContents()

    return pnl, lbl, infoLbl
end

function UI:CreateCustomDropdown(parent, y, themeID, labelText, themeOptions)
    local pnl = vgui.Create("DPanel", parent)
    pnl:SetSize(parent:GetWide(), 80)
    pnl:SetPos(0, y)

    pnl.Paint = function(self, w, h)
        draw.RoundedBox(0, 10, 5, w - 20, 70, Color(42, 42, 42, 250))
        draw.SimpleText(labelText, "ui.mainmenu.button", 20, 15, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    local dropdownButton = vgui.Create("DButton", pnl)
    dropdownButton:SetPos(20, 40)
    dropdownButton:SetSize(200, 25)
    dropdownButton:SetText("")

    local isHudHidden = GetConVar("bhop_hud_hide"):GetBool()
    local selectedTheme = isHudHidden and "disabled" or Settings:GetValue("selected.hud", "hud.css")
    local selectedText = isHudHidden and "Select an option" or (themeOptions[selectedTheme] or "Select an option")

    local dropdownOpen = false

    dropdownButton.Paint = function(self, w, h)
        local bgColor = self:IsHovered() and Color(50, 50, 50, 255) or Color(35, 35, 35, 255)
        draw.RoundedBox(0, 0, 0, w, h, bgColor)

        draw.SimpleText(selectedText, "ui.mainmenu.button", 10, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

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
            draw.SimpleText(name, "ui.mainmenu.button", 10, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        option.DoClick = function()
            dropdownOpen = false
            dropdownMenu:SetVisible(false)

            if id == "disabled" then
                selectedText = "Select an option"
                RunConsoleCommand("bhop_hud_hide", "1")
            else
                selectedText = name
                RunConsoleCommand("bhop_hud_hide", "0")
                Settings:SetValue("selected.hud", id)
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
        draw.SimpleText(labelText, "ui.mainmenu.button", 20, 15, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
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

        draw.SimpleText(selectedText, "ui.mainmenu.button", 10, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

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

function UI:CreateCustomDropdownSB(parent, y, cvarName, labelText, options)
    local pnl = vgui.Create("DPanel", parent)
    pnl:SetSize(parent:GetWide(), 200)
    pnl:SetPos(0, y)

    pnl.Paint = function(self, w, h)
        draw.RoundedBox(0, 10, 5, w - 20, 70, Color(42, 42, 42, 250))
        draw.SimpleText(labelText, "ui.mainmenu.button", 20, 15, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    local dropdownButton = vgui.Create("DButton", pnl)
    dropdownButton:SetPos(20, 40)
    dropdownButton:SetSize(200, 25)
    dropdownButton:SetText("")

    local selectedTheme = GetConVar(cvarName):GetString()
    local selectedText = options[selectedTheme] or "Select an option"
    local dropdownOpen = false

    dropdownButton.Paint = function(self, w, h)
        local bgColor = self:IsHovered() and Color(50, 50, 50, 255) or Color(35, 35, 35, 255)
        draw.RoundedBox(0, 0, 0, w, h, bgColor)
        draw.SimpleText(selectedText, "ui.mainmenu.button", 10, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        surface.SetDrawColor(200, 200, 200, 255)
        draw.NoTexture()
        surface.DrawPoly({
            { x = w - 20, y = h / 2 - 4 },
            { x = w - 10, y = h / 2 - 4 },
            { x = w - 15, y = h / 2 + 4 }
        })
    end

    local dropdownMenu = vgui.Create("DPanel", pnl)
    dropdownMenu:SetSize(200, 25 * table.Count(options))
    dropdownMenu:SetPos(20, 70)
    dropdownMenu:SetVisible(false)

    dropdownMenu.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(25, 25, 25, 255))
    end

    local yOffset = 0
    for id, name in pairs(options) do
        local option = vgui.Create("DButton", dropdownMenu)
        option:SetSize(200, 25)
        option:SetPos(0, yOffset)
        option:SetText("")

        option.Paint = function(self, w, h)
            local bgColor = self:IsHovered() and Color(60, 60, 60, 255) or Color(35, 35, 35, 255)
            draw.RoundedBox(0, 0, 0, w, h, bgColor)
            draw.SimpleText(name, "ui.mainmenu.button", 10, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        option.DoClick = function()
            selectedText = name
            selectedTheme = id
            RunConsoleCommand(cvarName, id)
            dropdownOpen = false
            dropdownMenu:SetVisible(false)
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
        local isHudHidden = GetConVar("bhop_hud_hide"):GetBool()
        local isActive = (not isHudHidden and selectedTheme == themeID) or (themeID == 0 and isHudHidden)

        if themeID == 0 then
            local boxColor = isActive and Color(50, 205, 50) or Color(255, 69, 0)
            local knobColor = Color(255, 255, 255)

            draw.RoundedBox(8, w - 60, 20, 50, 20, boxColor)

            if isActive then
                draw.RoundedBox(8, w - 30, 20, 20, 20, knobColor) -- Green (ON)
            else
                draw.RoundedBox(8, w - 60, 20, 20, 20, knobColor) -- Red (OFF)
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
        if themeID == 0 then
            RunConsoleCommand("bhop_hud_hide", "1")
            Settings:SetValue('selected.hud', "disabled")
            Theme:DisableHUD()

            selectedTheme = "disabled"
        else
            RunConsoleCommand("bhop_hud_hide", "0")
            Settings:SetValue('selected.hud', themeID)

            selectedTheme = themeID
        end

        parent:InvalidateLayout(true)
    end

    local lbl = vgui.Create("DLabel", parent)
    lbl:SetPos(10, y + 8)
    lbl:SetText(labelText)
    lbl:SetTextColor(colors.text)
    lbl:SetFont("ui.mainmenu.button")
    lbl:SizeToContents()

    local infoLbl = vgui.Create("DLabel", parent)
    infoLbl:SetPos(10, y + 28)
    infoLbl:SetText("Enable HUD for " .. labelText)
    infoLbl:SetTextColor(colors.infoText)
    infoLbl:SetFont("ui.mainmenu.button")
    infoLbl:SizeToContents()

    return pnl, lbl, infoLbl
end

function UI:CreateInputBox(parent, y, command, defaultVal, labelText, infoText, minVal, maxVal)
    local pnl = vgui.Create("DPanel", parent)
    pnl:SetSize(parent:GetWide(), 90)
    pnl:SetPos(0, y)
    pnl.Paint = function(self, w, h)
        surface.SetDrawColor(0, 0, 0, 0)
        surface.DrawRect(0, 0, w, h)
    end

    minVal = minVal or 0
    maxVal = maxVal or 10

    local cvarValue = GetConVar(command) and GetConVar(command):GetFloat() or defaultVal

    local inputBox = vgui.Create("DTextEntry", pnl)
    inputBox:SetPos(pnl:GetWide() - 60, 15)
    inputBox:SetSize(36, 36)
    inputBox:SetNumeric(true)

    local function formatValue(val)
        return tonumber(string.format("%.1f", val))
    end

    inputBox:SetText(tostring(formatValue(cvarValue)))
    inputBox:SetFont("ui.mainmenu.button")

    inputBox.Paint = function(self, w, h)
        surface.SetDrawColor(colors.box)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        surface.SetDrawColor(colors.toggleButton)
        surface.DrawRect(2, 2, w - 4, h - 4)
        self:DrawTextEntryText(Color(255, 255, 255), Color(30, 130, 255), Color(255, 255, 255))
    end

    inputBox.OnChange = function(self)
        local value = tonumber(self:GetValue()) or minVal
        if value < minVal then
            value = minVal
        elseif value > maxVal then
            value = maxVal
        end
        self:SetText(tostring(formatValue(value)))
    end

    inputBox.OnEnter = function(self)
        local newValue = math.Clamp(tonumber(self:GetValue()) or minVal, minVal, maxVal)
        newValue = formatValue(newValue)
        self:SetText(tostring(newValue))
        lp():ConCommand(command .. " " .. tostring(newValue))
    end

    local lbl = vgui.Create("DLabel", parent)
    lbl:SetPos(10, y + 10)
    lbl:SetText(labelText)
    lbl:SetTextColor(colors.text)
    lbl:SetFont("ui.mainmenu.button")
    lbl:SizeToContents()

    local infoLbl = vgui.Create("DLabel", parent)
    infoLbl:SetPos(10, y + 34)
    infoLbl:SetText(infoText)
    infoLbl:SetTextColor(colors.infoText)
    infoLbl:SetFont("ui.mainmenu.button")
    infoLbl:SizeToContents()

    return pnl, lbl, infoLbl, inputBox
end

function UI:CreateInputBoxText(parent, y, command, defaultVal, labelText, infoText)
    local pnl = vgui.Create("DPanel", parent)
    pnl:SetSize(parent:GetWide(), 90)
    pnl:SetPos(0, y)
    pnl.Paint = function(self, w, h)
        surface.SetDrawColor(0, 0, 0, 0)
        surface.DrawRect(0, 0, w, h)
    end

    local cvarValue = GetConVar(command) and GetConVar(command):GetString() or defaultVal or "pyramid"

    local inputBox = vgui.Create("DTextEntry", pnl)
    inputBox:SetPos(pnl:GetWide() - 60, 15)
    inputBox:SetSize(36, 36)
    inputBox:SetText(cvarValue)
    inputBox:SetFont("ui.mainmenu.desc")

    inputBox.Paint = function(self, w, h)
        surface.SetDrawColor(colors.box)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        surface.SetDrawColor(colors.toggleButton)
        surface.DrawRect(2, 2, w - 4, h - 4)
        self:DrawTextEntryText(Color(255, 255, 255), Color(30, 130, 255), Color(255, 255, 255))
    end

    inputBox.OnEnter = function(self)
        local newValue = self:GetValue() or defaultVal or "pyramid"
        lp():ConCommand(command .. " " .. newValue)
    end

    -- Labels
    local lbl = vgui.Create("DLabel", parent)
    lbl:SetPos(10, y + 10)
    lbl:SetText(labelText)
    lbl:SetTextColor(colors.text)
    lbl:SetFont("ui.mainmenu.button")
    lbl:SizeToContents()

    local infoLbl = vgui.Create("DLabel", parent)
    infoLbl:SetPos(10, y + 34)
    infoLbl:SetText(infoText)
    infoLbl:SetTextColor(colors.infoText)
    infoLbl:SetFont("ui.mainmenu.button")
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
    lbl:SetFont("ui.mainmenu.button")
    lbl:SizeToContents()

    local dropdown = vgui.Create("DComboBox", pnl)
    dropdown:SetPos(10, 40)
    dropdown:SetSize(parent:GetWide() - 200, 30)
    dropdown:SetValue(defaultText)
    dropdown:SetFont("ui.mainmenu.button")

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
            option:SetFont("ui.mainmenu.button")
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
    lbl:SetFont("ui.mainmenu.button")
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
    pnl:SetSize(parent:GetWide(), 90)
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
        surface.DrawOutlinedRect(w - 60, 15, 36, 36, 2)

        if isActive then
            surface.SetDrawColor(DynamicColors.PanelColor)
            surface.DrawRect(w - 56, 19, 28, 28)
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
    lbl:SetPos(10, y + 10)
    lbl:SetText(labelText)
    lbl:SetTextColor(colors.text)
    lbl:SetFont("ui.mainmenu.button")
    lbl:SizeToContents()

    local infoLbl = vgui.Create("DLabel", parent)
    infoLbl:SetPos(10, y + 34)
    infoLbl:SetText(infoText)
    infoLbl:SetTextColor(colors.infoText)
    infoLbl:SetFont("ui.mainmenu.button")
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
    slider.TextArea:SetFont("ui.mainmenu.button")

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
    lbl:SetFont("ui.mainmenu.button")
    lbl:SizeToContents()

    local infoLbl = vgui.Create("DLabel", parent)
    infoLbl:SetPos(10, y + 18)
    infoLbl:SetText("Disables or enables rounded boxes")
    infoLbl:SetTextColor(colors.infoText)
    infoLbl:SetFont("ui.mainmenu.button")
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

        DrawText("Name", "ui.mainmenu.button", 10, h / 2, colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        DrawText("SteamID", "ui.mainmenu.button", leftWidth + 10, h / 2, colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        DrawText("Rank", "ui.mainmenu.button", leftWidth + middleWidth + 10, h / 2, colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
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

            DrawText(plyName, "ui.mainmenu.button", 10, h / 2, colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            DrawText(plySteamID, "ui.mainmenu.button", leftWidth + 10, h / 2, colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            DrawText(rankName, "ui.mainmenu.button", leftWidth + middleWidth + 10, h / 2, rankColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            surface.SetDrawColor(255, 255, 255, 100)
            surface.DrawLine(0, h - 1, w, h - 1)
        end
    end
end

net.Receive("SendAdminLogs", function()
    local count = net.ReadUInt(16)
    local logs = {}

    for i = 1, count do
        local date = net.ReadString()
        local admin = net.ReadString()
        local steam = net.ReadString()
        local action = net.ReadString()

        local logText = "[" .. date .. "] " .. admin .. " (" .. steam .. "): " .. action
        table.insert(logs, logText)
    end

    if UI and UI.UpdateServerLogs and IsValid(UI.CurrentLogsPanel) then
        print("[Client] Updating logs into panel.")
        UI:UpdateServerLogs(UI.CurrentLogsPanel, logs)
    else
        print("[Client] Panel not valid or missing")
    end
end)

function UI:UpdateServerLogs(parent, logs)
    if not Iv(parent) then return end

    self.LogsPanel = vgui.Create("DPanel", parent)
    self.LogsPanel:Dock(FILL)
    self.LogsPanel:DockMargin(0, 50, 0, 0)
    self.LogsPanel.Paint = function(self, w, h)
        surface.SetDrawColor(0, 0, 0, 0)
    end

    local scrollPanel = vgui.Create("DScrollPanel", self.LogsPanel)
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
                DrawText(log, "ui.mainmenu.logs", 10, h / 2, colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        end
    else
        local emptyLabel = vgui.Create("DLabel", scrollPanel)
        emptyLabel:SetText("No logs available yet.")
        emptyLabel:SetFont("ui.mainmenu.button")
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

        DrawText(buttonText, "ui.mainmenu.button", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
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
    label:SetFont("ui.mainmenu.button")
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

    local convarVal = ConVarExists(command) and GetConVar(command):GetFloat() or defaultVal
    inputBox:SetText(string.format("%.2f", convarVal))

    inputBox:SetFont("ui.mainmenu.button")

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
    lbl:SetFont("ui.mainmenu.button")
    lbl:SizeToContents()

    local infoLbl = vgui.Create("DLabel", parent)
    infoLbl:SetPos(10, y + 28)
    infoLbl:SetText(infoText)
    infoLbl:SetTextColor(colors.infoText)
    infoLbl:SetFont("ui.mainmenu.button")
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
        DrawText("Settings", "ui.mainmenu.button", 10, h / 2, colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        DrawText("Options", "ui.mainmenu.button", w * 0.5 + 290, h / 2, colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
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
    label:SetFont("ui.mainmenu.button")
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

function UI:CreateResetAllButton(parent, y, convarTable, labelText, infoText)
    local pnl = vgui.Create("DPanel", parent)
    pnl:SetSize(parent:GetWide(), 90)
    pnl:SetPos(0, y)
    pnl.Paint = function(self, w, h)
        surface.SetDrawColor(0, 0, 0, 0)
        surface.DrawRect(0, 0, w, h)
    end

    -- Text
    local lbl = vgui.Create("DLabel", parent)
    lbl:SetPos(10, y + 10)
    lbl:SetText(labelText or "Reset All Settings")
    lbl:SetTextColor(colors.text)
    lbl:SetFont("ui.mainmenu.button")
    lbl:SizeToContents()

    -- Info Text
    local infoLbl = vgui.Create("DLabel", parent)
    infoLbl:SetPos(10, y + 34)
    infoLbl:SetText(infoText or "This will reset all settings to their default values.")
    infoLbl:SetTextColor(colors.infoText)
    infoLbl:SetFont("ui.mainmenu.button")
    infoLbl:SizeToContents()

    -- Reset All Button
    local resetBtn = vgui.Create("DButton", pnl)
    resetBtn:SetText("")
    resetBtn:SetSize(120, 36)
    resetBtn:SetPos(pnl:GetWide() - 140, 15)
    resetBtn:SetFont("ui.mainmenu.button")
    resetBtn.Paint = function(self, w, h)
        surface.SetDrawColor(colors.box)
        surface.DrawOutlinedRect(0, 0, w, h, 2)

        if self:IsHovered() then
            surface.SetDrawColor(200, 50, 50, 255)
        else
            surface.SetDrawColor(colors.toggleButton)
        end

        surface.DrawRect(2, 2, w - 4, h - 4)
        draw.SimpleText("Reset All", "ui.mainmenu.button", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    resetBtn.DoClick = function()
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
            draw.SimpleText("Reset ALL settings to defaults?", "ui.mainmenu.button", w / 2, 30, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        -- Confirm
        local yesBtn = vgui.Create("DButton", confirm)
        yesBtn:SetText("")
        yesBtn:SetSize(120, 30)
        yesBtn:SetPos(30, 80)
        yesBtn.Paint = function(self, w, h)
            surface.SetDrawColor(colors.box)
            surface.DrawOutlinedRect(0, 0, w, h, 2)

            if self:IsHovered() then
                surface.SetDrawColor(0, 255, 0, 255)
            else
                surface.SetDrawColor(colors.toggleButton)
            end

            surface.DrawRect(2, 2, w - 4, h - 4)
            draw.SimpleText("Yes", "ui.mainmenu.button", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        yesBtn.DoClick = function()
            for convar, default in pairs(convarTable) do
                RunConsoleCommand(convar, default)
            end

            UTIL:AddMessage("Settings", color_white, "All ", Color(255 ,0, 0), "settings" , color_white, " reset to defaults!")
            confirm:Close()
        end

        -- Cancel
        local noBtn = vgui.Create("DButton", confirm)
        noBtn:SetText("")
        noBtn:SetSize(120, 30)
        noBtn:SetPos(150, 80)
        noBtn.Paint = function(self, w, h)
            surface.SetDrawColor(colors.box)
            surface.DrawOutlinedRect(0, 0, w, h, 2)

            if self:IsHovered() then
                surface.SetDrawColor(80, 80, 80, 255)
            else
                surface.SetDrawColor(colors.toggleButton)
            end

            surface.DrawRect(2, 2, w - 4, h - 4)
            draw.SimpleText("Cancel", "ui.mainmenu.button", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        noBtn.DoClick = function()
            confirm:Close()
        end
    end

    return pnl, lbl, infoLbl, resetBtn
end