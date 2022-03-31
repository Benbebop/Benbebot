local dir = os.getenv('LOCALAPPDATA')

local m = {}

function m.get( name, mode )
	mode = mode or "rb"
	return io.open(dir .. "\\benbebot\\" .. name, mode)
end

function m.init( data )
	for _,v in ipairs(data) do
		local testfor = m.get( v[1], "r" )
		if not testfor then
			testfor = m.get( v[1], "w" )
			testfor:write(v[2] or "")
		end
		testfor:close()
	end
end

return m