local evloop = require "evloop"
local viewport = require "viewport"
local tetrominoes = require "game/tetrominoes"

local M = {}
M.__index = M

function M.new(game)
	local new = setmetatable({game = game}, M)
	return new
end

local colors = {
	["tetr.Z"] = {1, 0.2, 0.2},
	["tetr.I"] = {0.2, 1, 1},
	["tetr.J"] = {0.2, 0.2, 1},
	["tetr.L"] = {1, 0.5, 0.2},
	["tetr.O"] = {1, 1, 0.2},
	["tetr.S"] = {0.2, 1, 0.2},
	["tetr.T"] = {1, 0.2, 1},
}

function M:field_dimensions()
	local padding = 20
	local area_width = 1280 - padding * 2
	local area_height = 1080 - padding * 2
	local c, l = self.game.field.columns, self.game.field.lines

	local scalex, scaley = area_width / c, area_height / l
	local block_size
	if scalex * l < area_height then
		block_size = scalex
	else
		block_size = scaley
	end
	
	local x = padding + area_width / 2 - c * block_size / 2
	local y = padding + area_height / 2 - l * block_size / 2
	local w, h = block_size * c, block_size * l

	return block_size, x, y, w, h
end

function M:draw_square(block, x, y, block_size)
	if colors[block] then
		love.graphics.setColor(unpack(colors[block]))
	else
		love.graphics.setColor(1, 1, 1)
	end
	love.graphics.rectangle("fill", x, y, block_size, block_size)
end

function M:draw_block(block, line, column)
	local block_size, field_x, field_y, _, field_h = self:field_dimensions()
	local x = field_x + (column - 1) * block_size
	local y = field_y + field_h - line * block_size
	if block then self:draw_square(block, x, y, block_size) end
end

function M:draw_tetromino(tetromino, x, y, block_size, trim_margins)
	for yy, line in pairs(tetromino.cells) do
		for xx, cell in pairs(line) do
			local xxx = xx
			local yyy = yy
			yyy = tetromino.size - yyy + 1
			if trim_margins then
				xxx = xxx - tetromino.left_side + 1
				yyy = yyy - (tetromino.size-tetromino.top)
			end
			M:draw_square(cell, x + (xxx-1)*block_size, y + (yyy-1)*block_size, block_size)
		end
	end
end

function M:draw_tetromino_confined(tetromino, x, y, sidelength, margin)
	local dim = math.max(tetromino.width, tetromino.height)
	local block_size = sidelength/3
	local scale = 3/math.max(dim, 3)
	local tetr_x = x + margin/2 + (3-tetromino.width*scale)/2 * block_size
	local tetr_y = y + margin/2 + (3-tetromino.height*scale)/2 * block_size
	self:draw_tetromino(tetromino, tetr_x, tetr_y, scale * block_size, true)
end

function M:draw_hold()
	local block_size, field_x, field_y, field_w, field_h = self:field_dimensions()
	local hold_x = field_x - block_size - block_size/2 - block_size*3/2
	local hold_y = field_y
	local margin = block_size/2
	love.graphics.setColor(0, 0, 0)
	love.graphics.rectangle("fill", hold_x, hold_y, block_size*1.5 + margin, block_size*1.5 + margin)
	if not self.game.can_hold then
		love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
		love.graphics.rectangle("fill", hold_x, hold_y, block_size*1.5 + margin, block_size*1.5 + margin)
	end
	if not self.game.hold then return end
	self:draw_tetromino_confined(self.game.hold, hold_x, hold_y, block_size*3/2, margin)
end

function M:draw_queue()
	local block_size, field_x, field_y, field_w, field_h = self:field_dimensions()
	local queue = self.game.bag:lookahead(5)
	local margin = block_size/2
	local x, y = field_x + field_w + block_size, field_y
	love.graphics.setColor(0, 0, 0)
	love.graphics.rectangle("fill", x, y, block_size*1.5 + margin, (block_size*1.5 + margin) * 5)
	for i=1, #queue do
		self:draw_tetromino_confined(queue[i], x, y + (i-1)*(block_size*1.5 + margin), block_size*1.5, margin)
	end
end

function M:draw_piece()
	local piece = self.game.piece
	if not piece then return end
	for l = 0, piece.poly.size - 1 do
		if piece.line + l <= self.game.field.lines then
			for c = 0, piece.poly.size - 1 do
				local block = piece:get_cell(l, c)
				if block then
					self:draw_block(block, piece.line + l, piece.column + c)
				end
			end
		end
	end
end

function M:draw_field()
	local field = self.game.field
	local _, x, y, w, h = self:field_dimensions()
	love.graphics.setColor(0.1, 0.1, 0.1)
	love.graphics.rectangle("fill", x, y, w, h)
	for line = 1, field.lines do
		for column = 1, field.columns do
			self:draw_block(field.cells[line][column], line, column)
		end
	end
end

function M:draw(dt)
	love.graphics.setColor(0.2, 0.2, 0.2)
	love.graphics.rectangle("fill", 0, 0, 1920, 1080)
	self:draw_field()
	self:draw_piece()
	self:draw_hold()
	self:draw_queue()
end

function M:loop()
	local function loop()
		local _, dt = evloop.poll "draw"
		self:draw(dt)
		return loop()
	end
	return loop
end

return M