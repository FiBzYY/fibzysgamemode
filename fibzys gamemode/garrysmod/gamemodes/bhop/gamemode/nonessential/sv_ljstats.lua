-- LJ Stats
util.AddNetworkString("LJStats")

local JUMP_LJ = 1
local JUMP_DROP = 2
local JUMP_UP = 3
local JUMP_LADDER = 4
local JUMP_WJ = 5
local MAX_STRAFES = 50

-- Types
local jumptypes = {
    [JUMP_LJ] = "LongJump",
    [JUMP_DROP] = "DropJump",
    [JUMP_UP] = "UpJump",
    [JUMP_LADDER] = "LadderJump",
    [JUMP_WJ] = "WeirdJump"
}

-- Distance
local jumpdist = {
    [JUMP_LJ] = 230,
    [JUMP_DROP] = 235,
    [JUMP_UP] = 200,
    [JUMP_LADDER] = 110,
    [JUMP_WJ] = 255
}

-- Cache
local wj, inbhop, strafes, ducking, lastducking = {}, {}, {}, {}, {}
local didjump, strafenum, strafingright, strafingleft = {}, {}, {}, {}
local speed, lastspeed, newp, oldp = {}, {}, {}, {}
local lastent, lastonground, jumpproblem, jumppos = {}, {}, {}, {}
local tproblem, jumptype, ladder, strafe = {}, {}, {}, {}
local difference = 17

hook.Add("PlayerInitialSpawn", "LJCollisionCheck", function(p)
    p:SetCustomCollisionCheck(true)
end)

hook.Add("SetupMove", "LJStats", function(p, data)
    if not p.ljen then return end
    local b = data:GetButtons()

    if not p:IsOnGround() and didjump[p] and not inbhop[p] then
        if p:Crouching() then
            ducking[p] = true
        end

        local dontrun = false
        strafe[p] = strafe[p] or {}

        local c = 0
        if bit.band(b, IN_MOVELEFT) > 0 then c = c + 1 end
        if bit.band(b, IN_MOVERIGHT) > 0 then c = c + 1 end

        if c == 1 and ((strafenum[p] and strafenum[p] < MAX_STRAFES) or not strafenum[p]) then
            if strafenum[p] and bit.band(b, IN_MOVELEFT) > 0 and (strafingright[p] or (not strafingright[p] and not strafingleft[p])) then
                strafingright[p] = false
                strafingleft[p] = true
                strafenum[p] = strafenum[p] + 1
                strafe[p][strafenum[p]] = {0, 0}
            elseif strafenum[p] and bit.band(b, IN_MOVERIGHT) > 0 and (strafingleft[p] or (not strafingright[p] and not strafingleft[p])) then
                strafingright[p] = true
                strafingleft[p] = false
                strafenum[p] = strafenum[p] + 1
                strafe[p][strafenum[p]] = {0, 0}
            end
        elseif strafenum[p] and strafenum[p] == 0 then
            dontrun = true
        end

        if not strafenum[p] then
            dontrun = true
        end

        if not dontrun then
            speed[p] = data:GetVelocity()
            newp[p] = data:GetOrigin()

            if lastspeed[p] then
                local g = speed[p]:Length2D() - lastspeed[p]:Length2D()
                if g > 0 then
                    strafe[p][strafenum[p]][1] = strafe[p][strafenum[p]][1] + 1
                else
                    strafe[p][strafenum[p]][2] = strafe[p][strafenum[p]][2] + 1
                end

                strafe[p][strafenum[p]][3] = speed[p]

                local cp, op = newp[p], oldp[p]
                if lastducking[p] and not p:Crouching() then
                    op.z = op.z - difference
                elseif not lastducking[p] and p:Crouching() then
                    cp.z = cp.z - difference
                end

                lastducking[p] = p:Crouching()

                if (cp - op):Length2D() > (lastspeed[p]:Length2D() / 100 + 3) then
                    tproblem[p] = true
                end
            end

            oldp[p] = newp[p]
            lastspeed[p] = speed[p]
        elseif strafenum[p] and strafenum[p] ~= 0 then
            strafe[p][strafenum[p]][2] = strafe[p][strafenum[p]][2] + 1
        end
    end

    if p:GetMoveType() == MOVETYPE_LADDER then
        jumptype[p] = JUMP_LADDER
        ladder[p] = true
    else
        if ladder[p] then
            ladder[p] = false
            didjump[p] = true
            inbhop[p] = false
            jumppos[p] = data:GetOrigin()
            timer.Simple(0.2, function()
                jumpproblem[p] = false
                lastent[p] = nil
            end)
        end
    end

    if p:IsOnGround() and not lastonground[p] then
        OnLand(p, data:GetOrigin())
    end

    lastonground[p] = p:IsOnGround()

    if bit.band(b, IN_JUMP) > 0 and p:IsOnGround() then
        if wj[p] then
            jumptype[p] = JUMP_WJ
            inbhop[p] = false
        end
        timer.Simple(0.2, function()
            didjump[p] = true
            lastent[p] = nil
        end)
        jumppos[p] = data:GetOrigin()
    end
end)

