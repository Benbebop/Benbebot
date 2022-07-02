local tocompile = {"bot.lua", "bot-audioplayer.lua", "errorcatcher.lua", "errorcatcher-audioplayer.lua", "lua/encoder.lua"}

for _,v in ipairs(tocompile) do
	local i = io.open(v, "r")
	local o = io.open("compiled/" .. v:gsub("^.+[/\\]", ""), "w")
	local s, itter = "", 0
	for v in i:read("*a"):gmatch("[^\"']+[\"']?") do
		itter = itter + 1
		if itter % 2 ~= 0 then
			s = s .. v:gsub("%-%-.-\n", ""):gsub("[\n\t%s]+", " "):gsub("%s*(~?[%.=,<>^*%-%+{}%(%)/]=?)%s*", "%1"):gsub(",}", "}")
		else 
			s = s .. v 
		end
	end
	o:write(s)
	i:close() o:close()
end