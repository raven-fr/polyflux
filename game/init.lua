local evloop = require "evloop"
local playfield = require "game.playfield"
local tetrominoes = require "game.tetrominoes"
local heav_optimal_shapes = require "game.heav_optimal_shapes"
local gfx = require "game.gfx"
local sfx = require "game.sfx"
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
	new.lock_delay = params.lock_delay or 0.5
	new.infinity = params.infinity or false
	new.bag = bag.new(pieces, {seed = os.time(), randomly_add = {
		[heav_optimal_shapes.heav] = {inverse_chance = 5000},
		[heav_optimal_shapes.spite_shape] = {inverse_chance = 10000},
		[heav_optimal_shapes.amongus] = {inverse_chance = 13500},
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

		local moved
		if e == "keypressed" then
			if key == "left" then
				moved = self.piece:move(0, -1)
			elseif key == "right" then
				moved = self.piece:move(0, 1)
			elseif key == "down" then
				local did_move = false
				while self.piece:move(-1, 0) do did_move = true end
				if did_move then evloop.queue "game.lock_cancel" end
			elseif key == "up" then
				moved = self.piece:rotate()
			elseif key == "space" then
				local dropped = false
				while self.piece:move(-1, 0) do
					dropped = true
				end
				self:place_piece()
				if dropped then sfx.play("harddrop") end
			elseif key == "c" then
				if not self.can_hold then goto bypass end
				if not self.hold then
					self.hold = self.piece.poly
					self:next_piece()
				else
					local tmp = self.hold
					self.hold = self.piece.poly
					self.piece = tmp:drop(self.field)
					evloop.queue "game.lock_cancel"
				end
				self.can_hold = false
				::bypass::
			end
		end

		if moved and self.infinity then
			evloop.queue "game.lock_cancel"
		end

		return loop()
	end
	return loop
end

function M:place_piece()
	if not self.piece:can_move(-1, 0) then
		self.piece:place()
		evloop.queue "game.lock_cancel"
		self:next_piece()
		self.field:remove_cleared()
		return true
	else
		return false
	end
end

function M:next_piece()
	self.can_hold = true
	self.piece = self.bag:next_piece():drop(self.field)
	return self.piece and true or false
end

function M:lock_loop()
	local function loop()
		evloop.poll "game.lock"
		local e = evloop.poll(self.lock_delay, "game.lock_cancel")
		if e then
			return loop()
		else
			self:place_piece()
		end
		return loop()
	end
	return loop
end

function M:gravity_loop()
	local function loop()
		evloop.sleep(self.gravity_delay)
		if self.piece and not self.piece:move(-1, 0) then
			evloop.queue "game.lock"
		end
		if self.piece then
			return loop()
		end
	end
	return loop
end

function M:loop()
	local function loop()
		self:next_piece()
		evloop.await_any(
			self:input_loop(),
			self:gravity_loop(),
			self:lock_loop(),
			self.gfx:loop()
		)
	end
	return loop
end

return M
