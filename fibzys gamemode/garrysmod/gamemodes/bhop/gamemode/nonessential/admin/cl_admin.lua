-- some stuff i used from flow replace soon
Window = {}
Window.NoClose = {"Vote"}
Window.NoThink = {"Admin", "VIP"}

Window.Elements = {
    Admin = {Dimensions = {0, 0}, Title = "Admin"},
    VIP = {Dimensions = {0, 0}, Title = "VIP"}
}

local hook_Add = hook.Add
local ActiveUI = nil
local KeyLock = false
local KeyCooldown = 0.15
local InputCheck = LocalPlayer

local WindowThinker = function() end
local WindowDrawer = function() end

function Window:Open(identifier, args, force)
    if IsValid(ActiveUI) and not force then
        if ActiveUI.Data and table.HasValue(Window.NoClose, ActiveUI.Data.ID) then
            return
        end
    end

    Window:Close()

    ActiveUI = vgui.Create("DFrame")
    ActiveUI:SetTitle("")
    ActiveUI:SetDraggable(false)
    ActiveUI:ShowCloseButton(false)

    ActiveUI.Data = Window:LoadData(identifier, args)

    if IsValid(ActiveUI) then
        if not table.HasValue(Window.NoThink, identifier) then
            ActiveUI.Think = WindowThinker
        end

        ActiveUI.Paint = function(self, w, h)
            local titleBarHeight = 30
            local bgColor = Color(60, 60, 60)
            local titleColor = Color(80, 80, 80) 

            draw.RoundedBox(3, 0, 0, w, h, bgColor)
            draw.RoundedBoxEx(3, 0, 0, w, titleBarHeight, titleColor, true, true, false, false)
            draw.SimpleText(identifier or "Window", "HUDFontSmall", 10, titleBarHeight / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
end

function Window:Update(identifier, args)
    if not IsValid(ActiveUI) then return end
    if not ActiveUI.Data then return end
    
    ActiveUI.Data = Window:LoadData(identifier, args, ActiveUI.Data)
end

function Window:Close()
    if not IsValid(ActiveUI) then return end
    ActiveUI:Close()
    ActiveUI = nil
end

function Window:LoadData(identifier, args, updateData)
    local window = updateData or {ID = identifier, Labels = {}, Offset = 35}

    local FormData = Window.Elements[identifier]
    if not FormData then return end
    
    if not updateData then
        if identifier == "Admin" or identifier == "VIP" then
            Window.Elements[identifier].Title = args.Title
            Window.Elements[identifier].Dimensions = {args.Width, args.Height}
            FormData = Window.Elements[identifier]
        end
    
        window.Title = FormData.Title
        KeyCooldown = 0.15
        ActiveUI:SetSize(FormData.Dimensions[1], FormData.Dimensions[2])
        ActiveUI:SetPos(20, ScrH() / 2 - ActiveUI:GetTall() / 2)
    end
    
    if identifier == "Admin" or identifier == "VIP" then
        Admin:GenerateGUI(ActiveUI, args)
    end
    
    return window
end

WindowDrawer = function()
    if not IsValid(ActiveUI) then return end

    local w, h = ActiveUI:GetWide(), ActiveUI:GetTall()
    surface.SetDrawColor(Color(30, 30, 30))
    surface.DrawRect(0, 0, w, h)
    
    local title = ActiveUI.Data and ActiveUI.Data.Title or ""
    draw.SimpleText(title, "CustomTitle", 10, 5, Color(30, 30, 30), TEXT_ALIGN_LEFT)
end

WindowThinker = function()
    if not IsValid(ActiveUI) then return end
    local windowData = ActiveUI.Data
    if not windowData then return end

    if InputCheck and IsValid(InputCheck()) and InputCheck():IsTyping() then
        return
    end

    local keyMappings = {
        [KEY_1] = 0,
        [KEY_2] = 1,
        [KEY_3] = 2,
    }

    local pressedKey = -1
    local keyPressed = false

    for key, value in pairs(keyMappings) do
        if input.IsKeyDown(key) then
            pressedKey = value
            keyPressed = true
            break
        end
    end

    if not keyPressed or pressedKey == -1 then return end

    local ID = windowData.ID

    if pressedKey == 0 and not KeyLock and not table.HasValue(Window.NoClose, ID) then
        KeyLock = true
        timer.Simple(KeyCooldown, function()
            if IsValid(ActiveUI) then
                ActiveUI:Close()
                ActiveUI = nil
            end
            KeyLock = false
        end)
    elseif pressedKey > 0 and not KeyLock then
        KeyLock = true
        timer.Simple(KeyCooldown, function()
            KeyLock = false
        end)
    end
end

function Window:GetActive()
    return ActiveUI
end

function Window:IsActive(identifier)
    if IsValid(ActiveUI) then
        if not ActiveUI.Data then return false end
        return ActiveUI.Data.ID == identifier
    end
    
    return false
end

function Window:CreateLabel(params)
    local lbl = vgui.Create("DLabel", params.parent)
    lbl:SetPos(params.x, params.y)
    lbl:SetFont(params.font or "HUDFontSmall")
    lbl:SetText(params.text or "")
    lbl:SizeToContents()
    
    lbl.TextColor = params.color or color_white
    lbl.BgColor = params.bgColor or Color(50, 50, 50, 0)

    lbl.Paint = function(self, w, h)
        if self.BgColor.a > 0 then
            draw.RoundedBox(3, 0, 0, w, h, self.BgColor)
        end
        
        draw.SimpleText(self:GetText(), self:GetFont(), 0, 0, self.TextColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    return lbl
end

function Window:CreateButton(params)
    local btn = vgui.Create("DButton", params.parent)
    btn:SetSize(params.w, params.h)
    btn:SetPos(params.x, params.y)
    btn:SetText("")
    
    if params.id then btn.SetID = params.id end
    btn.DoClick = params.onclick

    btn.Paint = function(self, w, h)
        local bgColor = self:IsHovered() and Color(100, 100, 100) or Color(80, 80, 80)
        draw.RoundedBox(3, 0, 0, w, h, bgColor)
        draw.SimpleText(params.text, "HUDFontSmall", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    return btn
end

function Window:CreateTextBox(params)
    local txt = vgui.Create("DTextEntry", params.parent)
    txt:SetPos(params.x, params.y)
    txt:SetSize(params.w, params.h)
    txt:SetText(params.text or "")
    txt:SetFont("HUDFontSmall")
    txt:SetTextColor(color_white)
    txt:SetCursorColor(color_white)

    txt.Paint = function(self, w, h)
        local bgColor = self:IsEditing() and Color(100, 100, 100) or Color(80, 80, 80)
        local borderColor = self:IsEditing() and Color(120, 120, 120) or Color(60, 60, 60)

        draw.RoundedBox(3, 0, 0, w, h, borderColor)
        draw.RoundedBox(3, 1, 1, w - 2, h - 2, bgColor)
        
        self:DrawTextEntryText(color_white, Color(30, 130, 255), color_white)
    end

    return txt
end

function Window.MakeQuery(c, t, ...)
    local arg = { ... }
    local numArgs = #arg

    local qry = Derma_Query(c, t, ...)
    
    if numArgs < 9 then return end

    local nTall = math.ceil(numArgs / 8) * 30
    local nExtra = nTall - 30
    local x, y = 5, 25
    local buttonCounter = 1

    local dPanel = nil
    for _, panel in pairs(qry:GetChildren()) do
        if panel:GetClassName() == "Panel" and panel:GetTall() == 30 then
            panel:SetTall(nTall)
            dPanel = panel
            break
        end
    end

    if not dPanel then return end

    local function CreateButton(text, func)
        local btn = vgui.Create("DButton", dPanel)
        btn:SetText("")
        btn:SizeToContents()
        btn:SetTall(20)
        btn:SetWide(btn:GetWide() + 75)
        btn:SetPos(x, y + 5)
        btn.DoClick = function() qry:Close(); func() end

        btn.Paint = function(self, w, h)
            local bgColor = self:IsHovered() and Color(100, 100, 100) or Color(80, 80, 80)
            draw.RoundedBox(3, 0, 0, w, h, bgColor)
            draw.SimpleText(text, "HUDFontSmall", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        x = x + btn:GetWide() + 5
        buttonCounter = buttonCounter + 1

        if buttonCounter > 4 then
            x, y = 5, y + 25
            buttonCounter = 1
        end
    end

    for k = 9, numArgs, 2 do
        local text = arg[k]
        local func = arg[k + 1] or function() end
        CreateButton(text, func)
    end

    qry:SetTall(qry:GetTall() + nExtra)
end

function Window.MakeRequest(c, t, d, f, l)
    local frame = vgui.Create("DFrame")
    frame:SetTitle("")
    frame:SetSize(300, 150)
    frame:Center()
    frame:MakePopup()

    frame.Paint = function(self, w, h)
        draw.RoundedBox(3, 0, 0, w, h, Color(60, 60, 60))
        draw.SimpleText(t, "HUDFontSmall", 10, 20, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local textEntry = vgui.Create("DTextEntry", frame)
    textEntry:SetSize(280, 30)
    textEntry:SetPos(10, 50)
    textEntry:SetText(d or "")

    local confirmButton = vgui.Create("DButton", frame)
    confirmButton:SetSize(135, 40)
    confirmButton:SetPos(10, 100)
    confirmButton:SetText("Confirm")
    confirmButton.DoClick = function()
        if f then f(textEntry:GetValue()) end
        frame:Close()
    end

    local cancelButton = vgui.Create("DButton", frame)
    cancelButton:SetSize(135, 40)
    cancelButton:SetPos(155, 100)
    cancelButton:SetText("Cancel")
    cancelButton.DoClick = function()
        if l then l() end
        frame:Close()
    end
end


Admin = Admin or {}
Admin.Protocol = "Admin"

local Verify = false
AdminLoad = {}
local RawCache = {}
local DrawData = nil
local DrawTimer = nil
local ElemList = {}
local ElemCache = {}
local ElemData = {}

function Admin:Receive(varArgs)
    local szType = tostring(varArgs[1])

    local actions = {
        Open = function()
            AdminLoad.Setup = varArgs[2]
            Verify = true
            Window:Open("Admin")
        end,

        Query = function()
            local tab, func = varArgs[2], {}
            for i = 1, #tab do
                table.insert(func, tab[i][1])
                table.insert(func, function() Admin:ReqAction(tab[i][2][1], tab[i][2][2]) end)
            end
            Window.MakeQuery(tab.Caption, tab.Title, unpack(func))
        end,

        EditZone = function()
            AdminLoad.Editor = varArgs[2] or nil
        end,

        Request = function()
            local tab = varArgs[2]
            Window.MakeRequest(tab.Caption, tab.Title, tab.Default, function(r) Admin:ReqAction(tab.Return, r or tab.Default) end, function() end)
        end,

        Edit = function()
            Admin.EditType = varArgs[2]
        end,

        Raw = function()
            RawCache = varArgs[2]
        end,

        Message = function()
            DrawData = varArgs[2]
            DrawTimer = CurTime()
        end,

        GUI = function()
            Verify = true
            Window:Open(varArgs[2], varArgs[3], true)
        end
    }

    if actions[szType] then
        actions[szType]()
    end
end

function Admin:ReqAction(nID, varData)
    if not Verify then return end
    if not nID or nID < 0 then return end

    TIMER:Send("Admin", {-1, nID, varData})
end

function Admin:SendAction(nID, varData)
    if not Verify then return end
    if not nID or nID < 0 then return end

    TIMER:Send("Admin", {-2, nID, varData})
end

function Admin:IsAvailable()
    return Verify
end

local function ButtonCallback(self)
    if self.Close then
        return Window:Close()
    end
    Admin:SendAction(self.Identifier, self.Require and ElemData.Store and ElemData.Store:GetValue() or nil)
end

local function CreateElement(data, parent)
    local elem = vgui.Create(data["Type"], parent)

    for func, args in pairs(data["Modifications"]) do
        if func == "SetText" then
            elem.CustomText = args[1]
        else
            local f = elem[func]
            f(elem, unpack(args))
        end
    end

    if data["Label"] then
        ElemCache[data["Label"]] = elem
    end

    if data["Type"] == "DButton" then
        elem.Identifier = data["Identifier"]
        elem.Require = data["Require"]
        elem.VIP = data["VIP"]
        elem.Extra = data["Extra"]
        elem.Close = data["Close"]
        elem.DoClick = ButtonCallback

        elem:SetText("")

        elem.Paint = function(self, w, h)
            local bgColor = self:IsHovered() and Color(42, 42, 42) or Color(42, 42, 42)
            local textColor = self:IsHovered() and Color(255, 255, 255) or Color(200, 200, 200)

            draw.RoundedBox(3, 0, 0, w, h, bgColor)
            if self.CustomText then
                draw.SimpleText(self.CustomText, "HUDFontSmall", w / 2, h / 2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
    end

    table.insert(ElemList, elem)
end

function Admin:SubmitAction(szID, varArgs)
    if szID == "Players" then
        local elem = ElemCache["PlayerList"]
        if not elem then return end
        for _, line in pairs(varArgs) do
            elem:AddLine(unpack(line))
        end
    elseif szID == "Store" then
        ElemData.Store = ElemCache[varArgs[1]]
        ElemData.Default = varArgs[2]
    end
end

function Admin:GenerateGUI(parent, data)
    parent:Center()
    parent:MakePopup()

    ElemList = {}

    for i = 1, #data do
        local elemdata = data[i]
        CreateElement(elemdata, parent)
    end
end