local M = {}
M.__index = M

local function line_index(cells, k)
	if type(k) == 'number' and math.floor(k) == k then
		cells[k] = {}
		return cells[k]
	end
end

function M.new(lines, columns)
	local new = setmetatable({}, M)
	new.lines, new.columns = lines, columns
	new.cells = setmetatable({}, {__index = line_index})
	return new
end

function M:cell_full(line, column)
	if line >= 1 and column >= 1 and column <= self.columns then
		return self.cells[line][column] or false
	else
		return true
	end
end

function M:line_cleared(line)
	for column = 1, self.columns do
		if not self:cell_full(line, column) then
			return false
		end
	end
	return true
end

function M:remove_line(line)
	for line = line, self.lines * 2 do
		for column = 1, self.columns do
			self.cells[line][column] = self.cells[line + 1][column]
		end
	end
end

function M:insert_line(line)
	for line = self.lines * 2, -line + 1 do
		for column = 1, self.columns do
			self.cells[line][column] = self.cells[line - 1][column]
		end
	end
end

function M:remove_cleared()
	local line = 1
	while line < self.lines * 2 do
		if self:line_cleared(line) then
			self:remove_line(line)
		else
			line = line + 1
		end
	end
end

return M
