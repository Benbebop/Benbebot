local discordia, http, json, thread, lwz, roleGiver, appdata, holiday, tokens, str_ext, server_info, coro_spawn, config, yt_downloader, media = require('discordia'), require("coro-http"), require("json"), require("coro-thread-work"), require("./lua/lualwz"), require("./lua/roleGiver"), require("./lua/appdata"), require("./lua/holiday"), require("./lua/token"), require("./lua/string"), require("./lua/server"), require("coro-spawn"), require("./lua/config"), require("./lua/youtube-dl"), require("./lua/media")

local f = io.open("tables/global.ini.default")
appdata.init({{"permaroles.dat","{}"},{"company.dat", "{}"},{"employed.dat","{}"},{"global.ini",f:read("*a")}})
f:close()

config.verify()

local _config = config.get()

local client = discordia.Client()
local dClock = discordia.Clock()
local discordiaPackage = require('discordia\\package')

local initFile = {}
local allRoles = {}
local helpText = require("./tables/helptext")

local truncate = str_ext.truncate

local outputModes = {null = {255, 255, 255}, info = {0, 0, 255}, err = {255, 0, 0}, mod = {255, 100, 0}, warn = {255, 255, 0}, http = {113, 113, 255}}

function output( str, mode, overwrite_trace )
	if not str then return end
	print( str )
	if mode == "silent" then return end
	str = truncate(str, "desc", true)
	mode = mode or "null"
	local foot = nil
	if mode == "err" then foot = {text = debug.traceback()} end
	if overwrite_trace then foot = {text = overwrite_trace} end
	foot = truncate(foot, "text", true)
	mode = outputModes[mode] or outputModes.null
	str = str:gsub("%d+%.%d+%.%d+%.%d+", "\\*\\*\\*.\\*\\*\\*.\\*\\*\\*.\\*\\*")
	client:getChannel("959468256664621106"):send({
		embed = {
			description = str,
			color = discordia.Color.fromRGB(mode[1], mode[2], mode[3]).value,
			footer = foot,
			timestamp = discordia.Date():toISO('T', 'Z')
		}
	})
end

function proxout( success, result )
	if not success then
		output( result, "err" )
	end
end

function setHoliday( holiday )
	if not _config.misc.suspend_holiday then
	client:setAvatar("images/icons/" .. holiday.avatar)
	client:setUsername(holiday.name)
	local member = client:getGuild(_config.static.myGuild):getMember(client.user.id)
	member:setNickname(holiday.name)
	if holiday.game == "none" or holiday.game == "" then
		client:setGame()
	else
		client:setGame(holiday.game)
	end
	if not holiday.text then
		member:removeRole(_config.roles.day_identifier)
		client:getRole(_config.roles.day_identifier):setName("benbebot day identifier")
	else
		member:addRole(_config.roles.day_identifier)
		client:getRole(_config.roles.day_identifier):setName(holiday.text)
	end
	--output("today is " .. holiday.text)
	else
		client:setAvatar("images/icons/default.jpg")
		client:setUsername("benbebot")
		local member = client:getGuild(_config.static.myGuild):getMember(client.user.id)
		member:setNickname(holiday.name)
		member:removeRole(_config.roles.day_identifier)
		client:getRole(_config.roles.day_identifier):setName("benbebot day identifier")
		client:setGame()
	end
end

function sendPrevError()
	local f = io.open("errorhandle/error.log", "r")
	if f then
		local content = f:read("*a")
		if content == "" then return end
		local err, trace = content:match("^(.-)\nstack traceback:\n(.-)$")
		output( err, "err", trace )
		f:close()
		os.remove("errorhandle/error.log")
	end
end

local githubAPI = require("./lua/api/github")

client:on('ready', function()
	allRoles = roleGiver.getRolePatterns( client:getGuild(_config.static.myGuild).roles )
	dClock:start()
	setHoliday( holiday() )
	sendPrevError()
	io.write("Logged in as ", client.user.username, "\n")
end) 

-- API RESET --
local apiTracker = require("./lua/api/tracker")

dClock:on("hour", function()
	output("clearing api tracker", "silent")
	apiTracker.clear()
end)

-- Commands --
local command, server, youtube, websters = require("./lua/command"), require("./lua/computer"), require("./lua/api/youtube"), require("./lua/api/websters")

client:on('messageCreate', function(message)
	local content = command.parse(message.content)
	if content then
		local success, result = command.run(content, message)
		if not success then
			output(result)
		end
	end
end)

command.new("help", function( message, _, arg )
	local target, targetName = command.get(arg or "")
	if target then 
		proxout(message.channel:send({
			embed = {
				title = "bbb " .. targetName .. " " .. target.stx,
				description = target.desc
			}
		}))
		return
	end
	local content = {}
	for _,v in ipairs(command.get()) do
		if not v.stx:match("^%s?$") then
			v.stx = v.stx .. " "
		end
		table.insert(content, {name = "bbb " .. v.name .. " " .. v.stx, value = v.desc, inline = true})
	end
	proxout(message.channel:send({
		embed = {
			--title = "",
			fields = content,
			--description = "",
			--timestamp = discordia.Date():toISO('T', 'Z')
		},
		refrence = {message = message, mention = false}
	}))
end, nil, "shows a list of commands", true)

command.new("status", function( message ) -- RETURNS STATUS OF SERVER --
	if (message.channel.id == "831564245934145599") or (message.channel.id == "832289651074138123") or true then
		message.channel:broadcastTyping()
		local dVersion, version, status, cpu, memory, networkrecieve, networktransfer, networksignal, duration = server.getStatus()
		proxout(message.channel:send("benbebot is online | discordia " .. dVersion .. " | " .. version .. "\nServer Status: " .. status .. "\ncpu: " .. cpu .. "%, memory: " .. memory .. " GB\nrecieve: " .. networkrecieve .. ", transfer: " .. networktransfer .. ", signal: " .. networksignal .. "%\nuptime: " .. math.floor( os.clock() / 60 / 6 ) / 100 .. "h"))
		output("status requested by " .. message.author.name .. " (" .. duration .. "s)", "info")
	end
end, nil, "get server status")

