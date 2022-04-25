local success, err = pcall(require, './bot-audioplayer')

if not success then
	print(err)
	os.execute("pause")
	os.exit()
end