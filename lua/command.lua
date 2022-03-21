local m = {}

function m.parse( str )
	if (str:lower():match("^bbb") or str:lower():match("^benbebot")) then
		return str:lower():gsub("^bbb%s*", ""):gsub("^benbebot%s*", "")
	else
		return false
	end
end

local commands = {}

function m.new( command, callback, syntax, desc, hidden )
	commands[command] = { 
		func = callback, 
		stx = syntax or "", 
		desc = desc or "nil", 
		show = not hidden
	}
end

function m.get( command )
	if not command then
		local final = {}
		for i,v in pairs(commands) do
			if v.show then
				table.insert(final, {
					name = i,
					stx = v.stx,
					desc = v.desc
				})
			end
		end
		return final
	else
		return commands[command:match("^[%a%_]+")]
	end
end

function m.run( command, message )
	local index = command:match("^[%a%_]+")
	if commands[index] and message.author.id ~= "941372431082348544" then
		commands[index].func( message, command:gsub("^[%a%_]+%s+", "") )
	end
end

return m