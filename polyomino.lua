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

function piece:get_cell(line, column, rotation)
	return self.poly.cells[line + 1][column + 1]
end

function piece:can_occupy(line, column, rotation)
	line = line or self.line
	column = column or self.column
	for l = 0, self.poly.size - 1 do
		for c = 0, self.poly.size - 1 do
			if self:get_cell(l, c)
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
	return rotated
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
