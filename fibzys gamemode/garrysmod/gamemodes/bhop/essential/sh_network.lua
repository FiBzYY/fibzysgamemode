if SERVER then
    util.AddNetworkString("TimerNetworkProtocol")
    util.AddNetworkString("NetworkProtocol")
    util.AddNetworkString("NetworkProtocolSSJ")
    util.AddNetworkString("NetworkProtocolEncoded")
    util.AddNetworkString("userinterface.network")
end

NETWORK = NETWORK or {}
DATA = DATA or {}

local function TableSize(tbl)
    local size = 0
    for k, v in pairs(tbl) do
        size = size + #tostring(k) + #tostring(v)
        if type(v) == "table" then
            size = size + TableSize(v)
        end
    end
    return size
end

local MAX_NET_MESSAGE_SIZE = 64000
local MAX_TABLE_SIZE = 32
local MAX_BOOLEAN_ARRAY_SIZE = 128

function NETWORK:StartNetworkMessage(net_tgt, net_action, ...)
    local net_contents = {...}
    local contentsSize = TableSize(net_contents)

    if contentsSize > MAX_NET_MESSAGE_SIZE then
        UTIL:Notify(Color(255, 255, 0), "Network", "Data exceeds max size! Size: " .. contentsSize .. " bytes.")
        return
    end

    net.Start("NetworkProtocol")
    net.WriteString(net_action)
    net.WriteUInt(#net_contents, 8) 

    for _, v in ipairs(net_contents) do
        local vType = type(v)

        if vType == "number" then
            net.WriteUInt(0, 4)         -- Type ID 0
            net.WriteFloat(v)
        elseif vType == "string" then
            net.WriteUInt(1, 4)         -- Type ID 1
            net.WriteString(v)
        elseif vType == "boolean" then
            net.WriteUInt(2, 4)         -- Type ID 2
            net.WriteBool(v)
        elseif IsValid(v) and v:IsPlayer() then
            net.WriteUInt(3, 4)         -- Type ID 3
            net.WriteEntity(v)
        elseif vType == "Vector" then
            net.WriteUInt(4, 4)         -- Type ID 4
            net.WriteVector(v)
        elseif vType == "Angle" then
            net.WriteUInt(5, 4)         -- Type ID 5
            net.WriteAngle(v)
        elseif vType == "table" then
            net.WriteUInt(6, 4)         -- Type ID 6
            net.WriteTable(v)
        else
            UTIL:Notify(Color(255, 0, 0), "Network", "[ERROR] Unhandled data type: " .. tostring(vType))
            print("[ERROR] Unhandled network data type:", vType, "Value:", v)
        end
    end

    if SERVER then
        if not net_tgt then
            net.Broadcast()
        else
            net.Send(net_tgt)
        end
    else
        net.SendToServer()
    end
end

function NETWORK:StartNetworkMessageSSJ(net_tgt, net_action, jumps, gain, currentVel, strafes, efficiency, sync, lastSpeed, difference)
    net.Start("NetworkProtocolSSJ")
    net.WriteString(net_action)

    net.WriteUInt(jumps, 16)       -- Number of jumps
    net.WriteFloat(gain)            -- Gain percentage
    net.WriteFloat(currentVel)       -- Current velocity
    net.WriteUInt(strafes, 16)        -- Strafe count
    net.WriteFloat(efficiency)         -- Efficiency percentage
    net.WriteFloat(sync)                -- Sync percentage
    net.WriteFloat(lastSpeed or 0)       -- Last speed
    net.WriteFloat(difference or 0)        -- Speed difference

    if SERVER then
        if not net_tgt then
            net.Broadcast()
        else
            net.Send(net_tgt)
        end
    elseif CLIENT then
        net.SendToServer()
    end
end

function NETWORK:StartNetworkMessageForBools(net_tgt, net_action, ...)
    local net_bools = {...}
    local boolsSize = #net_bools

    if boolsSize > MAX_BOOLEAN_ARRAY_SIZE then
        print("[Network Error] Too many boolean values! Size: " .. boolsSize)
        return
    end

    net.Start("NetworkProtocolBool")
    net.WriteString(net_action)

    for _, boolVal in ipairs(net_bools) do
        net.WriteBool(boolVal)
    end

    if CLIENT then
        net.SendToServer()
    elseif SERVER then
        if not net_tgt then
            net.Broadcast()
        else
            net.Send(net_tgt)
        end
    end
end

function NETWORK:StartNetworkMessageTimer(net_tgt, net_action, varArgs)
    local contentsSize = varArgs and type(varArgs) == "table" and TableSize(varArgs) or 0
    if contentsSize > MAX_NET_MESSAGE_SIZE then
        UTIL:Notify(Color(255, 255, 0), "Network", "Data exceeds maximum allowed size for network message! Size: " .. contentsSize .. " bytes.")
        return
    end

    net.Start("TimerNetworkProtocol")
    net.WriteString(net_action)

    if varArgs and type(varArgs) == "table" then
        net.WriteBool(true)
        net.WriteTable(varArgs)
    else
        net.WriteBool(false)
    end

    if CLIENT then
        net.SendToServer()
    elseif SERVER then
        if not net_tgt then
            net.Broadcast()
        else
            net.Send(net_tgt)
        end
    end
end

function NETWORK:Encode(tbl)
    local json = util.TableToJSON(tbl)
    return util.Compress(json)
end

function NETWORK:StartEncodedNetworkMessage(net_tgt, net_id, net_content)
    local len = #net_content
    net.Start("NetworkProtocolEncoded")
    net.WriteString(net_id)
    net.WriteUInt(len, 32)
    net.WriteData(net_content, len)
    if CLIENT then
        net.SendToServer()
    elseif SERVER then
        if not net_tgt then
            net.Broadcast()
        else
            net.Send(net_tgt)
        end
    end
end

function NETWORK:GetNetworkMessage(id, func)
    DATA[id] = func
end

function NETWORK:GetNetworkMessageSSJ(id, func)
    DATA[id] = func
end

net.Receive("NetworkProtocol", function(len, cl)
    local network_action = net.ReadString()

    local num_items = net.ReadUInt(8)
    local network_data = {}

    for i = 1, num_items do
        local data_type = net.ReadUInt(4)                  -- Read type

        if data_type == 0 then
            table.insert(network_data, net.ReadFloat())    -- Read number
        elseif data_type == 1 then
            table.insert(network_data, net.ReadString())   -- Read string
        elseif data_type == 2 then
            table.insert(network_data, net.ReadBool())     -- Read boolean
        elseif data_type == 3 then
            local pl = net.ReadEntity()
            table.insert(network_data, pl)
        elseif data_type == 4 then
            table.insert(network_data, net.ReadVector())   -- Read Vector
        elseif data_type == 5 then
            table.insert(network_data, net.ReadAngle())    -- Read Angle
        elseif data_type == 6 then
            table.insert(network_data, net.ReadTable())    -- Read Table
        else
            UTIL:Notify(Color(255, 0, 0), "Network", "[ERROR] Received unknown data type: " .. data_type)
        end
    end

    if DATA[network_action] then
        DATA[network_action](cl, network_data)
    end
end)

net.Receive("NetworkProtocolSSJ", function()
    local network_action = net.ReadString()

    local network_data = {
        jumps = net.ReadUInt(16),
        gain = net.ReadFloat(),
        speed = net.ReadFloat(),
        strafes = net.ReadUInt(16),
        efficiency = net.ReadFloat(),
        sync = net.ReadFloat(),
        lastspeed = net.ReadFloat() or 0,
        difference = net.ReadFloat() or 0
    }

    local callback = DATA[network_action]
    if callback then 
        callback(network_data) 
    end
end)

net.Receive("NetworkProtocolBool", function(_, ply)
    local network_action = net.ReadString()

    local network_data = {}

    while net.BytesLeft() > 0 do
        table.insert(network_data, net.ReadBool())
    end

    if DATA[network_action] then
        DATA[network_action](ply, network_data)
    end
end)

net.Receive("NetworkProtocolEncoded", function(_, cl)
    local network_id = net.ReadString()
    local network_len = net.ReadUInt(32)
    local network_data = net.ReadData(network_len)
    network_data = util.JSONToTable(util.Decompress(network_data))
    if DATA[network_id] then
        DATA[network_id](cl, network_data)
    end
end)

net.Receive("TimerNetworkProtocol", function(len, cl)
    local szAction = net.ReadString()
    local hasTable = net.ReadBool()
    local varArgs = hasTable and net.ReadTable() or {}
    if DATA["TimerNetworkProtocol"] then
        DATA["TimerNetworkProtocol"](szAction, varArgs, cl)
    end
end)

UI = UI or {}
function UI:SendToClient(client, uiId, ...)
    NETWORK:StartNetworkMessage(client, "UI", uiId, ...)
end

function UI:SendCallback(handle, data)
    NETWORK:StartNetworkMessage(false, "UI", handle, unpack(data))
end

function UI:AddListener(id, func)
    DATA[id] = func
end

if CLIENT then
    NETWORK:GetNetworkMessage("UI", function(cl, data)
        local id = data[1]
        table.remove(data, 1)

        if DATA[id] then
            DATA[id](cl, data)
        else
            UTIL:AddMessage("Network", "No listener found for UI ID", id)
        end
    end)
end