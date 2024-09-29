local types = require(script.Parent.types)

type Signal<T> = types.Signal<T>
-- i swear this is not a useless abstraction and definitely won't cause any memory leaks and related hassles
function new_signal<T>(): Signal<T>
	local listeners = {}
	return {
		listen = function(listener: (message: T) -> ())
			listeners[listener] = true
			return function()
				listeners[listener] = nil
			end
		end,
		wait = function()
			local listener
			listener = function(message)
				coroutine.resume(coroutine.running(), message)
				listeners[listener] = nil
			end
			listeners[listener] = true
			return coroutine.yield()
		end,
		send = function(message: T)
			for listener in listeners do
				listener(message)
			end
		end,
		-- unlisten = function(listener)
		-- 	listeners[listener] = nil
		-- end,
		destroy = function()
			listeners = {}
		end,
	}
end

function signal_filter_map<T, T2>(signal: Signal<T>, fn: (value: T) -> T2?): Signal<T2>
	local filtered_signal = new_signal()
	local unlisten = signal.listen(function(message)
		local mapped = fn(message)
		if mapped ~= nil then
			filtered_signal.send(mapped)
		end
	end)
	local old = filtered_signal.destroy
	filtered_signal.destroy = function()
		old()
		unlisten()
	end
	return filtered_signal
end

return { new_signal = new_signal, signal_filter_map = signal_filter_map }