hook.Add("ShouldCollide", "LJWorldCollide", function(ent1, ent2)
    if ent1:IsPlayer() and ent2:IsPlayer() then return false end

    local p = ent1:IsPlayer() and ent1 or ent2
    local o = ent1:IsPlayer() and ent2 or ent1

    if not p.ljen then return end
    lastent[p] = lastent[p] or nil

    if didjump[p] and o ~= lastent[p] then
        timer.Simple(1, function()
            if not IsValid(p) then return end

            if not p:IsOnGround() and not inbhop[p] and didjump[p] then
                local t = util.QuickTrace(p:GetPos() + Vector(0, 0, 2), Vector(0, 0, -34), {p})
                if not t.Hit then
                    jumpproblem[p] = true
                elseif t.HitPos and p:GetPos().z - t.HitPos.z <= 0.2 then
                    jumpproblem[p] = true
                end
            end
        end)
    end

    lastent[p] = o
end)

function OnLand(p, jpos)
    local good, bad, sync, i = 0, 0, 0, 0
    local totalstats = {sync = {}, speed = {}}

    for k, v in pairs(strafe[p] or {}) do
        if type(v) == "table" then
            local sync = math.Round((v[1] * 100) / (v[1] + v[2]))
            if sync and sync ~= 0 and sync <= 100 then
                i = i + 1
                totalstats.sync[i] = sync
                totalstats.speed[i] = math.Round((v[3] or Vector(0, 0, 0)):Length2D())
                good = good + v[1]
                bad = bad + v[2]
            end
        end
    end

    local straf = strafenum[p]
    local validlj = false
    local jt = jumptype[p]
    local dist = 0

    if jumppos[p] then
        local cz = jpos.z
        if cz - jumppos[p].z > -1 and cz - jumppos[p].z < 1 then
            cz = jumppos[p].z
        end

        if jt and jt ~= JUMP_WJ and cz < jumppos[p].z then
            if jt ~= JUMP_LADDER then
                jt = JUMP_DROP
                validlj = true
            else
                validlj = true
                if jumppos[p].z - cz > 20 then
                    validlj = false
                end
            end
        elseif jt and jt ~= JUMP_WJ and cz > jumppos[p].z then
            if jt ~= JUMP_LADDER then
                jt = JUMP_UP
                validlj = true
            else
                validlj = true
                if jumppos[p].z - cz < -20 then
                    validlj = false
                end
            end
        elseif jt then
            if jt == JUMP_WJ and cz == jumppos[p].z then
                validlj = true
            elseif jt ~= JUMP_WJ then
                validlj = true
            end
        end

        dist = (jpos - jumppos[p]):Length2D()
        if jt ~= JUMP_LADDER then
            dist = dist + 30
        end
    end

    local dj = didjump[p]
    if jumpproblem[p] or tproblem[p] then
        validlj = false
    end

    timer.Simple(0.3, function()
        if IsValid(p) and p:IsOnGround() then
            inbhop[p] = false
            if (jt == JUMP_WJ or dj) and straf and straf ~= 0 and dist > jumpdist[jt] and validlj and good > 0 and bad > 0 then
                sync = (good * 100) / (good + bad)
                local nsync = math.Round(sync * 100)

                net.Start("LJStats")
                net.WriteString(jumptypes[jt])
                net.WriteInt(math.Round(dist), 16)
                net.WriteTable(totalstats.sync)
                net.WriteTable(totalstats.speed)
                net.WriteInt(nsync, 16)
                net.Send(p)

                print(string.format("[%s] %d units", jumptypes[jt], math.Round(dist)))
                print("Strafe   Speed   Sync")
                for k, v in ipairs(totalstats.sync) do
                    print(string.format("%2d        %3d      %d%%", k, totalstats.speed[k], v))
                end
                print("Total Sync: " .. nsync .. "%")
            end
        end
    end)

    inbhop[p] = true
    strafe[p] = {}
    strafenum[p] = 0
    jumppos[p] = nil
    strafingleft[p] = false
    strafingright[p] = false
    speed[p] = nil
    lastspeed[p] = nil
    jumpproblem[p] = false
    ducking[p] = false

    if not didjump[p] then
        wj[p] = true
        inbhop[p] = false
        timer.Simple(0.3, function()
            if p and p:IsValid() then
                wj[p] = false
            end
        end)
    end

    jumptype[p] = JUMP_LJ
    oldp[p] = nil
    newp[p] = nil
    tproblem[p] = false
    didjump[p] = false
end

hook.Add("PlayerSpawn", "LJPlayerSpawn", function(p)
    inbhop[p] = false
    strafe[p] = {}
    strafenum[p] = 0
    jumppos[p] = nil
    strafingleft[p] = false
    strafingright[p] = false
    speed[p] = nil
    lastspeed[p] = nil
    jumpproblem[p] = false
    ducking[p] = false
    jumptype[p] = JUMP_LJ
    oldp[p] = nil
    newp[p] = nil
    tproblem[p] = false
    didjump[p] = false
end)