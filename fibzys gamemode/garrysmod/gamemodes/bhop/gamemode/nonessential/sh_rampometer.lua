--[[

     ____   __   _  _  ____   __   _  _  ____  ____  ____  ____
    (  _ \ / _\ ( \/ )(  _ \ /  \ ( \/ )(  __)(_  _)(  __)(  _ \
     )   //    \/ \/ \ ) __/(  O )/ \/ \ ) _)   )(   ) _)  )   /
    (__\_)\_/\_/\_)(_/(__)   \__/ \_)(_/(____) (__) (____)(__\_) ! by fibzy

]]--

if SERVER then
    util.AddNetworkString("RampTestingSync")

    local bhopRampConVar = CreateConVar("bhop_addon_rampometer", "1", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Enable or disable Ramp-O-Meter")

    local playerPrevPos = {}
    local playerPrevVel = {}
    local playerRampEnergy = {}
    local playerRampStartEnergy = {}
    local playerRampPostStartEnergy = {}
    local playerPrevOnRamp = {}
    local playerPrevOnRamp2 = {}

    local gravityConVar = GetConVar("sv_gravity")
    local maxVelocityConVar = GetConVar("sv_maxvelocity")

    hook.Add("PlayerInitialSpawn", "InitializePlayerData", function(ply)
        playerPrevPos[ply] = Vector()
        playerPrevVel[ply] = Vector()
        playerRampEnergy[ply] = 0
        playerRampStartEnergy[ply] = 0
        playerRampPostStartEnergy[ply] = 0
        playerPrevOnRamp[ply] = false
        playerPrevOnRamp2[ply] = false
    end)

    local function CheckVelocity(velocity)
        local maxVelocity = maxVelocityConVar:GetFloat()
        velocity[1] = math.Clamp(velocity[1], -maxVelocity, maxVelocity)
        velocity[2] = math.Clamp(velocity[2], -maxVelocity, maxVelocity)
        velocity[3] = math.Clamp(velocity[3], -maxVelocity, maxVelocity)
    end

    local function StartGravity(ply, velocity)
        local localGravity = ply:GetGravity()
        if localGravity == 0 then localGravity = 1 end

        local baseVelocity = ply:GetBaseVelocity()
        local gravityValue = 800
        local tickInterval = engine.TickInterval() * ply:GetLaggedMovementValue()

        velocity[3] = velocity[3] + (baseVelocity[3] - localGravity * gravityValue * 0.5) * tickInterval
        return velocity
    end

    local function GetEnergy(ply)
        local velocity = ply:GetVelocity()
        local position = ply:GetPos()
        local speed = velocity:Length()
        local gravity = gravityConVar:GetFloat()

        return (speed * speed) / (2 * gravity) + position[3]
    end

    hook.Add("SetupMove", "RampoMeter", function(ply, mv, cmd)
        if bhopRampConVar:GetInt() == 0 then return end
        if not IsValid(ply) or not ply:Alive() then return end

        local pos = mv:GetOrigin()
        local vel = mv:GetVelocity()
        local predictedVel = StartGravity(ply, vel)

        local isOnRamp = false
        local mins, maxs = ply:GetCollisionBounds()
        local traceData = {
            start = pos,
            endpos = pos + predictedVel * (engine.TickInterval() * ply:GetLaggedMovementValue()),
            mins = mins,
            maxs = maxs,
            filter = ply,
            mask = MASK_SOLID_BRUSHONLY
        }

        local traceResult = util.TraceHull(traceData)
        if traceResult.Hit and traceResult.HitNormal[3] < 0.7 then
            isOnRamp = true
        end

        local energy = GetEnergy(ply)

        if not playerPrevOnRamp[ply] and isOnRamp then
            playerRampStartEnergy[ply] = energy
        end

        if not playerPrevOnRamp2[ply] and playerPrevOnRamp[ply] then
            playerRampPostStartEnergy[ply] = energy
        end

        if playerPrevOnRamp[ply] and not isOnRamp then
            playerRampStartEnergy[ply] = 0
            playerRampPostStartEnergy[ply] = 0
            playerRampEnergy[ply] = 0
            ply:SetNWFloat("RampEntry", 0)
            ply:SetNWFloat("RampLoss", 0)
        end

        if isOnRamp then
            local rampEntry = (playerRampStartEnergy[ply] or 0) - (playerRampPostStartEnergy[ply] or 0)
            local rampLoss = (playerRampPostStartEnergy[ply] or 0) - (energy or 0)

            ply:SetNWFloat("RampEntry", rampEntry)
            ply:SetNWFloat("RampLoss", rampLoss)
        else
            ply:SetNWFloat("RampLoss", 0)
        end

        playerPrevPos[ply] = pos
        playerPrevVel[ply] = predictedVel
        playerPrevOnRamp2[ply] = playerPrevOnRamp[ply]
        playerPrevOnRamp[ply] = isOnRamp
    end)
end

if CLIENT then
    local hudAlpha = 0
    local fadeSpeed = 5

    local hudEnabled = CreateClientConVar("bhop_ramp_o_meter", "0", true, false, "Toggle Ramp Testing HUD")
    local showPercent = CreateClientConVar("bhop_rampometer_percent", "0", true, false, "Show Ramp Testing HUD values as percentages")

    hook.Add("HUDPaint", "RampHUD", function()
        if not hudEnabled:GetBool() then return end

        local ply = LocalPlayer()
        if not IsValid(ply) or not ply:Alive() then return end

        local rampEntry = ply:GetNWFloat("RampEntry", 0)
        local rampLoss = ply:GetNWFloat("RampLoss", 0)
        local velocity = ply:GetVelocity():Length()

        local targetAlpha = (rampEntry ~= 0 or rampLoss ~= 0) and 255 or 0
        hudAlpha = math.Approach(hudAlpha, targetAlpha, fadeSpeed)

        if hudAlpha > 0 then
            if showPercent:GetBool() then
                local rampEntryPercent = (velocity ~= 0) and (rampEntry / velocity * 100) or 0
                local rampLossPercent = (velocity ~= 0) and (rampLoss / velocity * 100) or 0

                draw.SimpleText(string.format("Ramp Entry: %.2f%%", rampEntryPercent), "HUDTimerMed", ScrW() * 0.2, ScrH() * 0.4, Color(255, 255, 255, hudAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                draw.SimpleText(string.format("Ramp Loss: %.2f%%", rampLossPercent), "HUDTimerMed", ScrW() * 0.2, ScrH() * 0.4 + 20, Color(255, 255, 255, hudAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            else
                draw.SimpleText(string.format("Ramp Entry: %.4f", rampEntry), "HUDTimerMed", ScrW() * 0.2, ScrH() * 0.4, Color(255, 255, 255, hudAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                draw.SimpleText(string.format("Ramp Loss: %.4f", rampLoss), "HUDTimerMed", ScrW() * 0.2, ScrH() * 0.4 + 20, Color(255, 255, 255, hudAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end
        end
    end)
end