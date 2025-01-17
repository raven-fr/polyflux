local evloop = require "evloop"
local playfield = require "game.playfield"
local tetrominoes = require "game.tetrominoes"
local heav_optimal_shapes = require "game.heav_optimal_shapes"
local gfx = require "game.gfx"
local sfx = require "game.sfx"
local music = require "game.music"
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

function M.new(assets, params)
	local new = setmetatable({}, M)
	new.assets = assets
	new.params = params
	new.field = playfield.new(params.lines or 20, params.columns or 10)
	new.gfx = gfx.new(assets, new)
	new.sfx = sfx.new(assets)
	new.music = music.new(assets, new)

	new.hold = false
	new.can_hold = true
	new.bag = bag.new(pieces, {seed = os.time(), randomly_add = {
		[heav_optimal_shapes.heav] = {inverse_chance = 5000},
		[heav_optimal_shapes.spite_shape] = {inverse_chance = 10000},
		[heav_optimal_shapes.amongus] = {inverse_chance = 13500},
	}})

	new.t_spun = false
	new.combo = -1
	new.stats = {pieces = 0, lines = 0, time = 0, start_time = love.timer.getTime()}

	new.gravity_delay = 0.5
	new.lock_delay = params.lock_delay or 0.8
	new.infinity = params.infinity or false
	new.das_delay = params.das_delay or 0.16
	new.das_repeat_delay = params.das_repeat_delay or 0.03

	new.loop = evloop.new()
	return new
end

local directions = {
	left = {0, -1},
	right = {0, 1},
}

function M:input_loop()
	local delay = self.das_delay

	for e, key in evloop.events("keypressed", "keyreleased") do
		-- TODO: interface with a remappable input system (it should generate
		-- its own events)
		if not self.piece then
			goto continue
		end

		delay = self.das_delay

		if e == "keypressed" then
			local moved
			if directions[key] then
				self:move(unpack(directions[key]))
				self.loop:queue("game.das", key)
			elseif key == "down" then
				moved = self:move(-1, 0)
				while self.piece:move(-1, 0) do end
			elseif key == "up" then
				moved = self:rotate()
			elseif key == "lctrl" then
				moved = self:rotate(true)
			elseif key == "space" then
				local dropped = false
				while self.piece:move(-1, 0) do
					dropped = true
				end
				self:place_piece()
				if dropped then self.sfx:play("harddrop") end
			elseif key == "c" then
				if not self.can_hold then goto bypass end
				if not self.hold then
					self.hold = self.piece.poly
					self:next_piece()
				else
					local tmp = self.hold
					self.hold = self.piece.poly
					self.piece = tmp:drop(self.field)
					self.loop:queue "game.lock_cancel"
				end
				self.can_hold = false
				::bypass::
			end
		elseif e == "keyreleased" then
			if key == "left" or key == "right" then
				self.loop:queue("game.das_cancel", key)
			end
		end

		::continue::
	end
end

function M:das_loop()
	for _, dir in evloop.events "game.das" do
		::das::
		local e, new_dir = evloop.poll(
			self.das_delay, "game.das", "game.das_cancel")
		while true do
			if e == "game.das" then
				dir = new_dir
				goto das
			elseif e == "game.das_cancel" then
				if dir == new_dir then break end
			end
			self:move(unpack(directions[dir]))
			e, new_dir = evloop.poll(
				self.das_repeat_delay, "game.das", "game.das_cancel")
		end
	end
end

function M:on_moved()
	if self.infinity then
		self.loop:queue "game.lock_cancel"
	elseif not self.piece:can_move(-1, 0) then
		self.loop:queue "game.lock"
	end
end

function M:move(lines, columns)
	if self.piece:move(lines, columns) then
		self:on_moved()
	end
end

function M:rotate(ccw)
	if self.piece:rotate(ccw) then
		self:on_moved()
		if self.piece.t_spun then
			if self.piece.last_kick_id == 5 then
				self.sfx:play("tspinkick5")
			else
				self.sfx: play("tspin")
			end
		end
		return true
	else
		return false
	end
end

function M:place_piece()
	if not self.piece:can_move(-1, 0) then
		self.piece:place()
		self.stats.pieces = self.stats.pieces + 1
		self.loop:queue "game.lock_cancel"
		local cleared = self.field:remove_cleared()
		if cleared > 0 then
			self.combo = self.combo + 1
			self.stats.lines = self.stats.lines + cleared
			if self.piece.t_spun then
				local sound = ({"tspinsingle","tspindouble","tspintriple"})[cleared]
				self.sfx:play(sound)
			end
			self.loop:queue("game.line_clear")
		else
			self.combo = -1
		end
		self.loop:queue("game.piece_placed")
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
	for _ in evloop.events "game.lock" do
		local e = evloop.poll(self.lock_delay, "game.lock_cancel")
		if not e then
			self:place_piece()
		end
	end
end

function M:gravity_loop()
	for _ in evloop.events(self.gravity_delay) do
		if self.piece and not self.piece:move(-1, 0) then
			self.loop:queue "game.lock"
		end
		if not self.piece then
			self.loop:quit()
		end
	end
end

function M:time_loop()
	while true do
		self.loop.poll("update")
		self.stats.time = love.timer.getTime() - self.stats.start_time
	end
end

function M:win()
	self.loop:kill("input_loop")
	self.loop:kill("gravity_loop")
	self.loop:kill("lock_loop")
	self.loop:kill("das_loop")
	self.loop:kill("time_loop")
	self.piece = nil
	self.gfx.text_sidebar[1].text = "you win.\n\n"
	self.gfx.text_sidebar[1].color = {1, 1, 0}
	self.music:fade(self.loop, 4)
end

function M:run()
	self:next_piece()
	self.loop:wrap{function() self:input_loop() end, name="input_loop"}
	self.loop:wrap{function() self:gravity_loop() end, name="gravity_loop"}
	self.loop:wrap{function() self:lock_loop() end, name="lock_loop"}
	self.loop:wrap{function() self:das_loop() end, name="das_loop"}
	self.loop:wrap{function() self:time_loop() end, name="time_loop"}
	self.loop:wrap{function() self.gfx:run() end, name="gfx"}
	return self.loop:run()
end

return M
