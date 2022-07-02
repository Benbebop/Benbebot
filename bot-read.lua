local discordia, tokens = require('discordia'), require("./lua/token")

local client = discordia.Client()

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

client:on('ready', function()
	repeat
		local bollox = io.read():gsub("[^\\]\\n", "\n")
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
				setfenv(f, {client = client, json = require("json"), print = p})
				p(f())
			elseif command == "dm" then
				channel = client:getUser(arg:match("(%d+)")):getPrivateChannel().id
			end
		else
			client:getChannel(channel):send(bollox)
		end
	until false
end) 

client:run('Bot ' .. tokens.getToken( 1 ))