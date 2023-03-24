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

function M:line_full(line)
	for column = 1, w do
		if self.cells[line][column] then
			return true
		end
	end
	return false
end


function M:shift_down(line)
end

function M:shift_up(line)
end

function M:clear_full()
end

return M
