local http, json, tracker, getToken, appdata = require("coro-http"), require("json"), require("./lua/api/tracker"), require("./lua/token").getToken, require("./lua/appdata")

appdata.init({{"otmvideos.dat"},{"player_download/"},{"player_download/ytdl.conf",[[-x
-audio-format "wav"
-o %LOCALAPPDATA%/Local/benbebot/player_download/nil_file]]}})

local m = {}

function m.getSchoolAnnouncements()
	local resp = {status = "NOT SET", data = nil}

	if tracker.youtube() <= (100) / 24 then
		local tmpfile = appdata.get("otmvideos.dat", "a+")
		local otmVideos = tmpfile:read("*a")
		
		tracker.youtube( 1 )
		local success, result = http.request("GET", "https://www.googleapis.com/youtube/v3/search?key=" .. getToken( 3 ) .. "&channelId=UCxp1l0VLqE7yWUqmYbAuCxQ&part=id&order=date&maxResults=5")
		local data = json.parse(result)
		if not (success.code == 200 and data.items) then resp.status = "ERROR" resp.data = data return resp end
		data = data.items
		
		local append, successful, announcements = "", false, {}
		for i = #data, 1, -1 do
			local v = data[i]				
			if v.id.kind == "youtube#video" then
				local continue = otmVideos:match(v.id.videoId:gsub("%-", "%%%-")) == nil
				if continue then
					successful = true
					append = append .. "\t" .. v.id.videoId
					table.insert(announcements, v.id.videoId)
				end
			end
		end
		tmpfile:write(append)
		tmpfile:close()
		resp.status = "OK"
		resp.data = announcements
		return resp
	else
		resp.status = "ERROR"
		resp.data = "Youtube API max hourly usage exeeded"
		return resp
	end
end

function m.randomVideo()
	local resp = {status = "NOT SET", data = nil}

	local success, result = http.request("GET", "https://petittube.com/")
	if success.code ~= 200 then resp.status = "ERROR" resp.data = result return resp end
	
	result = result:match("<iframe%s?width=\"%d+\"%s?height=\"%d+\"%s?src=\"(.+)\"%s?frameborder=\"%d+\"%s?allowfullscreen>")
	local address = result:match("https://www.youtube.com/embed/([%w%_]+)")
	if not address then resp.status = "ERROR" resp.data = "couldn't parse petittube" return resp end
	
	resp.status = "OK"
	resp.data = address
	
	return resp
end

local streamObj = {}
streamObj.__index = streamObj

function m.stream( channel )
	
	--channel:setUserLimit(channel.userLimit + 1)
	
	return setmetatable({channel = channel, vc = channel:join(), songs = {}, current = "", exists = true}, streamObj)
	
end

function play(vc, file)
	local file = appdata.get(file, "rb")
	vc:playPCM(file:read('*all'))
	file:close()
end

function download(url, index)
	index = index or "nil_file"
	local file = io.popen("bin\\youtube-dl.exe --no-call-home -o %LOCALAPPDATA%/benbebot/player_download/file.%(ext)s " .. url):read("*a"):match("%[download%].-(%u:[^%s]+)")
	io.popen("bin\\ffmpeg.exe -y -i " .. file .. " %LOCALAPPDATA%/benbebot/player_download/file.wav")
	os.remove(file)
	return "player_download/file.wav"
end

function streamObj:queue( url, message )
	if not self.exists then return end
	message:setContent("queueing your file")
	table.insert(self.songs, url)
	if self.current == "" then
		self.current = self.songs[1]
		table.remove(self.songs, 1)
		message:setContent("downloading your file")
		local fuckyoufish21 = download(url, "playdata")
		message:setContent("downloaded file successfully")
		play(self.vc, fuckyoufish21)
		self.current = ""
		message:setContent("finished playing successfully")
	end
end

function streamObj:progress()
	if not self.exists then return end
	self.current = self.songs[1] or ""
	table.remove(self.songs, 1)
	play(self.vc, download(url, "playdata"))
end

function streamObj:leave()
	if not self.exists then return end
	self.exists = false
	self.channel, self.songs, self.current, self.vc = nil, nil, nil, nil
	--self.channel:setUserLimit(channel.userLimit - 1)
	self.channel:leave()
end

return m