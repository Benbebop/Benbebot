local http, json = require("coro-http"), require("json")

local w = {}

w.default_payload = ""
w.default_headers = {
   {"Content-Length", tostring(w.default_headers)}, -- Must always be set if a payload is returned
   {"Content-Type", "text/plain"}, -- Type of the response's payload (res_payload)
   {"Connection", "close"}, -- Whether to keep the connection alive, or close it
   code = 500,
   reason = "idk",
}

function w.create(host, port, callback)
	http.createServer(host, port, function( ... )
		local headers, payload = {callback( ... )}
		if not headers then headers = w.default_headers end
		if not payload then payload = w.default_payload end
		return headers, payload
	end)
end

return w