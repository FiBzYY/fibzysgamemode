if not FONT_CACHE then
    FONT_CACHE = true
    local MakeFont = surface.CreateFont

    -- Kawaii/JCS
    MakeFont("HUDTimerMed", { size = 20, weight = 4000, font = "Trebuchet24" })
    MakeFont("HUDTimerMedThick", { size = 22, weight = 40000, font = "Trebuchet24" })
    MakeFont("HUDTimerBig", { size = 28, weight = 400, font = "Trebuchet24" })
    MakeFont("HUDTimerUltraBig", { size = 48, weight = 4000, font = "Trebuchet24" })
    MakeFont("HUDTimerKindaUltraBig", { size = 28, weight = 4000, font = "Trebuchet24" })

    -- Flow
    MakeFont("HUDHeaderBig", { size = 44, font = "Coolvetica" })
    MakeFont("HUDHeader", { size = 30, font = "Coolvetica" })
    MakeFont("HUDTitle", { size = 24, font = "Coolvetica" })
    MakeFont("HUDTitleSmall", { size = 20, font = "Coolvetica" })

    MakeFont("HUDFont", { size = 22, weight = 800, font = "Tahoma" })
    MakeFont("HUDFont2", { size = 20, weight = 800, font = "Tahoma" })
    MakeFont("HUDFontSmall", { size = 14, weight = 800, font = "Tahoma" })
    MakeFont("HUDLabelSmall", { size = 12, weight = 800, font = "Tahoma" })
    MakeFont("HUDLabelMed", { size = 15, weight = 550, font = "Verdana" })
    MakeFont("HUDLabel", { size = 17, weight = 550, font = "Verdana" })
    MakeFont("HUDSpecial", { size = 17, weight = 550, font = "Verdana", italic = true })
    MakeFont("HUDSpeed", { size = 16, weight = 800, font = "Tahoma" })
    MakeFont("HUDTimer", { size = 17, weight = 800, font = "Trebuchet24" })
    MakeFont("HUDTimerSmall", { size = 13, weight = 550, font = "Trebuchet24" })
    MakeFont("HUDMessage", { size = 30, weight = 800, font = "Verdana" })
    MakeFont("HUDCounter", { size = 144, weight = 800, font = "Coolvetica" })
    MakeFont("BottomHUDTime", { size = 20, font = "Lato" })
    MakeFont("BottomHUDVelocity", { size = 34, font = "Lato" })

    -- George
    MakeFont("VerdanaUI", { size = 25, weight = 500, font = "Verdana", antialias = true })
    MakeFont("VerdanaUI_B", { size = 18, weight = 500, font = "Verdana", antialias = true })

    -- Stellar
    MakeFont("sm_mod", { size = 19, weight = 600, font = "Arial", antialias = true })

    -- Roblox
    MakeFont("RobloxTop", { size = 18, weight = 700, font = "Verdana", antialias = true })
    MakeFont("RobloxBottom", { size = 20, font = "Verdana" })

    -- Other
    MakeFont("Unity", { font = "Courier New", size = 24, weight = 1000, antialias = false, outline = false })
    MakeFont("UnityBottom", { font = "Courier New", size = 22, weight = 1000, antialias = false, outline = false })

    -- CS:S
    MakeFont("CSS_FONT", { font = "Counter-Strike", size = 54 })
    MakeFont("CSS_ICONS", { font = "csd", size = 100 })
    MakeFont("HUDcsstop2", { size = 40, weight = 1000, antialias = true, font = "FiBuchetMS-Bold" })
    MakeFont("HUDcss", { size = 21, weight = 800, antialias = true, bold = true, font = "Verdana" })
    MakeFont("HUDcssBottomTimer", { size = 21.9, weight = 800, antialias = true, bold = true, font = "Verdana" })
    MakeFont("HUDcssBottom", { size = 21.5, weight = 800, antialias = true, bold = true, font = "Verdana" })
    MakeFont("HUDcss4", { size = 21, weight = 800, antialias = true, bold = true, font = "Verdana" })
    MakeFont("HUDcss2", { size = 21, weight = 700, bold = true, antialias = true, font = "Verdana" })
    MakeFont("CounterStrike", { size = 45, antialias = true, font = "Counter-Strike" })
    MakeFont("HUDSpecHud", { size = 21, weight = 800, antialias = true, bold = true, font = "Verdana" })

    -- Jump Hud
    MakeFont("JHUDMain", { size = 20, weight = 4000, font = "Trebuchet24" })
    MakeFont("JHUDMainSmall", { size = 20, weight = 4000, font = "Trebuchet24" })
    MakeFont("JHUDMainBIG", { size = 48, weight = 4000, font = "Trebuchet24" })
    MakeFont("JHUDMainBIG2", { size = 28, weight = 4000, font = "Trebuchet24" })
    MakeFont("JHUDSPJ", { size = 20, weight = 4000, font = "Roboto" })
    MakeFont("JHUDEFF", { size = 20, weight = 4000, font = "Roboto" })
    MakeFont("JHUDMainKawaii", {font = "Impact", size = 48, weight = 500, antialias = true, shadow = false, extended = true})
    MakeFont("JHUDMainKawaiiSmall", {font = "Impact", size = 32, weight = 500, antialias = true, shadow = false, extended = true})
    MakeFont("ClazJHUD", {font = "Impact", size = 36, weight = 4000})

    -- Other
    MakeFont("HUDTitle", { size = 24, weight = 700, font = "Arial" })
    MakeFont("HUDTitle2Text", { size = 15, weight = 700, font = "Arial" })
    MakeFont("HUDText", { size = 18, weight = 500, font = "Arial" })
    MakeFont("HUDSync", { size = 16, weight = 500, font = "Arial" })
    MakeFont("HUDSideText", { size = 14, weight = 500, font = "Arial" })
    MakeFont("TitleStellar", { font = "Trebuchet MS", size = 18, weight = 500, antialias = true, extended = false })
    MakeFont("RNGFixText", { font = "Trebuchet MS", size = 40, weight = 500, antialias = true, extended = false })

    -- UI
    MakeFont("hud.numberedui.css1", {font = "Roboto", size = 19, weight = 500, antialias = true})
    MakeFont("hud.numberedui.css2", {font = "Roboto", size = 18, weight = 500, antialias = true})
    MakeFont("hud.numberedui.kawaii1", {font = "Roboto", size = 17, weight = 500, antialias = true})

    MakeFont("hud.subinfo", {font = "Tahoma", size = 12, weight = 300, antialias = true})
    MakeFont("hud.zedit.title", {font = "Roboto", size = 28, weight = 0, antialias = true, italic = false})
    MakeFont("hud.zedit", {font = "Roboto", size = 19, weight = 0, antialias = true, italic = false})
    MakeFont("hud.smalltext", {font = "Roboto", size = 14, weight = 0, antialias = true})
    MakeFont("hud.subtitle", {font = "Roboto", size = 18, weight = 0, antialias = true, italic = false})
    MakeFont("hud.subtitleverdana", {font = "Verdana", size = 14, weight = 0, antialias = true, italic = false})
    MakeFont("hud.subinfo2", {font = "Roboto", size = 10, weight = 0, antialias = true})
    MakeFont("hud.simplefont", {font = "Roboto", size = 21, weight = 900, antialias = true})

    MakeFont("hud.title", {font = "coolvetica", size = 20, weight = 100, antialias = true})
    MakeFont("hud.title2.1", {font = "Verdana", size = 14, weight = 0, antialias = true})

    MakeFont("ascii.font", {font = "", size = 9, weight = 0, antialias = true})
    MakeFont("hud.title2", {font = "Roboto", size = 16, weight = 0, antialias = true})
    MakeFont("hud.credits", {font = "Tahoma", size = 12, weight = 100, antialias = true})
    MakeFont("zedit.cam", {font = "Roboto", size = 100, weight = 300, antialias = true})

    MakeFont("ui.mainmenu.close", {font = "Verdana Regular", size = 20, weight = 1000, antialias = true})
    MakeFont("ui.mainmenu.button", {font = "Roboto", size = 18, weight = 500, antialias = true})
    MakeFont("ui.mainmenu.button-bold", {font = "Roboto", size = 18, weight = 600, antialias = true})
    MakeFont("ui.mainmenu.button2", {font = "Roboto", size = 19, weight = 500, antialias = true})
    MakeFont("ui.mainmenu.desc", {font = "Roboto", size = 17, weight = 500, additive = true, antialias = true})
    MakeFont("ui.mainmenu.title", {font = "Roboto", size = 20, weight = 500, antialias = true})
    MakeFont("ui.mainmenu.title2", {font = "Roboto", size = 20, weight = 500, antialias = true})

    -- Chat box
    MakeFont("chatbox.font", { size = 19, weight = 2000, font = "Coolvetica", antialias = true })

    -- Older
    MakeFont( "CustomHeaderBig", { size = 44, font = "Coolvetica" } )
    MakeFont( "CustomHeader", { size = 30, font = "Coolvetica" } )
    MakeFont( "CustomTitle", { size = 24, font = "Coolvetica" } )
    MakeFont( "CustomTitleSmall", { size = 20, font = "Coolvetica" } ) 

    MakeFont( "CustomFont", { size = 22, weight = 800, font = "Tahoma" } )
    MakeFont( "CustomFontSmall", { size = 14, weight = 800, font = "Tahoma" } )
    MakeFont( "CustomLabelSmall", { size = 12, weight = 800, font = "Tahoma" } )
    MakeFont( "CustomLabelMed", { size = 15, weight = 550, font = "Verdana" } )
    MakeFont( "CustomLabel", { size = 17, weight = 550, font = "Verdana" } )

    MakeFont( "CustomSpecial", { size = 17, weight = 550, font = "Verdana", italic = true } )
    MakeFont( "CustomSpeed", { size = 16, weight = 800, font = "Tahoma" } )
    MakeFont( "CustomTimer", { size = 17, weight = 800, font = "Trebuchet24" } )
    MakeFont( "CustomMessage", { size = 30, weight = 800, font = "Verdana" } )
    MakeFont( "CustomCounter", { size = 144, weight = 800, font = "Coolvetica" } )

    -- New
    MakeFont("Bhop.Time", {font = "Default", size = 15, weight = 100})
    MakeFont("Bhop.Player", {font = "Default", size = 12, weight = 100})
    MakeFont("Bhop.Rank", {font = "Default", size = 12, weight = 100})
    MakeFont("Bhop.Vel", {font = "Default", size = 14, weight = 500, italic = true})
    MakeFont("Bhop.PB", {font = "Default", size = 11, weight = 500})

    -- Menu
    MakeFont("TopNavFont", {font = "Roboto", size = 19, weight = 800, antialias = true})
    MakeFont("ToggleButtonFont", {font = "Roboto", size = 14, weight = 800, antialias = true})
    MakeFont("ToggleButtonFontTitle", {font = "Roboto", size = 16, weight = 800, antialias = true})
    MakeFont("SmallTextFont", {font = "Roboto", size = 17, weight = 800, antialias = true})
end