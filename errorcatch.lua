local success, err = pcall(function() require("./" .. args[2]) end)

if not success then
	print(err)
	io.read()
end