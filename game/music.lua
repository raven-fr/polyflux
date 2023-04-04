local M = {}
M.__index = M
M.playing = nil
M.volume = 0.5

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
    self.assets.music[name]:setVolume(self.volume)
	self.assets.music[name]:play()
    self.assets.music[name]:setLooping(true)
end

function M:fade(loop, time)
    for i=1, math.ceil(time*20) do
        loop.poll(1/20)
        local volume = self.volume * (1-i/(time*20))
        self.playing:setVolume(volume)
    end
end

return M
