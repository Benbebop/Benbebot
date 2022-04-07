local lwz, json, appdata = require("./lua/lualwz"), require("json"), require("./lua/appdata")

local m = {}

function m.getRolePatterns( roles )
	local rolePatterns = {}
	roles:forEach(function( role )
		table.insert(rolePatterns, {
			id = role.id, 
			name = role.name, 
			pattern = "%s*" .. role.name:lower():gsub("%s", "%%s%*") .. "%s*"
		})
	end)
	return rolePatterns
end

function m.savePermaroles( roles )
	local prfile = appdata.get("permaroles.dat")
	prfile:write(json.stringify(roles))
	prfile:close()
end

function m.parseCommand( message )
	if (message.channel.id == "822174811694170133") then
		return 0
	end
end

return m