-- literally my best written code ever im so proud

local function topurenumber(number)
	if type(number) ~= "number" then
		return 0
	else
		return number
	end
end

local m = {}

local function m.parse(str)
	local tbl = {}
	local cursor, cursorMax = 0, 0
	repeat
		-- KEY --
		
		local _, entryStart = string.find(str, "%s*", cursor) 
		-- the character before the key
		
		local key, keyStart, keyEnd = nil, nil, nil
		keyStart = topurenumber(entryStart) + 1
		-- start of key
		
		if string.sub(str, keyStart, keyStart + 1) == "\\\\"  then
			_, entryStart = string.find(str, "\n", entryStart)
			-- the end of the comment
			
			_, entryStart = string.find(str, "%s*", cursor) 
			-- the character before the key

			keyStart = entryStart + 1
			-- start of key
		end
		
		if string.sub(str, keyStart, keyStart) == "\""  then -- if first character of the key is a quote
			_, keyEnd = string.find(str, "[^\\]\"", keyStart + 1)
			-- end of key
			
			key = string.sub(str, keyStart + 1, tonumber(keyEnd) - 1)
			-- the key name
		else
			_, keyEnd = string.find(str, "%s", keyStart)
			keyEnd = topurenumber(keyEnd) - 1
			-- end of key
			
			key = string.sub(str, keyStart, keyEnd):gsub("+", " ")
			-- the key name
		end
		
		-- VALUE --
		
		local _, entryStart = string.find(str, "%s*", keyEnd + 1)
		-- the character before the value
		
		local value, valueStart, valueEnd, valueType = nil, nil, nil, nil
		valueStart = entryStart + 1
		-- start of value
		
		if string.sub(str, valueStart, valueStart + 1) == "\"\"" then -- if the value is an empty quote
			valueType = "string"
			-- type of the value
			
			valueEnd = entryStart + 2
			-- end of value
			
			value = ""
			-- the value content
		elseif string.sub(str, valueStart, valueStart) == "\"" then -- if first character of the value is a quote
			valueType = "string"
			-- type of the value
			
			_, valueEnd = string.find(str, "[^\\]\"", valueStart)
			-- end of value
			
			value = string.sub(str, valueStart + 1, valueEnd - 1)
			-- the value content
		else
			_, valueEnd = string.find(str, "%s", valueStart + 1)
			valueEnd = topurenumber(valueEnd) - 1
			-- end of value
			
			value = string.sub(str, valueStart, valueEnd)
			-- the value content
			
			if value:match("/") then -- if the value contains a slash
				valueType = "directory"
				-- type of the value
				
			elseif value:match("^[%d%.]*$") then -- if the value is entirely didgets
				valueType = "number"
				-- type of the value
				
				value = tonumber(value)	
				-- the value content
			elseif value == "{" then -- if the value is the start of a table
				valueType = "table"
				-- type of the value
				
				local tblCursor, bracketRatio, i = 0, 1, 0
				tblCursor = valueStart + 1
				-- first character of the key name
				
				repeat
					i = i + 1
					local _, t = string.find(str, ".-[{}]", tblCursor)
					t = t
					-- next open or closed bracket
					
					if str:sub(t, t) == "{" then -- if the bracket is open
						bracketRatio = bracketRatio + 1
						-- increase the ratio by 1
						
					elseif str:sub(t, t) == "}" then -- if the bracket is closed
						bracketRatio = bracketRatio - 1
						-- decrease the ratio by 1
						
					end
					
					print(i .. " : " .. str:sub(t - 2, t-1) .. ">" .. str:sub(t, t) .. "<" .. str:sub(t + 2, t+1))
					
					tblCursor = t + 1
					-- one character after the current bracket
					
				until bracketRatio <= 0 or i > 20000 or t == nil
				
				print("table start")
				
				local parseStr = string.sub(str, valueStart + 1, tblCursor - 2)
				
				value = parse(parseStr)
				-- the value content
				
				print("table end: " .. parseStr)
				
				valueEnd = #parseStr + valueStart + 1
				-- character after the last bracket of the table
			else
				valueType = "string"
			end
		end
		cursor = valueEnd + 1
		cursorMax = math.max(cursorMax, cursor)
		local dbgstr = str:gsub("\n", " ")
		tbl[key] = value
		local _, nextEntry = string.find(str, "%s*", cursor)
	until cursor < cursorMax or cursor >= #str
	return tbl
end

return m