JAC = {}

-- Kick message
local kick_msg = "You have been banned permanently for cheating.\nDetails of your detections will not be released."

-- Statistical
local stats = {
	["gain"] = {{85, 87, 90}, {false, false, false}, "Warning! Client 1 has 2 gains (Level: 3)"},
	["angle"] = {{40, 60, 80}, {false, false, true}, "Warning! Client 1 had an illegal angle snap of 2 degrees (Level: 3)"}
}

-- JAC Print
CW = color_white
cj = Color(186, 85, 211)
function JAC:Print(client, ...)
	Core:Send(client, "Print", {"jAntiCheat", {CW, ...}})
end

-- Compiling string for jokes
local function CompileString(str, client, stat, level)
	local s = {CW}
	for k,v in pairs(string.Explode('', str)) do 
		if (v == "1") or (v == "2") then
			table.insert(s, cj)
			table.insert(s, v == "1" and client:Nick() or stat)
			table.insert(s, CW)
		elseif (v == "3") then 
			table.insert(s, level[1])
			table.insert(s, level[2])
			table.insert(s, CW)
		else 
			table.insert(s, v)
		end
	end
	return s
end

-- Report
function JAC:ReportStat(client, stat, var)
	local thresholds = stats[stat][1]
	local response = false
	local threat = 1

	if var >= thresholds[3] then 
		response = stats[stat][2][3]
		threat = 3	
	elseif var >= thresholds[2] then 
		response = stats[stat][2][2] 
		threat = 2	
	elseif var >= thresholds[3] then 
		response = stats[stat][2][1]
	else return end

	local level = threat == 1 and {Color(0, 100, 0), "Low"} or (threat == 2 and {Color(255, 140, 0), "Medium"} or (threat == 3 and {Color(186, 82, 73), "High [No Kick]"}))
	local str = CompileString(stats[stat][3], client, stat=="gain" and tostring(var).."%" or tostring(var), level)
	self:InitWarn(unpack(str))
end

function JAC:InitWarn(...)
	for _, admin in pairs(player.GetHumans()) do
		if (admin:GetNWInt( "AccessIcon", 0 ) < 3) then return end 
		self:Print(admin, ...)
	end
end

-- Init ban
function JAC:InitBan(client)
	local name = client:Name()

	Admin:AddBan(client:SteamID(), name, 0, kick_msg, "CONSOLE", "CONSOLE")
	client:Kick(kick_msg)
	self:Print(player.GetHumans(), "Player ", cj, name, CW, " has been banned permanently for cheating.")
end

-- Registering a detection 
local DetectionLimit = {
	["consistant_strafe"] = 3,
	["perfect_strafe"] = 3,
	["no_startcommand"] = 1
}

