-- Cache
local hook_Add, InputCheck = hook.Add, LocalPlayer
local isPlacing = false
local isZoneFinalized = false
local startPoint = nil
local endPoint = nil
local canPlaceZone = true
local previewPos = nil
local zonePlacementEnabled = false
local zoneMenuOpened = false
local showZoneHUD = false
local minm, maxm = math.min, math.max
local ZoneTypeCache = {}
local currentZoneHeight = 128

net.Receive("zone_menu_types", function()
    ZoneTypeCache = {}
    local count = net.ReadUInt(8)
    for i = 1, count do
        local name = net.ReadString()
        local id = net.ReadUInt(8)
        ZoneTypeCache[name] = id
    end
end)

function UI:OpenZoneTypeMenu()
    local currentSortAscending = true

    local frame = vgui.Create("DFrame")
    frame:SetTitle("")
    frame:SetSize(650, 550)
    frame:Center()
    frame:MakePopup()
    frame:SetDraggable(false)
    frame:SetDeleteOnClose(true)
    frame:ShowCloseButton(false)

    frame.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(32, 32, 32)) -- bg
        draw.RoundedBox(0, 0, 0, w, 25, Color(42, 42, 42)) -- top bar
        draw.SimpleText("Select Zone Type", "ui.mainmenu.button-bold", 10, 4, color_white, TEXT_ALIGN_LEFT)
        draw.SimpleText("Pick a zone to select it.", "ui.mainmenu.button", 10, 30, Color(180, 180, 180), TEXT_ALIGN_LEFT)
    end

    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetText("")
    closeBtn:SetSize(25, 25)
    closeBtn:SetPos(frame:GetWide() - 30, 0)
    closeBtn:SetZPos(10)
    closeBtn.Paint = function(self, w, h)
        local clr = self:IsHovered() and Color(200, 60, 60) or Color(150, 40, 40)
        draw.SimpleText("X", "ui.mainmenu.button-bold", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    closeBtn.DoClick = function()
        frame:Close()
    end
    frame.OnSizeChanged = function()
        closeBtn:SetPos(frame:GetWide() - 30, 0)
    end

    local wrapper = vgui.Create("DPanel", frame)
    wrapper:Dock(FILL)
    wrapper:DockMargin(10, 50, 10, 10)
    wrapper.Paint = nil

    local header = vgui.Create("DPanel", wrapper)
    header:SetTall(30)
    header:Dock(TOP)
    header.Paint = nil

    local sortBtn = vgui.Create("DButton", header)
    sortBtn:Dock(FILL)
    sortBtn:SetText("")
    sortBtn.Paint = function(self, w, h)
        surface.SetDrawColor(Color(50, 50, 50))
        surface.DrawRect(0, 0, w, h)
        draw.SimpleText("Zone", "ui.mainmenu.button-bold", 10, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local scroll = vgui.Create("DScrollPanel", wrapper)
    scroll:Dock(FILL)
    UI:MenuScrollbar(scroll:GetVBar())

    local function AddMenuButton(parent, text, callback)
        local btn = vgui.Create("DButton", parent)
        btn:SetText("")
        btn:SetTall(30)
        btn:Dock(TOP)
        btn:DockMargin(0, 0, 0, 0)
        btn.Paint = function(self, w, h)
            local bg = self:IsHovered() and Color(60, 60, 60) or Color(45, 45, 45)
            surface.SetDrawColor(bg)
            surface.DrawRect(0, 0, w, h)
            draw.SimpleText(text, "ui.mainmenu.button", 10, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        btn.DoClick = callback
    end

    local hint = vgui.Create("DLabel", wrapper)
    hint:Dock(BOTTOM)
    hint:DockMargin(0, 0, 0, 0)
    hint:SetTall(25)
    hint:SetFont("ui.mainmenu.button")
    hint:SetTextColor(Color(180, 180, 180))
    hint:SetText("")
    hint:SetContentAlignment(4)

    hint.Paint = function(self, w, h)
        draw.SimpleText("Hint: You can press the titles to sort by them", "ui.mainmenu.button", 0, 10, Color(180, 180, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    local function BuildZoneButtons()
        scroll:Clear()
        local zones = {}
        for name, id in pairs(ZoneTypeCache) do
            table.insert(zones, {name = name, id = id})
        end

        table.sort(zones, function(a, b)
            if currentSortAscending then
                return a.name:lower() < b.name:lower()
            else
                return a.name:lower() > b.name:lower()
            end
        end)

        for _, zone in ipairs(zones) do
            AddMenuButton(scroll, zone.name, function()
                AdminLoad.Editor = AdminLoad.Editor or {}
                AdminLoad.Editor.ZoneName = zone.name
                net.Start("zone_menu_select")
                net.WriteUInt(zone.id, 8)
                net.SendToServer()
                frame:Close()
            end)
        end

        AddMenuButton(scroll, "Add Extra Zone", function()
            net.Start("zone_menu_select")
            net.WriteUInt(255, 8)
            net.SendToServer()
            frame:Close()
        end)

        AddMenuButton(scroll, "Stop Extra", function()
            net.Start("zone_menu_select")
            net.WriteUInt(254, 8)
            net.SendToServer()
            frame:Close()
        end)
    end

    sortBtn.DoClick = function()
        currentSortAscending = not currentSortAscending
        BuildZoneButtons()
    end

    BuildZoneButtons()
end

NETWORK:GetNetworkMessage("CancelZonePlacement", function(_, _)
    isPlacing = false
    isZoneFinalized = false
    startPoint = nil
    endPoint = nil
    previewPos = nil
    zonePlacementEnabled = false
    AdminLoad.Editor = nil
end)

local snapGridSize = CreateClientConVar("bhop_snap_grid_size", "2", true, false, "The size of the snap grid in units.")
local function SnapToGrid(pos, gridSize)
    if not AdminLoad or not AdminLoad.Editor or not AdminLoad.Editor.Active then
        return pos
    end

    gridSize = gridSize or snapGridSize:GetInt()
    return Vector(
        math.Round(pos.x / gridSize) * gridSize,
        math.Round(pos.y / gridSize) * gridSize,
        math.Round(pos.z / gridSize) * gridSize
    )
end

local normal = Material(BHOP.Zone.ZoneMaterial)
local function DrawZoneWireFrame(min, max, colour, fill, pos, thickness)
    if not (min and max and pos) then return end
    local width = thickness or 1
    local steps = 1

    local adjustedMin = min - pos
    local adjustedMax = max - pos

    render.SetMaterial(normal)
    render.DrawWireframeBox(pos, Angle(0, 0, 0), adjustedMin, adjustedMax, colour, false)
end

local function DrawDynamicZone()
    if isPlacing and startPoint and endPoint then
        local min = SnapToGrid(Vector(
            minm(startPoint.x, endPoint.x),
            minm(startPoint.y, endPoint.y),
            minm(startPoint.z, endPoint.z)
        ))
        local max = SnapToGrid(Vector(
            maxm(startPoint.x, endPoint.x),
            maxm(startPoint.y, endPoint.y),
            maxm(startPoint.z + currentZoneHeight, endPoint.z + currentZoneHeight)
        ))

        DrawZoneWireFrame(min, max, Color(255, 255, 255), 1, InputCheck():GetPos(), 2)
    end
end


local ZoneColorMap = {
    [0] = Color(0, 255, 0, 120),        -- Normal Start
    [1] = Color(255, 0, 0, 120),        -- Normal End
    [2] = Color(0, 80, 255, 120),       -- Bonus Start
    [3] = Color(0, 80, 255, 80),        -- Bonus End
    [4] = Color(153, 0, 153, 120),      -- Anti-Cheat
    [5] = Color(80, 80, 255, 120),      -- Freestyle
    [6] = Color(140, 140, 140, 120),    -- NormalAC
    [7] = Color(0, 0, 153, 120),        -- BonusAC
    [100] = Color(255, 200, 0, 120),    -- LegitSpeed
    [122] = Color(255, 0, 128, 120),    -- Gravity Zone
    [123] = Color(0, 255, 128, 120),    -- Step Size
    [124] = Color(128, 128, 255, 120),  -- Restart Zone
    [125] = Color(255, 128, 0, 120),    -- Booster
    [126] = Color(255, 255, 255, 120),  -- Full Bright
    [130] = Color(255, 0, 128, 120),    -- Helper
}

local function DrawPreviewCircle(playerPos, circleColor)
    if not previewPos then return end

    local segments = 60
    local radius = 5
    local lineColor = Color(255, 255, 255, 200)
    local lineHeight = 25
    local sideLineLength = 25

    local vertices = {}
    for i = 0, segments do
        local angle = math.rad((i / segments) * -360)
        local x = math.cos(angle) * radius
        local y = math.sin(angle) * radius

        table.insert(vertices, {
            x = x,
            y = y,
            u = 0.5 + (x / radius) * 0.5,
            v = 0.5 + (y / radius) * 0.5,
        })
    end

    cam.Start3D2D(previewPos, Angle(0, 0, 0), 1)
        surface.SetDrawColor(circleColor or Color(0, 255, 0, 100))
        surface.DrawPoly(vertices)
    cam.End3D2D()

    local startPos = previewPos
    local endPos = previewPos + Vector(0, 0, lineHeight)
    render.SetColorMaterial()
    render.DrawLine(startPos, endPos, lineColor, false)

    local topStart = previewPos + Vector(0, 0, lineHeight)
    local bottomStart = previewPos

    local topLeft = bottomStart + Vector(0, -sideLineLength, 0)
    local topRight = bottomStart + Vector(0, sideLineLength, 0)
    local bottomLeft = bottomStart + Vector(-sideLineLength, 0, 0)
    local bottomRight = bottomStart + Vector(sideLineLength, 0, 0)

    render.DrawLine(topLeft, topRight, lineColor, false)
    render.DrawLine(bottomLeft, bottomRight, lineColor, false)

    if playerPos then
        render.DrawLine(playerPos, previewPos, lineColor, false)
    end
end

hook.Add("PostDrawOpaqueRenderables", "PreviewZone", function()
    if not AdminLoad.Editor or not AdminLoad.Editor.Active then return end

    local player = LocalPlayer()
    local playerPos = player:GetPos() + Vector(0, 0, 32)

    local zoneType = AdminLoad.Editor.Type or 0
    local zoneColor = ZoneColorMap[zoneType] or Color(255, 255, 255, 100)

    DrawPreviewCircle(playerPos, zoneColor)
    DrawPreviewCircle(nil, zoneColor)
    DrawDynamicZone()
end)

hook.Add("Tick", "ZonePlace", function()
    if not AdminLoad.Editor or not AdminLoad.Editor.Active or not canPlaceZone then return end

    if input.IsKeyDown(KEY_0) and not exitCooldown then
        isPlacing = false
        isZoneFinalized = false
        startPoint = nil
        endPoint = nil
        previewPos = nil
        zonePlacementEnabled = false
        AdminLoad.Editor = nil

        NETWORK:StartNetworkMessage(nil, "CancelZonePlacement", LocalPlayer())

        exitCooldown = true
        timer.Simple(0.3, function() exitCooldown = false end)
        return
    end

    if input.IsKeyDown(KEY_1) and not zoneMenuOpened then
        UI:OpenZoneTypeMenu()
        zoneMenuOpened = true
        timer.Simple(0.3, function() zoneMenuOpened = false end)
    end

    if input.IsKeyDown(KEY_2) then
        zonePlacementEnabled = true
    end

    if not zonePlacementEnabled then return end

    local trace = InputCheck():GetEyeTrace()
    previewPos = SnapToGrid(trace.HitPos)

    if input.IsMouseDown(MOUSE_LEFT) and not isPlacing then
        isPlacing = true
        isZoneFinalized = false
        startPoint = previewPos
    end

    local finalizeKey = input.IsKeyDown(KEY_4)
    local rightClick = input.IsMouseDown(MOUSE_RIGHT)

    if (finalizeKey or rightClick) and isPlacing then
        isZoneFinalized = true
        endPoint = previewPos

        NETWORK:StartNetworkMessage(nil, "SendZoneData", LocalPlayer(), startPoint, endPoint, AdminLoad.Editor.Type, currentZoneHeight)

        isPlacing = false
        isZoneFinalized = false
        startPoint = nil
        endPoint = nil
        previewPos = nil
        AdminLoad.Editor = nil
        zonePlacementEnabled = false
    end

    if input.IsKeyDown(KEY_5) and not cancelCooldown then
        NETWORK:StartNetworkMessage(nil, "CancelZonePlacement", LocalPlayer())

        cancelCooldown = true
        timer.Simple(0.3, function() cancelCooldown = false end)
    end

    if isPlacing and not isZoneFinalized then
        endPoint = previewPos
    end

    if input.IsKeyDown(KEY_3) and not heightAdjustCooldown then
        heightAdjustCooldown = true

        -- Replace soon
        Derma_StringRequest(
            "Zone Height Adjustment",
            "Enter new desired height (default is " .. tostring(currentZoneHeight) .. "):",
            tostring(currentZoneHeight),
            function(text)
                local newHeight = tonumber(text)
                if newHeight and newHeight > 0 then
                    currentZoneHeight = newHeight
                    chat.AddText(Color(50, 255, 50), "[ZoneTool] Height set to " .. newHeight .. " units.")
                else
                    chat.AddText(Color(255, 50, 50), "[ZoneTool] Invalid height.")
                end
            end
        )

        timer.Simple(0.5, function() heightAdjustCooldown = false end)
    end
end)

hook.Add("HUDPaint", "ZoneEditorToolHUD", function()
    if not showZoneHUD then return end
    if not AdminLoad.Editor or not AdminLoad.Editor.Active then return end

    local w, h = 280, 180
    local startX, startY = 5, 65
    local padding = 8

    draw.SimpleText("Zone Management Tool", "HUDTitle", startX + padding, startY + padding - 5, Color(255, 120, 40), TEXT_ALIGN_LEFT)

    local statusText = ""
    if not canPlaceZone then
        statusText = "Cannot Place Zones"
    elseif not zonePlacementEnabled then
        statusText = "Press 1 to Start Placing"
    elseif isPlacing and not isZoneFinalized then
        statusText = "Placing... (LMB to Start, RMB to End)"
    elseif isZoneFinalized then
        statusText = "Placement Finalized"
    end

    draw.SimpleText("Status | " .. statusText, "HUDFont", startX + padding, startY + 25, Color(255, 120, 40), TEXT_ALIGN_LEFT)

    local options = {
        "1 | Select Zone",
        "2 | Place New Zone (" .. (AdminLoad.Editor and AdminLoad.Editor.ZoneName or "Select First") .. ")",
        "3 | Zone Height Adjustment",
        "4 | Finish Placement",
        "5 | Cancel Placement",
        "6 | Manage Zones",
        "0 | Exit Management Tool"
    }

    local y = startY + 50
    for i, text in ipairs(options) do
        local color = color_white

        if string.StartWith(text, "1") and AdminLoad.Editor and AdminLoad.Editor.Type then
            color = Color(50, 255, 50)
        elseif string.StartWith(text, "2") and zonePlacementEnabled and not isPlacing then
            color = Color(50, 255, 50)
        elseif string.StartWith(text, "4") and isZoneFinalized then
            color = Color(50, 255, 50)
        end

        draw.SimpleText(text, "HUDFont", startX + padding, y, color, TEXT_ALIGN_LEFT)
        y = y + 20
    end
end)

net.Receive("zone_toggle_hud", function()
    showZoneHUD = net.ReadBool()
end)

net.Receive("zone_editor_data", function()
    local active = net.ReadBool()
    local typeID = net.ReadUInt(8)

    AdminLoad = AdminLoad or {}
    AdminLoad.Editor = AdminLoad.Editor or {}

    AdminLoad.Editor.Active = active
    AdminLoad.Editor.Type = typeID

    if not AdminLoad.Editor.ZoneName or AdminLoad.Editor.ZoneName == "Select First" then
        AdminLoad.Editor.ZoneName = ZoneTypeCache[typeID] or "Select First"
    end
end)

NETWORK:GetNetworkMessage("EditZone", function(_, data)
    AdminLoad = AdminLoad or {}
    AdminLoad.Editor = data[1]
end)