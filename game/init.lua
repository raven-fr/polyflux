local evloop = require "evloop"
local playfield = require "game.playfield"
local tetrominoes = require "game.tetrominoes"
local gfx = require "game.gfx"

local M = {}
M.__index = M

function M.new(params)
	local new = setmetatable({}, M)
	new.params = params
	new.field = playfield.new(params.lines or 20, params.columns or 10)
	new.gfx = gfx.new(new)
	new.gravity_delay = 0.5
	return new
end

function M:input_loop()
	local function loop()
		-- TODO: interface with a remappable input system (it should generate
		-- its own events)
		local e, key = evloop.poll("keypressed", "keyreleased")
		if not self.piece then
			return loop()
		end

		if e == "keypressed" then
			if key == "left" then
				self.piece:move(0, -1)
			elseif key == "right" then
				self.piece:move(0, 1)
			elseif key == "down" then
				self.piece:move(-1, 0)
			elseif key == "up" then
				self.piece:rotate()
			elseif key == "space" then
				repeat until not self.piece:move(-1, 0)
				self.piece:place()
			end
		end

		return loop()
	end
	return loop
end

local pieces = {
	tetrominoes.i,
	tetrominoes.j,
	tetrominoes.l,
	tetrominoes.o,
	tetrominoes.s,
	tetrominoes.t,
	tetrominoes.z,
}

function M:next_piece()
	-- TODO: interface with configurable random system (it should implement
	-- seeds, bags)
	self.piece = pieces[love.math.random(#pieces)]:drop(self.field)
	return self.piece and true or false
end

function M:gravity_loop()
	local function loop()
		evloop.sleep(self.gravity_delay)
		self.field:remove_cleared()
		if not self.piece then
			assert(self:next_piece(), "you lose!")
			return loop()
		end
		if not self.piece:move(-1, 0) then
			self.piece:place()
			self.piece = nil
		end
		return loop()
	end
	return loop
end

function M:loop()
	local function loop()
		evloop.await_any(
			self:input_loop(),
			self:gravity_loop(),
			self.gfx:loop()
		)
	end
	return loop
end

return M
