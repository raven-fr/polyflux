local M = {}
M.__index = M

local queue = {}

local function resume_task(task, e)
	if coroutine.status(task.co) == "dead" then
		return false
	end

	if task.filter then
		for _, f in ipairs(task.filter) do
			if f == e[1] then
				goto resume
			end
		end
		if e[1] == "update" and
				task.timeout and love.timer.getTime() >= task.timeout then
			e = {}
			goto resume
		end
		return true
	end

	::resume::
	local ok, ret, timeout = coroutine.resume(task.co, e)
	if not ok then
		io.stderr:write(debug.traceback(task.co, ret)..'\n\n')
		error "error in event loop"
	end
	task.filter = ret
	task.timeout = timeout and love.timer.getTime() + timeout
	return coroutine.status(task.co) ~= "dead"
end

local function create_task(fn)
	local task = {}
	task.co = coroutine.create(fn)
	resume_task(task)
	return task
end

function M.poll(timeout, ...)
	local filter = {...}
	if type(timeout) == "string" then
		table.insert(filter, timeout)
		timeout = nil
	end
	return unpack(
		coroutine.yield((timeout or #filter > 0) and filter, timeout))
end

function M.sleep(secs)
	M.poll(secs)
end

function M.queue(...)
	table.insert(queue, {...})
end

function M.await_any(...)
	local tasks = {...}
	for i, t in ipairs(tasks) do
		tasks[i] = create_task(t)
	end
	while true do
		local e = coroutine.yield()
		for _, t in ipairs(tasks) do
			if not resume_task(t, e) then return end
		end
	end
end

function M.debug_sleep(secs)
	M.paused = true
	local t = 0
	while t < secs do
		local _, dt = M.poll "debug.update"
		t = t + dt
	end
	M.paused = false
end

local function poll_love()
	love.event.pump()
	local es = love.event.poll()
	while true do
		local e = {es()}
		if not e[1] then break end
		if love.handlers[e[1]] then
			love.handlers[e[1]](unpack(e, 2))
		end
		table.insert(queue, e)
	end
end

function M.mainloop(start)
	local main = create_task(function()
		start()
	end)

	return function()
		if not M.paused then poll_love() end

		local q = queue
		queue = {}
		for i, e in ipairs(q) do
			if e[1] == "quit" then
				if not love.quit or not love.quit() then
					return e[2] or 0
				end
			end
			if not resume_task(main, e) then return 0 end
		end

		local dt = love.timer.step()
		if not resume_task(
				main, {M.paused and "debug.update" or "update", dt}) then
			return 0
		end

		::graphics::
		if love.graphics and love.graphics.isActive() then
			love.graphics.clear(love.graphics.getBackgroundColor())
			require "viewport".origin()
			if not resume_task(main, {"draw", dt}) then return 0 end
			love.graphics.present()
		end

		love.timer.sleep(0.001)
	end
end

return M
