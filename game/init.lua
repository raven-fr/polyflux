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
	new.t_spun = false
	new.combo = -1
	new.stats = {pieces=0, lines=0}
	new.gfx = gfx.new(new)
	new.gravity_delay = 0.5
	new.lock_delay = params.lock_delay or 0.8
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
				moved = self.piece:move(-1, 0)
				while self.piece:move(-1, 0) do end
			elseif key == "up" then
				moved = self.piece:rotate()
				if moved then self:on_rotated() end
			elseif key == "lctrl" then
				moved = self.piece:rotate(true)
				if moved then self:on_rotated() end
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

		if moved then
			if self.infinity then
				evloop.queue "game.lock_cancel"
			elseif not self.piece:can_move(-1, 0) then
				evloop.queue "game.lock"
			end
		end

		return loop()
	end
	return loop
end

function M:on_rotated()
	if self.piece.t_spun then
		if self.piece.last_kick_id == 5 then
			sfx.play("tspinkick5")
		else
			sfx.play("tspin")
		end
	end
end

function M:place_piece()
	if not self.piece:can_move(-1, 0) then
		self.piece:place()
		self.stats.pieces = self.stats.pieces + 1
		evloop.queue "game.lock_cancel"
		local cleared = self.field:remove_cleared()
		if cleared > 0 then
			self.combo = self.combo + 1
			self.stats.lines = self.stats.lines + cleared
			if self.piece.t_spun then
				local sound = ({"tspinsingle","tspindouble","tspintriple"})[cleared]
				sfx.play(sound)
			end
			evloop.queue "game.line_clear"
		else
			self.combo = -1
		end
		evloop.queue "game.piece_placed"
		self:next_piece()
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
