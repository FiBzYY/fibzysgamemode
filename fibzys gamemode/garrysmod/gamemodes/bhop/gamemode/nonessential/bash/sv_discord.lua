pcall(require, "reqwest")
local reqwest = reqwest

local DISCORD_WEBHOOK = file.Read("bash2_discord_webhook.txt", "DATA")
local MESSAGE_PERIOD = 5
local LOG_MAP_CHANGES = 1 -- 0 - disabled, 1 - only with logs, 2 - always
local LEVEL_EMOJIS = {
	[0] = ":information_source: ",
	[1] = ":warning:",
	[2] = ":red_circle:",
	[3] = ":punch:",
	[4] = ":no_entry_sign: @here",
	[5] = ":skull: @here",
}

local g_avatarCache = {}
local g_discordEmbedsQueue = {}
local g_lastMessageTime = RealTime()

local function FetchSteamAvatar(sid64, cb)
	if g_avatarCache[sid64] then
		return timer.Simple(0, function()
			cb(g_avatarCache[sid64], nil)
		end)
	end

	return reqwest({
		method = "GET",
		url = "https://playerdb.co/api/player/steam/" .. sid64,
		timeout = 5,
		success = function(status, body, headers)
			if status ~= 200 then return cb(nil, "HTTP " .. status) end

			local json = util.JSONToTable(body)
			if not json then return cb(nil, "Cant parse JSON") end
			if not json.success then
				return cb(nil, json.code)
			end

			local avatar = json.data.player.meta.avatar
			g_avatarCache[sid64] = avatar
			cb(avatar, nil)
		end,
		failed = function(err, errExt)
			cb(nil, err)
		end
	})
end

local function SendSingleMessage(body, cb)
	local callback = cb or function() end
	return reqwest({
		method = "POST",
		url = DISCORD_WEBHOOK,
		body = util.TableToJSON(body, false),
		headers = {
			["content-type"] = "application/json",
			["user-agent"] = "insomnia/2021.6.0", -- TODO: better user agent?
		},
		timeout = 5,
		success = function(status, body, headers)
			if status == 204 then return callback(true) end
			callback(false, "HTTP " .. status)
		end,
		failed = function(err, errExt)
			callback(false, err)
		end
	})
end

local MessageTimer
MessageTimer = function ()
	if #g_discordEmbedsQueue == 0 then return end

	SendSingleMessage({
		username = GetHostName(),
		embeds = g_discordEmbedsQueue,
		allowed_mentions = { parse = { "everyone" } },
	}, function(ok, err)
		if not ok then
			print("[BASH] Discord failed to send message:", err)
		end
	end)

	g_discordEmbedsQueue = {}
	g_lastMessageTime = RealTime()

	timer.Create("bash2_discord", MESSAGE_PERIOD, 1, MessageTimer)
end

local function LogToDiscord(ply, level, msg, length)
	if not DISCORD_WEBHOOK or not reqwest or not IsValid(ply) then return end
	local sid64, nick, sid = ply:SteamID64(), ply:Nick(), ply:SteamID()

	FetchSteamAvatar(sid64, function(avatar, err)
		if err then
			print(string.format("[BASH] Cant fetch avatar for %s: %s", sid64, err))
		end

		local author = {
			name = string.format("%s [%s]", nick, sid),
			url = "https://www.steamcommunity.com/profiles/" .. sid64,
			icon_url = avatar,
		}

		local last_embed = g_discordEmbedsQueue[#g_discordEmbedsQueue]
		local same_author = last_embed and last_embed.author and last_embed.author.name == author.name
		local emoji = LEVEL_EMOJIS[level] or ":poop:"
		local embed = length and {
			color = 16715792, -- red
			author = author,
			fields = {{
				name = "Ban reason",
				value = msg,
				inline = true,
			}, {
				name = "Ban length",
				value = length == 0 and "Forever" or string.NiceTime(length),
				inline = true,
			}},
		} or {
			description = emoji .. " ".. msg,
			author = author,
		}

		if not length and same_author and last_embed.description then
			-- merge logs about same player
			last_embed.description = last_embed.description .. "\n" .. embed.description
		else
			table.insert(g_discordEmbedsQueue, embed)
		end

		if #g_discordEmbedsQueue >= 10 then
			MessageTimer()
		elseif g_lastMessageTime + MESSAGE_PERIOD > RealTime() then
			timer.Create("bash2_discord", 0.5, 1, MessageTimer)
		elseif not timer.Exists("bash2_discord") then
			timer.Create("bash2_discord", MESSAGE_PERIOD, 1, MessageTimer)
		end
	end)
end

hook.Add("InitPostEntity", "bash2_discord", function()
	local map = string.lower(game.GetMap())
	local thumb = "http://gmod.klazarev.com/maps/thumb/" .. map .. ".png"
	local maps = sql.Query("SELECT * FROM game_map WHERE szMap = " .. map .. ";")

	local embed = {
		thumbnail = { url = thumb },
		title = "Map changed",
		description = "`" .. map .. "`",
		fields = nil,
		color = 49919, -- blue
	}

	if BHDATA and BHDATA.GetMapVariable then
		local pp = tostring(BHDATA.GetMapVariable("Multiplier"))
		local b, tier = BHDATA.GetMapVariable("Bonus"), tonumber(BHDATA.GetMapVariable("Tier"))
		if b and b ~= 0 then pp = string.format("%s / %d", pp, b) end
		if tier and tier ~= 0 then pp = string.format("%s [%d]", pp, tier) end
		embed.fields = {
			{ name = "Plays", value = tostring(BHDATA.GetMapVariable("Plays")), inline = true },
			{ name = "Tier", value = pp, inline = true },
		}
	end

	if LOG_MAP_CHANGES == 1 then
		table.insert(g_discordEmbedsQueue, embed)
	elseif LOG_MAP_CHANGES == 2 then
		SendSingleMessage({
			username = GetHostName(),
			embeds = { embed },
		}, nil)
	end
end)

timer.Remove("bash2_discord")

return LogToDiscord
