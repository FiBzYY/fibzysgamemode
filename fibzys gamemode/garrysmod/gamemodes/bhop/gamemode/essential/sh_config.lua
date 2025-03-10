--[[~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Bunny Hop Configuration

    Author: FiBzY (www.steamcommunity.com/id/fibzy_)
    File: essential/sh_config.lua
    Description: Configuration settings for Bunny Hop gamemode
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~]]--

if not CONFIG_LOADED then
    CONFIG_LOADED = true
    BHOP = BHOP or {}

    -- Gamemode Author (Don't change)
    BHOP.Author = "FiBzY"

    -- Server name
    BHOP.ServerName = GetConVar("hostname"):GetString() -- "fibzy dev"
    BHOP.GameType = "bhop"

    -- Enable live cycling host name
    BHOP.EnableCycle = false

    -- Cycle text
    BHOP.Nametime = 10
    BHOP.ServerNames = {
        "Best server ever 10/10",
         "Smooth gamemode!",
          "FiBzY is the best owner!",
           "Why not click that join button?",
             "Justa who?",
              "FiBzY is cool",
               "100 Tick | RNGFix | Stats",
                "Top custom features",
                 "Top hosting by CroustyCloud",
                  "Efficiency | Gain | Strafes",
                   "Themes | Menu | and more!",
                  "Now using a tick-based timer",
                 "TAS | Segmented | Timescale",
               "Bash | Anti-Cheat",
             "SSJ | SSJTop | LJ",
           "6500+ Maps! | Custom Movement",
          "Crouch Boosting Fix",
        "Strafes on Fleek 2020 remake"
    }

    -- Gamemode version
    BHOP.Version = {
        Engine = "9594",
        GM = "12.62",
        ReleaseDate = "03/09/25",
        LastUpdated = "03/09/25"
    }

    -- Main movement settings
    BHOP.Move = {
        BaseGainsMovement = true,
        GModGainsMovement = true,

        -- Cvar settings
        MaxVel = 320,
        Gravity = 800,
        AirAccel = 1000,
        StepSize = 18,

        -- Speed gain
        SpeedGain = 32.8,
        SpeedGainUnreal = 49.2,
        SpeedCap = 4000,

        -- Jump Height
        JumpHeight = 290,
        JumpScroll = 268.4,
        JumpHeightBase = 301.99337,
        
        -- Walk speed
        WalkSpeed = 250,
        EnableCheckpoints = true,

        -- View hulls
        EyeView = 62.0,
        EyeDuck = 45.0,
        OffsetView = 64.0,
        OffsetDuck = 47.0
    }

    BHOP.Banlist = BHOP.Banlist or {}
    BHOP.IsBanOn = BHOP.IsBanOn or true

    -- Auto ban these IDs
    BHOP.Banlist = {
        ["STEAM_0:1:48688711"] = true,
        ["STEAM_0:0:98765432"] = true,
    }

    -- Enable whitelist
    BHOP.IsWhitelistOn = false

    -- Auto whitelist these IDs
    BHOP.Whitelist = {
        ["STEAM_0:1:48688711"] = true,
        ["STEAM_0:0:87749794"] = false
    }

    -- Zone colors
    BHOP.Zone = {
        HelperColour = Color(255, 255, 0),
        PlacingColour = Color(255, 0, 0),
        StartColor = Color(255, 255, 255),
        EndColor = Color(0, 0, 255),
        BonusColor = Color(255, 165, 0),

        ZoneMaterial = "sprites/jscfixtimer",
        ZoneHeight = 128,
        JumpZoneSpeedCap = 290
    }

    -- RTV colors
    BHOP.RTV = {
        VoteStartedColour = Color(255, 0, 0),
        VoteColourPicked = Color(0, 106, 0),
        VoteSuccessColour = Color(0, 255, 0),
        VoteFailColour = Color(255, 0, 0),
        ExtendColour = Color(0, 132, 255)
    }

    -- Server stuff
    BHOP.Server = {
        AdminLogging = true,
        MapRotationTime = 30,
        WelcomeMessage = "Welcome to " .. BHOP.ServerName .. ".",
        AdminList = {
            ["STEAM_0:1:48688711"] = true
        },
        AFKKickTime = 300
    }

    -- MISC
    BHOP.HUD = {
        HUDColors = {
            SpeedColor = Color(0, 255, 0),
            TimerColor = Color(255, 255, 255),
            BackgroundColor = Color(0, 0, 0, 150)
        },
        ShowSpeedHUD = true,
        Crosshair = {
            Type = "dot",
            Color = Color(0, 255, 0),
            Size = 5
        },
        CustomPlayerModels = {
            "models/player/alyx.mdl",
            "models/player/barney.mdl"
        },
        CSPlayerModels = {
            "models/player/css/ct_sas.mdl",
            "models/player/css/ct_urban.mdl",
        }
    }
end