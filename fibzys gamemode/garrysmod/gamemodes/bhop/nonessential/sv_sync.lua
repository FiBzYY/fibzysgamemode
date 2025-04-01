--[[

 ____  ____  _  _   __  ____  __ _  ____  ____    ____  _  _  __ _   ___ 
(  _ \(  __)/ )( \ /  \(  _ \(  / )(  __)(    \  / ___)( \/ )(  ( \ / __)
 )   / ) _) \ /\ /(  O ))   / )  (  ) _)  ) D (  \___ \ )  / /    /( (__ 
(__\_)(____)(_/\_) \__/(__\_)(__\_)(____)(____/  (____/(__/  \_)__) \___) ! by fibzy

]]--

SYNC = SYNC or {}

TIMER.SyncMonitored = TIMER.SyncMonitored or {}
TIMER.SyncTick = TIMER.SyncTick or {}
TIMER.SyncA = TIMER.SyncA or {}
TIMER.SyncB = TIMER.SyncB or {}
StateArchive = StateArchive or {}

-- Cache
local Iv, mround = IsValid, math.Round 
local hook_Add, cvars_AddChangeCallback = hook.Add, cvars.AddChangeCallback

function SYNC:Monitor(ply)
    TIMER.SyncMonitored[ply] = true
    TIMER.SyncTick[ply] = 0
    TIMER.SyncA[ply] = 0
    TIMER.SyncB[ply] = 0

    ply.strafes = 0
    ply.strafesjump = 0
    ply.lastkey = 0

    TIMER.SyncAngles = TIMER.SyncAngles or {}
    TIMER.SyncAngles[ply] = ply:EyeAngles().y
end

function SYNC:ResetStatistics(ply)
    TIMER.SyncMonitored[ply] = true
    TIMER.SyncTick[ply] = 0
    TIMER.SyncA[ply] = 0
    TIMER.SyncB[ply] = 0

    ply.strafes = 0
    ply.strafesjump = 0
    ply.lastkey = 0

    TIMER.SyncAngles[ply] = ply:EyeAngles().y
end

function SYNC:RemovePlayer(ply)
    if Iv(ply) then
        TIMER.SyncMonitored[ply] = nil
        TIMER.SyncTick[ply] = nil
        TIMER.SyncA[ply] = nil
        TIMER.SyncB[ply] = nil
        if TIMER.SyncAngles then
            TIMER.SyncAngles[ply] = nil
        end
    end
end

-- Get sync stats
function SYNC:GetSync(ply, round)
    if not TIMER.SyncMonitored[ply] then
        return "N/A"
    end

    if TIMER.SyncTick[ply] == 0 then
        return 0
    end

    local result = math.floor((TIMER.SyncA[ply] / TIMER.SyncTick[ply]) * 100)
    return result
end

-- Finished Sync
function SYNC:GetFinishingSync(ply)
    if not TIMER.SyncMonitored[ply] then
        return 0
    end

    local sync = TIMER:GetSync(ply)

    if not sync or sync ~= sync then
        return 0
    end

    return sync
end

-- Network sync data
local function SendSyncData(ply)
    if not Iv(ply) then return end

    local sync = TIMER:GetSync(ply)
    local syncA = TIMER.SyncA[ply] or 0
    local syncB = TIMER.SyncB[ply] or 0

    NETWORK:StartNetworkMessage(ply, "Sync", ply, syncA, syncB, sync)

    for _, spectator in ipairs(player.GetHumans()) do
        if Iv(spectator:GetObserverTarget()) and spectator:GetObserverTarget() == ply then
            NETWORK:StartNetworkMessage(spectator, "Sync", ply, syncA, syncB, sync)
        end
    end
end

local syncInterval = (1 / engine.TickInterval())
local lastSyncTick = 0

CreateConVar("bhop_sync_interval", "100", {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "Sync interval multiplier")

cvars_AddChangeCallback("bhop_sync_interval", function(cvar, old, new)
    syncInterval = (1 / engine.TickInterval()) * (tonumber(new))
end)

-- Update for 100 tick rate
--[[hook_Add("StartCommand", "SyncDistributeThink", function(ply, cmd)
    local currentTick = cmd:TickCount()

    if currentTick == 0 then return end
    if currentTick >= lastSyncTick + syncInterval then
        lastSyncTick = currentTick

        SendSyncData(ply)

        for _, spectator in ipairs(player.GetHumans()) do
            if Iv(spectator:GetObserverTarget()) and spectator:GetObserverTarget() == ply then
                SendSyncData(ply)
            end
        end
    end
end)--]]

timer.Create("SyncDistribute", 2, 0, function()
    for _, ply in ipairs(player.GetHumans()) do
        if TIMER.SyncMonitored[ply] then
            SendSyncData(ply)
        end
    end
end)

-- Percentage
function SYNC:GetSyncPercentage(client)
    if not TIMER.SyncMonitored[client] then
        return 0
    end

    if SERVER then
        local syncTotal = TIMER.SyncTick[client] or 0
        local syncA = TIMER.SyncA[client] or 0
        local syncB = TIMER.SyncB[client] or 0

        if syncTotal == 0 then
            return 0
        end
        return math.floor(((syncA / syncTotal * 100) + (syncB / syncTotal * 100)) / 2)
    else
        return client.sync
    end
end