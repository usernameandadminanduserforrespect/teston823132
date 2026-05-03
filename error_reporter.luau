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
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local StatefulObject = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Core"):WaitForChild("StatefulObject") :: ModuleScript)

	local Classes = debug.getupvalue(StatefulObject.new_class, 3)
	assert(Classes and type(Classes) == "table", "Classes table not found in StatefulObject module.")

	local ClassInterface = {}

	-- Util funcs

	local function GetInstanceFromPath(path : string)
		local instance = game
		for part in path:gmatch("[^%.]+") do
			instance = instance:FindFirstChild(part)
			if not instance then
				return nil
			end
		end
		return instance
	end

	-- Class funcs

	function ClassInterface.GetClasses()
		Classes = debug.getupvalue(StatefulObject.new_class, 3)
		return Classes
	end

	function ClassInterface._GetClassInfo(Class : { new: (self: any, ...any) -> any, objects: { [any]: any } })

		if not Class or type(Class) ~= "table" then
			warn("Invalid class provided.")
			return nil
		end

		if not Class.new or type(Class.new) ~= "function" then
			warn("Class does not have a valid 'new' method.")
			return nil
		end

		local Info = {
			Name = "???",
			Module = nil,
			ModulePath = "???",
			Objects = {}
		}

		local ClassInitiator = debug.getupvalue(Class.new, 3)

		if not (ClassInitiator and type(ClassInitiator) == "function") then
			warn("ClassInitiator not found for class:", Class)
			return 
		end

		local Module = getfenv(ClassInitiator).script or GetInstanceFromPath(debug.info(ClassInitiator, "s"))
		local ClassName = Module and Module.Name or "???"

		Info.Name = ClassName
		Info.Module = Module
		Info.ModulePath = Module and Module:GetFullName() or "???"
		Info.Objects = Class.objects

		return Info
	end

	function ClassInterface.GetClass(TargetClassName : string)
		
		for i, Class in next, Classes do
			local ClassInfo = ClassInterface._GetClassInfo(Class)
			if ClassInfo and (ClassInfo.Name == TargetClassName or tostring(i) == TargetClassName) then
				return Class
			end
		end

		warn("Class not found:", TargetClassName)

		return nil
	end

	function ClassInterface.GetClassFromModule(TargetModule : ModuleScript)
		if not TargetModule or not TargetModule:IsA("ModuleScript") then
			warn("Invalid module script provided.")
			return nil
		end

		for _, Class in next, Classes do
			local ClassInfo = ClassInterface._GetClassInfo(Class)
			if ClassInfo and ClassInfo.Module == TargetModule then
				return Class
			end
		end

		warn("Class not found for module:", TargetModule:GetFullName())
		return nil
	end

	return ClassInterface

end)()