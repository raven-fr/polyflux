local tetrominoes = require "game.tetrominoes"

local M = {}
M.__index = M

M.new = function(set, settings)
    local new = setmetatable({}, M)
    new.queue = {}
    new.pool = {}
    new.set = set
    new.randomly_add = settings.randomly_add or {}
    new.rng = love.math.newRandomGenerator(settings.seed)
    return new
end

function M:lookahead(amount)
    local res = {}
    for i=1, amount do
        if self.queue[i] then
            table.insert(res, self.queue[i])
        else
            for k,v in pairs(self.randomly_add) do
                if self.rng:random(1, v.inverse_chance) == 1 then
                    table.insert(self.queue, k)
                    table.insert(res, k)
                    goto bypass
                end
            end
            if #self.pool == 0 then
                for _, v in ipairs(self.set) do
                    table.insert(self.pool, v)
                end
            end
            local choice = self.rng:random(1, #self.pool)
            local choice_tetr = self.pool[choice]
            table.remove(self.pool, choice)
            table.insert(self.queue, choice_tetr)
            table.insert(res, choice_tetr)
            ::bypass::
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