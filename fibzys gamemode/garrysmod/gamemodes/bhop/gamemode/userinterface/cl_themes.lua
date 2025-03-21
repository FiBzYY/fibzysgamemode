-- Themes for changing HUDs
themes = themes or {}

if not Theme then 
    Theme = {}
end

function Theme:Register(ty, id, name, options)
    themes[id] = {name = name, ty = ty, options = options}

    Settings:Register(id, themes[id])
    self:SetupPreference(id, options)
end

function Theme:Translate(id)
    if themes[id] then 
        return themes[id].name 
    else 
        return 0
    end
end

function Theme:SetupPreference(id, ops)
    local idk 
    for k, v in pairs(ops) do 
        if type(v) == "table" and v["Colours"] then 
            idk = k 
            break 
        end
    end
    Settings:Register('preference.' .. id, idk)
end

function Theme:BuildNew(ty, name, id, basePreset, ops)
    Settings:SetValue('preference.' .. id, name)

    themes[id].options[name] = ops
    themes[id].options[name].isCustom = true
    Settings:SetValue(id, themes[id])
    self:RemoveCache()
end

function Theme:UpdateValue(id, pref, mod, k, v)
    print(id, pref, mod, k, v)
    themes[id].options[pref][mod][k] = v 
    Settings:SetValue(id, themes[id])
end

function Theme:GetOptions(id)
    local preference = Settings:GetValue('preference.' .. id)
    return preference
end

function Theme:RemoveCache()
    cache = {}
end

function Theme:DisableHUD()
    -- DO TO: Remove HUDs
end

Settings:Register('selected.hud', 'hud.momentum', {'hud.flow', 'hud.momentum', 'hud.css', 'hud.simple', "hud.shavit", "hud.stellar"})

Theme:Register("HUD", "hud.flow", "Flow Network (Re-Design)", {
	["Transparent"] = {
		["Colours"] = {
			["Primary Colour"] = Color(44, 44, 44, 170),
			["Secondary Colour"] = Color(38, 38, 38, 170),
			["Accent Colour"] = Color(80, 30, 40, 170),
			["Text Colour"] = color_white,
			["Outlines Colour"] = color_black
		},

		["Toggles"] = {
			["Outlines"] = false,
			["Strafe HUD"] = true,
		}
	},

	["Grey"] = {
		["Colours"] = {
			["Primary Colour"] = Color(44, 44, 44, 240),
			["Secondary Colour"] = Color(38, 38, 38, 255),
			["Accent Colour"] = Color(80, 30, 40, 255),
			["Text Colour"] = color_white,
			["Outlines Colour"] = color_black
		},

		["Toggles"] = {
			["Outlines"] = false,
			["Strafe HUD"] = true
		}
	},

	["White"] = {
		["Colours"] = {
			["Primary Colour"] = Color(200, 200, 200, 255),
			["Secondary Colour"] = Color(255, 255, 255, 255),
			["Accent Colour"] = Color(200, 200, 200, 255),
			["Text Colour"] = color_black,
			["Outlines Colour"] = Color(0, 0, 0, 0)
		},

		["Toggles"] = {
			["Outlines"] = true,
			["Strafe HUD"] = true
		}
	}
})

Theme:Register("HUD", "hud.momentum", "Momentum Mod", {
	["Regular"] = {
		["Colours"] = {
			["Box Colour"] = Color(0, 0, 0, 100),
			["Speed Positive"] = Color(0, 160, 200),
			["Speed Negative"] = Color(200, 0, 0),
			["Text Colour #1"] = color_white,
			["Text Colour #2"] = Color(0, 160, 200)
		},

		["Toggles"] = {
			["Outlines"] = true
		}
	}
})

Theme:Register("HUD", "hud.css", "Counter Strike: Source", {
	["Regular"] = {
		["Colours"] = {
		},

		["Toggles"] = {
		},
	}
})

