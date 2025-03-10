--[[

 ____  __  _  _    ____  _  _  ____    ____  ____  ____ 
(  __)(  )( \/ )  (_  _)/ )( \(  __)  (  __)(  _ \/ ___)
 ) _)  )(  )  (     )(  ) __ ( ) _)    ) _)  ) __/\___ \
(__)  (__)(_/\_)   (__) \_)(_/(____)  (__)  (__)  (____/ !

]]--

local surface = surface
local Color = Color
local color_white = color_white

local TEXT_ALIGN_LEFT = 0
local TEXT_ALIGN_CENTER = 1
local TEXT_ALIGN_RIGHT = 2
local TEXT_ALIGN_TOP = 3
local TEXT_ALIGN_BOTTOM = 4

local surface_SetFont = surface.SetFont
local surface_GetTextSize = surface.GetTextSize
local surface_SetTextPos = surface.SetTextPos
local surface_SetTextColor = surface.SetTextColor
local surface_DrawText = surface.DrawText
local surface_SetTexture = surface.SetTexture
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect
local surface_DrawTexturedRect = surface.DrawTexturedRect
local surface_DrawTexturedRectRotated = surface.DrawTexturedRectRotated
local surface_GetTextureID = surface.GetTextureID
local string_sub = string.sub
local math_ceil = math.ceil
local Tex_Corner8 = surface_GetTextureID("gui/corner8")
local Tex_Corner16 = surface_GetTextureID("gui/corner16")
local Tex_white = surface_GetTextureID("vgui/white")

local CachedFontHeights = {}
local w, h
local function draw_GetFontHeight(font)
    if CachedFontHeights[font] then
        return CachedFontHeights[font]
    end

    surface_SetFont(font)
    w, h = surface_GetTextSize("W")
    CachedFontHeights[font] = h

    return h
end

local font = "TargetID"
local cache = setmetatable({}, {
    __mode = "k"
})

timer.Create("surface.ClearFontCache", 1800, 0, function()
    for k, _ in pairs(cache) do
        cache[k] = nil
    end
end)

function surface.SetFont(_font)
    font = _font
    return surface_SetFont(_font)
end

function surface.GetTextSize(text)
    if text == nil or text == "" then return 1, 1 end

    if not cache[font] then
        cache[font] = {}
    end

    if not cache[font][text] then
        local w, h = surface_GetTextSize(text)
        cache[font][text] = {w = w, h = h}
        return w, h
    end

    return cache[font][text].w, cache[font][text].h
end

local function draw_SimpleText(text, font, x, y, colour, xalign, yalign)
    surface_SetFont(font)
    local w, h = surface_GetTextSize(text)

    if xalign == TEXT_ALIGN_CENTER then
        x = x - w / 2
    elseif xalign == TEXT_ALIGN_RIGHT then
        x = x - w
    end

    if yalign == TEXT_ALIGN_CENTER then
        h = draw_GetFontHeight(font)
        y = y - h / 2
    elseif yalign == TEXT_ALIGN_BOTTOM then
        h = draw_GetFontHeight(font)
        y = y - h
    end

    surface_SetTextPos(x, y)
    if colour then
        surface_SetTextColor(colour.r, colour.g, colour.b, colour.a)
    else
        surface_SetTextColor(255, 255, 255, 255)
    end
    surface_DrawText(text)
end

local curX, curY
local curString = ""
local lineHeight
local ch
local strNL = "\n"
local strT = "\t"
local strEmpty = ""

local function draw_DrawText(text, font, x, y, colour, xalign, yalign)
    surface_SetFont(font)
    local lineHeight = draw_GetFontHeight(font)
    local curX = x
    local curY = y
    local curString = ""

    for i = 1, #text do
        local ch = string_sub(text, i, i)
        if ch == "\n" then
            if #curString > 0 then
                draw_SimpleText(curString, font, curX, curY, colour, xalign, yalign)
            end
            curY = curY + lineHeight
            curX = x
            curString = ""
        elseif ch == "\t" then
            if #curString > 0 then
                draw_SimpleText(curString, font, curX, curY, colour, xalign, yalign)
            end
            local tmpSizeX, tmpSizeY = surface_GetTextSize(curString)
            curX = math_ceil((curX + tmpSizeX) / 50) * 50
            curString = ""
        else
            curString = curString .. ch
        end
    end

    if #curString > 0 then
        draw_SimpleText(curString, font, curX, curY, colour, xalign, yalign)
    end
end

local function draw_RoundedBox(bordersize, x, y, w, h, color)
    surface_SetDrawColor(color)

    local effectiveBorderSize = math.min(bordersize, w / 2, h / 2)

    surface_DrawRect(x + effectiveBorderSize, y, w - effectiveBorderSize * 2, h)
    surface_DrawRect(x, y + effectiveBorderSize, effectiveBorderSize, h - effectiveBorderSize * 2)
    surface_DrawRect(x + w - effectiveBorderSize, y + effectiveBorderSize, effectiveBorderSize, h - effectiveBorderSize * 2)

    local tex = Tex_Corner8
    if effectiveBorderSize > 8 then tex = Tex_Corner16 end

    surface_SetTexture(tex)

    surface_DrawTexturedRectRotated(x + effectiveBorderSize / 2, y + effectiveBorderSize / 2, effectiveBorderSize, effectiveBorderSize, 0)
    surface_DrawTexturedRectRotated(x + w - effectiveBorderSize / 2, y + effectiveBorderSize / 2, effectiveBorderSize, effectiveBorderSize, 270)
    surface_DrawTexturedRectRotated(x + effectiveBorderSize / 2, y + h - effectiveBorderSize / 2, effectiveBorderSize, effectiveBorderSize, 90)
    surface_DrawTexturedRectRotated(x + w - effectiveBorderSize / 2, y + h - effectiveBorderSize / 2, effectiveBorderSize, effectiveBorderSize, 180)
