--[[~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	🏃‍♂️ Bunny Hop Gamemode 🏃‍♂️
		by: fibzy (www.steamcommunity.com/id/fibzy_)

		file: shared.lua
		desc: 🌍 Shared file for the Bunny Hop gamemode.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~]]

-- Dont change
GM.Name = "Bunny Hop"
GM.DisplayName = "Bunny Hop"
GM.Author = "fibzy"
GM.Version = BHOP.Version.GM

--util.PrecacheModel "models/player/lpswat.mdl"

-- Set up nocliping
function GM:PlayerNoClip(ply)
    local practice = ply:GetNWBool("inPractice", false)

    if not practice and SERVER then
		TIMER:Print(ply, Lang:Get("NoClip"))

        TIMER:Disable(ply)
        ply:SetNWBool("inPractice", true) 

        return true
    end

    return practice
end

-- Set up use
function GM:PlayerUse( ply )
	if not ply:Alive() then return false end
	if ply:Team() == TEAM_SPECTATOR then return false end
	if ply:GetMoveType() != MOVETYPE_WALK then return false end
	
	return true
end

-- Teams
team.SetUp(1, "Bunny Hoppers", Color(255, 0, 0), false)
team.SetUp(TEAM_SPECTATOR, "Spectators", Color(150, 150, 150), true)

-- Aux fix jump height
if game.GetMap() == "bhop_aux_a9" then
	BHOP.JumpPower = math.sqrt(2 * 800 * 57)
end

BHDATA = BHDATA or {} 

local hook_Add = hook.Add
local hook_Remove = hook.Remove

-- Remove bad hooks
hook_Add("MouthMoveAnimation", "Optimization", function() return nil end)
hook_Add("GrabEarAnimation", "Optimization", function() return nil end)

function GM:PreRegisterSWEP(swep, class)
	if !swep.Primary then return end
	if !swep.Primary.Recoil then return end

	swep.Primary.Recoil = 0
end

-- Remove bad functions
local MainStand, IdleActivity = ACT_MP_STAND_IDLE, ACT_HL2MP_IDLE
function GM:CalcMainActivity() return MainStand, -1 end
function GM:TranslateActivity() return IdleActivity end
function GM:CreateMove() end

-- Main optimize hook
function BHDATA:Optimize()
    hook_Remove("PlayerTick", "TickWidgets")
    hook_Remove("PreDrawHalos", "PropertiesHover")
end

function GM:PostGamemodeLoaded()
    if BHDATA and BHDATA.Optimize then
        BHDATA:Optimize()
    end
end

-- Showhidden load up

--ShowHidden = ShowHidden or {}
--ShowHidden.Refresh = (ShowHidden.Refresh ~= nil)