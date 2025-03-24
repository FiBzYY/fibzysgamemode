-- Bash2 config

-- TODO: share some configs with client and discord

return {
	ban_reason = "Anticheat autoban", -- nil to show real reason
	kick_reason = nil, -- nil to show real reason
	ban_length = 1, -- in minutes (1 week = 10080)
	min_ban_timing = 95.0, -- ban if player's timing is greater
	menu_cols = 10, -- stats count in a menu row
	min_log_level = 1, -- save logs starting from this level
	turn_bind_delay = 150, -- in ticks
	log_insert_press = true,

	-- Gains checks (each 6 jumps)
	min_strafe_ticks = 300, -- ignore high gains if less than given ticks have passed
	min_log_gain = 85.0, -- do log if gains are higher
	max_log_yawing = 60.0, -- do log if yawing pct is lesser
	min_ban_gain = 99.5,

	-- Start and end strafes stats
	max_frames = 50, -- how many frames to record
	max_log_sd = 0.8, -- do log if deviation is less than it
	max_ban_sd = 0.4,
	min_perfect_strafes = 15,

	-- Key switches stats
	max_frames_keyswitch = 80, -- key-switch frames to record
	switch_max_log_sd = 0.0, -- max log key-switch deviation
	kick_for_nulls = false,
	min_null_pct = 95.0, -- kick if nulls pct is greater
	check_klook = true, -- do logs about +klook LJ binds
	klook_delay = 5000, -- delay in ticks between detections

	-- Check for illegal movements and buttons
	min_stop_illegal_moves = 4,
	min_illegal_sidemoves = 10, -- count, to trigger logs
	min_illegal_consecutives = 10, -- count
	min_yaw_change_ratio = 0.3,
	check_mouse = true, -- check mouse_dx and yaw difference

	-- Check for illegal turning
	turns_check_period = 100, -- in ticks
	min_illegal_yaw_count = 30,
	min_wonly_pct = 30.0,

	-- Scroll checks
	do_scroll_checks = true,
	scroll_samples_min = 45, -- decrease this to make the scroll anticheat more sensitive
	scroll_samples_max = 55, -- samples will be taken from the last X jumps' data
	scroll_max_history = 200, -- how many jumps info to store
	ticks_not_count_jump = 8, -- amount of ticks between jumps to not count one
	ticks_not_count_air = 135, -- maximum airtime per jump in ticks before we stop measuring

	-- Oryx Strafe checks
	do_opti_checks = true,
	turn_rate_log = 33,
	turn_rate_kick = 50,
	turn_bypass_log = 50,
	turn_pre_log = 30,
	turn_pre_kick = 45,

	convars = { -- what console variables to track
		"in_usekeyboardsampletime", "cl_yawspeed",
		"m_yaw", "m_filter", "m_rawinput",
		"m_customaccel", "m_customaccel_exponent",
		"m_customaccel_max", "m_customaccel_scale",
		"sensitivity", "zoom_sensitivity_ratio",
		"joystick", "joy_yawsensitivity", "lookstrafe",
	}
}