end

local text, font
local strDefault = "DermaDefault"
local x, y
local xalign
local yalign
local w, h

local function draw_Text(tab)
    text = tab.text
    font = tab.font or strDefault
    x = tab.pos[1] or 0
    y = tab.pos[2] or 0
    xalign = tab.xalign
    yalign = tab.yalign

    surface_SetFont(font)

    if xalign == TEXT_ALIGN_CENTER then
        w, h = surface_GetTextSize(text)
        x = x - w / 2
    elseif xalign == TEXT_ALIGN_RIGHT then
        w, h = surface_GetTextSize(text)
        x = x - w
    end

    if yalign == TEXT_ALIGN_CENTER then
        h = draw_GetFontHeight(font)
        y = y - h / 2
    end

    surface_SetTextPos(x, y)

    if tab.color then
        surface_SetTextColor(tab.color)
    else
        surface_SetTextColor(255, 255, 255, 255)
    end

    surface_DrawText(text)
end

function draw.WordBox(bordersize, x, y, text, font, color, fontcolor)
    surface_SetFont(font)
    w, h = surface_GetTextSize(text)

    draw.RoundedBox(bordersize, x, y, w + bordersize * 2, h + bordersize * 2, color)

    surface_SetTextColor(fontcolor.r, fontcolor.g, fontcolor.b, fontcolor.a)
    surface_SetTextPos(x + bordersize, y + bordersize)
    surface_DrawText(text)
end

local color, pos
function draw.TextShadow(tab, distance, alpha)
    alpha = alpha or 200

    color = tab.color
    pos = tab.pos
    tab.color = Color(0, 0, 0, alpha)
    tab.pos = {pos[1] + distance, pos[2] + distance}

    draw_Text(tab)

    tab.color = color
    tab.pos = pos

    draw_Text(tab)
end

function draw.TexturedQuad(tab)
    surface_SetTexture(tab.texture)
    surface_SetDrawColor(tab.color or color_white)
    surface_DrawTexturedRect(tab.x, tab.y, tab.w, tab.h)
end

function draw.NoTexture()
    surface_SetTexture(Tex_white)
end

function draw.RoundedBoxEx(bordersize, x, y, w, h, color, a, b, c, d)
    surface_SetDrawColor(color)

    local effectiveBorderSize = math.min(bordersize, w / 2, h / 2)

    surface_DrawRect(x + effectiveBorderSize, y, w - effectiveBorderSize * 2, h)
    surface_DrawRect(x, y + effectiveBorderSize, effectiveBorderSize, h - effectiveBorderSize * 2)
    surface_DrawRect(x + w - effectiveBorderSize, y + effectiveBorderSize, effectiveBorderSize, h - effectiveBorderSize * 2)

    surface_SetTexture(effectiveBorderSize > 8 and Tex_Corner16 or Tex_Corner8)

    if a then
        surface_DrawTexturedRectRotated(x + effectiveBorderSize / 2, y + effectiveBorderSize / 2, effectiveBorderSize, effectiveBorderSize, 0)
    else
        surface_DrawRect(x, y, effectiveBorderSize, effectiveBorderSize)
    end

    if b then
        surface_DrawTexturedRectRotated(x + w - effectiveBorderSize / 2, y + effectiveBorderSize / 2, effectiveBorderSize, effectiveBorderSize, 270)
    else
        surface_DrawRect(x + w - effectiveBorderSize, y, effectiveBorderSize, effectiveBorderSize)
    end

    if c then
        surface_DrawTexturedRectRotated(x + effectiveBorderSize / 2, y + h - effectiveBorderSize / 2, effectiveBorderSize, effectiveBorderSize, 90)
    else
        surface_DrawRect(x, y + h - effectiveBorderSize, effectiveBorderSize, effectiveBorderSize)
    end

    if d then
        surface_DrawTexturedRectRotated(x + w - effectiveBorderSize / 2, y + h - effectiveBorderSize / 2, effectiveBorderSize, effectiveBorderSize, 180)
    else
        surface_DrawRect(x + w - effectiveBorderSize, y + h - effectiveBorderSize, effectiveBorderSize, effectiveBorderSize)
    end
end

local steps
function draw.SimpleTextOutlined(text, font, x, y, colour, xalign, yalign, outlinewidth, outlinecolour)
    steps = (outlinewidth * 2) / 3
    if steps < 1 then steps = 1 end

    for _x = -outlinewidth, outlinewidth, steps do
        for _y = -outlinewidth, outlinewidth, steps do
            draw_SimpleText(text, font, x + _x, y + _y, outlinecolour, xalign, yalign)
        end
    end

    draw_SimpleText(text, font, x, y, colour, xalign, yalign)
end

draw.GetFontHeight = draw_GetFontHeight
draw.SimpleText = draw_SimpleText
draw.DrawText = draw_DrawText
draw.RoundedBox = draw_RoundedBox
draw.Text = draw_Text
draw.RoundedBoxEx = draw.RoundedBoxEx