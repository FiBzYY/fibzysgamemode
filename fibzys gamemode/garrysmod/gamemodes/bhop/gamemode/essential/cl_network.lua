CSList, CSData, CS_LocalList, CS_RemoteList = {}, {}, {}, {}
CSTitle, CS_Type = "", 3
SpectateData = { Replay = false, Player = "Unknown", Start = nil, Best = nil, Contains = false }
S_Data = { Contains = nil, Replay = false, Player = "Unknown", Start = nil, Record = nil }

function ResetSpectateData()
    SpectateData = { Replay = false, Player = "Unknown", Start = nil, Best = nil, Contains = false }
    S_Data = { Contains = nil, Replay = false, Player = "Unknown", Start = nil, Record = nil }
    CSList = {}
    CSTitle = ""
end

function UpdateSpectateData(isBot, playerName, startTime, bestRecord)
    SpectateData.Replay = isBot
    SpectateData.Start = startTime and startTime + TIMER:GetDifference() or nil
    SpectateData.Best = bestRecord or 0
    SpectateData.Contains = true

    S_Data = {
        Contains = SpectateData.Contains,
        Replay = SpectateData.Replay,
        Start = SpectateData.Start,
        Record = SpectateData.Best
    }

    TIMER:SpectateUpdate()
end

function SpectatePlayer(startTime, bestRecord)
    UpdateSpectateData(false, "Player", startTime, bestRecord)
end

local function CS_Viewer(bLeave, szName, szUID)
    if not bLeave then
        if not CS_LocalList[szUID] or CS_LocalList[szUID] ~= szName then
            CS_LocalList[szUID] = szName
        end
    else
        if CS_LocalList[szUID] then
            CS_LocalList[szUID] = nil
        end
    end

    local nCount = 0
    for _, s in pairs(CS_LocalList) do
        nCount = nCount + 1
    end

    TIMER:SpectateData(CS_LocalList, false, nCount)
end

function CS_Bot(timer, name, record, server, var)
    if server and type(server) == "number" then
        TIMER:Sync(server)
    else
        print("[CS_Bot] server is not a number! Got:", type(server))
    end

    if var and type(var) == "table" and #var > 0 then
        CS_Remote(var)
    else
        CS_Remote({})
    end

    UpdateSpectateData(true, name or "Replay", timer, record)
end

function UpdateSpectatorsList(viewerList, remote)
    CSList = viewerList or {}
    local numSpectators = #CSList
    CSTitle = "Spectators (#" .. numSpectators .. "):"
end

function TIMER:SpectateData(viewerList, isRemote, numViewers)
    UpdateSpectatorsList(viewerList, isRemote)
end

function TIMER:SpectateUpdate()
    CSData = S_Data
end

function CS_Remote(var)
    UpdateSpectatorsList(var, true)
end

function CS_Clear()
    CS_LocalList = {}
    CS_RemoteList = {}
    ResetSpectateData()
    CS_Type = 3

    TIMER:SpectateUpdate()
    TIMER:SpectateData({}, true, 0, true)
end

function CS_Mode(nMode)
    CS_Type = nMode

    if CS_Type == 3 then
        CS_Clear()
    end
end

local timer_prefix = CreateClientConVar("bhop_timer_prefix_rainbow", "0", true, false, "Enable or disable rainbow timer prefix.")
local timer_format = CreateClientConVar("bhop_timer_format", "pipe", true, false, "Choose the timer format: 'brackets' or 'pipe'.")
local use_dynamic_color = CreateClientConVar("bhop_use_dynamic_color", "0", true, false, "Use DynamicColors.TextColor for all prefixes.")
local timer_sound = CreateClientConVar("bhop_chatsound", "0", true, false, "Toggle sound when displaying chat messages (1 = enabled, 0 = disabled)")

local prefixColors = {
    ["Server"] = UTIL.Colour["Server"],
    ["Timer"] = UTIL.Colour["Timer"],
    ["Notification"] = UTIL.Colour["Timer"],
    ["AntiCheat"] = UTIL.Colour["AntiCheat"],
    ["SSJTOP"] = UTIL.Colour["AntiCheat"]
}

