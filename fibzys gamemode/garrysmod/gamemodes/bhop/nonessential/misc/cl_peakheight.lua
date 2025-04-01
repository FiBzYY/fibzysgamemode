local showPeakHeightCVar = CreateClientConVar("bhop_showpeakheight", "0", true, false, "Toggle peak height display")

local prevHeight = {}
local groundHeight = {}
local peakReached = {}

hook.Add("StartCommand", "TrackPlayerHeight_Client", function(ply, cmd)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end

    if CLIENT and ply == LocalPlayer() then
        local pos = ply:GetPos()
        local vel = ply:GetVelocity().z

        if ply:IsOnGround() then
            prevHeight[ply] = -99999999
            groundHeight[ply] = pos.z
            peakReached[ply] = false
            return
        end

        local height = pos.z - (groundHeight[ply] or 0)

        if vel > 0 then
            prevHeight[ply] = height
        elseif vel < 0 and not peakReached[ply] then
            PeakReached_Client(prevHeight[ply] or 0)
            peakReached[ply] = true
        end
    end
end)

function PeakReached_Client(height)
    if showPeakHeightCVar:GetBool() then
        UTIL:AddMessage("Timer", string.format("Peak height: %.2f", height))
    end
end