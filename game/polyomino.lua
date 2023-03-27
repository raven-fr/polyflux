local M = {}
M.__index = M

local evloop = require "evloop"
local debug_gfx = require "game.debug_gfx"

function M.def(name, shape, kick_table)
	local new = setmetatable({name = name}, M)
	new.kick_table = kick_table or {{{0, 0}}, {{0, 0}}, {{0, 0}}, {{0, 0}}}
	new.cells = {}
	for l in shape:gmatch "[^%s]+" do
		local line = {}
		new.size = #l
		for i = 1, #l do
			local c = l:sub(i, i)
			if c ~= "." then
				if c == "#" then
					line[i] = new.name
				else
					line[i] = new.name .. "." .. c
				end
			end
		end
		table.insert(new.cells, 1, line)
	end
	new.bottom = new.size
	new.top = 1
	new.left_side = new.size
	new.right_side = 1
	for line = 1, new.size do
		for column = 1, new.size do
			if new.cells[line][column] then
				if new.bottom > line then new.bottom = line end
				if new.right_side < column then new.right_side = column end
				if new.top < line then new.top = line end
				if new.left_side > column then new.left_side = column end
			end
		end
	end
	new.height = new.top - new.bottom + 1 
	new.width = new.right_side - new.left_side + 1
	return new
end

local rotations = {
	{1, 0, 0, 1},
	{0, 1, -1, 0},
	{-1, 0, 0, -1},
	{0, -1, 1, 0},
}

local function rotate(line, column, rotation, size)
	local center = size / 2 - 0.5
	line = line - center
	column = column - center
	local rotation = rotations[rotation or rotation]
	local l = line * rotation[1] + column * rotation[2]
	local c = line * rotation[3] + column * rotation[4]
	line = l + center
	column = c + center
	return line, column
end

function M:get_cell(line, column, rotation)
	line, column = rotate(line, column, rotation or 1, self.size)
	return self.cells[line + 1][column + 1]
end

local piece = {}
piece.__index = piece

function M:drop(field)
	local new = setmetatable({poly = self}, piece)
	new.field = field
	new.line = field.lines - (self.bottom - 1)
	new.column = math.floor(field.columns / 2 - self.size / 2 + 1)
	new.rotation = 1
	if not new:can_occupy() then
		return
	end
	return new
end

function piece:get_cell(line, column, rotation)
	return self.poly:get_cell(line, column, rotation or self.rotation)
end

function piece:can_occupy(line, column, rotation)
	line = line or self.line
	column = column or self.column
	for l = 0, self.poly.size - 1 do
		for c = 0, self.poly.size - 1 do
			if self:get_cell(l, c, rotation)
					and self.field:cell_full(line + l, column + c) then
				return false
			end
		end
	end
	return true
end

function piece:can_move(lines, columns, rotation)
	local rotation = self.rotation + (rotation or 0)
	if rotation > 4 then
		rotation = 1
	elseif rotation < 1 then
		rotation = 4
	end
	local line, column = self.line + lines or 0, self.column + columns or 0
	return self:can_occupy(line, column, rotation)
end

function piece:place()
	if self.placed then
		return
	end
	for line = 0, self.poly.size - 1 do
		for column = 0, self.poly.size - 1 do
			local cell = self:get_cell(line, column)
			if cell then
				self.field.cells[self.line + line][self.column + column] = cell
			end
		end
	end
	self.placed = true
end

function piece:rotate(ccw)
	local rotation = self.rotation + (ccw and -1 or 1)
	if rotation > 4 then
		rotation = 1
	elseif rotation < 1 then
		rotation = 4
	end
	for i,v in ipairs(self.poly.kick_table[ccw and rotation or self.rotation]) do
		local mul = ccw and -1 or 1
		local ty = self.line + v[2] * mul
		local tx = self.column + v[1] * mul

		--[[ debug rotation
		if i ~= 1 then
			evloop.paused = true
			local shadow = self.poly:drop(self.field)
			shadow.line = ty
			shadow.column = tx
			shadow.rotation = rotation
			debug_gfx.push(function(self)
				self:draw_piece_general(shadow, "only visual")
			end)
			evloop.debug_sleep(0.6)
			debug_gfx.pop()
			evloop.paused = false
		end
		]]

		if self:can_occupy(ty, tx, rotation) then
			self.rotation = rotation
			self.line = ty
			self.column = tx
			return true
		end
	end
	return false
end

function piece:move(lines, columns)
	if self:can_move(lines, columns) then
		self.line = self.line + lines or 0
		self.column = self.column + columns or 0
		return true
	end
	return false
end

return M
