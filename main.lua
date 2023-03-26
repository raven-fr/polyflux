local evloop = require "evloop"
local viewport = require "viewport"
local playfield = require "game.playfield"
local tetrominoes = require "game.tetrominoes"

local field = playfield.new(20, 10)
local piece

local function draw()
	evloop.poll "draw"

	local size = viewport.height / field.lines

	love.graphics.setColor(0.1, 0.1, 0.1)
	love.graphics.rectangle("fill",
		0, 0, size * field.columns, size * field.lines)
	love.graphics.setColor(1, 1, 1)

	local function draw_block(line, column)
		local x = (column - 1) * size
		local y = viewport.height - line * size
		love.graphics.rectangle("fill", x, y, size, size)
	end

	for line = 1, field.lines do
		for column = 1, field.columns do
			if field.cells[line][column] then
				draw_block(line, column)
			end
		end
	end

	if piece then
		for line = 0, piece.poly.size - 1 do
			for column = 0, piece.poly.size - 1 do
				if piece:get_cell(line, column) then
					draw_block(piece.line + line, piece.column + column)
				end
			end
		end
	end

	return draw()
end

local function gravity()
	evloop.sleep(0.5)
	field:remove_cleared()
	if not piece then
		piece = tetrominoes.l:drop(field)
		assert(piece, "you lose.")
	else
		if not piece:move(-1, 0) then
			piece:place()
			piece = nil
		end
	end
	return gravity()
end

local function inputs()
	local _, key = evloop.poll "keypressed"
	if piece then
		if key == "left" then
			piece:move(0, -1)
		elseif key == "right" then
			piece:move(0, 1)
		elseif key == "down" then
			piece:move(-1, 0)
		elseif key == "up" then
			piece:rotate()
		end
	end
	return inputs()
end

function love.run()
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end
	if love.timer then love.timer.step() end
	return evloop.mainloop(function()
		evloop.await_any(inputs, gravity, draw)
	end)
end
