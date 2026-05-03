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

-- Prediction.luau
-- Dead-reckoning module for predicting server-side positions of parts and characters

return LPH_NO_VIRTUALIZE(function()

    local function ValidatePart(Part : BasePart?)
        return Part and Part.Parent and Part:IsDescendantOf(workspace)
    end

    local Prediction = {
        Connections = {},
        TrackedParts = {},
        TrackedCharacters = {},
        Configuration = {
            AccelerationWindowSize = 2,
            PredictPhysics = true
        },
        ModelSettings = {
            SimplifiedNetworkTime = false,
            AddAccelerationComponent = true,
            UseCustomVelocityResolver = false -- Toggle between Roblox velocity and custom resolver
        },
        -- Custom velocity resolver data: tracks position history per HumanoidRootPart
        VelocityResolver = {
            TrackedRoots = {}, -- [HumanoidRootPart] = { LastPosition, LastTime, ResolvedVelocity }
        }
    }

    local function GetCharacterFromPart(Part : BasePart)
        for Character, Data in next, Prediction.TrackedCharacters do
            if Part:IsDescendantOf(Character) then
                return Character, Data
            end
        end
        return nil
    end

    local RunService = game:GetService("RunService")
    local Heartbeat = RunService.Heartbeat
    local os_clock = os.clock

    -- Custom velocity resolver: computes velocity from position delta
    local function GetResolvedVelocity(RootPart: BasePart): Vector3
        if not Prediction.ModelSettings.UseCustomVelocityResolver then
            return RootPart.AssemblyLinearVelocity
        end

        local resolverData = Prediction.VelocityResolver.TrackedRoots[RootPart]
        if resolverData and resolverData.ResolvedVelocity then
            return resolverData.ResolvedVelocity
        end

        -- Fallback to Roblox velocity if not yet tracked
        return RootPart.AssemblyLinearVelocity
    end

    -- Update velocity resolver each heartbeat
    local function UpdateVelocityResolver(DeltaTime: number)
        if not Prediction.ModelSettings.UseCustomVelocityResolver then
            return
        end

        local currentTime = os_clock()

        for Character, CharData in next, Prediction.TrackedCharacters do
            local RootPart = CharData.Root
            if RootPart and RootPart.Parent then
                local currentPos = RootPart.Position
                local resolverData = Prediction.VelocityResolver.TrackedRoots[RootPart]

                if resolverData then
                    local timeDelta = currentTime - resolverData.LastTime
                    if timeDelta > 0 then
                        local posDelta = currentPos - resolverData.LastPosition
                        resolverData.ResolvedVelocity = posDelta / timeDelta
                    end
                    resolverData.LastPosition = currentPos
                    resolverData.LastTime = currentTime
                else
                    -- Initialize tracking for this root
                    Prediction.VelocityResolver.TrackedRoots[RootPart] = {
                        LastPosition = currentPos,
                        LastTime = currentTime,
                        ResolvedVelocity = RootPart.AssemblyLinearVelocity
                    }
                end
            else
                -- Cleanup invalid roots
                Prediction.VelocityResolver.TrackedRoots[RootPart] = nil
            end
        end
    end

    function Prediction:Register(Part : BasePart)
        assert(Part:IsA("BasePart"), string.format("Invalid part class: %s", Part.ClassName))
        assert(not self.TrackedParts[Part], string.format("Part %s is already registered", Part.Name))
        self.TrackedParts[Part] = {
            LastVelocity = Vector3.new(0, 0, 0),
            PredictedPosition = Part.Position
        }
    end

    function Prediction:RegisterCharacter(Model : Model)
        assert(Model:IsA("Model"), string.format("Invalid model class: %s", Model.ClassName))
        assert(Model:FindFirstChild("Humanoid"), "Model must have a Humanoid")
        assert(Model:FindFirstChild("HumanoidRootPart"), "Model must have a HumanoidRootPart")

        -- If the character was previously registered, unregister it first
        if self.TrackedCharacters[Model] then
            self:UnregisterCharacter(Model)
        end

        Prediction:Register(Model:FindFirstChild("HumanoidRootPart") :: BasePart)

        self.TrackedCharacters[Model] = {
            Root = Model:FindFirstChild("HumanoidRootPart") :: BasePart
        }

        print("Registered character:", Model.Name)
    end
    
    function Prediction:UnregisterCharacter(Model : Model)
        if self.TrackedCharacters[Model] then
            local RootPart = self.TrackedCharacters[Model].Root
            if RootPart and self.TrackedParts[RootPart] then
                self.TrackedParts[RootPart] = nil
            end
            self.TrackedCharacters[Model] = nil
            print("Unregistered character:", Model.Name)
            return true
        end
        return false
    end

    function Prediction:GetPredictedPosition(Part : BasePart)
        assert(Part:IsA("BasePart"), string.format("Invalid part class: %s", Part.ClassName))

        if not self.TrackedParts[Part] then
            local Character, Data = GetCharacterFromPart(Part)
            if Character then
                if Part == Data.Root then
                    return self.TrackedParts[Data.Root].PredictedPosition
                else
                    local Offset = Part.Position - Data.Root.Position
                    return self.TrackedParts[Data.Root].PredictedPosition + Offset
                end
            else
                warn(string.format("Part %s is not registered", Part.Name))
                return Part.Position
            end
        end

        return self.TrackedParts[Part].PredictedPosition
    end

    Prediction.Connections.Heartbeat = Heartbeat:Connect(function(DeltaTime)

        -- Update custom velocity resolver first
        UpdateVelocityResolver(DeltaTime)

        local Ping = game:GetService("Players").LocalPlayer:GetNetworkPing()

        local NetworkTime = Ping

        if Prediction.ModelSettings.SimplifiedNetworkTime then
            NetworkTime *= 1.15
        else
            NetworkTime += DeltaTime + (1 / 60)
        end

        for Part, Data in next, Prediction.TrackedParts do
            if ValidatePart(Part) then

                -- Use custom velocity resolver or Roblox velocity based on setting
                local CurrentVelocity = GetResolvedVelocity(Part)

                local Acceleration = Vector3.new(0, 0, 0)
                if DeltaTime > 0 then
                    Acceleration = (CurrentVelocity - Data.LastVelocity) / DeltaTime
                end

                Data.LastVelocity = CurrentVelocity
                Data.PredictedPosition = Part.Position + (CurrentVelocity * NetworkTime)

                if Prediction.ModelSettings.AddAccelerationComponent then
                    Data.PredictedPosition = Data.PredictedPosition + (Acceleration * 0.5 * (NetworkTime ^ 2))
                end

            else
                -- Remove from TrackedParts
                Prediction.TrackedParts[Part] = nil
                
                -- Cleanup velocity resolver data
                Prediction.VelocityResolver.TrackedRoots[Part] = nil
                
                -- Check if this was a character's root part and remove from TrackedCharacters
                for Character, CharData in next, Prediction.TrackedCharacters do
                    if CharData.Root == Part then
                        Prediction.TrackedCharacters[Character] = nil
                        print("Removed invalid tracked character:", Character.Name)
                        break
                    end
                end
            end
        end

    end)

    function Prediction:Cleanup()
        -- Disconnect all connections
        for _, Connection in next, self.Connections do
            if typeof(Connection) == "RBXScriptConnection" and Connection.Connected then
                Connection:Disconnect()
            end
        end
        
        -- Clear tracked data
        self.Connections = {}
        self.TrackedParts = {}
        self.TrackedCharacters = {}
        self.VelocityResolver.TrackedRoots = {}
        
        print("Prediction module cleaned up")
    end

    -- Expose method to get resolved velocity for external use
    function Prediction:GetVelocity(Part: BasePart): Vector3
        return GetResolvedVelocity(Part)
    end

    return Prediction

end)()