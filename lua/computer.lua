local m = {}

function m.getStatus()
	local start = os.clock()
	local prompt = io.popen("wmic cpu get /value") local data = prompt:read("*a")
	local cpu = data:match("LoadPercentage=%d*"):match("%d+")
	local cpustatus = data:match("Status=%a+"):match("%a+$")
	prompt:close() prompt = io.popen("wmic os get /value") data = prompt:read("*a")
	local memory = data:match("FreePhysicalMemory=%d*"):match("%d+") / 1e+6
	local osstatus = data:match("Status=%a+"):match("%a+$")
	prompt:close() prompt = io.popen("WMIC Path Win32_Battery Get BatteryStatus /value") data = prompt:read("*a")
	local batterystatus = data:match("BatteryStatus=%d+"):match("%d+$")
	prompt:close() prompt = io.popen("netsh wlan show interfaces") data = prompt:read("*a")
	local networkconnected = data:match("State%s*:%s*%a+"):match("%a+$")
	local networkrecieve = data:match("Receive%s*rate%s*%(Mbps%)%s*:%s*%d+%.?%d+"):match("%d*%.?%d+$")
	local networktransfer = data:match("Transmit%s*rate%s*%(Mbps%)%s*:%s*%d+%.?%d+"):match("%d*%.?%d+$")
	local networksignal = data:match("Signal%s*:%s*%d+%%"):match("%d+")
	prompt:close()
	local status = "OK"
	if cpustatus ~= "OK" or osstatus ~= "OK" then
		print("WARNING: cpustatus=" .. cpustatus .. ", osstatus" .. osstatus)
		status = "ERROR"
	elseif batterystatus ~= "2" then
		print("WARNING: server unplugged, power loss iminent")
		status = "BATTERY"
	elseif networkconnected ~= "connected" then
		print("WARNING: lost network connection")
		status = "LOSTCONNECTION"
	elseif testingMode then
		status = "TESTING"
	end
	return require('discordia\\package').version, _VERSION:lower(), status or "nil", cpu or "nil", math.floor( memory * 100 ) / 100 or "nil", networkrecieve or "nil", networktransfer or "nil", networksignal or "nil", os.clock() - start
end

return m