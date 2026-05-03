local ConnectionProxyMgr = {
	Registry = {},
	Id = 0,
}

function ConnectionProxyMgr._requestId()
	ConnectionProxyMgr.Id += 1
	return ConnectionProxyMgr.Id
end

function ConnectionProxyMgr._newProxyHandler(ConnectionProxy)
	local Id = ConnectionProxyMgr._requestId()

	local Handler = {
		Proxy = ConnectionProxy,
		Enabled = true,
		ClearSignal = Instance.new("BindableEvent"),
	}

	function Handler:Disable()
		self.Enabled = false
		self.Proxy:Disable()
	end

	function Handler:Enable()
		self.Enabled = true
		self.Proxy:Enable()
	end

	Handler.ClearSignal.Event:Once(function()
		pcall(function()
			Handler.Proxy:Enable()
			ConnectionProxyMgr.Registry[Id] = nil
		end)
	end)

	ConnectionProxyMgr.Registry[Id] = Handler

	return Handler
end

function ConnectionProxyMgr:Register(ConnectionProxy)
	return ConnectionProxyMgr._newProxyHandler(ConnectionProxy)
end

function ConnectionProxyMgr:Clear()
	for _, Handler in next, ConnectionProxyMgr.Registry do
		Handler.ClearSignal:Fire()
	end
end

function ConnectionProxyMgr:YieldForConnection(Signal: RBXScriptSignal, SourceNeedle: string, Timeout: number?)
	local Start = os.clock()

	while task.wait() do
		local Connections = getconnections(Signal) :: { any } -- linter thinks it returns connections instead of proxies idk why
		for _, Connection in next, Connections do
			local Function = Connection.Function
			if Function and type(Function) == "function" then
				if not pcall(debug.info, Function, "s") then
					warn("Failed to get function source:", Function)
					continue
				end

				if debug.info(Function, "s"):match(SourceNeedle) then
					return Connection
				end
			end
		end

		if Timeout and os.clock() - Start >= Timeout then
			return nil
		end
	end

	return nil
end

return ConnectionProxyMgr