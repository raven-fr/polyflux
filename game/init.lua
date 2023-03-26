local evloop = require "evloop"
local playfield = require "game.playfield"
local tetrominoes = require "game.tetrominoes"
local heav_optimal_shapes = require "game.heav_optimal_shapes"
local gfx = require "game.gfx"
local bag = require "game.bag"

local M = {}
M.__index = M

local pieces = {
	tetrominoes.i,
	tetrominoes.j,
	tetrominoes.l,
	tetrominoes.o,
	tetrominoes.s,
	tetrominoes.t,
	tetrominoes.z,
}

function M.new(params)
	local new = setmetatable({}, M)
	new.params = params
	new.field = playfield.new(params.lines or 20, params.columns or 10)
	new.hold = false
	new.can_hold = true
	new.gfx = gfx.new(new)
	new.gravity_delay = 0.5
	new.bag = bag.new(pieces, {seed = os.time(), randomly_add = {
		[heav_optimal_shapes.heav] = {inverse_chance = 5000},
		[heav_optimal_shapes.spite_shape] = {inverse_chance = 10000},
	}})
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
			elseif key == "c" then
				if not self.can_hold then goto bypass end
				if not self.hold then
					self.hold = self.piece.poly
					self:next_piece()
				else
					local tmp = self.hold
					self.hold = self.piece.poly
					self.piece = tmp:drop(self.field)
					
				end
				self.can_hold = false
				::bypass::
			end
		end

		return loop()
	end
	return loop
end

function M:next_piece()
	self.can_hold = true
	self.piece = self.bag:next_piece():drop(self.field)
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
