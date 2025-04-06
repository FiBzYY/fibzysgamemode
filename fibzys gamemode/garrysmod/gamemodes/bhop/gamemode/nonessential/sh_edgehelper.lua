--[[ 
     ____  ____   ___  ____    _  _  ____  __    ____  ____  ____ 
    (  __)(    \ / __)(  __)  / )( \(  __)(  )  (  _ \(  __)(  _ \
     ) _)  ) D (( (_ \ ) _)   ) __ ( ) _) / (_/\ ) __/ ) _)  )   /
    (____)(____/ \___/(____)  \_)(_/(____)\____/(__)  (____)(__\_) ! by fibzy
]]--

if SERVER then
    local edgeHelperPlayers = {}
    local FILE_NAME = "edgehelper_state.txt"

    local function SaveEdgeHelperState()
        local data = {}
        for steamID, enabled in pairs(edgeHelperPlayers) do
            table.insert(data, steamID .. " " .. tostring(enabled))
        end
        file.Write(FILE_NAME, table.concat(data, "\n"))
    end

    local function LoadEdgeHelperState()
        if not file.Exists(FILE_NAME, "DATA") then return end
        local data = file.Read(FILE_NAME, "DATA")
        local lines = string.Explode("\n", data)
        for _, line in ipairs(lines) do
            local steamID, enabled = string.match(line, "([^%s]+) ([^%s]+)")
            if steamID and enabled then
                edgeHelperPlayers[steamID] = enabled == "true"
            end
        end
    end
    LoadEdgeHelperState()

    hook.Add("PlayerInitialSpawn", "EdgeHelperInit", function(ply)
        local steamID = ply:SteamID()
        edgeHelperPlayers[steamID] = edgeHelperPlayers[steamID] or false
    end)

    concommand.Add("bhop_edgehelper", function(ply)
        local steamID = ply:SteamID()
        local enabled = not edgeHelperPlayers[steamID]
        edgeHelperPlayers[steamID] = enabled
        SaveEdgeHelperState()
        ply:ChatPrint(enabled and ":)" or ":(")
    end)
end

if CLIENT then
    local edgeHelperCorners = {}
    local bhopEdgeHelperEnabled = CreateClientConVar("bhop_enable_edgehelper", "1", true, false, "Toggle edge helper visibility")
    local gF_StartedOnGround = 0
    local gI_LastDrawn = 0
    local START_CHECKING = 0.1

    local PLAYER_HULL_MIN = Vector(-16, -16, 0)
    local PLAYER_HULL_STAND = Vector(16, 16, 62)
    local PLAYER_HULL_DUCK = Vector(16, 16, 45)

    local function IsHullOnSomething(origin)
        local endpoint = Vector(origin[1], origin[2], origin[3] - 0.1)
        local trace = util.TraceHull({
            start = origin,
            endpos = endpoint,
            mins = PLAYER_HULL_MIN,
            maxs = Vector(16, 16, 0),
            mask = MASK_PLAYERSOLID,
            filter = LocalPlayer()
        })
        return trace.Hit
    end

    local function HowFarFromSide(origin, idx, add_this)
        local startpos = Vector(origin[1], origin[2], origin[3])
        
        for i = 0, 63 do
            if idx == 0 then
                startpos[1] = startpos[1] + add_this
            elseif idx == 1 then
                startpos[2] = startpos[2] + add_this
            end
            
            if not IsHullOnSomething(startpos) then
                return 16.0 - (i / 4)
            end
        end

        return 0.0
    end

    hook.Add("StartCommand", "EdgeHelper", function(client, cmd)
        if cmd:TickCount() == 0 then return end
        if not client:IsOnGround() or not client:Crouching() then
            gF_StartedOnGround = 0
            edgeHelperCorners = {}
            return
        end

        if gF_StartedOnGround == 0 then
            gF_StartedOnGround = cmd:TickCount()
        end

        if cmd:TickCount() - gF_StartedOnGround < START_CHECKING then
            return
        end

        local origin = client:GetPos()

        -- Edge Distance --
        local distLeft  = HowFarFromSide(origin, 0, -0.25)
        local distRight = HowFarFromSide(origin, 0,  0.25)
        local distFront = HowFarFromSide(origin, 1, -0.25)
        local distBack  = HowFarFromSide(origin, 1,  0.25)

        if distLeft == 0.0 and distRight == 0.0 and distFront == 0.0 and distBack == 0.0 then
            edgeHelperCorners = {}
            return
        end

        -- Edge Helper --
        edgeHelperCorners = {
            origin + Vector(-16 + distLeft,  16,  0),
            origin + Vector( 16 - distRight, 16,  0),
            origin + Vector(-16 + distLeft, -16,  0),
            origin + Vector( 16 - distRight, -16,  0)
        }
    end)

    -- Render --
    hook.Add("PostDrawOpaqueRenderables", "DrawEdgeHelperBeams", function()
        if not bhopEdgeHelperEnabled:GetBool() or #edgeHelperCorners == 0 then return end

        render.SetColorMaterial()

        local width = 1
        local colour = Color(255, 153, 255, 75)

        render.DrawBeam(edgeHelperCorners[1], edgeHelperCorners[2], width, 0, 0, colour)
        render.DrawBeam(edgeHelperCorners[1], edgeHelperCorners[3], width, 0, 0, colour)
        render.DrawBeam(edgeHelperCorners[3], edgeHelperCorners[4], width, 0, 0, colour)
        render.DrawBeam(edgeHelperCorners[2], edgeHelperCorners[4], width, 0, 0, colour)
    end)

    -- Toggle --
    cvars.AddChangeCallback("bhop_enable_edgehelper", function(convar_name, old_value, new_value)
        if new_value == "1" then
            UTIL:AddMessage("EdgeHelper", "Enabled! :)")
        else
            UTIL:AddMessage("EdgeHelper", "Disabled! :(")
            edgeHelperCorners = {}
        end
    end)
end