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

local ArgumentCheck = {}

local function sprint(...)
	-- if USERCONSOLE then
	-- 	rconsoleprint("[SASWARE] " .. table.concat(Stringify({ ... }), " ") .. (Executor == "Volcano" and "\n" or ""))
	-- else
	-- 	dbgprint("[SASWARE]", ...)
	-- end
    return
end

local function _swarn(...)
    -- if USERCONSOLE then
    -- 	rconsolewarn("[SASWARE] " .. table.concat(Stringify({ ... }), " ") .. (Executor == "Volcano" and "\n" or ""))
    -- else
	-- 	warn("[SASWARE]", ...)
	-- end
	return
end

local function flen(Table): number
	local Count = 0
	for _ in next, Table do
		Count += 1
	end
	return Count
end

local T = require("./Translation").translate
local Checks = {
    Purchase_Consumable = {
        Match = "purchase_consumable",
        Last_Constant = "get",
        Value = "purchase_consumable",
        Found = false,
        SourceString = "ReplicatedStorage.Modules.Game.UI.ConsumableBuyUI",
    },
    Win = {
        Match = "atm_win",
        Last_Constant = "send",
        Value = "atm_win_2",
        Found = false,
        SourceString = "ReplicatedStorage.Modules.Game.ATM.ATM",
    },
    Request = {
        Match = "request_begin_hacking",
        Last_Constant = "send",
        Value = "request_begin_hacking_2",
        Found = false,
        SourceString = "ReplicatedStorage.Modules.Game.ATM.ATM",
    },
    Sprint = {
        Match = "set_sprinting",
        Last_Constant = "send",
        Value = "set_sprinting_1",
        Found = false,
        SourceString = "ReplicatedStorage.Modules.Game.Sprint",
    },
    Start_Grilling = {
        Match = "start_grilling",
        Last_Constant = "send",
        Value = "start_grilling_2",
        Found = false,
        SourceString = "ReplicatedStorage.Modules.Game.Jobs.SteakhouseCook",
    },
    Finish_Grilling = {
        Match = "finish_grilling",
        Last_Constant = "send",
        Value = "finish_grilling_2",
        Found = false,
        SourceString = "ReplicatedStorage.Modules.Game.Jobs.SteakhouseCook",
    },
    ATM_Transfer = {
        Match = "transfer_funds",
        Last_Constant = "get",
        Value = "transfer_funds",
        Found = false,
        SourceString = "ReplicatedStorage.Modules.Game.ATM.ATMUI",
    },
    Respawn = {
        Match = "death_screen_request_respawn",
        Last_Constant = "send",
        Value = "death_screen_request_respawn",
        Found = false,
        SourceString = "ReplicatedStorage.Modules.Game.DeathScreen",
    },
    Request_Respawn = {
        Match = "request_respawn",
        Last_Constant = "send",
        Value = "request_respawn",
        Found = false,
        SourceString = "ReplicatedStorage.Modules.Game.ResetCallback",
    },
    Toggle_Equip_Item = {
        Match = "toggle_equip_item",
        Last_Constant = "format", --{"get", "send"},
        Value = "toggle_equip_item_1",
        Found = false,
        SourceString = "ReplicatedStorage.Modules.Game.Inventory.ItemsUI",
    },
    Apply_For_Job = {
        Match = "apply_for_job",
        Last_Constant = "send",
        Value = "apply_for_job",
        Found = false,
        SourceString = "ReplicatedStorage.Modules.Game.Jobs.JobApplicationBeacon",
    },
    Leave_Character_Creator = {
        Match = "leave_character_creator",
        Last_Constant = "send",
        Value = "leave_character_creator",
        Found = false,
        SourceString = "ReplicatedStorage.Modules.Game.CharacterCreator.CharacterCreator",
    },
    Enter_Character_Creator = {
        Match = "enter_character_creator",
        Last_Constant = "send",
        Value = "enter_character_creator",
        Found = false,
        SourceString = "ReplicatedStorage.Modules.Game.CharacterCreator.CharacterCreator",
    },
    End_Ragdoll_Early = {
        Match = "end_ragdoll_early",
        Last_Constant = "send",
        Value = "end_ragdoll_early",
        Found = false,
        SourceString = "ReplicatedStorage.Modules.Game.Ragdoll",
    },
    Player_Started_Stocking_Shelf = {
        Match = "player_started_stocking_shelf",
        Last_Constant = "get",
        Value = "player_started_stocking_shelf",
        Found = false,
        SourceString = "ReplicatedStorage.Modules.Game.Jobs.ShelfStocking",
    },
    Player_Stocked_Shelf = {
        Match = "player_stocked_shelf",
        Last_Constant = "get",
        Value = "player_stocked_shelf",
        Found = false,
        SourceString = "ReplicatedStorage.Modules.Game.Jobs.ShelfStocking",
    },
    Pickup_Dropped_Item = {
        Match = "pickup_dropped_item",
        Last_Constant = "get",
        Value = "pickup_dropped_item",
        Found = false,
        SourceString = "ReplicatedStorage.Modules.Game.DroppedItem",
    },
    Get_Random_Free_Grill = {
        Match = "get_random_free_grill",
        Last_Constant = "get",
        Value = "get_random_free_grill",
        Found = false,
        SourceString = "ReplicatedStorage.Modules.Game.Jobs.SteakhouseCook",
    },
    Claim_Quest = {
        Match = "claim_quest",
        Last_Constant = "get",
        Value = "claim_quest",
        Found = false,
        SourceString = "ReplicatedStorage.Modules.Game.Quests.QuestsUI",
    },
    Melee_Attack = {
        Match = "melee_attack",
        Last_Constant = "send",
        Value = "melee_attack",
        Found = false,
        SourceString = "ReplicatedStorage.Modules.Game.ItemTypes.Melee",
    },
    Lock_Vehicle = {
        Match = "lock_vehicle",
        Last_Constant = "send",
        Value = "lock_vehicle",
        Found = false,
        SourceString = "ReplicatedStorage.Modules.Game.VehicleSystem.VehicleGui",
    },
    Drop_Item = {
        Match = "drop_item",
        Last_Constant = "send",
        Value = "drop_item",
        Found = false,
        SourceString = "ReplicatedStorage.Modules.Game.Inventory.ItemsUI",
    },
    Reel_Ended = {
        Match = "reel_ended",
        Last_Constant = "send",
        Value = "reel_ended",
        Found = false,
        SourceString = "ReplicatedStorage.Modules.Game.ItemTypes.FishingRod",
    },
    Change_Accessory = {
        Match = "change_accessory",
        Last_Constant = "get",
        Value = "change_accessory",
        Found = false,
        SourceString = "ReplicatedStorage.Modules.Game.CharacterCreator.CharacterCreator.Items.HatAccessories",
    },
    Throw_Item = {
        Match = "throw_item",
        Last_Constant = "send",
        Value = "throw_item",
        Found = false,
        SourceString = "ReplicatedStorage.Modules.Game.ItemTypes.Throwable",
    },
    Throw_Hit = {
        Match = "throw_hit",
        Last_Constant = "send",
        Value = "throw_hit",
        Found = false,
        SourceString = "ReplicatedStorage.Modules.Game.ItemTypes.Throwable",
    },
    Throw_Rod = {
        Match = "throw_rod",
        Last_Constant = "send",
        Value = "throw_rod",
        Found = false,
        SourceString = "ReplicatedStorage.Modules.Game.ItemTypes.FishingRod",
    },
    Fix_Desync_Hip_Height = {
        Match = "fix_desync_hip_height",
        Last_Constant = "get",
        Value = "fix_desync_hip_height",
        Found = false,
        SourceString = "ReplicatedStorage.Modules.Game.Character.AutomaticScalingEnabled",
    },
    Redeem_Referral_Code = {
        Match = "redeem_referral_code",
        Last_Constant = "get",
        Value = "redeem_referral_code",
        Found = false,
        SourceString = "ReplicatedStorage.Modules.Game.Referral.ReferralUI",
    },
    Run_Over = {
        Math = "run_over",
        Last_Constant = "send",
        Value = "run_over",
        Found = false,
        SourceString = "ReplicatedStorage.Modules.Game.VehicleSystem.Vehicle.VehicleTypes.car",
    }
}

