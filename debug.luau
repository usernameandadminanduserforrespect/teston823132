

local assert = assert
local type = type
local setfenv = setfenv

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
		assert(type(f) == "function" and #{ ... } == 0, "LPH_JIT only accepts a single constant function as an argument.")
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
		assert(#{ ... } == 0, "LPH_CRASH does not accept any arguments.")
	end
end

local DEBUGGING = false

do
	local G2L = {};

	-- StarterGui.WLUI
	G2L["1"] = Instance.new("ScreenGui", game:GetService("CoreGui"));
	G2L["1"]["IgnoreGuiInset"] = true;
	G2L["1"]["ScreenInsets"] = Enum.ScreenInsets.DeviceSafeInsets;
	G2L["1"]["Name"] = [[WLUI]];
	G2L["1"]["ZIndexBehavior"] = Enum.ZIndexBehavior.Sibling;
	G2L["1"]["ResetOnSpawn"] = false;
	G2L["1"]["OnTopOfCoreBlur"] = true;

	-- StarterGui.WLUI.Root
	G2L["2"] = Instance.new("Frame", G2L["1"]);
	G2L["2"]["BorderSizePixel"] = 0;
	G2L["2"]["BackgroundColor3"] = Color3.fromRGB(31, 31, 47);
	G2L["2"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["2"]["Size"] = UDim2.new(0, 350, 0, 120);
	G2L["2"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);
	G2L["2"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["2"]["Name"] = [[Root]];


	-- StarterGui.WLUI.Root.UICorner
	G2L["3"] = Instance.new("UICorner", G2L["2"]);

	-- StarterGui.WLUI.Root.UIStroke
	G2L["4"] = Instance.new("UIStroke", G2L["2"]);
	G2L["4"]["Thickness"] = 2;
	G2L["4"]["Color"] = Color3.fromRGB(66, 61, 86);


	-- StarterGui.WLUI.Root.Title
	G2L["5"] = Instance.new("Frame", G2L["2"]);
	G2L["5"]["BorderSizePixel"] = 0;
	G2L["5"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["5"]["Size"] = UDim2.new(1, 0, 0, 70);
	G2L["5"]["Position"] = UDim2.new(0, 0, 0, 10);
	G2L["5"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["5"]["Name"] = [[Title]];
	G2L["5"]["BackgroundTransparency"] = 1;


	-- StarterGui.WLUI.Root.Title.Image
	G2L["6"] = Instance.new("ImageLabel", G2L["5"]);
	G2L["6"]["BorderSizePixel"] = 0;
	G2L["6"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["6"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["6"]["Image"] = [[rbxassetid://133895178375690]];
	G2L["6"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["6"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["6"]["BackgroundTransparency"] = 1;
	G2L["6"]["Name"] = [[Image]];
	G2L["6"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);


	-- StarterGui.WLUI.Root.Title.Image.UIAspectRatioConstraint
	G2L["7"] = Instance.new("UIAspectRatioConstraint", G2L["6"]);
	G2L["7"]["AspectRatio"] = 4.64;


	-- StarterGui.WLUI.Root.UIGradient
	G2L["8"] = Instance.new("UIGradient", G2L["2"]);
	G2L["8"]["Rotation"] = -90;
	G2L["8"]["Transparency"] = NumberSequence.new{NumberSequenceKeypoint.new(0.000, 0.075),NumberSequenceKeypoint.new(1.000, 0.30625)};
	G2L["8"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(192, 192, 192))};


	-- StarterGui.WLUI.Root.Key
	G2L["9"] = Instance.new("Frame", G2L["2"]);
	G2L["9"]["BorderSizePixel"] = 0;
	G2L["9"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["9"]["Size"] = UDim2.new(1, 0, 0, 20);
	G2L["9"]["Position"] = UDim2.new(0, 0, 0, 85);
	G2L["9"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["9"]["Name"] = [[Key]];
	G2L["9"]["LayoutOrder"] = 1;
	G2L["9"]["BackgroundTransparency"] = 1;


	-- StarterGui.WLUI.Root.Key.KeyInput
	G2L["a"] = Instance.new("TextBox", G2L["9"]);
	G2L["a"]["CursorPosition"] = -1;
	G2L["a"]["Name"] = [[KeyInput]];
	G2L["a"]["BorderSizePixel"] = 0;
	G2L["a"]["TextSize"] = 14;
	G2L["a"]["TextScaled"] = true;
	G2L["a"]["TextColor3"] = Color3.fromRGB(228, 228, 228);
	G2L["a"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["a"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
	G2L["a"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["a"]["ClearTextOnFocus"] = false;
	G2L["a"]["PlaceholderText"] = [[Enter License Key]];
	G2L["a"]["Size"] = UDim2.new(0.7, 0, 1, 0);
	G2L["a"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);
	G2L["a"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["a"]["Text"] = [[]];
	G2L["a"]["BackgroundTransparency"] = 0.5;


	-- StarterGui.WLUI.Root.Key.KeyInput.UICorner
	G2L["b"] = Instance.new("UICorner", G2L["a"]);
	G2L["b"]["CornerRadius"] = UDim.new(0, 5);


	-- StarterGui.WLUI.Root.Status
	G2L["c"] = Instance.new("Frame", G2L["2"]);
	G2L["c"]["BorderSizePixel"] = 0;
	G2L["c"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["c"]["Size"] = UDim2.new(1, 0, 0, 20);
	G2L["c"]["Position"] = UDim2.new(0, 0, 1, 10);
	G2L["c"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["c"]["Name"] = [[Status]];
	G2L["c"]["LayoutOrder"] = 3;
	G2L["c"]["BackgroundTransparency"] = 1;


	-- StarterGui.WLUI.Root.Status.Text
	G2L["d"] = Instance.new("TextLabel", G2L["c"]);
	G2L["d"]["TextWrapped"] = true;
	G2L["d"]["BorderSizePixel"] = 0;
	G2L["d"]["TextSize"] = 14;
	G2L["d"]["TextScaled"] = true;
	G2L["d"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["d"]["FontFace"] = Font.new([[rbxassetid://16658221428]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
	G2L["d"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["d"]["BackgroundTransparency"] = 1;
	G2L["d"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["d"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["d"]["Text"] = [[...]];
	G2L["d"]["Name"] = [[Text]];


	-- StarterGui.WLUI.Root.Status.Text.UIStroke
	G2L["e"] = Instance.new("UIStroke", G2L["d"]);
	G2L["e"]["Transparency"] = 0.27;


	-- StarterGui.WLUI.Root.Authorize
	G2L["f"] = Instance.new("Frame", G2L["2"]);
	G2L["f"]["BorderSizePixel"] = 0;
	G2L["f"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["f"]["Size"] = UDim2.new(0, 20, 0, 20);
	G2L["f"]["Position"] = UDim2.new(1, -40, 0, 85);
	G2L["f"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["f"]["Name"] = [[Authorize]];
	G2L["f"]["LayoutOrder"] = 1;
	G2L["f"]["BackgroundTransparency"] = 1;


	-- StarterGui.WLUI.Root.Authorize.Button
	G2L["10"] = Instance.new("ImageButton", G2L["f"]);
	G2L["10"]["BorderSizePixel"] = 0;
	G2L["10"]["BackgroundTransparency"] = 1;
	-- [ERROR] cannot convert ImageContent, please report to "https://github.com/uniquadev/GuiToLuaConverter/issues"
	G2L["10"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["10"]["Image"] = [[rbxassetid://6776872133]];
	G2L["10"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["10"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["10"]["Name"] = [[Button]];


	KeyUI = {
		Root = G2L["2"],
		Status = G2L["d"],
		KeyInput = G2L["a"],
		Button = G2L["10"],
	}

end

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalizationService = game:GetService("LocalizationService")
local RNG = Random.new(tick())
local DecKey = LPH_ENCSTR("REDACTED_RC4_KEY")
local Debounce = 0
local RunService = game:GetService("RunService")
RunService:SetRobloxGuiFocused(true)
shared.CanAuthenticate = true

local TranslationTable = {
	es = {
		["Authenticating..."] = "Autenticando...",
		["Network error. Details copied to clipboard."] = "Error de red. Detalles copiados al portapapeles.",
		["Please enter a key."] = "Por favor ingresa una clave.",
		["Incompatible executor!"] = "¡Ejecutor incompatible!",
		["Invalid key!"] = "¡Clave inválida!",
		["Key is blacklisted!"] = "¡La clave está en la lista negra!",
		["HWID mismatch, please reset it or use your original device."] = "Desajuste de HWID, restablécelo o usa tu dispositivo original.",
		["Key expired! Purchase a new one at blockspinscript.com/script."] = "¡La clave expiró! Compra una nueva en blockspinscript.com/script.",
		["An unknown error occurred."] = "Ocurrió un error desconocido.",
		["(details copied)"] = "(detalles copiados)",
	},
	th = {
		["Authenticating..."] = "กำลังยืนยันตัวตน...",
		["Network error. Details copied to clipboard."] = "เกิดข้อผิดพลาดของเครือข่าย คัดลอกรายละเอียดไปยังคลิปบอร์ดแล้ว",
		["Please enter a key."] = "กรุณากรอกคีย์.",
		["Incompatible executor!"] = "ตัวรันไม่รองรับ!",
		["Invalid key!"] = "คีย์ไม่ถูกต้อง!",
		["Key is blacklisted!"] = "คีย์ถูกขึ้นบัญชีดำ!",
		["HWID mismatch, please reset it or use your original device."] = "HWID ไม่ตรงกัน โปรดรีเซ็ตหรือใช้เครื่องเดิมของคุณ.",
		["Key expired! Purchase a new one at blockspinscript.com/script."] = "คีย์หมดอายุ! ซื้อใหม่ได้ที่ blockspinscript.com/script.",
		["An unknown error occurred."] = "เกิดข้อผิดพลาดไม่ทราบสาเหตุ.",
		["(details copied)"] = "(คัดลอกรายละเอียดแล้ว)",
	},
	ar = {
		["Authenticating..."] = "جاري التحقق...",
		["Network error. Details copied to clipboard."] = "خطأ في الشبكة. تم نسخ التفاصيل إلى الحافظة.",
		["Please enter a key."] = "يرجى إدخال المفتاح.",
		["Incompatible executor!"] = "المنفذ غير متوافق!",
		["Invalid key!"] = "المفتاح غير صالح!",
		["Key is blacklisted!"] = "المفتاح مُدرج في القائمة السوداء!",
		["HWID mismatch, please reset it or use your original device."] = "عدم تطابق HWID، يرجى إعادة تعيينه أو استخدام جهازك الأصلي.",
		["Key expired! Purchase a new one at blockspinscript.com/script."] = "انتهت صلاحية المفتاح! اشتر مفتاحًا جديدًا من blockspinscript.com/script.",
		["An unknown error occurred."] = "حدث خطأ غير معروف.",
		["(details copied)"] = "(تم نسخ التفاصيل)",
	},
}

local function DetermineLocaleId(): string
	local localeId
	local localPlayer = Players.LocalPlayer
	if localPlayer and type(localPlayer.LocaleId) == "string" and localPlayer.LocaleId ~= "" then
		localeId = localPlayer.LocaleId
	end
	if not localeId or localeId == "" then
		localeId = LocalizationService.RobloxLocaleId
	end
	localeId = localeId or "en-us"
	return string.lower(localeId)
end

local function ResolveTranslation()
	local localeId = DetermineLocaleId()
	if TranslationTable[localeId] then
		return TranslationTable[localeId]
	end
	local primary = string.sub(localeId, 1, 2)
	return TranslationTable[primary]
end

local ActiveTranslation = ResolveTranslation()

local function Translate(text: string): string
	if not ActiveTranslation then
		return text
	end
	return ActiveTranslation[text] or text
end

local AUTH_URL = "https://example.com/auth"
local MAX_REQUEST_ATTEMPTS = 3
local RETRY_DELAY = 0.35

assert(clonefunction, "This script requires clonefunction to be loaded!")
assert(getreg, "This script requires getreg to be loaded!")

pcall(restorefunction, request)
local request = clonefunction(request)

local RC4 = {}
do
	local function ksa(key: string)
		local keyLength = #key
		local S = {}
		for i = 0, 255 do
			S[i] = i
		end

		local j = 0
		for i = 0, 255 do
			local keyByte = string.byte(key, (i % keyLength) + 1)
			j = (j + S[i] + keyByte) % 256
			S[i], S[j] = S[j], S[i]
		end

		return S
	end

	local function prga(S, dataLength: number)
		local i, j = 0, 0
		local keystream = {}

		for n = 1, dataLength do
			i = (i + 1) % 256
			j = (j + S[i]) % 256
			S[i], S[j] = S[j], S[i]

			local K = S[(S[i] + S[j]) % 256]
			keystream[n] = K
		end

		return keystream
	end

	local function stringToBytes(str: string)
		local bytes = {}
		for i = 1, #str do
			bytes[i] = string.byte(str, i)
		end
		return bytes
	end

	local function bytesToString(bytes: { [number]: number })
		local chars = {}
		for i = 1, #bytes do
			chars[i] = string.char(bytes[i])
		end
		return table.concat(chars)
	end

	function RC4.process(key: string, data: string): string
		assert(type(key) == "string" and #key > 0, "Key must be a non-empty string")
		assert(type(data) == "string", "Data must be a string")
		local S = ksa(key)
		local keystream = prga(S, #data)
		local dataBytes = stringToBytes(data)
		local outputBytes = {}
		for i = 1, #dataBytes do
			outputBytes[i] = bit32.bxor(dataBytes[i], keystream[i])
		end
		return bytesToString(outputBytes)
	end

	function RC4.decrypt(key: string, ciphertext: string): string
		return RC4.process(key, ciphertext)
	end
end

local function f(Reason)
	if DEBUGGING then
		warn("Crash prompted! Reason:", Reason)
		return
	end

	Players.LocalPlayer:Kick(Reason)

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
end

-- 
local PasteTables = {
	LPH_ENCSTR("REDACTED"),
	"||RHEX5||", -- server
	LPH_ENCSTR("REDACTED"),
	"||RHEX5||", -- server
	LPH_ENCSTR("REDACTED"),
	"||RHEX5||", -- server
	LPH_ENCSTR("REDACTED"),
	"||RHEX5||", -- server
	LPH_ENCSTR("REDACTED"),
	"||RHEX5||", -- server
	LPH_ENCSTR("REDACTED"),
	"||RHEX5||", -- server
	LPH_ENCSTR("REDACTED"),
	"||RHEX5||",
	"||RHEX5||",
	"||RHEX5||",
	"||RHEX5||",
	"||RHEX5||",
	"||RHEX5||",
	"||RHEX5||",
	"||RHEX5||",
	"||RHEX5||",
	"||RHEX5||",
	"||RHEX5||",
	"||RHEX5||",
	"||RHEX5||",
	"||RHEX5||",
	"||RHEX5||",
	"||RHEX5||",
	"||RHEX5||",
	"||RHEX5||",
	"||RHEX5||",
	"||RHEX5||",
}

pcall(function()

	local LastNumber = RNG:NextInteger(1, 1000000)
	local Changed = false

	for i = 1, 1000 do
		if RNG:NextInteger(1, 1000000) ~= LastNumber then
			Changed = true
			break
		end
	end

	if not Changed then
		f("Random number generator tampered!")
		LPH_CRASH()
	end

	-- Detect time manipulation

	local Start = tick()

	task.wait(1.5)

	if tick() - Start < 1 then
		f("Time manipulation detected!")
		LPH_CRASH()
	end

end)

local function MaskKey(Key)
	if type(Key) ~= "string" then
		return "<invalid>"
	end
	if #Key <= 8 then
		return Key
	end
	return string.sub(Key, 1, 4) .. "..." .. string.sub(Key, -4)
end

local function IdentifyExecutor()
	if typeof(identifyexecutor) == "function" then
		local ok, name, version = pcall(identifyexecutor)
		if ok then
			if version then
				return tostring(name) .. " (" .. tostring(version) .. ")"
			end
			return tostring(name)
		end
	end
	return "Unknown"
end

local function BuildHeaders(Key, Challenge)
	return {
		["Content-Type"] = "application/json",
		["wl-key"] = Key,
		["script"] = "Blockspin",
		["challenge"] = tostring(Challenge),
	}
end

local function FormatAttemptMessage(Source, Attempt, Success, Detail)
	local statusText = Success and "Success" or "Failure"
	return string.format("[%s #%d] %s - %s", Source, Attempt, statusText, Detail)
end

local function BuildSupportReport(Key, Attempts)
	local lines = {}
	lines[#lines + 1] = "[Blockspin Auth Failure Report]"
	lines[#lines + 1] = "Time (UTC): " .. os.date("!%Y-%m-%d %H:%M:%S")
	lines[#lines + 1] = "Executor: " .. IdentifyExecutor()
	lines[#lines + 1] = "Masked Key: " .. MaskKey(Key)
	lines[#lines + 1] = "Discord: https://discord.gg/FpHmSDdG"
	lines[#lines + 1] = "Attempts:"
	for _, entry in ipairs(Attempts) do
		lines[#lines + 1] = "  " .. entry
	end
	return table.concat(lines, "\n")
end

local function TryViaRequest(Key, Challenge)
	local headers = BuildHeaders(Key, Challenge)
	local success, response = pcall(request, {
		Url = AUTH_URL,
		Method = "GET",
		Headers = headers,
	})
	if not success then
		return false, nil, tostring(response)
	end
	if type(response) ~= "table" then
		return false, nil, "No response table returned"
	end
	return true, response, "HTTP " .. tostring(response.StatusCode or "<nil>")
end

local function TryViaHttpPost(Key, Challenge)
	local HttpPost = rawget(game, "HttpPost")
	if type(HttpPost) ~= "function" then
		return false, nil, "game:HttpPost is unavailable in this executor"
	end
	local encodedKey = HttpService:UrlEncode(Key)
	local encodedChallenge = HttpService:UrlEncode(tostring(Challenge))
	local url = string.format("%s?script=Blockspin&wl-key=%s&challenge=%s", AUTH_URL, encodedKey, encodedChallenge)
	local success, bodyOrError = pcall(function()
		return HttpPost(game, url, "", true, "application/json", Enum.HttpRequestType.Default, false)
	end)
	if not success then
		return false, nil, tostring(bodyOrError)
	end
	local response = {
		StatusCode = 200,
		Body = bodyOrError,
	}
	return true, response, "HTTP 200 (HttpPost fallback)"
end

local function PerformAuthRequest(Key, Challenge)
	local attempts = {}
	local response
	for attempt = 1, MAX_REQUEST_ATTEMPTS do
		local ok, result, detail = TryViaRequest(Key, Challenge)
		attempts[#attempts + 1] = FormatAttemptMessage("request", attempt, ok, detail)
		if ok then
			response = result
			break
		end
		task.wait(RETRY_DELAY * attempt)
	end
	if not response then
		local ok, result, detail = TryViaHttpPost(Key, Challenge)
		attempts[#attempts + 1] = FormatAttemptMessage("HttpPost", 1, ok, detail)
		if ok then
			response = result
		end
	end
	return response, attempts
end

function Clear()
	KeyUI.KeyInput.Text = ""
	KeyUI.Status.Text = "..."
	KeyUI.Status.TextColor3 = Color3.fromRGB(255, 255, 255)
	KeyUI.KeyInput.Interactable = true
end

function Authenticate(Key)
	if Debounce > os.clock() then
		return
	end

	if not shared.CanAuthenticate then
		return
	end

	KeyUI.Status.Text = Translate("Authenticating...")
	KeyUI.KeyInput.Interactable = false
	shared.CanAuthenticate = false

	local Challenge = RNG:NextInteger(1, 1000000)

	local Response, AttemptLog = PerformAuthRequest(Key, Challenge)

	if not Response then
		Debounce = os.clock() + 3
		local supportMessage = BuildSupportReport(Key, AttemptLog)
		KeyUI.Status.Text = Translate("Network error. Details copied to clipboard.")
		KeyUI.Status.TextColor3 = Color3.fromRGB(255, 0, 0)
		if typeof(setclipboard) == "function" then
			pcall(setclipboard, supportMessage)
		end
		warn(supportMessage)
		task.delay(3, function()
			Clear()
			shared.CanAuthenticate = true
		end)
		return
	end

	if Response.StatusCode ~= 200 then
		pcall(delfile, "skey.png")

		Debounce = os.clock() + 3

		local ErrorCodes = {
			["HWID not provided."] = "Incompatible executor!",
			["Invalid key."] = "Invalid key!",
			["Key is blacklisted."] = "Key is blacklisted!",
			["Invalid HWID."] = "HWID mismatch, please reset it or use your original device.",
			["Key expired."] = "Key expired! Purchase a new one at blockspinscript.com/script.",
		}
		
		local ErrorMessage = Translate(ErrorCodes[Response.Body] or "An unknown error occurred.")

		KeyUI.KeyInput.Text = ""
		local responseAttemptLog = { FormatAttemptMessage("response", 0, false, "HTTP " .. tostring(Response.StatusCode)) }
		local supportMessage = BuildSupportReport(Key, responseAttemptLog)
		KeyUI.Status.Text = ErrorMessage .. " " .. Translate("(details copied)")
		KeyUI.Status.TextColor3 = Color3.fromRGB(255, 0, 0)
		if typeof(setclipboard) == "function" then
			pcall(setclipboard, supportMessage)
		end
		warn(supportMessage)
		
		if not LPH_OBFUSCATED then
			warn("Auth error:", Response.Body)
		end

		task.delay(3, function()
			Clear()
			shared.CanAuthenticate = true
		end)
		return
	else
		getgenv().Key = Key
		writefile("skey.png", Key)
		KeyUI.Root.Visible = false
		RunService:SetRobloxGuiFocused(false)

		local Decrypted = RC4.decrypt(DecKey, Response.Body)
		local jsonSuccess, Data = pcall(HttpService.JSONDecode, HttpService, Decrypted)

		if not jsonSuccess or not Data then
			f("Authentication failed: Corrupted data.")
			LPH_CRASH()
			return
		end

		if Data.message ~= "success" then
			f("Invalid key!")
			LPH_CRASH()
		end

		if Data.challenge ~= (Challenge * 525 // 3) then
			f("Invalid challenge response!")
			LPH_CRASH()
		end

		if not Data.dkey then
			f("Invalid deckey!")
			LPH_CRASH()
		end

		local DecKey = ""

		if #Data.dkey ~= 30 then
			f("Invalid deckey!")
			LPH_CRASH()
		end

		local dkeyChunk = 1
		for i = 1, #PasteTables do
			if i % 2 == 0 then
				local startIdx = (dkeyChunk - 1) * 5 + 1
				local endIdx = startIdx + 4
				DecKey = DecKey .. string.sub(Data.dkey, startIdx, endIdx)
				dkeyChunk = dkeyChunk + 1
			else
				DecKey = DecKey .. PasteTables[i]
			end

			if #DecKey >= 64 then
				break
			end
		end

		do
			--[[SCRIPTINS]]
		end
		shared.CanAuthenticate = true
	end
	shared.CanAuthenticate = true
end

KeyUI.Button.Activated:Connect(function()
	-- print('keyinput')
	local Key = KeyUI.KeyInput.Text
	if #Key > 3 then
		Authenticate(Key)
	else
		KeyUI.Status.Text = Translate("Please enter a key.")
		KeyUI.Status.TextColor3 = Color3.fromRGB(255, 0, 0)
		task.delay(3, Clear)
	end
end)

if getgenv().Key and #getgenv().Key > 3 then
	-- print('keyinenv')
	Authenticate(getgenv().Key)
elseif isfile('skey.png') then
	-- print('keyinfile')
	local File = readfile('skey.png')
	if File and #File > 3 then
		Authenticate(File)
	end
end