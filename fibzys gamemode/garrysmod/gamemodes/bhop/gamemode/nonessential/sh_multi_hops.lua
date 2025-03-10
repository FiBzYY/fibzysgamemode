local DEBUG = false

local SF_DOOR_PTOUCH = 1024
local SF_DOOR_LOCKED = 2048
local SF_DOOR_SILENT = 4096
local SF_DOOR_IGNORE_USE = 32768
local DOOR_FLAGS = bit.bor(SF_DOOR_PTOUCH, SF_DOOR_LOCKED, SF_DOOR_SILENT, SF_DOOR_IGNORE_USE)

local SF_BUTTON_DONTMOVE = 1
local SF_BUTTON_TOUCH_ACTIVATES = 256
local BUTTON_FLAGS = bit.bor(SF_BUTTON_DONTMOVE, SF_BUTTON_TOUCH_ACTIVATES)

local TELEPORT_DELAY = 2 -- 0.06
local PLATFORM_COOLDOWN = 1.10

-- Global State Variables
local gI_LastBlock = {}
local gF_PunishTime = {}
local gI_DoorState = {}

local function HookBlock(ent, isButton)
    if not IsValid(ent) then return end

    local spawnFlags = ent:GetInternalVariable("m_spawnflags") or 0
    if bit.band(spawnFlags, isButton and SF_BUTTON_TOUCH_ACTIVATES or SF_DOOR_PTOUCH) == 0 then return end

    local startPos = ent:GetInternalVariable("m_vecPosition1")
    local endPos = ent:GetInternalVariable("m_vecPosition2")
    if not startPos or not endPos then return end

    if DEBUG then
        print(string.format("[HookBlock] %s: Start: %s | End: %s", ent:GetClass(), tostring(startPos), tostring(endPos)))
    end

    if startPos[3] > endPos[3] then
        for _, tele in ipairs(ents.FindByClass("trigger_teleport")) do
            if tele:GetPos():WithinAABox(startPos, endPos) then
                gI_DoorState[ent:EntIndex()] = tele
                ent:SetNWBool("Bhop_Teleport", true)
                break
            end
        end

        ent:SetKeyValue("speed", "0")
        ent:SetSaveValue("m_vecVelocity", Vector(0, 0, 0))
        ent:SetSaveValue("m_vecAbsVelocity", Vector(0, 0, 0))

        ent:SetKeyValue("spawnflags", bit.bor(spawnFlags, isButton and BUTTON_FLAGS or DOOR_FLAGS))
        ent:Fire("Lock")
    else
        local speed = ent:GetInternalVariable("m_flSpeed") or 0
        if speed > 100 then
            gI_DoorState[ent:EntIndex()] = 1
        end
    end
end

local function Frame_HookDoor(ent)
    if IsValid(ent) then
        HookBlock(ent, false)
    end
end

local function Frame_HookButton(ent)
    if IsValid(ent) then
        HookBlock(ent, true)
    end
end

-- for doors and buttons
hook.Add("OnEntityCreated", "HookBhopDoors", function(ent)
    if not IsValid(ent) then return end
    local className = ent:GetClass()
    if className == "func_door" then
        timer.Simple(0, function() Frame_HookDoor(ent) end)
    elseif className == "func_button" then
        timer.Simple(0, function() Frame_HookButton(ent) end)
    end
end)

-- touch on func_door and func_button
hook.Add("AcceptInput", "BhopPlatformTouch", function(ent, input, activator)
    if input ~= "Open" and input ~= "Use" then return end
    if not IsValid(activator) or not activator:IsPlayer() then return end

    local entIndex = ent:EntIndex()
    if gI_DoorState[entIndex] then
        Block_Touch_Teleport(activator, entIndex)
    end
end)

-- teleport
local function Block_Touch_Teleport(ply, block)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    local time = CurTime()
    local clientID = ply:UserID()

    if DEBUG then
        print(string.format("[Bhop] %s touched block %d at %.2f", ply:Nick(), block, time))
    end

    local diff = time - (gF_PunishTime[clientID] or 0)

    if gI_LastBlock[clientID] ~= block or diff > PLATFORM_COOLDOWN then
        gI_LastBlock[clientID] = block
        gF_PunishTime[clientID] = time + TELEPORT_DELAY
    elseif diff > TELEPORT_DELAY then
        if time > (PLATFORM_COOLDOWN + TELEPORT_DELAY) then
            local tele = gI_DoorState[block]

            if IsValid(tele) then
                gI_LastBlock[clientID] = -1
                ply:SetPos(tele:GetPos() + Vector(0, 0, 5))
                ply:SetVelocity(Vector(0, 0, 0))
            end
        end
    end
end

-- MP Hops
local unduckedHull = Vector(16, 16, 62)
local duckedHull = Vector(16, 16, 45)

local function MPHops(ply)
    if not IsValid(ply) then return end

    local ent = ply:GetGroundEntity()
    if not IsValid(ent) then return end

    if ent:GetClass() == "func_door" or ent:GetClass() == "func_button" then
        local boostMultiplier = 1.3
        local playerHull = ply:Crouching() and duckedHull or unduckedHull
        local boostDelay = ply:Crouching() and 2 or 0.2

        if ent.BHSp and ent.BHSp > 100 then
            timer.Simple(boostDelay, function()
                if IsValid(ply) then
                    local vel = ply:GetVelocity()
                    vel[3] = ent.BHSp * boostMultiplier
                    ply:SetVelocity(vel)
                end
            end)
        else
            if CLIENT then
                timer.Simple(0.2, function()
                    ent:SetOwner(ply)
                    ent:SetColor(Color(255, 255, 255, 125))
                end)
                timer.Simple(0.9, function()
                    ent:SetOwner(nil)
                    ent:SetColor(Color(255, 255, 255, 255))
                end)
            else
                timer.Simple(0.2, function() ent:SetOwner(ply) end)
                timer.Simple(0.9, function() ent:SetOwner(nil) end)
            end
        end
    end
end
hook.Add("OnPlayerHitGround", "MPHops", MPHops)