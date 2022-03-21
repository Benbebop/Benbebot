local discordia, http, json, thread, lwz, roleGiver, appdata, holiday = require('discordia'), require("coro-http"), require("json"), require("coro-thread-work"), require("./lua/lualwz"), require("./lua/roleGiver"), require("./lua/appdata"), require("./lua/holiday")
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
	print("today is " .. holiday.text)
end

client:on('ready', function()
	allRoles = roleGiver.getRolePatterns( client:getGuild(myGuild).roles )
	dClock:start()
	setHoliday( holiday() )
	io.write("Logged in as ", client.user.username, "\n")
end) 
-- API RESET --
local apiTracker = require("./lua/api/tracker")

dClock:on("hour", function()
	print("clearing api tracker")
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
	local target = command.get(arg or "")
	if target and not arg:match("help") then message.channel:send(arg .. " " .. target.stx .. "| " .. target.desc) return end
	local str = ""
	for _,v in ipairs(command.get()) do
		if not v.stx:match("^%s?$") then
			v.stx = v.stx .. " "
		end
		str = str .. "bbb " .. v.name .. " " .. v.stx .. "| " .. v.desc .. "\n"
	end
	message.channel:send(str)
end, nil, "shows a list of commands", true)

command.new("status", function( message ) -- RETURNS STATUS OF SERVER --
	if (message.channel.id == "831564245934145599") or (message.channel.id == "832289651074138123") or true then
		message.channel:broadcastTyping()
		local dVersion, version, status, cpu, memory, networkrecieve, networktransfer, networksignal, duration = server.getStatus()
		message.channel:send("benbebot is online | discordia " .. dVersion .. " | " .. version .. "\nServer Status: " .. status .. "\ncpu: " .. cpu .. "%, memory: " .. memory .. " GB\nrecieve: " .. networkrecieve .. ", transfer: " .. networktransfer .. ", signal: " .. networksignal .. "%\nuptime: " .. math.floor( os.clock() / 60 / 6 ) / 100 .. "h")
		print("status requested by " .. message.author.name .. " (" .. duration .. "s)")
	end
end, nil, "get server status")

command.new("event", function( message, argument ) -- RUNS AN EVENT --
	local eventid = argument:match("(%d+)%s*$")
	if eventid == "0000" then
		client:getGuild(myGuild):getChannel(botChannel):send("success")
	end
	print("event number " .. eventid .. " triggered by " .. message.author.name)
end, "<event id>", "runs an event in the server")

command.new("random", function( message, argument ) -- MAKES A RANDOM NUMBER --
	local initial, final = argument:match("(%d+)%s(%d+)%s*$")
	if initial and final then
		message.channel:send(tostring(math.random(initial, final)))
	end
end, "<lower limit> <upper limit>", "generates a random number")

command.new("define", function( message, argument ) -- DEFINES A WORD --
	local success, result = websters.getDefinition( argument:match("(%a+)%s*$") )
	if result then
		message.channel:send(result)
	elseif success then
		message.channel:send("couldnt find definition for " .. todefine)
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
				message.channel:send( tostring( result ) )
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
	local success, result = youtube.getSchoolAnnouncements()
	if success then
		local mString = client:getRole("920088237568032768").mentionString
		for _,v in ipairs(result) do
			client:getGuild(myGuild):getChannel("823397621887926272"):send(mString .. "\nhttps://www.youtube.com/watch?v=" .. v)
		end
	elseif result then
		client:getGuild(myGuild):getChannel(botChannel):send(message.author.mentionString .. " no new announcement videos found")
	else
		client:getGuild(myGuild):getChannel(botChannel):send(message.author.mentionString .. " bot has exeded maximum api calls, please wait an hour before trying again")
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
	message.channel:send({
		embed = {
			fields = {
				{
					name = target.name .. "'s pp", value = "8" .. string.rep("=", r) .. "D", inline = true}
				},
				color = discordia.Color.fromRGB((9 - math.min( r, 9 )) / 9 * 255, math.min( r, 9 ) / 9 * 255, 0).value
			},
		refrence = {message = message.id, mention = false}
	})
end, "<target>", "imperical measurement of a man's penis")

command.new("randomyt", function( message ) -- PENID --
	message.channel:broadcastTyping()
	local _, result = http.request("GET", "https://petittube.com/")
	result = result:match("<iframe%s?width=\"%d+\"%s?height=\"%d+\"%s?src=\"(.+)\"%s?frameborder=\"%d+\"%s?allowfullscreen>")
	local address = result:match("https://www.youtube.com/embed/([%w%_]+)")
	message.channel:send("https://www.youtube.com/watch?v=" .. address)
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
	message.channel:send("https://github.com/Benbebop/Benbebot")
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
			message.channel:send("succesfully fired")
		else
			table.insert(forceEmployed, target.id)
			target:addRole("930996065329631232")
			message.channel:send("succesfully employed")
		end
		initFile = appdata.get("employed.dat", "w+")
		initFile:write(json.stringify(forceEmployed))
		initFile:close()
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
		message.channel:send({
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
			refrence = {message = message.id, mention = false}
		})
	end
end, "", "", true)

