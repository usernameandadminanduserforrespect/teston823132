local function flen(Table): number
	local Count = 0
	for _ in next, Table do
		Count += 1
	end
	return Count
end

local Cleaner = {
	Registry = {},
	AllowedTypes = {
		["RBXScriptConnection"] = true,
		["Instance"] = true,
		["table"] = true,
		["function"] = true,
		["thread"] = true,
	},
	CleanEvent = Instance.new("BindableEvent"),
}

local function _autoRegisterWithStorage(Object: any)
	local ok, getg = pcall(function()
		return getgenv
	end)
	if not ok or type(getg) ~= "function" then
		return
	end
	local env = getg()
	local Storage = env and env.BS_Storage
	local optIn = env and env.BS_AutoRegisterStorage
	if not Storage or not optIn then
		return
	end

	local function nextKey(map, base)
		map.__auto_index = map.__auto_index or {}
		local counters = map.__auto_index
		local n = (counters[base] or 0) + 1
		local key = base
		if rawget(map, base) ~= nil then
			key = string.format("%s#%d", base, n)
		end
		while rawget(map, key) ~= nil do
			n += 1
			key = string.format("%s#%d", base, n)
		end
		counters[base] = n
		return key
	end

	local t = typeof(Object)
	if t == "RBXScriptConnection" then
		local key = nextKey(Storage.Connections, "AutoConnection")
		Storage.Connections[key] = Object
	elseif t == "thread" then
		local key = nextKey(Storage.Routines, "AutoRoutine")
		Storage.Routines[key] = Object
	end
end

function Cleaner.Register(Object: any)
	if not Cleaner.AllowedTypes[typeof(Object)] then
		warn("Attempted to register an invalid object type:", typeof(Object))
		warn(debug.traceback())
		return
	end

	if Cleaner.Registry[Object] then
		warn("Object is already registered for cleanup:", Object)
		return
	end

	Cleaner.Registry[Object] = true

	-- Auto-register connections and threads into Storage for visibility (opt-in only)
	if typeof(Object) == "RBXScriptConnection" or typeof(Object) == "thread" then
		_autoRegisterWithStorage(Object)
	end

	return {
		Clean = function()
			Cleaner.CleanOne(Object)
		end,
	}
end

function Cleaner.Clean()
	print("Cleaning up", flen(Cleaner.Registry), "objects.")
	for Object, _ in next, Cleaner.Registry do
		if typeof(Object) == "RBXScriptConnection" then
			Object:Disconnect()
		elseif typeof(Object) == "Instance" then
			Object:Destroy()
		elseif type(Object) == "table" then
			for Index, Value in next, Object do
				Object[Index] = nil
			end
		elseif type(Object) == "function" then
			Object()
		elseif type(Object) == "thread" then
			coroutine.close(Object)
		end

		Cleaner.Registry[Object] = nil
	end
	Cleaner.CleanEvent:Fire()
end

function Cleaner.CleanOne(Object: any)
	if not Cleaner.AllowedTypes[typeof(Object)] then
		warn("Attempted to clean an invalid object type:", typeof(Object))
		return
	end

	if not Cleaner.Registry[Object] then
		warn("Object is not registered for cleanup:", Object)
		return
	end

	if typeof(Object) == "RBXScriptConnection" then
		Object:Disconnect()
	elseif typeof(Object) == "Instance" then
		Object:Destroy()
	elseif type(Object) == "table" then
		for Index, Value in next, Object do
			Object[Index] = nil
		end
	elseif type(Object) == "function" then
		Object()
	elseif type(Object) == "thread" then
		coroutine.close(Object)
	end

	Cleaner.Registry[Object] = nil
end

function Cleaner.GetCleanEvent()
	return Cleaner.CleanEvent.Event
end

setmetatable(Cleaner, {
	__call = function(self, Object: any)
		self.Register(Object)
		return Object
	end,
})

return Cleaner