Theme:Register("HUD", "hud.simple", "Simplistic", {
    ["Regular"] = {
        ["Colours"] = {
            ["Primary Colour"] = Color(47, 47, 47, 255),
            ["Secondary Colour"] = Color(38, 38, 38, 255),
            ["Accent Colour"] = Color(80, 30, 40, 255),
            ["Text Colour"] = color_white,
            ["Outlines Colour"] = color_black
        },
        ["Toggles"] = {
            ["Outlines"] = false,
            ["Strafe HUD"] = true
        }
    }
})

Theme:Register("HUD", "hud.shavit", "Shavit CS:S", {
	["Regular"] = {
		["Colours"] = {
		},

		["Toggles"] = {
		},
	}
})

Theme:Register("HUD", "hud.stellar", "Stellar Mod", {
	["Regular"] = {
		["Colours"] = {
		},

		["Toggles"] = {
		},
	}
})

-- Scoreboard
Theme:Register("Scoreboard", "scoreboard.kawaii", "Kawaii Clan", {
	HasMulti = true,
	["Clear"] = {
		["Colours"] = {
			["Primary Colour"] = Color(38, 38, 38, 100),
			["Secondary Colour"] = Color(44, 44, 44, 100),
			["Tri Colour"] = Color(47, 47, 47, 100),
			["Accent Colour"] = Color(0, 160, 200, 100),
			["Outlines Colour"] = color_black,
			["Text Colour"] = color_white,
			["Text Colour 2"] = Color(200, 200, 200)
		},

		["Toggles"] = {
			["Outlines"] = false
		}
	},

	["Default"] = {
		["Colours"] = {
			["Primary Colour"] = Color(47, 47, 47, 255),
			["Secondary Colour"] = Color(44, 44, 44, 255),
			["Tri Colour"] = Color(38, 38, 38, 255),
			["Accent Colour"] = Color(0, 160, 200),
			["Outlines Colour"] = color_black,
			["Text Colour"] = color_white,
			["Text Colour 2"] = color_black
		},

		["Toggles"] = {
			["Outlines"] = false
		}
	},

    ["Light"] = {
	    ["Colours"] = {
		    ["Primary Colour"] = Color(245, 245, 245),
		    ["Secondary Colour"] = Color(230, 230, 230),
		    ["Tri Colour"] = Color(210, 210, 210),
		    ["Accent Colour"] = Color(0, 160, 200),
		    ["Text Colour"] = color_black,
		    ["Text Colour 2"] = Color(80, 80, 80),
		    ["Outlines Colour"] = Color(0, 0, 0),
		    ["Outlines Colour 2"] = Color(50, 50, 50)
	    },
	    ["Toggles"] = {
		    ["Outlines"] = true
	    }
    }
})

Theme:Register("Zones", "zones.kawaii", "Zones Kawaii Clan", {
    ["Default"] = {
        ["Colours"] = {
            ["Start Zone Colour"] = Color(0, 230, 0, 255),
            ["End Zone Colour"] = Color(180, 0, 0, 255),
            ["Bonus Start Colour"] = Color(127, 140, 141),
            ["Bonus End Colour"] = Color(52, 73, 118),
            ["Placement Colour"] = Color(0, 230, 0, 255)
        },
        ["Toggles"] = {
            ["Outlines"] = false
        }
    },

    ["Kawaii"] = {
        ["Colours"] = {
            ["Start Zone Colour"] = Color(255, 255, 255, 255),
            ["End Zone Colour"] = Color(255, 0, 0, 255),
            ["Bonus Start Colour"] = Color(127, 140, 141, 255),
            ["Bonus End Colour"] = Color(52, 73, 118, 255),
            ["Placement Colour"] = Color(153, 0, 153, 100)
        },
        ["Toggles"] = {
            ["Outlines"] = false
        }
    },

    ["Changing"] = {
        ["Colours"] = {
            ["Start Zone Colour"] = DynamicColors.PanelColor,
            ["End Zone Colour"] = DynamicColors.PanelColor,
            ["Bonus Start Colour"] = DynamicColors.PanelColor,
            ["Bonus End Colour"] = DynamicColors.PanelColor,
            ["Placement Colour"] = DynamicColors.PanelColor
        },
        ["Toggles"] = {
            ["Outlines"] = false
        }
    },

    ["Pink"] = {
        ["Colours"] = {
            ["Start Zone Colour"] = Color(255, 105, 180, 255),
            ["End Zone Colour"] = Color(0, 255, 0, 255),
            ["Bonus Start Colour"] = Color(255, 105, 180, 255),
            ["Bonus End Colour"] = Color(255, 255, 255, 255),
            ["Placement Colour"] = Color(255, 105, 180, 255)
        },
        ["Toggles"] = {
            ["Outlines"] = false
        }
    }
})

