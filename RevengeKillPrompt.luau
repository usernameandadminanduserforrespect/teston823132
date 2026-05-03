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

	local RarityColors = {
		["Common"] = Color3.fromRGB(255, 255, 255),
		["Uncommon"] = Color3.fromRGB(99, 255, 52),
		["Rare"] = Color3.fromRGB(51, 170, 255),
		["Epic"] = Color3.fromRGB(237, 44, 255),
		["Legendary"] = Color3.fromRGB(255, 150, 0),
		["Omega"] = Color3.fromRGB(255, 20, 51)
	}

	local InventoryLib = require("./inventorylib.luau")

	local Collection = {}

	local function Collect(Item: RBXScriptConnection | thread)
		table.insert(Collection, Item)
		return Item
	end

	local function Cleanup(Item: any)
		if typeof(Item) == "Instance" then
			Item:Destroy()
			return
		end
		if typeof(Item) == "RBXScriptConnection" then
			Item:Disconnect()
			return
		end
		if type(Item) == "thread" then
			coroutine.close(Item)
			return
		end
		if type(Item) == "table" then
			for Index, Value in pairs(Item) do
				Cleanup(Value)
			end
			table.clear(Item)
			return
		end
		pcall(function()
			Item:Remove()
			return
		end)
	end

	local function Unload()
		for _, Item in next, Collection do
			Cleanup(Item)
		end
	end

	local Players = game:GetService("Players")
	local CollectionService = game:GetService("CollectionService")
	local CoreGui = game:GetService("CoreGui")
	local AssetService = game:GetService("AssetService")
	local RunService = game:GetService("RunService")

	for _, Item in next, CoreGui:GetChildren() do
		if Item:IsA("Folder") and Item.Name == "ItemViewLib" then
			Item:Destroy()
		end
	end

	local Storage = Instance.new("Folder", CoreGui)
	Storage.Name = "ItemViewLib"

	local ItemViewLib = {
		ItemTags = {
			"Gun",
			"Melee",
			"PowerUp",
			"Throwable"
		},
		Views = {},
		Cache = {},
		Scale = 50,
		MaxDistance = 500,
		Enabled = false,
		Color = Color3.fromRGB(255, 255, 255),
	}

	local function NewContainer(): BillboardGui
		local Container = Instance.new("BillboardGui")
		Container.Size = UDim2.new(0, ItemViewLib.Scale * 3, 0, ItemViewLib.Scale * 2)
		Container.AlwaysOnTop = true
		Container.StudsOffsetWorldSpace = Vector3.new(0, -6, 0)
		Container.ResetOnSpawn = false
		Container.MaxDistance = ItemViewLib.MaxDistance
		Container.Enabled = ItemViewLib.Enabled

		local Grid = Instance.new("UIGridLayout")
		Grid.CellSize = UDim2.new(0, ItemViewLib.Scale, 0, ItemViewLib.Scale)
		Grid.CellPadding = UDim2.new(0, 0, 0, 0)
		Grid.FillDirection = Enum.FillDirection.Horizontal
		Grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
		Grid.VerticalAlignment = Enum.VerticalAlignment.Center
		Grid.SortOrder = Enum.SortOrder.LayoutOrder
		Grid.Parent = Container

		local Connection = nil
		Connection = Collect(RunService.RenderStepped:Connect(function()
			if not Container.Parent then
				Connection:Disconnect()
				return
			end
			if not Container.Adornee then
				Connection:Disconnect()
				return
			end

			Container.MaxDistance = ItemViewLib.MaxDistance
			Container.Enabled = ItemViewLib.Enabled

			if not Container.Adornee then
				return
			end

			local Camera = workspace.CurrentCamera
			local CurrentDistance = (Container.Adornee.Position - Camera.CFrame.Position).Magnitude

			local Scale = math.clamp(1 - CurrentDistance / Container.MaxDistance, 0.2, 1) * (70 / Camera.FieldOfView)
			Grid.CellSize = UDim2.new(0, ItemViewLib.Scale * Scale, 0, ItemViewLib.Scale * Scale)
			Container.Size = UDim2.new(0, ItemViewLib.Scale * Scale * 3, 0, ItemViewLib.Scale * Scale * 2)

			for _, Item in next, Container:GetChildren() do
				if Item:IsA("ImageLabel") then
					Item.ImageTransparency = 1 - Scale
					Item.ImageColor3 = ItemViewLib.Color
				end
			end
		end))

		return Container
	end

	local function NewItem(Item: Tool): ImageLabel
		local Type = nil
		local Priority = 0

		for i, Tag in next, ItemViewLib.ItemTags do
			if CollectionService:HasTag(Item, Tag) then
				Type = Tag
				Priority = i
				break
			end
		end
		assert(Type, `Item {Item} does not have a valid tag`)

		local ItemData = InventoryLib.ResolveDataFromHashedTool(Item)

		if not ItemData then
			error(`Failed to resolve data for item {Item}`)
		end
		if not ItemViewLib.Cache[ItemData.ImageId] then
			local EImage = nil
			local MaxRetries = 3
			local RetryCount = 0

			-- Retry loop for loading texture
			while RetryCount < MaxRetries do
				local Success, Result = pcall(function()
					return AssetService:CreateEditableImageAsync(ItemData.ImageId)
				end)

				if Success then
					EImage = Result
					break
				else
					RetryCount += 1
					warn(`Failed to load texture for {ItemData.ImageId}, attempt {RetryCount}/{MaxRetries}: {Result}`)

					if RetryCount < MaxRetries then
						task.wait(0.5) -- Wait before retrying
					end
				end
			end

			-- Fallback to red square if all retries failed
			if not EImage then
				warn(`All retries failed for {ItemData.ImageId}, using fallback red square`)
				EImage = AssetService:CreateEditableImage({ Size = Vector2.new(255, 255) })
				local FallbackData = buffer.create(255 * 255 * 4)
				for i = 0, 255 * 255 - 1 do
					buffer.writeu8(FallbackData, i * 4, 255) -- R
					buffer.writeu8(FallbackData, i * 4 + 1, 0) -- G
					buffer.writeu8(FallbackData, i * 4 + 2, 0) -- B
					buffer.writeu8(FallbackData, i * 4 + 3, 255) -- A
				end
				(EImage :: EditableImage):WritePixelsBuffer(Vector2.zero, EImage.Size, FallbackData)
			else
				-- Process the image with rarity colors
				local RarityColor = RarityColors[ItemData.Rarity] or Color3.fromRGB(255, 255, 255)

				local ImageData = EImage:ReadPixelsBuffer(Vector2.zero, EImage.Size)
				local ProcessedImageData = buffer.create(EImage.Size.X * EImage.Size.Y * 4)

				local Y = 0

				for i = 0, EImage.Size.X * EImage.Size.Y - 1 do
					Y = math.floor(i / EImage.Size.X)
					local offset = i * 4

					local A = buffer.readu8(ImageData, offset + 3)

					if A > 250 then
						-- Preserve original color for opaque pixels
						local R = buffer.readu8(ImageData, offset + 0)
						local G = buffer.readu8(ImageData, offset + 1)
						local B = buffer.readu8(ImageData, offset + 2)

						buffer.writeu8(ProcessedImageData, offset + 0, R)
						buffer.writeu8(ProcessedImageData, offset + 1, G)
						buffer.writeu8(ProcessedImageData, offset + 2, B)
						buffer.writeu8(ProcessedImageData, offset + 3, A)
					elseif A ~= 0 then -- Affect more of the semi-transparent area
						-- Apply gradient to outline (semi-transparent pixels)
						local Gradient = math.max(Y / EImage.Size.Y, 0.7) -- Brighter gradient
						local TintedR = 255 * RarityColor.R * Gradient
						local TintedG = 255 * RarityColor.G * Gradient
						local TintedB = 255 * RarityColor.B * Gradient

						buffer.writeu8(ProcessedImageData, offset + 0, TintedR)
						buffer.writeu8(ProcessedImageData, offset + 1, TintedG)
						buffer.writeu8(ProcessedImageData, offset + 2, TintedB)
						buffer.writeu8(ProcessedImageData, offset + 3, math.min(A * 5, 255)) -- Less transparent
					end
				end
				EImage:WritePixelsBuffer(Vector2.zero, EImage.Size, ProcessedImageData)
			end

			ItemViewLib.Cache[ItemData.ImageId] = EImage
		end

		local EImage = ItemViewLib.Cache[ItemData.ImageId]

		local ItemImage = Instance.new("ImageLabel")
		ItemImage.Size = UDim2.new(0, 255, 0, 255)
		ItemImage.BackgroundTransparency = 1
		ItemImage.LayoutOrder = Priority
		ItemImage.ImageContent = Content.fromObject(EImage)

		return ItemImage
	end

	local function ValidateTool(Item: Tool): boolean
		if (not Item) or (not Item.IsA) then
			return false
		end
		if not Item:IsA("Tool") then
			return false
		end
		if not Item:GetAttribute("ImageId") then
			return false
		end
		if not Item:FindFirstChildOfClass("MeshPart") then
			return false
		end
		local Valid = false
		for _, Tag in next, ItemViewLib.ItemTags do
			if CollectionService:HasTag(Item, Tag) then
				Valid = true
				break
			end
		end
		if not Valid then
			return false
		end
		return true
	end

	local function NewItemView(Player: Player): BillboardGui
		local Character = Player.Character or Player.CharacterAdded:Wait()
		local Container = NewContainer()
		local Backpack = Player:WaitForChild("Backpack")

		Container.Parent = Storage
		Container.Adornee = Character:WaitForChild("HumanoidRootPart")
		Container.Enabled = true
		Container.Name = Player.Name

		-- Populate function to sync views
		local function Populate()

			Backpack = Player:WaitForChild("Backpack")
			Character = Player.Character

			if not (Character and Backpack) then
				warn("Populate for cycle", Player, "skipped due to Character or Backpack being nil.")
				return
			end

			local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart", 3)

			if not HumanoidRootPart then
				return
			end

			Container.Adornee = HumanoidRootPart

			-- remove any stale views
			for Item, ItemImage in pairs(ItemViewLib.Views) do
				if ItemImage.Parent == Container then
					ItemImage:Destroy()
					ItemViewLib.Views[Item] = nil
				end
			end

			-- add any new tools
			for _, Tool in ipairs(Backpack:GetChildren()) do
				if ValidateTool(Tool) and not ItemViewLib.Views[Tool] then
					local ItemImage = NewItem(Tool)
					ItemImage.Parent = Container
					ItemViewLib.Views[Tool] = ItemImage
				end
			end
			
			for _, Tool in ipairs(Character:GetChildren()) do
				if ValidateTool(Tool) and not ItemViewLib.Views[Tool] then
					local ItemImage = NewItem(Tool)
					ItemImage.Parent = Container
					ItemViewLib.Views[Tool] = ItemImage
				end
			end
		end

		-- initial sync
		Populate()

		-- refresh loop routine
		local RefreshLoop = Collect(coroutine.create(function()
			while true do
				-- exit if container destroyed or player left
				if not Container.Parent then print("Container for", Player, "cancelled due to NoParent"); break end
				if not Player:IsDescendantOf(Players) then print("Container for", Player, "cancelled due to NotInPlayers"); break end
				Populate()
				task.wait(1.5)
			end
		end))
		coroutine.resume(RefreshLoop)

		return Container
	end

	function ItemViewLib:CreateItemView(Player: Player): BillboardGui
		return NewItemView(Player)
	end

	function ItemViewLib:DestroyItemView(Player: Player): nil
		local Container = Storage:FindFirstChild(Player.Name)
		if Container then
			Container:Destroy()
		end
		return nil
	end

	function ItemViewLib:DestroyAllItemViews(): nil
		for _, View in next, Storage:GetChildren() do
			if View:IsA("BillboardGui") then
				View:Destroy()
			end
		end
		return nil
	end

	function ItemViewLib:Init(): nil
		Collect(Players.PlayerAdded:Connect(function(Player)
			Player.CharacterAdded:Wait()
			self:CreateItemView(Player)
		end))

		for _, Player in next, Players:GetPlayers() do
			if Player == Players.LocalPlayer then
				continue
			end

			if Player.Character then
				task.spawn(function()
					self:CreateItemView(Player)
				end)
			end
		end

		return nil
	end

	function ItemViewLib:Unload(): nil
		Storage:Destroy()
		Unload()
		return nil
	end

	ItemViewLib.RarityColors = RarityColors

	return ItemViewLib

	-- ItemViewLib:Init()
end)()