RTVStart = RTVStart or false
RTVSelected = RTVSelected or false

local PANEL = false 
local VoteInProgress = false 
local RTVStart = false
local CurrentSelected = false

local function Vote(mapId)
    return function()
        if not UI.rtv then return end

        local accent = UI.rtv.themec and UI.rtv.themec["Accent Colour"] or color_white
        local text = UI.rtv.themec and color_white -- UI.rtv.themec["Text Colour"]
        local old = false

        if CurrentSelected == mapId then return end

        CurrentSelected = mapId
        UI.rtv:UpdateOption(mapId, false, accent, false)

        for k, v in pairs(UI.rtv.options) do
            if k ~= mapId then
                if v.col and v.col == accent then
                    old = k
                end
                UI.rtv:UpdateOption(k, false, text, false)
            end
        end

       NETWORK:StartNetworkMessage(false, "VoteCallback", mapId, old)
    end
end

local function StartRTV(info, isRevote)
    local ui_options = {}
    local mapInfotier = {
        ["bhop_asko"] = {tier = 1},
        ["bhop_newdun"] = {tier = 1},
        ["bhop_stref_amazon"] = {tier = 2},
    }

    for k, v in pairs(info) do 
        local mapName = v[1]
        local mapData = mapInfotier[mapName] or {tier = 1}
        local tierName = "Tier " .. mapData.tier
        local name = "(0) " .. mapName .. " - " .. tierName .. " (" .. v[2] .. " points, " .. v[3] .. " plays)"
        table.insert(ui_options, {["name"] = name, ["function"] = Vote(k)})
    end

    table.insert(ui_options, {["name"] = "(0) Extend the current map", ["function"] = Vote(6)})
    table.insert(ui_options, {["name"] = "(0) Go to a randomly selected map", ["function"] = Vote(7)})

    UI.rtv = UI:NumberedUIPanel("", unpack(ui_options))
    RTVStart = isRevote and (RTVStart or CurTime() + 15) or CurTime() + 15

    function UI.rtv:OnThink()
        local s = math.Round(RTVStart - CurTime())
        if s <= 0 then
            self:Exit()
            RTVStart = false
            RTVSelected = false
            return
        end
        self.title = "Map Vote (" .. s .. "s remaining)"
    end

    function UI.rtv:OnExit()
        UTIL:AddMessage("Notification", "You can reopen this menu with !revote")
    end

    UI.rtv:SetCustomDelay(3)
end

local function UpdatePanel(info)
    if not UI.rtv or not UI.rtv.title then return end
    for k, v in pairs(info) do
        if UI.rtv.options and UI.rtv.options[k] then
            local name = UI.rtv.options[k].name
            name = "(" .. v .. ") " .. (v <= 10 and name:sub(5) or name:sub(6))
            surface.PlaySound("garrysmod/ui_click.wav")
            UI.rtv:UpdateOption(k, name, false, false)
        end
    end
end

local function Instant(info)
    if UI.rtv then
        UI.rtv:SelectOption(info)
    end
end

local function Revote(info)
    if not UI.rtv or not UI.rtv.title then
        DATA["rtv"](_, {"update", info}, true)
        if RTVSelected then
            UI.rtv:UpdateOption(RTVSelected, false, RainbowTextEffect(text), false)
        end
    end
end

UI:AddListener("MapVote", function(_, data, isRevote)
    local id = data[1]
    local info = data[2]

    if id == "started" then
        StartRTV(info, isRevote)
    elseif id == "update" then
        UpdatePanel(info)
    elseif id == "instant" then
        Instant(info)
    elseif id == "revote" then
        Revote(info)
    end
end)