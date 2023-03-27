local poly = require "game.polyomino"

local M = {}
M.__index = M

M.spite_shape = poly.def("heav.spite_shape", [[
	#.#
	.#.#
	#.#.
	.#.#
]])

M.heav = poly.def("heav.heav", [[
	..#.
	###.
	.###
	.#..
]])

M.colon = poly.def("heav.colon", [[
	.#.
	...
    .#.
]])

M.semicolon = poly.def("heav.semicolon", [[
	.#.
	...
    ##.
]])

M.dot = poly.def("heav.dot", [[
	#
]])

M.amongus = poly.def("heav.amongus", [[
	....###..
	...#####.
	..####...
	..######.
	..######.
	..######.
	..######.
	...#...#.
	...#...#.
]])

return M
