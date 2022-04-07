local uv, p = require("uv"), {}

local m = {}

function m.getStatus()
	local prompt = io.popen("wmic cpu get /value") local data = prompt:read("*a")
	local cpu = p.cpuUsage()
	local memory = uv.get_free_memory() / 1e+6
	prompt:close() prompt = io.popen("WMIC Path Win32_Battery Get BatteryStatus /value") data = prompt:read("*a")
	local batterystatus = data:match("BatteryStatus=%d+"):match("%d+$")
	prompt:close() prompt = io.popen("netsh wlan show interfaces") data = prompt:read("*a")
	local networkconnected = data:match("State%s*:%s*%a+"):match("%a+$")
	local networkrecieve = data:match("Receive%s*rate%s*%(Mbps%)%s*:%s*%d+%.?%d+"):match("%d*%.?%d+$")
	local networktransfer = data:match("Transmit%s*rate%s*%(Mbps%)%s*:%s*%d+%.?%d+"):match("%d*%.?%d+$")
	local networksignal = data:match("Signal%s*:%s*%d+%%"):match("%d+")
	return require("discordia").package.version, _VERSION:lower()--, status or "nil", cpu or "nil", math.floor( memory * 100 ) / 100 or "nil", networkrecieve or "nil", networktransfer or "nil", networksignal or "nil", os.clock() - start
end

return m