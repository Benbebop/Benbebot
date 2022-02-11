local discordia, http, lualwz = require('discordia'), require("http"), require("lualzw")
local client = discordia.Client()

local users = {
	larry = "463065400960221204"
}

client:on('ready', function()
	io.write("Logged in as ", client.user.username, "\n")
end) 

-- Commands --
client:on('messageCreate', function(message)
	if message.content:match("^benbebot") then
		local command = message.content:gsub("^benbebot%s*", "")
		if command:match("status") then
			if (message.channel.id == "831564245934145599") or (message.channel.id == "832289651074138123") then
				message.channel:send([[benbebot is online | discordia 2.9.2 | ]] .. _VERSION:lower())
			end
		elseif command:match("event") then
			local eventid = command:match("%d*$")
			if eventid == "0000" then
				message.channel:send("success")
			end
		end
	end
end)

-- Role Giver --
local roles = {
	["pinged%s?for%s?stupid%s?shit"] = "938951562447953990",
	["pinged%s?for%s?important%s?shit"] = "938951721990893579",
	["gay"] = "869942564399247361",
	["member"] = "837714055731871836",
	["pedophobic"] = "872232039305347072",
	["the%s?true%s?furry"] = "863100222100340737",
	["mommy"] = "869615621535596585",
	["smallest%s?penis"] = "829785639385694229",
	["monke"] = "832528770572615730",
	["suffering"] = "826144739048030249",
	["UN"] = "867912530570395689",
	["big%s?floppa%s?lover"] = "828830283138072646",
	["kill%s?me"] = "866755277985153064",
	["nebraska%s?furniture%s?mart"] = "866752609801076756",
	["small%s?floppa%s?hater"] = "869944223015792690"
}

client:on('messageCreate', function(message)
	if message.channel.id == "822174811694170133" then
		if message.content:match("^%s*help") then
			message.channel:send([[bot helps u add roles by saying
+[insert role name]
you can remove it by saying
-[insert role name]

reccomended roles:

member, pinged for stupid shit, pinged for important shit

type "role list" for whole list]])
		elseif message.content:match("^%s*role%s?list") then
			local str = ""
			for i,v in pairs(roles) do
				str = str .. ", " .. client:getRole(v).name
			end
			message.channel:send(str:gsub(",%s$", ""))
		else
			for i,v in pairs(roles) do
				if message.content:lower():match("^%s*%-?%+?%s*" .. i) then
					if message.content:match("^%-") then
						message.member:removeRole(v)
						message.channel:send("removed role")
						print("deleted role " .. client:getRole(v).name .. " from " .. message.member.name)
					else
						message.member:addRole(v)
						message.channel:send("added role")
						print("gave " .. message.member.name .. " role " .. client:getRole(v).name)
					end
				end
			end
		end
	end
end)

-- Fun --
client:on('messageCreate', function(message)
	if message.channel.id == "822165758942642217" then
		if message.author.id == users.larry then
			message:delete()
			print("larry tried to make a rule!")
		end
	elseif message.channel.id == "862470542607384596" then
		if message.content:match("amo[n]?g%s?us") then
			message.member:addRole("823772997856919623")
			print(message.author.name .. " said among us in #rage-or-vent")
			message.channel:send("you are unfunny :thumbsdown:")
		end
	end
end)

client:run('Bot ' .. io.lines("token")())