command.new("config", function( message, _, args )
	local section, key, value = args:match("([^%s]+)%s*([^%s]+)%s*(.-)$")
	if not section then
		message.author:send("```ini\n" .. appdata.read("global.ini") .. "\n```")
	else
		if value then
			if section == "static" then message.channel:send("section static cannot be modified by non-operators") return end
			if not _config[section] then message.channel:send("no such section: " .. section) return end
			if _config[section][key] == nil then message.channel:send("no such key: " .. key) return end
			local old_value = _config[section][key]
			if value == "true" then
				value = true
			elseif value == "false" then
				value = false
			elseif value:match("^%d+$") then
				value = tonumber(value)
			elseif value:match("^s%d+$") then
				value = value:match("^s(%d+)$")
			end
			_config[section][key] = value
			config.setKey(section, key, value)
			message.channel:send("set config " .. key .. " from " .. type(old_value) .. " " .. tostring(old_value) .. " to " .. tostring(value))
		else
			if not _config[key] then message.channel:send("no such key: " .. key) return end
			local old_value = _config[section]
			_config[section] = key
			config.setKey(nil, section, key)
			message.channel:send("set config " .. section .. " from " .. type(old_value) .. " " .. old_value .. " to " .. key)
		end
		_config = config.get()
	end
end, "<section> <key> <value>", "edit benbebot config", false, {"manageWebhooks"})

command.new("random", function( message, args ) -- MAKES A RANDOM NUMBER --
	local initial, final = args[1], args[2]
	if initial and final then
		initial, final = tonumber(initial), tonumber(final)
		if initial > final then initial, final = final, initial end
		proxout(message.channel:send(tostring(math.random(initial, final))))
	end
end, "<lower limit> <upper limit>", "generates a random number")

command.new("define", function( message, args ) -- DEFINES A WORD --
	local success, content, found, title = websters.getDefinition( args[1] )
	local result = websters.getDefinition( args[1] )
	if result.status ~= "OK" then output(result.data, "err") return end
	local success, content, found, title = true, result.data[1], result.data[2], result.data[3]
	if content then
		local desc = nil
		if not found then desc = "no definition exists for your word, here are some suggestions" end
		proxout(message.channel:send({
			embed = {
				title = title,
				fields = content,
				description = desc,
				timestamp = discordia.Date():toISO('T', 'Z')
				},
			refrence = {message = message, mention = false}
		}))
		proxout(message.channel:send(result))
	elseif success then
		proxout(message.channel:send("couldnt find definition for " .. todefine))
	else
		-- do nothing for now
	end
end, "<word>", "uses the webster's dictionary api to define words")

command.new("calc", function( message, _, argument ) -- RENDER --
	if #argument < math.huge then
		local success, result = pcall(load("return " .. argument:gsub("\n", " "), nil, "t", math))
		if success then
			if argument:match("^%s*9%s*%+%s*10%s*$") and result == 19 then
				result = 21
			end
			if type(result) == "number" then
				proxout(message.channel:send( tostring( result ) ))
			end
		end
	end
end, "<lua>", "calculates a value based on a lua string")

command.new("vote", function( message ) -- VOTE --
	if message.channel.id == _config.static.c_announcement then
		message:addReaction("👍")
		message:addReaction("👎")
	end
end, nil, "calls vote in announcemnt", true)

command.new("s_announce", function( message ) -- SCHOOL ANNOUNCMENT --
	message:delete()
	local announcement = youtube.getSchoolAnnouncements()
	if announcement.status ~= "OK" then output(announcement.data) return end
	local mString = client:getRole(_config.roles.school_announcment).mentionString
	for _,v in ipairs(announcement.data) do
		client:getGuild(_config.static.myGuild):getChannel(_config.static.c_announcement):send(mString .. "\nhttps://www.youtube.com/watch?v=" .. v)
	end
end, nil, nil, true)

command.new("pp", function( message ) -- PENID --
	local target = message.mentionedUsers.first or message.author
	math.randomseed(target.id)
	local rand = math.random(-1000, 1000) / 750
	local sign = 0
	if rand ~= 0 then
		sign = rand / math.abs(rand)
	end
	local r = math.floor( rand ^ 2 * sign * 1.5 + 5 )
	if target.id == _config.users.ben then
		r = 8
	end
	proxout(message.channel:send({
		embed = {
			fields = {
				{
					name = target.name .. "'s pp", value = "8" .. string.rep("=", r) .. "D", inline = true}
				},
				color = discordia.Color.fromRGB((9 - math.min( r, 9 )) / 9 * 255, math.min( r, 9 ) / 9 * 255, 0).value
			},
		refrence = {message = message, mention = false}
	}))
end, "<target>", "imperical measurement of a man's penis")

command.new("ryt", function( message ) -- PENID --
	message.channel:broadcastTyping()
	local result = youtube.randomVideo()
	if result.status ~= "OK" then output(result.data) return end
	proxout(message.channel:send("https://www.youtube.com/watch?v=" .. address))
end, nil, "uses https://petittube.com to find a random unknown video")

command.new("fuckdankmemer", function( message ) -- PENID --
	local dm = client:getGuild(_config.static.myGuild):getMember(_config.users.dankmemer)
	if dm:hasRole(_config.roles.dankmemer_mute) then
		dm:removeRole(_config.roles.dankmemer_mute)
	else
		dm:addRole(_config.roles.dankmemer_mute)
	end
	message:delete()
end, nil, "dank memer cant send messages anymore :vballs:", true)

command.new("github", function( message ) -- PENID --
	proxout(message.channel:send("https://github.com/Benbebop/Benbebot"))
end, nil, "sends the benbebot github repository", true)

initFile = appdata.get("employed.dat", "r")
local forceEmployed = json.parse(initFile:read("*a"))
initFile:close()

command.new("forceemploy", function( message ) -- PENID --
	if message.member:hasRole(_config.roles.company_CEO) and message.mentionedUsers.first then
		local target = client:getGuild(_config.static.myGuild):getMember(message.mentionedUsers.first.id)
		local employed = false
		for i,v in ipairs( forceEmployed ) do
			if target.id == v then
				employed = i
				break
			end
		end
		if employed then
			forceEmployed[employed] = nil
			target:removeRole(_config.roles.company_employee)
			proxout(message.channel:send("succesfully fired"))
		else
			table.insert(forceEmployed, target.id)
			target:addRole(_config.roles.company_employee)
			proxout(message.channel:send("succesfully employed"))
		end
		initFile = appdata.get("employed.dat", "w+")
		initFile:write(json.stringify(forceEmployed))
		initFile:close()
	else
		proxout(message.channel:send("you do not have permissions to use this command"))
	end
end, "<target>", "bypass autoemploy on target", true)

initFile = appdata.get("company.dat", "r")
local company = json.parse(initFile:read("*a"))
initFile:close()

