Segment = Segment or {}

local ct = CurTime

CreateConVar("timer_segmentfreeze", "0.15", FCVAR_ARCHIVE, "Segmented checkpoint freeze time.")

function Segment:WaypointSetup(client)
    if not client.waypoints then 
        client.waypoints = {}
        client.lastWaypoint = 0
        client.lastTele = 0
        client.freezeDelay = GetConVar("timer_segmentfreeze"):GetFloat()
        client.wpReady = true
        client.tpTime = 0
    end
end

function Segment:Reset(client)
    client.waypoints = nil
    client.lastWaypoint = 0
end

function Segment:SetWaypoint(client)
    self:WaypointSetup(client)

    if (client.style == TIMER:GetStyleID("Segment") or client.style == TIMER:GetStyleID("TAS")) and client.time then
        table.insert(client.waypoints, {
            frame = Replay:GetFrame(client),
            pos = client:GetPos(),
            angles = client:EyeAngles(),
            vel = client:GetVelocity(),
            tick = engine.TickCount() - client.time
        })
        NETWORK:StartNetworkMessageTimer(client, "Print", {"Timer", Lang:Get("SegmentSet")})
        SendPopupNotification(client, "Notification", "Set a new checkpoint.", 2)

    end
end

function Segment:GotoWaypoint(client)
    self:WaypointSetup(client)

    if client.style ~= TIMER:GetStyleID("Segment") and client.style ~= TIMER:GetStyleID("TAS") then
        return
    end

    if #client.waypoints < 1 then
        NETWORK:StartNetworkMessageTimer(client, "Print", {"Timer", "Set a checkpoint first."})
        SendPopupNotification(client, "Notification", "Set a checkpoint first.", 2)

        return
    end

    local waypoint = client.waypoints[#client.waypoints]
    client:SetMoveType(MOVETYPE_NONE)
    client:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    client:Lock()
    client.wpReady = false
    client.tpTime = ct() + client.freezeDelay
    client.teleportWaypoint = waypoint

    local savedWaypoint = waypoint

    timer.Simple(client.freezeDelay, function()
        if not IsValid(client) then return end

        if not savedWaypoint then
            NETWORK:StartNetworkMessageTimer(client, "Print", {"Timer", "Failed to load waypoint: Invalid data."})
            return
        end

        local elapsedTicks = savedWaypoint.tick
        local waypointPos = savedWaypoint.pos
        local waypointAngles = savedWaypoint.angles
        local waypointVel = savedWaypoint.vel

        if elapsedTicks then
            client:SetPos(waypointPos)
            client:SetLocalVelocity(waypointVel)
            client:SetEyeAngles(waypointAngles)

            client.time = engine.TickCount() - elapsedTicks
            client.iFractionalTicks = 0
            client.iFullTicks = elapsedTicks

            client.finished = nil
            client.bonustime = nil
            client.bonusfinished = nil

            SendTimerUpdate(client, client.time, 0, client.iFractionalTicks)
            Replay:StripFromFrame(client, savedWaypoint.frame)

            client:SetMoveType(MOVETYPE_WALK)
            client:SetCollisionGroup(COLLISION_GROUP_PLAYER)
            client:UnLock()
            client.wpReady = true
            client.teleportWaypoint = nil
            client.lastTele = ct() + 0.5 + engine.TickInterval()
        else
            NETWORK:StartNetworkMessageTimer(client, "Print", {"Timer", "Failed to load waypoint: Invalid data."})
        end
    end)
end

function Segment:RemoveWaypoint(client)
    self:WaypointSetup(client)

    if client.style ~= TIMER:GetStyleID("Segment") and client.style ~= TIMER:GetStyleID("TAS") then return end
    if #client.waypoints < 1 then 
        NETWORK:StartNetworkMessageTimer(client, "Print", {"Timer", "Set a checkpoint first."})
        return
    end

    client.waypoints[#client.waypoints] = nil 
    NETWORK:StartNetworkMessageTimer(client, "Print", {"Timer", "Checkpoint removed."})
    self:GotoWaypoint(client)
end

function Segment:Exit(client)
    UI:SendToClient(client, "segment", true)
end

-- teleportation reset
hook.Add("SetupMove", "SegPlayerReset", function(client, data, cmd)
    if client.style ~= TIMER:GetStyleID("Segment") and client.style ~= TIMER:GetStyleID("TAS") then return end
    if client.waypoints and not client.wpReady then
        local waypoint = client.teleportWaypoint
        if ct() >= client.tpTime then
            client.time = engine.TickCount() - waypoint.tick
            client:SetMoveType(MOVETYPE_WALK)
            client:SetCollisionGroup(COLLISION_GROUP_PLAYER)
            client:UnLock()
            client.wpReady = true
            client.tpTime = 0

            NETWORK:StartNetworkMessageTimer(client, "Timer", {"Start", client.time})
        else
            client:SetMoveType(MOVETYPE_NONE)
            client:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
            client:SetEyeAngles(waypoint.angles)
            cmd:SetButtons(0)
            data:SetOrigin(waypoint.pos)
            data:SetVelocity(waypoint.vel)
        end
    end
end)

UI:AddListener("segment", function(client, data)
    local id = data[1]
    if id == "set" then 
        Segment:SetWaypoint(client)
    elseif id == "goto" then
        Segment:GotoWaypoint(client)
    elseif id == "remove" then 
        Segment:RemoveWaypoint(client)
    elseif id == "reset" then
        client.hasWarning = client.hasWarning or false
        if client.hasWarning then 
            client.hasWarning = false
            Segment:Reset(client)
            NETWORK:StartNetworkMessageTimer(client, "Print", {"Timer", "Your checkpoints have been reset."})
        else 
            client.hasWarning = true 
            NETWORK:StartNetworkMessageTimer(client, "Print", {"Timer", "Are you sure you wish to reset your checkpoints? Press again to confirm."})
            timer.Simple(3, function()
                if IsValid(client) then
                    client.hasWarning = false
                end
            end)
        end 
    end
end)

local segmentStyleID = TIMER:GetStyleID("Segment")
local tasStyleID = TIMER:GetStyleID("TAS")
local msg = "You must be in Segmented to use this command."
local msg2 = "To reopen the segment menu at any time, use this command again."

Command:Register({"segment", "segmented", "seg"}, function(client)
    if client.style ~= segmentStyleID then
        Command.Style(client, nil, {segmentStyleID})
        NETWORK:StartNetworkMessageTimer(client, "Print", {"Timer", msg2})
    end

    UI:SendToClient(client, "segment")
end)

Command:Register({"tas", "ts"}, function(client)
    if client.style ~= tasStyleID then
        Command.Style(client, nil, {tasStyleID})
        NETWORK:StartNetworkMessageTimer(client, "Print", {"Timer", msg2})
    end

    UI:SendToClient(client, "segment")
end)

Command:Register({"cpsave"}, function(client)
    if client.style == segmentStyleID then 
        Segment:SetWaypoint(client) 
    else
        NETWORK:StartNetworkMessageTimer(client, "Print", {"Timer", msg})
    end
end)

Command:Register({"cpload"}, function(client) 
    if client.style == segmentStyleID then 
        Segment:GotoWaypoint(client) 
    else
        NETWORK:StartNetworkMessageTimer(client, "Print", {"Timer", msg})
    end
end)

concommand.Add("bhop_cpsave", function(client)
    if client.style == segmentStyleID then 
        Segment:SetWaypoint(client) 
    else
        NETWORK:StartNetworkMessageTimer(client, "Print", {"Timer", msg})
    end
end)

concommand.Add("bhop_cpload", function(client)
    if client.style == segmentStyleID then 
        Segment:GotoWaypoint(client) 
    else
        NETWORK:StartNetworkMessageTimer(client, "Print", {"Timer", msg})
    end
end)

Command:Register({"segment", "segmented", "seg"}, function(client)
    if client.style ~= segmentStyleID then
        Command:RemoveLimit(client)
        Command.Style(client, nil, {segmentStyleID})
        NETWORK:StartNetworkMessageTimer(client, "Print", {"Timer", "To reopen the segment menu at any time, use this command again."})
    end

    UI:SendToClient(client, "segment")
end)

Command:Register({"cpsave"}, function(client)
    if client.style == segmentStyleID then 
        Segment:SetWaypoint(client) 
    else 
        NETWORK:StartNetworkMessageTimer(client, "Print", {"Timer", msg})
    end 
end)

Command:Register({"cpload"}, function(client) 
    if client.style == segmentStyleID then 
        Segment:GotoWaypoint(client) 
    else 
        NETWORK:StartNetworkMessageTimer(client, "Print", {"Timer", msg})
    end 
end)