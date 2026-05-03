local Webhooks = require("./webhooks.luau")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local REPORT_URL = "https://discord.com/api/webhooks/REDACTED/REDACTED"
local MAX_FIELD_LENGTH = 1024
local MAX_DESCRIPTION_LENGTH = 2048

local ErrorReporter = {}

local function toString(value)
	if value == nil then
		return "nil"
	end

	if type(value) == "string" then
		return value
	end

	if type(value) == "table" then
		local success, encoded = pcall(function()
			return HttpService:JSONEncode(value)
		end)

		if success then
			return encoded
		end
	end

	return tostring(value)
end

local function truncate(value, limit)
	local text = toString(value)

	if limit and #text > limit then
		return string.sub(text, 1, limit - 3) .. "..."
	end

	return text
end

local function getEnvValue(key)
	if type(getgenv) ~= "function" then
		return nil
	end

	local success, env = pcall(getgenv)

	if success and type(env) == "table" then
		return env[key]
	end

	return nil
end

local function getExecutorInfo()
	if type(identifyexecutor) == "function" then
		local success, name, version = pcall(identifyexecutor)

		if success then
			if type(name) == "table" then
				local encoded = toString(name)
				return truncate(encoded, MAX_FIELD_LENGTH)
			end

			local label = tostring(name or "Unknown")

			if version and version ~= "" then
				label = label .. " " .. tostring(version)
			end

			return truncate(label, MAX_FIELD_LENGTH)
		end
	end

	return "Unavailable"
end

local function getLicenseKey()
	local key = getEnvValue("Key")

	if key == nil or key == "" then
		return "No Key"
	end

	return truncate(toString(key), MAX_FIELD_LENGTH)
end

local function resolveFreeBuild()
	local value = getEnvValue("FREE_BUILD")

	if value ~= nil then
		return value and "Yes" or "No"
	end

	local success, fallback = pcall(function()
		return FREE_BUILD
	end)

	if success and fallback ~= nil then
		return fallback and "Yes" or "No"
	end

	return "Unknown"
end

local function getLocalPlayer()
	local success, player = pcall(function()
		return Players.LocalPlayer
	end)

	if success and player then
		return player
	end

	return nil
end

local function resolveTraceback(raw, depth)
	if raw and raw ~= "" then
		return truncate(toString(raw), MAX_FIELD_LENGTH)
	end

	if type(debug) == "table" and type(debug.traceback) == "function" then
		local success, trace = pcall(function()
			return debug.traceback(nil, depth or 4)
		end)

		if success and trace and trace ~= "" then
			return truncate(trace, MAX_FIELD_LENGTH)
		end
	end

	return "Unavailable"
end

function ErrorReporter.ReportPopup(data)
	if type(data) ~= "table" then
		return
	end

	task.spawn(function()
		local player = getLocalPlayer()
		local playerLabel = "Unknown"
		local userId = "0"

		if player then
			local display = player.DisplayName or player.Name
			playerLabel = string.format("%s (%s)", player.Name, display)
			userId = tostring(player.UserId)
		end

		local message = truncate(data.message or "No message provided.", MAX_DESCRIPTION_LENGTH)
		local trace = resolveTraceback(data.traceback, data.tracebackDepth)
		local executorInfo = getExecutorInfo()
		local licenseKey = getLicenseKey()
		local freeBuild = resolveFreeBuild()
		local recoverableText = "Unknown"

		if data.recoverable ~= nil then
			recoverableText = data.recoverable and "Yes" or "No"
		end

		local embed = {
			title = data.title or "Sasware Error Report",
			description = message,
			color = data.color or 0xFF5555,
			fields = {
				{
					name = "Error Code",
					value = truncate(data.code or "N/A", 256),
					inline = true,
				},
				{
					name = "Recoverable",
					value = recoverableText,
					inline = true,
				},
				{
					name = "Source",
					value = truncate(data.source or "Unknown", MAX_FIELD_LENGTH),
					inline = true,
				},
				{
					name = "Executor",
					value = executorInfo,
					inline = true,
				},
				{
					name = "Free Build",
					value = freeBuild,
					inline = true,
				},
				{
					name = "License Key",
					value = licenseKey,
					inline = false,
				},
				{
					name = "Player",
					value = truncate(playerLabel, MAX_FIELD_LENGTH),
					inline = true,
				},
				{
					name = "UserId",
					value = userId,
					inline = true,
				},
				{
					name = "PlaceId",
					value = tostring(game.PlaceId),
					inline = true,
				},
				{
					name = "Traceback",
					value = trace,
					inline = false,
				},
			},
			footer = {
				text = string.format("Timestamp: %s", os.date("%Y-%m-%d %H:%M:%S")),
			},
		}

		if type(data.extraFields) == "table" then
			for _, field in ipairs(data.extraFields) do
				if type(field) == "table" then
					table.insert(embed.fields, {
						name = truncate(field.name or "Extra", 256),
						value = truncate(field.value or "N/A", MAX_FIELD_LENGTH),
						inline = field.inline or false,
					})
				end
			end
		end

		local payload = {
			url = REPORT_URL,
			embeds = { embed },
			username = data.username or "Sasware Error Reporter",
		}

		if data.content then
			payload.content = truncate(data.content, 2000)
		end

		local success = Webhooks.SendWebhook(payload)

		if not success then
			warn("[ErrorReporter] Failed to send error webhook")
		end
	end)
end

return ErrorReporter
