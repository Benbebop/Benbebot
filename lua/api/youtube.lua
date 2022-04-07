local http, json, tracker, getToken, appdata = require("coro-http"), require("json"), require("./lua/api/tracker"), require("./lua/token").getToken, require("./lua/appdata")

appdata.init({{"otmvideos.dat"}})

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

function m.stream( channel )
	
	return setmetatable({channel = channel, queue = {}, current = "", exists = true}, streamObj)
	
end

function streamObj:queue( url )
	if not self.exists then return end
	table.insert(self.queue, url)
end

function streamObj:progress()
	if not self.exists then return end
	self.current = self.queue[1]
	table.remove(self.queue, 1)
end

function streamObj:getPCM( part )
	if not self.exists then return end
	
end

function streamObj:leave()
	if not self.exists then return end
	self.exists = false
end

return m