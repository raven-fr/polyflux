local poly = require "polyomino"

local M = {}
M.__index = M

M.i = poly.def("tetr.I", [[
	....
	####
	....
	....
]])

M.j = poly.def("tetr.J", [[
	#..
	###
	...
]])

M.l = poly.def("tetr.L", [[
	..#
	###
	...
]])

M.o = poly.def("tetr.O", [[
	....
	.##.
	.##.
	....
]])

M.s = poly.def("tetr.S", [[
	.##
	##.
	...
]])

M.z = poly.def("tetr.Z", [[
	##.
	.##
	...
]])

M.t = poly.def("tetr.T", [[
	.#.
	###
	...
]])

return M
