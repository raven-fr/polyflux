local M = {}

M.pieces = function(game)
    local t = {text="pieces:\n0"}
    game.loop:wrap(function()
        while true do
            local e = game.loop.poll("game.piece_placed")
            t.text  = "pieces:\n"..game.stats.pieces
        end
    end)
    return t
end

M.lines = function(game, goal)
    local t = {text="lines:\n0"..(goal and "/"..goal or "")}
    game.loop:wrap(function()
        while true do
            local e = game.loop.poll("game.line_clear")
            t.text  = "lines:\n"..game.stats.lines..(goal and "/"..goal or "")
        end
    end)
    return t
end

local function display_time(t)
    local seconds = math.floor(t%60)
    local minutes = math.floor(t/60)
    local centiseconds = math.floor((t*100)%100)
    return ("%02d:%02d:%02d"):format(minutes, seconds, centiseconds)

end
M.time = function(game)
    local t = {text="time:\n"..display_time(0)}
    game.loop:wrap(function()
        while true do
            local e = game.loop.poll("update")
            t.text  = "time:\n"..display_time(game.stats.time)
        end
    end)
    return t
end

return M