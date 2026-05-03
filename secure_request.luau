--!native

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

	local PathfindingService = game:GetService("PathfindingService")
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer
	local TweenService = game:GetService("TweenService")
	local Debris = game:GetService("Debris")
	local Camera = workspace.CurrentCamera

	type MarkerObject = {
		Object: Part,
		Destroy: (self: MarkerObject) -> (),
		SetColor: (self: MarkerObject, Color: Color3) -> (),
		SetPosition: (self: MarkerObject, Position: Vector3) -> (),
	}

	local PathModule = {
		Visualization = true,
		RefreshRate = 1/30,
		CurrentTarget = nil,
		Storage = {
			Temporary = {},
		}
	}

	local function Marker(Position : Vector3, Index : number?) : MarkerObject
		local Marker = Instance.new("Part")
		Marker.Size = Vector3.new(.5, .5, .5)
		Marker.Material = Enum.Material.Neon
		Marker.Color = Color3.fromRGB(255, 0, 0)
		Marker.Anchored = true
		Marker.CanCollide = false
		Marker.CanQuery = false
		Marker.CFrame = CFrame.new(Position)
		Marker.Parent = Camera
		Marker.Shape = Enum.PartType.Ball
		Marker.Name = `PathModuleMarker{Index or "nan"}`
		return {
			Object = Marker,
			Destroy = function(self)
				if self.Object then
					TweenService:Create(self.Object, TweenInfo.new(1), {Transparency = 1, Size = Vector3.zero}):Play()
					Debris:AddItem(self.Object, 1)
				end
			end,
			SetColor = function(self, Color : Color3)
				self.Object.Color = Color
			end,
			SetPosition = function(self, Position : Vector3)
				self.Object.CFrame = CFrame.new(Position)
			end,
		}
	end

	local function PV2V3(PV : PVInstance | Vector3) : Vector3
		if typeof(PV) == "Vector3" then
			return PV
		elseif typeof(PV) == "Instance" and PV:IsA("PVInstance") then
			return PV:GetPivot().Position
		else
			error(`Invalid type "{typeof(PV)}" for PV2V3`)
		end
	end

	local function PV2CF(PV : PVInstance | Vector3) : CFrame
		if typeof(PV) == "Vector3" then
			return CFrame.new(PV)
		elseif typeof(PV) == "Instance" and PV:IsA("PVInstance") then
			return PV:GetPivot()
		else
			error(`Invalid type "{typeof(PV)}" for PV2CF`)
		end
	end

	local function FixDoors()
		for _, Descendant in workspace:GetDescendants() do
			if (string.find(string.lower(Descendant.Name), "door")) then
				local modifier = Instance.new("PathfindingModifier", Descendant); do
					modifier.Label = "Door";
					modifier.PassThrough = true
				end
			end
		end
	end

	local function GetHumanoid() : Humanoid
		local Character = LocalPlayer.Character
		if not Character then repeat task.wait() until LocalPlayer.Character; Character = LocalPlayer.Character end
		local Humanoid = Character:FindFirstChildOfClass("Humanoid")
		if not Humanoid then repeat task.wait() until Character:FindFirstChildOfClass("Humanoid"); Humanoid = Character:FindFirstChildOfClass("Humanoid") end
		return Humanoid
	end

	local function CreatePathWrapper(path: Path)
		local wrapper = {}
		setmetatable(wrapper, {__index = path})

		function wrapper:GetWaypoints()
			local originalWaypoints = path:GetWaypoints()
			local modifiedWaypoints = {}
			for i, waypoint in ipairs(originalWaypoints) do
				local pos = waypoint.Position
				if pos.Y < 251 then
					pos = Vector3.new(pos.X, 251, pos.Z)
				end
				modifiedWaypoints[i] = {
					Position = pos,
					Action = waypoint.Action,
					Label = waypoint.Label,
				}
			end
			return modifiedWaypoints
		end

		return wrapper
	end

	local function GetPath(Origin : Vector3 | PVInstance, Target : Vector3 | PVInstance) : Path?

		Origin = PV2V3(Origin)
		Target = PV2V3(Target)

		assert(typeof(Origin) == "Vector3", "Origin must be a Vector3") -- i hate this
		assert(typeof(Target) == "Vector3", "Target must be a Vector3") -- so much

		local Path = PathfindingService:CreatePath({
			AgentRadius = math.ceil(2 * (GetHumanoid():FindFirstChild("BodyWidthScale") :: NumberValue).Value),
			AgentHeight = math.ceil(5 * (GetHumanoid():FindFirstChild("BodyHeightScale") :: NumberValue).Value),
			AgentCanJump = true,
			AgentJumpHeight = 10,
			AgentMaxSlope = 70,
			Costs = {
				Water = 20,
				Door = 1
			}
		})

		-- Compute path

		Path:ComputeAsync(Origin, Target :: Vector3)

		-- Check if path is successful, if not check if it's a partial path and try creating a path from the last point

		if Path.Status == Enum.PathStatus.Success then
			return CreatePathWrapper(Path)
		elseif Path.Status == Enum.PathStatus.NoPath then
			warn("PathfindingService: No path found")
			return 
		else
			warn("Undefined pathfinding status: ", Path.Status)
			return
		end

	end

	local function GetPathH(Origin : Vector3 | PVInstance, Target : Vector3 | PVInstance) : Path?

		Origin = PV2V3(Origin)
		Target = PV2V3(Target)

		assert(typeof(Origin) == "Vector3", "Origin must be a Vector3") -- i hate this
		assert(typeof(Target) == "Vector3", "Target must be a Vector3") -- so much

		local Path = PathfindingService:CreatePath({
			AgentRadius = 2,
			AgentHeight = 5,
			AgentCanJump = false,
			AgentJumpHeight = 10,
			AgentMaxSlope = 70,
		})

		-- Compute path

		Path:ComputeAsync(Origin, Target :: Vector3)

		-- Check if path is successful, if not check if it's a partial path and try creating a path from the last point

		if Path.Status == Enum.PathStatus.Success then
			return CreatePathWrapper(Path)
		elseif Path.Status == Enum.PathStatus.NoPath then
			warn("PathfindingService: No path found")
			return 
		else
			warn("Undefined pathfinding status: ", Path.Status)
			return
		end

	end

	local function VisualizePath(Path : Path) : ({[PathWaypoint]: MarkerObject})?
		local PointMarkers = {}
		
		if PathModule.Visualization then
			local Points = Path:GetWaypoints()
			for i, Point in next, Points do
				local Marker = Marker(Point.Position, i)
				PointMarkers[Point] = Marker
			end
			return PointMarkers
		else
			warn("PathModule.Visualization is disabled")
			return nil
		end
	end

	local function MarkerFromWaypoint(PathMarkers : {[PathWaypoint]: MarkerObject}, Waypoint : PathWaypoint) : MarkerObject?
		for _, Marker in next, PathMarkers do
			if Marker.Object.Position == Waypoint.Position then
				return Marker
			end
		end
		return nil
	end

	local function TweenColor(Object : BasePart, Color : Color3, Duration : number)
		local Tween = TweenService:Create(Object, TweenInfo.new(Duration), {Color = Color})
		Tween:Play()
		return Tween
	end

	local function GetPathLength(Path : Path) : number
		local Length = 0
		local Points = Path:GetWaypoints()
		for i = 1, #Points - 1 do
			Length += (Points[i].Position - Points[i + 1].Position).Magnitude
		end
		return Length
	end

	local function GetTravelTime(Distance : number, Speed : number) : number
		return Distance / Speed
	end

	return {
		Marker = Marker,
		PV2V3 = PV2V3,
		PV2CF = PV2CF,
		GetPath = GetPath,
		VisualizePath = VisualizePath,
		TweenColor = TweenColor,
		PathModule = PathModule,
		GetPathLength = GetPathLength,
		GetTravelTime = GetTravelTime,
		MarkerFromWaypoint = MarkerFromWaypoint,
		GetPathH = GetPathH,
	}

end)()