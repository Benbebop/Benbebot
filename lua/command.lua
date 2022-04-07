local m = {}

function m.parse( str )
	if (str:lower():match("^bbb") or str:lower():match("^benbebot")) then
		return str:lower():gsub("^bbb%s*", ""):gsub("^benbebot%s*", "")
	else
		return false
	end
end

local commands = {}

local id = 0

function m.new( command, callback, syntax, desc, hidden )
	id = id + 1
	commands[command] = { 
		func = callback, 
		stx = syntax or "", 
		desc = desc or "nil", 
		show = not hidden,
		id = id
	}
end

function sort(tbl)
	local tblmax = 0
	for i in pairs(tbl) do
		tblmax = math.max(tblmax, tonumber(i))
	end
	local final = {}
	for i=1,tblmax do
		if tbl[i] then
			table.insert(final, tbl[i])
		end
	end
	return final
end

function m.get( command )
	if not command then
		local final = {}
		for i,v in pairs(commands) do
			if v.show then
				final[v.id] = {
					name = i,
					stx = v.stx,
					desc = v.desc
				}
			end
		end
		return sort(final)
	else
		return commands[command:match("^[%a%_]+")], command:match("^[%a%_]+")
	end
end

function m.run( command, message )
	local index = command:match("^[%a%_]+")
	if commands[index] and message.author.id ~= "941372431082348544" then
		commands[index].func( message, command:gsub("^[%a%_]+%s*", "") )
	end
end

return m