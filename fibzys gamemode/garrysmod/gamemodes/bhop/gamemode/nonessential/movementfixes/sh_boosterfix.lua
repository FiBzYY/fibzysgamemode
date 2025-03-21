-- Edited BoosterFix by DotShark
-- Works good just needs to be networked for client boosters no ping lag

-- DO TO: Make this work for client boosters recode it so when networked OnStartTouch is called then apply the Fix

local TickRate = 1 / engine.TickInterval()
local Boosters = {}

local function SetupPlayerData(ply)
    local enabled = ply.Boosterfix and ply.Boosterfix.Enabled or true
    ply.Boosterfix = {
        Enabled = enabled,
        PreviousVL = {Vector()},
        PreviousPos = Vector(),
        WasOnGround = true,
        Landing = false,
        Landed = false,
        Jumped = false,
        GroundTrace = {},
        InBooster = false,
        NoClip = false,
        Teleported = false,
        NextGravity = false,
        NextVelocity = false,
    }
end

local meta = FindMetaTable("Player")
function meta:UseBoosterfix()
    return self.Boosterfix and self.Boosterfix.Enabled
        and not self.Spectating
        and not self.Boosterfix.NoClip
        and not (self.style == 6 or self.style == 7)
        and not self:IsBot()
end

hook.Add("PlayerSpawn", "SetupData", function(ply)
    SetupPlayerData(ply)
end)

-- PrepareBoosters for hooking
hook.Add("InitPostEntity", "PrepareBoosters", function()
	for _, ent in pairs( ents.FindByClass("trigger_multiple") ) do
		local booster = ent.Booster
		if booster and #booster == 1 and booster[1].Change == "gravity" then
			ent.Booster = nil
		elseif booster then
			Boosters[#Boosters + 1] = ent
		end
	end
end)

-- Store Booster data
hook.Add("EntityKeyValue", "AnalyseBoosters", function(ent, k, v)
	if ent:GetClass() == "trigger_push" and k == "pushdir" then
		local pd = string.Explode(" ", v)
		ent.PushDir = Vector(pd[1], pd[2], pd[3])
	elseif ent:GetClass() == "trigger_push" and k == "speed" then
		ent.PushSpeed = tostring(v)
	end

	if ent:GetClass() != "trigger_multiple" then return end
	if not (k == "OnStartTouch" or k == "OnEndTouch") then return end
		
	local a = "!activator,AddOutput,"
	if string.sub(v, 1, #a) != a then return end
	local b = string.Explode( ",", string.sub(v, #a + 1) )
	b[1] = string.Explode(" ", b[1])
	b = {
		Output = k,
		Change = b[1][1],
		Value = b[1][3] and Vector(b[1][2], b[1][3], b[1][4]) or b[1][2],
		Timer = tonumber(b[2])
	}
	if not (b.Change == "basevelocity" or b.Change == "gravity") then
		return
	end

	if not ent.Booster then ent.Booster = {} end
	local booster = ent.Booster
	booster[#booster + 1] = b
end)

-- Remove all default boosters later for overwrite
hook.Add("AcceptInput", "DisableBoosters", function(ent, input, activator, caller)
    if not activator:IsPlayer() then return end

    if activator.UseBoosterfix and activator:UseBoosterfix() and caller.Booster then
        return true
    end
end)

-- Main Fix
hook.Add("SetupMove", "BoosterFix", function(ply, mv)
    if not ply.Boosterfix then
        SetupPlayerData(ply)
    end

    local pFix = ply.Boosterfix
    if not pFix then return end

    -- Handle gravity change if queued
    if pFix.NextGravity then
        local nGravity = pFix.NextGravity
        nGravity[1] = nGravity[1] - 1 -- Countdown ticks
        if nGravity[1] == 0 then
            ply:SetGravity(nGravity[2]) -- Apply gravity once timer ends
            pFix.NextGravity = false -- Clear the gravity timer
        end
    -- Handle velocity boost if queued
    elseif pFix.NextVelocity then
        local vl = mv:GetVelocity() + pFix.NextVelocity -- Add the boost to current velocity
        mv:SetVelocity(vl)
        pFix.NextVelocity = false -- Clear velocity boost after applying
    end

    -- Reactivate booster triggers for proper collision checks
    for _, ent in pairs(Boosters) do ent:SetNotSolid(false) end

    -- Setup trace parameters to detect booster zones
    local pos = mv:GetOrigin()
    local vl = mv:GetVelocity()
    pos.z = pos.z + (0.01 * vl.z) -- Small offset on Z to be more precise

    -- TraceHull to check if player is inside a booster
    local tr = util.TraceHull {
        start = pos,
        endpos = pos,
        mins = ply:OBBMins(),
        maxs = ply:OBBMaxs(),
        mask = MASK_ALL,
        filter = player.GetAll(), -- Ignore other players
        ignoreworld = true, -- Only checking for boosters/entities
    }
        
    -- Validate entity hit
    local ent = tr.Entity
    if not (ent and ent:IsValid() and ent.Booster) then
        ent = false
        tr.Entity = false
    end

    local cOutput -- Output event to fire (OnStartTouch or OnEndTouch)
    if ent and not pFix.InBooster then
        cOutput = "OnStartTouch" -- Maybe network OnStartTouch
    elseif pFix.InBooster and not ent then
        ent = pFix.InBooster
        cOutput = "OnEndTouch"
    end

    -- Check if entity passes filters if one exists
    local passesFilter
    if ent and cOutput then
        local filter = ent:GetKeyValues().filtername
        if filter and filter != "" then 
            filter = ents.FindByName(filter)[1]
            passesFilter = (not filter) or filter:PassesFilter(ent, ply)
        else
            passesFilter = true
        end
    end 

    -- Process booster logic when touching the entity
    if ent and passesFilter then
        for _, b in pairs(ent.Booster) do
            if cOutput != b.Output then continue end -- Only trigger correct event type
            -- Apply basevelocity on leaving booster
            if b.Change == "basevelocity" and b.Output == "OnEndTouch" then
                local vl = mv:GetVelocity() + b.Value
                mv:SetVelocity(vl)
            -- Queue basevelocity for next tick
            elseif b.Change == "basevelocity" then
                pFix.NextVelocity = b.Value
            -- Apply gravity modifier
            elseif b.Change == "gravity" then
                local v = tonumber(b.Value)
                -- Optional cap for certain styles
                if (v == 0 or v > 0.75) and ply.style == 8 then v = 0.75 end
                if b.Timer > 0 then
                    pFix.NextGravity = {math.floor(b.Timer * TickRate), v}
                else
                    ply:SetGravity(v)
                end
            end
        end
    end

    -- Track if inside booster
    pFix.InBooster = tr.Entity

    -- Disable booster solid after checks
    for _, ent in pairs(Boosters) do ent:SetNotSolid(true) end
end)