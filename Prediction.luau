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
    local Modules = ReplicatedStorage:WaitForChild("Modules")
    local Core = Modules:WaitForChild("Core")
    local Data = require(Core:WaitForChild("Data") :: ModuleScript)

    local ToolHashes = {}
    local InventoryLib = {}

    function InventoryLib.ListInventory()
        local InventoryItems = {}
        
        -- Iterate through each item type (e.g., "car", "gun", "ammo")
        for ItemType, ItemsByType in pairs(Data.items or {}) do
            -- Iterate through each item name under the type
            for ItemName, Items in pairs(ItemsByType) do
                -- Iterate through each individual item entry
                for _, ItemData in ipairs(Items) do
                    table.insert(InventoryItems, {
                        Type = ItemType,
                        Name = ItemData.name,
                        Guid = ItemData.guid,
                        Location = ItemData.location or "hand", -- Default to 'hand' if not specified
                        Amount = ItemData.amount or 1,
                        Durability = ItemData.durability,
                        Health = ItemData.health,
                        Class = ItemData.class and ItemData.class.name or nil,
                        Destroyed = ItemData.destroyed,
                    })
                end
            end
        end
        
        return InventoryItems
    end

    function InventoryLib.GetItemsByType(ItemType)
        local ItemsByType = {}
        
        -- Iterate through each item type (e.g., "car", "gun", "ammo")
        for Type, Items in pairs(Data.items or {}) do
            if Type == ItemType then
                -- Iterate through each item name under the type
                for ItemName, ItemData in pairs(Items) do
                    ItemsByType[ItemName] = ItemData
                end
            end
        end
        
        return ItemsByType
    end

    function InventoryLib.GetItemsByName(ItemName)
        local ItemsByName = {}

        local InventoryItems = InventoryLib.ListInventory()

        -- Iterate through each item in the inventory
        for _, Item in ipairs(InventoryItems) do
            if Item.Name == ItemName then
                table.insert(ItemsByName, Item)
            end
        end

        return ItemsByName
    end

    function InventoryLib.FilterByLocation(InventoryItems, Location)
        local FilteredItems = {}
        
        for _, Item in ipairs(InventoryItems) do
            if Item.Location == Location then
                table.insert(FilteredItems, Item)
            end
        end
        
        return FilteredItems
    end

    -- Returns how many items each inventory can hold and how many are currently in use
    function InventoryLib.GetInventoryStats()
        local Data = require(Core.Data :: ModuleScript)
        local Net = require(Core.Net :: ModuleScript)

        local function GetItems()
            local counts = {
                hand = 0,
                safe = 0,
            }

            if Data.items then
                for _, itemsByType in Data.items do
                    for _, itemsByName in itemsByType do
                        for _, itemData in itemsByName do
                            if itemData and not itemData.destroyed then
                                local rawLocation = itemData.location
                                if typeof(rawLocation) ~= "string" or rawLocation == "" then
                                    continue
                                end

                                local location = string.lower(rawLocation)

                                if location == "safe" then
                                    counts.safe += 1
                                elseif location == "hand" then
                                    counts.hand += 1
                                end
                            end
                        end
                    end
                end
            end

            counts.hand = math.max(counts.hand, 0)
            counts.safe = math.max(counts.safe, 0)

            return counts
        end

        local Item_Limits = Net.get("get_max_inventory_space") or {} -- {hand = XX, safe = XX}
        local Current_Items = GetItems()

        local handMax = tonumber(Item_Limits.hand) or 0
        local safeMax = tonumber(Item_Limits.safe) or 0
        local handCurrent = math.max(0, math.floor(Current_Items.hand))
        local safeCurrent = math.max(0, math.floor(Current_Items.safe))

        return {
            hand = {
                current = handCurrent,
                max = handMax,
            },
            safe = {
                current = safeCurrent,
                max = safeMax,
            },
        }
    end

    function InventoryLib.GetMoney() : (number, number)
        local MoneyData = Data.money
        return MoneyData.hand or 0, MoneyData.bank or 0
    end

    function InventoryLib.GetMoneyT() : { Cash: number, Bank: number }
        local MoneyData = Data.money
        return {
            Cash = MoneyData.hand or 0,
            Bank = MoneyData.bank or 0
        }
    end

    local function GenerateToolHash(Tool : Tool)
        
        local AssetIds = {}

        for _, Descendant in next, Tool:GetDescendants() do
            if Descendant:IsA("MeshPart") then
                local MeshId = Descendant.MeshId
                if MeshId and MeshId ~= "" then
                    table.insert(AssetIds, MeshId)
                end

                if Descendant.TextureID and Descendant.TextureID ~= "" then
                    table.insert(AssetIds, Descendant.TextureID)
                end
                
                table.insert(AssetIds, Descendant.Material.Name)
            elseif Descendant:IsA("SpecialMesh") then
                local MeshId = Descendant.MeshId
                if MeshId and MeshId ~= "" then
                    table.insert(AssetIds, MeshId)
                end

                if Descendant.TextureId and Descendant.TextureId ~= "" then
                    table.insert(AssetIds, Descendant.TextureId)
                end
                
                if Descendant.Parent and Descendant.Parent:IsA("BasePart") then
                    table.insert(AssetIds, Descendant.Parent.Material.Name)
                end
            end
        end

        table.sort(AssetIds, function(a, b)
            if tonumber(a:match("%d+")) and tonumber(b:match("%d+")) then
                return tonumber(a:match("%d+")) < tonumber(b:match("%d+"))
            end
            return a < b
        end)

        local ConcatenatedIDs = table.concat(AssetIds, ",")

        local Hash = 0
        for i = 1, #ConcatenatedIDs do
            Hash = (Hash * 31 + ConcatenatedIDs:byte(i)) % 2 ^ 32
        end

        return Hash
    end

    function InventoryLib.ResolveDataFromHashedTool(Tool : Tool)

        local Hash = GenerateToolHash(Tool)
        local ToolReference = ToolHashes[Hash]

        local ValidCategories = {
            gun = true,
            melee = true,
            accessory = true,
            consumable = true,
            throwable = true
        }
        
        if not ToolReference then
            for _, ItemCategory in next, ReplicatedStorage.Items:GetChildren() do

                if not ValidCategories[ItemCategory.Name] then
                    continue
                end

                for _, Item in next, ItemCategory:GetChildren() do
                    local ToolHash = GenerateToolHash(Item)

                    ToolHashes[ToolHash] = Item

                    if ToolHash == Hash then
                        ToolReference = Item
                        break
                    end
                end
            end
        end

        if ToolReference then
            return {
                Name = ToolReference.Name,
                Description = ToolReference:GetAttribute("Description"),
                Rarity = ToolReference:GetAttribute("RarityName"),
                ImageId = ToolReference:GetAttribute("ImageId"),
                Price = ToolReference:GetAttribute("RarityPrice"),
            }
        end

        return nil
    end

    function InventoryLib.GetItemsFromCategory(Category : string)
        local Items = {}
        local CategoryFolder = ReplicatedStorage.Items:FindFirstChild(Category)
        if CategoryFolder then
            for _, Item in next, CategoryFolder:GetChildren() do
                table.insert(Items, {
                    Name = Item.Name,
                    Description = Item:GetAttribute("Description"),
                    Rarity = Item:GetAttribute("RarityName"),
                    ImageId = Item:GetAttribute("ImageId"),
                    Price = Item:GetAttribute("RarityPrice"),
                })
            end
        end
        return Items
    end

    function InventoryLib.GetAllItems()
        local Items = {}

        local NonItemCategories = {
            "bike",
            "car",
            "cosmetic",
            "money"
        }

        for _, Category in next, ReplicatedStorage.Items:GetChildren() do

            if table.find(NonItemCategories, Category.Name) then
                continue
            end

            for _, Item in next, Category:GetChildren() do
                table.insert(Items, {
                    Name = Item.Name,
                    Description = Item:GetAttribute("Description"),
                    Rarity = Item:GetAttribute("RarityName"),
                    ImageId = Item:GetAttribute("ImageId"),
                    Price = Item:GetAttribute("RarityPrice"),
                })
            end
        end
        return Items
    end

    local VehicleCategories = {"bike", "car"}
    InventoryLib.VehicleReferences = {}

    for _, CategoryName in next, VehicleCategories do
        local Category = ReplicatedStorage:FindFirstChild("Items"):FindFirstChild(CategoryName)
        if Category then
            for _, Vehicle in next, Category:GetChildren() do
                if Vehicle:IsA("Model") then
                    InventoryLib.VehicleReferences[Vehicle.Name] = Vehicle
                end
            end
        end
    end

    return InventoryLib
end)()