command.new("companyrebrand", function( message, _, argument ) -- PENID --
	if message.member:hasRole(_config.roles.company_CEO) or message.author.id == _config.users.ben then
		local gm = argument:gmatch("%b\"\"")
		local name, color, autoemploy, autofire = gm() or "", gm() or "", gm() or "", nil
		name, color, autoemploy, autofire = name:gsub("\"", ""), color:gsub("\"", ""), autoemploy:gsub("\"", ""), autofire == "true"
		local prevname, prevae = company.name, company.autoemploy
		if autoemploy:match("^%s*$") then 
			company.autoemploy = company.autoemploy
		else 
			company.autoemploy = autoemploy 
		end
		local g = client:getGuild(_config.static.myGuild)
		local ceo, employ = g:getRole(_config.roles.company_CEO), g:getRole(_config.roles.company_employee)
		if color:match("%d+%s+%d+%s+%d+") then 
			color = {color:match("(%d+)%s+(%d+)%s+(%d+)")}
			company.color = color
		else
			color = {ceo:getColor():toRGB()}
		end
		if not name:match("^%s*$") then 
			company.name = name 
		end
		local prevceo = ceo.name
		ceo:setName(company.name .. " CEO's")
		local prevemploy = employ.name
		employ:setName(company.name .. " Employees")
		local cCeo, cEmploy = ceo:getColor(), employ:getColor()
		local cDiff, cSet = cEmploy - cCeo, discordia.Color()
		cSet:setRed(tonumber( color[1] )) cSet:setGreen(tonumber( color[2] )) cSet:setBlue(tonumber( color[3] ))
		ceo:setColor(cSet)
		employ:setColor(cSet + cDiff)
		initFile = appdata.get("company.dat", "w+")
		initFile:write(json.stringify(company))
		initFile:close()
		local e_inline = false
		proxout(message.channel:send({
			embed = {
				title = "Company Rebrand Results",
				fields = {
					{name = "Name", value = "\"" .. prevname .. "\" to \"" .. company.name .. "\"", inline = e_inline},
					{name = "Role Color", value = cCeo.r .. " " .. cCeo.g .. " " .. cCeo.b .. " to " .. cSet.r .. " " .. cSet.g .. " " .. cSet.b, inline = e_inline},
					{name = "Autoemploy String", value = "\"" .. prevae .. "\" to \"" .. company.autoemploy .. "\"", inline = e_inline},
					{name = "Ceo Role Name", value = "\"" .. prevceo .. "\" to \"" .. company.name .. " CEO's\"", inline = e_inline},
					{name = "Employee Role Name", value = "\"" .. prevemploy .. "\" to \"" .. company.name .. " Employees\"", inline = e_inline},
				},
				color = discordia.Color.fromRGB(cSet.r, cSet.g, cSet.b).value,
				description = "some changes take some time to take effect, please wait",
				timestamp = discordia.Date():toISO('T', 'Z')
				},
			refrence = {message = message, mention = false}
		}))
	else
		proxout(message.channel:send("you do not have permissions to use this command"))
	end
end, "", "", true)

local clash = require("./lua/api/clash")

local server_clan = "%23" .. _config.misc.coc_clan_id

command.new("clan", function( message )
	local clan = clash.getClanInfo( server_clan )
	if clan.status ~= "OK" then output(clan.status, "err") return end
	clan = clan.data
	proxout(message.channel:send {
		embed = {
			title = clan.name,
			fields = {
				{name = "Tag", value = clan.tag, inline = false},
				{name = "Required Trophies", value = clan.trophies, inline = true},
				{name = "Required Townhall Level", value = clan.townhallLevel, inline = false},
				{name = "Wins", value = clan.wins, inline = true},
				{name = "Ties", value = clan.ties, inline = true},
				{name = "Losses", value = clan.losses, inline = true},
				{name = "Members", value = clan.members, inline = false},
			},
			description = clan.description,
			image = {
				url = clan.image,
				height = 70,
				width = 70
			},
			color = discordia.Color.fromRGB(clan.r, clan.g, clan.b).value,
			timestamp = discordia.Date():toISO('T', 'Z')
		}
	})
end, "", "(clash of clans) get the servers clan")

command.new("war", function( message )
	local war = clash.getWarInfo( server_clan )
	if war.status ~= "OK" then output(war.status, "err") return end
	war = war.data
	if war then
	proxout(message.channel:send {
		embed = {
			title = war.c .. " VS " .. war.o,
			fields = {
				{name = war.c, value = war.cTag, inline = false},
				{name = "Destruction", value = war.cDest .. "%", inline = true},
				{name = "Attacks", value = war.cAttacks, inline = true},
				{name = "Stars", value = war.cStars, inline = true},
				{name = war.o, value = war.oTag, inline = false},
				{name = "Destruction", value = war.oDest .. "%", inline = true},
				{name = "Attacks", value = war.oAttacks, inline = true},
				{name = "Stars", value = war.oStars, inline = true},
			},
			-- description = "",
			-- image = {
				-- url = war.opponent.badgeUrls.small,
				-- height = 20,
				-- width = 20
			-- },
			color = discordia.Color.fromRGB(war.r, war.g, war.b).value,
			timestamp = war.stamp
		}
	})
	else
		proxout(message.channel:send("there is no clan war currently"))
	end
end, "", "(clash of clans) clan's war status")

command.new("war_announce", function( message, _, arg )
	message:delete()
	if message.channel.id == _config.static.c_announcement then
	local war = clash.getWarAnnounce( server_clan, client:getRole("954149526325833738"), arg )
	if war.status ~= "OK" then output(war.status, "err") return end
	war = war.data
	proxout(message.channel:send({
		content = war.content,
		embed = {
			title = war.c .. " is under attack",
			description = war.desc,
			fields = {
				{name = war.o, value = war.oTag or "err_nil", inline = false},
				{name = "Wins", value = war.oWins or "err_nil", inline = true},
				{name = "Ties", value = war.oTies or "err_nil", inline = true},
				{name = "Losses", value = war.oLosses or "err_nil", inline = true},
				{name = "Members", value = war.oMembers or "err_nil", inline = false},
			},
			-- description = "",
			-- image = {
				-- url = war.opponent.badgeUrls.small,
				-- height = 20,
				-- width = 20
			-- },
			color = war.color,
			timestamp = war.stamp
		}
	}))
	end
end, "<description>", "(clash of clans) announce war", true)

local cocLiveMessage = false

local function wl( message, _, arg )
	message:delete()
	if true then--message.channel.id == _config.static.c_announcement then
		cocLiveMessage = clash.liveWarMessage( message.channel:send({
			content = client:getRole("954149526325833738").mentionString,
			embed = clash.liveEmbedInit
		}), server_clan )
		if cocLiveMessage.status ~= "OK" then output(cocLiveMessage.status, "err") return end
		cocLiveMessage = cocLiveMessage.data
		cocLiveMessage:update()
		output("new war_live object created", "info")
	end
end

command.new("war_live", wl, "", "(clash of clans) sends message that will update as a war happens", true)

client:on('messageCreate', function(message)
	if message.author.id == _config.users.paul then
		if message.mentionedRoles:find(function(v) return v.id == "968908152093409310" end) then
			if not message.content:match("war") then return end
			message:delete()
			wl( client:getChannel("823397621887926272"):send("funny little message cause the way i set up the bot there has to be a message in the announcements channel for the war live object to work") )
		end
	end
end)