local function dbgprint(...)
	if DEBUGGING then
		-- if USERCONSOLE then
		-- 	rconsoleprint("[DEBUGGING] " .. table.concat(Stringify({ ... }), " "))
		-- else
		print("[DEBUGGING]", ...)
		-- end
	end
end

local function dbgwarn(...)
	if DEBUGGING then
		-- if USERCONSOLE then
		-- rconsolewarn("[DEBUGGING] " .. table.concat(Stringify({ ... }), " "))
		-- else
		warn("[DEBUGGING]", ...)
		-- end
    end
end

local function IsASCII(char)
    return char:byte() >= 32 and char:byte() <= 127
end

function ParseBytecode(data)
    local Constants = {}
    local Constant = {}

    local NAIaR = 0
    local CanAbort = false

    for i = 1, #data do
        local char = data:sub(i, i)

        if IsASCII(char) then
            NAIaR = 0
            table.insert(Constant, char)
        else
            NAIaR += 1
            if #Constant > 0 then
                table.insert(Constants, table.concat(Constant, ''))
                table.clear(Constant)
                CanAbort = true
            end
        end

        if NAIaR > 10 and CanAbort then
            -- warn('Encountered more than 5 non-ASCII characters in a row. Aborting.')
            break
        end

    end

    return Constants
