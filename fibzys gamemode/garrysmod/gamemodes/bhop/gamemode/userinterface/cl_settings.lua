if not Settings then
    Settings = Settings or {}
    local settingsList = {}
    local possibleValues = {}

    function Settings:Register(settingId, default, options)
        settingsList[settingId] = {value = default, default = default}
        possibleValues[settingId] = options
        return settingsList[settingId].value
    end

    function Settings:Load()
        self.loaded = true
        if file.Exists("timer", "DATA") and file.Exists("timer/settings.txt", "DATA") then
            local settings = file.Read("timer/settings.txt", "DATA")
            settingsList = util.JSONToTable(settings)
            return
        end
        file.CreateDir("timer")
    end

    hook.Add("Initialize", "Settings_Load", function()
        if Settings.loaded then return end
        Settings:Load()
    end)

    function Settings:Save()
        local settings = util.TableToJSON(settingsList, true)
        file.Write("timer/settings.txt", settings)
    end

    function Settings:GetValue(settingId)
        if not settingsList or not settingsList[settingId] then
            return nil
        end
        return settingsList[settingId].value
    end

    function Settings:SetValue(settingId, value)
        if not settingsList[settingId] then
            return nil
        end

        if possibleValues[settingId] and not table.HasValue(possibleValues[settingId], value) then
            return nil
        end

        settingsList[settingId].value = value
        self:Save()
    end

    function Settings:GetOptions(settingId)
        return possibleValues[settingId]
    end

    function Settings:ResetDefault(settingId)
        self:SetValue(settingId, settingsList[settingId].default)
    end
end