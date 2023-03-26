local tetrominoes = require "game.tetrominoes"

local M = {}
M.__index = M

M.new = function()
    local new = setmetatable({}, M)
    new.queue = {}
    new.pool = {}
    return new
end

function M:lookahead(amount)
    local res = {}
    for i=1, amount do
        if self.queue[i] then
            table.insert(res, self.queue[i])
        else
            if #self.pool == 0 then
                self.pool = {
                    tetrominoes.i,
                    tetrominoes.j,
                    tetrominoes.l,
                    tetrominoes.o,
                    tetrominoes.s,
                    tetrominoes.t,
                    tetrominoes.z,
                }
            end
            local choice = math.random(1, #self.pool)
            local choice_tetr = self.pool[choice]
            table.remove(self.pool, choice)
            table.insert(self.queue, choice_tetr)
            table.insert(res, choice_tetr)
        end
    end
    return res
end

function M:next_piece()
    local res = self:lookahead(1)[1]
    table.remove(self.queue, 1)
    return res
end

return M