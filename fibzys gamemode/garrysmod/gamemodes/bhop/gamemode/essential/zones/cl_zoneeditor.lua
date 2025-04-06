-- Cache
local hook_Add, InputCheck = hook.Add, LocalPlayer
local isPlacing = false
local isZoneFinalized = false
local startPoint = nil
local endPoint = nil
local canPlaceZone = true
local previewPos = nil
local zonePlacementEnabled = false
local minm, maxm = math.min, math.max

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
            maxm(startPoint.z + BHOP.Zone.ZoneHeight, endPoint.z + BHOP.Zone.ZoneHeight)
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

        NETWORK:StartNetworkMessage(nil, "SendZoneData", LocalPlayer(), startPoint, endPoint, AdminLoad.Editor.Type)

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

-- placement hud
hook.Add("HUDPaint", "ZoneEditorHUD", function()
    if not AdminLoad.Editor or not AdminLoad.Editor.Active then return end

    local startX, startY = 10, 100
    local lineSpacing = 20
    local y = startY
    local green = Color(0, 255, 0)
    local white = Color(255, 255, 255)

    local function DrawStep(stepLabel, stepInfo)
        draw.SimpleText(stepLabel, "HUDFont", startX, y, green, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(stepInfo, "HUDFont", startX + 70, y, white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        y = y + lineSpacing
    end

    if canPlaceZone then
        if not zonePlacementEnabled then
            DrawStep("Step 1:", "Press 1 to enable zone placement mode.")
        elseif not isPlacing then
            DrawStep("Step 2:", "Left-click to set the start point.")
        elseif isPlacing and not isZoneFinalized then
            DrawStep("Step 3:", "Right-click to set the end point and finalize the zone.")
        end
    end

    draw.SimpleText("Grid Size:", "HUDFont", startX, y, green, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(snapGridSize:GetInt() .. " units", "HUDFont", startX + 90, y, white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end)