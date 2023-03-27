local M = {}

M.stack = {}

function M.push(fn)
    table.insert(M.stack, fn)
end
function M.pop()
    M.stack[#M.stack] = nil
end

return M