local evloop = require "evloop"
local game = require "game"

local function main()
	evloop.poll "load"
	local game_obj = game.new {}
	evloop.poll "loaded"
	game_obj:run()
	evloop:quit()
end

local function update()
	evloop:queue("load", love.arg.parseGameArguments(arg), arg)
	evloop:queue "loaded"
	evloop.poll "loaded"
	local paused = false
	for e in evloop.events("update", "debug.pause", "debug.unpause") do
		if e == "debug.pause" then
			paused = true
		elseif e == "debug.unpause" then
			paused = false
		end
		if not paused then
			love.event.pump()
			local es = love.event.poll()
			while true do
				local e = {es()}
				if not e[1] then break end
				if love.handlers[e[1]] then
					love.handlers[e[1]](unpack(e, 2))
				end
				evloop:queue(unpack(e))
			end
		end

		local dt = love.timer.step()
		evloop:queue(not paused and "timer" or "debug.timer", dt)

		if love.graphics and love.graphics.isActive() then
			love.graphics.clear(love.graphics.getBackgroundColor())
			require "viewport".origin()
			evloop:queue "draw"
			evloop:queue "draw_complete"
			evloop.poll "draw_complete"
			love.graphics.present()
		end

		love.timer.sleep(0.001)
	end
end

evloop:wrap(update)
evloop:wrap(main)

local run = coroutine.wrap(function() evloop:run() end)

function love.run()
	if love.timer then love.timer.step() end
	return function()
		local val = run({"update"})
		if val == true then
			return
		elseif val == nil then
			return 0
		else
			return val
		end
	end
end
