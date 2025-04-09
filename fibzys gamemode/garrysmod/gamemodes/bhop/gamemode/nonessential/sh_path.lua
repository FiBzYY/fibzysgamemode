-- Replay Path by FiBzY
-- DO TO: Maybe show coruching in white?

if SERVER then
    util.AddNetworkString("ShavitLine_Beam")
    util.AddNetworkString("ShavitLine_Request")
    util.AddNetworkString("ShavitLine_Toggle")
    util.AddNetworkString("ShavitLine_Clear")

    net.Receive("ShavitLine_Request", function(len, ply)
        if not IsValid(ply) then return end

        local landings = Replay:GetAllLandings(1)

        for _, pos in ipairs(landings) do
            net.Start("ShavitLine_Beam")
            net.WriteVector(pos - Vector(10, 0, 0))
            net.WriteVector(pos + Vector(10, 0, 0))
            net.WriteColor(Color(0, 0, 255))
            net.Send(ply)
        end
    end)

    net.Receive("ShavitLine_Toggle", function(len, ply)
        if not IsValid(ply) then return end
        local state = net.ReadBool()
        ply:SetPData("replay_beams", state and "1" or "0")
    end)

    -- Landing Data 
    function Replay:GetAllLandings(style)
        local data = self.BotData[style]
        if not data or not data[7] then
            return {}
        end

        local landings = {}
        local x, y, z = data[1], data[2], data[3]
        local flags = data[7]

        local lastPos
        local minDistanceSqr = 64 * 64

        for i = 1, #x - 1 do 
            if bit.band(flags[i] or 0, FL_ONGROUND) ~= 0 then
                local pos = Vector(x[i], y[i], z[i])
                if not lastPos or lastPos:DistToSqr(pos) > minDistanceSqr then
                    table.insert(landings, pos)
                    lastPos = pos
                end
            end
        end

        return landings
    end

    hook.Add("PlayerInitialSpawn", "SendLandingBeams", function(ply)
        if not IsValid(ply) then return end

        local saved = ply:GetPData("replay_beams", "0")
        if saved == "1" then
            local landings = Replay:GetAllLandings(1)
            for _, pos in ipairs(landings) do
                net.Start("ShavitLine_Beam")
                net.WriteVector(pos - Vector(10, 0, 0))
                net.WriteVector(pos + Vector(10, 0, 0))
                net.WriteColor(Color(0, 255, 0))
                net.Send(ply)
            end
        end
    end)
end

if CLIENT then
    CreateClientConVar("bhop_replaylines", "0", true, false, "Show the path of replay")
    CreateClientConVar("bhop_replaylines_dist", "1000", true, false, "Show the path of replay distance")

    -- Replay path
    local landingBoxes = {}

    net.Receive("ShavitLine_Beam", function()
        if not GetConVar("bhop_replaylines"):GetBool() then return end

        local startPos = net.ReadVector()
        local endPos = net.ReadVector()
        local color = net.ReadColor()

        local center = (startPos + endPos) / 2
        center.z = center.z + 0.2

        table.insert(landingBoxes, {
            pos = center,
            color = color
        })
    end)

    -- render
    hook.Add("PostDrawTranslucentRenderables", "DrawReplayPath", function()
        if not GetConVar("bhop_replaylines"):GetBool() then return end
        if #landingBoxes == 0 then return end

        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local posPlayer = ply:GetPos()
        local drawDistance = GetConVar("bhop_replaylines_dist"):GetFloat()
        local drawDistanceSqr = drawDistance * drawDistance

        local size = 6
        local height = 0.1
        local overlap = 0.5
        local lastValidPos = nil

        local function ExtendBeam(p1, p2)
            if not p1 or not p2 then return p1, p2 end
            local direction = (p2 - p1):GetNormalized()
            return p1 - direction * overlap, p2 + direction * overlap
        end

        render.SetColorMaterial()

        for _, box in ipairs(landingBoxes) do
            local pos = box.pos
            local color = box.color or Color(128, 0, 128)
            local colorline = Color(0, 0, 255)

            local isVisible = pos:DistToSqr(posPlayer) <= drawDistanceSqr

            if isVisible then
                -- Draw square
                local tl = pos + Vector(-size, -size, height)
                local tr = pos + Vector( size, -size, height)
                local br = pos + Vector( size,  size, height)
                local bl = pos + Vector(-size,  size, height)

                local a, b = ExtendBeam(tl, tr)
                render.DrawBeam(a, b, 1.5, 0, 0, color)

                a, b = ExtendBeam(tr, br)
                render.DrawBeam(a, b, 1.5, 0, 0, color)

                a, b = ExtendBeam(br, bl)
                render.DrawBeam(a, b, 1.5, 0, 0, color)

                a, b = ExtendBeam(bl, tl)
                render.DrawBeam(a, b, 1.5, 0, 0, color)
            end

            -- Now draw the path line ONLY if both this and last are visible
            if lastValidPos and isVisible and lastValidPos:DistToSqr(posPlayer) <= drawDistanceSqr then
                local from, to = ExtendBeam(lastValidPos, pos)
                render.DrawBeam(from, to, 1, 0, 0, colorline)
            end

            -- Always update last valid pos
            lastValidPos = pos
        end
    end)

    -- clear path
    net.Receive("ShavitLine_Clear", function()
        table.Empty(landingBoxes)
    end)

    -- callback
    cvars.AddChangeCallback("bhop_replaylines", function(_, _, new)
        local state = tonumber(new) == 1

        if state then
            net.Start("ShavitLine_Request")
            net.SendToServer()
        else
            net.Start("ShavitLine_Clear")
            net.SendToServer()
        end

        net.Start("ShavitLine_Toggle")
        net.WriteBool(state)
        net.SendToServer()
    end, "ShavitLine_Beam")
end