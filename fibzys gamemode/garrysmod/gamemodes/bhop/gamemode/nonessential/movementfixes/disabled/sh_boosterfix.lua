local hook_Add = hook.Add
local Iv = IsValid
local lp = LocalPlayer

-- Gravity fixes
local GravitySyncNetwork = "sync_gravity_fix"
if SERVER then
    util.AddNetworkString(GravitySyncNetwork)

    local function SyncPlayerGravity(ply)
        if not IsValid(ply) or not ply:Alive() then return end

        local clientGravity = ply:GetGravity()
        if clientGravity == 0 then return end

        local serverGravity = GetConVar("sv_gravity"):GetFloat()
        local effectiveGravity = clientGravity * serverGravity

        if ply.LastSyncedGravity ~= effectiveGravity then
            ply.LastSyncedGravity = effectiveGravity
            net.Start(GravitySyncNetwork)
                net.WriteFloat(clientGravity)
            net.Send(ply)
        end
    end

    hook_Add("Tick", "GravitySync_Think", function()
        for _, ply in ipairs(player.GetHumans()) do
            SyncPlayerGravity(ply)
        end
    end)

elseif CLIENT then
    local gravityFactor = 1

    net.Receive(GravitySyncNetwork, function()
        gravityFactor = net.ReadFloat()
        if IsValid(LocalPlayer()) then
            LocalPlayer():SetGravity(gravityFactor)
        end
    end)
end