dClock:on("min", function()
	if cocLiveMessage and tonumber(os.date("%M")) % 15 == 0 then
		local info = cocLiveMessage:update()
		if info.status ~= "OK" then output(info.data, "err") return end
		if info.data == false then cocLiveMessage:delete() cocLiveMessage = nil output("war_live concluded", "info") return end
		output("war_live updated", "info")
	end
end)

local vdsg_catalogue = {}
for l in io.lines("./tables/vdsg.txt") do 
	local id, content = l:match("^(%d+)%s+(.+)$")
	table.insert(vdsg_catalogue, {id = id, content = content})
end
vdsg_catalogue["n"] = #vdsg_catalogue

command.new("vdsg", function( message )
	math.randomseed(os.clock())
	local tbl = vdsg_catalogue[math.random(1, vdsg_catalogue.n)]
	message.channel:send({
		embed = {
			title = "VDSG Catalogue No." .. tbl.id,
			description = tbl.content,
			timestamp = discordia.Date():toISO('T', 'Z')
		},
		color = discordia.Color.fromRGB(15, 255, 15).value,
		refrence = {message = message, mention = false}
	})
end, nil, "get a vault dweller survival guide tip", true)

local langton = require("./lua/langton/langton")

command.new("ant", function( message, arg )
	if arg[1] == "status" then
		local stats = langton.state()
		message.channel:send({
			embed = {
				title = "Langton Status",
				fields = {
					{name = "Pattern", value = stats.patternstr, inline = false},
					{name = "Ant Position", value = stats.position.x .. " " .. stats.position.y, inline = false},
					{name = "Step", value = tostring( stats.itteration ), inline = false},
				}
			}
		})
	else
		langton.step()
	end
end, "<status>", "progresses the current langton by one step")

local ai = require("./lua/api/15ai")

command.new("fifteenai", function( message, _, arg )
	if arg:match("^list") then
		local fields = {}
		for i,v in pairs(ai.getCharacter()) do
			table.insert(fields, {name = i, value = v:gsub(",%s*$", ""), inline = false})
		end
		message.channel:send({
			embed = {
				title = "15ai Catalog",
				description = "supports any of the voices on 15.ai",
				fields = fields
			},
			refrence = {message = message, mention = true}
		})
		return
	end
	message.channel:broadcastTyping()
	local character, content = arg:match("^%s*\"(.-)\"%s*(.-)$")
	c = ai.getCharacter( character or "" )
	if c == false then
		message.channel:send({embed = {description = "\"" .. character .. "\"", image = {url = "https://cdn.discordapp.com/emojis/851306893745717288.webp?size=128&quality=lossless"}}})
	elseif c then
		local result = ai.saveToFile(c, content, "15ai-" .. c:lower():gsub("%s", "%-") .. ".wav")
		if result.status ~= "OK" and not result.filename then output(result.status, "err") return end
		message.channel:send({
			content = "generated with 15.ai",
			file = result.filename
		})
	else
		message.channel:send("couldn't find character " .. character)
	end
end, "\"<character>\" <message>", "uses http://15.ai to generate a sound file")

local currentStream = nil

command.new("slowmode", function( message, arg )
	if message.author.id == _config.users.paul then
		local limit, duration = arg[1], arg[2]
		message.channel:setRateLimit(limit)
		output("set slowmode for channel " .. message.channel.name, "info")
	end
end, "<limit> <duration>", "sets the current channel to slowmode", true)

local garfield = require("./lua/api/garfield")

command.new("garfield", function( message )
	local result = garfield.getStrip(os.clock())
	if result.status ~= "OK" then output(result.status, "err") return end
	proxout(message.channel:send {
		embed = {
			image = {
				url = result.data.url
			},
			footer = {text = result.data.year .. "/" .. result.data.month .. "/" .. result.data.day}
		}
	})
end, nil, "gets a random garfield strip")

local google = require("./lua/api/google")

command.new("reverse", function( message )
	if not (message.referencedMessage or {}).attachment then output("error: no refrence message", "err") return end
	local ct = message.referencedMessage.attachment.content_type:lower()
	ct = ct:match("image/(.+)") or ct or "null"
	if not google.supportedImages[ct] then output("error: unsupported file type (" .. ct .. ")", "err") return end
	local results = google.reverseSearch( message.referencedMessage.attachment.url )
	if results.status ~= "OK" then output(results.data, "err") return end
	output(results.data)
end, nil, "reverse image searches for an image (google doesnt like this, can get taken down)")

command.new("restart", function( message ) os.exit() end, nil, "restarts server", false, {"manageWebhooks"})

local toremind = {}

command.new("remind", function( message, args )
	local t, c, m = args[1], args[2], args[3]
	if c == "d" then
		t = tonumber(t) * 1440
	elseif c == "h" then
		t = tonumber(t) * 60
	elseif c == "m" then
		t = tonumber(t)
	else
		output("could not parse time mode: " .. c, "warn") return
	end
	table.insert(toremind, {mentionString = message.member.mentionString, name = message.member.nickname or message.member.name, current = 0, total = t, message = m})
	proxout(message.channel:send({
		embed = {
			description = "reminder set for " .. t .. " minutes"
		}
	}))
end, "<time> <m/h/d>", "reminds you after a certain time period (note: if bot errors all current reminders are erased)")

dClock:on("min", function()
	for i in ipairs(toremind) do
		toremind[i].current = toremind[i].current + 1
		if toremind[i].current >= toremind[i].total then
			proxout(client:getChannel(_config.static.c_bot):send({
				content = toremind[i].mentionString,
				embed = {
					title = toremind[i].name .. "'s Reminder",
					description = toremind[i].message
				}
			}))
		end
	end
end)

command.new("pirate", function( message, _, arg )
	if arg:match("^%s*list%s*$") then
		local str = ""
		for i in io.lines("tables/pirate.txt") do
			str = str .. i:gsub("%s*http.-$", ",")
		end
		message.channel:send(str)
		return
	end
	local thing = ""
	for i in io.lines("tables/pirate.txt") do
		if i:lower():match(arg:lower()) then
			thing = i
			break
		end
	end
	print(thing)
	message.channel:send(thing:match("(http.-)$"))
end, "<movie>", "pirates a movie")

command.new("frequency", function(_, arg)
	local g = appdata.read("global.ini")
	local v = tonumber(arg[1])
	if v > 5000 then 
		v = 5000
	elseif v < 5 then
		v = 5
	end
	g:gsub("frequency=%d+", "frequency=" .. v)
end, "<url>", "set frequency of badding the bone." )

