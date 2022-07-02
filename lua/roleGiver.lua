local lwz, json, appdata = require("./lualwz"), require("json"), require("./appdata")

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

function m.getPermaroles()
	return json.parse(appdata.read("permaroles.dat"))
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