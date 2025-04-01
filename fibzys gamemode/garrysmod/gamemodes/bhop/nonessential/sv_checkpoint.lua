Checkpoints = Checkpoints or {}

local ct, Iv = CurTime, IsValid

CreateConVar("timer_cpfreeze", "0.15", FCVAR_ARCHIVE, "Checkpoint freeze time.")

local function InitializePlayer(pl)
    pl.checkpoints = {}
    pl.checkpoint_current = 0
    pl.checkpoint_angles = true
    pl.freezeDelay = GetConVar("timer_cpfreeze"):GetFloat()
    pl.tpReady = true
    pl.tpTime = 0
    pl:SetNWInt("inPractice", true)
end

function Checkpoints:SetUp(pl)
    if not pl.checkpoints then
        InitializePlayer(pl)
    end

    if not pl:GetNWInt("inPractice", false) then
        BHDATA:Send(pl, "Print", { "Timer", Lang:Get("StopTimer") })
    end

    if pl.time or pl.bonustime then
        TIMER:Disable(pl)
    end
end

function Checkpoints:GetCurrent(pl)
    return pl.checkpoint_current
end

function Checkpoints:SetCurrent(pl, current)
    pl.checkpoint_current = current
end

function Checkpoints:Next(pl)
    local current = self:GetCurrent(pl)
    if not pl.checkpoints[current + 1] then return end
    self:SetCurrent(pl, current + 1)
    UI:SendToClient(pl, "checkpoints", true, current + 1, #pl.checkpoints)
end

function Checkpoints:Previous(pl)
    local current = self:GetCurrent(pl)
    if not pl.checkpoints[current - 1] then return end
    self:SetCurrent(pl, current - 1)
    UI:SendToClient(pl, "checkpoints", true, current - 1, #pl.checkpoints)
end

function Checkpoints:ReorderFrom(pl, index, method)
    if method == "add" then
        for i = #pl.checkpoints, index, -1 do
            pl.checkpoints[i + 1] = pl.checkpoints[i]
        end
    elseif method == "del" then
        local newcheckpoints = {}
        local i = 1
        for k, v in pairs(pl.checkpoints) do
            newcheckpoints[i] = v
            i = i + 1
        end
        pl.checkpoints = newcheckpoints
    end
end

function Checkpoints:Save(pl)
    self:SetUp(pl)
    local d = Iv(pl:GetObserverTarget()) and pl:GetObserverTarget() or pl
    local vel = d:GetVelocity()
    local pos = d:GetPos()
    local angles = d:EyeAngles()
    local current = self:GetCurrent(pl)

    if #pl.checkpoints > 99 then
        BHDATA:Send(pl, "Print", { "Timer", "Sorry, you are only allowed a maximum of 100 checkpoints!" })
        SendPopupNotification(pl, "Notification", "Sorry, you are only allowed a maximum of 100 checkpoints.", 2)

        return
    end

    if pl.checkpoints[current + 1] then
        self:ReorderFrom(pl, current + 1, "add")
    end

    local tickInterval = engine.TickInterval()
    local timing = ct() - (pl.time or ct()) + tickInterval

    pl.checkpoints[current + 1] = { vel, pos, angles, time = timing }
    self:SetCurrent(pl, current + 1)
    UI:SendToClient(pl, "checkpoints", true, current + 1, #pl.checkpoints)
end

function Checkpoints:Teleport(pl)
    self:SetUp(pl)
    local current = self:GetCurrent(pl)
    local data = pl.checkpoints[current]
    if not data then return end

    TIMER:Disable(pl)

    pl:SetMoveType(MOVETYPE_NONE)
    pl:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    pl:Lock()
    pl.tpReady = false
    pl.tpTime = ct() + pl.freezeDelay
    pl.teleportData = data

    timer.Simple(pl.freezeDelay, function()
        if not Iv(pl) then return end

        local teleportData = pl.teleportData
        if not teleportData then return end

        local pos, vel, angles, time = teleportData[2], teleportData[1], teleportData[3], teleportData.time
        if not pos or not vel or not angles or not time then return end

        pl:SetPos(pos)
        pl:SetLocalVelocity(vel)
        if pl.checkpoint_angles then
            pl:SetEyeAngles(angles)
        end

        pl.time = nil
        pl.finished = nil
        pl.bonustime = nil
        pl.bonusfinished = nil
        pl:SetNWBool("inPractice", true)
        
        pl:SetMoveType(MOVETYPE_WALK)
        pl:SetCollisionGroup(COLLISION_GROUP_PLAYER)
        pl:UnLock()
        pl.tpReady = true
        pl.teleportData = nil
    end)
end

hook.Add("SetupMove", "CheckpointsPlayerReset", function(pl, data, cmd)
    if pl.tpReady then return end
    local teleportData = pl.teleportData
    if not teleportData then
        return
    end

    if ct() >= pl.tpTime then
        pl:SetMoveType(MOVETYPE_WALK)
        pl:SetCollisionGroup(COLLISION_GROUP_PLAYER)
        pl:UnLock()
        pl.tpReady = true
        pl.tpTime = 0

        BHDATA:Send(pl, "Timer", { "Start", pl.time })
    else
        pl:SetMoveType(MOVETYPE_NONE)
        pl:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
        pl:SetEyeAngles(teleportData[3])
        cmd:SetButtons(0)
        data:SetOrigin(teleportData[2])
        data:SetVelocity(teleportData[1])
    end
end)

function Checkpoints:Reset(pl)
    self:SetUp(pl)
    self:SetCurrent(pl, 0)
    pl.checkpoints = {}
    UI:SendToClient(pl, "checkpoints", true, false)
end

function Checkpoints:Delete(pl)
    self:SetUp(pl)
    if #pl.checkpoints < 1 then return end
    if #pl.checkpoints == 1 then return self:Reset(pl) end

    local current = self:GetCurrent(pl)
    pl.checkpoints[current] = nil
    self:ReorderFrom(pl, current, "del")

    if current ~= 1 and not pl.checkpoints[current - 1] then
        self:SetCurrent(pl, current + 1)
    elseif current ~= 1 then
        self:SetCurrent(pl, current - 1)
    end

    UI:SendToClient(pl, "checkpoints", true, self:GetCurrent(pl), #pl.checkpoints)
end

local function CheckpointOpen(pl, args)
    UI:SendToClient(pl, "checkpoints")
    pl:SetNWInt("inPractice", true)

    if pl.checkpoints then
        UI:SendToClient(pl, "checkpoints", true, Checkpoints:GetCurrent(pl), #pl.checkpoints)
    end

    if pl.time or pl.bonustime or not pl:GetNWInt("inPractice", false) then
        BHDATA:Send(pl, "Print", { "Timer", Lang:Get("DacTimer") })
    end
end

Command:Register({ "cp", "checkpoints", "cps" }, CheckpointOpen)

UI:AddListener("checkpoints", function(client, data)
    local id = data[1]
    if id == "save" then
        Checkpoints:Save(client)
    elseif id == "tp" then
        Checkpoints:Teleport(client)
    elseif id == "next" then
        Checkpoints:Next(client)
    elseif id == "prev" then
        Checkpoints:Previous(client)
    elseif id == "del" then
        Checkpoints:Delete(client)
    elseif id == "reset" then
        Checkpoints:Reset(client)
    elseif id == "angles" then
        Checkpoints:SetUp(client)
        client.checkpoint_angles = not client.checkpoint_angles
        UI:SendToClient(client, "checkpoints", "angles", client.checkpoint_angles)
    end
end)

concommand.Add("bhop_checkpoint_save", function(cl) Checkpoints:Save(cl) end)
concommand.Add("bhop_checkpoint_tele", function(cl) Checkpoints:Teleport(cl) end)
concommand.Add("bhop_checkpoint_next", function(cl) Checkpoints:Next(cl) end)
concommand.Add("bhop_checkpoint_prev", function(cl) Checkpoints:Previous(cl) end)
concommand.Add("bhop_checkpoint_del", function(cl) Checkpoints:Delete(cl) end)
concommand.Add("bhop_checkpoint_reset", function(cl) Checkpoints:Reset(cl) end)