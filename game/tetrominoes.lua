local poly = require "game.polyomino"

local M = {}
M.__index = M

local jlstz_kicks = {
	{{0,0}, {-1,0}, {-1, 1}, {0,-2}, {-1,-2}},
	{{0,0}, { 1,0}, { 1,-1}, {0, 2}, { 1, 2}},
	{{0,0}, { 1,0}, { 1, 1}, {0,-2}, { 1,-2}},
	{{0,0}, {-1,0}, {-1,-1}, {0, 2}, {-1, 2}},
}

M.i = poly.def("tetr.I", [[
	....
	####
	....
	....
]], {
	{{0,0}, {-2,0}, {1,0}, {-2,-1}, {1,2}}, -- TODO: format this nicely if you dare.
	{{0,0}, {-1,0}, {2,0}, {-1,2}, {2,-1}},
	{{0,0}, {2,0}, {-1,0}, {2,1}, {-1,-2}},
	{{0,0}, {1,0},{-2,0},{1,-2},{-2,1}},
})

M.j = poly.def("tetr.J", [[
	#..
	###
	...
]], jlstz_kicks)

M.l = poly.def("tetr.L", [[
	..#
	###
	...
]], jlstz_kicks)

M.o = poly.def("tetr.O", [[
	....
	.##.
	.##.
	....
]], jlstz_kicks)

M.s = poly.def("tetr.S", [[
	.##
	##.
	...
]], jlstz_kicks)

M.z = poly.def("tetr.Z", [[
	##.
	.##
	...
]], jlstz_kicks)

M.t = poly.def("tetr.T", [[
	.#.
	###
	...
]], jlstz_kicks)

return M
