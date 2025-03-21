-- Paint by FiBzY

Paint = Paint or {}

local PAINT_DISTANCE_SQ = 1.0
local PAINT_TICK_INTERVAL = 0.1

Paint.LastPaintPos = Paint.LastPaintPos or {}
Paint.PaintingHeld = Paint.PaintingHeld or {}

Paint.PlayerPaintColour = {}
Paint.PlayerPaintSize = {}

Paint.Colors = {
    { "Random", "random" },
    { "White", "white" },
    { "Black", "black" },
    { "Blue", "blue" },
    { "Light Blue", "lightblue" },
    { "Brown", "brown" },
    { "Cyan", "cyan" },
    { "Green", "green" },
    { "Dark Green", "darkgreen" },
    { "Red", "red" },
    { "Orange", "orange" },
    { "Yellow", "yellow" },
    { "Pink", "pink" },
    { "Light Pink", "lightpink" },
    { "Purple", "purple" }
}

Paint.Sizes = {
    { "Random", "" },
    { "Small", "" },
    { "Medium", "_med" },
    { "Large", "_large" }
}

Paint.Sprites = {}

function Paint:InitDecals()
    for col = 2, #self.Colors do
        self.Sprites[col - 1] = {}
        for sz = 1, #self.Sizes do
            local mat = "decals/paint/paint_" .. self.Colors[col][2] .. self.Sizes[sz][2]
            game.AddDecal("paint_" .. self.Colors[col][2] .. self.Sizes[sz][2], mat)
            if SERVER then
                resource.AddFile("materials/" .. mat .. ".vmt")
                resource.AddFile("materials/" .. mat .. ".vtf")
                resource.AddFile("materials/decals/paint/paint_decal.vtf")
            end
            self.Sprites[col - 1][sz - 1] = "paint_" .. self.Colors[col][2] .. self.Sizes[sz][2]
        end
    end
end

function Paint:TraceEye(ply, out)
    if not IsValid(ply) then return end

    local eyePos = ply:EyePos()
    local angles = ply:EyeAngles()

    local tr = util.TraceLine({
        start = eyePos,
        endpos = eyePos + angles:Forward() * 1e6,
        mask = MASK_SHOT,
        filter = function(ent)
            return ent ~= ply
        end
    })

    if tr.Hit and out then
        out[1] = tr.HitPos[1]
        out[2] = tr.HitPos[2]
        out[3] = tr.HitPos[3]
    end

    return tr
end

