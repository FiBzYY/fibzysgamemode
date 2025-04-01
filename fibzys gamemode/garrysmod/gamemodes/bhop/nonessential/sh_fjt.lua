-- FJT --

if SERVER then
    util.AddNetworkString("JumpTickMessage")
end

JUMPTICK = JUMPTICK or {}

CreateClientConVar("bhop_fjt", "1", true, false, "Toggle Jump Tick", 0, 1)

if SERVER then
    util.AddNetworkString("RequestFJTStatus")
    util.AddNetworkString("SendFJTStatus")

    net.Receive("RequestFJTStatus", function(len, ply)
        local status = net.ReadInt(2)
        ply.bhop_fjt_enabled = (status == 1)
    end)

    hook.Add("PlayerInitialSpawn", "RequestFJTOnSpawn", function(ply)
        timer.Simple(1, function()
            if IsValid(ply) then
                net.Start("SendFJTStatus")
                net.Send(ply)
            end
        end)
    end)
end

if CLIENT then
    cvars.AddChangeCallback("bhop_fjt", function(convar_name, oldValue, newValue)
        net.Start("RequestFJTStatus")
        net.WriteInt(tonumber(newValue), 2)
        net.SendToServer()
    end)

    net.Receive("SendFJTStatus", function()
        net.Start("RequestFJTStatus")
        net.WriteInt(GetConVar("bhop_fjt"):GetInt(), 2)
        net.SendToServer()
    end)
end

local playerLeftZone = {}
local playerJumpedInsideZone = {}
local playerFJT = {}
local tickcount = {}

hook.Add("KeyPress", "FJT_DetectJump", function(ply, key)
    if key == IN_JUMP and ply:IsOnGround() then
        if ply.InStartZone then
            playerJumpedInsideZone[ply] = true

            tickcount[ply] = engine.TickCount()
        elseif playerLeftZone[ply] and tickcount[ply] and not playerFJT[ply] then
            local currentTick = engine.TickCount()
            local jumpTick = (currentTick - tickcount[ply]) + 1

            if jumpTick > 150 then return end

            playerFJT[ply] = jumpTick

            local ColorSSJ = ply.DynamicColor or Color(255, 255, 255)
            local str = {ColorSSJ, color_white}
            str[#str + 1] = "FJT: "
            str[#str + 1] = ColorSSJ
            str[#str + 1] = tostring(jumpTick)
            str[#str + 1] = color_white

            net.Start("JumpTickMessage")
            net.WriteInt(jumpTick, 16)
            net.Send(ply)
            if not ply.bhop_fjt_enabled then return end

            NETWORK:StartNetworkMessageTimer(ply, "Print", {"Timer", str})
        end
    end
end)

function JUMPTICK:HandleStartZone(ply)
    playerLeftZone[ply] = false
    playerJumpedInsideZone[ply] = false
    playerFJT[ply] = nil

    tickcount[ply] = engine.TickCount()

    ply.InStartZone = true
end

function JUMPTICK:HandleEndZone(ply)
    ply.InStartZone = false
    playerLeftZone[ply] = true

    local currentTick = engine.TickCount()

    if playerJumpedInsideZone[ply] and tickcount[ply] then
       local negativeTick = -(currentTick - (tickcount[ply] or currentTick))

        -- Ignore absurd negative values
        if math.abs(negativeTick) > 150 then return end

        playerFJT[ply] = negativeTick

        local ColorSSJ = ply.DynamicColor or Color(255, 255, 255)
        local str = {ColorSSJ, color_white}
        str[#str + 1] = "FJT: "
        str[#str + 1] = ColorSSJ
        str[#str + 1] = tostring(negativeTick)
        str[#str + 1] = color_white

        net.Start("JumpTickMessage")
        net.WriteInt(negativeTick, 16)
        net.Send(ply)

        if not ply.bhop_fjt_enabled then return end
        NETWORK:StartNetworkMessageTimer(ply, "Print", {"Timer", str})
    end

    tickcount[ply] = currentTick
    playerFJT[ply] = nil
    playerJumpedInsideZone[ply] = false
end

-- Display
if CLIENT then
    CreateClientConVar("bhop_showfjthud", "1", true, false, "Toggle Jump Tick HUD", 0, 1)

    cvars.AddChangeCallback("bhop_fjt", function(convar_name, oldValue, newValue)
        net.Start("RequestFJTStatus")
        net.WriteInt(tonumber(newValue), 2)
        net.SendToServer()
    end)

    net.Receive("SendFJTStatus", function()
        net.Start("RequestFJTStatus")
        net.WriteInt(GetConVar("bhop_fjt"):GetInt(), 2)
        net.SendToServer()
    end)

    local jumpTickValue = 0
    local lastUpdateTime = 0
    local displayDuration = 0.5
    local fadeDuration = 0.2

    net.Receive("JumpTickMessage", function()
        jumpTickValue = net.ReadInt(16)
        lastUpdateTime = CurTime()
    end)

    hook.Add("HUDPaint", "DrawJumpTickHUD", function()
        if not GetConVar("bhop_showfjthud"):GetBool() then return end

        local timeSinceUpdate = CurTime() - lastUpdateTime
        if timeSinceUpdate > (displayDuration + fadeDuration) then return end

        local alpha = 255
        if timeSinceUpdate > displayDuration then
            alpha = math.max(0, 255 - ((timeSinceUpdate - displayDuration) / fadeDuration) * 255)
        end

        draw.SimpleText("FJT: @" .. tostring(jumpTickValue), "JHUDMainBIG2", ScrW() / 2, ScrH() / 2 - 60, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end)
end