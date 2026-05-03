local TweenService = game:GetService("TweenService")
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

local SecureRequest = require('./secure_request.luau')

local rconsoleprint = print

require('./anti_skid.luau')

-- task.wait(5)

return LPH_NO_VIRTUALIZE(function()
	local Success = xpcall(function()
		local _Repr: (any, { [string]: any }?) -> string =
			loadstring(SecureRequest:HttpGet("https://raw.githubusercontent.com/Ozzypig/repr/refs/heads/master/repr.lua"))()
			
		local RunService = game:GetService("RunService")
		local DarkOverlay = Instance.new("ScreenGui")
		DarkOverlay.IgnoreGuiInset = true
		DarkOverlay.DisplayOrder = 1000
		DarkOverlay.Name = "SGuardOverlay"

		local InformationDrawing = Instance.new("ImageLabel")
		local StatusText = Instance.new("TextLabel")

		do
			local Frame = Instance.new("Frame")
			Frame.Size = UDim2.new(1, 0, 1, 0)
			Frame.BackgroundColor3 = Color3.new(1, 1, 1)
			Frame.BackgroundTransparency = 0
			Frame.Parent = DarkOverlay
			Frame.ZIndex = 1000

			local UIGradient = Instance.new("UIGradient")
			UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(0.462745, 0.078431, 0.819608)),
				ColorSequenceKeypoint.new(1, Color3.new(0.384314, 0, 1))
			})
			UIGradient.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 1)
			})

			local NV = Instance.new("NumberValue")
			NV.Value = 1

			local Tween = TweenService:Create(NV, TweenInfo.new(5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Value = 0
			})

			Tween:Play()

			local TC = NV:GetPropertyChangedSignal("Value"):Connect(function()
				UIGradient.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, NV.Value),
					NumberSequenceKeypoint.new(1, 1)
				})
			end)

			Tween.Completed:Once(function()
				TC:Disconnect()
				NV:Destroy()
			end)

			UIGradient.Rotation = -90
			UIGradient.Parent = Frame
		end

		shared.DarkOverlay = DarkOverlay
		DarkOverlay.Parent = game:GetService("CoreGui")

		local imageData = SecureRequest:HttpGet("https://example.com/file/Overlay.png")
		writefile("sg_overlay.png", imageData)
		InformationDrawing.Image = getcustomasset("sg_overlay.png")
		InformationDrawing.BackgroundTransparency = 1
		InformationDrawing.ZIndex = 1001
		InformationDrawing.Parent = DarkOverlay

		StatusText.Text = "Loading..."
		StatusText.TextSize = 24
		StatusText.Font = Enum.Font.SourceSansLight
		StatusText.TextColor3 = Color3.new(1, 1, 1)
		StatusText.BackgroundTransparency = 1
		StatusText.ZIndex = 1001
		StatusText.Parent = DarkOverlay
		StatusText.Size = UDim2.new(1, 0, 0, 30) -- Give it some height
		StatusText.TextXAlignment = Enum.TextXAlignment.Center
		StatusText.TextYAlignment = Enum.TextYAlignment.Top

		shared.OverlayImage = InformationDrawing
		shared.StatusText = StatusText

		local ViewportSize = workspace.CurrentCamera.ViewportSize

		local OriginalImageResolution = Vector2.new(1361, 299)
		local AspectRatio = OriginalImageResolution.X / OriginalImageResolution.Y
		local NewWidth = ViewportSize.X * 0.5
		local NewHeight = NewWidth / AspectRatio

		InformationDrawing.Size = UDim2.fromOffset(NewWidth, NewHeight)
		InformationDrawing.Position = UDim2.fromOffset(
			(ViewportSize.X - NewWidth) / 2,
			(ViewportSize.Y - NewHeight) / 2
		)

		local InformationDrawingBackGlow = InformationDrawing:Clone()
		InformationDrawingBackGlow.Parent = InformationDrawing.Parent

		task.spawn(function()
			while RunService.RenderStepped:Wait() do
				if InformationDrawing and InformationDrawing.Parent then
					InformationDrawing.ImageTransparency = math.abs(math.sin(os.clock() * 3) * .5)
				else
					InformationDrawingBackGlow:Destroy()
					break
				end
			end
		end)

		RunService:BindToRenderStep("Overlay", Enum.RenderPriority.Camera.Value, function()

			ViewportSize = workspace.CurrentCamera.ViewportSize

			local currentSize = InformationDrawing.AbsoluteSize
			InformationDrawing.Position = UDim2.fromOffset(
				(ViewportSize.X - currentSize.X) / 2,
				(ViewportSize.Y - currentSize.Y) / 2
			)

			local currentPos = InformationDrawing.AbsolutePosition
			StatusText.Position = UDim2.fromOffset(
				0,
				currentPos.Y + currentSize.Y + 35
			)

			local InteractiveToast = game:GetService("CoreGui"):FindFirstChild("InteractiveToast")
			DarkOverlay.Enabled = not InteractiveToast
		end)

		local function UpdateStatus(Text)
			shared.StatusText.Text = Text
		end

		local Required = {
			"hookfunction",
			"getthreadcontext",
			"getconnections",
			"setthreadcontext",
			"isexecutorclosure",
			"hookmetamethod",
			"getrenv",
		}

		local validlevel = debug.validlevel or debug.isvalidlevel or function(Level)
			return debug.info(Level + 1, "f") ~= nil
		end

		for _, v in next, Required do
			if not getgenv()[v] then
				error("Missing required function: " .. v)
			end
		end

		local _OldDebugTraceback, OldDebugInfo, OldFenv = debug.traceback, debug.info, getfenv

		local checkfirstcaller = function()
			-- Check if level 4 is valid, if not check 3.

			local Levels = {
				[1] = 4,
				[2] = 3,
			}

			for _, Level in ipairs(Levels) do
				if validlevel(Level) then
					local Func = debug.info(Level, "f")
					if Func and isexecutorclosure(Func) then
						return true
					end
				end
			end

			return false
		end

		local TargetScriptName = "ReplicatedFirst."

		-- thanks upio 😘

		local _BlacklistedRemoteArgumentNeedles = {
			"invalid_entry",
			"replicate_bil",
		}

		if not shared.Hooking then
			shared.Hooking = {}
		end

		if not shared.Hooking.IncludeInStackFunctions then
			shared.Hooking.IncludeInStackFunctions = {}
		end

		shared.SafeHook = function(Original, Replacement)
			shared.Hooking.IncludeInStackFunctions[Original] = true
			return hookfunction(Original, Replacement)
		end

		local function logDebugMessage(...)
			local Strings = {}

			for _, v in next, { ... } do
				table.insert(Strings, tostring(v))
			end

			local Message = table.concat(Strings, ", ")
			return warn(Message)
		end

		UpdateStatus("Loading getfenv proxy...")

		OldFenv = shared.SafeHook(getrenv().getfenv, function(...)
			-- logDebugMessage("getfenv", ...)
			if checkfirstcaller() then
				return OldFenv(...)
			end
			
			local ToInspect: (...any) -> ...any | number = ...

			if type(ToInspect) == "number" then
				local RealEnv, ExecutorEnv = getrenv(), getgenv()
				local Metatable = {
					__index = function(_, Key)
						if RealEnv[Key] ~= nil then
							return RealEnv[Key]
						elseif ExecutorEnv[Key] ~= nil and not RealEnv[Key] then -- sussy BAKA
							-- logDebugMessage(
							-- 	`[SGuard v4] Attempted to access getgenv() variable "{Key}" from getfenv()! This is not allowed and will be ignored.`
							-- )
							return nil
						else
							return OldFenv(ToInspect)[Key]
						end
					end,
				}
				return setmetatable({}, Metatable)
			elseif ToInspect == nil then
				return OldFenv(...)
			end

			return OldFenv(...)
		end)

		task.wait(0.1)

		rconsoleprint(`[SGuard v4] getfenv proxy loaded!\n`)

		-- Disable all blacklisted connections

		local BlacklistedSignals = {
			game:GetService("LogService").MessageOut,
			game:GetService("ScriptContext").Error,
		}

		-- local DummySignals = {}

		UpdateStatus("Loading signal proxy...")

		for _, Signal in next, BlacklistedSignals do
			for _, Connection in next, getconnections(Signal) do
				-- dawg why does volcano return a thread for Connection.Function
				if
					(
						Connection.Function
						and type(Connection.Function) == "function"
						and isexecutorclosure(Connection.Function)
					) or Connection.Function == nil -- CoreScript connections return nil for Function
				then
					continue
				else
					Connection:Disable()
				end
			end
		end

		task.wait(0.1)
		UpdateStatus("Scanning for Anti-Cheat threads...")

		local ThreadLinkedFunctions = {}
		local Hooked = 0

		-- Kill all threads first, then hook all functions that are obfuscated.
		for _, v in next, getreg() do
			if type(v) == 'thread' then
				local src = debug.info(v, 1, 's')
				if src and src == TargetScriptName then
					table.insert(ThreadLinkedFunctions, debug.info(v, 1, 'f'))
					warn("Killing thread", v)
					coroutine.close(v)
				end
			end
		end
		
		-- logDebugMessage(`[SGuard v4] Killed {#ThreadLinkedFunctions} threads, waiting for them to get GCd...\n`)
		-- task.wait(1)
		UpdateStatus("Waiting for garbage collector...")
		-- task.wait(1)

		for _, Object in next, getgc() do
			if type(Object) == 'function' and (not isexecutorclosure(Object)) then
				if debug.info(Object, 's') == TargetScriptName then

					-- task.wait()

					for _, ThreadFunction in next, ThreadLinkedFunctions do
						if Object == ThreadFunction then
							-- logDebugMessage(`[SGuard v4] Skipping thread-linked function: {debug.info(Object, 's')}`)
							return
						end
					end

					Hooked += 1
					hookfunction(Object, coroutine.yield)
					logDebugMessage('[SGuard v4] ACTraceKill', Object)
				end
			end
		end

		print(`[SGuard v4] Loaded successfully! Found: {Hooked}`)
		
	end, function(err)
		warn("SGuard v4 failed to load:", err)
		print("Stack trace:", debug.traceback())
		shared.ErrorMessage = `{err}\n{debug.traceback()}`
	end)

	if not Success then
		warn("SGuard v4 failed to load!")
		game:GetService("Players").LocalPlayer:Kick("SGuard v4 failed to load. \nThe error code has been copied to your clipboard, please report it in support.")
		local x,v = identifyexecutor()
		setclipboard(`{x} {v} {shared.ErrorMessage}`)
	end

	return Success, shared.SafeHook
end)()
