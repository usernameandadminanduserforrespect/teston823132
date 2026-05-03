--[[
RS_Gen
Generates a private server access code and attempts to teleport the local player there.

Enhancements added:
 - Safe retry loop with configurable timeout (default 20s) and max attempts (default 5; set to math.huge for infinite)
 - Regenerates access code after each timeout or failure
 - Cancels pending teleport requests with TeleportService:TeleportCancel() before retrying
 - Lightweight modal UI in CoreGui showing status, attempt count, and countdown
 - Basic error handling + graceful degradation if remote or services are missing

Usage (backwards compatible):
  local start = require(RS_Gen)
  start() -- uses defaults
  -- or with options
  start({ timeout = 20, maxAttempts = 10, placeId = 123456789 })

The function returns a control table:
  { Cancel = <function>, Gui = <ScreenGui>, Attempts = <BindableEvent> }
Cancel() will stop further retries (if still in current server).
Attempts event fires with (attemptNumber, phaseString)
]]

return function(opts)
	opts = opts or {}
	local timeout = tonumber(opts.timeout) or 20 -- seconds to wait before retry
	local maxAttempts = opts.maxAttempts or 5
	local placeId = opts.placeId or game.PlaceId
	local urlBase = opts.urlBase or "https://example.com/gpsk/"
	local confirmOnTeleport = opts.confirmOnTeleport == true -- default false per updated requirement

	local Players = game:GetService("Players")
	local TeleportService = game:GetService("TeleportService")
	local CoreGui = game:GetService("CoreGui")
	local LocalPlayer = Players.LocalPlayer

	local active = true
	local attempt = 0
	local lastCode = nil

	-- UI ------------------------------------------------------------------
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PrivateServerTeleportModal"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 999999
	pcall(function()
		screenGui.Parent = CoreGui
	end)

	local frame = Instance.new("Frame")
	frame.Name = "Container"
	frame.Size = UDim2.fromOffset(380, 170)
	frame.Position = UDim2.new(0.5, -190, 0.5, -85)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	frame.BorderSizePixel = 0
	frame.AutomaticSize = Enum.AutomaticSize.None
	frame.Parent = screenGui
	frame.ZIndex = 999999

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingBottom = UDim.new(0, 12)
	padding.PaddingLeft = UDim.new(0, 14)
	padding.PaddingRight = UDim.new(0, 14)
	padding.Parent = frame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 24)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = Color3.fromRGB(235, 235, 240)
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "Teleporting to Private Server"
	title.Parent = frame

	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.BackgroundTransparency = 1
	status.Position = UDim2.new(0, 0, 0, 40)
	status.Size = UDim2.new(1, 0, 1, -40)
	status.Font = Enum.Font.Gotham
	status.TextColor3 = Color3.fromRGB(210, 210, 215)
	status.TextSize = 14
	status.TextWrapped = true
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.TextYAlignment = Enum.TextYAlignment.Top
	status.RichText = true
	status.Text = "Preparing..."
	status.Parent = frame

	local AttemptsEvent = Instance.new("BindableEvent")

	local function fmtAttempt()
		local maxText = (maxAttempts == math.huge) and "∞" or tostring(maxAttempts)
		return string.format("Attempt %d/%s", attempt, maxText)
	end

	local function setStatus(lines)
		status.Text = table.concat(lines, "\n")
	end

	local function getAccessCode()
		local ok, code = pcall(function()
			return game:HttpGet(urlBase .. tostring(placeId))
		end)
		if ok and type(code) == "string" and #code > 0 then
			lastCode = code
			return code
		end
		return nil, code
	end

	local cancelledExternally = false
	local function cancel()
		active = false
		cancelledExternally = true
		pcall(function()
			TeleportService:TeleportCancel()
		end)
		setStatus({
			fmtAttempt(),
			"Cancellation requested. No further teleport attempts.",
		})
		task.delay(2, function()
			if screenGui and screenGui.Parent then
				screenGui:Destroy()
			end
		end)
	end

	-- Teleport state tracking (we DO NOT automatically treat this as success unless confirmOnTeleport)
	local teleporting = false
	local successFlag = false
	local teleportFailedFlag = false

	-- TeleportService event connections (protected for exploit environment differences)
	pcall(function()
		TeleportService.TeleportInitFailed:Connect(function(player, result, errorMsg)
			if player == LocalPlayer and active and not successFlag then
				teleportFailedFlag = true
				setStatus({ fmtAttempt(), "Teleport init failed: " .. tostring(result), "Will retry after timeout..." })
			end
		end)
	end)

	-- Some environments provide LocalPlayer.OnTeleport
	pcall(function()
		LocalPlayer.OnTeleport:Connect(function(state)
			if not active then return end
			if state == Enum.TeleportState.Started or state == Enum.TeleportState.InProgress then
				teleporting = true
				if confirmOnTeleport then
					successFlag = true
					setStatus({ fmtAttempt(), "Teleport started. Good luck!" })
				end
			elseif state == Enum.TeleportState.Failed then
				teleportFailedFlag = true
			end
		end)
	end)

	-- Main attempt loop (non-blocking)
	task.spawn(function()
		while active and (maxAttempts == math.huge or attempt < maxAttempts) do
			attempt += 1
			AttemptsEvent:Fire(attempt, "begin")

			-- Acquire access code
			local code = getAccessCode()
			if not code then
				setStatus({ fmtAttempt(), "Failed to acquire access code.", "Retrying in 3s..." })
				AttemptsEvent:Fire(attempt, "code_fail")
				local waitStart = os.clock()
				while active and os.clock() - waitStart < 3 do task.wait(0.25) end
				if not active then break end
				-- continue loop
			else
				-- Fire remote
				setStatus({ fmtAttempt(), "Access code acquired.", "Firing teleport remote..." })
				local remoteContainer = game:FindFirstChild("RobloxReplicatedStorage") or (pcall(function() return game:GetService("ReplicatedStorage") end) and game:GetService("ReplicatedStorage"))
				local remote = remoteContainer and remoteContainer:FindFirstChild("ContactListIrisInviteTeleport")
				local remoteOk, errRemote = pcall(function()
					if remote then
						remote:FireServer(placeId, "", code)
					else
						error("Remote missing")
					end
				end)
				if not remoteOk then
					setStatus({ fmtAttempt(), "Teleport remote missing or failed.", tostring(errRemote or "(no remote)"), "Retrying in 5s..." })
					AttemptsEvent:Fire(attempt, "remote_fail")
					local waitStart2 = os.clock()
					while active and os.clock() - waitStart2 < 5 do task.wait(0.25) end
					if not active then break end
				else
					teleporting = false
					teleportFailedFlag = false
					-- Wait for success (only if confirmOnTeleport) or until timeout; otherwise if teleport truly happens the script stops executing.
					local startClock = os.clock()
					while active and not successFlag do
						local elapsed = os.clock() - startClock
						local remaining = timeout - elapsed
						if remaining <= 0 then break end
						if teleportFailedFlag then break end
						local lines
						if teleporting then
							lines = { fmtAttempt(), "Teleport reported in-progress...", string.format("Will retry in %.1fs if still here", remaining) }
						else
							lines = { fmtAttempt(), "Waiting for teleport...", string.format("Regenerating code in %.1fs if no progress", remaining) }
						end
						setStatus(lines)
						task.wait(0.5)
					end

					if successFlag then
						AttemptsEvent:Fire(attempt, "success")
						-- Let user see success for a moment then remove
						task.delay(2, function()
							if screenGui and screenGui.Parent and not cancelledExternally then
								screenGui:Destroy()
							end
						end)
						break
					end
					if not active then break end

					-- Timeout or failure path (if we reach here no success)
					AttemptsEvent:Fire(attempt, "timeout")
					setStatus({ fmtAttempt(), "No teleport confirmation within timeout.", "Cancelling & retrying with new code..." })
					pcall(function()
						TeleportService:TeleportCancel()
					end)
					local cancelStart = os.clock()
					while active and os.clock() - cancelStart < 1 do task.wait(0.1) end
				end
			end
		end

		if active and not successFlag then
			setStatus({ "Teleport attempts exhausted.", "You remain in the current server." })
			task.delay(3, function()
				if screenGui and screenGui.Parent then
					screenGui:Destroy()
				end
			end)
		end
	end)

	return {
		Cancel = cancel,
		Gui = screenGui,
		Attempts = AttemptsEvent.Event,
		GetLastCode = function() return lastCode end,
	}
end
