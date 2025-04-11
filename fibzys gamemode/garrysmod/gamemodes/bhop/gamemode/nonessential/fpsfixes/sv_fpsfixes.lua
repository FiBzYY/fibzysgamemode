local hook_Add, hook_Remove = hook.Add, hook.Remove

local function isNonEssentialGlobal(key)
    local nonEssentialGlobals = {
        ["DMG_FALL"] = true, ["ParticleEffect"] = true, ["predictionFactor"] = true, ["BOUNDS_COLLISION"] = true,
        ["CreatePhysCollidesFromModel"] = true, ["CreatePhysCollideBox"] = true, ["SND_DELAY"] = true,
        ["MAT_FOLIAGE"] = true, ["RENDERMODE_GLOW"] = true, ["SetGlobal2Var"] = true, ["GetGlobal2Entity"] = true,
        ["ParticleEffectAttach"] = true, ["PrecacheParticleSystem"] = true, ["FL_FROZEN"] = true,
        ["MASK_BLOCKLOS_AND_NPCS"] = true, ["RENDERMODE_NONE"] = true, ["kRenderFxPulseSlow"] = true,
        ["RENDERGROUP_OPAQUE_BRUSH"] = true, ["RENDERMODE_WORLDGLOW"] = true, ["FSASYNC_ERR_READING"] = true,
        ["TRANSMIT_ALWAYS"] = true, ["PrecacheSentenceGroup"] = true, ["PrecacheSentenceFile"] = true,
        ["PrecacheScene"] = true, ["ACT_MP_DOUBLEJUMP"] = true, ["GetPredictionPlayer"] = true, ["SuppressHostEvents"] = true,
        ["BLOOD_COLOR_MECH"] = true, ["ACT_HL2MP_JUMP_SLAM"] = true, ["ACT_GET_DOWN_STAND"] = true,
        ["GetGlobal2Vector"] = true, ["ACT_VM_DEPLOY_5"] = true, ["KEY_PAD_PLUS"] = true, ["BUTTON_CODE_NONE"] = true,
        ["ACT_MP_CROUCHWALK_MELEE"] = true, ["SOUND_READINESS_LOW"] = true, ["ACT_GET_UP_STAND"] = true,
        ["DMG_BUCKSHOT"] = true, ["ACT_MELEE_ATTACK2"] = true, ["ACT_DOD_PRONE_ZOOM_PSCHRECK"] = true,
        ["ACT_DOD_RUN_AIM_GREN_STICK"] = true, ["PLAYERANIMEVENT_CUSTOM_SEQUENCE"] = true, ["KEY_7"] = true,
        ["COLLISION_GROUP_PUSHAWAY"] = true, ["ACT_SWIM"] = true,
        ["ACT_HL2MP_WALK_CROUCH_KNIFE"] = true, ["MAT_EGGSHELL"] = true, ["JOYSTICK_FIRST"] = true,
        ["FL_STATICPROP"] = true, ["ACT_HL2MP_JUMP_SCARED"] = true, ["SOUND_DANGER"] = true,
        ["FSASYNC_STATUS_ABORTED"] = true, ["FORCE_VECTOR"] = true, ["TRACER_BEAM"] = true,
        ["ACT_DOD_CROUCH_IDLE_MP44"] = true, ["EFL_NO_ROTORWASH_PUSH"] = true, ["ACT_GRENADE_ROLL"] = true,
        ["ACT_SLAM_THROW_TO_STICKWALL_ND"] = true, ["SOUND_CONTEXT_COMBINE_ONLY"] = true,
        ["ACT_MP_STAND_PDA"] = true, ["ACT_HL2MP_WALK_GRENADE"] = true, ["ACT_DOD_RELOAD_GARAND"] = true,
        ["HITGROUP_RIGHTARM"] = true, ["BOX_FRONT"] = true, ["SCHED_ALERT_STAND"] = true,
        ["EFL_SERVER_ONLY"] = true, ["D_ER"] = true, ["NUM_AI_CLASSES"] = true, ["CLASS_INSECT"] = true,
        ["ACT_DOD_PRONE_AIM_MP40"] = true, ["ACT_MP_AIRWALK_MELEE"] = true, ["CLASS_ALIEN_PREY"] = true,
        ["CLASS_ALIEN_MONSTER"] = true, ["CLASS_MACHINE"] = true, ["SCHED_PATROL_RUN"] = true,
        ["CLASS_COMBINE_HUNTER"] = true, ["CLASS_EARTH_FAUNA"] = true, ["CLASS_FLARE"] = true,
        ["CLASS_VORTIGAUNT"] = true, ["ACT_DOD_RUN_IDLE_PISTOL"] = true, ["ACT_DOD_PRONE_ZOOM_RIFLE"] = true,
        ["ACT_READINESS_PISTOL_AGITATED_TO_STIMULATED"] = true, ["CLASS_HEADCRAB"] = true,
        ["ACT_DOD_WALK_ZOOM_PSCHRECK"] = true, ["ACT_STRAFE_LEFT"] = true, ["RunString"] = true,
        ["ACT_HL2MP_SWIM_IDLE_CROSSBOW"] = true, ["ACT_VM_IDLE_DEPLOYED_1"] = true,
        ["ACT_SLAM_THROW_DRAW"] = true, ["ACT_DOD_WALK_AIM_BOLT"] = true, ["ACT_VM_USABLE_TO_UNUSABLE"] = true,
        ["CLASS_BULLSEYE"] = true, ["CLASS_ANTLION"] = true, ["ACT_DOD_HS_IDLE_KNIFE"] = true,
        ["CLASS_PLAYER"] = true, ["ACT_DIEBACKWARD"] = true, ["SOUND_MOVE_AWAY"] = true,
        ["HULL_LARGE_CENTERED"] = true, ["DMG_SONIC"] = true, ["HULL_WIDE_SHORT"] = true, ["D_LI"] = true,
        ["HULL_SMALL_CENTERED"] = true, ["HULL_HUMAN"] = true, ["CAP_AIM_GUN"] = true, ["PLAYERANIMEVENT_FLINCH_CHEST"] = true,
        ["ACT_VM_RELOAD2"] = true, ["CAP_NO_HIT_PLAYER"] = true, ["ACT_GESTURE_RANGE_ATTACK_AR1"] = true,
        ["CAP_ANIMATEDFACE"] = true, ["ACT_HL2MP_RUN_RPG"] = true, ["CAP_MOVE_SHOOT"] = true, ["CAP_MOVE_CRAWL"] = true,
        ["ACT_HL2MP_SIT_SLAM"] = true, ["ACT_DOD_CROUCHWALK_ZOOMED"] = true,
        ["LAST_SHARED_SCHEDULE"] = true, ["SCHED_SLEEP"] = true, ["FCVAR_DONTRECORD"] = true,
        ["SCHED_FLINCH_PHYSICS"] = true, ["MOVETYPE_VPHYSICS"] = true, ["SCHED_INTERACTION_MOVE_TO_PARTNER"] = true,
        ["ACT_DOD_WALK_AIM_GREN_FRAG"] = true, ["NPC_STATE_NONE"] = true, ["SCHED_FAIL_NOSTOP"] = true,
        ["ACT_GESTURE_TURN_LEFT"] = true, ["SCHED_DROPSHIP_DUSTOFF"] = true, ["FL_ANIMDUCKING"] = false, -- bug error
        ["ACT_ROLL_LEFT"] = true, ["SCHED_FALL_TO_GROUND"] = true, ["ACT_HOP"] = true, ["ACT_WALK_PACKAGE"] = true,
        ["SCHED_PATROL_WALK"] = true, ["SCHED_FORCED_GO_RUN"] = true, ["SCHED_MOVE_AWAY_END"] = true,
        ["ACT_SIGNAL_LEFT"] = true, ["SCHED_MOVE_AWAY_FAIL"] = true, ["ACT_GESTURE_RANGE_ATTACK_SMG1_LOW"] = true,
        ["SCHED_WAIT_FOR_SPEAK_FINISH"] = true, ["ACT_DIE_LEFTSIDE"] = true, ["SCHED_NEW_WEAPON_CHEAT"] = true,
        ["saverestore"] = true, ["ACT_MP_RELOAD_SWIM_PRIMARY_LOOP"] = true,
        ["ACT_SLAM_STICKWALL_DRAW"] = true, ["ACT_VM_DEPLOYED_FIRE"] = true, ["SCHED_SCRIPTED_CUSTOM_MOVE"] = true,
        ["SCHED_WAIT_FOR_SCRIPT"] = true, ["SCHED_DIE"] = true, ["SCHED_AMBUSH"] = true,
        ["ACT_DOD_STAND_IDLE_PISTOL"] = true, ["ACT_IDLE_PACKAGE"] = true, ["ACT_VM_IDLE_4"] = true,
        ["SCHED_RELOAD"] = true, ["SCHED_SPECIAL_ATTACK2"] = true, ["SCHED_SPECIAL_ATTACK1"] = true,
        ["SCHED_RANGE_ATTACK1"] = true, ["SCHED_MELEE_ATTACK2"] = true, ["ACT_HL2MP_WALK_AR2"] = true,
        ["SCHED_FAIL_ESTABLISH_LINE_OF_FIRE"] = true, ["ACT_VM_IRECOIL1"] = true, ["SendUserMessage"] = true,
        ["SCHED_FAIL_TAKE_COVER"] = true, ["SCHED_TAKE_COVER_FROM_ORIGIN"] = true,
        ["SCHED_FLEE_FROM_BEST_SOUND"] = true, ["SCHED_TAKE_COVER_FROM_ENEMY"] = true,
        ["ACT_HL2MP_WALK_ZOMBIE_04"] = true, ["SCHED_BACK_AWAY_FROM_SAVE_POSITION"] = true,
        ["widgets"] = false, ["SCHED_SMALL_FLINCH"] = true, ["DMG_DROWNRECOVER"] = true, ["ACT_VM_UNUSABLE"] = true, -- widgets
        ["ACT_DOD_STAND_AIM_BAZOOKA"] = true, ["ACT_HL2MP_GESTURE_RELOAD_SHOTGUN"] = true, ["MAT_DIRT"] = true,
        ["SCHED_TARGET_FACE"] = true, ["SOLID_OBB_YAW"] = true, ["SCHED_VICTORY_DANCE"] = true,
        ["SCHED_COMBAT_WALK"] = true, ["SCHED_COMBAT_STAND"] = true, ["SCHED_FEAR_FACE"] = true,
        ["CT_DOWNTRODDEN"] = true, ["ACT_OVERLAY_GRENADEREADY"] = true, ["TYPE_MATERIAL"] = true,
        ["ACT_VM_DRAWFULL_M203"] = true, ["ACT_DOD_CROUCH_IDLE_MP40"] = true, ["ACT_HL2MP_IDLE_GRENADE"] = true,
        ["SCHED_ALERT_REACT_TO_COMBAT_SOUND"] = true, ["SCHED_ALERT_FACE"] = true, ["ACT_MP_SWIM_SECONDARY"] = true,
        ["ACT_ROLL_RIGHT"] = true, ["SOUND_CONTEXT_EXCLUDE_COMBINE"] = true,
        ["EFL_DORMANT"] = true, ["FVPHYSICS_PART_OF_RAGDOLL"] = true, ["ACT_VM_DEPLOYED_IRON_IDLE"] = true, 
        ["ai_schedule"] = true, ["ACT_MP_CROUCH_PDA"] = true, ["PLAYERANIMEVENT_FLINCH_LEFTLEG"] = true, 
        ["ACT_MP_ATTACK_CROUCH_GRENADE_PRIMARY"] = true, ["KEY_XBUTTON_RIGHT_SHOULDER"] = true, 
        ["ACT_DOD_RUN_ZOOM_BOLT"] = true, ["ACT_HL2MP_FIST_BLOCK"] = true, ["ACT_DOD_RUN_IDLE_GREASE"] = true, 
        ["SIM_GLOBAL_ACCELERATION"] = true, ["MAT_CONCRETE"] = true, ["ACT_DOD_WALK_AIM_30CAL"] = true, 
        ["KEY_LWIN"] = true, ["CLASS_HUMAN_PASSIVE"] = true, ["ACT_MP_ATTACK_CROUCH_GRENADE_SECONDARY"] = true, 
        ["ACT_SLAM_THROW_ND_IDLE"] = true, ["ACT_MP_GESTURE_FLINCH_RIGHTLEG"] = true, ["ACT_TRIPMINE_WORLD"] = true, 
        ["ACT_ZOMBIE_CLIMB_END"] = true, ["ACT_HL2MP_WALK_CROUCH_SUITCASE"] = true, ["ACT_HL2MP_IDLE_MELEE"] = true, 
        ["CHAN_WEAPON"] = true, ["ACT_VM_DEPLOYED_IN"] = true, ["ACT_DOD_HS_IDLE_30CAL"] = true, 
        ["ACT_DOD_CROUCHWALK_IDLE_MG"] = true, ["EFL_DIRTY_ABSANGVELOCITY"] = true, ["ACT_DOD_RELOAD_DEPLOYED_BAR"] = true, 
        ["ACT_LAND"] = false, ["ACT_WALK_AIM_STEALTH"] = false, ["KEY_ESCAPE"] = false, -- chat box
        ["ACT_MP_GESTURE_FLINCH_LEFTARM"] = true, ["ACT_HL2MP_JUMP_ANGRY"] = true, ["ACT_DOD_RELOAD_DEPLOYED"] = true, 
        ["SURF_HINT"] = true, ["ACT_VM_READY_M203"] = true, ["ACT_WALK_CROUCH_RPG"] = true, 
        ["MASK_SHOT_HULL"] = true, ["OBS_MODE_NONE"] = false, ["DMG_POISON"] = true, 
        ["MAT_TILE"] = true, ["ACT_VM_IDLE_TO_LOWERED"] = true, ["ACT_VM_IDLE_8"] = true, 
        ["CAP_FRIENDLY_DMG_IMMUNE"] = true, ["ACT_DOD_CROUCHWALK_AIM_BAR"] = true, ["ACT_HL2MP_WALK_RPG"] = true, 
        ["ACT_MP_GESTURE_FLINCH_STOMACH"] = true, ["ACT_HL2MP_JUMP_MELEE"] = true, ["EFL_DONTBLOCKLOS"] = true, 
        ["FL_CLIENT"] = true, ["ACT_DOD_WALK_IDLE_PSCHRECK"] = true, ["ACT_HL2MP_IDLE_CROUCH_RPG"] = true, 
        ["ACT_DOD_RELOAD_PRONE_DEPLOYED_MG34"] = true, ["ACT_RELOAD_PISTOL_LOW"] = true, 
        ["ACT_DOD_PRIMARYATTACK_PRONE_SPADE"] = true, ["ACT_VM_RELOAD_END_EMPTY"] = true, 
        ["ACT_DIE_RIGHTSIDE"] = true, ["EF_NODRAW"] = false, ["FL_DISSOLVING"] = true, -- showhidden
        ["ACT_VM_UNDEPLOY_2"] = true, ["ACT_VM_RELOAD_EMPTY"] = true, ["isangle"] = true, 
        ["ACT_HL2MP_JUMP_CAMERA"] = true, ["ACT_DOD_RELOAD_PRONE_PISTOL"] = true, ["EFL_DIRTY_ABSVELOCITY"] = false, 
        ["ACT_SMG2_TOAUTO"] = true, ["ACT_VM_PRIMARYATTACK_3"] = true, ["ACT_GESTURE_RANGE_ATTACK_PISTOL_LOW"] = true, 
        ["ACT_MP_VCD"] = true, ["CT_DEFAULT"] = true, ["ACT_HL2MP_JUMP_ZOMBIE"] = true, 
        ["LAST_VISIBLE_CONTENTS"] = true, ["FL_GRENADE"] = true, ["ACT_DOD_SPRINT_IDLE_RIFLE"] = true, 
        ["ACT_OBJ_IDLE"] = true, ["SIM_LOCAL_FORCE"] = true, ["BONE_USED_MASK"] = true, 
        ["ACT_MP_ATTACK_CROUCH_GRENADE"] = true, ["CHAN_VOICE_BASE"] = true, ["ACT_SLAM_TRIPMINE_TO_THROW_ND"] = true, 
        ["ACT_DOD_STAND_AIM_C96"] = true, ["ACT_RANGE_AIM_AR2_LOW"] = true, ["KEY_P"] = true, 
        ["SCHED_MOVE_TO_WEAPON_RANGE"] = true, ["ACT_SLAM_TRIPMINE_IDLE"] = true, ["ACT_PLAYER_RUN_FIRE"] = true, 
        ["KEY_DOWN"] = true, ["CAP_MOVE_SWIM"] = true, ["ACT_HL2MP_WALK_CROUCH_SCARED"] = true, 
        ["ACT_MP_ATTACK_AIRWALK_SECONDARYFIRE"] = true, ["ACT_HL2MP_WALK_CROUCH_ZOMBIE_03"] = true, 
        ["ACT_DOD_CROUCH_IDLE_TNT"] = true, ["SCHED_CHASE_ENEMY_FAILED"] = true, ["ACT_DOD_RUN_IDLE_C96"] = true, 
        ["ACT_DOD_RELOAD_DEPLOYED_FG42"] = true, ["KEY_UP"] = false, ["KEY_XBUTTON_Y"] = true, 
        ["ACT_VM_DEPLOYED_IRON_IN"] = true, ["ACT_RELOAD_PISTOL"] = true, ["ACT_SLAM_THROW_TO_TRIPMINE_ND"] = true, 
        ["ACT_DOD_CROUCH_IDLE"] = true, ["ACT_DO_NOT_DISTURB"] = true, ["SURF_BUMPLIGHT"] = true, 
        ["ACT_DOD_PRONE_AIM_MG"] = true, ["ACT_HL2MP_ZOMBIE_SLUMP_ALT_IDLE"] = true, 
        ["ACT_MP_ATTACK_SWIM_SECONDARYFIRE"] = true, ["EFL_NO_DAMAGE_FORCES"] = true, ["ACT_DOD_WALK_AIM_RIFLE"] = true, 
        ["ACT_VM_RELOADEMPTY"] = true, ["ACT_IDLE_RPG_RELAXED"] = true, ["BUTTON_CODE_COUNT"] = true, 
        ["SF_PHYSBOX_NEVER_PUNT"] = true, ["ACT_VM_IIDLE_M203"] = true, ["ACT_DOD_RUN_IDLE_30CAL"] = true, 
        ["EFL_NO_GAME_PHYSICS_SIMULATION"] = true, ["ACT_MP_JUMP_LAND_SECONDARY"] = true, 
        ["ACT_HL2MP_WALK_CROUCH_FIST"] = true, ["DMG_NEVERGIB"] = true, ["ACT_DOD_PRONEWALK_IDLE_BOLT"] = true, 
        ["EFL_DONTWALKON"] = true, ["ACT_SIGNAL2"] = true, ["ACT_MP_GESTURE_FLINCH"] = true, 
        ["ACT_HL2MP_IDLE_DUEL"] = true, ["SF_LUA_RUN_ON_SPAWN"] = true, ["ACT_VM_LOWERED_TO_IDLE"] = true, 
        ["ACT_VM_IDLE_DEPLOYED"] = true, ["ACT_DOD_RELOAD_PRONE"] = true, ["GAMEMODE_NAME"] = true, ["MASK_ALL"] = true, 
        ["ACT_HL2MP_SWIM_IDLE_SLAM"] = true, ["GAMEMODE"] = true, ["ACT_MP_GRENADE1_DRAW"] = true, 
        ["IN_ALT1"] = true, ["ACT_VM_UNDEPLOY_1"] = true, ["AddChatCommands"] = true, ["ACT_DIE_HEADSHOT"] = true, 
        ["SURF_LIGHT"] = true, ["DMG_DISSOLVE"] = true, ["ACT_DEEPIDLE4"] = true, 
        ["cj"] = true, ["KEY_PAD_9"] = true, ["ACT_HL2MP_WALK_SUITCASE"] = true, ["ACT_DOD_CROUCH_IDLE_BAZOOKA"] = true, 
        ["KEY_TAB"] = true, ["StateArchive"] = true, ["ACT_WALK_CARRY"] = true, 
        ["CLASS_COMBINE_GUNSHIP"] = true, ["CLASS_HACKED_ROLLERMINE"] = true, ["ACT_GESTURE_FLINCH_LEFTARM"] = true, 
        ["ACT_CROSSBOW_FIDGET_UNLOADED"] = true, ["ACT_DOD_PRONEWALK_IDLE_PISTOL"] = true, 
        ["ACT_DOD_RELOAD_PRONE_C96"] = true, ["ACT_BUSY_SIT_GROUND"] = true, ["SCHED_INVESTIGATE_SOUND"] = true, 
        ["ACT_FLINCH_BACK"] = true, ["ACT_DOD_RELOAD_CROUCH_MP44"] = true, ["cache_player_names"] = true, 
        ["RandomPairs"] = false, ["ACT_HL2MP_SIT_MELEE"] = true, ["FVPHYSICS_CONSTRAINT_STATIC"] = true, -- RandomPairs
        ["ACT_DOD_RELOAD_CROUCH_BOLT"] = true,
        ["FL_NPC"] = true, 
        ["DUCK_MIN_DUCKSPEED"] = true, ["BONE_SCREEN_ALIGN_SPHERE"] = true, ["AIR_SPEED_CAP"] = true, 
        ["IN_USE"] = false, ["kRenderFxEnvRain"] = true, ["CLASS_CITIZEN_PASSIVE"] = true, ["CreateSound"] = true, -- use
        ["TimedSin"] = true, ["ACT_DOD_RELOAD_M1CARBINE"] = true, ["KEY_PAD_DECIMAL"] = true, 
        ["FSOLID_CUSTOMRAYTEST"] = true, ["EFL_NO_WATER_VELOCITY_CHANGE"] = true, 
        ["ACT_DOD_WALK_IDLE_BOLT"] = true, ["CONTENTS_CURRENT_180"] = true, ["PlayerJumps"] = false, 
        ["ACT_DOD_CROUCHWALK_IDLE_PSCHRECK"] = true, ["ACT_HL2MP_RUN_GRENADE"] = true, ["EF_PARENT_ANIMATES"] = true, 
        ["ACT_MP_RUN_PRIMARY"] = true, ["CFindMetaTable"] = true, ["ACT_HL2MP_SWIM_IDLE_AR2"] = true, 
        ["ACT_MP_RELOAD_SWIM_PRIMARY_END"] = true, ["SCHED_SWITCH_TO_PENDING_WEAPON"] = true, ["SURF_HITBOX"] = true, 
        ["ACT_WALK_RPG"] = true, ["DEATH_NOTICE_FRIENDLY_VICTIM"] = true, ["ACT_DOD_RUN_IDLE_BAZOOKA"] = true, 
        ["TauntCamera"] = true, ["motionsensor"] = true, ["ACT_RAPPEL_LOOP"] = true, 
        ["ACT_DOD_RELOAD_RIFLE"] = true, ["ACT_SPECIAL_ATTACK2"] = true, 
        ["ACT_HL2MP_RUN_SHOTGUN"] = true, ["ACT_SLAM_STICKWALL_ND_IDLE"] = true, ["SortedPairsByMemberValue"] = false, 
        ["COLLISION_GROUP_NPC"] = true, ["ACT_DOD_SPRINT_AIM_GREN_FRAG"] = true, ["ALL_VISIBLE_CONTENTS"] = true, 
        ["SortedPairsByValue"] = false, ["ACT_DOD_CROUCH_AIM_KNIFE"] = true, ["FSASYNC_ERR_ALIGNMENT"] = true, 
        ["SortedPairs"] = false, ["DTVar_ReceiveProxyGL"] = true, ["ACT_SIGNAL_GROUP"] = true, ["FL_DONTTOUCH"] = true, -- barmenu
        ["AIMR_OK"] = true, ["EFL_IN_SKYBOX"] = true, ["utf8"] = true, ["FCVAR_USERINFO"] = false, 
        ["cookie"] = false, ["ACT_MP_JUMP_LAND_PDA"] = true, ["HULL_LARGE"] = true, ["SCHED_BIG_FLINCH"] = true, 
        ["GetGlobal2Float"] = true, ["ACT_HL2MP_JUMP_MAGIC"] = true,
        ["usermessage"] = true, ["SCHED_RUN_FROM_ENEMY_FALLBACK"] = true, ["construct"] = true, 
        ["BOX_LEFT"] = true, ["cleanup"] = true, ["undo"] = true,
        ["numpad"] = true, ["ACT_IDLE_SHOTGUN_AGITATED"] = true,
        ["SCHED_NEW_WEAPON"] = true, ["ACT_GESTURE_TURN_LEFT45"] = true, ["ACT_VM_CRAWL_EMPTY"] = true, 
        ["ACT_GESTURE_FLINCH_CHEST"] = true, ["AddConsoleCommand"] = true, 
        ["EF_NOFLASHLIGHT"] = true, ["ACT_RUN_RELAXED"] = false, ["MAT_CLIP"] = true, ["ACT_DOD_PRONE_AIM_GREASE"] = true, 
        ["STEPSOUNDTIME_NORMAL"] = true, ["RENDERMODE_NORMAL"] = false,
        ["CONTENTS_EMPTY"] = true, ["KEY_A"] = true, ["GetConVarString"] = false, ["Add_NPC_Class"] = true,  -- showhidden
        ["CLASS_SCANNER"] = true, ["ACT_MP_RELOAD_CROUCH_PRIMARY"] = true, ["Either"] = true, 
        ["ACT_SIGNAL_ADVANCE"] = true, ["IsFriendEntityName"] = true, ["MASK_VISIBLE"] = true, 
        ["ACT_HL2MP_SWIM_IDLE_REVOLVER"] = true, ["IsEnemyEntityName"] = true, ["Serialize"] = true, 
        ["UTIL_IsUselessModel"] = true, ["ServerLog"] = true, ["CAP_AUTO_DOORS"] = true, ["IsUselessModel"] = true, 
        ["PLAYERANIMEVENT_FLINCH_LEFTARM"] = true, ["SafeRemoveEntityDelayed"] = true, ["SafeRemoveEntity"] = true, 
        ["ACT_DOD_CROUCH_AIM_TOMMY"] = true, ["FORCE_COLOR"] = true, 
        ["ACT_SLAM_STICKWALL_TO_THROW_ND"] = true, ["FORCE_BOOL"] = true, ["ACT_MP_ATTACK_SWIM_GRENADE_BUILDING"] = true, 
        ["FORCE_NUMBER"] = true, ["FORCE_STRING"] = true, ["ACT_IDLE_ANGRY_PISTOL"] = false, ["EFL_KILLME"] = true, 
        ["ACT_VM_SHOOTLAST"] = true, ["angle_zero"] = true, ["ACT_DOD_CROUCHWALK_AIM"] = true, 
        ["ACT_VM_DEPLOYED_DRYFIRE"] = true, ["ACT_DOD_PRONEWALK_IDLE_GREASE"] = true, 
        ["vector_up"] = true, ["ACT_HL2MP_GESTURE_RELOAD_SUITCASE"] = true, 
        ["vector_origin"] = false, ["Particle"] = true, ["ACT_VM_UNDEPLOY_8"] = true, 
        ["ColorRand"] = true, ["AngleRand"] = true, ["VectorRand"] = true, ["SCHED_NONE"] = true, 
        ["ACT_DOD_HS_IDLE_BAZOOKA"] = true, ["COLLISION_GROUP_NPC_SCRIPTED"] = true,
        ["ACT_DOD_SPRINT_IDLE_MG"] = true, ["ACT_HL2MP_SWIM_IDLE_PASSIVE"] = true, 
        ["ACT_MP_SECONDARY_GRENADE2_DRAW"] = true, ["ACT_GESTURE_RANGE_ATTACK1"] = false, ["ACT_USE"] = true, 
        ["ACT_VM_DRYFIRE_SILENCED"] = false, -- usp
        ["EFL_IS_BEING_LIFTED_BY_BARNACLE"] = true, ["KEY_9"] = true, ["ai"] = true, 
        ["SCHED_BACK_AWAY_FROM_ENEMY"] = true, ["COLLISION_GROUP_INTERACTIVE_DEBRIS"] = true, 
        ["ACT_MP_ATTACK_SWIM_PRIMARYFIRE"] = true, ["ACT_DOD_PRIMARYATTACK_KNIFE"] = true, ["ACT_DIEFORWARD"] = true, 
        ["sound"] = true, ["ACT_DOD_HS_CROUCH_30CAL"] = true, ["physenv"] = true, ["ACT_RANGE_ATTACK_AR2"] = true, 
        ["FSASYNC_ERR_RETRY_LATER"] = true, ["ACT_SIGNAL1"] = true, ["hammer"] = true, -- ssjtop
        ["OBS_MODE_ROAMING"] = false, ["system"] = false, ["effects"] = true, ["ACT_DOD_HS_CROUCH_K98"] = true, 
        ["ACT_MP_GESTURE_VC_FINGERPOINT_SECONDARY"] = true,
        ["MOVECOLLIDE_DEFAULT"] = true, ["rawequal"] = true, ["ACT_GMOD_SHOWOFF_DUCK_01"] = true, 
        ["CONTENTS_CURRENT_UP"] = true, ["kRenderFxStrobeFast"] = true, ["debugoverlay"] = true, 
        ["GetHostName"] = false, ["ACT_DOD_RELOAD_CROUCH_RIFLE"] = true, ["EFL_DIRTY_SPATIAL_PARTITION"] = true, 
        ["ACT_MP_ATTACK_SWIM_PREFIRE"] = true, ["PATTACH_CUSTOMORIGIN"] = true,
        ["umsg"] = true, ["CAP_USE_WEAPONS"] = true, ["BONE_SCREEN_ALIGN_CYLINDER"] = true, ["SCHED_RUN_FROM_ENEMY"] = true, 
        ["ACT_MP_ATTACK_SWIM_PRIMARY"] = true, ["ACT_HL2MP_IDLE_CROUCH_FIST"] = true, 
        ["ACT_DI_ALYX_ZOMBIE_SHOTGUN64"] = true, ["ACT_HL2MP_IDLE_PASSIVE"] = true, ["RecipientFilter"] = false, -- bash
        ["CAP_WEAPON_MELEE_ATTACK2"] = true, ["ACT_MP_SWIM_PRIMARY"] = true, ["MASK_NPCWORLDSTATIC"] = true, 
        ["ACT_VM_PRIMARYATTACK_6"] = true, ["EF_NOINTERP"] = true, ["EmitSound"] = true, ["EmitSentence"] = true, 
        ["ACT_HL2MP_JUMP_DUEL"] = true, ["ACT_BUSY_SIT_CHAIR"] = true, ["KEY_S"] = true, 
        ["SentenceDuration"] = true, ["ACT_DOD_RELOAD_PRONE_DEPLOYED_MG"] = true, ["ACT_HL2MP_JUMP_KNIFE"] = true, 
        ["ACT_HL2MP_SIT_KNIFE"] = true, ["ACT_HL2MP_WALK_ZOMBIE_01"] = true, ["ACT_DOD_PRIMARYATTACK_MP44"] = true, 
        ["EFL_TOUCHING_FLUID"] = true, ["ACT_VM_CRAWL"] = true, ["ACT_VM_DRAW_SILENCED"] = false, -- bug error
        ["GetGlobal2Angle"] = true, ["SetGlobal2Angle"] = true, ["SetGlobal2Vector"] = true, 
        ["SCHED_DIE_RAGDOLL"] = true, ["ACT_DOD_RUN_AIM_MP44"] = true, ["ACT_DOD_RUN_AIM_BOLT"] = true, 
        ["SetGlobal2String"] = true, ["GetGlobal2Bool"] = true, ["SetGlobal2Bool"] = true, ["TYPE_DAMAGEINFO"] = true, 
        ["BLEND_SRC_ALPHA_SATURATE"] = true, ["ACT_DIE_FRONTSIDE"] = true, ["properties"] = true, 
        ["ACT_DOD_CROUCH_AIM_GREASE"] = true, ["ACT_MELEE_ATTACK_SWING_GESTURE"] = true, ["ACT_GRENADE_TOSS"] = true, 
        ["SetGlobal2Int"] = true, ["BuildNetworkedVarsTable"] = true, ["SIGNONSTATE_CHALLENGE"] = true, 
        ["ACT_HL2MP_RUN_MAGIC"] = true, ["SND_SHOULDPAUSE"] = true, ["ACT_GESTURE_BIG_FLINCH"] = true, 
        ["ACT_READINESS_AGITATED_TO_STIMULATED"] = false, ["ACT_HL2MP_SWIM_IDLE_ZOMBIE"] = true, 
        ["ACT_MP_DEPLOYED_PRIMARY"] = true, ["SetGlobalFloat"] = true, ["ACT_HL2MP_SWIM_IDLE_PHYSGUN"] = true, 
        ["SetGlobalInt"] = false, ["SetGlobalString"] = false, ["SCHED_FAIL"] = true, ["SetGlobalVar"] = true, --host
        ["CONTENTS_TEAM2"] = true, ["ACT_PHYSCANNON_UPGRADE"] = true, ["ACT_HL2MP_IDLE_ANGRY"] = true, 
        ["ACT_RANGE_AIM_PISTOL_LW"] = true, ["ACT_VM_SWINGHIT"] = true, ["SCHED_RANGE_ATTACK2"] = true, 
        ["SF_NPC_GAG"] = true, ["ACT_MP_SECONDARY_GRENADE1_IDLE"] = true, ["TYPE_PARTICLESYSTEM"] = true, 
        ["ispanel"] = true, ["IN_WALK"] = true, ["MASK_DEADSOLID"] = true, ["NAV_MESH_NO_HOSTAGES"] = true, 
        ["isbool"] = true, ["DMG_ACID"] = true, 
        ["false"] = true, ["ACT_IDLE_AIM_STEALTH"] = false, ["ACT_DOD_PRIMARYATTACK_PSCHRECK"] = true, 
        ["ACT_VM_DEPLOY_7"] = true, ["CompileString"] = false, ["ACT_VM_DEPLOYED_IRON_FIRE"] = true, 
        ["ProtectedCall"] = true, ["ACT_HL2MP_RUN_AR2"] = true, ["KEY_F9"] = true, 
        ["ACT_WALK_AIM_SHOTGUN"] = true, ["ACT_DOD_CROUCH_IDLE_MG"] = true, ["RunStringEx"] = true, 
        ["MOVETYPE_FLY"] = true, ["NPC_STATE_IDLE"] = true, ["SIM_NOTHING"] = true, ["ACT_DOD_RELOAD_C96"] = true, 
        ["ColorToHSL"] = true, ["ACT_DOD_PRIMARYATTACK_CROUCH_KNIFE"] = true, ["BRANCH"] = true, 
        ["ACT_WALK_CROUCH_AIM_RIFLE"] = true, ["HSLToColor"] = true, ["ACT_DOD_PRONE_ZOOM_BAZOOKA"] = true, 
        ["MASK_BLOCKLOS"] = true, ["CONTENTS_TEAM4"] = true, ["ACT_GLOCK_SHOOT_RELOAD"] = true, 
        ["SF_NPC_START_EFFICIENT"] = true,
        ["ACT_MP_RELOAD_AIRWALK_SECONDARY"] = true, ["ACT_VM_IDLE_DEPLOYED_7"] = true, ["ConVarExists"] = true, 
        ["ACT_HL2MP_JUMP_FIST"] = true, ["ACT_VM_DRAW_M203"] = true, ["ACT_DOD_PRONEWALK_IDLE_TNT"] = true, 
        ["ErrorNoHalt"] = true, ["ACT_CROUCHING_SHIELD_DOWN"] = true, ["MsgN"] = false, ["ACT_DOD_WALK_AIM"] = true, -- msg
        ["ACT_DOD_RELOAD_MP40"] = true, ["DebugInfo"] = true, ["PrintMessage"] = true, 
        ["ACT_HL2MP_IDLE_RPG"] = true, ["SetPhysConstraintSystem"] = true, ["IsEntity"] = true, 
        ["ACT_DOD_RUN_AIM_GREN_FRAG"] = true, ["KEY_PAD_DIVIDE"] = true, 
        ["ACT_MP_AIRWALK_BUILDING"] = true, ["ACT_GESTURE_FLINCH_BLAST_DAMAGED_SHOTGUN"] = true,
        ["ACT_VM_IDLE_6"] = true, ["ACT_HL2MP_GESTURE_RELOAD_ZOMBIE"] = true, ["MASK_SPLITAREAPORTAL"] = true, 
        ["ACT_HANDGRENADE_THROW2"] = true, ["CLASS_HUMAN_MILITARY"] = true, ["CompileFile"] = true, 
        ["ACT_HL2MP_IDLE_AR2"] = true, ["ACT_DOD_WALK_IDLE_BAZOOKA"] = true, 
        ["KEY_XSTICK1_LEFT"] = true, ["ACT_IDLE_SHOTGUN_STIMULATED"] = true, ["ACT_BUSY_SIT_CHAIR_ENTRY"] = true, 
        ["UnPredictedCurTime"] = true, ["DropEntityIfHeld"] = true, ["TEXFILTER"] = true, ["GAME_DLL"] = true, 
        ["ACT_MP_RELOAD_CROUCH_PRIMARY_END"] = true, ["BOX_BOTTOM"] = true, ["ACT_RANGE_ATTACK_SHOTGUN_LOW"] = true, 
        ["BOX_TOP"] = true, ["BOX_RIGHT"] = true, ["ACT_GMOD_GESTURE_BECON"] = true, ["ACT_RIDE_MANNED_GUN"] = true, 
        ["ACT_SLAM_TRIPMINE_ATTACH2"] = true, ["CLASS_MILITARY"] = true, ["BOX_BACK"] = true, 
        ["BOUNDS_HITBOXES"] = true, ["MASK_CURRENT"] = true, ["ACT_GESTURE_SMALL_FLINCH"] = true, 
        ["ACT_DOD_WALK_IDLE"] = true, ["AIMR_ILLEGAL"] = true, ["ACT_DOD_RELOAD_TOMMY"] = true, 
        ["ACT_MP_RELOAD_SWIM_END"] = true, ["ACT_VM_PRIMARYATTACK"] = false, ["DMG_GENERIC"] = true, 
        ["ACT_FLINCH_LEFTARM"] = true, ["ACT_CROSSBOW_HOLSTER_UNLOADED"] = true,
        ["ACT_MP_RELOAD_AIRWALK_PRIMARY_END"] = true, ["ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL"] = true, 
        ["ACT_DOD_WALK_IDLE_MP44"] = true, ["ACT_HL2MP_WALK_CROUCH_ZOMBIE_01"] = true, 
        ["BLEND_ONE_MINUS_DST_ALPHA"] = true, ["KEY_XBUTTON_STICK2"] = true, ["EFL_KEEP_ON_RECREATE_ENTITIES"] = true, 
        ["ACT_RANGE_ATTACK_SMG1_LOW"] = true, ["BLEND_ONE_MINUS_SRC_COLOR"] = true, ["KEY_1"] = false, 
        ["KEY_8"] = true, ["BLENDFUNC_ADD"] = true, ["BLEND_DST_ALPHA"] = true, ["NAV_MESH_BLOCKED_PROPDOOR"] = true, 
        ["CLASS_BARNACLE"] = true, ["ACT_IDLE_ANGRY_RPG"] = true, ["ACT_DROP_WEAPON_SHOTGUN"] = true, 
        ["ACT_VM_UNLOAD"] = true, ["ACT_DOD_PRONE_ZOOMED"] = true, ["BLEND_ONE_MINUS_DST_COLOR"] = true, 
        ["ACT_VM_RECOIL1"] = true, ["BLEND_ONE"] = true, ["STEPSOUNDTIME_WATER_FOOT"] = true, 
        ["ACT_MP_JUMP_LAND_BUILDING"] = true, ["ACT_HL2MP_GESTURE_RANGE_ATTACK_PASSIVE"] = true, ["_R"] = true, 
        ["EF_ITEM_BLINK"] = true, 
        ["ACT_DOD_PRIMARYATTACK_PRONE_DEPLOYED_30CAL"] = true, ["ACT_DOD_SECONDARYATTACK_MP40"] = true, 
        ["EF_BONEMERGE_FASTCULL"] = true, ["SCHED_STANDOFF"] = true, ["EF_NOSHADOW"] = true, 
        ["ACT_POLICE_HARASS1"] = true, ["ACT_DOD_CROUCHWALK_AIM_BAZOOKA"] = true, 
        ["ACT_MP_ATTACK_AIRWALK_BUILDING"] = true, ["ACT_MP_AIRWALK_PRIMARY"] = true, ["EF_BRIGHTLIGHT"] = true, 
        ["EF_BONEMERGE"] = true, ["FCVAR_LUA_SERVER"] = true, ["ACT_VM_DEPLOYED_LIFTED_IDLE"] = true, 
        ["FCVAR_LUA_CLIENT"] = true, ["KEY_SCROLLLOCK"] = true, ["CT_REBEL"] = true, 
        ["ACT_MP_GESTURE_VC_NODNO_MELEE"] = true, ["ACT_DOD_SPRINT_IDLE_C96"] = true,
        ["ACT_GESTURE_TURN_LEFT90"] = true, ["FCVAR_SERVER_CAN_EXECUTE"] = true, ["FCVAR_ARCHIVE_XBOX"] = true, 
        ["FCVAR_NOT_CONNECTED"] = true, ["SCHED_INTERACTION_WAIT_FOR_PARTNER"] = true, ["FCVAR_DEMO"] = true, 
        ["kRenderFxRagdoll"] = true, ["FCVAR_NEVER_AS_STRING"] = true, ["FCVAR_UNLOGGED"] = true, 
        ["FCVAR_PRINTABLEONLY"] = true, ["FCVAR_CHEAT"] = true, ["HULL_MEDIUM"] = true, 
        ["ACT_CROUCHING_GRENADEREADY"] = true, ["ACT_DOD_CROUCH_AIM_RIFLE"] = true, ["KEY_R"] = true, 
        ["BONE_USED_BY_HITBOX"] = true, ["ACT_HL2MP_IDLE_CROUCH_MAGIC"] = true, ["ACT_VM_DEPLOY_1"] = true, 
        ["OBS_MODE_DEATHCAM"] = true, ["ACT_MP_RELOAD_SWIM_SECONDARY_END"] = true, ["FCVAR_CLIENTDLL"] = true, 
        ["FCVAR_GAMEDLL"] = true, ["ACT_HL2MP_IDLE_CROUCH_PASSIVE"] = true, ["TASKSTATUS_COMPLETE"] = true, 
        ["KEY_XSTICK2_DOWN"] = true, ["CAP_WEAPON_MELEE_ATTACK1"] = true, ["KEY_XSTICK2_LEFT"] = true, 
        ["MOVETYPE_STEP"] = true, ["ACT_SLAM_THROW_THROW2"] = true, ["KEY_XSTICK2_RIGHT"] = true, 
        ["KEY_XBUTTON_RTRIGGER"] = true, ["CLASS_ZOMBIE"] = true, ["KEY_PAD_5"] = true, 
        ["ACT_VM_DEPLOYED_OUT"] = true, ["KEY_XBUTTON_LTRIGGER"] = true, ["ACT_HL2MP_WALK_CROUCH_PISTOL"] = true, 
        ["KEY_XSTICK1_UP"] = true, ["KEY_XSTICK1_DOWN"] = true, ["SOUND_CONTEXT_PLAYER_VEHICLE"] = true, 
        ["FSASYNC_OK"] = true, ["KEY_XBUTTON_STICK1"] = true, ["KEY_XBUTTON_START"] = true, 
        ["ACT_MP_GESTURE_FLINCH_HEAD"] = true, ["ACT_MP_GRENADE2_IDLE"] = true, ["NAV_MESH_NO_MERGE"] = true, 
        ["CONTENTS_TESTFOGVOLUME"] = true, ["ACT_HL2MP_GESTURE_RELOAD_PHYSGUN"] = true, 
        ["KEY_XBUTTON_LEFT_SHOULDER"] = true, ["KEY_XBUTTON_X"] = true, ["KEY_XBUTTON_DOWN"] = true, 
        ["KEY_XBUTTON_RIGHT"] = true, ["BUTTON_CODE_LAST"] = true, ["JOYSTICK_LAST"] = true, 
        ["ACT_DOD_CROUCH_ZOOM_PSCHRECK"] = true, ["JOYSTICK_FIRST_AXIS_BUTTON"] = true, 
        ["JOYSTICK_LAST_POV_BUTTON"] = true, ["JOYSTICK_FIRST_POV_BUTTON"] = true, ["JOYSTICK_FIRST_BUTTON"] = true, 
        ["ACT_WALK_SCARED"] = true, ["ACT_HL2MP_SIT_PHYSGUN"] = true, ["MOUSE_LAST"] = true, 
        ["ACT_SLAM_DETONATOR_DETONATE"] = true, ["MOUSE_WHEEL_DOWN"] = true, ["ACT_MP_GESTURE_VC_THUMBSUP"] = true, 
        ["MOUSE_WHEEL_UP"] = true, ["MOUSE_5"] = true, ["MOUSE_4"] = true, ["KEY_SCROLLLOCKTOGGLE"] = true, 
        ["ACT_DOD_RUN_AIM_SPADE"] = true, ["KEY_COUNT"] = true, 
        ["ACT_MP_ATTACK_STAND_STARTFIRE"] = true, ["KEY_LAST"] = true, ["ACT_DOD_PRIMARYATTACK_GREASE"] = true, 
        ["ACT_DOD_CROUCHWALK_AIM_KNIFE"] = true, ["MOUSE_MIDDLE"] = true, ["ACT_READINESS_RELAXED_TO_STIMULATED"] = false, 
        ["ACT_DOD_PRIMARYATTACK_PRONE_PSCHRECK"] = true, ["KEY_F11"] = true, ["KEY_F6"] = true, 
        ["ACT_VM_IDLE_DEPLOYED_2"] = true, ["KEY_F3"] = true, ["KEY_F2"] = true, ["SF_ROLLERMINE_FRIENDLY"] = true, 
        ["PLAYER_SUPERJUMP"] = true, ["ACT_OVERLAY_GRENADEIDLE"] = true, ["CONTENTS_TEAM1"] = true, 
        ["ACT_COWER"] = true, ["KEY_RIGHT"] = true, ["KEY_LEFT"] = true, ["KEY_RWIN"] = true, ["NAV_CLIMB"] = true, 
        ["ACT_DOD_RELOAD_BAR"] = true, ["ACT_MP_ATTACK_SWIM_PDA"] = true, ["ACT_HL2MP_GESTURE_RELOAD"] = true, 
        ["KEY_RCONTROL"] = true, ["KEY_LALT"] = true, ["KEY_BREAK"] = true, ["KEY_PAGEDOWN"] = true, 
        ["SF_NPC_NO_WEAPON_DROP"] = true, ["KEY_PAGEUP"] = true, ["kRenderFxNoDissipation"] = true, 
        ["TYPE_PIXELVISHANDLE"] = true, ["KEY_END"] = true, ["KEY_HOME"] = true, ["ACT_MP_CROUCH_SECONDARY"] = true, 
        ["kRenderFxFlickerFast"] = true, ["KEY_DELETE"] = true, ["KEY_INSERT"] = true, 
        ["FCVAR_SERVER_CANNOT_QUERY"] = true, ["KEY_CAPSLOCK"] = true, ["ACT_SLAM_THROW_IDLE"] = true, 
        ["KEY_ENTER"] = false, ["KEY_EQUAL"] = true, ["KEY_MINUS"] = true, ["KEY_SLASH"] = true, -- chat box
        ["KEY_PERIOD"] = true, ["SF_CITIZEN_NOT_COMMANDABLE"] = true, ["ACT_DOD_WALK_AIM_GREN_STICK"] = true, 
        ["PLAYER_IDLE"] = true, ["ACT_HL2MP_SWIM_IDLE_MELEE"] = true, ["HUD_PRINTCENTER"] = false, 
        ["SCHED_TAKE_COVER_FROM_BEST_SOUND"] = true, ["KEY_RBRACKET"] = true, ["TYPE_VIDEO"] = true, 
        ["MOUSE_COUNT"] = true, ["ACT_HL2MP_ZOMBIE_SLUMP_ALT_RISE_SLOW"] = true, 
        ["BroadcastLua"] = true, ["ACT_MP_ATTACK_STAND_BUILDING"] = true, ["ACT_MP_ATTACK_CROUCH_BUILDING"] = true, 
        ["CW"] = true, ["ACT_RELOAD_START"] = true, ["KEY_PAD_8"] = true, ["KEY_PAD_7"] = true, 
        ["ACT_HL2MP_WALK_ZOMBIE"] = true, ["ACT_HL2MP_WALK_PASSIVE"] = true, ["KEY_PAD_6"] = true, 
        ["KEY_PAD_4"] = true, ["ACT_STEP_LEFT"] = true, ["SCHED_COMBAT_FACE"] = true, ["TYPE_USERMSG"] = true, 
        ["KEY_PAD_3"] = true, ["KEY_PAD_2"] = true, ["KEY_PAD_1"] = true, ["KEY_PAD_0"] = true, 
        ["ACT_VM_RELOAD_IDLE"] = true, ["ACT_HL2MP_SWIM_IDLE_FIST"] = true, ["MASK_NPCSOLID"] = true, ["KEY_X"] = true, 
        ["ACT_HANDGRENADE_THROW3"] = true, ["ACT_VM_IIN"] = true, ["KEY_W"] = true, ["KEY_V"] = true, 
        ["ACT_DOD_CROUCH_IDLE_30CAL"] = true, ["KEY_U"] = true, ["USE_SET"] = true, 
        ["ACT_DOD_PRIMARYATTACK_DEPLOYED_30CAL"] = true, ["KEY_Q"] = true, ["ACT_HL2MP_WALK_SHOTGUN"] = true, 
        ["KEY_M"] = true, ["CLASS_PLAYER_BIOWEAPON"] = true, ["KEY_L"] = true, ["ACT_CROUCHING_GRENADEIDLE"] = true, 
        ["ACT_DOD_HS_IDLE_PISTOL"] = true, ["ACT_DOD_WALK_AIM_KNIFE"] = true, ["KEY_K"] = true, ["KEY_J"] = true, 
        ["KEY_I"] = true, ["KEY_H"] = true, ["ACT_HL2MP_IDLE_FIST"] = true, ["KEY_E"] = true, 
        ["ACT_TURN_LEFT"] = true, ["ACT_DOD_PRIMARYATTACK_BAZOOKA"] = true, ["ACT_WALK_ANGRY"] = true, 
        ["FCVAR_NONE"] = true, ["KEY_B"] = true, ["KEY_6"] = true, ["ACT_VM_RECOIL2"] = true, 
        ["ACT_DOD_RUN_IDLE_MP44"] = true, ["KEY_4"] = false, ["KEY_3"] = false, ["ACT_DOD_CROUCH_AIM_PSCHRECK"] = true, 
        ["ACT_HL2MP_GESTURE_RANGE_ATTACK_CAMERA"] = true, ["ACT_SLAM_STICKWALL_ATTACH"] = true, 
        ["ACT_RUN_PISTOL"] = true, ["BLEND_SRC_COLOR"] = true, ["KEY_NONE"] = true, ["KEY_FIRST"] = true, 
        ["ACT_RUN_AIM_AGITATED"] = false, ["NAV_MESH_INVALID"] = true, ["TYPE_SURFACEINFO"] = true, 
        ["ACT_DOD_PRIMARYATTACK_RIFLE"] = true, ["ACT_90_LEFT"] = true, ["TYPE_PROJECTEDTEXTURE"] = true, 
        ["TYPE_USERDATA"] = true, ["TYPE_NAVLADDER"] = true, ["TYPE_PATH"] = true, 
        ["ACT_HL2MP_WALK_CROUCH_SMG1"] = true, ["TYPE_DLIGHT"] = true, ["TYPE_TEXTURE"] = true, 
        ["ACT_HL2MP_WALK_CROUCH_REVOLVER"] = true, ["ACT_DOD_RUN_AIM_C96"] = true, ["ACT_DOD_WALK_ZOOMED"] = true, 
        ["TYPE_PARTICLEEMITTER"] = true, ["ACT_PRONE_FORWARD"] = true, ["TYPE_PARTICLE"] = true, 
        ["ACT_DOD_STAND_IDLE_30CAL"] = true, ["ACT_DOD_STAND_AIM_PISTOL"] = true, ["ACT_VM_HOLSTERFULL_M203"] = true, 
        ["TYPE_SCRIPTEDVEHICLE"] = true, ["ACT_DOD_RUN_AIM_TOMMY"] = true, ["TYPE_RECIPIENTFILTER"] = true, 
        ["ACT_VM_DEPLOY_EMPTY"] = true, ["DMG_DROWN"] = true,
        ["ACT_VM_PRIMARYATTACK_2"] = true, ["ACT_HL2MP_WALK_CROUCH_ZOMBIE_04"] = true, 
        ["ACT_RELOAD_FINISH"] = true, ["PATTACH_POINT_FOLLOW"] = true, ["ACT_MP_RELOAD_AIRWALK_END"] = true, 
        ["ACT_HL2MP_SWIM_GRENADE"] = true,
        ["HITGROUP_GENERIC"] = true, ["ACT_MP_ATTACK_CROUCH_MELEE"] = true, 
        ["SOLID_CUSTOM"] = true, ["AIMR_CHANGE_TYPE"] = true, ["ai_task"] = true, 
        ["AIMR_BLOCKED_WORLD"] = true, ["MAT_GRATE"] = true, ["ACT_HL2MP_WALK_CROUCH_CAMERA"] = true, 
        ["ACT_HL2MP_GESTURE_RELOAD_REVOLVER"] = true, ["SCHED_MOVE_AWAY_FROM_ENEMY"] = true, ["KEY_C"] = true, 
        ["TASKSTATUS_RUN_TASK"] = true, ["ACT_VM_HITKILL"] = true, ["ACT_VM_DRYFIRE_LEFT"] = true, 
        ["BONE_USED_BY_VERTEX_LOD4"] = true, ["CHAN_USER_BASE"] = true, ["TASKSTATUS_NEW"] = true, 
        ["FCVAR_PROTECTED"] = true, ["SOUND_CONTEXT_EXPLOSION"] = true, ["SOUND_CONTEXT_REACT_TO_SOURCE"] = true, 
        ["SOUND_MEAT"] = true, ["ACT_ZOMBIE_LEAP_START"] = true, ["ACT_VM_IIN_EMPTY"] = true, 
        ["SOUND_CONTEXT_MORTAR"] = true, ["SCHED_SCRIPTED_RUN"] = true, ["SOUND_CONTEXT_GUNFIRE"] = true, 
        ["ACT_DOD_RELOAD_PRONE_BAR"] = true, ["SOUND_CONTEXT_FROM_SNIPER"] = true, ["SOUND_READINESS_HIGH"] = true, 
        ["ACT_HOVER"] = true, ["ACT_DOD_PRIMARYATTACK_GREN_STICK"] = true, 
        ["SOUND_PLAYER_VEHICLE"] = true, ["CONTENTS_AUX"] = false, ["CLASS_NONE"] = true, 
        ["DMG_REMOVENORAGDOLL"] = true, ["SF_CITIZEN_MEDIC"] = true, ["MAT_VENT"] = true, ["ACT_OBJ_UPGRADING"] = true, 
        ["ACT_DOD_STAND_AIM_PSCHRECK"] = true, ["SOUND_BUGBAIT"] = true, ["ACT_DOD_HS_IDLE_PSCHRECK"] = true, 
        ["SOUND_CARCASS"] = true, ["SOUND_BULLET_IMPACT"] = true, ["FSOLID_MAX_BITS"] = true, ["SOUND_WORLD"] = true, 
        ["SOUND_COMBAT"] = true, ["SOUND_NONE"] = true, ["ACT_HL2MP_SWIM_SUITCASE"] = true, 
        ["ACT_GESTURE_TURN_RIGHT45"] = true, ["ACT_MP_ATTACK_STAND_SECONDARY"] = true, ["ACT_GMOD_TAUNT_LAUGH"] = true, 
        ["USE_OFF"] = true, ["IN_RUN"] = true, ["ACT_DOD_HS_CROUCH_TOMMY"] = true, ["NAV_MESH_FUNC_COST"] = true, 
        ["NAV_MESH_CLIFF"] = true, ["ACT_MP_RELOAD_SWIM_SECONDARY_LOOP"] = true, ["ACT_COMBAT_IDLE"] = true, 
        ["ACT_MP_RELOAD_AIRWALK_SECONDARY_END"] = true, ["NAV_MESH_STAIRS"] = true, 
        ["ACT_HL2MP_SWIM_IDLE_SMG1"] = true, ["ACT_SLAM_DETONATOR_HOLSTER"] = true, ["FL_GRAPHED"] = true, 
        ["NAV_MESH_TRANSIENT"] = true, ["ACT_GESTURE_RANGE_ATTACK_ML"] = true, ["ACT_HL2MP_WALK_CROUCH_SLAM"] = true, 
        ["NAV_MESH_AVOID"] = true, ["ACT_VM_IOUT_EMPTY"] = true, ["NAV_MESH_RUN"] = true, ["NAV_MESH_NO_JUMP"] = true, 
        ["ACT_WALK_AIM_AGITATED"] = false, ["ACT_HL2MP_GESTURE_RANGE_ATTACK_RPG"] = true, 
        ["ACT_DOD_RELOAD_PRONE_DEPLOYED_BAR"] = true, ["NAV_MESH_PRECISE"] = true,
        ["ACT_HL2MP_IDLE_CROUCH_CROSSBOW"] = true, ["HITGROUP_STOMACH"] = true, ["ACT_POLICE_HARASS2"] = true, 
        ["ACT_VM_RELOAD_M203"] = true, ["SCHED_FORCED_GO"] = true, ["SF_NPC_NO_PLAYER_PUSHAWAY"] = true, 
        ["SF_NPC_ALTCOLLISION"] = true, ["ACT_VM_MISSCENTER2"] = true, ["ACT_DEEPIDLE3"] = true, 
        ["SF_NPC_LONG_RANGE"] = true, ["ACT_RPG_HOLSTER_UNLOADED"] = true, ["VGUIFrameTime"] = false, -- profile
        ["ACT_IDLE_SUITCASE"] = true, ["SF_NPC_WAIT_TILL_SEEN"] = true, ["ACT_RUN_STIMULATED"] = false, 
        ["SF_CITIZEN_RANDOM_HEAD_MALE"] = true, ["ACT_DOD_RUN_ZOOM_RIFLE"] = true, ["KEY_COMMA"] = true, 
        ["ACT_MP_ATTACK_CROUCH_MELEE_SECONDARY"] = true, ["SF_CITIZEN_FOLLOW"] = true, ["IN_SPEED"] = false, -- noclip
        ["CT_REFUGEE"] = true, ["ACT_DOD_RELOAD_PRONE_FG42"] = true, ["BLEND_ONE_MINUS_SRC_ALPHA"] = true, 
        ["WEAPON_PROFICIENCY_VERY_GOOD"] = true, ["D_FR"] = true, ["SCHED_WAKE_ANGRY"] = true, 
        ["ACT_HL2MP_RUN_REVOLVER"] = true, ["SCHED_IDLE_WALK"] = true, ["ACT_MP_ATTACK_SWIM_MELEE"] = true, 
        ["ACT_BIG_FLINCH"] = true, ["ACT_DOD_RELOAD_PRONE_MP40"] = true, ["COLLISION_GROUP_PASSABLE_DOOR"] = true, 
        ["PrintTable"] = false, ["ACT_SHIELD_ATTACK"] = true, ["NPC_STATE_DEAD"] = true, -- debugging
        ["ACT_HL2MP_SIT_SMG1"] = true, ["ACT_HL2MP_GESTURE_RANGE_ATTACK_ANGRY"] = true, ["EFL_NO_DISSOLVE"] = true, 
        ["ACT_DOD_STAND_IDLE_TOMMY"] = true, ["NPC_STATE_PRONE"] = true, ["NPC_STATE_PLAYDEAD"] = true, 
        ["NPC_STATE_SCRIPT"] = true, ["ACT_HL2MP_RUN_CAMERA"] = true, ["COLLISION_GROUP_DISSOLVING"] = true, 
        ["NPC_STATE_ALERT"] = true, ["NPC_STATE_INVALID"] = true, ["COND"] = true, ["SOUND_PLAYER"] = true, 
        ["FSOLID_TRIGGER_TOUCH_DEBRIS"] = true, ["FSOLID_USE_TRIGGER_BOUNDS"] = true, ["GESTURE_SLOT_VCD"] = true, 
        ["ACT_HL2MP_WALK_MELEE2"] = true, ["FSOLID_VOLUME_CONTENTS"] = true, ["ACT_RANGE_AIM_LOW"] = false, 
        ["FSOLID_NOT_STANDABLE"] = true, ["FSOLID_NOT_SOLID"] = false, ["FSOLID_CUSTOMBOXTEST"] = true, -- rngfix
        ["ACT_VM_PRIMARYATTACK_DEPLOYED"] = true, ["ACT_RELOAD_SHOTGUN"] = true, ["ACT_MP_SWIM_PDA"] = true, 
        ["SND_IGNORE_NAME"] = true, ["SetGlobal2Entity"] = true, ["BONE_USED_BY_VERTEX_LOD5"] = true, ["USE_ON"] = true, 
        ["SND_CHANGE_VOL"] = true, ["ACT_CROUCHIDLE_AIM_STIMULATED"] = false, ["SENSORBONE"] = true, 
        ["TRACER_RAIL"] = true, ["TASKSTATUS_RUN_MOVE_AND_TASK"] = true, ["_VERSION"] = true, 
        ["ACT_HL2MP_GESTURE_RELOAD_ANGRY"] = true, ["ACT_HL2MP_JUMP_SHOTGUN"] = true, 
        ["ACT_GMOD_SHOWOFF_DUCK_02"] = true, ["CHAN_VOICE"] = true, ["ACT_HL2MP_WALK_ZOMBIE_05"] = true, 
        ["CHAN_AUTO"] = true, ["KEY_SEMICOLON"] = true, ["ACT_DOD_PRIMARYATTACK_CROUCH"] = true, 
        ["SF_PHYSPROP_MOTIONDISABLED"] = true, ["ACT_HL2MP_IDLE_SMG1"] = true, 
        ["ACT_DOD_PRIMARYATTACK_PRONE_GREN_STICK"] = true, ["ACT_DOD_PRIMARYATTACK_PRONE_BAR"] = true, 
        ["ACT_HL2MP_SWIM_SLAM"] = true, ["HUD_PRINTNOTIFY"] = true, ["FCVAR_UNREGISTERED"] = true, 
        ["ACT_MP_JUMP_BUILDING"] = true, ["TEAM_SPECTATOR"] = false, ["ACT_HL2MP_IDLE_CROUCH_PISTOL"] = true, 
        ["ACT_MP_ATTACK_STAND_GRENADE_BUILDING"] = true,
        ["COLLISION_GROUP_DOOR_BLOCKER"] = true, ["ACT_MP_GESTURE_VC_HANDMOUTH_PRIMARY"] = true, 
        ["ACT_HL2MP_WALK_KNIFE"] = true, ["ACT_SLAM_THROW_DETONATOR_HOLSTER"] = true, ["ACT_IDLE_AIM_AGITATED"] = false, 
        ["ACT_RANGE_ATTACK_AR2_GRENADE"] = true,
        ["TRANSMIT_PVS"] = true, ["TRANSMIT_NEVER"] = true, ["FrameNumber"] = false, 
        ["ACT_HL2MP_JUMP_MELEE2"] = true, ["KEY_T"] = true, ["SND_SPAWNING"] = true, ["ACT_VM_RELOAD_DEPLOYED"] = true, 
        ["ACT_DOD_CROUCHWALK_AIM_C96"] = true, ["CONTINUOUS_USE"] = true, ["BONE_USED_BY_BONE_MERGE"] = true, 
        ["BONE_USED_BY_VERTEX_LOD7"] = true, ["ACT_MP_GESTURE_VC_FINGERPOINT"] = true, 
        ["ACT_GMOD_SHOWOFF_STAND_01"] = true, ["ACT_WALK_CROUCH_RIFLE"] = true, ["BONE_USED_BY_VERTEX_LOD6"] = true, 
        ["TYPE_PHYSCOLLIDE"] = true, ["DMG_SLASH"] = true, ["ACT_FLINCH"] = true, ["BONE_USED_BY_VERTEX_LOD0"] = true, 
        ["ACT_MP_AIRWALK"] = true, ["FL_FLY"] = true, ["BONE_USED_BY_ANYTHING"] = true, 
        ["ACT_RUN_AIM"] = false, ["ACT_HL2MP_JUMP_PISTOL"] = true,
        ["CLASS_ALIEN_BIOWEAPON"] = true,
        ["SCHED_MOVE_AWAY"] = true,
        ["ACT_RUN_SCARED"] = true,
        ["ACT_VM_IDLE_DEPLOYED_5"] = true,
        ["ACT_GMOD_GESTURE_POINT"] = true,
        ["ACT_MP_PRIMARY_GRENADE1_IDLE"] = true,
        ["MAT_PLASTIC"] = true,
        ["ACT_MP_RELOAD_SWIM"] = true,
        ["ACT_TURN_RIGHT"] = true,
        ["KEY_APP"] = true,
        ["ACT_HL2MP_SWIM_AR2"] = true,
        ["ACT_SLAM_DETONATOR_STICKWALL_DRAW"] = true,
        ["COLLISION_GROUP_VEHICLE_CLIP"] = true,
        ["ACT_MP_ATTACK_CROUCH_PRIMARY"] = true,
        ["ACT_STARTDYING"] = true,
        ["ACT_DOD_SPRINT_AIM_KNIFE"] = true,
        ["ACT_HL2MP_SIT_CROSSBOW"] = true,
        ["ACT_MP_GESTURE_VC_THUMBSUP_BUILDING"] = true,
        ["DISPSURF_SURFACE"] = true,
        ["BLEND_DST_COLOR"] = true,
        ["FL_ONTRAIN"] = true,
        ["ACT_RUN_RIFLE"] = true,
        ["ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN"] = true,
        ["ACT_DOD_RUN_AIM_BAZOOKA"] = true,
        ["ACT_MP_RELOAD_CROUCH_LOOP"] = true,
        ["ACT_DOD_CROUCHWALK_IDLE"] = true,
        ["CAP_USE"] = true,
        ["KEY_CAPSLOCKTOGGLE"] = true,
        ["FL_ONFIRE"] = true,
        ["CAP_SQUAD"] = true,
        ["ACT_GMOD_SHOWOFF_STAND_02"] = true,
        ["TYPE_SOUND"] = true,
        ["ACT_MP_GESTURE_VC_NODYES_SECONDARY"] = true,
        ["TimedCos"] = true,
        ["ACT_PRONE_IDLE"] = true,
        ["ACT_WALK_SUITCASE"] = true,
        ["SOLID_BSP"] = true,
        ["ACT_DOD_CROUCH_AIM_GREN_STICK"] = true,
        ["KEY_BACKSLASH"] = true,
        ["ACT_VM_PRIMARYATTACK_DEPLOYED_1"] = true,
        ["ACT_RANGE_ATTACK_HMG1"] = true,
        ["ACT_DEPLOY"] = true,
        ["SCHED_COMBAT_PATROL"] = true,
        ["SCHED_SCENE_GENERIC"] = true,
        ["TASKSTATUS_RUN_MOVE"] = true,
        ["SF_NPC_DROP_HEALTHKIT"] = true,
        ["DMG_CRUSH"] = true,
        ["SetGlobal2Float"] = true,
        ["ACT_HL2MP_SWIM_SHOTGUN"] = true,
        ["IN_CANCEL"] = true,
        ["FCVAR_REPLICATED"] = false, -- rng
        ["COLLISION_GROUP_PLAYER_MOVEMENT"] = false, -- needed
        ["KEY_PAD_MULTIPLY"] = true,
        ["ACT_DOD_WALK_IDLE_MG"] = true,
        ["ACT_IDLE_ANGRY"] = false,
        ["ACT_DOD_STAND_IDLE_BAZOOKA"] = true,
        ["TYPE_FUNCTION"] = true,
        ["ACT_BUSY_SIT_CHAIR_EXIT"] = true,
        ["ACT_DOD_SPRINT_IDLE_TNT"] = true,
        ["SetGlobalVector"] = true,
        ["ACT_VM_RELEASE"] = true,
        ["DMG_DIRECT"] = true,
        ["KEY_F"] = true,
        ["ACT_DOD_CROUCH_AIM"] = true,
        ["ACT_GMOD_TAUNT_CHEER"] = true,
        ["ACT_RUN_CROUCH_AIM"] = true,
        ["ACT_CROSSBOW_IDLE_UNLOADED"] = true,
        ["ACT_MP_RELOAD_CROUCH_SECONDARY_END"] = true,
        ["ACT_VM_UNUSABLE_TO_USABLE"] = true,
        ["ACT_RANGE_ATTACK_TRIPWIRE"] = true,
        ["TEAM_CONNECTING"] = true,
        ["ACT_ARM"] = true,
        ["ACT_HL2MP_GESTURE_RANGE_ATTACK_SCARED"] = true,
        ["ACT_OBJ_DETERIORATING"] = true,
        ["ACT_DOD_PRIMARYATTACK_GREN_FRAG"] = true,
        ["ACT_MP_GESTURE_VC_HANDMOUTH_PDA"] = true,
        ["ACT_DIE_BACKSIDE"] = true,
        ["KEY_LSHIFT"] = false,
        ["ACT_FLINCH_RIGHTLEG"] = true,
        ["ACT_VM_RECOIL3"] = true,
        ["ACT_MP_ATTACK_STAND_SECONDARYFIRE"] = true,
        ["ACT_SLAM_STICKWALL_DETONATOR_HOLSTER"] = true,
        ["ACT_HL2MP_WALK_REVOLVER"] = true,
        ["BONE_ALWAYS_PROCEDURAL"] = true,
        ["ACT_VM_IDLE_3"] = true,
        ["ACT_DOD_RUN_IDLE_PSCHRECK"] = true,
        ["CAP_TURN_HEAD"] = true,
        ["ACT_VM_FIREMODE"] = true,
        ["ACT_DROP_WEAPON"] = true,
        ["SCHED_HIDE_AND_RELOAD"] = true,
        ["ACT_DOD_SECONDARYATTACK_CROUCH"] = true,
        ["ACT_MP_STAND_SECONDARY"] = true,
        ["ACT_VM_SWINGMISS"] = true,
        ["RENDERMODE_ENVIROMENTAL"] = true,
        ["ACT_DOD_PRONEWALK_IDLE_30CAL"] = true,
        ["ACT_DOD_PRONE_DEPLOY_MG"] = true,
        ["ACT_MP_AIRWALK_SECONDARY"] = true,
        ["ACT_DOD_CROUCHWALK_IDLE_PISTOL"] = true,
        ["MAT_SNOW"] = true,
        ["ACT_FLINCH_HEAD"] = true,
        ["ACT_WALK_AIM"] = false,
        ["ACT_MP_RUN_MELEE"] = true,
        ["ACT_CLIMB_DOWN"] = true,
        ["ACT_VM_DEPLOY_3"] = true,
        ["LAST_SHARED_COLLISION_GROUP"] = true,
        ["ACT_DOD_STAND_AIM_MP44"] = true,
        ["ACT_DOD_SPRINT_IDLE_BOLT"] = true,
        ["TYPE_IMESH"] = true,
        ["SIGNONSTATE_SPAWN"] = true,
        ["TEXT_ALIGN_BOTTOM"] = false,
        ["setfenv"] = true,
        ["MAT_SLOSH"] = true,
        ["ACT_DOD_WALK_AIM_C96"] = true,
        ["CAP_WEAPON_RANGE_ATTACK2"] = true,
        ["ACT_STEP_FORE"] = true,
        ["ACT_SLAM_TRIPMINE_DRAW"] = true,
        ["ACT_MP_ATTACK_STAND_POSTFIRE"] = true,
        ["ACT_OVERLAY_SHIELD_UP_IDLE"] = true,
        ["ACT_VICTORY_DANCE"] = true,
        ["ACT_FLINCH_STOMACH"] = true,
        ["ACT_RUN"] = false,
        ["EFL_DIRTY_ABSTRANSFORM"] = true,
        ["HUD_PRINTCONSOLE"] = true,
        ["ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2"] = true,
        ["ACT_GESTURE_RANGE_ATTACK_SNIPER_RIFLE"] = true,
        ["ACT_DOD_CROUCH_AIM_MP40"] = true,
        ["DeriveGamemode"] = true,
        ["ACT_BUSY_LEAN_LEFT"] = true,
        ["PLAYERANIMEVENT_RELOAD"] = true,
        ["SIGNONSTATE_NONE"] = true,
        ["constraint"] = true,
        ["ACT_VM_DRYFIRE"] = false, -- usp
        ["ACT_SLAM_STICKWALL_ND_DRAW"] = true,
        ["ACT_IDLE_AGITATED"] = false,
        ["ACT_SMG2_RELOAD2"] = true,
        ["SCHED_SHOOT_ENEMY_COVER"] = true,
        ["ACT_HL2MP_GESTURE_RELOAD_DUEL"] = true,
        ["PLAYER_WALK"] = true,
        ["ACT_DOD_HS_IDLE_TOMMY"] = true,
        ["TYPE_SOUNDHANDLE"] = true,
        ["ACT_RUN_RIFLE_STIMULATED"] = true,
        ["ACT_VM_SECONDARYATTACK"] = false,
        ["ACT_DOD_RELOAD_PRONE_MP44"] = true,
        ["ACT_RUN_AIM_PISTOL"] = true,
        ["FL_FROZEN"] = true, ["FL_STATICPROP"] = true, ["FL_ANIMDUCKING"] = false, ["FL_CLIENT"] = true, -- bug error
        ["FL_DISSOLVING"] = true, ["FL_GRENADE"] = true, ["FL_NPC"] = true, ["FL_DONTTOUCH"] = true, 
        ["FL_GRAPHED"] = true, ["FL_ITEM_BLINK"] = true, ["FL_NO_ROTORWASH_PUSH"] = true, ["FL_FLY"] = true,
        ["EFL_SERVER_ONLY"] = true, ["EFL_NO_ROTORWASH_PUSH"] = true, ["EFL_DIRTY_ABSVELOCITY"] = false, 
        ["EFL_NO_DAMAGE_FORCES"] = true, ["EFL_DIRTY_ABSANGVELOCITY"] = true, ["EFL_DONTBLOCKLOS"] = true, 
        ["EFL_IS_BEING_LIFTED_BY_BARNACLE"] = true, ["EFL_DORMANT"] = true, ["EFL_DIRTY_SPATIAL_PARTITION"] = true, 
        ["EFL_TOUCHING_FLUID"] = true, ["EFL_NO_DISSOLVE"] = true, ["EFL_KILLME"] = true, 
        ["EFL_BONEMERGE"] = true, ["EFL_NO_GAME_PHYSICS_SIMULATION"] = true, ["EFL_KEEP_ON_RECREATE_ENTITIES"] = true, 
        ["EFL_IN_SKYBOX"] = true, ["EFL_BONEMERGE_FASTCULL"] = true, ["EFL_BRIGHTLIGHT"] = true,
        ["SortedPairsByValue"] = false, ["SortedPairsByMemberValue"] = false, 
        ["convar"] = true,
        ["construct"] = true, ["duplicator"] = true, 
        ["cleanup"] = true, ["undo"] = true, ["numpad"] = true,
        ["system"] = false, ["effects"] = true,
        ["debugoverlay"] = true, ["cookie"] = false, ["umsg"] = true, ["saverestore"] = true,
        ["SetGlobal2Var"] = true, ["GetGlobal2Entity"] = true, ["GetGlobal2Vector"] = true, 
        ["GetGlobal2Float"] = true, ["SetGlobal2String"] = true, ["GetGlobal2Bool"] = true, 
        ["SetGlobal2Bool"] = true, ["SetGlobal2Int"] = true, ["SetGlobal2Vector"] = true, 
        ["SetGlobal2Angle"] = true, ["GetGlobal2Angle"] = true, ["SetGlobal2Entity"] = true,
        ["ACT_HL2MP_IDLE_PISTOL"] = false, --
        ["ACT_HL2MP_IDLE_SMG1"] = true,
        ["ACT_HL2MP_IDLE_GRENADE"] = true,
        ["ACT_HL2MP_IDLE_AR2"] = true,
        ["ACT_HL2MP_IDLE_SHOTGUN"] = true,
        ["ACT_HL2MP_IDLE_RPG"] = true,
        ["ACT_HL2MP_IDLE_PHYSGUN"] = true,
        ["ACT_HL2MP_IDLE_CROSSBOW"] = true,
        ["ACT_HL2MP_IDLE_MELEE"] = true,
        ["ACT_HL2MP_IDLE_SLAM"] = true,
        ["ACT_HL2MP_IDLE_FIST"] = true, 
        ["ACT_HL2MP_IDLE_MELEE2"] = true,
        ["ACT_HL2MP_IDLE_PASSIVE"] = true,
        ["ACT_HL2MP_IDLE_KNIFE"] = true,
        ["ACT_HL2MP_IDLE_DUEL"] = true,
        ["ACT_HL2MP_IDLE_CAMERA"] = true,
        ["ACT_HL2MP_IDLE_MAGIC"] = true,
        ["ACT_HL2MP_IDLE_REVOLVER"] = true,
    }
    return nonEssentialGlobals[key] == true
