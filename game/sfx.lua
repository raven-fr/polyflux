local sounds = {
    "harddrop",
    "tspinsingle", "tspindouble", "tspintriple",
}

local sources = {}
for _, soundname in ipairs(sounds) do
    sources[soundname] = love.audio.newSource("assets/"..soundname..".mp3","static")
end

local M = {}

function M.play(name)
    if sources[name] then
        sources[name]:seek(0)
        sources[name]:play()
    else
        error("no such sound effect: "..name)
    end
end

return M