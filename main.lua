local evloop = require "evloop"
local game = require "game"

local game_obj

function love.load()
	game_obj = game.new {}
end

function love.run()
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end
	if love.timer then love.timer.step() end
	return evloop.mainloop(function()
		game_obj:loop()()
	end)
end
