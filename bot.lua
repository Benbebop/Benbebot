local discordia, http, json, thread, lwz, roleGiver, appdata, holiday, tokens, str_ext = require('discordia'), require("coro-http"), require("json"), require("coro-thread-work"), require("./lua/lualwz"), require("./lua/roleGiver"), require("./lua/appdata"), require("./lua/holiday"), require("./lua/token"), require("./lua/string")

appdata.init({{"permaroles.dat","{}"},{"company.dat", "{}"},{"employed.dat","{}"}})

local client = discordia.Client()
local dClock = discordia.Clock()
local discordiaPackage = require('discordia\\package')

local myGuild, myId, botChannel = "822165179692220476", "941372431082348544", "832289651074138123"
local initFile = {}
local allRoles = {}
local helpText = require("./tables/helptext")

local channels = {
	bot = "832289651074138123",
	announcement = "823397621887926272"
}
local users = {
	larry = "463065400960221204",
	diego = "823215010461384735",
	ben = "459880024187600937",
	dankmemer = "270904126974590976",
	arcane = ""
}

local truncate = str_ext.truncate

local outputModes = {null = {255, 255, 255}, info = {0, 0, 255}, err = {255, 0, 0}, mod = {255, 100, 0}, warn = {255, 255, 0}}

local max_output_len, max_foot_len = 4048, 2048

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
	client:setAvatar("images/icons/" .. holiday.avatar)
	client:setUsername(holiday.name)
	client:getGuild(myGuild):getMember(client.user.id):setNickname(holiday.name)
	if holiday.game == "none" or holiday.game == "" then
		client:setGame()
	else
		client:setGame(holiday.game)
	end
	client:setStatus(holiday.status)
	--output("today is " .. holiday.text)
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
	allRoles = roleGiver.getRolePatterns( client:getGuild(myGuild).roles )
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
		command.run(content, message)
	end
end)

