-- Testing
--[[local eventQueue = {}
local lastOnGround = {}

-- Fix for trigger_multiple not working properly with activators
local function TPFix_HandleNewTriggers()
    for _, ent in ipairs(ents.FindByClass("trigger_multiple")) do
        ent:Fire("AddOutput", "OnStartTouch !activator:teleported:0:0:-1")
    end
end
hook.Add("InitPostEntity", "TPFix_HandleNewTriggers", TPFix_HandleNewTriggers)

-- Event queue system for delayed execution (adjusted for faster processing)
local function QueueEvent(ply, ent, input)
    if not IsValid(ent) or not IsValid(ply) then return end

    if not eventQueue[ply] then
        eventQueue[ply] = {}
    end

    table.insert(eventQueue[ply], {
        ent = ent,
        input = input,
        time = RealTime() + 0.01
    })
end

-- Fix button activation tracking
hook.Add("AcceptInput", "FixButtonActivator", function(ent, input, activator)
    if not IsValid(ent) or not IsValid(activator) or not activator:IsPlayer() then return end
    if input ~= "Press" and input ~= "Use" then return end

    ent.LastActivator = activator
end)

-- Fix multi-trigger spam issues
hook.Add("AcceptInput", "FixMultiTrigger", function(ent, input, activator)
    if not IsValid(ent) or not IsValid(activator) or not activator:IsPlayer() then return end
    if input ~= "Trigger" then return end

    ent.LastActivator = activator

    -- Prevent spam by setting cooldown
    ent.NextTrigger = ent.NextTrigger or 0
    if ent.NextTrigger > RealTime() then return true end
    ent.NextTrigger = RealTime() + 0.05

    QueueEvent(activator, ent, input)
end)

-- Process queued events
hook.Add("Tick", "ProcessQueuedEvents", function()
    for ply, events in pairs(eventQueue) do
        if not IsValid(ply) then
            eventQueue[ply] = nil
            continue
        end

        for i = #events, 1, -1 do
            local event = events[i]
            if event.time <= RealTime() then
                if IsValid(event.ent) then
                    event.ent:Fire(event.input, "", 0, ply)
                end
                table.remove(events, i)
            end
        end
    end
end)

-- Clean up when players disconnect
hook.Add("PlayerDisconnected", "TPFix_CleanupData", function(ply)
    eventQueue[ply] = nil
end)--]]