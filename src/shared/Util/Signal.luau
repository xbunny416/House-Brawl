--!strict
-- Minimal typed signal. Each listener runs in its own thread, so one failing listener cannot break the others.
local Signal = {}
Signal.__index = Signal

export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
}

export type Signal<T...> = {
	Connect: (self: Signal<T...>, listener: (T...) -> ()) -> Connection,
	Once: (self: Signal<T...>, listener: (T...) -> ()) -> Connection,
	Fire: (self: Signal<T...>, T...) -> (),
	Wait: (self: Signal<T...>) -> T...,
	DisconnectAll: (self: Signal<T...>) -> (),
}

type Listener = {
	callback: (...any) -> (),
	connection: Connection,
}

function Signal.new<T...>(): Signal<T...>
	return (setmetatable({ _listeners = {} :: { Listener } }, Signal) :: any) :: Signal<T...>
end

function Signal.Connect(self: any, callback: (...any) -> ()): Connection
	local listeners: { Listener } = self._listeners
	local connection: Connection
	connection = {
		Connected = true,
		Disconnect = function(_: Connection)
			if not connection.Connected then
				return
			end
			connection.Connected = false
			for index, listener in listeners do
				if listener.connection == connection then
					table.remove(listeners, index)
					break
				end
			end
		end,
	}
	table.insert(listeners, { callback = callback, connection = connection })
	return connection
end

function Signal.Once(self: any, callback: (...any) -> ()): Connection
	local connection: Connection
	connection = Signal.Connect(self, function(...: any)
		connection:Disconnect()
		callback(...)
	end)
	return connection
end

function Signal.Fire(self: any, ...: any)
	for _, listener in table.clone(self._listeners :: { Listener }) do
		if listener.connection.Connected then
			task.spawn(listener.callback, ...)
		end
	end
end

function Signal.Wait(self: any): ...any
	local thread = coroutine.running()
	Signal.Once(self, function(...: any)
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function Signal.DisconnectAll(self: any)
	for _, listener in table.clone(self._listeners :: { Listener }) do
		listener.connection:Disconnect()
	end
end

return Signal
