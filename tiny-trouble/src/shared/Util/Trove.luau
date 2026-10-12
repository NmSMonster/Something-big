--!strict
--[[
	Trove
	-----
	Collects objects that need cleaning up (instances, connections, threads,
	functions, tables with Destroy/Disconnect/Clean) and disposes of them all in
	one call. Every controller/service uses a Trove per lifetime (per character,
	per prompt, per UI window) so nothing leaks between respawns.
]]

local Signal = require(script.Parent.Signal)

export type Trove = {
	Add: <T>(self: Trove, object: T, cleanupMethod: string?) -> T,
	Connect: (self: Trove, signal: RBXScriptSignal, handler: (...any) -> ()) -> RBXScriptConnection,
	Construct: <T>(self: Trove, constructor: (...any) -> T, ...any) -> T,
	Extend: (self: Trove) -> Trove,
	Remove: (self: Trove, object: any) -> boolean,
	Clean: (self: Trove) -> (),
	Destroy: (self: Trove) -> (),
}

type Entry = {
	object: any,
	cleanup: string | ((...any) -> ()),
}

type TroveImpl = {
	_entries: { Entry },
	_cleaning: boolean,
}

local Trove = {}

local TroveClass = {}
TroveClass.__index = TroveClass

local function resolveCleanup(object: any, explicit: string?): string | ((...any) -> ())
	if explicit then
		return explicit
	end

	local kind = typeof(object)
	if kind == "Instance" then
		return "Destroy"
	elseif kind == "RBXScriptConnection" then
		return "Disconnect"
	elseif kind == "thread" then
		return function(thread: thread)
			if coroutine.status(thread) ~= "dead" then
				task.cancel(thread)
			end
		end
	elseif kind == "function" then
		return function(callback: () -> ())
			callback()
		end
	elseif kind == "table" then
		if Signal.is(object) then
			return "Destroy"
		elseif typeof(object.Destroy) == "function" then
			return "Destroy"
		elseif typeof(object.Disconnect) == "function" then
			return "Disconnect"
		elseif typeof(object.Clean) == "function" then
			return "Clean"
		end
	end

	error(("Trove cannot clean up objects of type %s"):format(kind))
end

local function cleanupEntry(entry: Entry): boolean
	local cleanup = entry.cleanup
	if typeof(cleanup) == "function" then
		cleanup(entry.object)
	else
		local method = (entry.object :: any)[cleanup]
		if typeof(method) == "function" then
			method(entry.object)
		end
	end
	return true
end

function TroveClass.Add(self: TroveImpl, object: any, cleanupMethod: string?): any
	assert(object ~= nil, "Trove:Add received nil")
	table.insert(self._entries, {
		object = object,
		cleanup = resolveCleanup(object, cleanupMethod),
	})
	return object
end

function TroveClass.Connect(self: TroveImpl, signal: RBXScriptSignal, handler: (...any) -> ()): RBXScriptConnection
	return TroveClass.Add(self, signal:Connect(handler))
end

function TroveClass.Construct(self: TroveImpl, constructor: (...any) -> any, ...: any): any
	return TroveClass.Add(self, constructor(...))
end

function TroveClass.Extend(self: TroveImpl): Trove
	local child = Trove.new()
	TroveClass.Add(self, child)
	return child
end

function TroveClass.Remove(self: TroveImpl, object: any): boolean
	for index, entry in self._entries do
		if entry.object == object then
			table.remove(self._entries, index)
			cleanupEntry(entry)
			return true
		end
	end
	return false
end

function TroveClass.Clean(self: TroveImpl)
	if self._cleaning then
		return
	end
	self._cleaning = true

	local entries = self._entries
	self._entries = {}
	-- Clean in reverse so later dependencies are released first.
	for index = #entries, 1, -1 do
		local ok, err = pcall(cleanupEntry, entries[index])
		if not ok then
			warn(("[Trove] cleanup failed: %s"):format(tostring(err)))
		end
	end

	self._cleaning = false
end

function TroveClass.Destroy(self: TroveImpl)
	TroveClass.Clean(self)
end

function Trove.new(): Trove
	local trove: TroveImpl = setmetatable({
		_entries = {},
		_cleaning = false,
	}, TroveClass) :: any
	return trove :: any
end

return Trove
