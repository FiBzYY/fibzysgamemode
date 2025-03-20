local data = {}
local panel = false

local function style_select(mode, style)
	return function()
		UI:SendCallback("replayselect", {mode, style})
		panel:Exit()
		panel = nil
	end
end

local function translate(mode)
	return TIMER:TranslateMode(mode) == "" and "Normal" or TIMER:TranslateMode(mode)
end

function mode_select2(mode)
	return function()
		panel:UpdateTitle((mode < 0 and "Segmented " or "") .. translate(math.abs(mode)) .. " replays")

		panel.options = {}

		panel:ForceNextPrevious()

		local options = {}
		for k, v in pairs(botdata[mode]) do 
			table.insert(options, {["name"] = TIMER:TranslateStyle(k) .. " (" .. TIMER:GetFormatted(v.time) .. " by ".. v.name .. ")", ["function"] = style_select(mode, k)})
		end
		panel.options = options 

		function panel:OnPrevious(isMax)
			if isMax then 
				panel:goto_start()
			end

			self:UpdateLongestOption()
		end

		panel:UpdateLongestOption()
	end
end

local function goto_start(panel)
	local options = {}
	for i = 1, (#botdata) do
		if not botdata[i] then continue end 
		info = botdata[i] 
		table.insert(options, {["name"] = translate(i), ["function"] = mode_select2(i)})
	end
	for i = -20, 0 do
		if not botdata[i] then continue end 
		info = botdata[i] 
		table.insert(options, {["name"] = "Segmented " .. translate(math.abs(i)), ["function"] = mode_select2(i)})
	end

	panel.options = options 
	panel:UpdateLongestOption()
	panel:UpdateTitle("Replays")
	panel:RemoveNextPrevious()
end

local function ToggleReplayMenu()
	if (panel) then 
		panel:Exit()
		panel = nil
		return 
	end

	local options = {}
	for i = 1, (#botdata) do
		if not botdata[i] then continue end 
		info = botdata[i] 
		table.insert(options, {["name"] = translate(i), ["function"] = mode_select2(i)})
	end
	for i = -20, 0 do
		if not botdata[i] then continue end 
		info = botdata[i] 
		table.insert(options, {["name"] = "Segmented " .. translate(math.abs(i)), ["function"] = mode_select2(i)})
	end

	panel = UI:NumberedUIPanel("Replays", unpack(options))
	panel.goto_start = goto_start

	function panel:OnExit()
		panel = false
	end
end

-- Hook "replay"
UI:AddListener("replay", function(_, data)
	botdata = data[1]

	if (botdata[1]) and (botdata[1][1]) then 
		botdata[1][1] = nil 
		if (table.Count(botdata[1]) == 0) then 
			botdata[1] = nil 
		end 
	end

	ToggleReplayMenu()
end)