Theme:Register("NumberedUI", "nui.css", "Counter Strike: Source", {
	Regular = {
		["Colours"] = {
			["Primary Colour"] = Color(20, 20, 20, 150),
			["Title Colour"] = color_white,
			["Secondary Colour"] = Color(38, 38, 38, 255),
			["Text Colour"] = Color(224, 181, 113, 255),
			["Accent Colour"] = Color(160, 90, 50)
		},

		["Toggles"] = {}
	}
})

Theme:Register("NumberedUI", "nui.kawaii", "Kawaii Clan", {
    ["Dark"] = {
        ["Colours"] = {
            ["Primary Colour"] = Color(40, 40, 40, 255),
            ["Secondary Colour"] = Color(32, 32, 32, 255),
            ["Accent Colour"] = Color(200, 100, 100, 255),
            ["Text Colour"] = color_white,
            ["Title Colour"] = color_white
        },
        ["Toggles"] = {}
    },
})

-- Get preferance
local sel = "nui.kawaii"
local selop = "Dark"
local sel2 = "scoreboard.kawaii"
local selop2 = "Default"
local sel3 = "hud.momentum"
local selop3 = "Dark"

function Theme:GetPreference(id, base)
	if (id == "UI") then 
		return themes["ui.default"].options

	elseif (id == "NumberedUI") then 
		local sel = Settings:GetValue('selected.nui') or "nui.kawaii"
		local selop = Settings:GetValue('preference.' .. sel) or "Dark"
		local theme = themes[sel].options
		return theme[selop], sel

	elseif (id == "Scoreboard") then 
		local sel = Settings:GetValue('selected.scoreboard') or "scoreboard.kawaii"
		local selop = Settings:GetValue('preference.' .. sel) or "Default"
		local theme = themes[sel].options

		if (theme.HasMulti) then 
			return theme[selop], sel
		else
			return theme, sel
		end

	elseif (id == "HUD") then
		local t = Settings:GetValue('selected.hud')
		local thms = Settings:GetValue(t).options
		return thms[self:GetOptions(t) or base], t

	elseif (id == "Zones") then
		local z = "zones.kawaii"
		local preset = Settings:GetValue('preference.' .. z) or "Default"
		local theme = themes[z].options
		return theme[preset], z
	end
end

function Theme:Get(id)
	return Settings:GetValue(id).options
end

-- way to change themes
local function ChangeHUDTheme(ply, cmd, args)
    local newHUD = args[1]

    if not newHUD then
        UTIL:AddMessage("Presets", "Error: Please specify a HUD theme.")
        return
    end
    
    if themes[newHUD] then
        Settings:SetValue('selected.hud', newHUD)
        UTIL:AddMessage("Presets", "HUD theme changed to: " .. newHUD)
    else
        UTIL:AddMessage("Presets", "Invalid HUD theme: " .. tostring(newHUD))
    end
end
concommand.Add("bhop_change_hud", ChangeHUDTheme)