end

local function ClearNonEssentialGlobals()
    for key, _ in pairs(_G) do
        if isNonEssentialGlobal(key) then
            _G[key] = nil
        end
    end
end

ClearNonEssentialGlobals()

local rents = {
	['env_fire'] = true, ['trigger_hurt'] = true,
	['prop_physics'] = true, ['prop_ragdoll'] = true,
	['light'] = true, ['spotlight_end'] = true,
	['beam'] = true, ['point_spotlight'] = true,
	['env_sprite'] = true, ['func_tracktrain'] = true,
	['light_spot'] = true, ['point_template'] = true
}

for class, _ in pairs(rents) do
	for k, v in pairs(ents.FindByClass(class)) do
		v:Remove()
	end
end

-- Remove unneeded flags
hook_Add("PlayerSpawn", "RemovePlayerFlags", function(ply)
    local flagsToRemove = {
        FL_ANIMDUCKING,
        FL_WATERJUMP,
        FL_ONTRAIN,
        FL_INRAIN, 
        FL_FROZEN,
        FL_ATCONTROLS,
        FL_FAKECLIENT,
        FL_INWATER,
        FL_FLY,
        FL_SWIM,
        FL_CONVEYOR,
        FL_NPC,
        FL_GODMODE,
        FL_NOTARGET,
        FL_AIMTARGET,
        FL_PARTIALGROUND,
        FL_STATICPROP,
        FL_GRAPHED,
        FL_GRENADE,
        FL_STEPMOVEMENT,
        FL_DONTTOUCH,
        FL_BASEVELOCITY,
        FL_WORLDBRUSH,
        FL_OBJECT,
        FL_KILLME,
        FL_ONFIRE,
        FL_DISSOLVING,
        FL_TRANSRAGDOLL,
        FL_UNBLOCKABLE_BY_PLAYER
    }

    for _, flag in ipairs(flagsToRemove) do
        ply:RemoveFlags(flag)
    end
end)

