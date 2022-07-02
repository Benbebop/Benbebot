local discordia, tokens, appdata, roleGiver, emoji, subtitle = require('discordia'), require("./lua/token"), require("./lua/appdata"), require("./lua/roleGiver"), require("./lua/emoji"), require("./lua/srt")

local client = discordia.Client({cacheAllMembers = true})

local channel = "822165179692220479"
local guild = "822165179692220476"

function split(lenth, str)
	length = tonumber(length or 1999)
	local cursor = 0
	repeat
		cursor = cursor + length + 1
		repeat until client:getChannel(channel):send(str:sub(cursor - length, cursor))
	until #str:sub(cursor - length, cursor) < length
end

appdata.init({{"takeover_backups/"},{"send.log"}})

client:on('ready', function()
	io.write("Logged in as ", client.user.username, "\n")
	repeat
		local bollox = io.read():gsub("[^\\]\\n", "\n")
		appdata.append("send.log", "\n" .. bollox)
		if bollox:match("^%s*%-%-") then
			local command, arg = bollox:match("^%s*%-%-%s*([^%s]+)%s*(.-)$")
			if command == "channel" then
				channel = arg:match("(%d+)")
			elseif command == "ban" then
				client:getGuild(guild):getMember(arg):ban("FUCK YOU")
			elseif command == "kick" then
				client:getGuild(guild):getMember(arg):kick("FUCK YOU")
			elseif command == "spam" then
				local duration, message = arg:match("^(%d+)%s*(.-)$")
				for i=1,tonumber(duration) do
					repeat until client:getChannel(channel):send(message:gsub("%%i", i))
				end
			elseif command == "split" then
				split(arg:match("^(%d+)%s*(.-)$"))
			elseif command == "say" then
				local f = io.open("say.txt", "rb")
				local s = f:read("*a")
				f:close()
				split(arg:match("^(%d+)%s*$"), s)
			elseif command == "run" then
				local f = assert(loadstring(arg))
				setfenv(f, {discordia = discordia, client = client, json = require("json"), print = p, emoji = emoji, pcall = pcall})
				p(f())
			elseif command == "dm" then
				channel = client:getUser(arg:match("(%d+)")):getPrivateChannel().id
			elseif command == "takeover" then
				local i = 0
				repeat i = i + 1 until not appdata.exists("takeover_backups/takeover_" .. i .. ".dat")
				local STX, ETX, GS, RS, US = string.char(2), string.char(3), string.char(29), string.char(30), string.char(31)
				local f = appdata.get("takeover_backups/takeover_" .. i .. ".dat", "wb")
				local g = client:getGuild(guild)
				f:write("REWARD", STX, arg .. " Takeover Survivors", ETX, GS, "REPLACE", STX, arg, ETX, GS, "GUILD", STX, g.name, US, g.description or "", ETX, GS, "CATAGORIES", STX)
				g.categories:forEach(function(c)
					f:write(c.id, US, c.name, RS)
				end)
				f:close() f = appdata.get("takeover_backups/takeover_" .. i .. ".dat", "ab")
				f:write(ETX, GS, "TEXTCHANNELS", STX)
				g.textChannels:forEach(function(t)
					f:write(t.id, US, t.name, US, t.topic or "", RS)
				end)
				f:close() f = appdata.get("takeover_backups/takeover_" .. i .. ".dat", "ab")
				f:write(ETX, GS, "VOICECHANNELS", STX)
				g.voiceChannels:forEach(function(v)
					f:write(v.id, US, v.name, RS)
				end)
				f:close() f = appdata.get("takeover_backups/takeover_" .. i .. ".dat", "ab")
				f:write(ETX, GS, "ROLES", STX)
				g.roles:forEach(function(r)
					f:write(r.id, US, r.name, RS)
				end)
				f:close() f = appdata.get("takeover_backups/takeover_" .. i .. ".dat", "ab")
				f:write(ETX, GS, "MEMBERS", STX)
				g.members:forEach(function(m)
					f:write(m.id, US, m.name, RS)
				end)
				f:write(ETX)
				f:close()
				local confirm = appdata.read("takeover_backups/takeover_" .. i .. ".dat")
				local function set(c)
					if confirm:match(c.id) then
						c:setName(arg)
					else
						print("could not locate " .. c.name .. " in backup file, skipping")
					end
				end
				g.categories:forEach(set)
				g.textChannels:forEach(set)
				g.voiceChannels:forEach(set)
				g.roles:forEach(set)
				g.members:forEach(function(c)
					if confirm:match(c.id) then
						c:setNickname(arg)
					else
						print("could not locate " .. c.name .. " in backup file, skipping")
					end
				end)
			elseif command == "undotakeover" then
				local i = 0
				repeat i = i + 1 until not appdata.exists("takeover_backups/takeover_" .. i .. ".dat")
				local STX, ETX, GS, RS, US = string.char(2), string.char(3), string.char(29), string.char(30), string.char(31)
				local content = appdata.read("takeover_backups/takeover_" .. i - 1 .. ".dat")
				local textmatch = STX .. "([^" .. ETX .. "]+)" .. ETX
				local g = client:getGuild(guild)
				local name, description = content:match("GUILD" .. textmatch):match("^(.-)" .. US .. "(.-)$")
				g:setName(name) --g:setDescription(description)
				for record in content:match("CATAGORIES" .. textmatch):gmatch("[^" .. RS .. "]+") do
					local unit = record:gmatch("([^" .. US .. "]+)")
					g:getChannel(unit()):setName(unit())
				end
				for record in content:match("TEXTCHANNELS" .. textmatch):gmatch("[^" .. RS .. "]+") do
					local unit = record:gmatch("([^" .. US .. "]+)")
					local channel = g:getChannel(unit())
					channel:setName(unit())
					channel:setTopic(unit() or "")
				end
				for record in content:match("VOICECHANNELS" .. textmatch):gmatch("[^" .. RS .. "]+") do
					local unit = record:gmatch("([^" .. US .. "]+)")
					g:getChannel(unit()):setName(unit())
				end
				for record in content:match("ROLES" .. textmatch):gmatch("[^" .. RS .. "]+") do
					local unit = record:gmatch("([^" .. US .. "]+)")
					g:getRole(unit()):setName(unit())
				end
				local reward = g:createRole(content:match("REWARD" .. textmatch))
				reward:disableAllPermissions()
				reward:unhoist()
				for record in content:match("MEMBERS" .. textmatch):gmatch("[^" .. RS .. "]+") do
					local unit = record:gmatch("([^" .. US .. "]+)")
					local member = g:getMember(unit())
					if member.name:lower() == content:match("REPLACE" .. textmatch):lower() then
						member:setNickname(unit())
						member:addRole(reward.id)
					end
				end
			elseif command == "react" then
				local message = client:getChannel(channel):getMessage(arg)
				repeat until not message:addReaction(emoji.random())
			elseif command == "srt" then
				local timer, uv = require("timer"), require("uv")
				local start = uv.gettimeofday()
				local c = client:getChannel(channel)
				for _,tstart,_,content in subtitle.itterator(arg) do
					repeat until c:send(subtitle.format(content))
					local s, us = uv.gettimeofday()
					local t = s + (us / 1e6)
					print(math.max(0, tstart - (t - start)) * 10)
					timer.sleep(math.max(0, tstart - (t - start)) * 10)
				end
			elseif command == "srtunsync" then
				local c = client:getChannel(channel)
				for _,_,_,content in subtitle.itterator(arg) do
					repeat until c:send(content)
				end
			end
		else
			client:getChannel(channel):send(bollox)
		end
	until false
end) 



client:run('Bot ' .. tokens.getToken( ({benbebop = 1, ghetto = 14})[args[2] or "benbebop"] ))