local function ChangeHUDPreset(ply, cmd, args)
    local newPreset = args[1]

    if not newPreset then
        UTIL:AddMessage("Presets", "Error: Please specify a preset.")
        return
    end
    
    local selectedHUD = Settings:GetValue('selected.hud')

    if themes[selectedHUD] and themes[selectedHUD].options[newPreset] then
        Settings:SetValue('preference.' .. selectedHUD, newPreset)
        UTIL:AddMessage("Presets", "Preset for " .. selectedHUD .. " changed to: " .. newPreset)
    else
        UTIL:AddMessage("Presets", "Invalid preset: " .. tostring(newPreset) .. " for HUD: " .. tostring(selectedHUD))
    end
end
concommand.Add("bhop_change_preset", ChangeHUDPreset)

local function ChangeScoreboardTheme(ply, cmd, args)
    local newTheme = args[1]

    if not newTheme then
        UTIL:AddMessage("Presets", "Error: Please specify a scoreboard theme.")
        return
    end

    if themes[newTheme] then
        Settings:SetValue('selected.scoreboard', newTheme)
        UTIL:AddMessage("Presets", "Scoreboard theme changed to: " .. newTheme)
    else
        UTIL:AddMessage("Presets", "Invalid scoreboard theme: " .. tostring(newTheme))
    end
end
concommand.Add("bhop_change_scoreboard", ChangeScoreboardTheme)

local function ChangeScoreboardPreset(ply, cmd, args)
    local newPreset = args[1]

    local selectedScoreboard = Settings:GetValue('selected.scoreboard')

    if themes[selectedScoreboard] and themes[selectedScoreboard].options[newPreset] then
        Settings:SetValue('preference.' .. selectedScoreboard, newPreset)
        UTIL:AddMessage("Presets", "Preset for " .. selectedScoreboard .. " changed to: " .. newPreset)
    else
        UTIL:AddMessage("Presets", "Invalid preset: " .. tostring(newPreset) .. " for scoreboard: " .. tostring(selectedScoreboard))
    end
end
concommand.Add("bhop_change_scoreboard_preset", ChangeScoreboardPreset)

local function ChangeZonesPreset(ply, cmd, args)
    local newPreset = args[1]

    local selectedZones = Settings:GetValue('selected.zones')

    if themes[selectedZones] and themes[selectedZones].options[newPreset] then
        Settings:SetValue('preference.' .. selectedZones, newPreset)
        UTIL:AddMessage("Presets", "Preset for " .. selectedZones .. " changed to: " .. newPreset)
    else
        UTIL:AddMessage("Presets", "Invalid preset: " .. tostring(newPreset) .. " for zones: " .. tostring(selectedZones))
    end
end
concommand.Add("bhop_change_zones_preset", ChangeZonesPreset)

local function ChangeNumberedUITheme(ply, cmd, args)
    local newNUITheme = args[1]

    if not newNUITheme then
        UTIL:AddMessage("Presets", "Error: Please specify a Numbered UI theme (nui.kawaii or nui.css).")
        return
    end

    if themes[newNUITheme] then
        Settings:SetValue('selected.nui', newNUITheme)
        UTIL:AddMessage("Presets", "Numbered UI theme changed to: " .. newNUITheme)
    else
        UTIL:AddMessage("Presets", "Invalid Numbered UI theme: " .. tostring(newNUITheme))
    end
end
concommand.Add("bhop_change_nui", ChangeNumberedUITheme)

local function ChangeNumberedUIPreset(ply, cmd, args)
    local newPreset = args[1]

    local selectedNUI = Settings:GetValue('selected.nui')

    if themes[selectedNUI] and themes[selectedNUI].options[newPreset] then
        Settings:SetValue('preference.' .. selectedNUI, newPreset)
        UTIL:AddMessage("Presets", "Preset for " .. selectedNUI .. " changed to: " .. newPreset)
    else
        UTIL:AddMessage("Presets", "Invalid preset: " .. tostring(newPreset) .. " for Numbered UI: " .. tostring(selectedNUI))
    end
end
concommand.Add("bhop_change_nui_preset", ChangeNumberedUIPreset)