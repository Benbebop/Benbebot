local http, json = require("coro-http"), require("json")

local m = {}

function m.applyMotd()
	initFile = io.open("scBackup.txt", "wb")
	local success, result = http.request("GET", "https://raw.githubusercontent.com/Benbebop/Benbebot/main/scBackup.txt")
	initFile:write(result)
	initFile:close()
end

return m