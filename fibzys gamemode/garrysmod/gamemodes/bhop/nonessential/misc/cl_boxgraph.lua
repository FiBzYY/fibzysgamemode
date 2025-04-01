local enable3DBox = CreateClientConVar("bhop_boxgraph", "0", true, false, "Enable or disable the 3D box.")
local enable3DLines = CreateClientConVar("bhop_graphminecraft", "0", true, false, "Enable or disable the 3D minecraft like red and green lines.")

local boxVertices = {
    Vector(-10, -10, -10),
    Vector(10, -10, -10),
    Vector(10, 10, -10),
    Vector(-10, 10, -10),
    Vector(-10, -10, 10),
    Vector(10, -10, 10),
    Vector(10, 10, 10),
    Vector(-10, 10, 10),
}

local function DrawThickLine(startPos, endPos, width, color)
    render.SetMaterial(Material("sprites/jscfixtimer"))
    render.DrawBeam(startPos, endPos, width, 0, 1, color)
end

hook.Add("PostDrawOpaqueRenderables", "DrawRotating3DBox", function()
    if not enable3DBox:GetBool() then return end

    local ply = LocalPlayer()
    local eyeAngles = ply:EyeAngles()

    local forward = ply:GetForward() * 100
    local boxPos = ply:EyePos() + forward

    local yawAngle = eyeAngles
    local rotation = Angle(0, yawAngle, 0)

    cam.Start3D()

    local rotatedVertices = {}
    for _, vertex in ipairs(boxVertices) do
        local rotatedVertex = Vector(vertex.x, vertex.y, vertex.z)
        rotatedVertex:Rotate(rotation)
        table.insert(rotatedVertices, rotatedVertex)
    end

    for i = 1, 4 do
        local nextIndex = (i % 4) + 1
        DrawThickLine(boxPos + rotatedVertices[i], boxPos + rotatedVertices[nextIndex], 1, Color(255, 255, 255))
        DrawThickLine(boxPos + rotatedVertices[i + 4], boxPos + rotatedVertices[nextIndex + 4], 1, Color(255, 255, 255))
        DrawThickLine(boxPos + rotatedVertices[i], boxPos + rotatedVertices[i + 4], 1, Color(255, 255, 255))
    end

    cam.End3D()
end)

local function DrawThickLine(startPos, endPos, width, color)
    render.SetMaterial(Material("sprites/jscfixtimer"))
    render.DrawBeam(startPos, endPos, width, 0, 1, color)
end

hook.Add("PostDrawOpaqueRenderables", "DrawRotatingLines", function()
    if not enable3DLines:GetBool() then return end

    local ply = LocalPlayer()
    local eyeAngles = ply:EyeAngles()

    local forward = ply:GetForward() * 200
    local linePos = ply:EyePos() + forward

    local yawAngle = eyeAngles
    local rotation = Angle(0, yawAngle, 0)

    cam.Start3D()

    local greenLineStart = linePos
    local greenLineEnd = linePos + Vector(0, 0, 30)
    DrawThickLine(greenLineStart, greenLineEnd, 2, Color(0, 255, 0))

    local redLineOffset = Vector(30, 0, 0)

    redLineOffset:Rotate(rotation)

    local redLineStart = greenLineStart
    local redLineEnd = greenLineStart + redLineOffset
    DrawThickLine(redLineStart, redLineEnd, 2, Color(255, 0, 0))

    local forwardRedLineStart = greenLineStart
    local forwardRedLineEnd = greenLineStart + Vector(0, 30, 0)
    DrawThickLine(forwardRedLineStart, forwardRedLineEnd, 2, Color(0, 0, 255))

    cam.End3D()
end)

local draw3DAnglesHUD = CreateClientConVar("bhop_draw_3d_angles", "0", true, false, "Enable/disable 3D angles HUD")

local function DrawArrowhead(x, y, angle, size)
    local arrowPoints = {
        { x = x + math.cos(angle) * size, y = y + math.sin(angle) * size },
        { x = x + math.cos(angle - math.rad(135)) * size / 2, y = y + math.sin(angle - math.rad(135)) * size / 2 },
        { x = x + math.cos(angle + math.rad(135)) * size / 2, y = y + math.sin(angle + math.rad(135)) * size / 2 }
    }
    surface.DrawPoly(arrowPoints)
end

hook.Add("HUDPaint", "Draw3DLinesWithArrowsBasedOnViewAngles", function()
    if not draw3DAnglesHUD:GetBool() then return end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local angles = ply:EyeAngles()

    local xPos = ScrW() / 2
    local yPos = ScrH() / 2
    local size = 100

    local pitchLineLength = size / 2
    local yawLineLength = size / 2
    local rollLineLength = size / 2

    local pitchEndX = xPos + math.cos(math.rad(angles.p)) * pitchLineLength
    local pitchEndY = yPos - math.sin(math.rad(angles.p)) * pitchLineLength

    local yawEndX = xPos + math.cos(math.rad(angles.y)) * yawLineLength
    local yawEndY = yPos - math.sin(math.rad(angles.y)) * yawLineLength

    local rollEndX = xPos + math.cos(math.rad(angles.r)) * rollLineLength
    local rollEndY = yPos - math.sin(math.rad(angles.r)) * rollLineLength

    surface.SetDrawColor(255, 0, 0)
    surface.DrawLine(xPos, yPos, pitchEndX, pitchEndY)
    DrawArrowhead(pitchEndX, pitchEndY, math.rad(angles.p), 10)

    surface.SetDrawColor(0, 255, 0)
    surface.DrawLine(xPos, yPos, yawEndX, yawEndY)
    DrawArrowhead(yawEndX, yawEndY, math.rad(angles.y), 10)

    surface.SetDrawColor(0, 0, 255)
    surface.DrawLine(xPos, yPos, rollEndX, rollEndY)
    DrawArrowhead(rollEndX, rollEndY, math.rad(angles.r), 10)
end)

local function DrawWishdirLine(x, y, angle, size)
    local lineLength = size * 2
    local lineEndX = x + math.cos(math.rad(angle)) * lineLength
    local lineEndY = y - math.sin(math.rad(angle)) * lineLength

    surface.SetDrawColor(0, 255, 255)
    surface.DrawLine(x, y, lineEndX, lineEndY)

    DrawArrowhead(lineEndX, lineEndY, math.rad(angle), size)
end

local function DisplayStatsHUD()
    if not draw3DAnglesHUD:GetBool() then return end

    local screenWidth = ScrW()
    local screenHeight = ScrH()

    local textX = screenWidth / 2
    local textY = screenHeight / 2

    local ply = LocalPlayer()
    if not ply or not ply.wishvel then return end
    local wishdir = math.deg(math.atan2(ply.wishvel.y, ply.wishvel.x))

    DrawWishdirLine(textX, textY, wishdir, 10)

    surface.SetFont("HUDTitleSmall")
    surface.SetTextColor(255, 255, 255)

    local textWidth, textHeight = surface.GetTextSize("Wish Direction: " .. wishdir)

    local textPosX = textX - textWidth / 2
    local textPosY = textY - textHeight / 2
end
hook.Add("HUDPaint", "DisplayStatsHUD", DisplayStatsHUD)