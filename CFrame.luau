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

local function Initialize(...)

    local Cleaner = require('./Cleaner.luau')
    local SecureNet = require('./SecureNet.luau')(...)
    local ArgumentChecks = require('./ArgumentCheck.luau').Results

    local LocalPlayer = game:GetService("Players").LocalPlayer
    local RunService = game:GetService("RunService")

    local Utils = {}

    function Utils.GetJoinCode(): string
        -- Encode the server JobId and PlaceId into a single join code.
        local JobId = game.JobId
        local PlaceId = game.PlaceId

        if not JobId or type(JobId) ~= "string" or #JobId < 1 then
            return ""
        end

        -- ROT13 for alphabetic characters (same as before)
        local function rot13(str)
            return str:gsub("%a", function(c)
                local byte = string.byte(c)
                local base
                if byte >= string.byte("a") and byte <= string.byte("z") then
                    base = string.byte("a")
                elseif byte >= string.byte("A") and byte <= string.byte("Z") then
                    base = string.byte("A")
                else
                    return c
                end
                return string.char((byte - base + 13) % 26 + base)
            end)
        end

        -- Base36 encode PlaceId to keep the join code compact
        local function toBase36(n)
            if type(n) ~= "number" or n < 0 then
                return ""
            end
            if n == 0 then
                return "0"
            end
            local chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
            local out = {}
            while n > 0 do
                local rem = n % 36
                n = math.floor(n / 36)
                table.insert(out, 1, chars:sub(rem + 1, rem + 1))
            end
            return table.concat(out)
        end

        -- Prepare encoded pieces
        local RotatedJobId = rot13(JobId):gsub("-", ".")
        local EncodedPlace = toBase36(PlaceId)

        -- Use '|' as separator between job part and place part
        return RotatedJobId .. "|" .. EncodedPlace
    end

    function Utils.JoinCodeToJoinData(JoinCode: string): { JobId: string, PlaceId: number }
        if not JoinCode or type(JoinCode) ~= "string" or #JoinCode < 1 then
            return { JobId = "", PlaceId = 0 }
        end

        local function rot13(str)
            return str:gsub("%a", function(c)
                local byte = string.byte(c)
                local base
                if byte >= string.byte("a") and byte <= string.byte("z") then
                    base = string.byte("a")
                elseif byte >= string.byte("A") and byte <= string.byte("Z") then
                    base = string.byte("A")
                else
                    return c
                end
                return string.char((byte - base + 13) % 26 + base)
            end)
        end

        local function fromBase36(s)
            if not s or s == "" then
                return 0
            end
            s = s:upper()
            local value = 0
            for i = 1, #s do
                local c = s:sub(i, i)
                local digit = tonumber(c)
                if not digit then
                    digit = string.byte(c) - string.byte("A") + 10
                end
                value = value * 36 + digit
            end
            return value
        end

        -- Split on the first '|' if present to avoid leaking the place part into the job id.
        local sep = JoinCode:find("|", 1, true)
        local rotatedPart, placePart
        if sep then
            rotatedPart = JoinCode:sub(1, sep - 1)
            placePart = JoinCode:sub(sep + 1)
        else
            rotatedPart = JoinCode
            placePart = nil
        end

        -- Trim whitespace just in case
        rotatedPart = rotatedPart:match("^%s*(.-)%s*$") or rotatedPart

        -- Restore original JobId format: '.' -> '-' then rot13
        local restoredJobRot = rotatedPart:gsub("%.", "-")
        local JobId = rot13(restoredJobRot)

        -- Decode place id, fall back to current game.PlaceId if missing
        local PlaceId = 0
        if placePart and #placePart > 0 then
            PlaceId = fromBase36(placePart)
        else
            PlaceId = game.PlaceId or 0
        end

        return { JobId = JobId, PlaceId = PlaceId }
    end

    Utils.TP = LPH_NO_VIRTUALIZE(function(Target: Vector3 | CFrame | PVInstance): boolean
        local Pivot: CFrame

        if typeof(Target) == "CFrame" then
            Pivot = Target :: CFrame
        elseif typeof(Target) == "Vector3" then
            Pivot = CFrame.new(Target :: Vector3)
        elseif typeof(Target) == "PVInstance" then
            Pivot = (Target :: PVInstance):GetPivot()
        elseif typeof(Target) == "BasePart" then
            Pivot = (Target :: BasePart):GetPivot()
        elseif typeof(Target) == "Model" then
            Pivot = (Target :: Model):GetPivot()
        end

        local Character = LocalPlayer.Character
        if Character then
            Character:PivotTo(Pivot)
            return true
        end

        return false
    end)

    Utils.TPRoot = LPH_NO_VIRTUALIZE(function(Target: Vector3 | CFrame | PVInstance): boolean
        local Pivot: CFrame

        if typeof(Target) == "CFrame" then
            Pivot = Target :: CFrame
        elseif typeof(Target) == "Vector3" then
            Pivot = CFrame.new(Target :: Vector3)
        elseif typeof(Target) == "PVInstance" then
            Pivot = (Target :: PVInstance):GetPivot()
        elseif typeof(Target) == "BasePart" then
            Pivot = (Target :: BasePart):GetPivot()
        elseif typeof(Target) == "Model" then
            Pivot = (Target :: Model):GetPivot()
        end

        local Character = LocalPlayer.Character
        if Character then
            Character.HumanoidRootPart.CFrame = Pivot
            return true
        end

        return false
    end)

    Utils.LockPosition = LPH_NO_VIRTUALIZE(function(Target: Vector3 | CFrame | PVInstance): RBXScriptConnection?
        local Character = LocalPlayer.Character

        if Character then
            local Connection = Cleaner(RunService.Heartbeat:Connect(function()
                Utils.TP(Target)
            end))

            task.delay(30, function()
                if Connection and Connection.Connected then
                    warn("LockPosition connection not properly cleaned up after 30 seconds!")
                    Connection:Disconnect()
                end
            end)

            return Connection
        end

        return nil
    end)

    Utils.LerpTP = LPH_NO_VIRTUALIZE(function(Target: Vector3 | CFrame | PVInstance, Duration: number): boolean
        local Pivot: CFrame

        if typeof(Target) == "CFrame" then
            Pivot = Target :: CFrame
        elseif typeof(Target) == "Vector3" then
            Pivot = CFrame.new(Target :: Vector3)
        elseif typeof(Target) == "PVInstance" then
            Pivot = (Target :: PVInstance):GetPivot()
        elseif typeof(Target) == "BasePart" then
            Pivot = (Target :: BasePart):GetPivot()
        elseif typeof(Target) == "Model" then
            Pivot = (Target :: Model):GetPivot()
        end

        local Character = LocalPlayer.Character
        if Character then
            local Humanoid = Character:FindFirstChildOfClass("Humanoid")
            local VehicleSeat = Humanoid and Humanoid.SeatPart
            local IsInVehicle = VehicleSeat and VehicleSeat:IsA("VehicleSeat")

            local ObjectToMove = (IsInVehicle and VehicleSeat.Parent) or Character
            if not (ObjectToMove and ObjectToMove:IsA("PVInstance")) then
                ObjectToMove = Character
            end

            local Start = os.clock()
            local StartPosition = ObjectToMove:GetPivot()
            local EndPosition = Pivot

            local LastSprintCall = 0

            while true do
                RunService.PreSimulation:Wait()

                for _, Descendant in next, ObjectToMove:GetDescendants() do
                    if Descendant:IsA("BasePart") then
                        Descendant.AssemblyLinearVelocity = Vector3.zero
                        Descendant.AssemblyAngularVelocity = Vector3.zero
                    end
                end

                local Elapsed = os.clock() - Start
                local Alpha = math.clamp(Elapsed / Duration, 0, 1)
                local NewPosition = StartPosition:Lerp(EndPosition, Alpha)
                
                if os.clock() - LastSprintCall > 1 then
                    LastSprintCall = os.clock()
                    SecureNet.Send(ArgumentChecks.Sprint.Value, true)
                end

                ObjectToMove:PivotTo(NewPosition)

                if Alpha >= 1 then
                    break
                end
            end

            if ObjectToMove then
                ObjectToMove:PivotTo(Pivot)
                return true
            else
                warn("ObjectToMove not found during end of LerpTP.")
                return false
            end
        end

        return false
    end)

    Utils.LerpTPWithHeight = LPH_NO_VIRTUALIZE(function(Target: Vector3 | CFrame | PVInstance, Duration: number): boolean
        local Pivot: CFrame

        if typeof(Target) == "CFrame" then
            Pivot = Target :: CFrame
        elseif typeof(Target) == "Vector3" then
            Pivot = CFrame.new(Target :: Vector3)
        elseif typeof(Target) == "PVInstance" then
            Pivot = (Target :: PVInstance):GetPivot()
        elseif typeof(Target) == "BasePart" then
            Pivot = (Target :: BasePart):GetPivot()
        elseif typeof(Target) == "Model" then
            Pivot = (Target :: Model):GetPivot()
        end

        local Params = RaycastParams.new()

        Params.FilterType = Enum.RaycastFilterType.Exclude
        Params.FilterDescendantsInstances = {
            LocalPlayer.Character,
            workspace:WaitForChild("Vehicles"),
            workspace:WaitForChild("Map"):WaitForChild("BoundaryWalls"),
            workspace:WaitForChild("Map"):WaitForChild("Vegetation"):WaitForChild("Trees"),
            workspace:WaitForChild("Map"):WaitForChild("Props"):WaitForChild("PowerLines"),
            workspace:WaitForChild("Map"):WaitForChild("Props"):WaitForChild("PrestigeMotorsLargeSign"),
        }
        Params.RespectCanCollide = true

        local function ShapecastDown(Position: Vector3): RaycastResult?
            local Result = workspace:Spherecast(Position + Vector3.yAxis * 7, 5, Vector3.yAxis * -200, Params)

            return Result
        end

        local function lerp(a: number, b: number, alpha: number): number
            return a + (b - a) * alpha
        end

        local Character = LocalPlayer.Character
        if Character then
            local Humanoid = Character:FindFirstChildOfClass("Humanoid")
            local VehicleSeat = Humanoid and Humanoid.SeatPart
            local IsInVehicle = VehicleSeat and VehicleSeat:IsA("VehicleSeat")

            local ObjectToMove = (IsInVehicle and VehicleSeat.Parent) or Character
            if not (ObjectToMove and ObjectToMove:IsA("PVInstance")) then
                ObjectToMove = Character
            end

            local Start = os.clock()
            local StartPosition = ObjectToMove:GetPivot()
            local EndPosition = Pivot
            local Height = StartPosition.Position.Y
            local Rotation = CFrame.lookAt(StartPosition.Position, EndPosition.Position).Rotation

            while true do
                RunService.PreSimulation:Wait()

                for _, Descendant in next, ObjectToMove:GetDescendants() do
                    if Descendant:IsA("BasePart") then
                        Descendant.AssemblyLinearVelocity = Vector3.zero
                        Descendant.AssemblyAngularVelocity = Vector3.zero
                    end
                end

                local Elapsed = os.clock() - Start
                local Alpha = math.clamp(Elapsed / Duration, 0, 1)
                local NewPosition = StartPosition:Lerp(EndPosition, Alpha)

                local RaycastResult = ShapecastDown(NewPosition.Position)
                local PivotTarget = CFrame.new(NewPosition.Position)

                if RaycastResult then
                    Height = lerp(Height, RaycastResult.Position.Y + 3, 0.1)
                    PivotTarget = CFrame.new(NewPosition.Position.X, NewPosition.Position.Y, NewPosition.Position.Z)
                end

                ObjectToMove:PivotTo(PivotTarget * Rotation)

                if Alpha >= 1 then
                    break
                end
            end

            if ObjectToMove then
                ObjectToMove:PivotTo(Pivot * Rotation)
                return true
            else
                warn("ObjectToMove not found during end of LerpTP.")
                return false
            end
        end

        return false
    end)

    Utils.MergeTables = LPH_NO_VIRTUALIZE(function(...)
        local Merged = {}
        for _, Table in ipairs({ ... }) do
            if type(Table) == "table" then
                for Key, Value in pairs(Table) do
                    Merged[Key] = Value
                end
            end
        end
        return Merged
    end)

    Utils.InsertMergeTables = LPH_NO_VIRTUALIZE(function(...)
        local Merged = {}
        for _, t in ipairs({ ... }) do
            if type(t) == "table" then
                for _, v in ipairs(t) do
                    table.insert(Merged, v)
                end
            end
        end
        return Merged
    end)

    function Utils.UnifiedTeleportHandler(options: { PlaceId: number, JobId: string?, Bypass: boolean? })
        local PlaceId = options.PlaceId
        local JobId = options.JobId
        local Bypass = options.Bypass

        print("Teleport requested", PlaceId, JobId, Bypass)
        setclipboard(JobId)

        if not PlaceId or type(PlaceId) ~= "number" or PlaceId <= 0 then
            error("Invalid PlaceId provided for teleport.")
            return
        end

        local TeleportService = game:GetService("TeleportService")
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer

        local PAID_PLACE = 95898900045000

        -- Script that will be queued to the final destination to load the main loader.
        local finalLoadScript = [[
    print("[Sasware] Loading main script...")
    --game:GetService("TeleportService"):SetLocalPlayerTeleportData({ teleport_reason = "Sasware Teleport Success" })
    if getgenv().Key ~= "BLACKLISTED" then
        task_wait(5)
        loadstring(game:HttpGet("https://example.com/script/Blockspin_Paid_Loader.luau"))()
    end
    ]]

        -- Prepare append string to preserve key across teleports and set teleport data
        local AppendString = 'getgenv().Key = "NoKey"\n'
        if getgenv().Key then
            AppendString = `getgenv().Key = "{getgenv().Key}"\n`
        end

        -- If caller explicitly requested to bypass paid-server redirection, teleport directly to the target.
        if Bypass == false then
            queue_on_teleport(AppendString .. finalLoadScript)

            local success, err = pcall(function()
                if JobId then
                    TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
                else
                    TeleportService:Teleport(PlaceId, LocalPlayer)
                end
            end)

            if not success then
                warn("Teleport error:", err)
            end

            return
        end

        -- If we're already going directly to the paid server, just queue the final loader and teleport.
        if PlaceId == PAID_PLACE then
            queue_on_teleport(AppendString .. finalLoadScript)

            local success, err = pcall(function()
                if JobId then
                    -- If JobId provided but target is paid server, attempt to join that instance
                    TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
                else
                    TeleportService:Teleport(PlaceId, LocalPlayer)
                end
            end)

            if not success then
                -- SafeNotify("Failed to teleport to paid server: " .. tostring(err), 5)
                warn("Teleport error:", err)
            end

            return
        end

        -- Build a redirect script that will run on the paid-only server.
        -- It will queue the final loader for the ultimate destination and then perform an authenticated teleport to it.
        local teleportCall
        if JobId then
            teleportCall = string.format(
                [[
    local TeleportService = game:GetService("TeleportService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    pcall(function()
        TeleportService:TeleportToPlaceInstance(%d, %q, LocalPlayer)
    end)
    ]],
                PlaceId,
                JobId
            )
        else
            -- If the PlaceId is the main place Id just queue the final loader on the next teleport.
            teleportCall = [[]] -- Nothing to do, the server will handle it.
        end

        -- paidRedirectScript runs on the paid server, queues the final loader and then teleports to the real target.
        local paidRedirectScript = string.format(
            [[
    local final = %q
    local append = %q
    -- Ensure the final loader is queued so it runs on arrival to the target server.
    queue_on_teleport(append .. final)
    -- Perform authenticated teleport to the actual destination.
    %s
    ]],
            finalLoadScript,
            AppendString,
            teleportCall
        )

        -- If we're currently on the paid server already, the above branch handled it.
        -- Otherwise queue the redirect script then teleport to the paid server.
        queue_on_teleport(AppendString .. paidRedirectScript)

        local success, err = pcall(function()
            TeleportService:Teleport(PAID_PLACE, LocalPlayer)
        end)

        if not success then
            -- SafeNotify("Failed to teleport to paid server: " .. tostring(err), 5)
            warn("Teleport error:", err)
        end
    end

    --#endregion

    return Utils
end

return Initialize