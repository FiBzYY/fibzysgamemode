--[[

 __      __    _  _  ___  __  __    __    ___  ____ 
(  )    /__\  ( \( )/ __)(  )(  )  /__\  / __)( ___)
 )(__  /(__)\  )  (( (_-. )(__)(  /(__)\( (_-. )__) 
(____)(__)(__)(_)\_)\___/(______)(__)(__)\___/(____) !

]]--

Lang = {
    -- Timer
    TimerFinish = {UTIL.Colour["Timer"], "2;", UTIL.Colour["White"], " beat the map in ", UTIL.Colour["Timer"], "4;", UTIL.Colour["White"], " on ", UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], " placing ", UTIL.Colour["Timer"], "[#6;]", " ", UTIL.Colour["White"], "(", UTIL.Colour["Green"], "5;", UTIL.Colour["White"], ")"},
    WorldRecord = { UTIL.Colour["Timer"], "2;", UTIL.Colour["White"], " beat the map in ", UTIL.Colour["Timer"], "4;", UTIL.Colour["White"], " (", UTIL.Colour["Green"], "WR ", "-5;", UTIL.Colour["White"], ")" },
    FinishingStats = {UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], " had ", UTIL.Colour["Timer"], "2;%", UTIL.Colour["White"], " Sync with ", UTIL.Colour["Timer"], "3;", UTIL.Colour["White"], " Jumps, and ", UTIL.Colour["Timer"], "4;", UTIL.Colour["White"], " Strafes."},

    -- Timer/Style
    StyleEqual = {"Your styles is already set to ", UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], "."},
    StyleChange = {"Your styles is changed to ", UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], "."},
    SegmentSet = {"New ", UTIL.Colour["Timer"], "checkpoint", UTIL.Colour["White"], " set."},
    StopTimer = {"Your timer has been stopped due to the use of ", UTIL.Colour["Red"], "checkpoints", UTIL.Colour["White"], "."},
    TooFast = { "You are moving too fast: ", UTIL.Colour["Red"], "1; u/s", UTIL.Colour["White"], "." },

    DacTimer = {"Warning: using checkpoint will ", UTIL.Colour["Red"], "deactivate", UTIL.Colour["White"], " your timer."},
    styleLimit = {"You can't use those Movements in your selected ", UTIL.Colour["Timer"], "styles", UTIL.Colour["White"], "."},
    styleBonusNone = {"There are no available ", UTIL.Colour["Timer"], "bonus ", UTIL.Colour["White"], "to play."},
    styleBonusFinish = {UTIL.Colour["Timer"], "You ", UTIL.Colour["White"], "finished the Bonus in ", UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], "! ", UTIL.Colour["Green"], "2;"},

    -- Noclip
    NoClip = {"Your timer has been ", UTIL.Colour["Red"], "disabled", UTIL.Colour["White"], " due to ", UTIL.Colour["Timer"], "nocliping", UTIL.Colour["White"], "."},
    NoClipSegment = {"Your noclip has been ", UTIL.Colour["Red"], "disabled", UTIL.Colour["White"], " due to ", UTIL.Colour["Timer"], "Segmented styles", UTIL.Colour["White"], "."},

    -- Spawn
    SetSpawn = {"You have set a ", UTIL.Colour["Timer"], "spawn point", UTIL.Colour["White"], "."},
    styleFreestyle = {"You have ", UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], " Freestyle Zone.", UTIL.Colour["Timer"], "2;"},

    -- SSJTOP
    ssjTop = {
        UTIL.Colour["Green"], "1;",
        UTIL.Colour["White"], " got a ",
        UTIL.Colour["Red"], "2;",
        UTIL.Colour["White"], " SSJ (", UTIL.Colour["Timer"], "3;", UTIL.Colour["White"], ") on the ",
        UTIL.Colour["Red"], "4;",
        UTIL.Colour["White"], " jump!"
    },

    -- Replay
    BotEnter = {UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], " styles Replay has been spawned."},
    BotSlow = {"Your time was not good enough to be displayed by the WR Replay ", UTIL.Colour["Timer"], "(+1;)", UTIL.Colour["White"], "."},
    BotInstRecord = {"You are now being Recorded by the WR Replay", UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], "."},
    BotInstFull = {"You couldn't be Recorded by the Replay because the list is already full!"},
    BotClear = {"You are now no longer being Recorded by the Replay."},
    BotStatus = {"You are currently ", UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], " Recorded by the Replay."},
    BotAlready = {"You are already being Recorded by the WR Replay."},
    BotstyleForce = {"Your ", UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], " run wasn't Recorded because this map is forced to ", UTIL.Colour["Timer"], "2;", " styles."},
    BotSaving = {UTIL.Colour["Timer"], "Replays", UTIL.Colour["White"], " will now be saved, a short period of", UTIL.Colour["Red"], " lag ", UTIL.Colour["White"], "may occur."},
    BotSavingStats = { "A total of ", UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], " replays have been saved taking ", UTIL.Colour["Timer"], "2;", UTIL.Colour["White"], " seconds", UTIL.Colour["White"], "."},
    BotMultiWait = "The Replay must have at least finished playback once before it can be changed.",
    BotMultiInvalid = "The entered styles was invalid or there are no Replays for this styles.",
    BotMultiNone = "There are no WR Replays of different styles to display.",
    BotMultiError = "An error occurred when trying to retrieve data to display. Please wait and try again.",
    BotMultiSame = "The Replay is already playing this styles.",
    BotMultiExclude = "The Replay can not display the Normal styles Run. Check the main Replay for that!",
    BotDetails = "The Replay run was done by 1; [2;] on the 3; styles in a time of 4; at this date: 5;",

    -- Zone
    ZoneStart = {"You are now placing a", UTIL.Colour["Timer"], " Zone", UTIL.Colour["White"], ". Start placing with 1. Press to", UTIL.Colour["Red"], " Set Zone", UTIL.Colour["White"], " Left click to save."},
    ZoneFinish = {"The", UTIL.Colour["Timer"], " Zone ", UTIL.Colour["White"], "has been placed."},
    ZoneCancel = {UTIL.Colour["Timer"], "Zone ", UTIL.Colour["White"], "Placement has been ", UTIL.Colour["Red"], "cancelled", UTIL.Colour["White"], "."},
    ZoneNoEdit = "You are not setting any Zones at the moment.",
    ZoneSpeed = {"You can't leave this ", UTIL.Colour["Timer"], "Zone", UTIL.Colour["White"], " with that ", UTIL.Colour["Red"], "speed", UTIL.Colour["White"], "."},

    -- RTV
    VotePlayer = {UTIL.Colour["Timer"], "1; ", UTIL.Colour["White"], "wants a map change. ", UTIL.Colour["White"], "(", UTIL.Colour["Timer"], "2; 3; required", UTIL.Colour["White"], ")"},
    VoteStart = {"A", UTIL.Colour["Timer"], " vote ", UTIL.Colour["White"], "to change map has started, choose your ", UTIL.Colour["Red"], "maps", UTIL.Colour["White"], "!"},
    VoteExtend = {"The vote has decided that the map is to be extended by ", UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], " minutes!"},
    VoteChange = {"Changing map to ", UTIL.Colour["Server"], "1;", UTIL.Colour["White"], " in ", UTIL.Colour["Server"], "10", UTIL.Colour["White"], " seconds."},
    VoteMissing = {"The map ", UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], " is not available on the server so it can't be played right now."},
    VoteLimit = {"Please wait for", UTIL.Colour["Timer"], " 1; ", UTIL.Colour["White"], "seconds before voting again."},
    VoteAlready = {"You have already Rocked the Vote."},
    VotePeriod = {"A map vote has already started. You cannot vote right now."},
    VoteRevoke = {UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], " has revoked his Rock the Vote. (", UTIL.Colour["Timer"], "2;", UTIL.Colour["White"], " ", UTIL.Colour["Timer"], "3;", UTIL.Colour["White"], " left)"},
    VoteList = {UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], " vote(s) needed to change maps.\nVoted (", UTIL.Colour["Timer"], "2;", UTIL.Colour["White"], "): ", UTIL.Colour["Timer"], "3;", UTIL.Colour["White"], "\nHaven't voted (", UTIL.Colour["Timer"], "4;", UTIL.Colour["White"], "): ", UTIL.Colour["Timer"], "5;", color_white},
    VoteCheck = {"There are ", UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], " ", UTIL.Colour["Timer"], "2;", UTIL.Colour["White"], " needed to change maps."},
    VoteCancelled = {"The vote was cancelled by an Admin, the map will not change.", UTIL.Colour["Timer"], "1;", UTIL.Colour["White"]},
    VoteFailure = {"Something went wrong while trying to change maps. Please ", UTIL.Colour["Timer"], " !rtv ", UTIL.Colour["White"], UTIL.Colour["Timer"], "again."},
    VoteVIPExtend = {"We need help of the VIPs! The extend limit is ", UTIL.Colour["Timer"], "2;", " do you wish to start a vote to extend anyway? Type !extend or !vip extend.", UTIL.Colour["White"], UTIL.Colour["Timer"]},
    RevokeFail = "You can not revoke your vote because you have not Rocked the Vote yet.",

    -- Nominate
    Nomination = {UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], " has nominated ", UTIL.Colour["White"], UTIL.Colour["Timer"], "2;", UTIL.Colour["White"], " to be played next."},
    NominationChange = {UTIL.Colour["Timer"], "1; ", UTIL.Colour["White"], " has changed his nomination from ", UTIL.Colour["Timer"], "2;", UTIL.Colour["White"], " to ", UTIL.Colour["Timer"], "3;"},
    NominationAlready = {"You have already nominated this map!", UTIL.Colour["White"]},
    NominateOnMap = {"You are currently playing this map so you can't nominate it.", UTIL.Colour["White"]},

    -- Map
    MapInfo = {"The map 1; has ", UTIL.Colour["Timer"], "2;", UTIL.Colour["White"], " points (3;) 4;"},
    MapInavailable = {"This map does not exist, not added or not zoned. Please contact an administrator if you feel this is incorrect.", UTIL.Colour["White"]},
    MapPlayed = {"This map has been played ", UTIL.Colour["Timer"], "1; times.", UTIL.Colour["White"]},
    TimeLeft = {"There is ", UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], " left on this map.", UTIL.Colour["White"]},

    -- MISC
    PlayerGunObtain = {"You have obtained a ", UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], "."},
    PlayerGunFound = {"You already have a ", UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], "."},
    PlayerSyncStatus = {"Your sync is ", UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], " being displayed."},
    PlayerTeleport = {"You have been teleported to ", UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], "."},

    -- Spectate
    SpectateRestart = {"You have to be alive in order to reset yourself to the start.", UTIL.Colour["Timer"], "1;", UTIL.Colour["White"]},
    SpectateTargetInvalid = {"You are unable to spectate this player right now."},
    SpectateWeapon = {"You can't obtain a weapon in Spectator.", UTIL.Colour["Timer"], "1;", UTIL.Colour["White"]},

    -- Admin
    AdminInvalidFormat = {"The supplied value ", UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], " is not of the requested type ", UTIL.Colour["Timer"], "2;", UTIL.Colour["White"]},
    AdminMisinterpret = {"The supplied string ", UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], " could not be interpreted. Make sure the format is correct."},
    AdminSetValue = {"The ", UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], " setting has successfully been changed to ", UTIL.Colour["Timer"], "2;", UTIL.Colour["White"]},
    AdminOperationComplete = {"The changes has completed successfully."},
    AdminHierarchy = {"The target's permission is greater than or equal to your permission level, thus you cannot perform this action.", UTIL.Colour["Timer"], "1;", UTIL.Colour["White"]},
    AdminDataFailure = {"The server can't load essential data! If you can, contact an admin to make him identify the issue: ", UTIL.Colour["Timer"], "1;", UTIL.Colour["White"]},
    AdminMissingArgument = {"The ", UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], " argument was missing. It must be of type ", UTIL.Colour["Timer"], "2;", UTIL.Colour["White"], " and have a format of ", UTIL.Colour["Timer"], "3;", UTIL.Colour["White"]},
    AdminErrorCode = {"An error occurred while executing statement: ", UTIL.Colour["Timer"], "1;", UTIL.Colour["White"]},
    AdminPlayerKick = {UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], " has been kicked. (Reason: ", UTIL.Colour["Timer"], "2;", UTIL.Colour["White"], ")"},
    AdminPlayerBan = {UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], " has been banned for ", UTIL.Colour["Timer"], "2;", UTIL.Colour["White"], " minutes. (Reason: ", UTIL.Colour["Timer"], "3;", UTIL.Colour["White"], ")"},

    -- Join/Leave
    Connect = { UTIL.Colour["Server"], "1;", UTIL.Colour["White"], " (", UTIL.Colour["Server"], "2;", UTIL.Colour["White"], ") has connected from ", UTIL.Colour["Server"], "3;", UTIL.Colour["White"], "." },
    Disconnect = {"1; (2;) has disconnected from the server. (Reason: 3;)"},

    -- Other
    AdminChat = {"[", UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], "] ", UTIL.Colour["Timer"], "2;", UTIL.Colour["White"], " says: ", UTIL.Colour["Timer"], "3;", UTIL.Colour["White"]},
    MissingArgument = {"You have to add ", UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], " argument to the command."},
    CommandLimiter = {UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], " Wait a bit before trying again (", UTIL.Colour["Timer"], "2;", UTIL.Colour["White"], "s)."},

    -- MISC
    MiscZoneNotFound = {"The ", UTIL.Colour["Timer"], "1;", UTIL.Colour["White"], " zone couldn't be found."},
    MiscAbout = {"This Gamemode, Bunny Hop Version ", UTIL.Colour["Timer"], BHOP.Version.GM, UTIL.Colour["White"], ", was developed By ",Color(0, 132, 255), "F",Color(85, 172, 255), "i",Color(128, 195, 255), "B",Color(170, 215, 255), "z",Color(213, 235, 255), "Y",color_white, "."}
}

-- Utility function to replace args in text
function replaceArgs(szText, varArgs)
    varArgs = varArgs or {}
    for nParamID, szArg in pairs(varArgs) do
        szText = string.gsub(szText, nParamID .. ";", szArg)
    end
    return szText
end

-- Main Lang.Get function for text in chat
function Lang.Get(self, szIdentifier, varArgs)
    varArgs = varArgs or {}
    local szText = self[szIdentifier]
    if not szText then return "" end

    local function processText(text)
        if type(text) == "string" then
            return replaceArgs(text, varArgs)
        end
        return text
    end

    if type(szText) == "table" then
        local result = {}
        for _, v in ipairs(szText) do
            table.insert(result, processText(v))
        end
        return result
    else
        return processText(szText)
    end
end