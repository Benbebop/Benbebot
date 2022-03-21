local m = {}

function m.getToken( index )
	index = index
	local token = io.lines("token")
	local ftoken = ""
	for i=1,index do
		ftoken = token():match("([^%s]+)%s*//")
	end
	return ftoken
end

return m