local M = {}

M.width, M.height = 1920, 1080

local dims = {love.graphics.getDimensions()}

function M.scale()
	local sw, sh = unpack(dims)
	local vw, vh = unpack(M)
	local scalex, scaley = sw / vw, sh / vh
	if scalex * vh < sh then
		return scalex
	else
		return scaley
	end
end

function M.offset()
	local sw, sh = unpack(dims)
	local vw, vh = unpack(M)
	local sc = M.scale()
	local x, y = sw / 2 - vw * sc / 2, sh / 2 - vh * sc / 2
	return x, y
end

function M.pos(win_x, win_y)
	local x, y = M.offset()
	local sc = M.scale()
	return (win_x - x) / sc, (win_y - y) / sc
end

function M.origin()
	dims = {love.graphics.getDimensions()}
	M[1], M[2] = M.width, M.height

	love.graphics.origin()
	love.graphics.translate(M.offset())
	love.graphics.scale(M.scale())
end

return M
