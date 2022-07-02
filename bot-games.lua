local spawn, appdata, token, uv = require("coro-spawn"), require("./lua/appdata"), require("./lua/token"), require("uv")

--terraria config

local cfg = io.open("terraria/serverconfig.txt")
appdata.write("terraria/serverconfig.txt", cfg:read("*a"))
cfg:close()

local terraria_in = 0
if uv.tty_get_vterm_state() == "supported" then
	terraria_in = uv.new_tty(0, true)
end

local servers = {
	minecraft = assert(spawn("java", {
		stdio = {nil, true, true},
		args = {
			"-Xmx1024M",
			"-jar", "minecraft_server.1.18.2.jar"
		}
	})),
	terraria = assert(spawn("terraria/TerrariaServer.exe", {
		stdio = {terraria_in, true, true},
		cwd = appdata.directory() .. "terraria/",
		args = {"-config", "serverconfig.txt"}
	}))
}

local function doout()
	for name,proc in pairs(servers) do
		local prefix = "\n[" .. name .. "] "
		for chunk in proc.stdout.read do
			chunk = chunk:gsub("%s+$", ""):gsub("\n", prefix)
			io.write(prefix, chunk)
		end
	end
end

local function doerr()
	for name,proc in pairs(servers) do
		local prefix = "\n[" .. name .. "] "
		for chunk in proc.stderr.read do
			chunk = chunk:gsub("%s+$", ""):gsub("\n", prefix)
			io.write(prefix, chunk)
		end
	end
end

coroutine.wrap(doout)()
coroutine.wrap(doerr)()