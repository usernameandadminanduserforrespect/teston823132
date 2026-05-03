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
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local Camera = workspace.CurrentCamera

	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		Camera = workspace.CurrentCamera
	end)

	local Aiming = {
		HitChance = 100,
		FOV = 60,
		NPCs = false,
		Players = true,
		Enabled = false,
		ShowFOV = true,
		AimTracer = true,
		DynamicFOV = true,
		FOVColor = Color3.fromRGB(255, 255, 255),
		AimTracerColor = Color3.fromRGB(255, 0, 0),
		CurrentTarget = nil,
		FilterFriends = false,
		CenterLockFOV = false,
		ClosestToCamera = false,
	}

	local InternalFOV = Aiming.FOV
	local FOVCircle = Drawing.new("Circle")

	FOVCircle.NumSides = 20
	FOVCircle.Transparency = 1
	FOVCircle.Thickness = 2
	FOVCircle.Color = Aiming.FOVColor
	FOVCircle.Filled = false

	local FOVTracer = Drawing.new("Line")

	FOVTracer.Thickness = 2

	local function UpdateFOV()
		if Aiming.ShowFOV then
			if Aiming.DynamicFOV then
				InternalFOV = Aiming.FOV * (70 / Camera.FieldOfView)
			else
				InternalFOV = Aiming.FOV
			end

			FOVCircle.Visible = true
			FOVCircle.Radius = InternalFOV
			FOVCircle.Color = Aiming.FOVColor
			if Aiming.CenterLockFOV then
				FOVCircle.Position = Camera.ViewportSize / 2
			else
				FOVCircle.Position = UserInputService:GetMouseLocation()
			end
		else
			FOVCircle.Visible = false
		end
	end

	local function GetCharactersInViewport(): { { Character: Model, Position: Vector2 } }
		local ToProcess = {}
		local CharactersOnScreen = {}

		if Aiming.Players then
			for _, Player in ipairs(Players:GetPlayers()) do
				if Player == Players.LocalPlayer then
					continue
				end

				if Aiming.FilterFriends then
					if Player:GetAttribute("IsFriend") ~= nil then

						local LastUpdate = Player:GetAttribute("LastUpdate")

						if LastUpdate and os.clock() - LastUpdate > 5 then
							Player:SetAttribute("IsFriend", Player:IsFriendsWith(Players.LocalPlayer.UserId))
							Player:SetAttribute("LastUpdate", os.clock())
						end

						if Player:GetAttribute("IsFriend") == true then
							continue
						end
						
					else
						Player:SetAttribute("IsFriend", Player:IsFriendsWith(Players.LocalPlayer.UserId))
						Player:SetAttribute("LastUpdate", os.clock())
						if Player:GetAttribute("IsFriend") == true then
							continue
						end
					end
				end

				if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then

					local Humanoid = Player.Character:FindFirstChild("Humanoid")
					if Humanoid and Humanoid.Health > 0 then
						table.insert(ToProcess, Player.Character)
					end
				end
			end
		end

		if Aiming.NPCs then
			-- for _, NPC in ipairs(workspace.NPCs.Hostile:GetChildren()) do
			--     if NPC:IsA("Model") and NPC:FindFirstChild("HumanoidRootPart") then
			--         table.insert(ToProcess, NPC)
			--     end
			-- end

			for _, NPC in next, game:GetService("CollectionService"):GetTagged("NPC") do
				if
					NPC:IsDescendantOf(workspace)
					and NPC:IsA("Model")
					and NPC:FindFirstChild("HumanoidRootPart")
					and game:GetService("CollectionService"):HasTag(NPC, "ActiveCharacter")
				then
					table.insert(ToProcess, NPC)
				end
			end
		end

		for _, Character in ipairs(ToProcess) do
			local Position, OnScreen = Camera:WorldToViewportPoint(Character.HumanoidRootPart.Position)

			if OnScreen then
				table.insert(CharactersOnScreen, {
					Character = Character,
					Position = Vector2.new(Position.X, Position.Y),
				})
			end
		end

		return CharactersOnScreen
	end

	local function DistanceFromMouse(Position: Vector2): number
		if Aiming.CenterLockFOV then
			return ((Camera.ViewportSize / 2) - Position).Magnitude
		else
			return (UserInputService:GetMouseLocation() - Position).Magnitude
		end
	end

	local function GetPlayersInFOV(): { { Character: Model, Distance: number, Position: Vector2, DistanceFromCamera: number } }
		local Characters = GetCharactersInViewport()
		local PlayersInFOV = {}

		for _, Character in ipairs(Characters) do
			local Distance = DistanceFromMouse(Character.Position)
			if Distance <= InternalFOV then
				table.insert(PlayersInFOV, {
					Character = Character.Character,
					Distance = Distance,
					Position = Character.Position,
					DistanceFromCamera = (Camera.CFrame.Position - Character.Character:GetPivot().Position).Magnitude,
				})
			end
		end

		return PlayersInFOV
	end

	local function GetClosestPlayer(): (Model, number, Vector2)
		local PlayersInFOV = GetPlayersInFOV()
		local ClosestPlayer = nil
		local ClosestDistance = math.huge
		local ClosestPosition = nil

		if Aiming.ClosestToCamera then
			table.sort(PlayersInFOV, function(a, b)
				return a.DistanceFromCamera < b.DistanceFromCamera
			end)
		else
			table.sort(PlayersInFOV, function(a, b)
				return a.Distance < b.Distance
			end)
		end

		if #PlayersInFOV > 0 then
			local Closest = PlayersInFOV[1]
			ClosestPlayer = Closest.Character
			ClosestPosition = Closest.Position
			ClosestDistance = Closest.Distance
		end
		
		return ClosestPlayer, ClosestDistance, ClosestPosition
	end

	local Connection = RunService.RenderStepped:Connect(function()
		if Aiming.Enabled then
			UpdateFOV()
			local ClosestPlayer, Distance, Position = GetClosestPlayer()
			Aiming.CurrentTarget = ClosestPlayer
			if ClosestPlayer then
				FOVTracer.Visible = Aiming.AimTracer
				FOVTracer.From = Aiming.CenterLockFOV and (Camera.ViewportSize / 2) or UserInputService:GetMouseLocation()
				FOVTracer.To = Position
				FOVTracer.Color = Aiming.AimTracerColor
			else
				FOVTracer.Visible = false
			end
		else
			FOVCircle.Visible = false
			FOVTracer.Visible = false
			Aiming.CurrentTarget = nil
		end
	end)

	function Aiming.ShouldMiss()
		local HitChance = Aiming.HitChance / 100
		local RandomValue = math.random(0, 100) / 100
		return RandomValue > HitChance
	end

	local function Unload()
		Connection:Disconnect()
		FOVCircle:Remove()
		FOVTracer:Remove()
	end

	Aiming.Unload = Unload

	return Aiming
end)()