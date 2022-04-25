local http, json = require("coro-http"), require("json")

local w = {}

local function createHeader( payload, content_type, connection, code, reason )
	content_type = content_type or "text/plain"
	connection = connection or "close"
	code = code or 500
	if code == 200 then reason = "" end
	reason = reason or "idk"
	return {
		{"Content-Length", #payload}, -- Must always be set if a payload is returned
		{"Content-Type", content_type}, -- Type of the response's payload (res_payload)
		{"Connection", connection}, -- Whether to keep the connection alive, or close it
		code = code,
		reason = reason,
	}
end

function w.create(host, port, callback)
	host, port = host or "0.0.0.0", port or 8080
	http.createServer(host, port, function( ... )
		local headers, payload, code = callback( ... )
		if not payload then payload = "" end
		if (not headers) or type(headers) ~= "table" then headers = createHeader(payload, nil, nil, code) end
		return headers, payload
	end)
end

return w