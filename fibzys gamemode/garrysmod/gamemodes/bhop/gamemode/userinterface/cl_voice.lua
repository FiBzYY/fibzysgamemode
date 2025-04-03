CreateClientConVar("bhop_customvoice", "1", true, false, "Enable or disable custom bhop voice panel.")

-- Cache
local iMuted = Material("icon32/muted.png")
local cWhite = Color(255, 255, 255)
local bgColor = Color(42, 42, 42, 255)
local borderColor = Color(35, 35, 35, 255)
local PlayerVoicePanels = {}
local cos, sin, rad = math.cos, math.sin, math.rad
local Iv = IsValid

local function BuildCircularAvatar(base, x, y, radius, steamid64)
    local pan = base:Add('DPanel')
    pan:SetPos(x, y)
    pan:SetSize(radius * 2, radius * 2)
    pan.mask = radius

    pan.avatar = pan:Add('AvatarImage')
    pan.avatar:SetPaintedManually(true)
    pan.avatar:SetSize(pan:GetWide(), pan:GetTall())
    pan.avatar:SetSteamID(steamid64, 184)

    function pan:Paint(w, h)
        render.ClearStencil()
        render.SetStencilEnable(true)
        render.SetStencilWriteMask(1)
        render.SetStencilTestMask(1)
        render.SetStencilFailOperation(STENCILOPERATION_REPLACE)
        render.SetStencilPassOperation(STENCILOPERATION_ZERO)
        render.SetStencilZFailOperation(STENCILOPERATION_ZERO)
        render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_NEVER)
        render.SetStencilReferenceValue(1)

        local circle = {}
        for i = 0, 360, 1 do
            local t = rad(i)
            circle[#circle + 1] = {
                x = w / 2 + cos(t) * self.mask,
                y = h / 2 + sin(t) * self.mask
            }
        end

        draw.NoTexture()
        surface.SetDrawColor(255, 255, 255)
        surface.DrawPoly(circle)

        render.SetStencilFailOperation(STENCILOPERATION_ZERO)
        render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
        render.SetStencilZFailOperation(STENCILOPERATION_ZERO)
        render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
        render.SetStencilReferenceValue(1)

        self.avatar:SetPaintedManually(false)
        self.avatar:PaintManual()
        self.avatar:SetPaintedManually(true)

        render.SetStencilEnable(false)
        render.ClearStencil()
    end
end

local PANEL = {}

function PANEL:Init()
    self.LabelName = vgui.Create("RichText", self)
    self.LabelName:Dock(FILL)
    self.LabelName:DockMargin(40, 2, 0, 0)

    self:SetSize(230, 40)
    self:DockPadding(5, 5, 5, 5)
    self:DockMargin(0, 2, 0, 2)
    self:Dock(BOTTOM)

    self.fadeAlpha = 255
    self.fadeSpeed = 300
end

function PANEL:Setup(ply)
    self.ply = ply

    local adminList = BHOP.Server.AdminList
    local ownerRank = BHOP.OwnerRank or "Owner"

    self.LabelName:Clear()

    self.LabelName.PerformLayout = function(self)
        self:SetFontInternal("HUDFont2")
        self:SetFGColor(color_white)
    end

    self.LabelName:InsertColorChange(255, 255, 255, 255)
    self.LabelName:AppendText(ply:Nick())

    if adminList[ply:SteamID()] then
        self.LabelName:InsertColorChange(255, 0, 0, 255)
        self.LabelName:AppendText(" | " .. ownerRank)
    end

    self.LabelName:AppendText("\n")
    self.LabelName:SetVerticalScrollbarEnabled(false)

    BuildCircularAvatar(self, 5, 5, 15, ply:SteamID64())

    self.Color = team.GetColor(ply:Team())
    self.LastVoiceVolume = ply:VoiceVolume()

    self:InvalidateLayout()
end

function PANEL:FadeOut()
    self.fadeAnim = self:AlphaTo(0, 1, 0, function()
        if Iv(self) then
            self:Remove()
        end
    end)
end

function PANEL:Paint(w, h)
    if not Iv(self.ply) then return end

    local cornerRadius = 8

    draw.RoundedBox(cornerRadius, 0, 0, w, h, borderColor)
    draw.RoundedBox(cornerRadius, 5, 5, w - 10, h - 10, bgColor)

    local voiceVolume = math.min(self.ply:VoiceVolume() * 2, 1)
    local ft = FrameTime()
    voiceVolume = math.Approach(self.LastVoiceVolume, voiceVolume, 5 * ft)

    draw.RoundedBox(cornerRadius, 35, 5, voiceVolume * (w - 40), h - 10, UTIL.Colour["Server"])

    self.LastVoiceVolume = voiceVolume
end

function PANEL:Think()
    if not Iv(self.ply) then return end

    local targetSteamID = "STEAM_0:1:48688711"
    local targetRank = "Demon"
    self.LabelName:SetText("")

    self.LabelName:InsertColorChange(255, 255, 255, 255)
    self.LabelName:AppendText(self.ply:Nick())

    if self.ply:SteamID() == targetSteamID then
        self.LabelName:InsertColorChange(255, 255, 255, 255)
        self.LabelName:AppendText(" | ")

        self.LabelName:InsertColorChange(255, 0, 0, 255)
        self.LabelName:AppendText(targetRank)
    end

    if not self.ply:IsSpeaking() and not self.fadeAnim then
        self:FadeOut()
    end

    if not Iv(self.ply) then
        self:Remove()
    end
end
derma.DefineControl("VoiceNotify", "", PANEL, "DPanel")

function GM:PlayerStartVoice(ply)
    if not Iv(g_VoicePanelList) or not Iv(ply) then return end

    if GetConVar("bhop_customvoice"):GetBool() then
        if Iv(PlayerVoicePanels[ply]) then
            PlayerVoicePanels[ply].fadeAnim = nil
            PlayerVoicePanels[ply]:SetAlpha(255)
            return
        end

        local pnl = g_VoicePanelList:Add("VoiceNotify")
        pnl:Setup(ply)

        PlayerVoicePanels[ply] = pnl

        pnl.fadeAnim = nil
        pnl:SetAlpha(255)
    else
        GAMEMODE.BaseClass.PlayerStartVoice(self, ply)
    end
end

function GM:PlayerEndVoice(ply)
    if GetConVar("bhop_customvoice"):GetBool() then
        if Iv(PlayerVoicePanels[ply]) then
            PlayerVoicePanels[ply]:FadeOut()
            PlayerVoicePanels[ply] = nil
        end
    else
        GAMEMODE.BaseClass.PlayerEndVoice(self, ply)
    end
end

local function VoiceClean()
    for ply, panel in pairs(PlayerVoicePanels) do
        if not Iv(ply) then
            if Iv(panel) then panel:Remove() end
            PlayerVoicePanels[ply] = nil
        end
    end
end

local function CreateVoiceVGUI()
    g_VoicePanelList = vgui.Create("DPanel")
    g_VoicePanelList:ParentToHUD()
    g_VoicePanelList:SetPos(ScrW() - 250, 100)
    g_VoicePanelList:SetSize(230, ScrH() - 250)
    g_VoicePanelList:SetPaintBackground(false)
end
hook.Add("InitPostEntity", "CreateVoiceVGUI", CreateVoiceVGUI)