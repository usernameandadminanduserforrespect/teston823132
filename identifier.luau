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
	-- Globals
	local game = game
	local workspace = workspace
	local pcall = pcall
	local typeof = typeof
	local ipairs = ipairs
	local table = table
	local next = next
	local Vector3 = Vector3
	local Vector2 = Vector2
	local Color3 = Color3
	local CFrame = CFrame
	local Drawing = Drawing
	local math = math
	local Enum = Enum
	local Instance = Instance

	-- Services
	local RunService = game:GetService("RunService")
	local Players = game:GetService("Players")

	-- Variables
	local LocalPlayer = Players.LocalPlayer
	local Camera = workspace.CurrentCamera

	local Connections = {}
	Connections[1] = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		Camera = workspace.CurrentCamera
	end)

	local ESP = {
		Config = {
			UseDisplayName = true,
			Highlights = true,
			Glow = false,
			Arrows = false,
			Tracers = false,
			Enabled = false,
			TeamCheck = false,
			Players = false,
			Boxes = false,
			Text = false,
			BoxType = "2D",
			BoxSize = Vector3.new(4, 6, 2),
			StaticSize = Vector2.new(40, 60),
			BoxColor = Color3.fromRGB(255, 255, 255),
			TextColor = Color3.fromRGB(255, 255, 255),
			Font = 0,
			TracerColor = Color3.fromRGB(255, 255, 255),
			HighlightFillColor = Color3.fromRGB(255, 145, 20),
			HighlightOutlineColor = Color3.fromRGB(255, 0, 0),
			HighlightFillTransparency = 0.9,
			HighlightOutlineTransparency = 0.5,
			UseTeamColor = false,
			MaxDistance = 500,
			FadeDistance = 100,
		},
		Storage = {
			PlayerVisuals = {},
		},
	}

	local function Cleanup(Item: any)
		if not Item then return end
		pcall(function()
			if typeof(Item) == "RBXScriptConnection" then
				Item:Disconnect()
				return
			elseif typeof(Item) == "Instance" then
				Item:Destroy()
				return
			end

			local destroyMethod = Item.Destroy
			local removeMethod = Item.Remove
			if type(destroyMethod) == "function" then
				local destroyedFlag = Item.Destroyed
				if destroyedFlag == nil or destroyedFlag == false then -- Prevent double-destroy calls
					destroyMethod(Item)
					return
				end
			end

			if type(removeMethod) == "function" then
				removeMethod(Item)
			end
		end)
	end

	local function CleanupPlayerVisuals(player)
		local visuals = ESP.Storage.PlayerVisuals[player]
		if visuals then
			Cleanup(visuals.Box)
			Cleanup(visuals.HighlightObject)
			Cleanup(visuals.TracerObject)
			ESP.Storage.PlayerVisuals[player] = nil
		end
	end

	local function Unload()
		for _, conn in ipairs(Connections) do
			Cleanup(conn)
		end
		table.clear(Connections)

		for player in next, ESP.Storage.PlayerVisuals do
			CleanupPlayerVisuals(player)
		end
	end

	-- Function Setup

	local function Distance(Position: Vector3)
		return (Position - Camera.CFrame.Position).Magnitude
	end

	local function ToV2(Vector: Vector3): Vector2
		return Vector2.new(Vector.X, Vector.Y)
	end

	local function WTVP(Position: Vector3): (Vector3, boolean)
		return Camera:WorldToViewportPoint(Position)
	end

	local function WTVP2D(Position: Vector3): Vector2
		local ScreenPosition, _ = Camera:WorldToViewportPoint(Position)
		local Vector = ToV2(ScreenPosition)
		return Vector
	end

	local function EnsureInstance(Instance: Instance)
		return Instance and Instance.Parent and Instance:IsDescendantOf(workspace)
	end

	local function GetPlayer(Character: Model): Player?
		return Players:GetPlayerFromCharacter(Character)
	end

	local function GetColor(Model: Model, Box: any): Color3
		if Box.IsPlayer then
			if ESP.Config.UseTeamColor and Box.Player and Box.Player.TeamColor then
				return Box.Player.TeamColor.Color
			end
		end

		if Box.DynamicColor then
			return Box.DynamicColor(Model)
		elseif Box.BoxColor then
			return Box.BoxColor
		end

		return ESP.Config.BoxColor
	end

	local function CalculateTransparency(Distance: number): number
		local MaxDistance = ESP.Config.MaxDistance
		local FadeDistance = ESP.Config.FadeDistance

		if Distance >= MaxDistance then
			return 0
		elseif Distance > (MaxDistance - FadeDistance) then
			return 1 - (Distance - (MaxDistance - FadeDistance)) / FadeDistance
		else
			return 1
		end
	end

	local function CreateBox(Root: PVInstance, Config: { any })
		local Box = {
			Root = Root,
			BoxType = ESP.Config.BoxType,
			DynamicColor = nil,
			DrawingObject = nil,
			TextObject = nil,
			Color = nil,
			IsPlayer = false,
			Destroyed = false,
		}

		assert(Box.Root.Parent and Box.Root.Parent:IsA("Model"), "Root must be a descendant of a Model")

		for Index, Value in Config do
			Box[Index] = Value
		end

		if Box.IsPlayer then
			Box.Player = GetPlayer(Box.Root.Parent)
		end

		Box.BoxColor = GetColor(Box.Root.Parent, Box)

		function Box:GetPivot(): CFrame
			local Pos, _ = Box.Root.Parent:GetBoundingBox() :: CFrame, Vector3
			return Pos
		end

		local function GetScreen(Model: Model)
			local Pivot = Model:GetPivot()
			local Position = Pivot.Position
			local ScreenPosition, Visible = WTVP(Position)
			return ScreenPosition, Visible
		end

		local function Create2DBox()
			local Drawing = Drawing.new("Quad")
			local DrawingObject = { Drawing = Drawing }
			function DrawingObject.Update()
				local Center, Visible = GetScreen(Box.Root.Parent)
				Visible = Visible and ESP.Config.Boxes
				Drawing.Visible = Visible
				if Visible then
					local ESPSize: Vector2 = ESP.Config.StaticSize
					local Distance = Distance(Box:GetPivot().Position)
					local FieldOfView = Camera.FieldOfView
					if Distance > ESP.Config.MaxDistance then
						Drawing.Visible = false
						return
					end
					Drawing.Transparency = CalculateTransparency(Distance)
					local Size = ESPSize / (Distance / 100) * (FieldOfView / 70)
					Drawing.PointA = Vector2.new(Center.X - Size.X / 2, Center.Y - Size.Y / 2)
					Drawing.PointB = Vector2.new(Center.X + Size.X / 2, Center.Y - Size.Y / 2)
					Drawing.PointC = Vector2.new(Center.X + Size.X / 2, Center.Y + Size.Y / 2)
					Drawing.PointD = Vector2.new(Center.X - Size.X / 2, Center.Y + Size.Y / 2)
				end
			end
			function DrawingObject:Remove()
				Drawing:Remove()
			end
			return DrawingObject
		end
		local function CreateBox3D()
			local Drawing = Drawing.new("Quad")
			local DrawingObject = { Drawing = Drawing }
			function DrawingObject.Update()
				local _, Visible = GetScreen(Box.Root.Parent)
				Visible = Visible and ESP.Config.Boxes
				Drawing.Visible = Visible
				if Visible then
					local ESPSize = ESP.Config.BoxSize
					local Pivot = Box:GetPivot()
					local Distance = Distance(Pivot.Position)
					if Distance > ESP.Config.MaxDistance then
						Drawing.Visible = false
						return
					end
					Drawing.Transparency = CalculateTransparency(Distance)
					local TopLeft = WTVP2D((Pivot * CFrame.new(ESPSize.X / 2, ESPSize.Y / 2, 0)).Position)
					local TopRight = WTVP2D((Pivot * CFrame.new(-ESPSize.X / 2, ESPSize.Y / 2, 0)).Position)
					local BottomRight = WTVP2D((Pivot * CFrame.new(-ESPSize.X / 2, -ESPSize.Y / 2, 0)).Position)
					local BottomLeft = WTVP2D((Pivot * CFrame.new(ESPSize.X / 2, -ESPSize.Y / 2, 0)).Position)
					Drawing.PointA = TopLeft
					Drawing.PointB = TopRight
					Drawing.PointC = BottomRight
					Drawing.PointD = BottomLeft
				end
			end
			function DrawingObject:Remove()
				Drawing:Remove()
			end
			return DrawingObject
		end
		local function CreateBox3DFull()
			local Lines = {}
			for i = 1, 12 do Lines[i] = Drawing.new("Line"); Lines[i].Thickness = 1; Lines[i].Transparency = 1 end
			local DrawingObject = { Drawing = Lines }
			function DrawingObject.Update()
				local _, Visible = GetScreen(Box.Root.Parent)
				Visible = Visible and ESP.Config.Boxes
				for _, Line in ipairs(Lines) do Line.Visible = Visible end
				if Visible then
					local ESPSize = ESP.Config.BoxSize
					local Pivot = Box:GetPivot()
					local Distance = Distance(Pivot.Position)
					if Distance > ESP.Config.MaxDistance then
						for _, Line in ipairs(Lines) do Line.Visible = false end
						return
					end
					local Transparency = CalculateTransparency(Distance)
					for _, Line in ipairs(Lines) do Line.Transparency = Transparency end
					local SizeX, SizeY, SizeZ = ESPSize.X / 2, ESPSize.Y / 2, ESPSize.Z / 2
					local Top1, Top2 = WTVP2D((Pivot * CFrame.new(-SizeX, SizeY, -SizeZ)).Position),
						WTVP2D((Pivot * CFrame.new(-SizeX, SizeY, SizeZ)).Position)
					local Top3, Top4 = WTVP2D((Pivot * CFrame.new(SizeX, SizeY, SizeZ)).Position),
						WTVP2D((Pivot * CFrame.new(SizeX, SizeY, -SizeZ)).Position)
					local Bottom1, Bottom2 = WTVP2D((Pivot * CFrame.new(-SizeX, -SizeY, -SizeZ)).Position),
						WTVP2D((Pivot * CFrame.new(-SizeX, -SizeY, SizeZ)).Position)
					local Bottom3, Bottom4 = WTVP2D((Pivot * CFrame.new(SizeX, -SizeY, SizeZ)).Position),
						WTVP2D((Pivot * CFrame.new(SizeX, -SizeY, -SizeZ)).Position)
					Lines[1].From, Lines[1].To = Top1, Top2
					Lines[2].From, Lines[2].To = Top2, Top3
					Lines[3].From, Lines[3].To = Top3, Top4
					Lines[4].From, Lines[4].To = Top4, Top1
					Lines[5].From, Lines[5].To = Bottom1, Bottom2
					Lines[6].From, Lines[6].To = Bottom2, Bottom3
					Lines[7].From, Lines[7].To = Bottom3, Bottom4
					Lines[8].From, Lines[8].To = Bottom4, Bottom1
					Lines[9].From, Lines[9].To = Bottom1, Top1
					Lines[10].From, Lines[10].To = Bottom2, Top2
					Lines[11].From, Lines[11].To = Bottom3, Top3
					Lines[12].From, Lines[12].To = Bottom4, Top4
					local BoxColor = GetColor(Box.Root.Parent, Box)
					for _, Line in ipairs(Lines) do Line.Color = BoxColor end
				end
			end
			function DrawingObject:Remove() for _, Line in ipairs(Lines) do Line:Remove() end end
			return DrawingObject
		end

		function Box:Update()
			if self.Destroyed then return end
			if not EnsureInstance(self.Root) then
				if self.BoxType == "3DFull" then
					local lines = self.DrawingObject and self.DrawingObject.Drawing
					if lines then
						for _, line in ipairs(lines) do line.Visible = false end
					end
				else
					local drawing = self.DrawingObject and self.DrawingObject.Drawing
					if drawing then drawing.Visible = false end
				end
				if self.TextObject then self.TextObject.Visible = false end
				return
			end
			local Enabled = ESP.Config.Enabled and ESP.Config.Players
			local Visible = Enabled

			if self.BoxType == "3DFull" then
				for _, Line in ipairs(self.DrawingObject.Drawing) do Line.Visible = Visible end
			else
				self.DrawingObject.Drawing.Visible = Visible
			end
			if self.TextObject then self.TextObject.Visible = Visible end
			if not Visible then return end

			if ESP.Config.Text then
				if not self.TextObject then
					self.TextObject = Drawing.new("Text")
					self.TextObject.Size = 16
					self.TextObject.Text = (ESP.Config.UseDisplayName and self.Player.DisplayName)
						or self.Player.Name
						or "Unknown"
					self.TextObject.Center = true
					self.TextObject.Outline = true
				end
				self.TextObject.Color = ESP.Config.TextColor
				local TextPosition = self.Root.Position + Vector3.new(0, 5, 0)
				local ScreenPos, OnScreen = WTVP(TextPosition)
				local Distance = Distance(self.Root.Position)
				self.TextObject.Visible = Distance <= ESP.Config.MaxDistance and OnScreen and ScreenPos.Z > 0
				if self.TextObject.Visible then
					self.TextObject.Transparency = CalculateTransparency(Distance)
					self.TextObject.Size = math.max(16 / Distance * 100, 13)
					self.TextObject.Position = Vector2.new(ScreenPos.X, ScreenPos.Y)
					self.TextObject.Font = ESP.Config.Font
				end
			elseif self.TextObject then
				Cleanup(self.TextObject)
				self.TextObject = nil
			end

			if self.BoxType ~= ESP.Config.BoxType then
				Cleanup(self.DrawingObject)
				self.BoxType = ESP.Config.BoxType
				if Box.BoxType == "2D" then
					Box.DrawingObject = Create2DBox()
				elseif Box.BoxType == "3D" then
					Box.DrawingObject = CreateBox3D()
				elseif Box.BoxType == "3DFull" then
					Box.DrawingObject = CreateBox3DFull()
				else
					error("Invalid BoxType")
				end
			end
			if self.BoxType ~= "3DFull" then self.DrawingObject.Drawing.Color = GetColor(self.Root.Parent, self) end
			self.DrawingObject.Update()
		end

		function Box:Destroy()
			if self.Destroyed then return end
			self.Destroyed = true
			Cleanup(self.TextObject)
			self.TextObject = nil
			Cleanup(self.DrawingObject)
		end

		if Box.BoxType == "2D" then
			Box.DrawingObject = Create2DBox()
		elseif Box.BoxType == "3D" then
			Box.DrawingObject = CreateBox3D()
		elseif Box.BoxType == "3DFull" then
			Box.DrawingObject = CreateBox3DFull()
		else
			error("Invalid BoxType")
		end
		return Box
	end

	local function CreateHighlight(HighlightInstance: Highlight, Player: Player, Character: Model)
		local HighlightObject = { Highlight = HighlightInstance, Player = Player, Character = Character, Destroyed = false }
		function HighlightObject:Update()
			if self.Destroyed or not EnsureInstance(self.Highlight) then return end
			local TeamCheckFail = ESP.Config.TeamCheck and self.Player.Team == LocalPlayer.Team
			self.Highlight.Enabled = ESP.Config.Enabled and ESP.Config.Highlights and not TeamCheckFail
			if self.Highlight.Enabled then
				local TransparencyMultiplier = CalculateTransparency(Distance(self.Character:GetPivot().Position))
				self.Highlight.Adornee = self.Character
				self.Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				self.Highlight.FillColor = ESP.Config.HighlightFillColor
				self.Highlight.OutlineColor = ESP.Config.HighlightOutlineColor
				self.Highlight.FillTransparency = ESP.Config.HighlightFillTransparency + (1 - TransparencyMultiplier)
				self.Highlight.OutlineTransparency = ESP.Config.HighlightOutlineTransparency + (1 - TransparencyMultiplier)
			end
		end
		function HighlightObject:Destroy()
			if self.Destroyed then return end
			self.Destroyed = true
			Cleanup(self.Highlight)
		end
		return HighlightObject
	end

	local function CreateTracer(TargetPart: Part)
		local TracerObject = { Line = Drawing.new("Line"), TargetPart = TargetPart, Destroyed = false }
		function TracerObject:Update()
			if self.Destroyed then return end
			local Enabled = ESP.Config.Enabled and ESP.Config.Tracers
			self.Line.Visible = Enabled
			if not Enabled then return end
			local LocalCharacter = LocalPlayer.Character
			local OriginPart = LocalCharacter and LocalCharacter:FindFirstChild("HumanoidRootPart")
			if not (OriginPart and EnsureInstance(OriginPart) and self.TargetPart and EnsureInstance(self.TargetPart)) then
				self.Line.Visible = false
				return
			end
			local TargetPosition = self.TargetPart.Position
			local OriginPosition = OriginPart.Position
			local Distance = (TargetPosition - Camera.CFrame.Position).Magnitude
			local ScreenPos, OnScreen = WTVP(TargetPosition)
			self.Line.Visible = Distance <= ESP.Config.MaxDistance and OnScreen and ScreenPos.Z > 0
			if self.Line.Visible then
				self.Line.Transparency = CalculateTransparency(Distance * 2)
				self.Line.Thickness = math.clamp(5 - Distance / 100, 1, 5)
				self.Line.Color = ESP.Config.TracerColor
				self.Line.From = WTVP2D(OriginPosition)
				self.Line.To = WTVP2D(TargetPosition)
			end
		end
		function TracerObject:Destroy()
			if self.Destroyed then return end
			self.Destroyed = true
			Cleanup(self.Line)
		end
		return TracerObject
	end

	local function Update()
		for _, Player in ipairs(Players:GetPlayers()) do
			if Player == LocalPlayer then continue end

			local Character = Player.Character
			local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
			if not (RootPart and EnsureInstance(RootPart)) then
				CleanupPlayerVisuals(Player)
				continue
			end

			local Visuals = ESP.Storage.PlayerVisuals[Player]

			if not Visuals or Visuals.Character ~= Character then
				CleanupPlayerVisuals(Player)

				Character.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
				local HighlightInstance = Character:FindFirstChildWhichIsA("Highlight")
					or Instance.new("Highlight", Character)

				local Config = {
					IsPlayer = true,
					Player = Player,
					DynamicColor = function(Model: Model)
						local Humanoid = Model:FindFirstChildOfClass("Humanoid")
						if Humanoid then
							if Model:FindFirstChild("ForceField") then return Color3.fromRGB(15, 207, 255) end
							return Color3.fromHSV(0.333 * (Humanoid.Health / Humanoid.MaxHealth), 1, 1)
						end
						return Color3.new(1, 0, 0)
					end,
				}

				Visuals = {
					Box = CreateBox(RootPart, Config),
					HighlightObject = CreateHighlight(HighlightInstance, Player, Character),
					TracerObject = CreateTracer(RootPart),
					Character = Character,
				}
				ESP.Storage.PlayerVisuals[Player] = Visuals
			end

			if Visuals then
				pcall(Visuals.Box.Update, Visuals.Box)
				pcall(Visuals.HighlightObject.Update, Visuals.HighlightObject)
				pcall(Visuals.TracerObject.Update, Visuals.TracerObject)
				Visuals.isValid = true
			end
		end

		for Player, Visuals in pairs(ESP.Storage.PlayerVisuals) do
			if Visuals.isValid then
				Visuals.isValid = false
			else
				CleanupPlayerVisuals(Player)
			end
		end
	end

	ESP.Config.Enabled = false
	ESP.Config.Players = false
	ESP.Config.Boxes = false

	Connections[#Connections + 1] = RunService.RenderStepped:Connect(Update)
	ESP.Unload = Unload
	return ESP
end)()