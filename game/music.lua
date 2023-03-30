local M = {}
M.__index = M
M.playing = nil

function M.new(assets)
	local new = setmetatable({}, M)
	new.assets = assets
	return new
end

function M:play(name)
	assert(self.assets.music[name], name.." isn't extant music")
	if M.playing ~= self.assets.music[name] then
        if M.playing then M.playing:stop() end
        self.assets.music[name]:seek(0)
        M.playing = self.assets.music[name]
    end
    self.assets.music[name]:setVolume(0.5)
	self.assets.music[name]:play()
    self.assets.music[name]:setLooping(true)
end

return M