local insert = table.insert

function TIMER:Print(szPrefix, varText)
    if szPrefix == "AntiCheat" then
        if not varText then return end
        if type(varText) ~= "table" then varText = { varText } end
        
        chat.AddText(color_white, "[", UTIL.Colour["AntiCheat"], szPrefix, color_white, "] ", unpack(varText))
        return
    end

    if not varText then return end
    varText = type(varText) == "table" and varText or { varText }

    local isRainbowEnabled = GetConVar("bhop_timer_prefix_rainbow"):GetBool()
    local format = GetConVar("bhop_timer_format"):GetString()
    local useDynamicColor = GetConVar("bhop_use_dynamic_color"):GetBool()

    local prefixStart, prefixEnd
    if format == "brackets" then
        prefixStart, prefixEnd = "[", "] "
    elseif format == "pipe" then
        prefixStart, prefixEnd = "", " | "
    else
        prefixStart, prefixEnd = "[", "] "
    end

    local prefixColor = useDynamicColor and DynamicColors.TextColor or (prefixColors[szPrefix] or color_white)
    local chatMessage = {}

    if isRainbowEnabled then
        local currentTime, hueOffset = SysTime(), 30
        local rainbowPrefix = {}

        for i = 1, #szPrefix do
            local hue = (currentTime * 120 + i * hueOffset) % 360
            insert(rainbowPrefix, HSVToColor(hue, 1, 1))
            insert(rainbowPrefix, szPrefix:sub(i, i))
        end

        insert(chatMessage, color_white)
        insert(chatMessage, prefixStart)
        for _, v in ipairs(rainbowPrefix) do insert(chatMessage, v) end
        insert(chatMessage, color_white)
        insert(chatMessage, prefixEnd)
    else
        insert(chatMessage, color_white)
        insert(chatMessage, prefixStart)

        insert(chatMessage, prefixColor)
        for i = 1, #szPrefix do
            insert(chatMessage, szPrefix:sub(i, i))
        end

        insert(chatMessage, color_white)
        insert(chatMessage, prefixEnd)
    end

    for _, v in ipairs(varText) do
        insert(chatMessage, v)
    end

    if timer_sound:GetBool() then
        surface.PlaySound("common/talk.wav")
    end

    chat.AddText(unpack(chatMessage))
end

function TIMER:Send(szAction, varArgs)
    NETWORK:StartNetworkMessageTimer(nil, szAction, varArgs)
end

NETWORK:GetNetworkMessage("TimerNetworkProtocol", function(actionType, data, ply)
    if actionType == "GUI_Open" then Window:Open(tostring(data[1]), data[2]) end
    if actionType == "JumpUpdate" then data[1].player_jumps = data[2] end
    if actionType == "GUI_Update" then Window:Update(tostring(data[1]), data[2]) end
    if actionType == "Print" then TIMER:Print(tostring(data[1]), data[2]) end

    if actionType == "Spectate" then
        local spectateType = tostring(data[1])

        if spectateType == "Clear" then 
            CS_Clear() 
        elseif spectateType == "Mode" then 
            CS_Mode(tonumber(data[2])) 
        elseif spectateType == "Viewer" then 
            CS_Viewer(data[2], data[3], data[4]) 
        elseif spectateType == "Timer" then 
            CS_Bot(data[3], data[4], data[5], data[6], data[7])
        end
    end

    if actionType == "Admin" then Admin:Receive(data) end

    if actionType == "Scoreboard" then
        local mode, client, timeStarted, finishedTime = data[1], data[2], data[3] or 0, data[4]
        client.time, client.finished, client.bonustime, client.bonusfinished = 0, nil, 0, nil
        if mode == "normal" then client.time, client.finished = timeStarted, finishedTime end
        if mode == "bonus" then client.bonustime, client.bonusfinished = timeStarted, finishedTime end
    end
end)

NETWORK:GetNetworkMessage("TIMER/Record", function(_, data)
    local ply = data[1]
    local recordTime = data[2]
    local style = data[3]

    TIMER:SetRecord(ply, recordTime, style)
    TIMER:Send("Speed", TIMER:GetSpeedData())
end)