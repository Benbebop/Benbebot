local stuff = io.open("tables/emoji.index", "rb")
local str = stuff:read("*a")
stuff:close()

local output = io.open("tables/emoji_final.index", "wb")

for i in str:gmatch("[^%s%w%d%.%[%]%(%)#=_;:-]+") do
	output:write(i, string.char(31))
end

output:close()