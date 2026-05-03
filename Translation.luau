local HttpService = game:GetService("HttpService")

type RequestOptions = {
	Url: string,
	Method: "GET" | "HEAD" | "POST" | "PUT" | "DELETE" | "OPTIONS" | "PATCH"?,
	Body: string?,
	Headers: { [string]: string }?,
	Cookies: { [string]: string }?,
	Timeout: number?,
}

type Response = {
	Success: boolean,
	Body: string,
	StatusCode: number,
	StatusMessage: string,
	Headers: { [string]: string },
}

local env = getfenv()
local http_request = rawget(env, "http_request")
local plainRequest = rawget(env, "request")
local syn = rawget(env, "syn")
local httpLib = rawget(env, "http")
local fluxus = rawget(env, "fluxus")
local krnl = rawget(env, "krnl")
local sharedTable = rawget(env, "shared")
local rconsoleprintFn = rawget(env, "rconsoleprint")
local warnFn = (type(env.warn) == "function" and env.warn) or print
local taskLib = rawget(env, "task")
local waitFn = (type(env.wait) == "function" and env.wait) or function(seconds)
	if seconds then
		local target = os.clock() + seconds
		repeat until os.clock() >= target
	end
end
local taskWait = taskLib and taskLib.wait or waitFn
local taskSpawn = taskLib and taskLib.spawn or function(callback, ...)
	local thread = coroutine.create(callback)
	local ok, err = coroutine.resume(thread, ...)
	if not ok then
		warnFn(err)
	end
end

local SecureRequest = {}

local function resolveRequestImpl()
	local impl = nil
	if type(http_request) == "function" then
		impl = http_request
	elseif type(request) == "function" then
		impl = request
	elseif type(plainRequest) == "function" then
		impl = plainRequest
	elseif syn and type(syn.request) == "function" then
		impl = syn.request
	elseif type(httpLib) == "table" and type(httpLib.request) == "function" then
		impl = httpLib.request
	elseif fluxus and type(fluxus.request) == "function" then
		impl = fluxus.request
	elseif krnl and type(krnl.request) == "function" then
		impl = krnl.request
	end
	return impl
end

local BaseRequest = resolveRequestImpl()
assert(type(BaseRequest) == "function", "[secure_request] No HTTP request implementation is available")

local RETRYABLE_STATUS = {
	[408] = true,
	[425] = true,
	[429] = true,
	[500] = true,
	[502] = true,
	[503] = true,
	[504] = true,
	[522] = true,
	[524] = true,
}

local INITIAL_DELAY = 0.5
local MAX_DELAY = 10

local function shallowCopy(dict: { [string]: any })
	local copy = {}
	for key, value in pairs(dict) do
		copy[key] = value
	end
	return copy
end

local function sanitizeUrl(url: string): string
	if #url <= 120 then
		return url
	end
	return url:sub(1, 117) .. "..."
end

local function consoleMessage(text: string)
	if type(rconsoleprintFn) == "function" then
		rconsoleprintFn(text .. "\n")
	else
		warnFn(text)
	end
end

local function startNotifier(method: string, url: string): () -> ()
	local overlay = sharedTable and sharedTable.StatusText or nil
	local previousText = overlay and overlay.Text or nil
	local message = (`[HTTP] Waiting for %s %s`):format(method, sanitizeUrl(url))
	local active = true

	taskSpawn(function()
		taskWait(1)
		if not active then
			return
		end
		if overlay then
			overlay.Text = message
		else
			consoleMessage(message)
		end
	end)

	return function()
		active = false
		if overlay and previousText and overlay.Text == message then
			overlay.Text = previousText
		end
	end
end

local function isRetryable(response: Response?, err: string?): boolean
	if err then
		return true
	end
	if not response then
		return true
	end

	local statusCode = response.StatusCode

	if response.Success and statusCode and statusCode >= 200 and statusCode < 400 then
		return false
	end

	if statusCode == nil then
		return not response.Success
	end

	if RETRYABLE_STATUS[statusCode] then
		return true
	end

	if statusCode >= 500 then
		return true
	end

	return false
end

function SecureRequest.request(options: RequestOptions): Response
	assert(type(options) == "table", "secure_request.request expects an options table")
	assert(type(options.Url) == "string", "secure_request.request requires options.Url")

	local normalized = shallowCopy(options)
	local timeout = normalized.Timeout
	normalized.Timeout = nil
	normalized.Method = string.upper(normalized.Method or "GET")

	local startTime = os.clock()
	local attempt = 0
	local notifierDone = startNotifier(normalized.Method, normalized.Url)
	local lastError: string? = nil

	while true do
		attempt += 1

		local success, responseOrError = pcall(BaseRequest, normalized)
		if success then
			local response = responseOrError :: Response
			if response and not isRetryable(response) then
				notifierDone()
				return response
			end
			lastError = response and (`HTTP %s %s`):format(response.StatusCode or "?", response.StatusMessage or "")
		else
			lastError = tostring(responseOrError)
		end

		if timeout and (os.clock() - startTime) >= timeout then
			notifierDone()
			error((`[secure_request] Request timed out after %d attempts: %s`):format(attempt, lastError or "Unknown error"))
		end

		taskWait(math.min(INITIAL_DELAY * 2 ^ math.min(attempt, 5), MAX_DELAY) + math.random() * 0.25)
	end
end

function SecureRequest:HttpGet(url: string, nocache: boolean?, timeoutSeconds: number?): string
	assert(type(url) == "string", "secure_request:HttpGet expects a URL string")
	local targetUrl = url

	if nocache then
		local sep = url:find("?", 1, true) and "&" or "?"
		targetUrl = (`%s%scachebuster=%s`):format(url, sep, HttpService:GenerateGUID(false))
	end

	local response = SecureRequest.request({
		Url = targetUrl,
		Method = "GET",
		Timeout = timeoutSeconds,
	})

	if response.Success then
		return response.Body
	end

	error((`[secure_request] HttpGet failed (HTTP %s %s)`):format(response.StatusCode or "?", response.StatusMessage or ""))
end

return table.freeze(SecureRequest)
