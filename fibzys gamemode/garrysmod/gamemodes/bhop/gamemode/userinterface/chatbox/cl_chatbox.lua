CreateClientConVar("bhop_chatbox", "1", true, false)

function InitChatbox()
    if GetConVar("bhop_chatbox"):GetInt() == 0 then
        return
    end

    chatbox = vgui.Create("DFrame")
    chatbox:SetSize(ScrW() * 0.4 + 20, ScrH() * 0.28 + 20)
    chatbox:SetTitle("")
    chatbox:ShowCloseButton(false)
    chatbox:SetDraggable(false)
    chatbox:SetMinWidth(320)
    chatbox:SetMinHeight(130)
    chatbox:SetPos(ScrW() * 0.0116, ScrH() * 0.6)

    function chatbox:Think()
        if input.IsKeyDown(KEY_ESCAPE) then
            HideChatbox()
        end
    end

    chatbox.entry = chatbox:Add("DTextEntry")
    chatbox.entry:SetPos(15, chatbox:GetTall() - 45)
    chatbox.entry:SetSize(chatbox:GetWide() - 30, 30)
    chatbox.entry:SetDrawBorder(false)
    chatbox.entry:SetTextColor(color_white)
    chatbox.entry:SetHighlightColor(Color(0, 100, 200))
    chatbox.entry:SetDrawBackground(false)
    chatbox.entry:SetFont("chatbox.font")
    chatbox.entry:SetCursorColor(color_white)

    function chatbox.entry:OnKeyCodeTyped(keyCode)
        if keyCode == KEY_ESCAPE then
            HideChatbox()
            gui.HideGameUI()
        elseif keyCode == KEY_ENTER then
            if string.Trim(self:GetText()) ~= "" then
                LocalPlayer():ConCommand('say "' .. self:GetText() .. '"')
                self:SetText("")
            end
            HideChatbox()
        end
    end

    chatbox.rich = chatbox:Add("RichText")
    chatbox.rich:SetPos(15, 15)
    chatbox.rich:SetSize(chatbox:GetWide() - 30, chatbox:GetTall() - 70)

    function chatbox.rich:PerformLayout()
        self:SetFontInternal("chatbox.font")
    end

    function chatbox.rich:CheckScroll()
        if not chatboxHid and chatbox.rich:GetNumLines() > 8 then
            self:SetVerticalScrollbarEnabled(true)
        else
            self:SetVerticalScrollbarEnabled(false)
        end
    end

    function chatbox.rich:Think()
        self:GotoTextEnd()
    end

    function chatbox.entry:Paint(width, height)
        surface.SetDrawColor(32, 32, 32, 255)
        surface.DrawRect(0, 0, width, height)
        derma.SkinHook("Paint", "TextEntry", self, width, height)
    end
    chatboxEntryPaint = chatbox.entry.Paint

    function chatbox:Paint(width, height)
        surface.SetDrawColor(32, 32, 32, 255)
        surface.DrawRect(0, 0, width, height)

        surface.SetDrawColor(42, 42, 42, 255)
        surface.DrawRect(10, 10, width - 20, height - 20)
    end
    chatboxPaint = chatbox.Paint

    HideChatbox()
end

function HideChatbox()
    if not chatbox or chatboxHid then return end

    chatbox.Paint = function() end
    chatbox.entry.Paint = function() end
    chatbox.rich.Paint = function() end
    chatbox.rich:SetVerticalScrollbarEnabled(false)
    chatbox:SetMouseInputEnabled(false)
    chatbox:SetKeyBoardInputEnabled(false)
    chatbox.entry:SetText("")
    gui.EnableScreenClicker(false)
    gamemode.Call("FinishChat")
    chatboxHid = true
end

function OpenChatbox()
    if GetConVar("bhop_chatbox"):GetInt() == 0 then
        return
    end

    if not chatbox then
        InitChatbox()
    end

    if not chatboxHid then return end

    chatbox.Paint = chatboxPaint
    chatbox.entry.Paint = chatboxEntryPaint
    chatbox:MakePopup()
    chatbox:ParentToHUD()
    chatbox.entry:RequestFocus()
    chatboxHid = false
    chatbox.rich:CheckScroll()

    gamemode.Call("StartChat")
end

local detourAddText = chat.AddText
local firstMessage = true
local FADE_TIME = 5
local FADE_DURATION = 2
local messages = {}

local function addMessage(segments)
    table.insert(messages, {
        segments = segments,
        time = CurTime(),
        alpha = 255
    })
end

function chat.AddText(...)
    if GetConVar("bhop_chatbox"):GetInt() == 0 then
        detourAddText(...)
        return
    end

    if not chatbox then
        InitChatbox()
    end

    if not firstMessage then
        chatbox.rich:AppendText("\n")
    end
    firstMessage = false

    local segments = {}

    for _, v in ipairs({...}) do
        if type(v) == "table" then
            table.insert(segments, {type = "color", value = Color(v.r or 255, v.g or 255, v.b or 255, v.a or 255)})
        elseif type(v) == "string" then
            table.insert(segments, {type = "text", value = v})
        elseif IsValid(v) and v:IsPlayer() then
            table.insert(segments, {type = "color", value = Color(0, 0, 200, 255)})
            table.insert(segments, {type = "text", value = v:Nick()})
        end
    end

    addMessage(segments)
    detourAddText(...)
end

hook.Add("Think", "ChatboxFader", function()
    if not chatbox or not chatbox.rich then return end

    local isOpen = not chatboxHid

    chatbox.rich:SetText("")

    for _, data in ipairs(messages) do
        if isOpen then
            data.alpha = 255
        else
            local elapsed = CurTime() - data.time
            if elapsed > FADE_TIME then
                local fadeProgress = math.Clamp((elapsed - FADE_TIME) / FADE_DURATION, 0, 1)
                data.alpha = 255 * (1 - fadeProgress)
            else
                data.alpha = 255
            end
        end

        for _, segment in ipairs(data.segments) do
            if segment.type == "color" then
                local c = segment.value
                chatbox.rich:InsertColorChange(c.r, c.g, c.b, math.Clamp(data.alpha, 0, 255))
            elseif segment.type == "text" then
                chatbox.rich:AppendText(segment.value)
            end
        end
        chatbox.rich:AppendText("\n")
    end

    chatbox.rich:CheckScroll()
end)

function GM:StartChat()
    if GetConVar("bhop_chatbox"):GetInt() == 0 then
        return false
    end
    return true
end

hook.Add("PlayerBindPress", "ChatboxCommand", function(client, bind, pressed)
    if GetConVar("bhop_chatbox"):GetInt() == 0 then
        return
    end

    if bind == "messagemode" or bind == "messagemode2" then
        OpenChatbox()
        return true
    end
end)

hook.Add("HUDShouldDraw", "hidechat", function(name)
    if name == "CHudChat" then
        if GetConVar("bhop_chatbox"):GetInt() == 0 then
            if chatbox then
                chatbox:Remove()
                chatbox = nil
            end
            return true
        else
            return false
        end
    end
end)

if GetConVar("bhop_chatbox"):GetInt() == 1 then
    InitChatbox()
end