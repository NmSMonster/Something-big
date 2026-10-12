--!strict
--[[
	Signal
	------
	Lightweight event primitive for in-process communication between modules.

	* Handlers run on their own thread (task.spawn), so a yielding or erroring
	  handler never blocks or breaks the code that fired the signal.
	* Firing takes a snapshot of the handler list, so connecting/disconnecting
	  from inside a handler is safe.
]]

export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
}

export type Signal<T...> = {
	Connect: (self: Signal<T...>, handler: (T...) -> ()) -> Connection,
	Once: (self: Signal<T...>, handler: (T...) -> ()) -> Connection,
	Wait: (self: Signal<T...>) -> T...,
	Fire: (self: Signal<T...>, T...) -> (),
	DisconnectAll: (self: Signal<T...>) -> (),
	Destroy: (self: Signal<T...>) -> (),
}

type ConnectionImpl = {
	Connected: boolean,
	_handler: (...any) -> (),
	_signal: SignalImpl,
	Disconnect: (self: ConnectionImpl) -> (),
}

type SignalImpl = {
	_handlers: { ConnectionImpl },
	_destroyed: boolean,
}

local ConnectionClass = {}
ConnectionClass.__index = ConnectionClass

function ConnectionClass.Disconnect(self: ConnectionImpl)
	if not self.Connected then
		return
	end
	self.Connected = false

	local handlers = self._signal._handlers
	for index = #handlers, 1, -1 do
		if handlers[index] == self then
			table.remove(handlers, index)
			break
		end
	end
end

local SignalClass = {}
SignalClass.__index = SignalClass

function SignalClass.Connect(self: SignalImpl, handler: (...any) -> ()): Connection
	assert(typeof(handler) == "function", "Signal:Connect expects a function")
	if self._destroyed then
		-- A destroyed signal returns an inert connection so callers never crash.
		return { Connected = false, Disconnect = function() end } :: any
	end

	local connection: ConnectionImpl = setmetatable({
		Connected = true,
		_handler = handler,
		_signal = self,
	}, ConnectionClass) :: any

	table.insert(self._handlers, connection)
	return connection :: any
end

function SignalClass.Once(self: SignalImpl, handler: (...any) -> ()): Connection
	local connection: Connection
	connection = SignalClass.Connect(self, function(...)
		if connection.Connected then
			connection:Disconnect()
		end
		handler(...)
	end)
	return connection
end

function SignalClass.Fire(self: SignalImpl, ...: any)
	if #self._handlers == 0 then
		return
	end
	local snapshot = table.clone(self._handlers)
	for _, connection in snapshot do
		if connection.Connected then
			task.spawn(connection._handler, ...)
		end
	end
end

function SignalClass.Wait(self: SignalImpl): ...any
	local thread = coroutine.running()
	local connection: Connection
	connection = SignalClass.Connect(self, function(...)
		connection:Disconnect()
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function SignalClass.DisconnectAll(self: SignalImpl)
	for _, connection in self._handlers do
		connection.Connected = false
	end
	table.clear(self._handlers)
end

function SignalClass.Destroy(self: SignalImpl)
	SignalClass.DisconnectAll(self)
	self._destroyed = true
end

local Signal = {}

function Signal.new<T...>(): Signal<T...>
	local signal: SignalImpl = setmetatable({
		_handlers = {},
		_destroyed = false,
	}, SignalClass) :: any
	return signal :: any
end

function Signal.is(object: any): boolean
	return typeof(object) == "table" and getmetatable(object) == SignalClass
end

return Signal
