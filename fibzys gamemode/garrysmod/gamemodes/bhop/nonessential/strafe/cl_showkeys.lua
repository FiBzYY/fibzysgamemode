--[[

 ____  _  _   __   _  _  __ _  ____  _  _  ____ 
/ ___)/ )( \ /  \ / )( \(  / )(  __)( \/ )/ ___)
\___ \) __ ((  O )\ /\ / )  (  ) _)  )  / \___ \
(____/\_)(_/ \__/ (_/\_)(__\_)(____)(__/  (____/ !

]]--

local Iv = IsValid
local hook_Add = hook.Add
local ba = bit.band

local MIN_UPDATE_RATE = 50
local TURNDIR_RIGHT = -1
local TURNDIR_NONE = 0
local TURNDIR_LEFT = 1

local g_iCmdNum = {}
local g_iLastTurnDir = {}
local g_iLastButtons = {}
local g_fLastYaw = {}
local g_bUpdateDelayed = {}
local g_iTickDelay = 3
local playerHUDText = {}

local lastHUDUpdate = 0
local HUD_UPDATE_INTERVAL = 0.01

local showKeysCVar = CreateClientConVar("bhop_showkeys", "0", true, false, "Toggle the ShowKeys HUD (1 to enable, 0 to disable)")

local ShowKeys_Send

local function ShowKeys_Start()
    g_iTickDelay = math.floor(1 / engine.TickInterval() * 0.03)
end

local function ShowKeys_Tick(ply, buttons, yaw)
    if not g_iCmdNum[ply] then
        g_iCmdNum[ply] = 0
        g_iLastTurnDir[ply] = TURNDIR_NONE
        g_iLastButtons[ply] = 0
        g_fLastYaw[ply] = yaw
        g_bUpdateDelayed[ply] = false
    end

    g_iCmdNum[ply] = g_iCmdNum[ply] + 1

    local yawDiff = math.NormalizeAngle(yaw - g_fLastYaw[ply])
    local turnDir = TURNDIR_NONE
    if yawDiff > 0 then
        turnDir = TURNDIR_LEFT
    elseif yawDiff < 0 then
        turnDir = TURNDIR_RIGHT
    end

    local updateThisTick = false

    if g_bUpdateDelayed[ply] or turnDir ~= g_iLastTurnDir[ply] or buttons ~= g_iLastButtons[ply] or g_iCmdNum[ply] % MIN_UPDATE_RATE == 0 then
        updateThisTick = true
    end

    if updateThisTick and g_iCmdNum[ply] < g_iTickDelay then
        g_bUpdateDelayed[ply] = true
        updateThisTick = false
    end

    g_fLastYaw[ply] = yaw
    g_iLastButtons[ply] = buttons
    g_iLastTurnDir[ply] = turnDir

    ShowKeys_Send(ply, buttons, yawDiff)

    g_bUpdateDelayed[ply] = false
    g_iCmdNum[ply] = 0
end

ShowKeys_Send = function(ply, buttons, yawDiff)
    local message = string.format("　  %s　　%s\n      %s    \n  %s%s　 %s 　%s%s\n　  %s　　%s",
        (ba(buttons, IN_JUMP) > 0) and "J" or " ",
        (ba(buttons, IN_DUCK) > 0) and "C" or " ",
        (ba(buttons, IN_FORWARD) > 0) and "W" or "  ",
        (yawDiff > 0) and "<" or "  ",
        (ba(buttons, IN_MOVELEFT) > 0) and "A" or " ",
        (ba(buttons, IN_BACK) > 0) and "S" or " ",
        (ba(buttons, IN_MOVERIGHT) > 0) and "D" or " ",
        (yawDiff < 0) and ">" or "  ",
        (ba(buttons, IN_LEFT) > 0) and "L" or " ",
        (ba(buttons, IN_RIGHT) > 0) and "R" or " ")

    playerHUDText[ply] = message
end

hook_Add("StartCommand", "ShowKeys_StartCommand", function(ply, cmd)
    ShowKeys_Tick(ply, cmd:GetButtons(), cmd:GetViewAngles().yaw)
end)

hook_Add("HUDPaint", "ShowKeys_DrawHUD", function()
    if not GetConVar("bhop_showkeys"):GetBool() then return end

    local client = LocalPlayer()
    if not client:IsValid() then return end

    local message = playerHUDText[client]

    if message then
        surface.SetFont("HUDFont")

        local textWidth, textHeight = surface.GetTextSize(message)
        draw.DrawText(message, "HUDFont", ScrW() / 2 - 0.7, ScrH() / 2 - textHeight / 1.6, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
    end
end)

ShowKeys_Start()