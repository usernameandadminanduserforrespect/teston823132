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

local function Initialize(Storage, SafeRequire, Core, UpdateStatus, T)
    local Net = SafeRequire(Core:WaitForChild("Net") :: ModuleScript)

    xpcall(function()
        if Storage.SecurityCheckPatched == true then
            return
        end

        local function findSecurityCheck()
            local Ok, Value = pcall(debug.getupvalue, Net.send, 2)

            -- print(Ok, Value)

            if Ok and Value and type(Value) == "function" then

                -- table.foreach(debug.getconstants(Value), print)

                local ConstantsToFind = { ["getfenv"] = false, ["identifyexecutor"] = false }

                for Constant, _ in next, ConstantsToFind do
                    local Found = false
                    for _, Const in next, debug.getconstants(Value) do
                        if Const == Constant then
                            -- print("Found constant:", Constant)
                            Found = true
                            break
                        end
                    end

                    if not Found then
                        return nil
                    end

                    ConstantsToFind[Constant] = true
                end

                if not (ConstantsToFind["getfenv"] and ConstantsToFind["identifyexecutor"]) then
                    return nil
                end

                -- print("Security check found, patching...")

                return Value
            end

            return nil
        end

        local SecurityCheck = findSecurityCheck()
        if not SecurityCheck then
            if Storage.SecurityCheckPatched ~= false then
                warn(
                    "Security check signature was not found on Net.send. It may have changed or been patched already."
                )
            end
            Storage.SecurityCheckPatched = false
            return
        end

        replaceclosure(
            SecurityCheck,
            LPH_NO_UPVALUES(function(p12, p13, p14, p15, ...)
                return p12(p13, p14, p15, ...)
            end)
        )

        Storage.SecurityCheckPatched = true
    end, function(err)
        local traceback
        local success, trace = pcall(debug.traceback, err, 2)
        if success and type(trace) == "string" then
            traceback = trace
        else
            traceback = tostring(err)
        end

        local message = "Network security check failed!"
        warn(message)
        print(traceback)

        if typeof(setclipboard) == "function" then
            local clipboardOk, clipboardErr = pcall(setclipboard, traceback)
            if clipboardOk then
                warn("Stack trace copied to clipboard.")
            else
                warn("Failed to copy stack trace to clipboard:", clipboardErr)
            end
        else
            warn("setclipboard is not available in this environment.")
        end

        coroutine.yield()
    end)

    local SecureNet = {
        Send2 = clonefunction(Net.send),
        Get2 = clonefunction(Net.get),
    }

    UpdateStatus(T("Updating arguments..."))
    local ArgCheck = require("./ArgumentCheck.luau")
    local ArgumentChecks = ArgCheck.Results

    -- Ensure all argument checks are found.
    assert(ArgCheck.AllFound, "Not all argument checks were found!")

    function SecureNet.Send(...)
        local FirstArg = select(1, ...)
        if type(FirstArg) == "string" then
            local Found = false
            for _, Data in pairs(ArgumentChecks) do
                if Data.Value == FirstArg and Data.Found then
                    Found = true
                    break
                end
            end

            if not Found then
                if Storage.Blacklisted_Network_Calls[FirstArg] then
                    warn("Network call to", FirstArg, "is blacklisted. Call blocked.")
                    return
                else
                    warn(
                        "First argument",
                        FirstArg,
                        "not found in argument checks or not verified. Network call blocked."
                    )
                    return
                end
            end
        else
            warn("First argument is not a string. Network call blocked.")
            return
        end

        return SecureNet.Send2(...)
    end

    function SecureNet.Get(...)
        local FirstArg = select(1, ...)
        if type(FirstArg) == "string" then
            local Found = false
            for _, Data in pairs(ArgumentChecks) do
                if Data.Value == FirstArg and Data.Found then
                    Found = true
                    break
                end
            end

            if not Found then
                if Storage.Blacklisted_Network_Calls[FirstArg] then
                    warn("Network call to", FirstArg, "is blacklisted. Call blocked.")
                    return
                else
                    warn(
                        "First argument",
                        FirstArg,
                        "not found in argument checks or not verified. Network call blocked."
                    )
                    return
                end
            end
        else
            warn("First argument is not a string. Network call blocked.")
            return
        end

        return SecureNet.Get2(...)
    end

    return SecureNet
end

return Initialize