command.new("clash", function( message )
	if true then
		initFile = io.open("coc/jwt_token.json")
		local data = json.parse(initFile:read("*a"))
		initFile:close()
		print(data.header, data.payload)
		local _, clan = http.request("https://api.clashofclans.com/v1/clans/%232Q2Y88JV8", data.header, data.payload)
		local lvlValue = math.min( clan.clanLevel / 10, 1 ) * 255
		message.channel:send {
			embed = {
				title = "Clan: " .. clan.name,
				description = clan.description,
				image = {
					url = clan.badgeUrls.small,
					height = 70,
					width = 70
				},
				color = discordia.Color.fromRGB(255 - lvlValue, lvlValue, 0).value,
				timestamp = discordia.Date():toISO('T', 'Z')
			}
		}
	end
end, "", "checks status of the server's clan")

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
					client:getChannel(botChannel):send("could not add permarole " .. client:getRole(i).name .. " to " .. member.name .. " (" .. err:gsub("\n", " ") .. ")")
				elseif not member:hasRole(i) then -- if no error but still doesnt have role
					print("addRole() failed, no error")
				else -- success
					print("added permarole \"" .. client:getRole(i).name .. "\" to " .. member.name)
					table.insert(dCheck, member.id)
				end
			else
				client:getChannel(botChannel):send("role " .. i .. " no longer exists, removing")
				permroles[member.id][i] = nil
				roleGiver.savePermaroles( permroles ) -- save the profile to files
			end
		end
	end
end)

dClock:on("min", function() -- fix for role giver bug
	if #dCheck ~= 0 then
		for i,v in ipairs(dCheck) do
			local member = client:getGuild(myGuild):getMember(v)
			for l in pairs(permroles[v]) do
				member:addRole(l)
				if member:hasRole(l) then
					table.remove(dCheck, i)
				end
			end
			print("dChecked permarole for " .. member.name)
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
						print("added role \"" .. role.name .. "\" to permarole profile of " .. target.name)
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
						print("deleted role " .. client:getRole(v).name .. " from " .. message.member.name)
					else
						message.member:addRole(v)
						message.channel:send("added role \"" .. role.name .. "\"")
						print("gave " .. message.member.name .. " role " .. client:getRole(v).name)
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
				print("gave " .. message.member.name .. " new roles ")
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
	initFile = io.open("scBackup.txt", "wb")
	local _, result = http.request("GET", "https://raw.githubusercontent.com/Benbebop/Benbebot/main/scBackup.txt")
	initFile:write(result)
	initFile:close()
	local mashup, nextMashup, count, index = soundcloud.getMashup(), soundcloud.nextMashup(), soundcloud.count()
	if nextMashup then
		client:getUser(users.ben):getPrivateChannel():send("next Mashup of The Day: https://soundcloud.com/" .. nextMashup .. " (" .. index .. "/" .. count .. " " .. math.floor( index / count * 100 ) .. "%)")
	else
		client:getUser(users.ben):getPrivateChannel():send("no existing next Mashup of The Day!")
	end
	if not skip then
		if mashup then
			local message = client:getGuild(myGuild):getChannel(channels.announcement):send(client:getRole("938951562447953990").mentionString .. " Mashup of The Day!\n https://soundcloud.com/" .. mashup)
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
				client:getGuild(myGuild):getChannel(channels.announcement):send({
					content = "why is everyone so mean to me?",
					file = "images/mean.jpg",
					reference = {
						message = latestMotd.id,
						mention = false,
					}
				})
				latestMotd.meansent = true
			end
		end
	end
end)

client:on('messageCreate', function(message)
	if message.channel.id == client:getUser(users.ben):getPrivateChannel().id then -- AMONG US VENT CHAT --
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
	if message.channel.id == "862470542607384596" then -- AMONG US VENT CHAT --
		if message.content:lower():match("amo%a?g%s?us") then
			message.member:addRole("823772997856919623")
			print(message.author.name .. " said among us in #rage-or-vent")
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
			print(message.author.name .. " is saying racial slurs")
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
			print(message.author.name .. " was succesfully blocked")
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
		member:addRole("930996065329631232")
	elseif member.nickname and member.nickname:match(company.autoemploy) then
		local success, _, found = websters.getDefinition( member.nickname:match("%a+ier%s*$"):gsub("%s", "") )
		if not success then
			client:getChannel(botChannel):send(member.user.mentionString .. " API usage exeded, contact a mod or wait an hour bitch. https://tenor.com/view/grrr-heheheha-clash-royale-king-emote-gif-24764227")
			return
		end
		if found then
			member:addRole("930996065329631232")
		else
			member:removeRole("930996065329631232")
			client:getChannel(botChannel):send("so close, but \"" .. member.nickname:match("%a+ier%s*$"):gsub("%s", "") .. "\" isnt a real word! If you think this is a mistake please ask a mod. " .. member.user.mentionString)
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
		elseif message.content:match("[addimplement].sex") then
			message:delete()
			message.channel:send("im not fucking adding sex shut the fuck up")
		end
	end
end)

client:run('Bot ' .. require("./lua/token").getToken( 1 ))