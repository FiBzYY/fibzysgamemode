RTVStart = RTVStart or false
RTVSelected = RTVSelected or false

local function RTV_Callback(id)
    return function()
        local accent = DynamicColors.PanelColor -- BHOP.RTV.VoteColourPicked
        local text = color_white
        local old = false

        if (UI.rtv.options[id].col) and (UI.rtv.options[id].col == accent) then
            return
        end

        RTVSelected = id
        UI.rtv:UpdateOption(id, false, accent, false)
        for k, v in pairs(UI.rtv.options) do
            if (k ~= id) then
                if (v.col) and (v.col == accent) then
                    old = k
                end

                UI.rtv:UpdateOption(k, false, text, false)
            end
        end

        UI:SendCallback("rtv", {id, old})
    end
end

UI:AddListener("rtv", function(_, data, isRevote)
    local id = data[1]
    local info = data[2]

    if id == "GetList" then
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

            local name = "[0] " .. mapName .. (tierName ~= "" and " - " .. tierName or "") .. " (" .. v[2] .. " points, " .. v[3] .. " plays)"
            table.insert(ui_options, {["name"] = name, ["function"] = RTV_Callback(k)})
        end

        table.insert(ui_options, {["name"] = "[0] Extend the current map", ["function"] = RTV_Callback(6)})
        table.insert(ui_options, {["name"] = "[0] Go to a randomly selected map", ["function"] = RTV_Callback(7)})

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
    elseif id == "VoteList" then
        if not UI.rtv or not UI.rtv.title then return end
        for k, v in pairs(info) do
            local name = UI.rtv.options[k].name
            name = "[" .. v .. "] " .. (v <= 10 and name:Right(#name - 4) or name:Right(#name - 5))
            surface.PlaySound("garrysmod/ui_click.wav")
            UI.rtv:UpdateOption(k, name, false, false)
        end
    elseif id == "InstantVote" then
        UI.rtv:SelectOption(info)
    elseif id == "Revote" then 
        if not UI.rtv or not UI.rtv.title then 
            DATA["rtv"](_, {"GetList", info}, true)
            if RTVSelected then 
                UI.rtv:UpdateOption(RTVSelected, false, RainbowTextEffect(text), false)
            end
        end
    end
end)