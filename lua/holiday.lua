local holidays = {d = {}, m = {}}

local e = {pface = "🥳", fist = "✊", beers = "🍻", french = "\xF0\x9F\x87\xA8\xF0\x9F\x87\xA6", canada = "\xF0\x9F\x87\xA8\xF0\x9F\x87\xA6", circ_orange = "🟠", gay = "🏳️‍🌈", turkey = "🦃", pump = "🎃", w_tree = "🎄"}

local hdefault = {
	avatar = "default.jpg",
	name = "benbebot",
	text = "no holiday",
	status = "",
	game = "Sex Simulator"
}

holidays.d["0101"] = { -- NEW YEAR
	avatar = "new_year.jpg",
	name = e.pface .. " benbebot " .. e.pface,
	text = "New Year",
	game = "New Year Countdown"
}

holidays.m["02"] = { -- BLACK HISTORY
	avatar = nil,
	name = e.fist .. " benbebot " .. e.fist,
	text = "Black History Month",
	game = nil
}

holidays.d["1703"] = { -- ST PATRIC
	avatar = "green_shirt.jpg",
	name = e.beers .. " benbebot " .. e.beers,
	text = "St. Patrick's Day",
	game = nil
}

holidays.d["2106"] = { -- INDIGENOUS DAY
	avatar = "indig.jpg",
	name = "ᓕᑦᑖᒍᑎᒃ", -- Olittâgutik
	text = "Indigenous Peoples Day",
	game = "none"
}

holidays.d["2406"] = { -- FRENCH DAY
	avatar = "quebec.jpg",
	name = e.french .. " benbebot " .. e.french,
	text = "Saint-Jean-Baptiste Day",
	game = "Spy TF2 Simulator"
}

holidays.d["0906"] = { -- SEGS DAY
	game = "Sex IRL"
}

holidays.d["0107"] = { -- CANADA DAY
	avatar = "canada_day.jpg",
	name = e.canada .. " benbebot " .. e.canada,
	text = "Canada Day",
	game = "Sex Simulator"
}

holidays.d["0508"] = { -- HERITAGE DAY
	avatar = nil,
	name = nil,
	text = nil,
	game = nil
}

holidays.d["3009"] = { -- RECONCILIATION DAY
	avatar = "first_nation.jpg",
	name = e.circ_orange .. " benbebot " .. e.circ_orange,
	text = "Truth and Reconciliation Day",
	game = "none"
}

holidays.m["10"] = { -- PRIDE
	avatar = "gay_month.jpg",
	name = e.gay .. " benbebot " .. e.gay,
	text = "Pride Month",
	game = "Gay Sex Simulator"
}

holidays.d["1010"] = { -- THANKSGIVING
	avatar = "thanks.jpg",
	name = e.turkey .. " benbebot " .. e.turkey,
	text = "Thanksgiving",
	game = ":turkey:"
}

holidays.d["3110"] = { -- HALLOWEEN
	avatar = nil,
	name = e.pump .. " benbebot " .. e.pump,
	text = "Halloween",
	game = "Phasmophobia"
}

holidays.d["1111"] = { -- REMEMBRANCE DAY
	avatar = nil,
	name = nil,
	text = "Remembrance Day",
	game = "none"
}

holidays.d["2512"] = { -- CHRISTMAS
	avatar = nil,
	name = e.w_tree .. " benbebot " .. e.w_tree,
	text = "Christmas",
	game = "Santa Simulator"
}

function getHoliday()
	local h = holidays.d[os.date("%d%m")] or holidays.m[os.date("%m")] or hdefault
	
	for i,v in pairs(hdefault) do
		if not h[i] then 
			h[i] = v
		end
	end
	
	return h
end

return getHoliday