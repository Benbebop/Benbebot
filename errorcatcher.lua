local success, err = pcall(require, './bot')

if not success then
	print(err)
	os.execute("pause")
	os.exit()
end