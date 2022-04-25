local discordia, appdata, tokens = require('discordia'), require("./lua/appdata"), require("./lua/token")

appdata.init({{"permaroles.dat","{}"},{"company.dat", "{}"},{"employed.dat","{}"}})

local client = discordia.Client()

local outputModes = {null = {255, 255, 255}, info = {0, 0, 255}, err = {255, 0, 0}, mod = {255, 100, 0}, warn = {255, 255, 0}}

local max_output_len, max_foot_len = 4048, 2048

function output( str, mode, overwrite_trace )
	print( str )
	if mode == "silent" then return end
	if #str >= max_output_len then
		str = str:sub(1, max_output_len / 2 - 3) .. "..." .. str:sub(#str - (max_output_len / 2 - 3), -1)
	end
	mode = mode or "null"
	local foot = nil
	if mode == "err" then foot = {text = debug.traceback()} end
	if overwrite_trace then foot = {text = overwrite_trace} end
	if #foot >= max_output_len then
		foot = foot:sub(1, max_foot_len / 2 - 3) .. "..." .. foot:sub(#foot - (max_foot_len / 2 - 3), -1)
	end
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

client:on('ready', function()
	sendPrevError()
end) 

local command, youtube = require("./lua/command"), require("./lua/api/youtube")

client:on('messageCreate', function(message)
	local content = command.parse(message.content)
	if content then
		command.run(content, message)
	end
end)

command.new("play", function( message, arg )
	
	if currentStream then
		
		currentStream:queue( arg, message.channel:send("loading please wait") )
		
	else
		
		if not message.member.voiceChannel then output("attempted to call play while not in voice channel", "warn") return end
		
		currentStream = youtube.stream( message.member.voiceChannel )
		
		currentStream:queue( arg, message.channel:send("loading please wait") )
		
	end
	
end, "<url>", "play a thing in a channel (work in progress)")

command.new("stop", function( message )
	
	if currentStream then
		
		currentStream:leave()
		
		currentStream = nil
		
	else
		
		 output("attempted to stop playing", "warn")
		
	end
	
end, nil, "stop playing a thing (work in progress)")

command.new("skip", function( message )
	
	if currentStream then
		
		currentStream:progress()
		
	else
		
		 output("attempted to skip", "warn")
		
	end
	
end, nil, "skip playing a thing (work in progress)")

client:on('voiceDisconnect', function()
	if currentStream then
		currentStream:leave()
		currentStream = nil
	end
end) 

client:run('Bot ' .. tokens.getToken( 1 ))