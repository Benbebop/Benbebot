local dir, fs = os.getenv('LOCALAPPDATA'), require("fs")

local m = {}

function m.get( name, mode )
	mode = mode or "rb"
	return io.open(dir .. "\\benbebot\\" .. name, mode)
end

function m.write( name, str )
	local f = io.open(dir .. "\\benbebot\\" .. name, "wb")
	f:write(str)
	f:close()
end

function m.append( name, str )
	local f = io.open(dir .. "\\benbebot\\" .. name, "a")
	f:write(str)
	f:close()
end

function m.exists( name )
	local f = io.open(dir .. "\\benbebot\\" .. name, "r")
	local exists = f ~= nil
	if exists then f:close() end
	return exists
end

function m.read( name, s, e )
	local f = io.open(dir .. "\\benbebot\\" .. name, "rb")
	local str = ""
	if s then
		f:seek(s - 1)
		str = f:read(e)
	else
		str = f:read("*a")
	end
	f:close()
	return str
end

function m.lines( name )
	return io.lines(dir .. "\\benbebot\\" .. name)
end

function m.modify( name, str, s, e )
	local f = io.open(dir .. "\\benbebot\\" .. name, "rb")
	local pre = f:read("*a")
	f:close()
	local f = io.open(dir .. "\\benbebot\\" .. name, "wb")
	f:write(pre:sub(1, s - 1) .. str .. pre:sub(e + 1, -1))
	f:close()
end

function m.replace( name, pattern, str )
	local f = io.open(dir .. "\\benbebot\\" .. name, "rb")
	local pre = f:read("*a")
	f:close()
	local f = io.open(dir .. "\\benbebot\\" .. name, "wb")
	f:write(pre:gsub(pattern, str))
	f:close()
end

function m.init( data )
	for _,v in ipairs(data) do
		if v[1]:match("[/\\]$") then
			fs.mkdir(dir .. "\\benbebot\\" .. v[1]:gsub("[/\\]$", ""))
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

function m.directory(forward_slash)
	dir = os.getenv('LOCALAPPDATA')
	if forward_slash then
		return dir:gsub("\\", "/") .. "/benbebot/"
	else
		return dir .. "\\benbebot\\"
	end
end

return m