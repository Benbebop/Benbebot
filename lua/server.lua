local s = {}

local ipconfig = io.popen("ipconfig")

s.ip = ipconfig:read("*a"):match("IPv4 Address[%s%.]+:%s+([%d%.]+)")

local file = io.open("terraria/serverconfig.txt")
local terraria = file:read("*a")
file:close()

s.terrariaport = terraria:match("\nport=(%d+)")
s.terrariapass = terraria:match("\npassword=(.-)\n")
s.terrariamotd = terraria:match("\nmotd=(.-)\n")

s.minecraftport = 25565

s.youtubeport = 8642

return s