local playfield = require "playfield"
local tetrominoes = require "tetrominoes"

local field
local piece

function love.load()
	field = playfield.new(20, 10)
end

function love.draw()
	local _, height = love.graphics.getDimensions()
	local size = height / field.lines

	love.graphics.setColor(0.1, 0.1, 0.1)
	love.graphics.rectangle("fill",
		0, 0, size * field.columns, size * field.lines)
	love.graphics.setColor(1, 1, 1)

	local function draw_block(line, column)
		local x = (column - 1) * size
		local y = height - line * size
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
end

local function gravity()
	if not piece then
		piece = tetrominoes.l:drop(field)
		assert(piece, "you lose.")
	else
		if not piece:move(-1, 0) then
			piece:place()
			piece = nil
		end
	end
end

local interval = 0.5
local ellapsed = 0

function love.update(dt)
	ellapsed = ellapsed + dt
	while ellapsed >= interval do
		gravity()
		ellapsed = ellapsed - interval
	end
end

function love.keypressed(key)
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
end
