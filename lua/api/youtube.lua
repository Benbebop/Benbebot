local http, json, tracker, getToken, appdata = require("coro-http"), require("json"), require("./lua/api/tracker"), require("./lua/token").getToken, require("./lua/appdata")

appdata.init({{"otmvideos.dat"}})

local m = {}

function m.getSchoolAnnouncements()
	if tracker.youtube() <= (100) / 24 then
		local tmpfile = appdata.get("otmvideos.dat", "a+")
		local otmVideos = tmpfile:read("*a")
		
		tracker.youtube( 1 )
		local _, result = http.request("GET", "https://www.googleapis.com/youtube/v3/search?key=" .. getToken( 3 ) .. "&channelId=UCxp1l0VLqE7yWUqmYbAuCxQ&part=id&order=date&maxResults=5")
		local data = json.parse(result).items
		
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
		return successful, announcements
	else
		return false
	end
end

return m