function Paint:AddPaint(ply, colorID, sizeID)
    if colorID == 1 then
        colorID = math.random(2, #self.Colors)
    end

    if sizeID == 0 then
        sizeID = math.random(1, #self.Sizes - 1)
    end

    local tr = self:TraceEye(ply)
    if not tr or not tr.Hit then return end

    net.Start("PaintDecal")
    net.WriteVector(tr.HitPos)
    net.WriteVector(tr.HitNormal)
    net.WriteUInt(colorID, 8)
    net.WriteUInt(sizeID, 8)
    net.Broadcast()
end

-- Map start hook
hook.Add("InitPostEntity", "Paint_OnMapStart", function()
    Paint:InitDecals()
end)

if SERVER then
    util.AddNetworkString("PaintDecal")

    hook.Add("PlayerInitialSpawn", "Paint_OnJoin", function(ply)
        Paint.PlayerPaintColour[ply] = 1
        Paint.PlayerPaintSize[ply] = 1
    end)

    concommand.Add("+paint", function(ply)
        local tr = Paint:TraceEye(ply)
        if tr then
            Paint.LastPaintPos[ply] = tr.HitPos
        end
        Paint.PaintingHeld[ply] = true
    end)

    concommand.Add("-paint", function(ply)
        Paint.PaintingHeld[ply] = false
    end)

    concommand.Add("paintcolor", function(ply, _, args)
        local idx = tonumber(args[1]) or 1
        if idx < 1 or idx > #Paint.Colors then
            NETWORK:StartNetworkMessageTimer(ply, "Print", {"Paint", "Invalid color index."})
            return
        end
        Paint.PlayerPaintColour[ply] = idx
        NETWORK:StartNetworkMessageTimer(ply, "Print", {"Paint", "Color set to " .. Paint.Colors[idx][1]})
    end)

    concommand.Add("paintsize", function(ply, _, args)
        local idx = tonumber(args[1]) or 1
        if idx < 1 or idx > #Paint.Sizes then
            UTIL:Print("Paint | Invalid size index.")
            return
        end
        Paint.PlayerPaintSize[ply] = idx - 1
        NETWORK:StartNetworkMessageTimer(ply, "Print", {"Paint", "Size set to " .. Paint.Sizes[idx][1]})
    end)

    timer.Create("Paint_Tick", PAINT_TICK_INTERVAL, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then continue end
            if not Paint.PaintingHeld[ply] or ply:GetObserverMode() ~= OBS_MODE_NONE then continue end

            local tr = Paint:TraceEye(ply)
            if not tr or not tr.Hit then continue end

            if not Paint.LastPaintPos[ply] or Paint.LastPaintPos[ply]:DistToSqr(tr.HitPos) > PAINT_DISTANCE_SQ then
                Paint.LastPaintPos[ply] = tr.HitPos
                Paint:AddPaint(ply, Paint.PlayerPaintColour[ply], Paint.PlayerPaintSize[ply])
            end
        end
    end)
end

if CLIENT then
    net.Receive("PaintDecal", function()
        local pos = net.ReadVector()
        local normal = net.ReadVector()
        local colorID = net.ReadUInt(8)
        local sizeID = net.ReadUInt(8)
        local decal = Paint.Sprites[colorID - 1][sizeID]
        util.Decal(decal, pos + normal, pos - normal)
    end)
end

if CLIENT then
    local function AddCustomTitle(parent, text, closeFunc)
        local header = vgui.Create("Panel", parent)
        header:Dock(TOP)
        header:SetTall(35)
        header:DockMargin(0, 0, 0, 5)

        local closeButton = vgui.Create("DButton", header)
        closeButton:SetSize(25, 25)
        closeButton:SetText("X")
        closeButton:SetFont("HUDFont")
        closeButton:SetTextColor(Color(220, 220, 220))
        closeButton.Paint = function(self, w, h)
            local col = self:IsHovered() and Color(200, 50, 50, 200) or Color(50, 50, 50, 200)
            draw.RoundedBox(0, 0, 0, w, h, col)
        end
        closeButton.DoClick = function()
            if closeFunc then closeFunc() end
        end

        header.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(50, 50, 50, 255))
            draw.SimpleText(text, "HUDFont", 15, h / 2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        header.PerformLayout = function(self, w, h)
            closeButton:SetPos(w - 35, 5)
        end

        return header
    end

    function Paint:OpenCombinedMenu()
        local menu = vgui.Create("DFrame")
        menu:SetTitle("")
        menu:SetSize(600, 350)
        menu:Center()
        menu:MakePopup()
        menu:SetDraggable(false)
        menu:ShowCloseButton(false)
        menu:DockPadding(0, 0, 0, 0)

        menu.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(32, 32, 32, 255))
        end

        AddCustomTitle(menu, "Select Paint Color & Size", function()
            menu:Close()
        end)

        local colorsPanel = vgui.Create("DPanel", menu)
        colorsPanel:Dock(LEFT)
        colorsPanel:SetWide(290)
        colorsPanel:DockMargin(5, 0, 2, 0)
        colorsPanel.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h - 10, Color(32, 32, 32, 255))
        end

        local colorList = vgui.Create("DListView", colorsPanel)
        colorList:Dock(FILL)
        colorList:AddColumn("")

        local colHeader = colorList.Columns[1]
        colHeader.Header.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(32, 32, 32, 255))
            draw.SimpleText("Colors", "HUDFontSmall", 5, h / 2 - 3, Color(220, 220, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end


        colorList.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h - 5, Color(42, 42, 42, 255))
        end

        colorList.VBar.Paint = function(self, w, h) end
        colorList.VBar.btnUp.Paint = function(self, w, h) end
        colorList.VBar.btnDown.Paint = function(self, w, h) end
        colorList.VBar.btnGrip.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(60, 60, 60, 255))
        end

        colorList.OnRowSelected = function(lst, index, pnl)
            net.Start("Paint_SetColor")
            net.WriteUInt(index, 8)
            net.SendToServer()
        end

        for i, color in ipairs(self.Colors) do
            local line = colorList:AddLine("")
            line.Paint = function(self, w, h)
                local bg = self:IsSelected() and DynamicColors.PanelColor or Color(42, 42, 42, 255)
                draw.RoundedBox(0, 0, 0, w, h, bg)
                draw.SimpleText(color[1], "HUDFontSmall", 8, h / 2 + 2, Color(220, 220, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            for _, col in pairs(line.Columns) do
                col:SetTextColor(Color(0, 0, 0, 0))
            end
        end


        local sizesPanel = vgui.Create("DPanel", menu)
        sizesPanel:Dock(FILL)
        sizesPanel:DockMargin(2, 0, 5, 0)
        sizesPanel.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(32, 32, 32, 255))
        end

        local sizeList = vgui.Create("DListView", sizesPanel)
        sizeList:Dock(FILL)
        sizeList:AddColumn("")
        local sizeColHeader = sizeList.Columns[1]
        sizeColHeader.Header.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(32, 32, 32, 255))
            draw.SimpleText("Sizes", "HUDFontSmall", 5, h / 2 - 3, Color(220, 220, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        sizeList.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h - 5, Color(42, 42, 42, 255))
        end

        sizeList.VBar.Paint = function(self, w, h) end
        sizeList.VBar.btnUp.Paint = function(self, w, h) end
        sizeList.VBar.btnDown.Paint = function(self, w, h) end
        sizeList.VBar.btnGrip.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(60, 60, 60, 255))
        end

        sizeList.OnRowSelected = function(lst, index, pnl)
            net.Start("Paint_SetSize")
            net.WriteUInt(index, 8)
            net.SendToServer()
        end

        for i, size in ipairs(self.Sizes) do
            local line = sizeList:AddLine("")
            line.Paint = function(self, w, h)
                local bg = self:IsSelected() and DynamicColors.PanelColor or Color(42, 42, 42, 255)
                draw.RoundedBox(0, 0, 0, w, h, bg)
                draw.SimpleText(size[1], "HUDFontSmall", 8, h / 2 + 2, Color(220, 220, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            for _, col in pairs(line.Columns) do
                col:SetTextColor(Color(0, 0, 0, 0))
            end
        end
    end

    concommand.Add("bhop_paintmenu", function()
        Paint:OpenCombinedMenu()
    end)

    net.Receive("PAINT_SendData", function()
        RunConsoleCommand("bhop_paintmenu")
    end)
end

if SERVER then
    util.AddNetworkString("Paint_SetColor")
    util.AddNetworkString("Paint_SetSize")

    net.Receive("Paint_SetColor", function(len, ply)
        local idx = net.ReadUInt(8)
        if idx < 1 or idx > #Paint.Colors then
            NETWORK:StartNetworkMessageTimer(ply, "Print", {"Paint", "Invalid color index."})
            return
        end
        Paint.PlayerPaintColour[ply] = idx
        NETWORK:StartNetworkMessageTimer(ply, "Print", {"Paint", "Color set to " .. Paint.Colors[idx][1]})
    end)

    net.Receive("Paint_SetSize", function(len, ply)
        local idx = net.ReadUInt(8)
        if idx < 1 or idx > #Paint.Sizes then
            ply:ChatPrint("[Paint] Invalid size index.")
            return
        end
        Paint.PlayerPaintSize[ply] = idx - 1
        NETWORK:StartNetworkMessageTimer(ply, "Print", {"Paint", "Color set to " .. Paint.Sizes[idx][1]})
    end)
end

-- Settings saver
hook.Add("PlayerInitialSpawn", "Paint_LoadSettings", function(ply)
    -- Load pdata when player joins
    local colorID = ply:GetPData("PaintColor", 1)
    local sizeID = ply:GetPData("PaintSize", 1)

    Paint.PlayerPaintColour[ply] = tonumber(colorID) or 1
    Paint.PlayerPaintSize[ply] = tonumber(sizeID) - 1 or 0

    NETWORK:StartNetworkMessageTimer(ply, "Print", {"Paint", "Loaded color & size preferences!"})
end)

hook.Add("PlayerDisconnected", "Paint_SaveSettings", function(ply)
    if Paint.PlayerPaintColour[ply] then
        ply:SetPData("PaintColor", Paint.PlayerPaintColour[ply])
    end
    if Paint.PlayerPaintSize[ply] then
        ply:SetPData("PaintSize", Paint.PlayerPaintSize[ply] + 1)
    end
end)

hook.Add("ShutDown", "Paint_SaveAllPlayersOnShutdown", function()
    for _, ply in ipairs(player.GetAll()) do
        if Paint.PlayerPaintColour[ply] then
            ply:SetPData("PaintColor", Paint.PlayerPaintColour[ply])
        end
        if Paint.PlayerPaintSize[ply] then
            ply:SetPData("PaintSize", Paint.PlayerPaintSize[ply] + 1)
        end
    end
end)