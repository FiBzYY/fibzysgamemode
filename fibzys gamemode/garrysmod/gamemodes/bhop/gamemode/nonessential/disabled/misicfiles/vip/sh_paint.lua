Paint = Paint or {}

local colors = {
    ["red"] = Color(255, 0, 0),
    ["black"] = Color(0, 0, 0),
    ["blue"] = Color(0, 0, 248),
    ["brown"] = Color(104, 49, 0),
    ["cyan"] = Color(0, 244, 248),
    ["green"] = Color(0, 252, 0),
    ["orange"] = Color(248, 148, 0),
    ["pink"] = Color(248, 0, 248),
    ["purple"] = Color(147, 0, 248),
    ["white"] = Color(255, 255, 255),
    ["yellow"] = Color(248, 252, 0),
}

for v,_ in pairs(colors) do
    game.AddDecal("paint_" .. v, "decals/paint/laser_" .. v .. "_med")

    if SERVER then
        resource.AddFile("materials/decals/paint/laser_" .. v .. ".vmt")
        resource.AddFile("materials/decals/paint/laser_" .. v .. "_med.vmt")
    end
end

if SERVER then
    util.AddNetworkString("PaintQueue")
    util.AddNetworkString("PaintHistory")

    local cooldown_time = 0.05
    local cooldown = {}
    local tempCache = {}
    local tempIndex = 1

    function Paint.ChangeColor(ply, color)
        if Command.EmptyValue(color) then
            UTIL:Print("You need to provide a color")
            return
        end

        local isValidPaint = colors[color]
        if not isValidPaint then
            UTIL:Print("This is an invalid color")
            return
        end

        ply.PaintColor = color
        UTIL:Print("Paint color set to " .. color)
    end

    concommand.Add("paintcolor", function(ply, cmd, args)
        Paint.ChangeColor(ply, args[1])
    end)

    -- Paint command
    concommand.Add("bhop_paint", function(ply)
        if cooldown[ply] and cooldown[ply] > RealTime() then return end
        cooldown[ply] = RealTime() + cooldown_time

        local eyePos = ply:EyePos() - Vector(0, 0, 16)
        local trace = ply:GetEyeTrace()
        local col = ply.PaintColor or "red"
        if not colors[col] then col = "red" end

        tempCache[tempIndex] = {trace.HitPos, trace.HitNormal, col}
        tempIndex = tempIndex + 1

        net.Start("PaintQueue")
            net.WriteVector(eyePos)
            net.WriteVector(trace.HitPos)
            net.WriteNormal(trace.HitNormal)
            net.WriteString(col)
        net.Broadcast()

        if tempIndex > 256 then
            tempIndex = 1
        end
    end)

    local function SendPaintHistory(ply)
        local cache = #tempCache
        if cache == 0 then return end

        net.Start("PaintHistory")
            net.WriteUInt(cache, 8)

            for _, data in pairs(tempCache) do
                local pos, norm, col = data[1], data[2], data[3]
                net.WriteVector(pos)
                net.WriteNormal(norm)
                net.WriteString(col)
            end
        net.Send(ply)
    end
    hook.Add("PlayerInitialSpawn", "SendPaintHistory", SendPaintHistory)
end

if CLIENT then
    local paintBeamCache = {}

    net.Receive("PaintQueue", function()
        local eye = net.ReadVector()
        local pos = net.ReadVector()
        local norm = net.ReadNormal()
        local col = net.ReadString()

        util.Decal("paint_" .. col, pos - norm, pos)
        table.insert(paintBeamCache, {eye, pos, norm, col, CurTime()})
    end)

    net.Receive("PaintHistory", function(len, _)
        local indices = net.ReadUInt(8)
        for i = 1, indices do
            local pos, norm, col = net.ReadVector(), net.ReadNormal(), net.ReadString()
            util.Decal("paint_" .. col, pos - norm, pos)
        end
        print("Loaded paint history | Size: " .. string.NiceSize(len))
    end)

    local cooldown_time = 0.05
    local cooldown = 0

    local bindedKey = input.LookupBinding("+paint")
    local keyCode = bindedKey and input.GetKeyCode(bindedKey)

    local function BindTracker()
        local currentKey = input.LookupBinding("+paint")
        if not currentKey then
            keyCode = nil
        end

        if currentKey == bindedKey then return end

        bindedKey = currentKey
        keyCode = bindedKey and input.GetKeyCode(bindedKey)

        print("Detected new paint binding, restarting paint hook")
    end
    timer.Create("BindTracker", 1, 0, BindTracker)

    local function PaintBeam()
        render.OverrideDepthEnable(true, true)
        render.SetColorMaterial()

        for _, data in pairs(paintBeamCache) do
            local time = CurTime()
            local deadline = data[5] + cooldown_time
            if time > deadline then
                table.remove(paintBeamCache, 1)
                continue
            end

            local start, finish, color = data[1], data[2] - data[3], colors[data[4]]
            render.DrawBeam(start, finish, 5, 0, 1, color)
        end

        render.OverrideDepthEnable(false)
    end
    hook.Add("PreDrawOpaqueRenderables", "Paintbeam", PaintBeam)

    local function PaintSpammer()
        if not keyCode then return end
        if vgui.CursorVisible() then return end
        local timing = rt

        if cooldown > timing() then return end
        cooldown = timing() + cooldown_time

        local isPressing = input.IsButtonDown(keyCode)
        if not isPressing then return end

        --RunConsoleCommand("+paint")
    end
    hook.Add("Tick", "Spammer", PaintSpammer)
end