local game = require "game"
local text_events = require "game.text_events"

local M = {}
M.__index = M

function M.new(assets)
    local new = {}
    setmetatable(new, M)

    new.game = game.new(assets, {})

    table.insert(new.game.gfx.text_sidebar, {text="40 lines mode."})
    table.insert(new.game.gfx.text_sidebar, text_events.pieces(new.game))
    table.insert(new.game.gfx.text_sidebar, text_events.lines(new.game, 40))
    table.insert(new.game.gfx.text_sidebar, text_events.time(new.game))

    new.game.loop:wrap(function()
        while true do
            new.game.loop.poll("game.line_clear")
            if new.game.stats.lines >= 40 then
                new.game:win()
            end
        end
    end)

    return new.game, new
end

return M