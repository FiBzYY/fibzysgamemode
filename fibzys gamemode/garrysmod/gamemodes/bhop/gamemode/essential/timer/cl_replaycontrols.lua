-- DO TO:

local BOT_SPEED, BOT_STATUS, BOT_TIME, BOT_SKIP = 1, 2, 3, 4
local replaycontrols = false
local currentbot = false 
local skipstep = 10

local play_ico = Material("bhop/replay_controls/play.png", "smooth")
local pause_ico = Material("bhop/replay_controls/pause.png", "smooth")
local forward_ico = Material("bhop/replay_controls/forward.png", "smooth")
local rewind_ico = Material("bhop/replay_controls/rewind.png", "smooth")
local step_ico = Material("bhop/replay_controls/step.png", "smooth")
local back_ico = Material("bhop/replay_controls/back.png", "smooth")

-- velocity
local function ChangeSpeed(direction)
    NETWORK:StartNetworkMessage(false, "botcontrols", currentbot.uid, BOT_SPEED, direction)
end

-- play pause
local function ChangeStatus()
    NETWORK:StartNetworkMessage(false, "botcontrols", currentbot.uid, BOT_STATUS)
end

-- set Replay time current frame
local function SetTime(time)
    NETWORK:StartNetworkMessage(false, "botcontrols", currentbot.uid, BOT_TIME, time)
end

-- skip frame
local function SkipFrame(direction)
    NETWORK:StartNetworkMessage(false, "botcontrols", currentbot.uid, BOT_SKIP, direction and skipstep or -skipstep)
end

local width, height = (24 * 5) + 40 + 100, 30 + 30
local icon_height = 24
local trueheight = height + icon_height + 20 + 10 + 25 + 10
local function Refresh()
    if not replaycontrols and not IsValid(replaycontrols) then return end

    if currentbot then
        replaycontrols.playpause:SetIcon(currentbot.status and play_ico or pause_ico)
        replaycontrols:SetTall(trueheight)

        replaycontrols.playpause:SetVisible(true)
        replaycontrols.forward:SetVisible(true)
        replaycontrols.rewind:SetVisible(true)
        replaycontrols.step:SetVisible(true)
        replaycontrols.back:SetVisible(true)
        replaycontrols.frameskip:SetVisible(true)
        replaycontrols.settime:SetVisible(true)

        replaycontrols.settime.opt.max = math.Round(currentbot.pb, 3)
        replaycontrols.settime.opt:SetMax(math.Round(currentbot.pb, 3))
    else
        replaycontrols:SetTall(height)

        replaycontrols.playpause:SetVisible(false)
        replaycontrols.forward:SetVisible(false)
        replaycontrols.rewind:SetVisible(false)
        replaycontrols.step:SetVisible(false)
        replaycontrols.back:SetVisible(false)
        replaycontrols.frameskip:SetVisible(false)
        replaycontrols.settime:SetVisible(false)
    end
end

NETWORK:GetNetworkMessage("botcontrols_response", function(server, data)
    Refresh()
end)

