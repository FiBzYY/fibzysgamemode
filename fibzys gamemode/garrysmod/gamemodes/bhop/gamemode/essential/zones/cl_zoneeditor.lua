local hook_Add = hook.Add
local InputCheck = LocalPlayer

-- bools
local isPlacing = false
local isZoneFinalized = false
local startPoint = nil
local endPoint = nil
local canPlaceZone = true
local previewPos = nil
local zonePlacementEnabled = false
local minm, maxm = math.min, math.max

net.Receive("CancelZonePlacement", function()
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
            maxm(startPoint.z + BHOP.Zone.ZoneHeight, endPoint.z + BHOP.Zone.ZoneHeight)
        ))

        DrawZoneWireFrame(min, max, Color(255, 255, 255), 1, InputCheck():GetPos(), 2)
    end
end

local function DrawPreviewCircle(playerPos)
    if previewPos then
        local segments = 60
        local radius = 5
        local circleColor = Color(0, 255, 0, 100)
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
            surface.SetDrawColor(circleColor)
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
            local centerOfCircle = previewPos
            render.DrawLine(playerPos, centerOfCircle, lineColor, false)
        end
    end
end

hook_Add("PostDrawOpaqueRenderables", "PreviewZone", function()
    if not AdminLoad.Editor or not AdminLoad.Editor.Active then return end
    local player = LocalPlayer()
    local playerPos = player:GetPos() + Vector(0, 0, 32)
    DrawPreviewCircle(playerPos)
    DrawPreviewCircle()
    DrawDynamicZone()
end)

hook.Add("Tick", "ZonePlace", function()
    if not AdminLoad.Editor or not AdminLoad.Editor.Active or not canPlaceZone then return end

    if input.IsKeyDown(KEY_1) then
        zonePlacementEnabled = true
    end

    if not zonePlacementEnabled then return end

    local trace = InputCheck():GetEyeTrace()
    previewPos = SnapToGrid(trace.HitPos)

    if input.IsMouseDown(MOUSE_LEFT) and not isPlacing then
        isPlacing = true
        isZoneFinalized = false
        startPoint = previewPos
    elseif input.IsMouseDown(MOUSE_RIGHT) and isPlacing then
        isZoneFinalized = true
        endPoint = previewPos

        net.Start("SendZoneData")
        net.WriteTable({
            Start = startPoint,
            End = endPoint,
            Type = AdminLoad.Editor.Type
        })
        net.SendToServer()

        isPlacing = false
        isZoneFinalized = false
        startPoint = nil
        endPoint = nil
        previewPos = nil
        AdminLoad.Editor = nil
        zonePlacementEnabled = false
    end

    if isPlacing and not isZoneFinalized then
        endPoint = previewPos
    end
end)

hook_Add("HUDPaint", "ZonePlacement", function()
    if not AdminLoad.Editor or not AdminLoad.Editor.Active or not canPlaceZone then return end

    local text = ""

    if not zonePlacementEnabled then
        text = "Press 1 to enable zone placement mode."
    elseif not isPlacing then
        text = "Left-click to set the start point."
    elseif isPlacing and not isZoneFinalized then
        text = "Right-click to set the end point and finalize the zone."
    end

    draw.SimpleText(text, "HUDFont", ScrW() / 2, ScrH() / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
end)

hook_Add("HUDPaint", "GridSize", function()
    if not AdminLoad.Editor or not AdminLoad.Editor.Active then return end

    local snapSize = snapGridSize:GetInt()
    draw.SimpleText(
        "Snap Grid Size: " .. snapSize .. " units",
        "HUDFont",
        ScrW() / 2,
        ScrH() / 2 + 50,
        Color(255, 255, 255),
        TEXT_ALIGN_CENTER,
        TEXT_ALIGN_BOTTOM
    )
end)