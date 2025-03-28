﻿local TEAM_SPECTATOR, Iv = TEAM_SPECTATOR, IsValid

local ZONE = {
    MAIN_START = 0,
    MAIN_END = 1,
    BONUS_START = 2,
    BONUS_END = 3,
    NormalAC = 4,
    BonusAC = 7, 
    AC = 6,
    RESTART = 10,
    VELOCITY = 11,
    SURFGRAVTY = 122,
    STEPSIZE = 123
}

resource.AddWorkshop("3020406990") -- Zone texture DL
resource.AddWorkshop("3444798278") -- Zone sounds DL

util.AddNetworkString("ZoneExitSound")

function ENT:Initialize()
    local BBOX = (self.max - self.min) / 2

    self:SetSolid(SOLID_BBOX)
    self:PhysicsInitBox(-BBOX, BBOX)
    self:SetCollisionBoundsWS(self.min, self.max)

    self:SetTrigger(true)
    self:DrawShadow(false)
    self:SetNotSolid(true)
    self:SetNoDraw(false)

    local phys = self:GetPhysicsObject()
    if Iv(phys) then
        phys:Sleep()
        phys:EnableCollisions(false)
    end

    if SERVER then
        self:SetNWInt("zonetype", self.zonetype)
    end
end

local function StartZoneTouch(ent, zone)
    local isJumping = ent:KeyDown(IN_JUMP)
    local isOnGround = ent:IsOnGround()
    local moveType = ent:GetMoveType()
    local style = TIMER:GetStyle(ent)

    if zone == ZONE.MAIN_START then
        ent.InStartZone = true
        ent.outsideSpawn = false

        local isPrespeed = (style == TIMER:GetStyleID("Prespeed"))

        if ent.time and (isPrespeed or not isJumping) and isOnGround then
            TIMER:ResetTimer(ent)
        elseif not ent.time and isJumping and moveType ~= MOVETYPE_NOCLIP then
            TIMER:StartTimer(ent)

            if isPrespeed and isJumping and isOnGround then
                ent:SetNWBool("inPractice", false)
            end

            if not ent:GetNWBool("inPractice") then
                net.Start("ZoneExitSound")
                net.Send(ent)
            end
        end
    elseif zone == ZONE.BONUS_START then
        ent.InStartZone = true
        ent.outsideSpawn = false

        if ent.bonustime and not isJumping and isOnGround then
            TIMER:BonusReset(ent)
        elseif not ent.bonustime and isJumping and moveType ~= MOVETYPE_NOCLIP then
            TIMER:BonusStart(ent)
            if not ent:GetNWBool("inPractice") then
                net.Start("ZoneExitSound")
                net.Send(ent)
            end
        end
    end
end

function ENT:StartTouch(ent)
    if not Iv(ent) or not ent:IsPlayer() or ent:Team() == TEAM_SPECTATOR then return end

    local zone = self:GetNWInt("zonetype")
    
    if zone == ZONE.MAIN_START or zone == ZONE.BONUS_START then
        StartZoneTouch(ent, zone)
    elseif zone == ZONE.MAIN_END and ent.time and not ent.finished then
        TIMER:StopTimer(ent)
    elseif zone == ZONE.BONUS_END and ent.bonustime and not ent.bonusfinished then
        TIMER:BonusStop(ent)
    elseif zone == ZONE.AC or zone == ZONE.NormalAC then
        TIMER:Disable(ent)
    elseif zone == ZONE.BonusAC and ent.bonustime then
        TIMER:BonusReset(ent)
    elseif zone == ZONE.STEPSIZE then
        ent:SetStepSize(16)
    elseif zone == ZONE.SURFGRAVTY then
        ent:SetGravity(0.6)
    end
end

function ENT:Touch(ent)
    if not Iv(ent) or not ent:IsPlayer() or ent:Team() == TEAM_SPECTATOR then return end
    StartZoneTouch(ent, self:GetNWInt("zonetype"))
end

function ENT:EndTouch(ent)
    if not Iv(ent) or not ent:IsPlayer() or ent:Team() == TEAM_SPECTATOR then return end

    local zone = self:GetNWInt("zonetype")

    if zone == ZONE.MAIN_START then
        JUMPTICK:HandleEndZone(ent)
        if not ent.time then
            TIMER:StartTimer(ent)
        end
    elseif zone == ZONE.BONUS_START then
        JUMPTICK:HandleEndZone(ent)
        if not ent.bonustime then
            TIMER:BonusStart(ent)
        end
    elseif zone == ZONE.MAIN_END and ent.time and not ent.finished then
        TIMER:StopTimer(ent)
    elseif zone == ZONE.BONUS_END and ent.bonustime and not ent.bonusfinished then
        TIMER:BonusStop(ent)
    elseif zone == ZONE.STEPSIZE then
         ent:SetStepSize(18)
    elseif zone == ZONE.SURFGRAVTY then
         ent:SetGravity(1)
    end

    if not ent:KeyDown(IN_JUMP) and not ent:GetNWBool("inPractice") then
        net.Start("ZoneExitSound")
        net.Send(ent)
    end
end