local lp, Iv, DrawText, Text, hook_Add = LocalPlayer, IsValid, draw.SimpleText, draw.DrawText, hook.Add

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

function UI:CreateCustomDropdown(parent, y, labelText, infoText, themeOptions)
    local pnl = vgui.Create("DPanel", parent)
    pnl:SetSize(parent:GetWide(), 90)
    pnl:SetPos(0, y)

    local selectedTheme = GetConVar("bhop_hud_hide"):GetBool() and "disabled" or Settings:GetValue("selected.hud", "hud.css")
    local selectedText = selectedTheme == "disabled" and "Select an option" or (themeOptions[selectedTheme] or "Select an option")

    -- background
    pnl.Paint = function(self, w, h)
        local bgW, bgH = w - 20, 70
        -- draw.RoundedBox(0, 10, 5, bgW, bgH, Color(42, 42, 42, 250))
    end

    local lbl = vgui.Create("DLabel", pnl)
    lbl:SetPos(20, 10)
    lbl:SetText(labelText)
    lbl:SetTextColor(colors.text)
    lbl:SetFont("ui.mainmenu.button")
    lbl:SizeToContents()

    local infoLbl = vgui.Create("DLabel", pnl)
    infoLbl:SetPos(20, 30)
    infoLbl:SetText(infoText or "")
    infoLbl:SetTextColor(colors.infoText)
    infoLbl:SetFont("ui.mainmenu.button")
    infoLbl:SizeToContents()

    local dropdownButton = vgui.Create("DButton", pnl)
    local btnW, btnH = 200, 25
    local btnX = pnl:GetWide() - btnW - 20
    local btnY = 15

    dropdownButton:SetSize(btnW, btnH)
    dropdownButton:SetPos(btnX, btnY)

    dropdownButton:SetText("")
    dropdownButton:SetCursor("hand")

    local dropdownOpen = false

    dropdownButton.Paint = function(self, w, h)
        local bgColor = self:IsHovered() and Color(50, 50, 50, 255) or Color(35, 35, 35, 255)
        draw.RoundedBox(0, 0, 0, w, h, bgColor)

        draw.SimpleText(selectedText, "ui.mainmenu.button", 10, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        surface.SetDrawColor(200, 200, 200, 255)
        surface.DrawPoly({
            { x = w - 20, y = h / 2 - 4 },
            { x = w - 10, y = h / 2 - 4 },
            { x = w - 15, y = h / 2 + 4 }
        })
    end

    local dropdownMenu = vgui.Create("DPanel", parent)
    dropdownMenu:SetSize(200, 25 * table.Count(themeOptions))
    dropdownMenu:SetPos(dropdownButton:LocalToScreen(535, 85))
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
        option:SetCursor("hand")

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

function UI:CreateCustomDropdownPreset(parent, y, labelText, infoText, themeOptions)
    local pnl = vgui.Create("DPanel", parent)
    pnl:SetSize(parent:GetWide(), 90)
    pnl:SetPos(0, y)

    local selectedTheme = Settings:GetValue('selected.nui', "nui.css")
    local selectedText = themeOptions[selectedTheme] or "Select an option"

    -- background
    pnl.Paint = function(self, w, h)
        local bgW, bgH = w - 20, 70
        -- draw.RoundedBox(0, 10, 5, bgW, bgH, Color(42, 42, 42, 250))
    end

    local lbl = vgui.Create("DLabel", pnl)
    lbl:SetPos(20, 10)
    lbl:SetText(labelText)
    lbl:SetTextColor(colors.text)
    lbl:SetFont("ui.mainmenu.button")
    lbl:SizeToContents()

    local infoLbl = vgui.Create("DLabel", pnl)
    infoLbl:SetPos(20, 30)
    infoLbl:SetText(infoText or "")
    infoLbl:SetTextColor(colors.infoText)
    infoLbl:SetFont("ui.mainmenu.button")
    infoLbl:SizeToContents()

    local dropdownButton = vgui.Create("DButton", pnl)
    local btnW, btnH = 200, 25
    local btnX = pnl:GetWide() - btnW - 20
    local btnY = 15

    dropdownButton:SetSize(btnW, btnH)
    dropdownButton:SetPos(btnX, btnY)

    dropdownButton:SetText("")
    dropdownButton:SetCursor("hand")

    local dropdownOpen = false

    dropdownButton.Paint = function(self, w, h)
        local bgColor = self:IsHovered() and Color(50, 50, 50, 255) or Color(35, 35, 35, 255)
        draw.RoundedBox(0, 0, 0, w, h, bgColor)

        draw.SimpleText(selectedText, "ui.mainmenu.button", 10, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        surface.SetDrawColor(200, 200, 200, 255)
        surface.DrawPoly({
            { x = w - 20, y = h / 2 - 4 },
            { x = w - 10, y = h / 2 - 4 },
            { x = w - 15, y = h / 2 + 4 }
        })
    end

    local dropdownMenu = vgui.Create("DPanel", parent)
    dropdownMenu:SetSize(200, 25 * table.Count(themeOptions))
    dropdownMenu:SetPos(dropdownButton:LocalToScreen(535, 85))
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
        option:SetCursor("hand")

        option.Paint = function(self, w, h)
            local bgColor = self:IsHovered() and Color(60, 60, 60, 255) or Color(35, 35, 35, 255)
            draw.RoundedBox(0, 0, 0, w, h, bgColor)
            draw.SimpleText(name, "ui.mainmenu.button", 10, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
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

function UI:CreateCustomDropdownSB(parent, y, cvarName, labelText, infoText, options)
    local pnl = vgui.Create("DPanel", parent)
    pnl:SetSize(parent:GetWide(), 90)
    pnl:SetPos(0, y)

    pnl.Paint = function(self, w, h) end

    local lbl = vgui.Create("DLabel", pnl)
    lbl:SetPos(20, 10)
    lbl:SetText(labelText)
    lbl:SetTextColor(colors.text)
    lbl:SetFont("ui.mainmenu.button")
    lbl:SizeToContents()

    -- label
    local infoLbl = vgui.Create("DLabel", pnl)
    infoLbl:SetPos(20, 30)
    infoLbl:SetText(infoText or "")
    infoLbl:SetTextColor(colors.infoText)
    infoLbl:SetFont("ui.mainmenu.button")
    infoLbl:SizeToContents()

    -- dropdown
    local dropdownButton = vgui.Create("DButton", pnl)
    local btnW, btnH = 200, 25
    local btnX = pnl:GetWide() - btnW - 20
    local btnY = 15

    dropdownButton:SetSize(btnW, btnH)
    dropdownButton:SetPos(btnX, btnY)
    dropdownButton:SetText("")
    dropdownButton:SetCursor("hand")

    local selectedTheme = GetConVar(cvarName) and GetConVar(cvarName):GetString() or "default"
    local selectedText = options[selectedTheme] or "Select an option"
    local dropdownOpen = false

    dropdownButton.Paint = function(self, w, h)
        local bgColor = self:IsHovered() and Color(50, 50, 50, 255) or Color(35, 35, 35, 255)
        draw.RoundedBox(0, 0, 0, w, h, bgColor)
        draw.SimpleText(selectedText, "ui.mainmenu.button", 10, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        surface.SetDrawColor(200, 200, 200, 255)
        surface.DrawPoly({
            { x = w - 20, y = h / 2 - 4 },
            { x = w - 10, y = h / 2 - 4 },
            { x = w - 15, y = h / 2 + 4 }
        })
    end

    -- Dropdown menu
    local dropdownMenu = vgui.Create("DPanel", parent)
    dropdownMenu:SetSize(200, 25 * table.Count(options))
    dropdownMenu:SetPos(dropdownButton:LocalToScreen(535, 164))
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
        option:SetCursor("hand")

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
        local isActive = (themeID == 0 and selectedTheme == "disabled") or (themeID ~= 0 and selectedTheme == themeID)


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
        local isHudHidden = GetConVar("bhop_hud_hide"):GetBool()

        if themeID == 0 then
            if isHudHidden then
                -- Enable HUD
                RunConsoleCommand("bhop_hud_hide", "0")
                selectedTheme = Settings:GetValue("selected.nui", "nui.css")
                Settings:SetValue("selected.hud", selectedTheme)
            else
                -- Disable HUD
                RunConsoleCommand("bhop_hud_hide", "1")
                selectedTheme = "disabled"
                Settings:SetValue("selected.hud", "disabled")
                Theme:DisableHUD()
            end
        else
            RunConsoleCommand("bhop_hud_hide", "0")
            selectedTheme = themeID
            Settings:SetValue("selected.nui", themeID)
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

NETWORK:GetNetworkMessage("SendAdminLogs", function(_, data)
    local logs = {}

    for _, row in ipairs(data[1]) do
        local date = row.date or "Unknown"
        local admin = row.adminname or "Unknown"
        local steam = row.adminsteam or "Unknown"
        local action = row.data or "No data"

        local logText = "[" .. date .. "] " .. admin .. " (" .. steam .. "): " .. action
        table.insert(logs, logText)
    end

    if UI and UI.UpdateServerLogs and IsValid(UI.CurrentLogsPanel) then
        UI:UpdateServerLogs(UI.CurrentLogsPanel, logs)
    end
end)

function UI:UpdateServerLogs(parent, logs)
    if not IsValid(parent) then return end

    if IsValid(self.LogsPanel) then
        self.LogsPanel:Remove()
    end

    self.LogsPanel = vgui.Create("DPanel", parent)
    self.LogsPanel:Dock(FILL)
    self.LogsPanel:DockMargin(0, 50, 0, 0)
    self.LogsPanel.Paint = function(self, w, h)
        surface.SetDrawColor(0, 0, 0, 0)
    end

    local scrollPanel = vgui.Create("DScrollPanel", self.LogsPanel)
    scrollPanel:Dock(FILL)
    scrollPanel:DockMargin(10, 5, 10, 10)
    UI:MenuScrollbar(scrollPanel:GetVBar())

    local infoLabel = vgui.Create("DLabel", scrollPanel)
    infoLabel:SetText("Click any log entry to view more details.")
    infoLabel:SetFont("ui.mainmenu.button")
    infoLabel:SetTextColor(colors.text)
    infoLabel:Dock(TOP)
    infoLabel:DockMargin(0, 0, 0, 10)
    infoLabel:SizeToContents()

    if logs and #logs > 0 then
        for _, log in ipairs(logs) do
            local logPanel = vgui.Create("DPanel", scrollPanel)
            logPanel:Dock(TOP)
            logPanel:SetHeight(30)
            logPanel:DockMargin(0, 5, 0, 0)
            logPanel:SetCursor("hand")

            logPanel.Paint = function(self, w, h)
                surface.SetDrawColor(42, 42, 42)
                surface.DrawRect(0, 0, w, h)
                draw.SimpleText(log, "ui.mainmenu.logs", 10, h / 2, colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            logPanel.OnMousePressed = function()
                local frame = vgui.Create("DFrame")
                frame:SetTitle("")
                frame:SetSize(500, 200)
                frame:Center()
                frame:MakePopup()
                frame:ShowCloseButton(false)

                frame.Paint = function(self, w, h)
                    surface.SetDrawColor(32, 32, 32)
                    surface.DrawRect(0, 0, w, h)
                    draw.SimpleText("Admin Log Details", "ui.mainmenu.button", 15, 10, colors.text, TEXT_ALIGN_LEFT)
                end

                local textEntry = vgui.Create("DTextEntry", frame)
                textEntry:SetMultiline(true)
                textEntry:SetPos(20, 40)
                textEntry:SetSize(460, 100)
                textEntry:SetFont("ui.mainmenu.button")
                textEntry:SetText(log)
                textEntry:SetEditable(false)

                textEntry.Paint = function(self, w, h)
                    surface.SetDrawColor(42, 42, 42)
                    surface.DrawRect(0, 0, w, h)
                    self:DrawTextEntryText(colors.text, Color(100, 100, 255), colors.text)
                end

                local closeBtn = vgui.Create("DButton", frame)
                closeBtn:SetPos(20, 150)
                closeBtn:SetSize(460, 30)
                closeBtn:SetText("")
                closeBtn:SetFont("ui.mainmenu.button")

                closeBtn.Paint = function(self, w, h)
                    local hover = self:IsHovered()
                    surface.SetDrawColor(hover and Color(60, 60, 60) or Color(45, 45, 45))
                    surface.DrawRect(0, 0, w, h)
                    draw.SimpleText("Close", "ui.mainmenu.button", w / 2, h / 2, colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end

                closeBtn.DoClick = function()
                    frame:Close()
                end
            end
        end
    else
        local emptyLabel = vgui.Create("DLabel", scrollPanel)
        emptyLabel:SetText("No logs available yet.")
        emptyLabel:SetFont("ui.mainmenu.button")
        emptyLabel:SetTextColor(colors.text)
        emptyLabel:Dock(TOP)
        emptyLabel:DockMargin(10, 10, 10, 0)
        emptyLabel:SizeToContents()
    end
end

function CreateCustomButton(parent, buttonText, onClickFunc)
    local button = vgui.Create("DButton", parent)
    button:SetText("")
    button:SetSize(100, 30)

    button.Paint = function(self, w, h)
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

    if command == "bhop_settings_cap" then
        inputBox:SetText(math.Round(convarVal * 5))
    elseif command == "bhop_settings_mv" then
        inputBox:SetText(string.format("%.1f", convarVal + 0.4))
    else
        inputBox:SetText(math.Round(convarVal))
    end

    inputBox:SetFont("ui.mainmenu.button")

    inputBox.Paint = function(self, w, h)
        surface.SetDrawColor(colors.toggleButton)
        surface.DrawRect(0, 0, w, h)
        self:DrawTextEntryText(Color(255, 255, 255), Color(30, 130, 255), Color(255, 255, 255))
    end

    if command == "bhop_admin_mapmultiplier" then
        NETWORK:StartNetworkMessage(nil, "RequestMapMultiplier")
    end

    NETWORK:GetNetworkMessage("ReceiveMapMultiplier", function(_, data)
        local actualMultiplier = data[1]
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
            NETWORK:StartNetworkMessage(nil, "AdminChangeMapMultiplier", newValue)
        else
            NETWORK:StartNetworkMessage(nil, "AdminChangeMovementSetting", command, newValue)
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

function UI:OpenChangeMapUI()
    local frame = vgui.Create("DFrame")
    frame:SetTitle("")
    frame:SetSize(300, 150)
    frame:Center()
    frame:MakePopup()
    frame:ShowCloseButton(false)

    frame.Paint = function(self, w, h)
        surface.SetDrawColor(32, 32, 32)
        surface.DrawRect(0, 0, w, h)

        draw.SimpleText("Change Map", "ui.mainmenu.button", 15, 10, Color(255, 255, 255), TEXT_ALIGN_LEFT)
    end

    local mapInput = vgui.Create("DTextEntry", frame)
    mapInput:SetPos(20, 40)
    mapInput:SetSize(260, 30)
    mapInput:SetText("")
    mapInput:SetFont("ui.mainmenu.button")

    mapInput.Paint = function(self, w, h)
        surface.SetDrawColor(42, 42, 42)
        surface.DrawRect(0, 0, w, h)
        self:DrawTextEntryText(Color(255, 255, 255), Color(100, 100, 255), Color(255, 255, 255))
    end

    -- Enter Button
    local enterButton = vgui.Create("DButton", frame)
    enterButton:SetPos(20, 85)
    enterButton:SetSize(120, 30)
    enterButton:SetText("")
    enterButton:SetFont("ui.mainmenu.button")

    enterButton.Paint = function(self, w, h)
        local hover = self:IsHovered()
        surface.SetDrawColor(hover and Color(60, 60, 60) or Color(45, 45, 45))
        surface.DrawRect(0, 0, w, h)

        draw.SimpleText("Enter", "ui.mainmenu.button", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    enterButton.DoClick = function()
        local mapName = mapInput:GetValue()
        if mapName ~= "" then
            NETWORK:StartNetworkMessage(nil, "AdminChangeMap", mapName)
            frame:Close()
        end
    end

    -- Close Button
    local closeButton = vgui.Create("DButton", frame)
    closeButton:SetPos(160, 85)
    closeButton:SetSize(120, 30)
    closeButton:SetText("")
    closeButton:SetFont("ui.mainmenu.button")

    closeButton.Paint = function(self, w, h)
        local hover = self:IsHovered()
        surface.SetDrawColor(hover and Color(60, 60, 60) or Color(45, 45, 45))
        surface.DrawRect(0, 0, w, h)

        draw.SimpleText("Close", "ui.mainmenu.button", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

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

function UI:UpdateCommand(parent)
    local function RoundedBoxBG(pnl, w, h, col)
        surface.SetDrawColor(col)
        surface.DrawRect(0, 0, w, h)
    end

    local yOffset = 75

    -- Draw header line
    local padding = 10
    local headerLine = vgui.Create("DPanel", parent)
    headerLine:SetPos(padding, yOffset - 8)
    headerLine:SetSize(parent:GetWide() - (padding * 2), 1)
    headerLine.Paint = function(self, w, h)
        surface.SetDrawColor(Color(150, 150, 150))
        surface.DrawRect(0, 0, w, h)
    end

    -- Title Labels
    local function AddLabel(text, x)
        local label = vgui.Create("DLabel", parent)
        label:SetText(text)
        label:SetFont("hud.subinfo")
        label:SetTextColor(Color(150, 150, 150))
        label:SetPos(x, yOffset - 26)
        label:SizeToContents()
    end

    AddLabel("Commands", 10)
    AddLabel("Player", 220)
    AddLabel("Level", 360)
    AddLabel("Arguments", 430)

    -- Command Scroll Panel
    local commandScroll = vgui.Create("DScrollPanel", parent)
    commandScroll:SetPos(10, yOffset)
    commandScroll:SetSize(200, parent:GetTall() - yOffset - 10)

    -- Apply custom scrollbar
    UI:MenuScrollbar(commandScroll:GetVBar())

    -- Player Scroll Panel
    local playerScroll = vgui.Create("DScrollPanel", parent)
    playerScroll:SetPos(220, yOffset)
    playerScroll:SetSize(190, parent:GetTall() - yOffset - 10)

    -- custom scrollbar
    UI:MenuScrollbar(playerScroll:GetVBar())

    -- Args Panel
    local argsPanel = vgui.Create("DPanel", parent)
    argsPanel:SetPos(420, yOffset)
    argsPanel:SetSize(parent:GetWide() - 420, parent:GetTall() - yOffset - 10)
    argsPanel.Paint = function(self, w, h)
        RoundedBoxBG(self, w, h, colors.content)
    end

    local currentArgs = {}

    -- Create Args function
    local function createArgs(cmd)
        argsPanel:Clear()
        currentArgs = {}

        local y = 10
        for _, arg in ipairs(cmd.args or {}) do
            local lbl = vgui.Create("DLabel", argsPanel)
            lbl:SetPos(10, y)
            lbl:SetText("Argument: " .. arg.name .. "     " .. (arg.help or ""))
            lbl:SetTextColor(colors.text)
            lbl:SetFont("ui.mainmenu.button")
            lbl:SizeToContents()
            y = y + 20

            local entry = vgui.Create("DTextEntry", argsPanel)
            entry:SetPos(10, y)
            entry:SetSize(300, 22)
            entry:SetText(arg.default or "")
            entry.Paint = function(self, w, h)
                surface.SetDrawColor(colors.sideNav)
                surface.DrawRect(0, 0, w, h)
                draw.SimpleText(self:GetText(), "ui.mainmenu.button", 6, h / 2, colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            table.insert(currentArgs, entry)
            y = y + 30
        end

        -- Execute Button
        local exec = vgui.Create("DButton", argsPanel)
        exec:SetText("")
        exec:SetPos(10, y + 10)
        exec:SetSize(300, 30)
        exec.Paint = function(self, w, h)
            surface.SetDrawColor(Color(0, 122, 255))
            surface.DrawRect(0, 0, w, h)
            draw.SimpleText("Execute Command", "ui.mainmenu.button", w / 2, h / 2, colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        exec.DoClick = function()
            if not commandScroll.SelectedCommand or not playerScroll.SelectedPlayer then return end
            local args = {}
            for _, entry in ipairs(currentArgs) do
                table.insert(args, entry:GetValue())
            end

            net.Start("UI_RunAdminCommand")
            net.WriteString(commandScroll.SelectedCommand.id)
            net.WriteString(playerScroll.SelectedPlayer:SteamID())
            net.WriteUInt(#args, 8)

            for _, v in ipairs(args) do
                net.WriteString(v)
            end

            net.SendToServer()
        end
    end

    -- Build Command Buttons
    for _, cmd in ipairs(UI.AdminCommands) do
        local btn = vgui.Create("DButton", commandScroll)
        btn:SetTall(35)
        btn:Dock(TOP)
        btn:DockMargin(0, 0, 0, 0)
        btn:SetText("")
        btn.Paint = function(self, w, h)
            local hovered = self:IsHovered()
            local active = self == commandScroll.Selected
            surface.SetDrawColor(active and Color(0, 122, 255) or hovered and Color(60, 60, 60) or Color(60, 60, 60, 0))
            surface.DrawRect(0, 0, w, h)
            draw.SimpleText(cmd.name, "ui.mainmenu.button", 10, h / 2, colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        btn.DoClick = function()
            commandScroll.Selected = btn
            commandScroll.SelectedCommand = cmd
            createArgs(cmd)
        end
    end

    -- Build Player Buttons
    for _, ply in ipairs(player.GetAll()) do
        if ply:IsBot() then continue end -- Skip bots

        local rank = UI.GetRankName and UI:GetRankName(Admin:GetAccess(ply)) or "None"
        local name = ply:Nick()

        local btn = vgui.Create("DButton", playerScroll)
        btn:SetTall(35)
        btn:Dock(TOP)
        btn:DockMargin(0, 0, 0, 0)
        btn:SetText("")
        btn.Paint = function(self, w, h)
            local hovered = self:IsHovered()
            local active = self == playerScroll.Selected
            surface.SetDrawColor(active and Color(0, 122, 255) or hovered and Color(60, 60, 60) or Color(60, 60, 60, 0))
            surface.DrawRect(0, 0, w, h)
            draw.SimpleText(name, "ui.mainmenu.button", 10, h / 2, colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(rank, "ui.mainmenu.button", w - 10, h / 2, colors.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
        btn.DoClick = function()
            playerScroll.Selected = btn
            playerScroll.SelectedPlayer = ply
        end
    end

    timer.Simple(0, function()
        local firstBtn = commandScroll:GetCanvas():GetChildren()[1]
        if IsValid(firstBtn) and firstBtn.DoClick then
            firstBtn:DoClick()
        end
    end)
end

-- Profile Menu
function UI:OpenProfileMenu(target, data)
    if not IsValid(target) or not data then return end

    local frame = vgui.Create("DFrame")
    frame:SetSize(700, 500)
    frame:Center()
    frame:SetTitle("")
    frame:MakePopup()
    frame:ShowCloseButton(false)
    frame.Paint = function(s, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(42, 42, 42)) -- main bg
        draw.RoundedBoxEx(0, 0, 0, w, 45, Color(32, 32, 32), true, true, false, false) -- top bar
        draw.SimpleText("Profile of " .. data.name, "ProfileTitle", 20, 12, color_white, TEXT_ALIGN_LEFT)
    end

    local avatar = vgui.Create("AvatarImage", frame)
    avatar:SetSize(128, 128)
    avatar:SetPos(20, 60)
    avatar:SetPlayer(target, 128)

    local function AddHeader(text, x, y)
        local label = vgui.Create("DLabel", frame)
        label:SetText(text)
        label:SetFont("ProfileFont")
        label:SetColor(Color(255, 255, 255))
        label:SetPos(x, y)
        label:SizeToContents()
    end

    local function AddStatLabel(title, value, x, y)
        local titleLabel = vgui.Create("DLabel", frame)
        titleLabel:SetPos(x, y)
        titleLabel:SetText(title)
        titleLabel:SetFont("ProfileFont")
        titleLabel:SetColor(Color(100, 200, 255))
        titleLabel:SizeToContents()

        local valueLabel = vgui.Create("DLabel", frame)
        valueLabel:SetPos(x + 130, y)
        valueLabel:SetText(value)
        valueLabel:SetFont("ProfileFont")
        valueLabel:SetColor(Color(255, 255, 255))
        valueLabel:SizeToContents()
    end

    -- Headers
    AddHeader("General Statistics", 170, 50)
    AddHeader("Map Statistics", 20, 200)
    AddHeader("Map Averages", 20, 280)
    AddHeader("Strafe Statistics", 20, 360)

    -- Left Stats
    AddStatLabel("Map Completions:", data.mapCompletions or "0", 45, 230)
    AddStatLabel("Amount of WRs:", data.wrs or "0", 45, 250)

    -- Avg
    AddStatLabel("Map Completions:", data.mapCompletions or "0", 45, 310)
    AddStatLabel("Map placement:", data.placement or "0", 45, 330)
    AddStatLabel("Sync:", data.sync or "0", 45, 390)

    -- Right Stats
    AddStatLabel("Rank:", data.rank or "Unranked", 195, 80)
    AddStatLabel("Points:", data.points or "0", 195, 100)
    AddStatLabel("Maps Left:", data.mapsLeft or "0", 195, 120)
    AddStatLabel("Maps Played:", data.mapsPlayed or "0", 195, 140)

    AddStatLabel("Time Played:", data.playtime or "00:00.000", 450, 70)
    AddStatLabel("Last Played:", data.lastplayed or "Never", 450, 100)
    AddStatLabel("Map Most Played:", data.mapmostplayed or "N/A", 450, 130)
    AddStatLabel("Role:", data.role or "Unknown", 450, 160)

    AddStatLabel("Most Recent WR:", data.lastWR or "N/A", 450, 210)
    AddStatLabel("Group 1 Times:", data.group1 or "0", 450, 240)
    AddStatLabel("Tier Played:", data.tierPlayed or "0", 450, 270)
    AddStatLabel("Group Placement:", data.groupPlacement or "0", 450, 300)
    AddStatLabel("Long Jump:", data.longJump or "0", 450, 330)

    -- Close
    local close = vgui.Create("DButton", frame)
    close:SetText("Close")
    close:SetFont("ProfileFont")
    close:SetSize(400, 30)
    close:SetPos(frame:GetWide() / 2 - 200, frame:GetTall() - 45)
    close:SetTextColor(Color(255, 255, 255))
    close.Paint = function(s, w, h)
        local col = s:IsHovered() and Color(100, 42, 42) or Color(32, 32, 32)
        draw.RoundedBox(0, 0, 0, w, h, col)
    end
    close.DoClick = function() frame:Close() end
end

net.Receive("SendProfileData", function()
    local target = net.ReadEntity()
    local data = net.ReadTable()

    if not IsValid(target) then return end
    UI:OpenProfileMenu(target, data)
end)

function UI:OpenRecordStatsMenu(target, data)
    if not IsValid(target) or not data then return end

    local frame = vgui.Create("DFrame")
    frame:SetSize(760, 540)
    frame:Center()
    frame:SetTitle("")
    frame:MakePopup()
    frame:ShowCloseButton(false)
    frame.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(42, 42, 42)) -- bg
        draw.RoundedBox(0, 0, 0, w, 45, Color(32, 32, 32)) -- header

        local mapName = game.GetMap() or "Unknown Map"
        local styleName = TIMER and TIMER.Styles and TIMER.Styles[LocalPlayer().style or 1] and TIMER.Styles[LocalPlayer().style or 1][1] or "Unknown Style"
        local playerName = data.name or "Unknown Player"
        local PlacementNum = data.placement or "Unknown Placement"

        draw.SimpleText("Stats for " .. playerName .. " " .. PlacementNum ..  " run on " .. mapName .. " (" .. styleName .. ")", "ui.mainmenu.button", 20, 12, color_white, TEXT_ALIGN_LEFT)
    end

    -- Section builder
    local function AddSection(title, y)
        local header = vgui.Create("DPanel", frame)
        header:SetPos(15, y)
        header:SetSize(730, 25)
        header.Paint = function(self, w, h)
            draw.SimpleText(title, "ui.mainmenu.button", 0, 0, Color(255, 255, 255), TEXT_ALIGN_LEFT)
            surface.SetDrawColor(90, 90, 90)
            surface.DrawLine(0, h - 1, w, h - 1)
        end
    end

    -- Stat label
    local function AddStat(title, value, x, y, titleColor, alignRight)
        titleColor = titleColor or Color(255, 80, 80)

        local titleLabel = vgui.Create("DLabel", frame)
        titleLabel:SetFont("ui.mainmenu.button")
        titleLabel:SetTextColor(titleColor)
        titleLabel:SetText(title .. ":")
        titleLabel:SizeToContents()

        local valueLabel = vgui.Create("DLabel", frame)
        valueLabel:SetFont("ui.mainmenu.button")
        valueLabel:SetTextColor(Color(255, 255, 255))
        valueLabel:SetText(value)
        valueLabel:SizeToContents()

        if alignRight then
            local totalWidth = titleLabel:GetWide() + 6 + valueLabel:GetWide()
            local baseX = x - totalWidth

            titleLabel:SetPos(baseX, y)
            valueLabel:SetPos(baseX + titleLabel:GetWide() + 6, y)
        else
            titleLabel:SetPos(x, y)
            valueLabel:SetPos(x + titleLabel:GetWide() + 6, y)
        end
    end

    -- Stat label
    local function AddStatGroup(title, value, x, y, titleColor, alignRight)
        titleColor = titleColor or Color(255, 80, 80)

        local titleLabel = vgui.Create("DLabel", frame)
        titleLabel:SetFont("ui.mainmenu.button")
        titleLabel:SetTextColor(titleColor)
        titleLabel:SetText(title .. ":")
        titleLabel:SizeToContents()

        local valueLabel = vgui.Create("DLabel", frame)
        valueLabel:SetFont("ui.mainmenu.button")
        valueLabel:SetTextColor(Color(0, 255, 0))
        valueLabel:SetText(value)
        valueLabel:SizeToContents()

        if alignRight then
            local totalWidth = titleLabel:GetWide() + 6 + valueLabel:GetWide()
            local baseX = x - totalWidth

            titleLabel:SetPos(baseX, y)
            valueLabel:SetPos(baseX + titleLabel:GetWide() + 6, y)
        else
            titleLabel:SetPos(x, y)
            valueLabel:SetPos(x + titleLabel:GetWide() + 6, y)
        end
    end

    -- Sections
    AddSection("Overall Statistics", 60)
    AddStat("Time", data.time or "N/A", 20, 90)
    AddStat("Jumps", data.jumps or "0", 20, 115)
    AddStat("Strafes", data.strafes or "0", 20, 140)
    AddStat("Points", data.points or "0", 740, 90, nil, true)
    AddStat("SteamID", data.steamid or "N/A", 740, 115, nil, true)

    AddSection("Speed/Strafe Statistics and Completions", 170)
    AddStat("Average Gain", data.gain or "0%", 20, 200)
    AddStat("Sync", data.sync or "0%", 20, 225)
    AddStat("Top Speed", data.speed or "0 u/s", 20, 250)
    AddStat("Completions", data.completions or "0", 20, 275)

    net.Receive("SendGroupStats", function()
        local styleID = net.ReadUInt(8)
        local wrFormatted = net.ReadString()
        local times = net.ReadTable()

        AddSection("Group Statistics", 310)

        AddStatGroup("Group 1", times[1] .. " (Achieved)", 20, 340, Color(255, 80, 80))
        AddStatGroup("Group 2", times[2] .. " (Achieved)", 20, 365, Color(255, 80, 80))
        AddStatGroup("Group 3", times[3] .. " (Achieved)", 20, 390, Color(255, 80, 80))
        AddStatGroup("Group 4", times[4] .. " (Achieved)", 740, 340, Color(255, 80, 80), true)
        AddStatGroup("Group 5", times[5] .. " (Achieved)", 740, 365, Color(255, 80, 80), true)
        AddStatGroup("Group 6", "Achieved", 740, 390, Color(255, 80, 80), true)
    end)

    -- Group Completion Bar
    local outlineThickness = 5
    local visualW, visualH = 720, 35
    local totalW, totalH = visualW + outlineThickness * 2, visualH + outlineThickness * 2

    local bar = vgui.Create("DPanel", frame)
    bar:SetSize(totalW, totalH)
    bar:SetPos((frame:GetWide() - bar:GetWide()) / 2, 430 - outlineThickness)

    bar.Paint = function(self, w, h)
        local groups = 6
        local completedGroups = data.completedGroups or 0
        local segmentWidth = visualW / groups
        local fillX = segmentWidth * completedGroups

        -- Outline
        surface.SetDrawColor(55, 55, 55)
        surface.DrawRect(0, 0, w, outlineThickness)
        surface.DrawRect(0, h - outlineThickness, w, outlineThickness)
        surface.DrawRect(0, 0, outlineThickness, h)
        surface.DrawRect(w - outlineThickness, 0, outlineThickness, h)

        local ox, oy = outlineThickness, outlineThickness

        -- Background
        surface.SetDrawColor(30, 30, 30)
        surface.DrawRect(ox, oy, visualW, visualH)

        -- Blue Bar
        surface.SetDrawColor(0, 180, 220)
        surface.DrawRect(ox, oy, fillX, visualH)

        -- Groups
        for i = 1, groups do
            draw.SimpleText(
                tostring(groups - i + 1),
                "ui.mainmenu.button",
                ox + segmentWidth * (i - 1) + segmentWidth / 2,
                oy + visualH / 2,
                color_white,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )
        end

        -- White Line
        surface.SetDrawColor(255, 255, 255)
        surface.DrawRect(ox + fillX - 1, oy, 2, visualH)

        -- WR
        draw.SimpleText("WR", "ui.mainmenu.button", ox + fillX, oy - 16, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- PB
        draw.SimpleText("PB", "ui.mainmenu.button", ox + fillX, oy + visualH + 10, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end

    -- Close
    local close = vgui.Create("DButton", frame)
    close:SetText("Close")
    close:SetFont("ProfileFont")
    close:SetSize(400, 30)
    close:SetPos(frame:GetWide() / 2 - 200, frame:GetTall() - 45)
    close:SetTextColor(Color(255, 255, 255))
    close.Paint = function(s, w, h)
        local col = s:IsHovered() and Color(100, 42, 42) or Color(32, 32, 32)
        draw.RoundedBox(0, 0, 0, w, h, col)
    end
    close.DoClick = function() frame:Close() end
end

net.Receive("SendRecordData", function()
    local target = net.ReadEntity()
    local data = net.ReadTable()

    if not IsValid(target) then return end
    UI:OpenRecordStatsMenu(target, data)
end)