if timer.Exists("CheckHookTimes") then
    timer.Remove("CheckHookTimes")
end

RunConsoleCommand("phys_timescale", "1")
RunConsoleCommand("gmod_maxammo", "0")
RunConsoleCommand("g_ragdoll_maxcount", "0")
RunConsoleCommand("sv_timeout", "0")
RunConsoleCommand("mp_falldamage", "0")

hook.Add("InitPostEntityMap", "Remove.Shadow.Control", function()
    for _, ent in pairs(ents.FindByClass("shadow_control")) do
        ent:SetKeyValue("disableallshadows", 1)
    end

    if #ents.FindByClass("shadow_control") == 0 then
        local ent = ents.Create("shadow_control")
        if IsValid(ent) then
            ent:SetKeyValue("disableallshadows", 1)
            ent:Spawn()
        end
    end

    for _, ent in pairs(ents.FindByClass("func_precipitation")) do
        ent:Remove()
    end

    for _, ent in pairs(ents.FindByClass("func_smokevolume")) do
        ent:Remove()
    end
end)

hook.Add("PlayerSpawn", "PlayerSpawn.RemoveShadows", function(ply)
    ply:DrawShadow(false)
end)

local function RemoveShadows(ent)
    local class = ent:GetClass()
    if class:match("^prop_") or class:match("^func_") or class:match("^item_") or class:match("^env_") then
        ent:DrawShadow(false)
        ent:SetKeyValue("disableshadows", 1)
    end
