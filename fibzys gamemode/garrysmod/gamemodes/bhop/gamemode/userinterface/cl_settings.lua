if not Settings then 

-- Module is neat
Settings = Settings or {}
local lst = lst or {}
local possibilites = possibilities or {}

-- Add new setting
function Settings:Register(settingId, default, ops, ty)
    lst[settingId] = {
        value = default,
        default = default,
        ty = ty or SETTINGTYPE_BOOL
    }
    possibilites[settingId] = ops
    return lst[settingId].value
end

function Settings:GetType(settingId)
    if not lst[settingId] then return nil end
    return lst[settingId].ty
end

-- Load settings
function Settings:Load()
	self.loaded = true 
	-- Does file exist
	if file.Exists("timer", "DATA") and file.Exists("timer/settings.txt", "DATA") then 
		local settings = file.Read("timer/settings.txt", "DATA")
		lst = util.JSONToTable(settings)

		return
	end

	file.CreateDir("timer")
end
hook.Add("Initialize", "Settings_Load", function()
	if Settings.loaded then return end
	Settings:Load()
end)

function Settings:Save()
	local settings = util.TableToJSON(lst, true)
	file.Write("timer/settings.txt", settings)
end

function Settings:GetValue(settingId)
	if (not lst) or (not lst[settingId]) then
		return nil 
	end

	return lst[settingId].value 
end

function Settings:SetValue(settingId, value)
	if (not lst[settingId]) then
		return nil 
	end

	if (possibilites[settingId] and (not table.HasValue(possibilites[settingId], value))) then 
		return nil 
	end

	lst[settingId].value = value
	self:Save() 
end

function Settings:GetOptions(settingId)
	if (not possibilites[settingId]) then 
		return nil 
	end
	return possibilites[settingId]
end

function Settings:ResetDefault(settingId)
	self:SetValue(settingId, lst[settingId].default)
end

end