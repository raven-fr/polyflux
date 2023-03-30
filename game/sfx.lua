local M = {}
M.__index = M

function M.new(assets)
	local new = setmetatable({}, M)
	new.assets = assets
	return new
end

function M:play(name)
	assert(self.assets.sfx[name], "no such sound effect: "..name)
	self.assets.sfx[name]:seek(0)
	self.assets.sfx[name]:play()
end

return M