end

hook.Add("OnEntityCreated", "RemoveShadowsOnEntityCreated", function(ent)
    if IsValid(ent) then
        RemoveShadows(ent)
    end
end)

hook.Add("InitPostEntity", "RemoveShadowsOnInitPostEntity", function()
    for _, ent in ipairs(ents.GetAll()) do
        RemoveShadows(ent)
    end
end)

_G.Exp = nil

setmetatable(_G, {
    __index = function(tbl, key)
        if key == "Exp" then
            print("[Profiler] Attempt to access _G.Exp")
            return nil
        end
        return rawget(tbl, key)
    end,
    __newindex = function(tbl, key, value)
        if key == "Exp" then
            print("[Profiler] Attempt to set _G.Exp is blocked")
            return
        end
        rawset(tbl, key, value)
    end
})

local originalExp = nil
concommand.Add("restore_exp", function()
    if originalExp then
        _G.Exp = originalExp
        print("[Profiler] _G.Exp has been restored")
    else
        print("[Profiler] No original _G.Exp function saved")
    end
end)

timer.Create("ResourceLogger", 1800, 0, function()
    print("Lua memory: ", collectgarbage("count"), "KB")
    print("Entity count: ", #ents.GetAll())
end)

collectgarbage("setpause", 200)
collectgarbage("setstepmul", 500)

hook_Add("MouthMoveAnimation", "Optimization", function() return nil end)
hook_Add("GrabEarAnimation", "Optimization", function() return nil end)

-- Remove Exp
local originalExp = _G.Exp

_G.Exp = nil
_G.package = nil
_G.rawse = nil

local function restoreExp()
    _G.Exp = originalExp
    if SERVER then
        print("[Server] _G.Exp has been restored")
    else
        print("[Client] _G.Exp has been restored")
    end
end

local gc = collectgarbage
local SysTime = SysTime
local timerCreate, timerRemove = timer.Create, timer.Remove
local create, yield, resume = coroutine.create, coroutine.yield, coroutine.resume

local GC_LIMIT = 1 / 300
local GC_INTERVAL = 60

local running = false

local function GarbageCollector()
	while gc("step", 1) do
		if SysTime() > (running and running + GC_LIMIT) then
			yield()
		end
	end
	running = false
end

local function StartGarbageCollection()
	if running then return end
	running = SysTime()
	local co = create(GarbageCollector)

	timerCreate("CollectGarbage.Process", 0, 0, function()
		if not resume(co) then
			timerRemove("CollectGarbage.Process")
			running = false
		end
	end)
end

timerCreate("CollectGarbage", GC_INTERVAL, 0, function()
	if running then return end
	if gc("count") > 1024 * 256 then
		StartGarbageCollection()
	end
end)

-- Networking
local vars, storage = {}, {}
local SERVER, CLIENT, _R = SERVER, CLIENT, debug.getregistry()
local AddReceiver, AddNetworkString = net.Receive, util.AddNetworkString
local EntIndex, Entity, next = _R.Entity.EntIndex, Entity, next
local NewVar, GetNetVar

do
	local mt = {__index = {
		Unrealiable = true,
		Read = net.ReadType, Write = net.WriteType,
		Send = net.Broadcast, PreSync = false}}
	local ReadUInt, WriteUInt, Start = net.ReadUInt, net.WriteUInt, net.Start

	function NewVar(name, funcs)
		local str = 'nw.' .. name
		local var = setmetatable(funcs or {}, mt)
		vars[name] = var

		if SERVER then
			AddNetworkString(str)
			var.OnChange = nil
			local Write, Send, Realiable, OnChanged =
				var.Write, var.Send, var.Unrealiable, var.OnServerChanged

			var.WriteFunction = function(ent, index, v)
				Start(str, Unrealiable)
				WriteUInt(index, 13)
				Write(v)
				Send(ent)
				if OnChanged ~= nil then
					OnChanged(ent, v)
				end
			end
		else
			var.OnServerChange = nil
			local Read, OnChanged = var.Read, var.OnChanged
			AddReceiver(str, function(l, pl)
				local id = ReadUInt(13)
				if storage[id] == nil then storage[id] = {} end
				local v = Read()
				storage[id][name] = v
				if OnChanged ~= nil then
					OnChanged(Entity(id), v)
				end
			end)
		end
	end
end

function GetNetVar(ent, name, default)
	local id = EntIndex(ent)
	if storage[id] == nil then return default end
	return storage[id][name] or default
end

local function BitLength(n)
	return math.floor(math.log(n, 2) + 1)
end

local function AccessorFunc(tab, key, name, def)
	tab['Get' .. name] = function(obj)
		local id = EntIndex(obj)
		if storage[id] == nil then return def end
		return storage[id][key] or def
	end

	if SERVER then
		tab['Set' .. name] = function(obj, val)
			local id, var = EntIndex(obj), vars[key]
			if var ~= nil then
				if storage[id] == nil then storage[id] = {} end
				storage[id][key] = val
				var.WriteFunction(obj, id, val)
			end
		end
	else
		tab['Set' .. name] = function(obj, val)
			local id, var = EntIndex(obj), vars[key]
			if var ~= nil then
				if storage[id] == nil then storage[id] = {} end
				storage[id][key] = val
			end
		end
	end
end

_R.Entity.GetNetVar = GetNetVar
_R.Player.GetNetVar = GetNetVar

if SERVER then
	AddNetworkString'nw.Remove'
	AddNetworkString'nw.Ping'

	function _R.Entity.SetNetVar(ent, name, v)
		local id, var = EntIndex(ent), vars[name]
		if var ~= nil then
			if storage[id] == nil then storage[id] = {} end
			storage[id][name] = v
			var.WriteFunction(ent, id, v)
		end
	end

	do
		local Run, Entity, IsValid, task, timer_Create, timer_Remove = 
			hook.Run, Entity, IsValid, task.Create, timer.Create, timer.Remove
		local wrap, yield = 
			coroutine.wrap, coroutine.yield

		local function SyncVars(pl)
			for id, list in next, storage do
				local ent = Entity(id)
				for name, v in next, list do
					if not IsValid(ent) then break end
					local var = vars[name]
					if var ~= nil and var.PreSync then
						var.WriteFunction(ent, id, v)
						yield(false)
					end
				end
			end
			yield(true)
		end

		AddReceiver('nw.Ping', function(l, pl)
			if pl._nwLoaded then return end
			pl._nwLoaded = true
			
			local name, thread = 
				'nw.Sync_' .. pl:UniqueID(), wrap(SyncVars)

			timer_Create(name, 0, 0, function()
				if not IsValid(pl) then
					timer_Remove(name)
					thread = nil
				elseif thread(pl) then
					timer_Remove(name)
					thread = nil
					Run('PlayerNetworkLoaded', pl)
					net.Start('nw.Ping')
					net.Send(pl)
				end
			end)
		end)
	end

	local Broadcast, Start, UInt = net.Broadcast, net.Start, net.WriteUInt
	hook.Add('EntityRemoved', 'nw.EntityRemoved', function(ent)
		local id = EntIndex(ent)
		if storage[id] ~= nil then
			storage[id] = nil
			Start('nw.Remove')
			UInt(id, 13)
			Broadcast()
		end
	end)
else
	hook.Add('InitPostEntity', 'nw.PreSync', function()
		net.Start('nw.Ping')
		net.SendToServer()
	end)

	local UInt = net.ReadUInt
	AddReceiver('nw.Remove', function()
		storage[UInt(13)] = nil
	end)

	NWLOADED = false
	AddReceiver('nw.Ping', function()
		hook.Run('PlayerNetworkLoaded', LocalPlayer())
		NWLOADED = true
	end)
end

local WriteByte, ReadByte, WriteShort, ReadShort, WriteLong, ReadLong, WriteUByte, ReadUByte,
	WriteUShort, ReadUShort, WriteULong, ReadULong, SendSelf, SendPVS, SendPAS, WriterUInt,
	WriterInt, ReaderUInt, ReaderInt, WriterUFloat, WriterFloat, ReaderUFloat, ReaderFloat

do
	local wuint, ruint, wint, rint, send, sendpvs, sendpas = 
		net.WriteUInt, net.ReadUInt, net.WriteInt, net.ReadInt, net.Send, net.SendPVS, net.SendPAS
	local GetPos = _R.Entity.GetPos
	local fn = function()end

	if SERVER then
		local cached_wuint, cached_wint = {}, {}
		function WriterUInt(bits)
			local fn = cached_wuint[bits]
			if fn ~= nil then return fn end
			cached_wuint[bits] = function(v)
				wuint(v, bits)
			end
			return cached_wuint[bits]
		end

		function WriterInt(bits)
			local fn = cached_wint[bits]
			if fn ~= nil then return fn end
			cached_wint[bits] = function(v)
				wint(v, bits)
			end
			return cached_wint[bits]
		end

		function WriterUFloat(max, bits)
			local ml = (1 / max) * (2 ^ bits - 1)
			return function(v)
				return wuint(v * ml, bits)
			end
		end

		function WriterFloat(max, bits)
			local ml = (1 / max * .5) * (2 ^ bits - 1)
			return function(v)
				return wint(v * ml, bits)
			end
		end

		WriteByte = WriterInt(8)
		WriteShort = WriterInt(16)
		WriteLong = WriterInt(32)
		WriteUByte = WriterUInt(8)
		WriteUShort = WriterUInt(16)
		WriteULong = WriterUInt(32)

		function SendSelf(pl)send(pl)end
		function SendPVS(pl)sendpvs(GetPos(pl))end
		function SendPAS(pl)sendpas(GetPos(pl))end

		ReaderUInt = fn
		ReaderInt = fn
		ReaderUFloat = fn
		ReaderFloat = fn
	else
		local cached_ruint, cached_rint = {}, {}

		function ReaderUInt(bits)
			local fn = cached_ruint[bits]
			if fn ~= nil then return fn end
			cached_ruint[bits] = function()
				return ruint(bits)
			end
			return cached_ruint[bits]
		end

		function ReaderInt(bits)
			local fn = cached_rint[bits]
			if fn ~= nil then return fn end
			cached_rint[bits] = function()
				return rint(bits)
			end
			return cached_rint[bits]
		end

		function ReaderUFloat(max, bits)
			local ml = max / (2 ^ bits - 1)
			return function()
				return ruint(bits) * ml
			end
		end

		function ReaderFloat(max, bits)
			local ml = (max * .5) / (2 ^ bits - 1)
			return function()
				return rint(bits) * ml
			end
		end

		ReadByte = ReaderInt(8)
		ReadShort = ReaderInt(16)
		ReadLong = ReaderInt(32)
		ReadUByte = ReaderUInt(8)
		ReadUShort = ReaderUInt(16)
		ReadULong = ReaderUInt(32)

		WriterUInt = fn
		WriterInt = fn
		WriterUFloat = fn
		WriterFloat = fn
	end
end

nw = {RegisterVar = NewVar, GetNetVar = GetNetVar,
	WriteByte = WriteByte, ReadByte = ReadByte,
	WriteShort = WriteShort, ReadShort = ReadShort,
	WriteLong = WriteLong, ReadLong = ReadLong,
	WriteUByte = WriteUByte, ReadUByte = ReadUByte,
	WriteUShort = WriteUShort, ReadUShort = ReadUShort,
	WriteULong = WriteULong, ReadULong = ReadULong,
	SendSelf = SendSelf, SendPVS = SendPVS, SendPAS = SendPAS,
	WriterUInt = WriterUInt, WriterInt = WriterInt,
	ReaderUInt = ReaderUInt, ReaderInt = ReaderInt,
	WriterUFloat = WriterUFloat, WriterFloat = WriterFloat,
	ReaderUFloat = ReaderUFloat, ReaderFloat = ReaderFloat,
	BitLen = BitLength, AccessorFunc = AccessorFunc}