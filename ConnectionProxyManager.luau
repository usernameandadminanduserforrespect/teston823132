-- Sasware Anti-Skid Module
-- Some integrity checks to see if someone's trying to sniff or tamper with the script.

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

if not LPH_OBFUSCATED then
    print('Anti-skid not loading due to test environment.')
    return {}
end

if getgenv().skibiditoiletohiorizzat3amworking2025 == "TOBIASHACKEDMYPC" then
    print('Anti-skid not loading due to test environment.')
    return {}
end

local Quartz = loadstring(game:HttpGetAsync("https://github.com/notpoiu/Quartz/releases/latest/download/Quartz.luau"))()

local Tester = Quartz.new({
    Timeout = 5
})

Tester:TestAll()
Tester:PatchEnvironment(0)

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Webhooks = require("./webhooks.luau")

local function GetFingerprint(): number
    local JobId = game.JobId

    local Sum = 0
    for i = 1, #JobId do
        Sum = Sum + string.byte(JobId, i)
    end

    return Sum % 255
end

if getgenv().CARLSEN == GetFingerprint() then
    print('Hermanos detected, adapting protections...')
    shared.CompatabilityMode = true
end

local cv = {}

for i : string, v in next, getgenv() do

    if type(i) ~= "string" then
        continue
    end

    if type(v) == "function" and (not i:match('LPH_')) and (i ~= "require") and (i ~= "Drawing") and (i ~= "cleardrawcache") then
        cv[i] = tostring(v)
    end
end

--print('cache setup complete')

pcall(restorefunction, getgenv().isfunctionhooked)

local function f(Reason)

    if not LPH_OBFUSCATED then
        print("Crash:", Reason)
        warn(debug.traceback())
        return
    end

    task.delay(0.00001, function()
        for _, v : Sound in next, game:GetDescendants() :: any do
            if v:IsA("Sound") then
                v:Stop()
            end
        end
    end)

    task.delay(1, function()
        game:Shutdown()
    end)

    task.defer(function()

        local vpz = workspace.CurrentCamera.ViewportSize

        for i = 100, 1, -1 do
            local t = Drawing.new("Text")
            t.Text = math.random() > 0.5 and "Sasware Anti-Skid" or "Tampering Detected"
            t.Size = math.random(20, 50)
            t.Color = Color3.fromRGB(math.random(100, 255), math.random(100, 255), math.random(100, 255))
            t.Position = Vector2.new(vpz.X / 2, vpz.Y / 2) + Vector2.new(math.random(-vpz.X / 2, vpz.X / 2), math.random(-vpz.Y / 2, vpz.Y / 2))
            t.Outline = math.random() < 0.5
            t.OutlineColor = Color3.fromRGB(math.random(100, 255), math.random(100, 255), math.random(100, 255))
            t.Visible = true
        end

    end)

    task.delay(2, function()
		LPH_CRASH()
		local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
		local Lines = table.create(40, Vector3.zero)

		for i = 1, 30000 do
			local W = Instance.new("WireframeHandleAdornment")
			W.Parent = PlayerGui
			W.Adornee = workspace
			W:AddLines(Lines)
		end

		task.spawn(function()
			task.wait(2.5)
			table.clear(getreg())
			repeat
				while true do
				end
			until false
		end)
	end)

    task.delay(10, function()
        for i,v in next, getconnections(Players.LocalPlayer.OnTeleportInternal) do
            v:Disable()
        end
        local f = function() while task.wait() do end end
        task.spawn(f)
        hookfunction(f, function() print('crash') end)
    end)

    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://109974502878146"
    s.Volume = 0.8
    s.PlaybackSpeed = 0.3

    Instance.new("DistortionSoundEffect", s)
    Instance.new("EchoSoundEffect", s)

    s.Parent = workspace
    s:Play()

    local fxect = Instance.new("ColorCorrectionEffect")
    fxect.Parent = Lighting

    TweenService:Create(fxect, TweenInfo.new(1), {
        Brightness = -2,
        Contrast = -12,
        Saturation = -20,
        TintColor = Color3.fromRGB(0, 255, 8)
    }):Play()
end

local tf = function(x)
    --print(x)
end

hookfunction(tf, warn)

