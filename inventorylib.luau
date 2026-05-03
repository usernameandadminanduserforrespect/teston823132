local Debugging = true
local DebugFileName = "esp2_debug.txt"

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
	local game = game
	local workspace = workspace
	local pcall = pcall
	local typeof = typeof
	local ipairs = ipairs
	local pairs = pairs
	local next = next
	local Vector2 = Vector2
	local Vector3 = Vector3
	local Color3 = Color3
	local CFrame = CFrame
	local math = math
	local Enum = Enum
	local Instance = Instance
	local Drawing = Drawing
 	local string = string

	local debugWriteFile = type(writefile) == "function" and writefile or nil
	local debugAppendFile = type(appendfile) == "function" and appendfile or nil
	local debugReadFile = type(readfile) == "function" and readfile or nil
	local debugDeleteFile = type(delfile) == "function" and delfile or nil

	if Debugging then
		if debugDeleteFile then
			pcall(debugDeleteFile, DebugFileName)
		elseif debugWriteFile then
			pcall(debugWriteFile, DebugFileName, "")
		end
	end

	local function logDebug(...)
		if not Debugging then return end
		if not (debugAppendFile or debugWriteFile) then return end
		local argCount = select("#", ...)
		if argCount == 0 then return end
		local parts = {}
		for index = 1, argCount do
			parts[index] = tostring(select(index, ...))
		end
		local timestamp
		if type(time) == "function" then
			timestamp = string.format("[%0.3f] ", time())
		elseif type(os) == "table" and type(os.clock) == "function" then
			timestamp = string.format("[%0.3f] ", os.clock())
		else
			timestamp = ""
		end
		local line = timestamp .. table.concat(parts, " ") .. "\n"
		if debugAppendFile then
			pcall(debugAppendFile, DebugFileName, line)
		elseif debugWriteFile then
			local existing = ""
			if debugReadFile then
				local ok, content = pcall(debugReadFile, DebugFileName)
				if ok and type(content) == "string" then
					existing = content
				end
			end
			pcall(debugWriteFile, DebugFileName, existing .. line)
		end
	end

	local RunService = game:GetService("RunService")
	local Players = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")

	type QuadDrawing = {
		Visible: boolean,
		Color: Color3,
		Transparency: number,
		PointA: Vector2,
		PointB: Vector2,
		PointC: Vector2,
		PointD: Vector2,
		Remove: (QuadDrawing) -> (),
	}

	type LineDrawing = {
		Visible: boolean,
		Color: Color3,
		Transparency: number,
		Thickness: number,
		From: Vector2,
		To: Vector2,
		Remove: (LineDrawing) -> (),
	}

	type TextDrawing = {
		Visible: boolean,
		Color: Color3,
		Transparency: number,
		Text: string,
		Position: Vector2,
		Size: number,
		Center: boolean,
		Outline: boolean,
		Font: number,
		Remove: (TextDrawing) -> (),
	}

	type HighlightInstance = Highlight

	type DrawingRecord = {
		key: string,
		kind: string,
		object: QuadDrawing | LineDrawing | TextDrawing,
		player: Player?,
		character: Model?,
		root: BasePart?,
		metadata: any,
	}

	type PlayerKeySet = { [string]: true }

	type HighlightRecord = {
		player: Player,
		character: Model,
		highlight: HighlightInstance,
	}

	type BoxFacade = {
		Keys: { string },
		Destroy: (BoxFacade) -> (),
		Destroyed: boolean,
	}

	type HighlightFacade = {
		Instance: HighlightInstance?,
		Destroy: (HighlightFacade) -> (),
		Destroyed: boolean,
	}

	type TracerFacade = {
		Key: string?,
		Destroy: (TracerFacade) -> (),
		Destroyed: boolean,
	}

	type PlayerVisualEntry = {
		Character: Model,
		Root: BasePart,
		Box: BoxFacade?,
		HighlightObject: HighlightFacade?,
		TracerObject: TracerFacade?,
	}

	type CustomHandle = {
		Id: number,
		Destroy: (CustomHandle) -> (),
		Destroyed: boolean,
	}

	type CustomEntry = {
		Id: number,
		Update: (number) -> (),
		Validate: ((number) -> boolean)?,
		Cleanup: ((CustomHandle?) -> ())?,
		Handle: CustomHandle?,
	}

	local LocalPlayer = Players.LocalPlayer
	local Camera = workspace.CurrentCamera

	local Connections = {} :: { RBXScriptConnection }

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
			BoxCornerSize = 0.25,
			BoxColor = Color3.fromRGB(255, 255, 255),
			TextColor = Color3.fromRGB(255, 255, 255),
			Font = 0,
			TextOffsetMultiplier = 0.6,
			LineThickness = 2,
			TracerColor = Color3.fromRGB(255, 255, 255),
			HighlightFillColor = Color3.fromRGB(255, 145, 20),
			HighlightOutlineColor = Color3.fromRGB(255, 0, 0),
			HighlightFillTransparency = 0.9,
			HighlightOutlineTransparency = 0.5,
			UseTeamColor = false,
			MaxDistance = 500,
			FadeDistance = 100,
			ZIndexEnabled = true,
			ZIndexNear = 200,
			ZIndexFar = 20,
			ZIndexClampMin = 0,
			ZIndexClampMax = 500,
			Spotlight = false,
			SpotlightFadeStart = 0.15,
			SpotlightFadeLength = 0.35,
		},
		Storage = {
			PlayerVisuals = {} :: { [Player]: PlayerVisualEntry },
		},
	}

	local DrawingTypeList = { "Line", "Text", "Image", "Circle", "Square", "Triangle", "Quad" }
	if type(table.freeze) == "function" then
		DrawingTypeList = table.freeze(DrawingTypeList)
	end

	local CustomEntries: { [number]: CustomEntry } = {}
	local NextCustomEntryId = 0

	ESP.Drawings = {
		Types = DrawingTypeList,
		New = function(kind: string)
			assert(type(kind) == "string", "ESP.Drawings.New expects a drawing type string.")
			local ok, object = pcall(Drawing.new, kind)
			if not ok then
				error(string.format("Failed to create drawing '%s': %s", kind, tostring(object)))
			end
			return object
		end,
	}

	for _, drawingType in ipairs(DrawingTypeList) do
		ESP.Drawings[drawingType] = function()
			return ESP.Drawings.New(drawingType)
		end
	end

	local DrawingStore: { [string]: DrawingRecord } = {}
	local PlayerKeyIndex: { [Player]: PlayerKeySet } = {}
	local HighlightStore: { [Player]: HighlightRecord } = {}

	local function tokenForPlayer(player: Player): string
		local userId = player.UserId
		if userId ~= 0 then
			return tostring(userId)
		end
		return player.Name
	end

	local function makeKey(player: Player, segment: string, index: number?): string
		if index ~= nil then
			return tokenForPlayer(player) .. ":" .. segment .. ":" .. tostring(index)
		end
		return tokenForPlayer(player) .. ":" .. segment
	end

	local function ensureKeyIndex(player: Player)
		if not PlayerKeyIndex[player] then
			PlayerKeyIndex[player] = {}
		end
	end

	local function registerKey(player: Player, key: string)
		ensureKeyIndex(player)
		PlayerKeyIndex[player][key] = true
	end

	local function unregisterKey(player: Player, key: string)
		local keySet = PlayerKeyIndex[player]
		if not keySet then return end
		keySet[key] = nil
		if next(keySet) == nil then
			PlayerKeyIndex[player] = nil
		end
	end

	local function Cleanup(item: any, context: string?)
		if not item then return end
		local ok, err = pcall(function()
			if typeof(item) == "RBXScriptConnection" then
				item:Disconnect()
				return
			end
			if type(item) == "table" then
				if type(item.Visible) == "boolean" then
					local success = pcall(function()
						item.Visible = false
					end)
					if not success and Debugging then
						logDebug("cleanupVisibleError", context or "<nil>")
					end
				end
			end
			if typeof(item) == "RBXScriptConnection" then
				return
			end
			local destroyMethod = item.Destroy
			if typeof(item) == "Instance" then
				(item :: Instance):Destroy()
				return
			elseif type(destroyMethod) == "function" then
				destroyMethod(item)
				return
			end
			local removeMethod = item.Remove
			if type(removeMethod) == "function" then
				removeMethod(item)
			end
		end)
		if not ok and Debugging then
			logDebug("cleanupError", context or "<nil>", tostring(err))
		end
	end

	ESP.CleanupItem = Cleanup

	local function cleanupDrawingKey(key: string)
		local record = DrawingStore[key]
		if not record then return end
		local player = record.player
		Cleanup(record.object, key)
		DrawingStore[key] = nil
		if player then
			unregisterKey(player, key)
		end
		logDebug("cleanupDrawing", key, record.kind)
	end

	local function cleanupHighlight(player: Player)
		local record = HighlightStore[player]
		if not record then return end
		Cleanup(record.highlight, "highlight:" .. tokenForPlayer(player))
		HighlightStore[player] = nil
		logDebug("cleanupHighlight", tokenForPlayer(player))
	end

	local function cleanupPlayer(player: Player)
		local keySet = PlayerKeyIndex[player]
		if keySet then
			for key in pairs(keySet) do
				cleanupDrawingKey(key)
			end
			PlayerKeyIndex[player] = nil
		end
		cleanupHighlight(player)
		ESP.Storage.PlayerVisuals[player] = nil
		logDebug("cleanupPlayerStorage", tokenForPlayer(player))
	end

	local function removeCustomEntry(id: number, reason: string?)
		local entry = CustomEntries[id]
		if not entry then return end
		CustomEntries[id] = nil
		local handle = entry.Handle
		if handle then
			handle.Destroyed = true
		end
		if entry.Cleanup then
			local ok, err = pcall(entry.Cleanup, handle)
			if not ok and Debugging then
				logDebug("customCleanupError", tostring(id), tostring(err))
			end
		end
		if Debugging then
			logDebug("customEntryRemoved", tostring(id), reason or "none")
		end
		entry.Handle = nil
	end

	local function cleanupAllCustomEntries()
		local ids = {}
		for id in pairs(CustomEntries) do
			ids[#ids + 1] = id
		end
		for _, id in ipairs(ids) do
			removeCustomEntry(id, "globalCleanup")
		end
	end

	local function processCustomEntries(deltaTime: number)
		local toRemove = {}
		for id, entry in pairs(CustomEntries) do
			local keep = true
			local okUpdate, updateError = pcall(entry.Update, deltaTime)
			if not okUpdate then
				keep = false
				if Debugging then
					logDebug("customUpdateError", tostring(id), tostring(updateError))
				end
			end
			if keep and entry.Validate then
				local okValidate, result = pcall(entry.Validate, deltaTime)
				if not okValidate then
					keep = false
					if Debugging then
						logDebug("customValidateError", tostring(id), tostring(result))
					end
				elseif result == false then
					keep = false
					if Debugging then
						logDebug("customValidatorFalse", tostring(id))
					end
				end
			end
			if not keep then
				toRemove[#toRemove + 1] = id
			end
		end
		for _, id in ipairs(toRemove) do
			removeCustomEntry(id, "validator")
		end
	end

	local function EnsureInstance(instance: Instance?): boolean
		if instance == nil then
			return false
		end
		if instance.Parent == nil then
			return false
		end
		return instance:IsDescendantOf(workspace)
	end

	local function Distance(position: Vector3): number
		local currentCamera = Camera
		if not currentCamera then
			return math.huge
		end
		return (position - currentCamera.CFrame.Position).Magnitude
	end

	local function WTVP(position: Vector3): (Vector3, boolean)
		local currentCamera = Camera
		if not currentCamera then
			return Vector3.zero, false
		end
		return currentCamera:WorldToViewportPoint(position)
	end

	local function CalculateTransparency(distance: number): number
		local maxDistance = ESP.Config.MaxDistance
		local fadeDistance = ESP.Config.FadeDistance

		if distance >= maxDistance then
			return 0
		elseif distance > (maxDistance - fadeDistance) then
			return 1 - (distance - (maxDistance - fadeDistance)) / fadeDistance
		end
		return 1
	end

	local function getMouseLocation(): Vector2?
		if not UserInputService then
			return nil
		end
		local ok, location = pcall(UserInputService.GetMouseLocation, UserInputService)
		if not ok then
			return nil
		end
		if typeof(location) ~= "Vector2" then
			return nil
		end
		return location
	end

	local function blendTransparency(baseTransparency: number, normalized: number): number
		local clampedBase = math.clamp(baseTransparency, 0, 1)
		local clampedNormalized = math.clamp(normalized, 0, 1)
		if clampedNormalized <= 0 then
			return clampedBase
		end
		return math.clamp(clampedBase * (1 - clampedNormalized), 0, 1)
	end

	local function normalizePercentage(value: number?): number?
		if value == nil then
			return nil
		end
		if value > 1 then
			return value * 0.01
		end
		return value
	end

	local function applySpotlight(baseTransparency: number, referencePosition: Vector2?, mousePosition: Vector2?): number
		if not ESP.Config.Spotlight then
			return baseTransparency
		end
		if not referencePosition then
			return baseTransparency
		end
		mousePosition = mousePosition or getMouseLocation()
		if not mousePosition then
			return baseTransparency
		end
		local currentCamera = Camera or workspace.CurrentCamera
		if not currentCamera then
			return baseTransparency
		end
		local viewportSize = currentCamera.ViewportSize
		if typeof(viewportSize) ~= "Vector2" then
			return baseTransparency
		end
		local diagonal = math.sqrt(viewportSize.X * viewportSize.X + viewportSize.Y * viewportSize.Y)
		if diagonal <= 0 then
			return baseTransparency
		end
		local fadeStartValue = normalizePercentage(tonumber(ESP.Config.SpotlightFadeStart)) or 0
		local fadeLengthValue = normalizePercentage(tonumber(ESP.Config.SpotlightFadeLength)) or 0
		fadeStartValue = math.clamp(fadeStartValue, 0, 1)
		fadeLengthValue = math.clamp(fadeLengthValue, 0, 1)
		local distancePercent = (referencePosition - mousePosition).Magnitude / diagonal
		if distancePercent <= fadeStartValue then
			return baseTransparency
		end
		if fadeLengthValue == 0 then
			return blendTransparency(baseTransparency, 1)
		end
		local normalized = math.clamp((distancePercent - fadeStartValue) / fadeLengthValue, 0, 1)
		return blendTransparency(baseTransparency, normalized)
	end

	local function resolveZIndexOverride(source: any): number?
		if source and type(source) == "table" then
			local override = source.ZIndex
			if type(override) == "number" then
				return override
			end
		end
		return nil
	end

	local function resolveZIndexOffset(source: any): number
		if source and type(source) == "table" then
			local offset = source.ZIndexOffset
			if type(offset) == "number" then
				return offset
			end
		end
		return 0
	end

	local function clampZIndex(value: number): number
		local clampMin = ESP.Config.ZIndexClampMin
		local clampMax = ESP.Config.ZIndexClampMax
		if type(clampMin) ~= "number" then
			clampMin = ESP.Config.ZIndexFar
		end
		if type(clampMax) ~= "number" then
			clampMax = ESP.Config.ZIndexNear
		end
		local lower = math.min(clampMin, clampMax)
		local upper = math.max(clampMin, clampMax)
		return math.clamp(value, lower, upper)
	end

	local function computeZIndex(distance: number?, params: any, metadata: any): number?
		local override = resolveZIndexOverride(params) or resolveZIndexOverride(metadata)
		if override ~= nil then
			return math.floor(override + 0.5)
		end
		if not ESP.Config.ZIndexEnabled then
			return nil
		end
		distance = distance or ESP.Config.MaxDistance
		if distance < 0 or distance ~= distance then
			distance = 0
		end
		local maxDistance = math.max(ESP.Config.MaxDistance, 1)
		local normalized = math.clamp(distance / maxDistance, 0, 1)
		local nearValue = ESP.Config.ZIndexNear
		local farValue = ESP.Config.ZIndexFar
		local baseValue = nearValue + (farValue - nearValue) * normalized
		local offset = resolveZIndexOffset(metadata) + resolveZIndexOffset(params)
		local finalValue = clampZIndex(baseValue + offset)
		return math.floor(finalValue + 0.5)
	end

	local zIndexSupported: boolean? = nil
	local CurrentMouseLocation: Vector2? = nil

	local function applyZIndex(drawing: any, zIndex: number?)
		if zIndex == nil then
			return
		end
		if zIndexSupported == false then
			return
		end
		local ok, err = pcall(function()
			drawing.ZIndex = zIndex
		end)
		if not ok then
			zIndexSupported = false
			if Debugging then
				logDebug("zIndexUnsupported", tostring(err))
			end
		elseif zIndexSupported == nil then
			zIndexSupported = true
		end
	end

	type BoxUpdateParams = {
		Pivot: CFrame,
		Size: Vector3,
		Distance: number?,
		Color: Color3?,
		Enabled: boolean?,
		Transparency: number?,
		StaticSize: Vector2?,
		Channel: string?,
		ZIndex: number?,
		ZIndexOffset: number?,
	}

	type BoxLineUpdateParams = {
		Pivot: CFrame,
		Size: Vector3,
		Distance: number?,
		Color: Color3?,
		Enabled: boolean?,
		Transparency: number?,
		Index: number,
		Channel: string?,
		ZIndex: number?,
		ZIndexOffset: number?,
		Thickness: number?,
	}

	type TextUpdateParams = {
		Text: string?,
		Color: Color3?,
		Position: Vector3?,
		ScreenPosition: Vector2?,
		Distance: number?,
		Enabled: boolean?,
		Font: number?,
		Size: number?,
		VerticalOffsetMultiplier: number?,
		Channel: string?,
		ZIndex: number?,
		ZIndexOffset: number?,
		Transparency: number?,
	}

	type TracerUpdateParams = {
		FromWorld: Vector3?,
		ToWorld: Vector3,
		Thickness: number?,
		Color: Color3?,
		Enabled: boolean?,
		Distance: number?,
		Channel: string?,
		ZIndex: number?,
		ZIndexOffset: number?,
		Transparency: number?,
	}

	type BoxCornerUpdateParams = BoxUpdateParams & {
		CornerSize: number?,
		Thickness: number?,
	}

	local function createQuadDrawing(): QuadDrawing
		local quad = (Drawing.new("Quad") :: any) :: QuadDrawing
		quad.Visible = false
		return quad
	end

	local function createLineDrawing(defaultThickness: number): LineDrawing
		local line = (Drawing.new("Line") :: any) :: LineDrawing
		line.Visible = false
		line.Thickness = defaultThickness
		return line
	end

	local function createTextDrawing(): TextDrawing
		local text = (Drawing.new("Text") :: any) :: TextDrawing
		text.Visible = false
		text.Center = true
		text.Outline = true
		text.Text = ""
		return text
	end

	local function resolveEnabled(flag: boolean?, defaultValue: boolean): boolean
		if flag == nil then
			return defaultValue
		end
		return flag
	end

	local function resolveChannel(params: any, metadata: any): string
		if params and type(params) == "table" then
			local channel = params.Channel
			if channel ~= nil then
				return channel
			end
		end
		if metadata and type(metadata) == "table" then
			local channel = metadata.Channel
			if channel ~= nil then
				return channel
			end
		end
		return "Custom"
	end

	local function updateQuadDrawing(quad: QuadDrawing, mode: "2D" | "3D", params: BoxUpdateParams, metadata: any)
		local channel = resolveChannel(params, metadata)
		local baseEnabled
		if channel == "PlayerBox" then
			baseEnabled = ESP.Config.Enabled and ESP.Config.Players and ESP.Config.Boxes
		else
			baseEnabled = ESP.Config.Enabled
		end
		local enabled = resolveEnabled(params.Enabled, baseEnabled)
		if not enabled then
			quad.Visible = false
			return false
		end

		local pivot = params.Pivot
		if not pivot then
			quad.Visible = false
			return false
		end

		local camera = Camera
		if not camera then
			quad.Visible = false
			return false
		end

		local size = params.Size or ESP.Config.BoxSize
		local distance = params.Distance or Distance(pivot.Position)
		local color = params.Color or ESP.Config.BoxColor
		if distance > ESP.Config.MaxDistance then
			quad.Visible = false
			return false
		end

		if mode == "2D" then
			local screenPos, onScreen = WTVP(pivot.Position)
			if not (onScreen and screenPos.Z > 0) then
				quad.Visible = false
				return false
			end
			local sizeConfig = params.StaticSize or ESP.Config.StaticSize
			local fieldOfView = camera.FieldOfView
			local scaledSize = sizeConfig / (math.max(distance, 1) / 100) * (fieldOfView / 70)
			quad.PointA = Vector2.new(screenPos.X - scaledSize.X / 2, screenPos.Y - scaledSize.Y / 2)
			quad.PointB = Vector2.new(screenPos.X + scaledSize.X / 2, screenPos.Y - scaledSize.Y / 2)
			quad.PointC = Vector2.new(screenPos.X + scaledSize.X / 2, screenPos.Y + scaledSize.Y / 2)
			quad.PointD = Vector2.new(screenPos.X - scaledSize.X / 2, screenPos.Y + scaledSize.Y / 2)
			quad.Color = color
			local screenPoint = Vector2.new(screenPos.X, screenPos.Y)
			local baseTransparency = params.Transparency
			if baseTransparency == nil then
				baseTransparency = CalculateTransparency(distance)
			end
			quad.Transparency = applySpotlight(baseTransparency, screenPoint, CurrentMouseLocation)
			applyZIndex(quad, computeZIndex(distance, params, metadata))
			quad.Visible = true
			return true
		else
			local halfSize = size / 2
			local corners = {
				pivot * CFrame.new(halfSize.X, halfSize.Y, 0),
				pivot * CFrame.new(-halfSize.X, halfSize.Y, 0),
				pivot * CFrame.new(-halfSize.X, -halfSize.Y, 0),
				pivot * CFrame.new(halfSize.X, -halfSize.Y, 0),
			}
			local points: { Vector2 } = {}
			local sumX = 0
			local sumY = 0
			for index = 1, #corners do
				local screenPos, onScreen = WTVP((corners[index]).Position)
				if not (onScreen and screenPos.Z > 0) then
					quad.Visible = false
					return false
				end
				points[index] = Vector2.new(screenPos.X, screenPos.Y)
				sumX += screenPos.X
				sumY += screenPos.Y
			end
			quad.PointA = points[1]
			quad.PointB = points[2]
			quad.PointC = points[3]
			quad.PointD = points[4]
			quad.Color = color
			local baseTransparency = params.Transparency
			if baseTransparency == nil then
				baseTransparency = CalculateTransparency(distance)
			end
			local referencePoint: Vector2? = nil
			if #points > 0 then
				referencePoint = Vector2.new(sumX / #points, sumY / #points)
			end
			quad.Transparency = applySpotlight(baseTransparency, referencePoint, CurrentMouseLocation)
			applyZIndex(quad, computeZIndex(distance, params, metadata))
			quad.Visible = true
			return true
		end
	end

	local Box3DFullEdges = {
		{ 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 1 },
		{ 5, 6 }, { 6, 7 }, { 7, 8 }, { 8, 5 },
		{ 1, 5 }, { 2, 6 }, { 3, 7 }, { 4, 8 },
	}

	local Box2DCornerSegments = {
		{ CornerIndex = 1, Axis = "Horizontal" },
		{ CornerIndex = 1, Axis = "Vertical" },
		{ CornerIndex = 2, Axis = "Horizontal" },
		{ CornerIndex = 2, Axis = "Vertical" },
		{ CornerIndex = 3, Axis = "Horizontal" },
		{ CornerIndex = 3, Axis = "Vertical" },
		{ CornerIndex = 4, Axis = "Horizontal" },
		{ CornerIndex = 4, Axis = "Vertical" },
	}

	local CornerHorizontalDirections = {
		Vector2.new(1, 0),
		Vector2.new(-1, 0),
		Vector2.new(-1, 0),
		Vector2.new(1, 0),
	}

	local CornerVerticalDirections = {
		Vector2.new(0, 1),
		Vector2.new(0, 1),
		Vector2.new(0, -1),
		Vector2.new(0, -1),
	}

	local function updateLineBoxDrawing(line: LineDrawing, params: BoxLineUpdateParams, metadata: any)
		local channel = resolveChannel(params, metadata)
		local baseEnabled
		if channel == "PlayerBox" then
			baseEnabled = ESP.Config.Enabled and ESP.Config.Players and ESP.Config.Boxes
		else
			baseEnabled = ESP.Config.Enabled
		end
		local enabled = resolveEnabled(params.Enabled, baseEnabled)
		if not enabled then
			line.Visible = false
			return false
		end

		local pivot = params.Pivot
		local size = params.Size or ESP.Config.BoxSize
		local index = params.Index
		if not pivot or not size or not index then
			line.Visible = false
			return false
		end

		local camera = Camera
		if not camera then
			line.Visible = false
			return false
		end

		local distance = params.Distance or Distance(pivot.Position)
		if distance > ESP.Config.MaxDistance then
			line.Visible = false
			return false
		end

		local edge = Box3DFullEdges[index]
		if not edge then
			line.Visible = false
			return false
		end

		local halfSize = size / 2
		local cornerOffsets = {
			Vector3.new(-halfSize.X, halfSize.Y, -halfSize.Z),
			Vector3.new(-halfSize.X, halfSize.Y, halfSize.Z),
			Vector3.new(halfSize.X, halfSize.Y, halfSize.Z),
			Vector3.new(halfSize.X, halfSize.Y, -halfSize.Z),
			Vector3.new(-halfSize.X, -halfSize.Y, -halfSize.Z),
			Vector3.new(-halfSize.X, -halfSize.Y, halfSize.Z),
			Vector3.new(halfSize.X, -halfSize.Y, halfSize.Z),
			Vector3.new(halfSize.X, -halfSize.Y, -halfSize.Z),
		}
		local startOffset = cornerOffsets[edge[1]]
		local endOffset = cornerOffsets[edge[2]]
		local startWorld = (pivot * CFrame.new(startOffset)).Position
		local endWorld = (pivot * CFrame.new(endOffset)).Position
		local startScreen, startOnScreen = WTVP(startWorld)
		local endScreen, endOnScreen = WTVP(endWorld)
		if not (startOnScreen and endOnScreen and startScreen.Z > 0 and endScreen.Z > 0) then
			line.Visible = false
			return false
		end
		local startPoint = Vector2.new(startScreen.X, startScreen.Y)
		local endPoint = Vector2.new(endScreen.X, endScreen.Y)
		line.From = startPoint
		line.To = endPoint
		line.Color = params.Color or ESP.Config.BoxColor
		local baseTransparency = params.Transparency
		if baseTransparency == nil then
			baseTransparency = CalculateTransparency(distance)
		end
		local midpoint = Vector2.new((startPoint.X + endPoint.X) * 0.5, (startPoint.Y + endPoint.Y) * 0.5)
		line.Transparency = applySpotlight(baseTransparency, midpoint, CurrentMouseLocation)
		local thickness = params.Thickness
		if thickness == nil then
			thickness = ESP.Config.LineThickness
		end
		thickness = tonumber(thickness) or 1
		if thickness < 0 then
			thickness = 0
		end
		line.Thickness = thickness
		applyZIndex(line, computeZIndex(distance, params, metadata))
		line.Visible = true
		return true
	end

	local function updateCornerSegmentDrawing(line: LineDrawing, params: BoxCornerUpdateParams, metadata: any)
		local channel = resolveChannel(params, metadata)
		local baseEnabled
		if channel == "PlayerBox" then
			baseEnabled = ESP.Config.Enabled and ESP.Config.Players and ESP.Config.Boxes
		else
			baseEnabled = ESP.Config.Enabled
		end
		local enabled = resolveEnabled(params.Enabled, baseEnabled)
		if not enabled then
			line.Visible = false
			return false
		end

		local pivot = params.Pivot
		if not pivot then
			line.Visible = false
			return false
		end

		local camera = Camera
		if not camera then
			line.Visible = false
			return false
		end

		local distance = params.Distance or Distance(pivot.Position)
		if distance > ESP.Config.MaxDistance then
			line.Visible = false
			return false
		end

		local screenPos, onScreen = WTVP(pivot.Position)
		if not (onScreen and screenPos.Z > 0) then
			line.Visible = false
			return false
		end

		local sizeConfig = params.StaticSize or ESP.Config.StaticSize
		local fieldOfView = camera.FieldOfView
		local scaledSize = sizeConfig / (math.max(distance, 1) / 100) * (fieldOfView / 70)
		local halfWidth = scaledSize.X * 0.5
		local halfHeight = scaledSize.Y * 0.5

		local corners = {
			Vector2.new(screenPos.X - halfWidth, screenPos.Y - halfHeight),
			Vector2.new(screenPos.X + halfWidth, screenPos.Y - halfHeight),
			Vector2.new(screenPos.X + halfWidth, screenPos.Y + halfHeight),
			Vector2.new(screenPos.X - halfWidth, screenPos.Y + halfHeight),
		}

		local cornerIndex = metadata and metadata.CornerIndex
		if type(cornerIndex) ~= "number" then
			line.Visible = false
			return false
		end

		local baseCorner = corners[cornerIndex]
		if not baseCorner then
			line.Visible = false
			return false
		end

		local axis = metadata and metadata.Axis
		local direction: Vector2? = nil
		if axis == "Horizontal" then
			direction = CornerHorizontalDirections[cornerIndex]
		elseif axis == "Vertical" then
			direction = CornerVerticalDirections[cornerIndex]
		end

		if not direction then
			line.Visible = false
			return false
		end

		local rawCornerSize = params.CornerSize
		if rawCornerSize == nil and metadata and metadata.CornerSize ~= nil then
			rawCornerSize = metadata.CornerSize
		end
		if rawCornerSize == nil then
			rawCornerSize = ESP.Config.BoxCornerSize
		end
		local cornerPercent = tonumber(rawCornerSize) or 0
		cornerPercent = normalizePercentage(cornerPercent) or cornerPercent
		cornerPercent = math.clamp(cornerPercent, 0, 1)
		if cornerPercent <= 0 then
			line.Visible = false
			return false
		end

		local topWidth = (corners[2] - corners[1]).Magnitude
		local bottomWidth = (corners[3] - corners[4]).Magnitude
		local leftHeight = (corners[4] - corners[1]).Magnitude
		local rightHeight = (corners[3] - corners[2]).Magnitude

		local edgeLength: number
		if axis == "Horizontal" then
			if cornerIndex == 1 or cornerIndex == 2 then
				edgeLength = topWidth
			else
				edgeLength = bottomWidth
			end
		else
			if cornerIndex == 1 or cornerIndex == 4 then
				edgeLength = leftHeight
			else
				edgeLength = rightHeight
			end
		end
		if not edgeLength or edgeLength <= 0 then
			line.Visible = false
			return false
		end

		local segmentLength = edgeLength * cornerPercent
		if segmentLength <= 0 then
			line.Visible = false
			return false
		end

		local endPoint = baseCorner + direction * segmentLength
		line.From = baseCorner
		line.To = endPoint
		line.Color = params.Color or ESP.Config.BoxColor
		local baseTransparency = params.Transparency
		if baseTransparency == nil then
			baseTransparency = CalculateTransparency(distance)
		end
		local midpoint = Vector2.new((baseCorner.X + endPoint.X) * 0.5, (baseCorner.Y + endPoint.Y) * 0.5)
		line.Transparency = applySpotlight(baseTransparency, midpoint, CurrentMouseLocation)
		local thickness = params.Thickness
		if thickness == nil then
			thickness = ESP.Config.LineThickness
		end
		thickness = tonumber(thickness) or 1
		if thickness < 0 then
			thickness = 0
		end
		line.Thickness = thickness
		applyZIndex(line, computeZIndex(distance, params, metadata))
		line.Visible = true
		return true
	end

	local function updateTextDrawing(text: TextDrawing, params: TextUpdateParams, metadata: any)
		local channel = resolveChannel(params, metadata)
		local baseEnabled
		if channel == "PlayerText" then
			baseEnabled = ESP.Config.Enabled and ESP.Config.Players and ESP.Config.Text
		else
			baseEnabled = ESP.Config.Enabled
		end
		local enabled = resolveEnabled(params.Enabled, baseEnabled)
		if not enabled then
			text.Visible = false
			return false
		end
		local position3D = params.Position
		local screenPos = params.ScreenPosition
		local distance = params.Distance
		if not screenPos then
			if not position3D then
				text.Visible = false
				return false
			end
			local rawScreen, onScreen = WTVP(position3D)
			if not (onScreen and rawScreen.Z > 0) then
				text.Visible = false
				return false
			end
			screenPos = Vector2.new(rawScreen.X, rawScreen.Y)
			distance = distance or Distance(position3D)
		else
			distance = distance or 0
		end
		text.Text = params.Text or text.Text
		text.Color = params.Color or ESP.Config.TextColor
		text.Font = params.Font or ESP.Config.Font
		local computedSize = params.Size or math.max(16 / math.max(distance, 1) * 100, 13)
		text.Size = computedSize
		local offsetMultiplier = params.VerticalOffsetMultiplier
		if offsetMultiplier == nil and type(metadata) == "table" then
			offsetMultiplier = metadata.VerticalOffsetMultiplier
		end
		if offsetMultiplier == nil then
			offsetMultiplier = ESP.Config.TextOffsetMultiplier
		end
		offsetMultiplier = tonumber(offsetMultiplier) or 0
		local normalizedOffset = normalizePercentage(offsetMultiplier)
		if normalizedOffset ~= nil then
			offsetMultiplier = normalizedOffset
		end
		offsetMultiplier = math.max(offsetMultiplier, 0)
		if offsetMultiplier > 0 then
			local offsetPixels = computedSize * offsetMultiplier
			screenPos = Vector2.new(screenPos.X, screenPos.Y - offsetPixels)
		end
		text.Position = screenPos
		local baseTransparency = params.Transparency
		if baseTransparency == nil then
			baseTransparency = CalculateTransparency(distance)
		end
		text.Transparency = applySpotlight(baseTransparency, screenPos, CurrentMouseLocation)
		applyZIndex(text, computeZIndex(distance, params, metadata))
		text.Visible = true
		return true
	end

	local function updateTracerDrawing(line: LineDrawing, params: TracerUpdateParams, metadata: any)
		local channel = resolveChannel(params, metadata)
		local baseEnabled
		if channel == "PlayerTracer" then
			baseEnabled = ESP.Config.Enabled and ESP.Config.Tracers
		else
			baseEnabled = ESP.Config.Enabled
		end
		local enabled = resolveEnabled(params.Enabled, baseEnabled)
		if not enabled then
			line.Visible = false
			return false
		end
		local fromWorld = params.FromWorld
		if not fromWorld then
			local localCharacter = LocalPlayer and LocalPlayer.Character or nil
			local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
			if not (localRoot and localRoot:IsA("BasePart") and EnsureInstance(localRoot)) then
				line.Visible = false
				return false
			end
			fromWorld = (localRoot :: BasePart).Position
		end
		local targetWorld = params.ToWorld
		local distance = params.Distance or Distance(targetWorld)
		local startScreen, onScreenStart = WTVP(fromWorld)
		local endScreen, onScreenEnd = WTVP(targetWorld)
		if not (onScreenEnd and endScreen.Z > 0 and onScreenStart and startScreen.Z > 0) then
			line.Visible = false
			return false
		end
		line.From = Vector2.new(startScreen.X, startScreen.Y)
		line.To = Vector2.new(endScreen.X, endScreen.Y)
		local baseTransparency = params.Transparency
		if baseTransparency == nil then
			baseTransparency = CalculateTransparency(distance * 0.5)
		end
		local referencePoint = Vector2.new(endScreen.X, endScreen.Y)
		line.Transparency = applySpotlight(baseTransparency, referencePoint, CurrentMouseLocation)
		line.Thickness = params.Thickness or math.clamp(5 - distance / 100, 1, 5)
		line.Color = params.Color or ESP.Config.TracerColor
		applyZIndex(line, computeZIndex(distance, params, metadata))
		line.Visible = true
		return true
	end

	local DrawingFactory = {
		Box2D = {
			Create = function(_: any)
				return createQuadDrawing()
			end,
			Update = function(object: QuadDrawing, params: BoxUpdateParams, metadata: any)
				return updateQuadDrawing(object, "2D", params, metadata)
			end,
		},
		Box2DCorners = {
			Create = function(_: any)
				return createLineDrawing(1)
			end,
			Update = function(object: LineDrawing, params: BoxCornerUpdateParams, metadata: any)
				return updateCornerSegmentDrawing(object, params, metadata)
			end,
		},
		Box3D = {
			Create = function(_: any)
				return createQuadDrawing()
			end,
			Update = function(object: QuadDrawing, params: BoxUpdateParams, metadata: any)
				return updateQuadDrawing(object, "3D", params, metadata)
			end,
		},
		Box3DFull = {
			Create = function(_: any)
				return createLineDrawing(1)
			end,
			Update = function(object: LineDrawing, params: BoxLineUpdateParams, metadata: any)
				return updateLineBoxDrawing(object, params, metadata)
			end,
		},
		Text = {
			Create = function(_: any)
				return createTextDrawing()
			end,
			Update = function(object: TextDrawing, params: TextUpdateParams, metadata: any)
				return updateTextDrawing(object, params, metadata)
			end,
		},
		Tracer = {
			Create = function(_: any)
				return createLineDrawing(2)
			end,
			Update = function(object: LineDrawing, params: TracerUpdateParams, metadata: any)
				return updateTracerDrawing(object, params, metadata)
			end,
		},
	}

	ESP.Drawings.Factory = DrawingFactory

	local function registerUseShortcut(kind: string)
		local functionName = "Use" .. kind
		ESP.Drawings[functionName] = function(metadata: any?)
			return ESP.Drawings.Acquire(kind, metadata)
		end
	end

	local function refreshDrawingKinds()
		local kinds = {}
		for kind in pairs(DrawingFactory) do
			kinds[#kinds + 1] = kind
		end
		table.sort(kinds)
		if type(table.freeze) == "function" then
			kinds = table.freeze(kinds)
		end
		ESP.Drawings.Kinds = kinds
		for _, kind in ipairs(kinds) do
			registerUseShortcut(kind)
		end
	end

	refreshDrawingKinds()

	function ESP.Drawings.RegisterType(name: string, definition: { Create: (any) -> any, Update: (any, any, any?) -> boolean })
		assert(type(name) == "string" and name ~= "", "ESP.Drawings.RegisterType requires a name")
		assert(type(definition) == "table", "Definition must be a table")
		assert(type(definition.Create) == "function", "Definition.Create must be a function")
		assert(type(definition.Update) == "function", "Definition.Update must be a function")
		DrawingFactory[name] = definition
		refreshDrawingKinds()
		if Debugging then
			logDebug("drawingTypeRegistered", name)
		end
	end

	function ESP.Drawings.Acquire(kind: string, metadata: any?)
		local definition = DrawingFactory[kind]
		assert(definition, string.format("Unknown drawing kind '%s'", tostring(kind)))
		local object = definition.Create(metadata)
		local destroyed = false
		return {
			Kind = kind,
			Object = object,
			Destroyed = false,
			Update = function(self, params: any)
				if destroyed then return false end
				return definition.Update(object, params, metadata)
			end,
			Destroy = function(self)
				if destroyed then return end
				destroyed = true
				self.Destroyed = true
				Cleanup(object)
			end,
		}
	end

	function ESP.Drawings.Create3DBox()
		local segmentHandles = {}
		for index = 1, #Box3DFullEdges do
			segmentHandles[index] = ESP.Drawings.Acquire("Box3DFull", { Index = index, Channel = "Custom" })
		end
		local destroyed = false
		return {
			Handles = segmentHandles,
			Destroyed = false,
			Update = function(self, params: BoxLineUpdateParams)
				if destroyed then return false end
				local enabled = params.Enabled
				local updated = false
				if enabled == false then
					for _, handle in ipairs(segmentHandles) do
						if not handle.Destroyed then
							handle:Update({ Enabled = false, Channel = params.Channel, ZIndex = params.ZIndex })
							updated = true
						end
					end
					return updated
				end
				local channel = params.Channel
				for index, handle in ipairs(segmentHandles) do
					if not handle.Destroyed then
						handle:Update({
							Pivot = params.Pivot,
							Size = params.Size,
							Distance = params.Distance,
							Color = params.Color,
							Enabled = params.Enabled,
							Transparency = params.Transparency,
							Index = index,
							Channel = channel,
							ZIndex = params.ZIndex,
							ZIndexOffset = params.ZIndexOffset,
							Thickness = params.Thickness,
						})
						updated = true
					end
				end
				return updated
			end,
			Destroy = function(self)
				if destroyed then return end
				destroyed = true
				self.Destroyed = true
				for _, handle in ipairs(segmentHandles) do
					handle:Destroy()
				end
			end,
		}
	end

	local function getBoxColor(model: Model, player: Player): Color3
		if ESP.Config.UseTeamColor and player.TeamColor then
			return player.TeamColor.Color
		end
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if humanoid then
			if model:FindFirstChild("ForceField") then
				return Color3.fromRGB(15, 207, 255)
			end
			local maxHealth = humanoid.MaxHealth
			if maxHealth > 0 then
				return Color3.fromHSV(0.333 * (humanoid.Health / maxHealth), 1, 1)
			end
		end
		return ESP.Config.BoxColor
	end

	local function ensureHighlightRecord(player: Player, character: Model): HighlightRecord
		local existing = HighlightStore[player]
		if existing then
			existing.character = character
			return existing
		end
		local highlight = character:FindFirstChildWhichIsA("Highlight") :: HighlightInstance?
		if not highlight then
			highlight = (Instance.new("Highlight") :: any) :: HighlightInstance
			highlight.Adornee = character
			highlight.Parent = character
		end
		local record: HighlightRecord = {
			player = player,
			character = character,
			highlight = highlight,
		}
		HighlightStore[player] = record
		logDebug("createHighlight", tokenForPlayer(player))
		return record
	end

	local function ensureDrawingRecord(player: Player?, key: string, kind: string, character: Model?, root: BasePart?, metadata: any): DrawingRecord
		local existing = DrawingStore[key]
		if existing then
			existing.player = player
			existing.character = character
			existing.root = root
			if metadata ~= nil then
				existing.metadata = metadata
			end
			return existing
		end
		local definition = DrawingFactory[kind]
		assert(definition, string.format("Unknown drawing kind '%s'", tostring(kind)))
		local object = definition.Create(metadata)
		local record: DrawingRecord = {
			key = key,
			kind = kind,
			object = object,
			player = player,
			character = character,
			root = root,
			metadata = metadata,
		}
		DrawingStore[key] = record
		if player then
			registerKey(player, key)
		end
		if Debugging then
			logDebug("createDrawing", key, kind)
		end
		return record
	end

	local function buildBoxFacade(player: Player, boxType: string, baseKey: string): BoxFacade
		local keys: { string } = {}
		if boxType == "3DFull" then
			for index = 1, #Box3DFullEdges do
				keys[index] = makeKey(player, baseKey, index)
			end
		elseif boxType == "2DCorners" then
			for index = 1, #Box2DCornerSegments do
				keys[index] = makeKey(player, baseKey, index)
			end
		else
			keys[1] = makeKey(player, baseKey)
		end
		local destroyed = false
		return {
			Keys = keys,
			Destroyed = false,
			Destroy = function(self: BoxFacade)
				if destroyed then return end
				destroyed = true
				self.Destroyed = true
				for _, key in ipairs(keys) do
					cleanupDrawingKey(key)
				end
			end,
		}
	end

	local function buildHighlightFacade(player: Player): HighlightFacade
		local destroyed = false
		return {
			Instance = HighlightStore[player] and HighlightStore[player].highlight or nil,
			Destroyed = false,
			Destroy = function(self: HighlightFacade)
				if destroyed then return end
				destroyed = true
				self.Destroyed = true
				cleanupHighlight(player)
				self.Instance = nil
			end,
		}
	end

	local function buildTracerFacade(player: Player, key: string): TracerFacade
		local destroyed = false
		return {
			Key = key,
			Destroyed = false,
			Destroy = function(self: TracerFacade)
				if destroyed then return end
				destroyed = true
				self.Destroyed = true
				if self.Key then
					cleanupDrawingKey(self.Key)
					self.Key = nil
				end
			end,
		}
	end

	local function updateHighlight(record: HighlightRecord, character: Model, player: Player, distance: number)
		local highlight = record.highlight
		local enabled = ESP.Config.Enabled and ESP.Config.Highlights
		if ESP.Config.TeamCheck then
			local localPlayer = LocalPlayer
			if localPlayer then
				local localTeam = localPlayer.Team
				local playerTeam = player.Team
				if localTeam ~= nil and playerTeam ~= nil and playerTeam == localTeam then
					enabled = false
				end
			end
		end
		highlight.Enabled = enabled
		if not enabled then return end
		highlight.Adornee = character
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.FillColor = ESP.Config.HighlightFillColor
		highlight.OutlineColor = ESP.Config.HighlightOutlineColor
		local multiplier = CalculateTransparency(distance)
		highlight.FillTransparency = math.clamp(ESP.Config.HighlightFillTransparency + (1 - multiplier), 0, 1)
		highlight.OutlineTransparency = math.clamp(ESP.Config.HighlightOutlineTransparency + (1 - multiplier), 0, 1)
	end

	local function processPlayer(player: Player, desiredKeys: { [string]: true }, desiredHighlightPlayers: { [Player]: true }, desiredPlayerSet: { [Player]: true })
		local character = player.Character
		if not character then
			return
		end
		local rootInstance = character:FindFirstChild("HumanoidRootPart")
		if not (rootInstance and rootInstance:IsA("BasePart") and EnsureInstance(rootInstance)) then
			return
		end
		local root = rootInstance :: BasePart

		local pivotCFrame: CFrame
		local success, result = pcall(function(): CFrame
			return character:GetPivot()
		end)
		if success then
			pivotCFrame = result
		else
			pivotCFrame = root.CFrame
		end

		local distance = Distance(pivotCFrame.Position)
		local color = getBoxColor(character, player)
		local baseKey = "Box"
		local keepVisual = false
		local boxFacade: BoxFacade? = nil
		local highlightFacade: HighlightFacade? = nil
		local tracerFacade: TracerFacade? = nil

		local boxType = ESP.Config.BoxType
		if ESP.Config.Enabled and ESP.Config.Players and ESP.Config.Boxes then
			keepVisual = true
			if boxType == "3DFull" then
				for index = 1, #Box3DFullEdges do
					local key = makeKey(player, baseKey, index)
					desiredKeys[key] = true
					local metadata = { Index = index, Channel = "PlayerBox", ZIndexOffset = 0 }
					local record = ensureDrawingRecord(player, key, "Box3DFull", character, root, metadata)
					DrawingFactory.Box3DFull.Update((record.object :: any) :: LineDrawing, {
						Pivot = pivotCFrame,
						Size = ESP.Config.BoxSize,
						Distance = distance,
						Color = color,
						Index = index,
						ZIndexOffset = 0,
						Thickness = ESP.Config.LineThickness,
					}, record.metadata)
				end
			elseif boxType == "2DCorners" then
				for index, segment in ipairs(Box2DCornerSegments) do
					local key = makeKey(player, baseKey, index)
					desiredKeys[key] = true
					local metadata = {
						CornerIndex = segment.CornerIndex,
						Axis = segment.Axis,
						Channel = "PlayerBox",
						ZIndexOffset = 0,
					}
					local record = ensureDrawingRecord(player, key, "Box2DCorners", character, root, metadata)
					DrawingFactory.Box2DCorners.Update((record.object :: any) :: LineDrawing, {
						Pivot = pivotCFrame,
						Size = ESP.Config.BoxSize,
						Distance = distance,
						Color = color,
						CornerSize = ESP.Config.BoxCornerSize,
						ZIndexOffset = 0,
						Thickness = ESP.Config.LineThickness,
					}, record.metadata)
				end
			else
				local kind = boxType == "2D" and "Box2D" or "Box3D"
				local key = makeKey(player, baseKey)
				desiredKeys[key] = true
				local record = ensureDrawingRecord(player, key, kind, character, root, { Channel = "PlayerBox", ZIndexOffset = 0 })
				local definition = DrawingFactory[kind]
				if definition then
					definition.Update((record.object :: any) :: QuadDrawing, {
						Pivot = pivotCFrame,
						Size = ESP.Config.BoxSize,
						Distance = distance,
						Color = color,
						ZIndexOffset = 0,
					}, record.metadata)
				end
			end
			boxFacade = buildBoxFacade(player, boxType, baseKey)
		end

		if ESP.Config.Enabled and ESP.Config.Players and ESP.Config.Text then
			keepVisual = true
			local key = makeKey(player, "Text")
			desiredKeys[key] = true
			local textRecord = ensureDrawingRecord(player, key, "Text", character, root, { Channel = "PlayerText", ZIndexOffset = 5 })
			DrawingFactory.Text.Update((textRecord.object :: any) :: TextDrawing, {
				Text = (ESP.Config.UseDisplayName and player.DisplayName) or player.Name or "Unknown",
				Position = root.Position + Vector3.new(0, 5, 0),
				Distance = distance,
				ZIndexOffset = 5,
			}, textRecord.metadata)
		end

		if ESP.Config.Enabled and ESP.Config.Tracers then
			keepVisual = true
			local tracerKey = makeKey(player, "Tracer")
			desiredKeys[tracerKey] = true
			local tracerRecord = ensureDrawingRecord(player, tracerKey, "Tracer", character, root, { Channel = "PlayerTracer", ZIndexOffset = -5 })
			DrawingFactory.Tracer.Update((tracerRecord.object :: any) :: LineDrawing, {
				ToWorld = root.Position,
				Distance = distance,
				ZIndexOffset = -5,
			}, tracerRecord.metadata)
			tracerFacade = buildTracerFacade(player, tracerKey)
		end

		if ESP.Config.Enabled and ESP.Config.Highlights then
			keepVisual = true
			desiredHighlightPlayers[player] = true
			local highlightRecord = ensureHighlightRecord(player, character)
			updateHighlight(highlightRecord, character, player, distance)
			highlightFacade = buildHighlightFacade(player)
		end

		if keepVisual then
			desiredPlayerSet[player] = true
			local existing = ESP.Storage.PlayerVisuals[player]
			if existing and existing.Character == character then
				existing.Root = root
				existing.Box = boxFacade
				existing.HighlightObject = highlightFacade
				existing.TracerObject = tracerFacade
			else
				ESP.Storage.PlayerVisuals[player] = {
					Character = character,
					Root = root,
					Box = boxFacade,
					HighlightObject = highlightFacade,
					TracerObject = tracerFacade,
				}
			end
		end
	end

	local function update(deltaTime: number)
		LocalPlayer = Players.LocalPlayer or LocalPlayer
		local desiredKeys: { [string]: true } = {}
		local desiredHighlightPlayers: { [Player]: true } = {}
		local desiredPlayerSet: { [Player]: true } = {}

		if ESP.Config.Spotlight then
			CurrentMouseLocation = getMouseLocation()
		else
			CurrentMouseLocation = nil
		end

		if not ESP.Config.Enabled then
			for key in pairs(DrawingStore) do
				cleanupDrawingKey(key)
			end
			for player in pairs(HighlightStore) do
				cleanupHighlight(player)
			end
			local playersToCleanup = {} :: { Player }
			for player in pairs(ESP.Storage.PlayerVisuals) do
				playersToCleanup[#playersToCleanup + 1] = player
			end
			for _, player in ipairs(playersToCleanup) do
				cleanupPlayer(player)
			end
			cleanupAllCustomEntries()
			return
		end

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				processPlayer(player, desiredKeys, desiredHighlightPlayers, desiredPlayerSet)
			end
		end

		for key in pairs(DrawingStore) do
			if not desiredKeys[key] then
				cleanupDrawingKey(key)
			end
		end

		for player, record in pairs(HighlightStore) do
			if not desiredHighlightPlayers[player] or not EnsureInstance(record.character) then
				cleanupHighlight(player)
			end
		end

		local playersToRemove = {} :: { Player }
		for player in pairs(ESP.Storage.PlayerVisuals) do
			if not desiredPlayerSet[player] then
				playersToRemove[#playersToRemove + 1] = player
			end
		end
		for _, player in ipairs(playersToRemove) do
			cleanupPlayer(player)
		end
		processCustomEntries(deltaTime or 0)
	end

	Connections[#Connections + 1] = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		Camera = workspace.CurrentCamera
	end)

	Connections[#Connections + 1] = Players.PlayerRemoving:Connect(function(player: Player)
		cleanupPlayer(player)
	end)

	Connections[#Connections + 1] = RunService.RenderStepped:Connect(update)

	function ESP.Unload()
		for _, connection in ipairs(Connections) do
			Cleanup(connection)
		end
		Connections = {} :: { RBXScriptConnection }
		for key in pairs(DrawingStore) do
			cleanupDrawingKey(key)
		end
		for player in pairs(HighlightStore) do
			cleanupHighlight(player)
		end
		local playersToCleanup = {} :: { Player }
		for player in pairs(ESP.Storage.PlayerVisuals) do
			playersToCleanup[#playersToCleanup + 1] = player
		end
		for _, player in ipairs(playersToCleanup) do
			cleanupPlayer(player)
		end
		cleanupAllCustomEntries()
	end

	function ESP.Register(updateFn: (number) -> (), validatorFn: ((number) -> boolean)?, cleanupFn: ((CustomHandle?) -> ())?)
		assert(type(updateFn) == "function", "ESP.Register requires an update function.")
		if validatorFn ~= nil then
			assert(type(validatorFn) == "function", "ESP.Register validator must be a function or nil.")
		end
		if cleanupFn ~= nil then
			assert(type(cleanupFn) == "function", "ESP.Register cleanup must be a function or nil.")
		end
		NextCustomEntryId += 1
		local id = NextCustomEntryId
		local entry: CustomEntry = {
			Id = id,
			Update = updateFn,
			Validate = validatorFn,
			Cleanup = cleanupFn,
			Handle = nil,
		}
		local handle: CustomHandle = {
			Id = id,
			Destroyed = false,
			Destroy = function(self: CustomHandle)
				if self.Destroyed then return end
				removeCustomEntry(id, "manual")
			end,
		}
		entry.Handle = handle
		CustomEntries[id] = entry
		if Debugging then
			logDebug("customEntryRegistered", tostring(id))
		end
		return handle
	end

	ESP.Config.Enabled = false
	ESP.Config.Players = false
	ESP.Config.Boxes = false

	return ESP
end)()