-- Client Booster Fix Lag Fix
    local string_sub = string.sub
    local string_Explode = string.Explode
    local pairs = pairs
    local tonumber = tonumber
    local math_floor = math.floor
    local Vector = Vector
    local util_TraceHull = util.TraceHull
    local timer_Simple = timer.Simple
    local hook_Add = hook.Add
    local engine_TickInterval = engine.TickInterval
    local ents_FindByClass = ents.FindByClass
    local ents_FindByName = ents.FindByName

    local RNGFix = {
        UpdateMessage = "BoosterFix has been initialized.",
        
        -- bugged maps
        DisabledMaps = {
            ["bhop_rinnegan"] = true,
            ["bhop_p08"] = true,
            ["bhop_theory"] = true
        },

        Hooks = {
            AnalyseBoosters = "EntityKeyValue",
            PrepareBoosters = "InitPostEntity",
            DisableBoosters = "AcceptInput",
            Move = "FinishMove",
        },

        TickRate = 1 / engine_TickInterval(),
        Boosters = {},
        GravityResetDelay = 0.9, -- changeable
        LerpFactor = 0.06, -- changeable

        -- Initialize
        Initialize = function(self)
            local currentMap = game.GetMap()
            if self.DisabledMaps[currentMap] then
                return
            end

            for name, hookName in pairs(self.Hooks) do
                if self[name] then
                    hook_Add(hookName, "RNGFix"..name, function(...)
                        return self[name](self, ...)
                    end)
                else
                    print("function '"..name.."' not found.")
                end
            end
        end,

        -- Analyze it here
        AnalyseBoosters = function(self, ent, k, v)
            if ent:GetClass() == "trigger_push" then
                if k == "pushdir" then
                    local pd = string_Explode(" ", v)
                    ent.PushDir = Vector(pd[1], pd[2], pd[3])
                elseif k == "speed" then
                    ent.PushSpeed = tonumber(v)
                end
            elseif ent:GetClass() == "trigger_teleport" then
                if k == "target" then
                    ent.TeleportTarget = v
                end
            end

            -- return end here
            if ent:GetClass() ~= "trigger_multiple" and ent:GetClass() ~= "trigger_teleport" and ent:GetClass() ~= "trigger_push" then return end
            if not (k == "OnStartTouch" or k == "OnEndTouch") then return end

            local a = "!activator,AddOutput,"
            if string_sub(v, 1, #a) ~= a then return end
            local b = string_Explode(",", string_sub(v, #a + 1))
            b[1] = string_Explode(" ", b[1])
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
        end,

        -- hook boosters for gmod and others
        PrepareBoosters = function(self)
            for _, ent in pairs(ents_FindByClass("trigger_push")) do
                self.Boosters[#self.Boosters + 1] = ent
            end

            for _, ent in pairs(ents_FindByClass("trigger_teleport")) do
                self.Boosters[#self.Boosters + 1] = ent
            end

            -- overwrite boosters
            for _, ent in pairs(ents_FindByClass("trigger_multiple")) do
                local booster = ent.Booster
                if booster and #booster == 1 and booster[1].Change == "gravity" then
                    ent.Booster = nil
                elseif booster then
                    self.Boosters[#self.Boosters + 1] = ent
                end
            end
        end,

        -- disabled boosters to overwrite
        DisableBoosters = function(self, ply, input, activator, caller, arg)
            if ply:IsValid() and ply:IsPlayer() and caller.Booster then
                return true
            end
        end,

        -- apply fix
        Move = function(self, ply, mv)
            if not IsValid(ply) then return end
            if not ply:Alive() then return end
            self:BoosterFix(ply, mv)
        end,

        -- the fix
        BoosterFix = function(self, ply, mv)
            if not ply:Alive() then return end

            local pFix = ply.RNGFix or {}
            ply.RNGFix = pFix

            if pFix.NextGravity then
                local nGravity = pFix.NextGravity
                nGravity[1] = nGravity[1] - 1
                if nGravity[1] == 0 then
                    ply:SetGravity(1)
                    pFix.NextGravity = false
                end
            end

            -- only if NextVelocity
            if pFix.NextVelocity then
                local currentVelocity = mv:GetVelocity()
                local addedVelocity = pFix.NextVelocity

                -- there must be a better way to do this
                local newVelocity = currentVelocity + addedVelocity * 0.062

                DebugMsg(ply, "DO FIX: Client Booster", nil)
                RNGFix.DebugHud(ply, "DO FIX: Client Booster", Color(255, 0, 255))

                local laserStart = mv:GetOrigin()
                local laserEnd = laserStart + currentVelocity * 0.1

                RNGFix.DebugLaser(ply, laserStart, laserEnd, 15.0, 0.5, Color(255, 255, 0), "Client Booster")

                mv:SetVelocity(newVelocity)

                pFix.BoosterTime = (pFix.BoosterTime or 0) + engine.TickInterval()

                if pFix.BoosterTime >= 3 then
                    pFix.NextVelocity = false
                    pFix.BoosterTime = 0
                    return
                end

                -- lerp and trick
                pFix.NextVelocity = pFix.NextVelocity - addedVelocity * self.LerpFactor

                if pFix.NextVelocity:Length() < 2 then
                    pFix.NextVelocity = false
                    pFix.BoosterTime = 0
                end
            end

            -- needed for a reason
            for _, ent in pairs(self.Boosters) do
                if IsValid(ent) then
                    ent:SetNotSolid(false)
                end
            end

            -- trace it
            local pos = mv:GetOrigin()
            local tr = util_TraceHull({
                start = pos,
                endpos = pos,
                mask = MASK_PLAYERSOLID_BRUSHONLY,
            })
            
            local ent = tr.Entity
            if not (ent and ent:IsValid() and ent.Booster) then
                ent = false
                tr.Entity = false
            end

            local cOutput
            if ent and not pFix.InBooster then
                -- some of kind teleport fix
                cOutput = "OnStartTouch"
                if ent:GetClass() == "trigger_teleport" and ent.TeleportTarget then
                    local target = ents_FindByName(ent.TeleportTarget)[1]
                    if target and target:IsValid() then
                        ply:SetPos(target:GetPos())
                        ply:SetEyeAngles(target:GetAngles())
                    end
                end

                -- trick engine
                ply:SetGravity(0.8)

                -- put it back after thr trick at the right time
                timer_Simple(self.GravityResetDelay, function()
                    if ply:IsValid() then
                        ply:SetGravity(1)
                    end
                end)
            elseif pFix.InBooster and not ent then
                ent = pFix.InBooster
                cOutput = "OnEndTouch"
            end

            if ent and cOutput then
                for _, b in pairs(ent.Booster) do
                    if cOutput ~= b.Output then continue end
                    if b.Change == "basevelocity" then -- change it!
                        pFix.NextVelocity = b.Value
                    elseif b.Change == "gravity" then -- also change it!
                        local v = tonumber(b.Value)
                        if b.Timer > 0 then -- logic
                            pFix.NextGravity = {math_floor(b.Timer * self.TickRate), v} -- * tickrate
                        else
                            -- restore
                            ply:SetGravity(v)
                        end
                    end
                end
            end

            pFix.InBooster = tr.Entity
           
            -- needed for some reason
            for _, ent in pairs(self.Boosters) do
                if IsValid(ent) then
                    ent:SetNotSolid(true)
                end
            end
        end,
    }

    RNGFix:Initialize()