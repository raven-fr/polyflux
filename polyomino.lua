local M = {}
M.__index = M

function M.def(name, shape)
	local new = setmetatable({name = name}, M)

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

	if name == "tetr.O" then print(#new.cells) end

	for line = 1, new.size do
		for column = 1, new.size do
			if new.cells[line][column] then
				new.bottom = line
			end
		end
		if new.bottom then
			break
		end
	end

	return new
end

local piece = {}
piece.__index = piece

function M:drop(field)
	local new = setmetatable({poly = self}, piece)
	new.field = field
	new.line = field.lines - (self.bottom - 1)
	new.column = math.floor(field.columns / 2 - self.size / 2 + 0.5) 
	new.rotation = 1
	if not new:can_occupy() then
		return
	end
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

function piece:get_cell(line, column, rotation)
	line, column = rotate(
		line, column, rotation or self.rotation, self.poly.size)
	return self.poly.cells[line + 1][column + 1]
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

function piece:place()
	for line = 0, self.poly.size - 1 do
		for column = 0, self.poly.size - 1 do
			local cell = self:get_cell(line, column)
			if cell then
				self.field.cells[self.line + line][self.column + column] = cell
			end
		end
	end
end

function piece:rotate(ccw)
	local rotation = self.rotation + (ccw and -1 or 1)
	if rotation > 4 then
		rotation = 1
	elseif rotation < 1 then
		rotation = 4
	end
	if not self:can_occupy(nil, nil, rotation) then
		return false
	end
	self.rotation = rotation
	return true
end

function piece:move(lines, columns)
	local line, column = self.line + lines, self.column + columns
	if self:can_occupy(line, column) then
		self.line = line
		self.column = column
		return true
	end
	return false
end

return M
