-- Identifier.luau
-- Module for identifying Sasware users and also identifying the current user.
-- The module uses animation replication to replicate the identifier to other clients.

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

    local Identifier = {
        Registry = {},
        Visuals = {},
        AnimationId = "http://www.roblox.com/asset/?id=507770818",
        OwnerAnimationId = "rbxassetid://139658061151500",
        Initialized = false,
        Identify = false,
        AnimationTrack = nil,
        Visualize = true -- Whether to visualize by having a billboard gui above the player's head
    }

    local Players = game:GetService("Players")
    local CoreGui = game:GetService("CoreGui")
    local LocalPlayer = Players.LocalPlayer

    local GuiFolder = CoreGui:FindFirstChild("IdentifierGuis")
    if not GuiFolder then
        GuiFolder = Instance.new("Folder")
        GuiFolder.Name = "IdentifierGuis"
        GuiFolder.Parent = CoreGui
    end

    local function CreateVisual(Player: Player, UserType: string)
        if Identifier.Visuals[Player] then
            return
        end

        local Character = Player.Character
        local Head = Character and Character:FindFirstChild("Head")

        if not Head then
            return
        end

        local BillboardGui = Instance.new("BillboardGui")
        BillboardGui.Name = Player.Name
        BillboardGui.Adornee = Head
        BillboardGui.AlwaysOnTop = true
        BillboardGui.LightInfluence = 0
        BillboardGui.Size = UDim2.new(4, 0, 4, 0)
        BillboardGui.StudsOffset = Vector3.new(0, 5, 0)
        BillboardGui.ClipsDescendants = false

        local Image = Instance.new("ImageLabel")
        Image.Image = "rbxassetid://113209211300754"
        Image.BackgroundTransparency = 1
        Image.Size = UDim2.new(1, 0, 1, 0)
        Image.Parent = BillboardGui

        if UserType == "Owner" then
            local Text = Instance.new("TextLabel")
            Text.Text = "Sasware Owner"
            Text.BackgroundTransparency = 1
            Text.Size = UDim2.new(2, 0, .5, 0)
            Text.Position = UDim2.new(-.5, 0, .8, 0)
            Text.Font = Enum.Font.SourceSansBold
            Text.TextColor3 = Color3.new(1, 1, 1)
            Text.TextScaled = true
            Text.Parent = Image
        end

        BillboardGui.Parent = GuiFolder
        Identifier.Visuals[Player] = BillboardGui
    end

    local function Scan(Player : Player) : string?
        
        if Player == LocalPlayer then
            local userType = Identifier.Identify and (not LPH_OBFUSCATED and "Owner" or "User") or nil
            if userType then
                print(`[Identifier] Local player registered as {userType}`)
            end
            return userType
        end

        local Character = Player.Character

        if not Character then
            return nil
        end

        local Humanoid = Character:FindFirstChild("Humanoid")

        if Humanoid then
            if Humanoid:FindFirstChild("Animator") then
                local Animator = Humanoid.Animator
                for _, Animation in next, Animator:GetPlayingAnimationTracks() do
                    if Animation.Animation.AnimationId == Identifier.OwnerAnimationId then
                        print(`[Identifier] {Player.Name} is playing the Owner animation. Registered as Owner.`)
                        return "Owner"
                    elseif Animation.Animation.AnimationId == Identifier.AnimationId then
                        print(`[Identifier] {Player.Name} is playing the User animation. Registered as User.`)
                        return "User"
                    end
                end
            end
        end

        return nil

    end

    function Identifier:Scan(Player : Player) : string?

        if not self.Registry[Player] then
            self.Registry[Player] = Scan(Player)
        end

        return self.Registry[Player]
    end


    local function UpdateVisuals()
        for Player, Gui in pairs(Identifier.Visuals) do
            local Character = Player.Character
            local Head = Character and Character:FindFirstChild("Head")
            local userType = Identifier:Scan(Player)
            local isOwner = userType == "Owner"
            local hasOwnerText = Gui:FindFirstChild("ImageLabel") and Gui.ImageLabel:FindFirstChild("TextLabel")

            if not Head or not userType or not Identifier.Visualize or Player == LocalPlayer or (isOwner and not hasOwnerText) or (not isOwner and hasOwnerText) then
                Gui:Destroy()
                Identifier.Visuals[Player] = nil
            else
                if Gui.Adornee ~= Head then
                    Gui.Adornee = Head
                end
            end
        end

        if Identifier.Visualize then
            for _, Player in ipairs(Players:GetPlayers()) do
                if Player ~= LocalPlayer then
                    local userType = Identifier:Scan(Player)
                    if userType and not Identifier.Visuals[Player] then
                        CreateVisual(Player, userType)
                    end
                end
            end
        end
    end

    function Identifier:Initialize()

        if self.Initialized then
            return
        end

        self.Initialized = true

        task.spawn(function()
            while self.Initialized do

                self.Registry = {} -- Reset registry each loop to get fresh data
                for _, Player in next, Players:GetPlayers() do
                    if Player ~= LocalPlayer then
                        self.Registry[Player] = Scan(Player)
                    end
                end

                if self.Visualize then
                    UpdateVisuals()
                end

                if self.Identify then
                    local Character = LocalPlayer.Character
                    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
                    local Animator = Humanoid and Humanoid:FindFirstChildOfClass("Animator")

                    if Animator then
                        if self.AnimationTrack then
                            self.AnimationTrack:Stop()
                            self.AnimationTrack:Destroy()
                        end
                        
                        local Animation = Instance.new("Animation")
                        Animation.AnimationId = not LPH_OBFUSCATED and self.OwnerAnimationId or self.AnimationId
                        self.AnimationTrack = Animator:LoadAnimation(Animation)
                        self.AnimationTrack:Play(0, 0.001, 1)
                        self.AnimationTrack.Looped = true
                        self.AnimationTrack:AdjustSpeed(0)
                        Animation:Destroy()
                    end
                else
                    if self.AnimationTrack then
                        self.AnimationTrack:Stop()
                        self.AnimationTrack:Destroy()
                        self.AnimationTrack = nil
                    end
                end
                task.wait(1)
            end
        end)
    end

    function Identifier:ToggleIdentify(Value : boolean)

        self.Identify = Value

        if Value then
            self:Initialize()
        else
            if self.AnimationTrack then
                self.AnimationTrack:Stop()
                self.AnimationTrack:Destroy()
                self.AnimationTrack = nil
            end
        end

    end

    function Identifier:Reset()

        self.Registry = {}
        self.AnimationTrack = nil
        self.Identify = false
        self.Initialized = false
        
        for _, visual in pairs(self.Visuals) do
            visual:Destroy()
        end
        self.Visuals = {}

    end

    function Identifier:Destroy()

        if self.AnimationTrack then
            self.AnimationTrack:Stop()
            self.AnimationTrack:Destroy()
            self.AnimationTrack = nil
        end

        for _, visual in pairs(self.Visuals) do
            visual:Destroy()
        end
        self.Visuals = {}

        self.Registry = {}
        self.Initialized = false
        self.Identify = false

    end

    return Identifier
end)()