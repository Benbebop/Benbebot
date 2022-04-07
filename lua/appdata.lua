local dir, fs = os.getenv('LOCALAPPDATA'), nil

local m = {}

function m.get( name, mode )
	mode = mode or "rb"
	return io.open(dir .. "\\benbebot\\" .. name, mode)
end

function m.init( data )
	for _,v in ipairs(data) do
		if v[1]:match("[/\\]$") then
			--os.execute("mkdir " .. dir .. "\\benbebot\\" .. v[1]:gsub("[/\\]$", ""))
		else
			local testfor = m.get( v[1], "r" )
			if not testfor then
				testfor = m.get( v[1], "w" )
				testfor:write(v[2] or "")
			end
			testfor:close()
		end
	end
end

function m.directory()
	dir = os.getenv('LOCALAPPDATA')
	return dir .. "\\benbebot\\"
end

return m