end

local Arguments = flen(Checks)
local Threads = {}
local CompletedCount = 0

-- Before checking GC, we need to require every module that could be holding the constants we need.
-- This ensures that the constants are loaded into memory and accessible via getgc().

local DumpCache = {}

local DumpScript = LPH_JIT_MAX(function(Script : BaseScript)

    if not DumpCache[Script] then
        DumpCache[Script] = ParseBytecode(getscriptbytecode(Script))
    end

    -- print('[DUMP]', Script:GetFullName())

    -- for i,v in next, DumpCache[Script] do
    --     if i % 10 == 0 then task.wait() end
    --     print(i,v)
    -- end

    -- task.wait(60)

    return DumpCache[Script]
end)

local function GetScriptInstanceFromSourceString(SourceString: string): Instance?
    local Current = game
    local Segments = {}
    for Segment in string.gmatch(SourceString, "[^%.]+") do
        table.insert(Segments, Segment)
    end

    for i = 1, #Segments do
        Current = Current:FindFirstChild(Segments[i])
        if not Current then
            warn("Failed to find segment", Segments[i], "in path", SourceString)
            return nil
        end
    end

    return Current
end

for Argument, Data in next, Checks do
    local Thread = task.spawn(function()
        local CurrentIndex = #Threads + 1
        sprint(T(`Performing integrity check {CurrentIndex}/{Arguments} for '{Argument}'...`))
        dbgprint(T(`------------------------------------------------------`))
        dbgprint(T(`[ArgCheck] Starting check for: {Argument}`))
        dbgprint(
            T(
                `[ArgCheck] Expected Value: '{Data.Value}', Match Pattern: '{Data.Match}', Source: '{Data.SourceString}'`
            )
        )

        local Constants = DumpScript(GetScriptInstanceFromSourceString(Data.SourceString))

        -- Attempt 1: Exact match with the current value.
        dbgprint(`[ArgCheck] Attempting exact match...`)
        for _, Constant in next, Constants do
            if type(Constant) == "string" and Constant == Data.Value then
                dbgprint(`[ArgCheck] SUCCESS: Exact match found for '{Argument}' with value '{Constant}'.`)
                Checks[Argument].Found = true
                break
            end
        end

        if Checks[Argument].Found then
            sprint(`Integrity check {CurrentIndex}/{Arguments} passed. ('{Argument}' is up-to-date)`)
        else
            -- Attempt 2: Fuzzy match if exact match failed.
            dbgwarn(
                `[ArgCheck] INFO: Exact match for '{Argument}' failed. Attempting fuzzy match to find new value...`
            )

            for i, Constant in ipairs(Constants) do
                local constantStr = tostring(Constant)
                local pattern = tostring(Data.Match)
                if string.match(constantStr, pattern) then
                    dbgprint(
                        `[ArgCheck] SUCCESS: Fuzzy match found. Updating '{Argument}' to new value '{Constant}'.`
                    )
                    Checks[Argument].Found = true
                    Checks[Argument].Value = Constant
                    break
                end
            end

            if Checks[Argument].Found then
                sprint(
                    `Integrity check {CurrentIndex}/{Arguments} passed. ('{Argument}' was updated to '{Data.Value}')`
                )
            else
                warn(`[ArgCheck] CRITICAL: All checks for '{Argument}' failed. Feature may be broken.`)
                sprint(`Integrity check {CurrentIndex}/{Arguments} FAILED. ('{Argument}' could not be found)`)
            end
        end
        dbgprint(`------------------------------------------------------`)
        CompletedCount += 1
    end)
    -- task.wait(1)
    table.insert(Threads, Thread)
end

-- Wait for all threads to complete
while CompletedCount < Arguments do
    task.wait()
end

ArgumentCheck.Results = Checks

-- Check if all arguments were found.

ArgumentCheck.AllFound = true

for Argument, Data in next, Checks do
    if not Data.Found then
        warn(`[ArgCheck] CRITICAL: '{Argument}' was not found. Feature may be broken.`)
        ArgumentCheck.AllFound = false
    end
end

return ArgumentCheck