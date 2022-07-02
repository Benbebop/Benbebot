-- benbebot value encoder v0.6

local function justify( s, l, c )
	while #s < l do s = c .. s end
	return s
end

local function todec( bin )
	return tonumber( bin, 2 )
end

local function tobin(x)
	if type(x) == str then x = tonumber(x) end
	ret=""
	while x~=1 and x~=0 do
		ret=tostring(x%2)..ret
		x=math.modf(x/2)
	end
	ret=tostring(x)..ret
	return ret
end

local e = {}

function e.encodenumber( num )
	local debugstr = ""
	local bin = tobin(num):gsub("%..-$", "")
	local bytes = {}
	for v in bin:gmatch("%d" .. string.rep("%d?", 6)) do table.insert(bytes, v) end
	local str = ""
	for i=1,#bytes - 1 do
		debugstr = debugstr .. "" .. bytes[i] .. " "
		str = str .. string.char(tonumber(bytes[i], 2))
	end
	debugstr = debugstr .. "" .. bytes[#bytes] .. ""
	str = str .. string.char(tonumber("1" .. bytes[#bytes], 2))
	return str, debugstr
end

function e.decodenumber( str )
	local debugstr = ""
	local bytes = {}
	for v in str:gmatch(".") do table.insert(bytes, tobin(string.byte(v))) end
	local num = ""
	for i=1,#bytes - 1 do
		debugstr = debugstr .. "" .. justify(bytes[i], 7, "0") .. " "
		num = num .. justify(bytes[i], 7, "0")
	end
	debugstr = debugstr .. "" .. bytes[#bytes]:gsub("^.", "") .. ""
	num = num .. bytes[#bytes]:gsub("^.", "")
	return todec(num), debugstr
end

function e.decodetext(str)
	if #str == 0 then return "" end
	local low = string.byte(str:sub(1, 1))
	str = str:sub(2, -1)
	local endstr = ""
	for i in str:gmatch(".") do
		endstr = endstr .. string.char(string.byte(i) + low)
	end
	return endstr
end

function e.encodetext(str)
	local low = math.huge
	for i in str:gmatch(".") do
		local b = string.byte(i)
		if b < low then
			low = b
		end
	end
	local endstr = string.char(low)
	for i in str:gmatch(".") do
		endstr = endstr .. string.char(string.byte(i) - low)
	end
	return endstr
end

local characterSet = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-_"

function e.toBase(num, base)
	base = base or #characterSet

	local str = ""

	while num > 0 do
		local q = math.floor(num / base)
		local r = num % base

		str = str .. characterSet:sub(r + 1, r + 1)
		num = q
	end

	return str:reverse()
end

return e