command.new("terraria", function( message )
	proxout(message.channel:send {
		embed = {
			title = "Bread Bag Terraria Server",
			fields = {
				{name = "Server IP Address", value = server_info.ip, inline = false},
				{name = "Server Port", value = server_info.terrariaport, inline = false},
				{name = "Server Password", value = server_info.terrariapass, inline = false},
			},
			description = server_info.terrariamotd,
		}
	})
end, "<movie>", "terraria server data")

local fBlacklist = {"privacy%.log", "player_download[\\/].*", "15ai[\\/].*", "directmessage[\\/].*", "http%.log", "incomingconnections%.log"}

command.new("read", function( message, _, args )
	local black = false
	for _,v in ipairs(fBlacklist) do
		if args:match("^" .. v .. "$") then black = true break end
	end
	local f = appdata.get(args, "r")
	if f then
		if black then
			message.channel:send("file is blacklisted")
			return
		end
		proxout(message.channel:send {
			embed = {
				title = truncate(args, "title", true),
				description = truncate(f:read("*a"), "desc"),
			}
		})
		f:close()
	else
		message.channel:send("could not find file")
	end
end, "<filename>", "read internal data from files inside the bot", true)

command.new("say_video", function( message, _, url )
	local file = yt_downloader.get_srt(url)
end, "<string> <pattern>", "match some stuff idk", true, {"manageMessages"})

local privacies = {n = 0}

appdata.init({{"privacy.log", "0"}})

command.new("privacy", function( message )
	local f = appdata.get("privacy.log", "r")
	if not f:read("*a"):match("%s" .. message.author.id .. "%s?") then
		privacies[message.author.id] = message.channel.id
		privacies.n = privacies.n + 1
		proxout(message.channel:send {
			embed = {
				title = "Benbebot Privacy Policy",
				description = "View our privacy policy\n\nhttps://github.com/Benbebop/Benbebot/blob/main/tables/bullshitPrivacyPolicy.md#privacy-policy\n\nOnce you have read this, please send in this channel:",
				fields = {
					{name = "I Agree", value = "if you agree to our privacy policy", inline = false},
					{name = "I Disagree", value = "if you do not agree to our privacy policy", inline = false},
				},
				footer = {text = "This message was generated by " .. message.member.nickname .. " and only applies to them. To generate your own message send \"bbb privacy\" in this server."}
			}
		})
	else
		proxout(message.channel:send {
			embed = {
				title = "Benbebot Privacy Policy",
				description = "View our privacy policy\n\nhttps://github.com/Benbebop/Benbebot/blob/main/tables/bullshitPrivacyPolicy.md#privacy-policy"
			}
		})
	end
	f:close()
end, nil, "read our privacy policy")

client:on('messageCreate', function(message)
	if privacies.n > 0 then
		if privacies[message.author.id] == message.channel.id then
			if message.content:lower():match("^%s*i%s*agree%s*$") then
				local f = appdata.get("privacy.log", "a")
				f:write(" ")
				f:write(message.author.id)
				f:close()
				privacies[message.author.id] = nil
				privacies.n = privacies.n - 1
				output(message.author.mentionString .. " has accepted the Benbebot Privacy Policy", "info")
			elseif message.content:lower():match("^%s*i%s*disagree%s*$") then
				message.member:kick()
				privacies[message.author.id] = nil
				privacies.n = privacies.n - 1
				output(message.author.mentionString .. " has rejected the Benbebot Privacy Policy", "info")
			else
				message:delete()
			end
		end
	end
end)

command.new("issue", function( message )
	proxout(message.channel:send("if you encounter an error, report it here https://github.com/Benbebop/Benbebot/issues/new"))
end, nil, "report an issue with the bot")

command.new("update_msg", function( message )
	local r = githubAPI.release()
	if r then
		client:getChannel("955315272879849532"):send({embed = r})
	end
end, nil, "i cant be bothered to write this", true)

local tmpfile = io.lines("lua/encoder.lua")
local encode, encode_info = require("./lua/encoder"), tmpfile():gsub("^%s*%-%-%s*", "")

command.new("test_encode", function( message, arg )
	local i = arg[1] or message.author.id
	local e, eb = encode.encodenumber(i)
	local d, db = encode.decodenumber(e)
	local bp, vp = eb:match(db) and "✔" or "❌", i:match(d) and "✔️" or "❌"
	proxout(message.channel:send {
		embed = {
			title = encode_info,
			fields = {
					{name = "encode bytes", value = bp .. " `" .. eb .. "`", inline = false},
					{name = "decode bytes", value = bp .. " `" .. db .. "`", inline = false},
					{name = "encoded value", value = vp .. " " .. i, inline = false},
					{name = "decoded value", value = vp .. " " .. d, inline = false},
					{name = "encoded string", value = e, inline = false},
				},
			footer = {text = "this takes your discord id and encodes it via the encoder and sees if it says consistant"}
		}
	})
end, nil, "i cant be bothered to write this", true)

command.new("clear", function( message )
	
end, "<time>", "clears all messages up to a certain time ago", false, {"manageMessages"})

command.new("minecraft", function( message )
	local m = message.channel:send("starting server, please wait")
	local proc = coro_spawn('python', {args = {'python/aternos_start.py'}})
	proc.stdout.handle:listen(128, function(out)
		print("print")
		m:update({content = out})
	end)
end, "<time>", "start up the minecraft server", true)

local sudoku = require("lua/sudoku").Create()

command.new("sudoku", function( message, args )
	sudoku:newGame()
	sudoku.level = tonumber(args[1] or "0")
	local output = ""
	for row=0,8 do
		for col=1,9 do
			output = output .. tostring(sudoku:getVal(row, col) or "?"):gsub("0", ".") .. " "
		end
		output = output .. "\n"
	end
	sudoku:solveGame()
	proxout(message.channel:send {
		embed = {
			description = "```\n" .. output .. "```",
			--footer = {text = String}
		}
	})
end, "<level>", "generate a sudoku puzzle or smthn", true)

command.new("sex", function( message )
	output("<@" .. message.author.id .. "> used sex", "info")
	message.author:send("GO FUCK YOURSELF")
	message.member:kick("GO FUCK YOURSELF")
end, nil, "FUCK YOU I DID IT", true)

command.new("nerd", function(message)
	if message.referencedMessage then
	message.channel:broadcastTyping()
	appdata.write("media/content.txt", message.referencedMessage.content)
	local file = media.overlayTextImage("resource/image/nerd.jpg", message.referencedMessage.content, {
		"-fill", "black",
		"-pointsize", "48", 
		"-size", "680x", 
		"-gravity", "North", 
		"caption:@" .. appdata.directory() .. "media/content.txt",
		"resource/image/nerd.jpg",
		"-append"
	})
	message:reply({file = file})
	os.remove(file)
	end
end, nil, "nerd!" )

-- WEBHOOKS --