-- Generate garbage args
local gargs = function()
    local garbage = {
        "stop",
        "skidding",
        "garbage",
        workspace,
        Players.LocalPlayer,
        Lighting,
        RunService,
        TweenService,
        Players:GetPlayers(),
        buffer,
        "arg" .. tostring(math.random(1, 100))
    }

    local args = {}
    for i = 1, math.random(5, 50) do
        if math.random() < 0.5 then
            table.insert(args, garbage[math.random(1, #garbage)])
        else
            table.insert(args, "arg" .. tostring(i))
        end
    end
    return args
end

local c = coroutine.create(function()

    local is, fs = Instance.new("RemoteFunction").InvokeServer, Instance.new("RemoteEvent").FireServer

    local rf, re = Instance.new("RemoteFunction"), Instance.new("RemoteEvent")

    RunService.RenderStepped:Connect(function()
        local n = ""

        for i = 1, math.random(1, 32) do
            n = n .. string.char(math.random(1, 255))
        end

        rf.Name = n
        pcall(is, rf, gargs())
        re.Name = n
        pcall(fs, re, gargs())
    end)

    while task.wait(1) do
        
        if isfunctionhooked(is) or isfunctionhooked(fs) then

            Webhooks.SendWebhook({
                url = "https://discord.com/api/webhooks/REDACTED/REDACTED",
                username = "Tamper Protection",
                content = `A user has attempted to remote-log Sasware!\nUser: {Players.LocalPlayer.Name}\nPID: {game.PlaceId}\nKey: \`{getgenv().Key or "No Key"}\``,
            })

            task.wait(1)

            f("Instance tampering detected")
            break
        end

    end

end)

spawn(function()
    if isfunctionhooked(getgenv().getcallingscript) then
        Webhooks.SendWebhook({
            url = "https://discord.com/api/webhooks/REDACTED/REDACTED",
            username = "Tamper Protection",
            content = `A user has attempted to tamper with Sasware's getcallingscript function!\nUser: {Players.LocalPlayer.Name}\nPID: {game.PlaceId}\nKey: \`{getgenv().Key or "No Key"}\``,
        })

        f("Function tampering detected")
    end
end)

spawn(function()
    while task.wait(1) do
        --print('cache check')
        for i,v in next, getgenv() do
            if type(v) == "function" and cv[i] then
                if tostring(v) ~= cv[i] then
                    Webhooks.SendWebhook({
                        url = "https://discord.com/api/webhooks/REDACTED/REDACTED",
                        username = "Tamper Protection",
                        content = `A user has attempted to replace Sasware's getgenv functions!\nFunction: {i}{tostring(cv[i])}{tostring(v)}\nUser: {Players.LocalPlayer.Name}\nPID: {game.PlaceId}\nKey: \`{getgenv().Key or "No Key"}\``,
                    })

                    f("getgenv tampering detected")
                end
            end
        end
    end
end)

task.defer(function()
    while task.wait(0.5) do
        --print('tamper isfunctionhooked check')
        if not isfunctionhooked(tf) then
            Webhooks.SendWebhook({
                url = "https://discord.com/api/webhooks/REDACTED/REDACTED",
                username = "Tamper Protection",
                content = `A user has attempted to tamper with Sasware's isfunctionhooked function!\nUser: {Players.LocalPlayer.Name}\nPID: {game.PlaceId}\nKey: \`{getgenv().Key or "No Key"}\``,
            })

            f("Function tampering detected")
        end
    end
end)

coroutine.resume(c)
task.defer(function()
    while task.wait() do
        if coroutine.status(c) == "dead" then
            -- Tampering detected, blow up.
            f("Coroutine tampering detected")
            return
        end
    end
end)

task.defer(function()
    while task.wait(1) do
        for n, v in next, getgenv() do
            --if type(v) == 'function' then --print('checking', n, v) end
            if type(v) == "function" and isfunctionhooked(v) then
                Webhooks.SendWebhook({ 
                    url = "https://discord.com/api/webhooks/REDACTED/REDACTED",
                    username = "Tamper Protection",
                    content = `A user has attempted to tamper with Sasware's getgenv functions! \nFunction: {n}\nUser: {Players.LocalPlayer.Name}\nPID: {game.PlaceId}\nKey: \`{getgenv().Key or "No Key"}\``,
                })

                f("getgenv tampering detected")
            end

            pcall(restorefunction, v)
        end
    end
end)

local function IsDev_LogService()
    for i,v in pairs(getconnections(game.LogService.ServerMessageOut)) do
        v:Disable()
    end

    game.LogService:ExecuteScript(string.rep(" ", 17000) .. [=[workspace:SetAttribute("a", "b")]=])
    wait(1)

    for i,v in pairs(getconnections(game.LogService.ServerMessageOut)) do
        v:Enable()
    end

    if workspace:GetAttribute("a") == "b" then
        return true
    end
    return false
end

spawn(function()
    if isfunctionhooked(require(game.ReplicatedStorage.Modules.Core.Net :: ModuleScript).send) then
        Webhooks.SendWebhook({
            url = "https://discord.com/api/webhooks/REDACTED/REDACTED",
            username = "Tamper Protection (send)",
            content = `A user has attempted to tamper with Sasware's network functions!\nUser: {Players.LocalPlayer.Name}\nPID: {game.PlaceId}\nKey: \`{getgenv().Key or "No Key"}\``,
        })

        f("Network tampering detected")
    end

    if isfunctionhooked(require(game.ReplicatedStorage.Modules.Core.Net :: ModuleScript).get) then
        Webhooks.SendWebhook({
            url = "https://discord.com/api/webhooks/REDACTED/REDACTED",
            username = "Tamper Protection (get)",
            content = `A user has attempted to tamper with Sasware's network functions!\nUser: {Players.LocalPlayer.Name}\nPID: {game.PlaceId}\nKey: \`{getgenv().Key or "No Key"}\``,
        })

        f("Network tampering detected")
    end
end)

spawn(function()
    while task.wait(1) do
        if IsDev_LogService() then

            Webhooks.SendWebhook({
                url = "https://discord.com/api/webhooks/REDACTED/REDACTED",
                username = "fedwatch",
                content = `A user with server-side execution permissions has attempted to use Sasware!\nUser: {Players.LocalPlayer.Name}\nPID: {game.PlaceId}`,
            })

            task.wait(1)

            f("LogService tampering detected")
            break
        end
    end
end)

return true