local function BuildSideOption(parent, x, y, default, min, max, title, unit, disable, dec, callback)
    local w = width - 20   
    local h = 30 

    local base = vgui.Create("DPanel", parent)
    base:SetPos(x, y + 30)
    base:SetSize(w, h)
    base.Paint = function(self, width, height)
        surface.SetDrawColor(UI_SECONDARY)
        surface.DrawRect(0, 0, 80, height)
        draw.SimpleText(title, "ui.mainmenu.button", 10, height / 2, UI_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end 

    base.opt = UI:NumberInput(base, 80, 0, w - 80, h, default, min, max, unit, dec, callback, disable)
    return base 
end 

local pl
local function BuildReplayControls()
    pl = LocalPlayer()

    if replaycontrols then 
        replaycontrols:Remove()
        replaycontrols = false 

        return 
    end 

    local scrw, scrh = ScrW(), ScrH()
    replaycontrols = UI:BasePanel(width, trueheight, scrw - width - 20, 20, false, true, "DFrame")
    replaycontrols:ShowCloseButton(false)
    replaycontrols:SetTitle("")
    replaycontrols.x = scrw - width - 20
    replaycontrols.y = 20
    replaycontrols:MakePopup()

    function replaycontrols:OnExit()
        replaycontrols = false  
    end 

    UI:DrawBanner(replaycontrols, "Replay controls")
    UI:AddCloseButton(replaycontrols)

    replaycontrols.frameskip = BuildSideOption(replaycontrols, 10, 10, skipstep, 1, 100, "Set step", "frames", true, false, function(var)
        skipstep = var 
        UTIL:AddMessage("Admin", "The Replay will now skip in ", tostring(var), " frame intervals.")
    end)   

    replaycontrols.settime = BuildSideOption(replaycontrols, 10, 10 + 30 + 5, 0.001, 0.1, 99999, "Set time", "seconds", true, true, function(var)
        SetTime(var)
    end)   

    local y = 10 + 30 + 5 + 30 + 10 + 30
    replaycontrols.playpause = replaycontrols:Add("control_button")
    replaycontrols.playpause:SetPos(50 + (24*2) + 20, y)
    replaycontrols.playpause:SetIcon(play_ico)
    replaycontrols.playpause.OnMousePressed = function(self)
        ChangeStatus()
    end
    
    replaycontrols.forward = replaycontrols:Add("control_button")
    replaycontrols.forward:SetPos(50 + (24 * 4) + 40, y)
    replaycontrols.forward:SetIcon(forward_ico)
    replaycontrols.forward.OnMousePressed = function(self)
        ChangeSpeed(1)
    end 

    replaycontrols.rewind = replaycontrols:Add("control_button")
    replaycontrols.rewind:SetPos(50, y)
    replaycontrols.rewind:SetIcon(rewind_ico)
    replaycontrols.rewind.OnMousePressed = function(self)
        ChangeSpeed(-1)
    end 

    replaycontrols.step = replaycontrols:Add("control_button")
    replaycontrols.step:SetPos(50 + (24 * 3) + 30, y)
    replaycontrols.step:SetIcon(step_ico)
    replaycontrols.step.OnMousePressed = function(self)
        SkipFrame(true)
    end 

    replaycontrols.back = replaycontrols:Add("control_button")
    replaycontrols.back:SetPos(50+24+10, y)
    replaycontrols.back:SetIcon(back_ico)
    replaycontrols.back.OnMousePressed = function(self)
        SkipFrame(false)
    end 

    replaycontrols.Think = function(self)
        local current = currentbot 

        if IsValid(pl) and IsValid(pl:GetObserverTarget()) and pl:GetObserverTarget():IsBot() then 
            currentbot = pl:GetObserverTarget()
        else 
            currentbot = false 
        end 

        if current ~= currentbot then 
            Refresh()
        end 
    end 

    replaycontrols.CPaint = function(self, w, h)
        if not currentbot then 
            draw.SimpleText("Not spectating a Replay.", "ui.mainmenu.button", w / 2, 30 + ((h - 30) / 2), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end 

    Refresh()
end 

local buttons = {}
function buttons:Init()
    self:SetSize(24, 24)
    self:SetText("")
end 

function buttons:SetIcon(ico)
    self.ico = ico 
end 

function buttons:Paint(w, h)
    if not self.ico then return end 
    
    surface.SetDrawColor(255, 255, 255)
    draw.NoTexture()
    surface.SetMaterial(self.ico)
    surface.DrawTexturedRect(0, 0, w, h)
end 
vgui.Register("control_button", buttons, "DButton")

NETWORK:GetNetworkMessage("botcontrols_menu", function()
    BuildReplayControls()
end)

--[[local function TestBotLanding(client, data)
    client = client:GetObserverTarget()
	if not IsValid(client) or not client:IsBot() then return end 
	if not client:IsOnGround() and client.hitground then
		client.hitground = false
	end

	if client:IsOnGround() and (not client.hitground) then 
		client.hitground = true 
        UTIL:AddMessage("Server", "Hit ground ", tostring(client:GetVelocity():Length2D()))
	end
end 
hook.Add("SetupMove", "TestBotLanding", TestBotLanding)--]]