local webhook = require("./lua/webhook")

appdata.init({{"incomingconnections.log"}})

webhook.create(nil, server_info.youtubeport, function(req, body)
	local m = "method: " .. req.method .. "\npath: " .. req.path .. "\nversion: " .. req.version .. "\nHEADERS: \n"
	local i = 1
	repeat
		local h = req[tostring(i)]
		m = m .. h[1] .. ": " .. h[2] .. "\n"
		i = i + 1
	until not req[tostring(i)]
	m = m .. "BODY: " .. body
	appdata.append("incomingconnections.log", "\n------------\n" .. m)
	output("SERVER CONNECTION: " .. m, "http")
end)

-- Role Giver --
initFile = io.open("tables\\roleindex.json", "rb")
local basicRoles = json.parse(initFile:read("*a"))
initFile:close()

local dCheck = {}

client:on("memberJoin", function(member)
	local permroles = roleGiver.getPermaroles()
	if permroles[member.id] then -- get if profile exists
		for i,v in pairs(permroles[member.id]) do -- go through profile
			if client:getRole(i) then -- role exists
				local success, err = member:addRole(i) -- give role from profile
				if not success then -- if there was an error
					output("PermaroleError (could not add permarole " .. client:getRole(i).name .. " to " .. member.name .. " [" .. err:gsub("\n", " ") .. "])", "err")
				elseif not member:hasRole(i) then -- if no error but still doesnt have role
					output("PermaroleError (addRole failed, no error)", "err")
				else -- success
					output("added permarole \"" .. client:getRole(i).name .. "\" to " .. member.name, "info")
					table.insert(dCheck, member.id)
				end
			else
				output("PermaroleError (role " .. i .. " no longer exists, removing)", "err")
				permroles[member.id][i] = nil
				roleGiver.savePermaroles( permroles ) -- save the profile to files
			end
		end
	end
end)

dClock:on("min", function() -- fix for role giver bug
	local permroles = roleGiver.getPermaroles()
	if #dCheck ~= 0 then
		output("dChecking permaroles", "info")
		for i,v in ipairs(dCheck) do
			local member = client:getGuild(_config.static.myGuild):getMember(v)
			for l in pairs(permroles[v]) do
				member:addRole(l)
				if member:hasRole(l) then
					table.remove(dCheck, i)
				end
				output("added permarole \"" .. client:getRole(l).name .. "\" to " .. member.name, "info")
			end
			output("dChecked permarole for " .. member.name, "info")
		end
	end
end)

client:on('messageCreate', function(message)
	if (message.channel.id == "822174811694170133") and (message.author.id ~= _config.static.myId) then 
		local permroles = roleGiver.getPermaroles()
		local permamode, permarole = message.content:lower():match("^%s*(%a*)(permarole)")
		if message.content:lower():match("^%s*help") then -- HELP --
			message.channel:send(helpText.role)
		elseif message.content:lower():match("^%s*role%s?list") then -- ROLE LIST --
			local str = ""
			for i,v in pairs(basicRoles) do
				local role = client:getRole(v)
				if role then
					str = str .. ", " .. role.name
				end
			end
			message.channel:send(str:gsub(",%s$", ""):gsub("^,%s?", ""))
		elseif permarole then -- PERMAROLE --
			if message.content:match("%a*$") == "get" then
				local userpermaroles = ""
				if not permroles[message.author.id] then permroles[message.author.id] = {} end
				for i,v in pairs(permroles[message.author.id]) do
					userpermaroles = userpermaroles .. ", " .. client:getRole(i).name
				end
				if userpermaroles == "" then
					message.channel:send("you have no permaroles")
				else
					message.channel:send(userpermaroles:gsub(",%s$", ""):gsub("^,%s?", ""))
				end
			elseif message.content:match("%a*$") == "all" then
				local m = message.channel:send("adding multiple roles, please wait.\nadded roles: ")
				local mc = m.content
				message.member.roles:forEach(function(r)
					if not permroles[message.member.id] then permroles[message.member.id] = {} end
					permroles[message.member.id][r.id] = true
					mc = mc .. r.name .. ", "
					m:update({content = mc:gsub(",%s$", "")})
				end)
				roleGiver.savePermaroles( permroles )
				m:update({content = "added multiple roles to permarole profile of " .. message.member.name})
			else
				local target = message.member
				local roleid = "0"
				if message.content:match("%d+$") then
					roleid = message.content:match("%d+$")
				else
					local truncatedmsg = message.content:lower():gsub("^%s*permarole%s*", "")
					for i,v in pairs(allRoles) do
						if truncatedmsg:match(v.pattern) then
							roleid = v.id
						end
					end
				end
				local role = client:getRole(roleid)
				if permamode == "un" then
					if not permroles[target.id] then permroles[target.id] = {} end
					if not permroles[target.id][roleid] then 
						message.channel:send("you do not have permarole "  .. role.name )
					else
						permroles[target.id][roleid] = nil
						message.channel:send("removed role \"" .. role.name .. "\" from permarole profile of " .. target.name)
					end
				elseif permamode == "" then
					if target:hasRole(roleid) then
						if not permroles[target.id] then permroles[target.id] = {} end
						permroles[target.id][roleid] = true
						message.channel:send("added role \"" .. role.name .. "\" to permarole profile of " .. target.name)
						output("added role \"" .. role.name .. "\" to permarole profile of " .. target.name, "info")
						roleGiver.savePermaroles( permroles )
					elseif role then
						message.channel:send("you must already have the role")
					else
						message.channel:send("role does not exist")
					end
				end
			end
		else -- GIVE ROLE --
			local success = false
			for i,v in pairs(basicRoles) do
				local role = client:getRole(v)
				if role and message.content:lower():match("^%s*%-?%+?%s*" .. i) then
					success = true
					if message.content:match("^%-") then
						message.member:removeRole(v)
						message.channel:send("removed role \"" .. role.name .. "\"")
						output("deleted role " .. client:getRole(v).name .. " from " .. message.member.name, "info")
					else
						message.member:addRole(v)
						message.channel:send("added role \"" .. role.name .. "\"")
						output("gave " .. message.member.name .. " role " .. client:getRole(v).name, "info")
					end
				end
			end
			if message.content:lower():match("^%s*%-?%+?%s*new%s*role") then
				local warnMsg = message.channel:send("changing all newroles, this can take some time")
				for i in client:getGuild("822165179692220476").roles:findAll(function(r) return r.name == "new role" end) do
					if message.content:match("^%-") then
						message.member:removeRole(i)
					else
						message.member:addRole(i)
					end
				end
				warnMsg:delete()
				if message.content:match("^%-") then
					message.channel:send("removed all newroles")
				else
					message.channel:send("added all newroles")
				end
				output("gave " .. message.member.name .. " new roles ", "info")
				success = true
			elseif message.content:lower():match("^%s*%+%s*biggest%s?penis") then
				if message.author.id == _config.users.ben then
					message.channel:send("yea :thumbsup:")
				else
					message.channel:send("as fucking if")
				end
			elseif message.content:lower():match("^%s*%+%s*biggest%s?balls") then
				if message.author.id == _config.users.diego then
					message.channel:send("yea :thumbsup:")
				else
					message.channel:send("ha no")
				end
			elseif (not success) and (message.content:lower():match("^%s*%-") or message.content:lower():match("^%s*%+")) then
				message.channel:send("couldn't find role \"" .. message.content:gsub("^%s*%-?%+?%s*", "") .. "\"")
			end
		end
	end
end)

