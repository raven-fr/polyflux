local evloop = require "evloop"
local viewport = require "viewport"
local tetrominoes = require "game/tetrominoes"
local debug_gfx = require "game.debug_gfx"

local font = love.graphics.newFont(20)
love.graphics.setFont(font)

local M = {}
M.__index = M

function M.new(assets, game)
	local new = setmetatable({}, M)
	new.assets = assets
	new.game = game
	new.text_sidebar = {{text = "this won't save you from the mind spiders.\n\n"}}
	return new
end

local colors = {
	["tetr.Z"] = {0, 1, 1},
	["tetr.I"] = {0.5, 1, 1},
	["tetr.J"] = {0.67, 1, 1},
	["tetr.L"] = {0.08, 1, 1},
	["tetr.O"] = {0.16, 1, 1},
	["tetr.S"] = {0.33, 1, 1},
	["tetr.T"] = {0.83, 1, 1},
}

function M:field_dimensions()
	local padding = 20
	local area_width = 1920 - padding * 2
	local area_height = 1080 - padding * 2
	local c, l = self.game.field.columns, self.game.field.lines

	local scalex, scaley = (area_width-500) / c, area_height / l
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

function M:draw_square(block, x, y, block_size, shadow)
	love.graphics.setColor(1, 1, 1, shadow and 0.2 or 1)
	local hueshift = self.assets.shader.hueshift
	love.graphics.setShader(hueshift)
	local hsv = colors[block] or {0, 0, 1}
	
	--hueshift:send("colorize_to",{(hsv[1] + love.timer.getTime()/5) % 1, math.sin(math.asin(hsv[2])+hsv[1]*math.pi*2+love.timer.getTime()/5), hsv[3]})
	hueshift:send("colorize_to", hsv)

	local img = self.assets.img.block
	local img_w, img_h = img:getDimensions()
	love.graphics.draw(img, x, y, 0, block_size / img_w, block_size / img_h)
end

function M:draw_block(block, line, column, shadow)
	local block_size, field_x, field_y, _, field_h = self:field_dimensions()
	local x = field_x + (column - 1) * block_size
	local y = field_y + field_h - line * block_size
	if block then self:draw_square(block, x, y, block_size, shadow) end
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
			self:draw_square(cell, x + (xxx-1)*block_size, y + (yyy-1)*block_size, block_size)
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

local function get_hold_size(self)
	local block_size, field_x, field_y, field_w, field_h = self:field_dimensions()
	local x = field_x - block_size - block_size/2 - block_size*3/2
	local y = field_y
	local margin = block_size/2
	local inner_size = block_size*3/2
	local size = inner_size + margin
	return x, y, margin, inner_size, size
end
function M:draw_hold()
	local block_size, field_x, field_y, field_w, field_h = self:field_dimensions()
	local x, y, margin, size = get_hold_size(self)
	love.graphics.setColor(0, 0, 0)
	love.graphics.rectangle("fill", x, y, block_size*1.5 + margin, block_size*1.5 + margin)
	if not self.game.can_hold then
		love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
		love.graphics.rectangle("fill", x, y, block_size*1.5 + margin, block_size*1.5 + margin)
	end
	if not self.game.hold then return end
	hold_size = block_size*3/2 + margin -- to be fair this is better described as padding.
	self:draw_tetromino_confined(self.game.hold, x, y, size, margin)
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

function M:draw_piece_general(piece,shadow)
	if shadow and shadow ~= "only visual" then
		local old_piece = piece
		piece = piece.poly:drop(self.game.field)
		piece.line = old_piece.line
		piece.column = old_piece.column
		piece.rotation = old_piece.rotation
		while piece:move(-1,0) do end
	end
	if not piece then return end
	for l = 0, piece.poly.size - 1 do
		if piece.line + l <= self.game.field.lines then
			for c = 0, piece.poly.size - 1 do
				local block = piece:get_cell(l, c)
				if block then
					self:draw_block(block, piece.line + l, piece.column + c, shadow)
				end
			end
		end
	end
end

function M:draw_piece(shadow)
	self:draw_piece_general(self.game.piece, shadow)
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
function M:draw_game_text()
	local font = love.graphics.getFont()
	local line_height = font:getHeight() * 3/2
	local hold_x, hold_y, _, _, hold_size = get_hold_size(self)
	local text_end_x = hold_x + hold_size
	local text_y = hold_y + hold_size + line_height
	
	for i, obj in ipairs(self.text_sidebar) do
		local y = text_y + (i-1) * line_height
		local newlines = 0
		for j=1, #obj.text do
			if obj.text:sub(j,j) == "\n" then newlines = newlines + 1 end
		end
		text_y = text_y + font:getHeight() * newlines
		if obj.color then
			love.graphics.setColor(unpack(obj.color))
		else
			love.graphics.setColor(1, 1, 1)
		end
		local j = 0
		for text in obj.text:gmatch("[^\n]+") do
			local w = font:getWidth(text)
			local x = text_end_x - w
			love.graphics.print(text, x, y + font:getHeight() * j)
			j = j + 1
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
	if self.game.piece then
		self:draw_piece(true) -- shadow.
	end
	self:draw_game_text()
	for i=1, #debug_gfx.stack do
		debug_gfx.stack[i](self)
	end
end

function M:run()
	for _, dt in evloop.events "draw" do
		self:draw(dt)
	end
end

return M
