local M = {}

local loaders = {
	sfx = function(f) return love.audio.newSource(f, "static") end,
	img = love.graphics.newImage,
	shader = love.graphics.newShader,
	music = function(f) return love.audio.newSource(f, "stream") end,
}

local loaded = {}
function M.load_from(assets_dir)
	if not loaded[assets_dir] then
		local assets = {}
		loaded[assets_dir] = assets
		for k, loader in pairs(loaders) do
			local dir = assets_dir..'/'..k..'/'
			assets[k] = {}
			for _, file in ipairs(love.filesystem.getDirectoryItems(dir)) do
				if love.filesystem.getInfo(dir..file).type == "file" then
					local name = file:match "(.+)%.[^%.]+$" or file
					assets[k][name] = assert(loader(dir..file))
				end
			end
		end
	end
	return loaded[assets_dir]
end

return M
