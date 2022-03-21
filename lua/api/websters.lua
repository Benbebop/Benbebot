local http, json, tracker, getToken = require("coro-http"), require("json"), require("./lua/api/tracker"), require("./lua/token").getToken

local m = {}

function m.getDefinition( toDefine )
	if tracker.webster() <= (1000) / 24 and toDefine then
		tracker.webster( 1 )
		local _, result = http.request("GET", "https://dictionaryapi.com/api/v3/references/collegiate/json/" .. toDefine:lower() .. "?key=" .. getToken( 4 ))
		local data, found = json.parse(result), false
		
		local toSay = "Websters Dictionary | " .. tracker.webster() .. "/" .. math.floor((1000) / 24) .. " \n"
		if data and toDefine then
			for i,v in ipairs(data) do
				if type(v) == "table" then
					found = true
					local word = "	**" .. v.meta.id:gsub("%:?%d*$", "") .. "**"
					if v.meta.offensive then --:face_with_symbols_over_mouth:
						word = word .. " :face_with_symbols_over_mouth:"
					end
					local definition = ""
					for l,k in ipairs(v.shortdef) do
						definition = definition .. l .. ": " .. k .. "\n"
					end
					toSay = toSay .. word .. "\n" .. definition
				else
					local word = "Рађ	***" .. tostring(v) .. "***"
					toSay = toSay .. word .. "\n"
				end
			end
			return true, toSay, found
		elseif toDefine then
			return true, toDefine, found
		end
	else
		return false, nil, found
	end
end

return m