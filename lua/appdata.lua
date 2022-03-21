local m = {}

function m.get( name, mode )
	mode = mode or "rb"
	local dir = os.getenv('LOCALAPPDATA')
	return io.open(dir .. "\\benbebot\\" .. name, mode)
end

return m