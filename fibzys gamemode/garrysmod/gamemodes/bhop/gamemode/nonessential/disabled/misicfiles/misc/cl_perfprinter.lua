local gB_OnGround = {}
local gB_Jumped = {}
local gI_LandingTick = {}
local jumpTrackerCVar = CreateClientConVar("bhop_perfprinter", "0", true, false, "Toggle the Jump Tracker for scrolling")

hook.Add("PlayerButtonDown", "PlayerJumpHook", function(ply, button)
    if not GetConVar("bhop_perfprinter"):GetBool() then return end

    if (button == KEY_SPACE or button == KEY_MWHEELUP or button == KEY_MWHEELDOWN) and ply:Alive() and not ply:IsBot() then
        gB_Jumped[ply] = true
    end
end)

local function StartCommand(ply, cmd)
    if not GetConVar("bhop_perfprinter"):GetBool() then return end

    if not ply:IsValid() or not ply:Alive() then return end
    local bOnGround = ply:IsOnGround()
    if cmd:TickCount() == 0 then return end

    if bOnGround and not gB_OnGround[ply] then
        gI_LandingTick[ply] = cmd:TickCount()
    elseif not bOnGround and gB_OnGround[ply] and gB_Jumped[ply] then
        local iDifference = cmd:TickCount() - (gI_LandingTick[ply] or 0)

        if iDifference < 10 then
            UTIL:AddMessage("Timer", "Jump tick difference = " .. iDifference .. (iDifference == 1 and " (perf!)" or ""))
        end
    end

    gB_Jumped[ply] = false
    gB_OnGround[ply] = bOnGround
end
hook.Add("StartCommand", "OnStartCommandPlayerMovement", StartCommand)