local Detections = {}
MySQL:Start('create table if not exists jac_log(id int AUTO_INCREMENT, steamid varchar(255), name text, ip text, detectionid text, data text, PRIMARY KEY(id))')
function JAC:RegisterDetection(client, id, ...)
	local data = {...}

	Detections[client] = Detections[client] or {}
	Detections[client][id] = Detections[client][id] or {}

	-- Add to their list
	table.insert(Detections[client][id], data)
	MySQL:Start("insert into jac_log(steamid, name, ip, detectionid, data) VALUES('"..client:SteamID().."', '"..client:Nick().."', '"..client:IPAddress().."', '"..id.."', '"..table.concat(data, ' ').."')")

	if (#Detections[client][id] > DetectionLimit[id]) then 
		self:InitBan(client)
	end
end

-- Looking at strafe data 
local TotalRight, PerfectRight, LastRight, CRight = {}, {}, {}, {}
local TotalLeft, PerfectLeft, LastLeft, CLeft = {}, {}, {}, {}

function JAC:Init(client)
	self:Refresh(client)
end

function JAC:Refresh(client)
	TotalRight[client] = 0
	TotalLeft[client] = 0
	PerfectRight[client] = 0
	PerfectLeft[client] = 0 
	LastRight[client] = 0
	LastLeft[client] = 0
	CRight[client] = 0
	CLeft[client] = 0
end

function JAC:CheckFrame(client, gain, smove)
	if (smove > 0) then 
		if (gain > 0.9) then 
			PerfectRight[client] = PerfectRight[client] + 1 
		end
		if (gain > 0.1) then 
			TotalRight[client] = TotalRight[client] + 1

			if (LastRight[client] < (gain + 0.01) and LastRight[client] > (gain - 0.01)) and (gain > 0.3) then 
				CRight[client] = CRight[client] + 1 
			end

			LastRight[client] = gain
		end
	elseif (smove < 0) then 
		if (gain > 0.9) then 
			PerfectLeft[client] = PerfectLeft[client] + 1 
		end
		if (gain > 0.1) then 
			TotalLeft[client] = TotalLeft[client] + 1

			if (LastLeft[client] < (gain + 0.01) and LastLeft[client] > (gain - 0.01)) and (gain > 0.3) then 
				CLeft[client] = CLeft[client] + 1 
			end

			LastLeft[client] = gain
		end
	end
end

JAC.Debug = true
function JAC:StartCheck(client)
	local perfectRightPer = PerfectRight[client] / TotalRight[client]
	local perfectLeftPer = PerfectLeft[client] / TotalLeft[client]
	local consistantRightPer = CRight[client] / TotalRight[client]
	local consistantLeftPer = CLeft[client] / TotalLeft[client]

	if TotalRight[client] + TotalLeft[client] < 15 then self:Refresh(client) return end

	-- +left / +right could be a serious issue here
	local consistantBan = (TotalRight[client] > 10) and (TotalLeft[client] > 10) and ((consistantRightPer > 0.9) or (consistantLeftPer > 0.9))
	local perfectBan = ((perfectRightPer + perfectLeftPer) / 2) > 0.95

	if (consistantBan) then 
		self:RegisterDetection(client, "consistant_strafe", TotalRight[client], TotalLeft[client], CRight[client], CLeft[client], consistantRightPer, consistantLeftPer)
	elseif (perfectBan) then 
		self:RegisterDetection(client, "perfect_strafe", TotalRight[client], TotalLeft[client], PerfectRight[client], PerfectLeft[client], perfectRightPer, perfectLeftPer)
	end

	if (self.Debug) then 
		local c = "-----------------------------[ Client: "..client:Nick().." ]-----------------------------"
		print("\n"..c.."\n")
		print("\tTotal Strafes: " .. TotalLeft[client]+TotalRight[client] .. " [Right: " .. TotalRight[client] .. "] [Left: " .. TotalLeft[client] .. "]")
		print("\tPerfect Strafes: " .. PerfectLeft[client]+PerfectRight[client] .. " [Right: " .. PerfectRight[client] .. " (" .. math.Round(perfectRightPer*100,2) .."%)] [Left: " .. PerfectLeft[client] .. " (".. math.Round(perfectLeftPer*100,2) .."%)]" )
		print("\tConsistant Strafes: " .. CLeft[client]+CRight[client] .. " [Right: " .. CRight[client] .. " (" .. math.Round(consistantRightPer*100,2) .."%)] [Left: " .. CLeft[client] .. " (".. math.Round(consistantLeftPer*100,2) .."%)]" )
		print("\tSuspected Cheat: " .. ((consistantBan or perfectBan) and "Yes" or "No"))
		print("\n"..string.rep("-", #c))
	end

	self:Refresh(client)
end

function JAC:ReportIllegalMovement(client, aDiff, pDiff)
	if aDiff > 10 then 
	-- print("Client "..client:Name().." ["..client:SteamID()..", "..client:IPAddress().."] Angle Snap: "..tostring(aDiff).."°")
	end
	-- Not good enough mate
	if (client.stopillegal) or (aDiff < 49.99) then return end

	-- Report
	-- self:ReportStat(client, "angle", math.Round(aDiff, 2))
end