command.new("help", function( message, arg )
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

command.new("event", function( message, argument ) -- RUNS AN EVENT --
	local eventid = argument:match("(%d+)%s*$")
	if eventid == "0000" then
		client:getGuild(myGuild):getChannel(botChannel):send("success")
	end
	output("event number " .. eventid .. " triggered by " .. message.author.name)
end, "<event id>", "runs an event in the server")

command.new("random", function( message, argument ) -- MAKES A RANDOM NUMBER --
	local initial, final = argument:match("(%-?%d+)%s(%-?%d+)%s*$")
	if initial and final then
		initial, final = tonumber(initial), tonumber(final)
		if initial > final then initial, final = final, initial end
		proxout(message.channel:send(tostring(math.random(initial, final))))
	end
end, "<lower limit> <upper limit>", "generates a random number")

command.new("define", function( message, argument ) -- DEFINES A WORD --
	local success, content, found, title = websters.getDefinition( argument:match("(%a+)%s*$") )
	local result = websters.getDefinition( argument:match("(%a+)%s*$") )
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

command.new("calc", function( message, argument ) -- RENDER --
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
	if message.channel.id == channels.announcement then
		message:addReaction("👍")
		message:addReaction("👎")
	end
end, nil, "calls vote in announcemnt", true)

command.new("s_announce", function( message ) -- SCHOOL ANNOUNCMENT --
	message:delete()
	local announcement = youtube.getSchoolAnnouncements()
	if announcement.status ~= "OK" then output(announcement.data) return end
	local mString = client:getRole("920088237568032768").mentionString
	for _,v in ipairs(announcement.data) do
		client:getGuild(myGuild):getChannel("823397621887926272"):send(mString .. "\nhttps://www.youtube.com/watch?v=" .. v)
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
	if target.id == users.ben then
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
	local dm = client:getGuild(myGuild):getMember(users.dankmemer)
	local role = "951697964177428490"
	if dm:hasRole(role) then
		dm:removeRole(role)
	else
		dm:addRole(role)
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
	if message.member:hasRole("931740892245684254") and message.mentionedUsers.first then
		local target = client:getGuild(myGuild):getMember(message.mentionedUsers.first.id)
		local employed = false
		for i,v in ipairs( forceEmployed ) do
			if target.id == v then
				employed = i
				break
			end
		end
		if employed then
			forceEmployed[employed] = nil
			target:removeRole("930996065329631232")
			proxout(message.channel:send("succesfully fired"))
		else
			table.insert(forceEmployed, target.id)
			target:addRole("930996065329631232")
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

command.new("companyrebrand", function( message, argument ) -- PENID --
	if message.member:hasRole("931740892245684254") or message.author.id == users.ben then
		local gm = argument:gmatch("%b\"\"")
		local name, color, autoemploy, autofire = gm() or "", gm() or "", gm() or "", nil
		name, color, autoemploy, autofire = name:gsub("\"", ""), color:gsub("\"", ""), autoemploy:gsub("\"", ""), autofire == "true"
		local prevname, prevae = company.name, company.autoemploy
		if autoemploy:match("^%s*$") then 
			company.autoemploy = company.autoemploy
		else 
			company.autoemploy = autoemploy 
		end
		local g = client:getGuild(myGuild)
		local ceo, employ = g:getRole("931740892245684254"), g:getRole("930996065329631232")
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

local server_clan = "%23" .. "2Q2Y88JV8"

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

command.new("war_announce", function( message, arg )
	message:delete()
	if message.channel.id == channels.announcement then
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

local function wl( message, arg )
	message:delete()
	if true then--message.channel.id == channels.announcement then
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
	if message.author.id == users.paul then
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

command.new("twitter_id", function( message )
	if message.author.id == users.ben then
		local _, results = http.request("GET", "https://api.twitter.com/2/users/by/username/3Dgifdubstep", {{"Authorization", "Bearer " .. tokens.getToken( 8 )}})
		message.channel:send("id: " .. json.parse(results).data.id)
	end
end, "<username>", "internal command", true)

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
	if arg:match("^status") then
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

command.new("fifteenai", function( message, arg )
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
	if message.author.id == users.paul then
		local limit, duration = arg:match("(%d+)%s*(%d*)")
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

command.new("restart", function( message )
	if message.author.id == users.ben then
		os.exit()
	end
end, nil, "restarts server")

local toremind = {}

command.new("remind", function( message, args )
	local t, c, m = args:match("(%d+)%s*(%a)%s*(.-)$")
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
			proxout(client:getChannel(botChannel):send({
				content = toremind[i].mentionString,
				embed = {
					title = toremind[i].name .. "'s Reminder",
					description = toremind[i].message
				}
			}))
		end
	end
end)

command.new("pirate", function( message, arg )
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

command.new("play", function() end, "<url>", [[play a thing in a channel (if doesnt work check #benbebot-output and if you dont understand it, fuck you)

supported formats: http://ytdl-org.github.io/youtube-dl/supportedsites.html]] )

command.new("terraria", function( message, args )
	local file = io.open("terraria/serverconfig.txt")
	local cfg = file:read("*a")
	proxout(message.channel:send {
		embed = {
			title = "Bread Bag Terraria Server",
			fields = {
				{name = "Server IP Address", value = "25.5.156.164", inline = false},
				{name = "Server Port", value = cfg:match("\nport=(%d+)"), inline = false},
				{name = "Server Password", value = cfg:match("\npassword=(.-)\n"), inline = false},
			},
			description = cfg:match("\nmotd=(.-)\n"),
		}
	})
end, "<movie>", "terraria server data")

command.new("id", function( message, args )
	
end, "<id>", "checks a discord id")

local fBlacklist = {"privacy%.log", "player_download[\\/].*", "15ai[\\/].*"}

command.new("read", function( message, args )
	local black = false
	for _,v in ipairs(fBlacklist) do
		if args:match("^" .. v .. "$") then black = true break end
	end
	if black then
		message.channel:send("file is blacklisted")
		return
	end
	local f = appdata.get(args, "r")
	if f then
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
	local i = arg:match("%d+") or message.author.id
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

-- WEBHOOKS --

local webhook = require("./lua/webhook")

webhook.create(nil, 8642, function(req, body)
	output("incoming connection: \n" .. json.stringify(req), "http")
end)

-- Role Giver --
initFile = io.open("tables\\roleindex.json", "rb")
local basicRoles = json.parse(initFile:read("*a"))
initFile:close()

local function getPermaroles()
	initFile = appdata.get("permaroles.dat")
	local permroles = json.parse(initFile:read("*a"))
	initFile:close()
	return permroles
end

local dCheck = {}

client:on("memberJoin", function(member)
	local permroles = getPermaroles()
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
	if #dCheck ~= 0 then
		output("dChecking permaroles", "info")
		for i,v in ipairs(dCheck) do
			local member = client:getGuild(myGuild):getMember(v)
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
	if (message.channel.id == "822174811694170133") and (message.author.id ~= myId) then 
		local permroles = getPermaroles()
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
				if message.author.id == users.ben then
					message.channel:send("yea :thumbsup:")
				else
					message.channel:send("as fucking if")
				end
			elseif message.content:lower():match("^%s*%+%s*biggest%s?balls") then
				if message.author.id == users.diego then
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
	githubAPI.applyMotd()
	local mashup, nextMashup, count, index = soundcloud.getMashup(), soundcloud.nextMashup(), soundcloud.count()
	if nextMashup then
		client:getUser(users.ben):getPrivateChannel():send("next Mashup of The Day: https://soundcloud.com/" .. nextMashup .. " (" .. index .. "/" .. count .. " " .. math.floor( index / count * 100 ) .. "%)")
	else
		client:getUser(users.ben):getPrivateChannel():send("no existing next Mashup of The Day!")
	end
	if not skip then
		if mashup then
			local message = client:getGuild(myGuild):getChannel(channels.announcement):send("https://soundcloud.com/" .. mashup)
			latestMotd.id = message.id
			message:addReaction("👍")
			message:addReaction("👎")
			message:addReaction("🖕")
		else
			client:getGuild(myGuild):getChannel(channels.announcement):send("someone fucked up and there aint any mashup of the day!!!!!")
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
			client:getUser(users.ben):getPrivateChannel():send("meanness: " .. meanness)
			if meanness > 0.75 and total > 5 + 3 then
				proxout(client:getGuild(myGuild):getChannel(channels.announcement):send({
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
	if message.channel.id == client:getUser(users.ben):getPrivateChannel().id then
		if message.content:match("^%s*motd%sskip") then
			sendMotd( true )
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
end 
end)

dClock:on("hour", function()
	if os.date("%H") == soundcloud.getPostTime() then
		sendMotd()
	end
end)

client:on('messageCreate', function(message)
	if message.channel.id == "862470542607384596" then -- AMONG US VENT CHAT --
		if message.content:lower():match("amo%a?g%s?us") then
			message.member:addRole("823772997856919623")
			output(message.author.name .. " said among us in #rage-or-vent", "mod")
			message.channel:send("you are unfunny :thumbsdown:")
		end
	elseif message.author.id == "437808476106784770" and message.content:match("please do not use blacklisted words!") and latestDelAuth ~= "941372431082348544" then -- F --
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
		if mbefore:iter()().author.id == myId then
			fomessage:delete()
		end
	elseif message.author.id == users.ben and message.channel.id == channels.bot and message.content:match("force motd 12345") then
		message:delete()
		sendMotd()
	end
end)

client:on('messageDelete', function(message)
	latestDelMsg, latestDelAuth, latestDelAttach = message.content, message.author, message.attachments
end)

client:on('memberUpdate', function(member)
	local employed = false
	for i,v in ipairs(forceEmployed) do
		if member.id == v then
			employed = true
			break
		end
	end
	if member.nickname and member.nickname:match("^%s*gang%s+weed%s*$") then
		member:addRole("880305120263426088")
	elseif employed then
	elseif member.nickname and company.autoemploy and member.nickname:match(company.autoemploy) then
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
		member:removeRole("880305120263426088") member:removeRole("930996065329631232")
	end
end)

dClock:on("day", function()
	if os.date("%a") == "Mon" then
		local DankMemer = client:getGuild(myGuild):getMember(users.dankmemer)
		for id in pairs(DankMemer.roles) do
			DankMemer:removeRole(id)
		end
		DankMemer:addRole("951697964177428490")
	else
		local DankMemer = client:getGuild(myGuild):getMember(users.dankmemer)
		DankMemer:removeRole("951697964177428490")
		DankMemer:addRole("829754598327320607")
		DankMemer:addRole("822960808812216350")
	end
	setHoliday( holiday() )
end)

client:on('messageCreate', function(message)
	if message.author.id == users.dankmemer then
		if message.member:hasRole("951697964177428490") then
			message:delete()
		end
	end
end)

client:on('messageCreate', function(message)
	if message.channel.id == "955315272879849532" then
		if message.author.id == myId then
		elseif message.content:match("[addimplement].+sex") then
			message:delete()
			message.channel:send("im not fucking adding sex shut the fuck up")
		end
	end
end)

client:on('messageCreate', function(message)
	if message.channel.id == "959468256664621106" and message.author.id ~= "941372431082348544" then
		message:delete()
	end
end)

appdata.init({{"lastposted.log"}})

local lpf = appdata.get("lastposted.log", "r")
local lp = lpf:read("*a")
lpf:close()

client:on('messageCreate', function(message)
	if not message.author.bot then
		if lp:match("\n" .. message.author.id) then
			lp:gsub("(\n" .. message.author.id .. ") [^\n]+", "%1 " .. message:getDate():toISO(nil, "MST"))
		else
			lp = lp .. "\n" .. message.author.id .. " " .. message:getDate():toISO(nil, "MST")
		end
		lpf = appdata.get("lastposted.log", "w")
		lpf:write(lp)
		lpf:close()
		message.member:addRole("837714055731871836")
	end
end)

local function checkposted( member )
	if lp:match("\n" .. member.id) then
		local d = discordia.Date():fromISO(lp:match("\n" .. member.id .. " ([^\n]+)"))
		if discordia.Date():toSeconds() - d:toSeconds() > 2.628e+6 then
			member:removeRole("837714055731871836")
			lp:gsub("\n" .. member.id .. " ([^\n]+)", "")
			lpf = appdata.get("lastposted.log", "w")
			lpf:write(lp)
			lpf:close()
			output("removed " .. member.mentionString .. "'s member role for inactivity")
		end
	else
		member:removeRole("837714055731871836")
	end
end

dClock:on("day", function()
	client:getRole("837714055731871836").members:forEach(checkposted)
end)

command.new("member_scan", function( message )
	if message.author.id == users.ben then
		client:getRole("837714055731871836").members:forEach(checkposted)
	end
end, "", "scans all users in guild for posting in the last month")

client:run('Bot ' .. tokens.getToken( 1 ))