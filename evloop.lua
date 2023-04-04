-- module implementing nestable asynchronous event loop objects. the module
-- itself is an event loop object, representing the main event loop.

local M

local function new(...)
	local new = setmetatable({}, M)
	new.event_queue = {}
	new.tasks = {}
	new.named_tasks = {}
	for i = 1, select("#", ...) do
		new:wrap(select(i, ...))
	end
	return new
end

M = new()
M.__index = M

M.new = new

-- create a new task in the event loop.
function M:wrap(fn, ...)
	local name = false
	if type(fn) == "table" then
		name = fn.name
		fn = fn[1]
	end
	table.insert(self.event_queue, {coroutine.create(fn), name, ...})
end

-- send an event: evloop:queue(event, args...)
function M:queue(...)
	assert(type((...)))
	table.insert(self.event_queue, {...})
end

-- destroy a named task
function M:kill(name)
	if self.named_tasks[name] then
		self.tasks[self.named_tasks[name]] = nil
		self.named_tasks[name] = nil
	end
end

local function event_filter(timeout, ...)
	local filter = {}
	for i = 1, select("#", ...) do
		filter[select(i, ...)] = true
	end
	if type(timeout) == "string" then
		filter[timeout] = true
		timeout = nil
	end
	return filter, timeout
end

-- poll for an event: evloop.poll([timeout,] [events...])
-- returns: event, args...
function M.poll(...)
	local filter, timeout = event_filter(...)
	local e
	local t = 0
	repeat
		e = coroutine.yield(true)
		if e[1] == "timer" then
			t = t + e[2]
		end
		if timeout and t >= timeout then
			return
		end
	until filter[e[1]] or (not timeout and not next(filter))
	return unpack(e)
end

-- like evloop.poll but returns an iterator
function M.events(...)
	local filter, timeout = event_filter(...)
	local t = 0
	local function iter()
		if timeout and t >= timeout then
			t = t - timeout
			return false
		end
		local e = coroutine.yield(true)
		if e[1] == "timer" then
			t = t + e[2]
		end
		if (timeout or next(filter)) and not filter[e[1]] then
			return iter()
		else
			return unpack(e)
		end
	end
	return iter
end

function M.sleep(secs)
	M.poll(secs)
end

function M:quit(...)
	self:queue("quit", ...)
end

function M.debug_sleep(secs)
	local t = 0
	M.queue "debug.pause"
	while t < secs do
		local _, dt = M.poll "debug.timer"
		t = t + dt
	end
	M.queue "debug.unpause"
end

local function resume_task(co, ...)
	if coroutine.status(co) == "dead" then
		return false
	end

	local ok, ret = coroutine.resume(co, ...)
	if not ok then
		-- TODO: make this better somehow
		io.stderr:write(debug.traceback(co, ret)..'\n\n')
		error "error in event loop"
	end

	return coroutine.status(co) ~= "dead"
end

-- run each task in the event loop at once
function M:run()
	while true do
		::send_events::
		local q = self.event_queue
		self.event_queue = {}
		for _, e in ipairs(q) do
			if type(e[1]) == "thread" then
				-- start a new task
				local name = e[2]
				if resume_task(e[1], unpack(e, 3)) then
					self.tasks[e[1]] = true
					if name then self.named_tasks[name] = e[1] end
				end
			elseif e[1] == "quit" then
				return unpack(e, 2)
			else
				for task in pairs(self.tasks) do
					self.tasks[task] = resume_task(task, e) or nil
				end
			end
		end
		if #self.event_queue == 0 then
			if not next(self.tasks) then return end
			assert(coroutine.running(), "event queue depleted!")
			table.insert(self.event_queue, coroutine.yield(true))
		end
	end
end

return M
