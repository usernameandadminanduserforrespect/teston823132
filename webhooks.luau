if not LPH_OBFUSCATED then
    LPH_ENCNUM = function(toEncrypt, ...)
        assert(
            type(toEncrypt) == "number" and #{ ... } == 0,
            "LPH_ENCNUM only accepts a single constant double or integer as an argument."
        )
        return toEncrypt
    end
    LPH_NUMENC = LPH_ENCNUM

    LPH_ENCSTR = function(toEncrypt, ...)
        assert(
            type(toEncrypt) == "string" and #{ ... } == 0,
            "LPH_ENCSTR only accepts a single constant string as an argument."
        )
        return toEncrypt
    end
    LPH_STRENC = LPH_ENCSTR

    LPH_ENCFUNC = function(toEncrypt, encKey, decKey, ...)
        assert(
            type(toEncrypt) == "function" and type(encKey) == "string" and #{ ... } == 0,
            "LPH_ENCFUNC accepts a constant function, constant string, and string variable as arguments."
        )
        return toEncrypt
    end
    LPH_FUNCENC = LPH_ENCFUNC

    LPH_JIT = function(f, ...)
        assert(
            type(f) == "function" and #{ ... } == 0,
            "LPH_JIT only accepts a single constant function as an argument."
        )
        return f
    end
    LPH_JIT_MAX = LPH_JIT

    LPH_NO_VIRTUALIZE = function(f, ...)
        assert(
            type(f) == "function" and #{ ... } == 0,
            "LPH_NO_VIRTUALIZE only accepts a single constant function as an argument."
        )
        return f
    end

    LPH_NO_UPVALUES = function(f, ...)
        assert(type(setfenv) == "function", "LPH_NO_UPVALUES can only be used on Lua versions with getfenv & setfenv")
        assert(
            type(f) == "function" and #{ ... } == 0,
            "LPH_NO_UPVALUES only accepts a single constant function as an argument."
        )
        return f
    end

    LPH_CRASH = function(...)
        warn("LPH_CRASH INVOKED")
        assert(#{ ... } == 0, "LPH_CRASH does not accept any arguments.")
    end
end

return LPH_NO_VIRTUALIZE(function()

	-- ROBLOX upstream: https://github.com/Roblox/roact/blob/master/src/createSignal.lua
	--[[
		* Copyright (c) Roblox Corporation. All rights reserved.
		* Licensed under the Apache License, Version 2.0 (the "License");
		* you may not use this file except in compliance with the License.
		* You may obtain a copy of the License at
		*
		*     http://www.apache.org/licenses/LICENSE-2.0
		*
		* Unless required by applicable law or agreed to in writing, software
		* distributed under the License is distributed on an "AS IS" BASIS,
		* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
		* See the License for the specific language governing permissions and
		* limitations under the License.
	]]

	type Function = (...any) -> ...any
	--[[
		This is a simple signal implementation that has a dead-simple API.

			local signal = createSignal()

			local disconnect = signal:subscribe(function(foo)
				print("Cool foo:", foo)
			end)

			signal:fire("something")

			disconnect()
	]]

	type Connection = { callback: Function, disconnected: boolean }
	type Map<K, V> = { [K]: V }

	local function createSignal(): ((Function) -> () -> (), (...any) -> ())
		local connections: Map<Function, Connection> = {}
		local suspendedConnections = {}
		local firing = false

		local function subscribe(callback)
			assert(
				typeof(callback) == "function",
				"Can only subscribe to signals with a function."
			)

			local connection = {
				callback = callback,
				disconnected = false,
			}

			-- If the callback is already registered, don't add to the suspendedConnection. Otherwise, this will disable
			-- the existing one.
			if firing and not connections[callback] then
				suspendedConnections[callback] = connection
			end

			connections[callback] = connection

			local function disconnect()
				assert(
					not connection.disconnected,
					"Listeners can only be disconnected once."
				)

				connection.disconnected = true
				connections[callback] = nil
				suspendedConnections[callback] = nil
			end

			return disconnect
		end

		local function fire(...)
			firing = true
			for callback, connection in connections do
				if not connection.disconnected and not suspendedConnections[callback] then
					callback(...)
				end
			end

			firing = false

			-- ROBLOX performance: use table.clear
			table.clear(suspendedConnections)
		end

		return subscribe, fire
	end

	return createSignal

end)()