-- Fun --
local char = string.char
initFile = io.open("tables\\characterreplacers.json", "rb")
local characterReplacers = json.parse(initFile:read("*a"))
initFile:close()
local latestDelMsg, latestDelAuth, latestDelAttach = "", "", {}
local soundcloud = require("./lua/api/soundcloud")

local latestMotd = {id = "", meansent = false}

local sendMotd = function( skip )
	if not _config.misc.motd then return end
	githubAPI.applyMotd()
	local mashup, nextMashup, count, index = soundcloud.getMashup(), soundcloud.nextMashup(), soundcloud.count()
	if nextMashup then
		client:getUser(_config.users.ben):getPrivateChannel():send("next Mashup of The Day: https://soundcloud.com/" .. nextMashup .. " (" .. index .. "/" .. count .. " " .. math.floor( index / count * 100 ) .. "%)")
	else
		client:getUser(_config.users.ben):getPrivateChannel():send("no existing next Mashup of The Day!")
	end
	if not skip then
		if mashup then
			local message = client:getGuild(_config.static.myGuild):getChannel(_config.static.c_announcement):send("https://soundcloud.com/" .. mashup)
			latestMotd.id = message.id
			message:addReaction("👍")
			message:addReaction("👎")
			message:addReaction("🖕")
		else
			client:getGuild(_config.static.myGuild):getChannel(_config.static.c_announcement):send("someone fucked up and there aint any mashup of the day!!!!!")
		end
	end
end

client:on('reactionAdd', function(reaction)
	local message = reaction.message
	if message.id == latestMotd.id and (not latestMotd.meansent) then
		local positive = message.reactions:find(function(v) return v.emojiName == "👍" end)
		local negitive = message.reactions:find(function(v) return v.emojiName == "👎" end)
		local middle_finger = message.reactions:find(function(v) return v.emojiName == "🖕" end)
		if positive and negitive and middle_finger then
			positive, negitive, middle_finger = positive.count - 1, negitive.count - 1, middle_finger.count - 1 
			local total = positive + negitive + middle_finger
			local meanness = middle_finger / total
			client:getUser(_config.users.ben):getPrivateChannel():send("meanness: " .. meanness)
			if meanness > 0.75 and total > 5 + 3 then
				proxout(client:getGuild(_config.static.myGuild):getChannel(_config.static.c_announcement):send({
					content = "why is everyone so mean to me?",
					file = "images/mean.jpg",
					reference = {
						message = latestMotd.id,
						mention = false,
					}
				}))
				latestMotd.meansent = true
			end
		end
	end
end)

client:on('messageCreate', function(message)
	if message.channel.id == client:getUser(_config.users.ben):getPrivateChannel().id then
		if message.content:match("^%s*motd%sskip") then
			sendMotd( true )
		end
	end 
end)

dClock:on("hour", function()
	if os.date("%H") == soundcloud.getPostTime() then
		sendMotd()
	end
end)

client:on('messageCreate', function(message)
	if message.channel.id == client:getUser(_config.users.ben):getPrivateChannel().id then
		if message.content:match("^%s*update%s*privacy") then
			local f = appdata.get("privacy.log", "r")
			for i in f:read("*a"):gmatch("%d+") do
				if client:getUser(i) then
					proxout(client:getUser(i):send( {
						embed = {
							title = "Benbebot Privacy Policy",
							description = "We have updated our privacy policy, please read it here:\n\nhttps://github.com/Benbebop/Benbebot/blob/main/tables/bullshitPrivacyPolicy.md#privacy-policy"
						}
					} ))
				end
			end
		end
	end
end)

client:on('messageCreate', function(message)
	if message.channel.id == "862470542607384596" then -- AMONG US VENT CHAT --
		if message.content:lower():match("amo%a?g%s?us") then
			message.member:addRole("823772997856919623")
			output(message.author.name .. " said among us in #rage-or-vent", "mod")
			message.channel:send("you are unfunny :thumbsdown:")
		end
	elseif message.author.id == _config.users.arcane and message.content:match("please do not use blacklisted words!") and latestDelAuth ~= "941372431082348544" then -- F --
		local translatedMsg = latestDelMsg
		local tofar = latestDelMsg:lower():match(char(110) .. char(105) .. char(103) .. char(103) .. char(101) .. char(114))
		for i,v in pairs(characterReplacers) do
			translatedMsg:gsub(i, v)
		end
		local fomessage = message:reply("fuck off " .. message.author.name .. " :middle_finger:")
		if tofar then
			message:reply("actually nevermind that message was too far")
			--output(message.author.name .. " is saying racial slurs", "mod")
		else
			local attachStr = ""
			if latestDelAttach then
				for i,v in ipairs(latestDelAttach) do
					attachStr = attachStr .. v.url .. "\n"
				end
			end
			message.channel:send({
				content = message.mentionedUsers.first.name .. ": " .. translatedMsg .. "\n" .. attachStr
			})
			message:delete()
			--output(message.author.name .. " was succesfully blocked", "mod")
		end
		local mbefore = message.channel:getMessagesBefore(fomessage.id, 1)
		if mbefore:iter()().author.id == _config.static.myId then
			fomessage:delete()
		end
	elseif message.author.id == _config.users.ben and message.channel.id == _config.static.c_bot and message.content:match("force motd 12345") then
		message:delete()
		sendMotd()
	end
end)

client:on('messageDelete', function(message)
	latestDelMsg, latestDelAuth, latestDelAttach = message.content, message.author, message.attachments
end)

--AUTO NAME ROLES--

