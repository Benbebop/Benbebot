local langton = require("lua/langton/langton")

langton.reset( "RLRRLLRLRL" )

function r()
	langton.step()
	os.execute("cls")
	io.write(langton.ascii())
	--os.execute("pause")
	r()
end

os.execute("pause")

r()
