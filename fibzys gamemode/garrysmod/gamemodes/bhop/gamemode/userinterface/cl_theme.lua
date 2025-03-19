THEME_HUD = 1
THEME_SCOREBOARD = 2
THEME_UI = 3
THEME_NUMBEREDUI = 4

theme = {}
theme.settings = {}

theme.themes = {
    [THEME_HUD] = {},
    [THEME_SCOREBOARD] = {},
    [THEME_UI] = {},
    [THEME_NUMBEREDUI] = {}
}

theme.selected = {
    [THEME_HUD] = nil,
    [THEME_SCOREBOARD] = nil,
    [THEME_UI] = nil,
    [THEME_NUMBEREDUI] = nil
}

function theme.registerType(id, name, ...)
    local ops = {...}
    
    theme.settings[id] = {
        selected = nil,
        ops = ops
    }
end 
theme.registerType(THEME_UI, "Main UI",
    {
        schemeInfo = {
            ["Primary"] = "The primary colour of the user interface.",
            ["Secondary"] = "The secondary colour of the user interface.",
            ["Tri"] = "",
            ["Accent"] = "The accent colour of the user interface.\nExample: buttons, selected items etc."
        },

        globals = {
            ["Scale"] = {}
        }
    }
)

theme.registerType(THEME_HUD, "HUD", {
})

theme.registerType(THEME_SCOREBOARD, "Scoreboard")
theme.registerType(THEME_NUMBEREDUI, "Numbered UI")

function theme.registerTheme(type, id, name, settings)
    settings.id = id 

    theme.themes[type][id] = {
        name = name, 
        settings = settings
    }

    if settings.isDefault then 
        theme.selected[type] = id
    end
end 

theme.registerTheme(THEME_UI, "ui.dark", "Dark", 
    {
        isDefault = true,

        scheme = {
            ["Primary"] = Color(47, 47, 47, 255),
            ["Secondary"] = Color(44, 44, 44, 255),
            ["Tri"] = Color(38, 38, 38, 255),
            ["Accent"] = Color(0, 160, 200),
            ["Highlight"] = Color(57, 57, 57, 255),
            ["Main Text"] = color_white,
            ["Secondary Text"] = Color(200, 200, 200),
            ["Outline"] = color_black
        },

        toggles = {
            ["Outlines"] = false
        }
    }
)

theme.registerTheme(THEME_UI, "ui.light", "Light",
    {
        scheme = {
            ["Primary"] = Color(240, 240, 250, 255),
            ["Secondary"] = Color(235, 235, 235, 255),
            ["Tri"] = Color(200, 200, 200, 255),
            ["Accent"] = Color(0, 160, 200),
            ["Highlight"] = Color(40, 40, 40, 255),
            ["Main Text"] = color_black,
            ["Secondary Text"] = Color(20, 20, 20),
            ["Outline"] = color_black
        },

        toggles = {
            ["Outlines"] = false
        }
    }
)

MODULE_MAIN = 1 
MODULE_MAPINFO = 2 
MODULE_KEYS = 3 
MODULE_SSJHUD = 4 
MODULE_STRAFETRAIN = 5 
MODULE_SPECS = 6

theme.registerTheme(THEME_HUD, "hud.momentum", "Momentum",
    {
        base = nil,
        modules = {
        }
    }
)

function theme.callUpdate(type)
    hook.Run("theme.update", type, theme.getTheme(type))
end

function theme.setTheme(type, schemeId) 
    theme.selected[type] = schemeId
    theme.callUpdate(type)
end 

function theme.getTheme(type)
    local selected = theme.selected[type] 
    return theme.themes[type][selected]
end