client:on('memberUpdate', function(member)
	local employed = false
	for i,v in ipairs(forceEmployed) do
		if member.id == v then
			employed = true
			break
		end
	end
	if _config.roles.gang_weed_autorole and member.nickname and member.nickname:match("^%s*gang%s+weed%s*$") then
		member:addRole(_config.users.gang_weed)
	elseif employed then
	elseif _config.roles.company_autorole and member.nickname and member.nickname:match(company.autoemploy) then
		member:addRole("930996065329631232")
		local result = websters.getDefinition( member.nickname:match("%a+ier%s*$"):gsub("%s", "") )
		if result.status ~= "OK" then output("something went wrong idk im too tired to write this error code, ill understand it ether way.", "err") end
		local success, _, found = result.data[1], result.data[2], result.data[3]
		if not success then
			output(member.user.mentionString .. " API usage exeded, contact a mod or wait an hour bitch. https://tenor.com/view/grrr-heheheha-clash-royale-king-emote-gif-24764227", "warn")
			return
		end
		if found then
			member:addRole("930996065329631232")
		else
			member:removeRole("930996065329631232")
			output("so close, but \"" .. member.nickname:match("%a+ier%s*$"):gsub("%s", "") .. "\" isnt a real word! If you think this is a mistake please ask a mod. " .. member.user.mentionString, "info")
		end
	else
		if not _config.roles.gang_weed_autorole then
			member:removeRole("880305120263426088")
		end
		if not _config.roles.company_autorole then
			member:removeRole("930996065329631232")
		end
	end
end)

dClock:on("day", function()
	if os.date("%a") == "Mon" then
		local DankMemer = client:getGuild(_config.static.myGuild):getMember(_config.users.dankmemer)
		for id in pairs(DankMemer.roles) do
			DankMemer:removeRole(id)
		end
		DankMemer:addRole("951697964177428490")
	else
		local DankMemer = client:getGuild(_config.static.myGuild):getMember(_config.users.dankmemer)
		DankMemer:removeRole("951697964177428490")
		DankMemer:addRole("829754598327320607")
		DankMemer:addRole("822960808812216350")
	end
	setHoliday( holiday() )
end)

client:on('messageCreate', function(message)
	if message.author.id == _config.users.dankmemer then
		if message.member:hasRole("951697964177428490") then
			message:delete()
		end
	end
end)

client:on('messageCreate', function(message)
	if message.channel.id == "959468256664621106" and message.author.id ~= "941372431082348544" then
		message:delete()
	end
end)

--DM LOGGING--

appdata.init({{"directmessage/"}})

client:on('messageCreate', function(message)
	if message.channel.type == 1 then
		appdata.append("directmessage/" .. message.author.name .. ".log", message.content .. "\n")
	end
end)

--ACTIVE ROLE STUFF--

appdata.init({{"lastposted.log"}})

local lp = appdata.read("lastposted.log")

client:on('messageCreate', function(message)
	lp = appdata.read("lastposted.log")
	if not message.author.bot and message.member then
		if lp:match("\n" .. message.author.id .. " ([%d%.]+)") then
			lp = lp:gsub("(\n" .. message.author.id .. ") [%d%.]+", "%1 " .. message:getDate():toSeconds())
		else
			lp = lp .. "\n" .. message.author.id .. " " .. message:getDate():toSeconds()
		end
		appdata.write("lastposted.log", lp)
		message.member:addRole(_config.roles.active_member)
	end
end)

local function checkposted( member )
	lp = appdata.read("lastposted.log")
	local balls = lp:match("\n" .. member.id .. " ([%d%.]+)")
	if balls then
		if discordia.Date() - discordia.Date().fromSeconds(balls) > discordia.Time.fromSeconds(2.628e+6) then
			member:removeRole(_config.roles.active_member)
			lp:gsub("\n" .. member.id .. " ([^\n]+)", "")
			appdata.write("lastposted.log", "w")
			output("removed " .. member.mentionString .. "'s member role for inactivity")
		end
	else
		output(member.mentionString .. " is absent from the checkposted file. removing member role.")
		member:removeRole(_config.roles.active_member)
	end
end

command.new("lastposted", function( message, args )
	lp = appdata.read("lastposted.log")
	local member = message.mentionedUsers.first or {id = args[1]}
	local t = lp:match("\n" .. member.id ..  " ([%d%.]+)")
	if not t then
		proxout(message.channel:send({
			embed = {
				description = "last posted not recorded"
			}
		}))
		return
	end
	t = discordia.Date() - discordia.Date().fromSeconds(t)
	proxout(message.channel:send({
		embed = {
			description = math.floor(t:toSeconds() / 86400) .. " days ago"
		}
	}))
end, "<user>", "", true)

dClock:on("day", function()
	client:getRole(_config.roles.active_member).members:forEach(checkposted)
end)

command.new("member_scan", function( message )
	if message.author.id == _config.users.ben then
		client:getRole(_config.roles.active_member).members:forEach(checkposted)
	end
end, "", "scans all users in guild for posting in the 4 weeks")

--SERVER BOOST EVENTS--

appdata.init({{"boosts.log"}})

client:on('memberUpdate', function(member) --FALLBACK
	if member.guild and (not member.guild.systemChannelId) and member.premiumSince then
		if (discordia.Date() - discordia.Date.parseISO(member.premiumSince)):toSeconds() <= 2 then
			client:emit("memberBoost", member)
		end
	end
end)

client:on('messageCreate', function(message)
	if message.guild and message.guild.systemChannel then
		if message.type == 8 then
			client:emit("memberBoost", message.member)
		end
	end
end)

client:on('memberBoost', function(member)
	appdata.append("boosts.log", "lvl: " .. member.guild.premiumTier .. ", user: " .. member.user.name)
	output("some shithead (" .. member.user.mentionString .. ") actually boosted the server")
	member.user:send("ok listen man, you gotta use your money better okay. We do not take kindly to boosting around these parts. Goodbye!")
	proxout(member:ban("not good with money"))
end)

--BAN AND KICK NOTIFS--

-- client:on('userBan', function(user, guild)
	-- local ban = guild:getBan(user.id)
	-- local reason = ""
	-- if ban.reason then
		-- reason = "\n\nreason: " .. ban.reason
	-- end
	-- user:send("you got banned from Bread Bag bitch!!!!" .. reason)
-- end)

-- local invite_channels = {"844020172851511296", "872304924455764058"}

-- client:on('userUnban', function(user, guild)
	-- user:send("you are unbanned from Bread Bag now. heres a link to get you back in: https://discord.gg/" .. guild:getChannel(invite_channels[math.random(1, #invite_channels)]):createInvite({max_age = 0, max_uses = 1}).code)
-- end)

client:on("channelUpdate", function(channel)
	if channel.id == "822165179692220479" or channel.id == "822172725455355924" or channel.id == "822172820322517025" then
		if channel.parent.id ~= "822165179692220477" then
			channel:setCategory("822165179692220477")
		end
	end
end)

client:on('messageCreate', function(message)
	if message.author.id == _config.users.vective and #message.content > 5 and message.content:match("^%L$") and message.content:match("%u") then
		message:addReaction("<:penus:989950618481360896>")
	end
end)

client:run('Bot ' .. tokens.getToken( 1 ))