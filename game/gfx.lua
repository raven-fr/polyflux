local evloop = require "evloop"
local viewport = require "viewport"

local M = {}
M.__index = M

function M.new(game)
	local new = setmetatable({game = game}, M)
	return new
end

local colors = {
	["tetr.Z"] = {1, 0.2, 0.2},
	["tetr.I"] = {1, 0.7, 0.2},
	["tetr.J"] = {1, 1, 0.2},
	["tetr.L"] = {0.2, 1, 0.2},
	["tetr.O"] = {0.2, 0.2, 1},
	["tetr.S"] = {0.5, 0.2, 0.7},
	["tetr.T"] = {0.7, 0.2, 1},
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

function M:draw_block(block, line, column)
	local block_size, field_x, field_y, _, field_h = self:field_dimensions()
	local x = field_x + (column - 1) * block_size
	local y = field_y + field_h - line * block_size
	if block then
		if colors[block] then
			love.graphics.setColor(unpack(colors[block]))
		else
			love.graphics.setColor(1, 1, 1)
		end
		love.graphics.rectangle("fill", x, y, block_size, block_size)
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
