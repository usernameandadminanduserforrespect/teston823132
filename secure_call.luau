--!nolint
local SHA256 = require("./SHA256.luau") :: (Content: string, Salt: string?) -> string
local HttpService = game:GetService("HttpService")
local SecureRequest = require("./secure_request.luau")

local ORCHESTRATION_ENDPOINT = "https://example.com/orchestration"

local OrchestratorTest = {}

-- Replicate the private key generation from the client
function OrchestratorTest:GeneratePrivateKey(licenseKey: string, userId: number): string
    -- Debug: Test basic SHA256 first
    local testHash = SHA256("hello")
    local expectedHello = "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
    
    local KeyHash = SHA256(licenseKey, "bsp_k1_9f3a")
    local UserHash = SHA256(tostring(userId), "bsp_u2_7c1e")
    
    local Interleaved = ""
    for i = 1, 64, 8 do
        Interleaved = Interleaved .. string.sub(KeyHash, i, i + 3) .. string.sub(UserHash, i + 4, i + 7)
    end
    
    local Final = SHA256(Interleaved, "bsp_f3_2d8b")
    
    -- Debug: copy all values to clipboard
    local debugInfo = string.format(
        "SHA256('hello'): %s\nExpected: %s\nMatch: %s\n\nActual salted input for key: %s\nKeyHash: %s\nExpected KeyHash: 9dadf26fe740fe035a8f488fb509f0c5117a04e4b5185a3165ca07d05693117a\n\nUserHash: %s\nInterleaved: %s\nFinal: %s",
        testHash, expectedHello, tostring(testHash == expectedHello),
        licenseKey .. "_bsp_k1_9f3a",
        KeyHash, UserHash, Interleaved, Final
    )
    if setclipboard then
        pcall(setclipboard, debugInfo)
    end
    print("[DEBUG] Copied debug info to clipboard")
    
    return Final
end

-- Test registering worker data (as a master would)
function OrchestratorTest:TestRegisterWorkerData(licenseKey: string, workerUserId: number)
    print("[TEST] Registering worker data...")
    
    local PrivateKey = self:GeneratePrivateKey(licenseKey, workerUserId)
    print("[TEST] Generated private key:", string.sub(PrivateKey, 1, 16) .. "...")
    
    local Url = string.format("%s/registerWorkerData", ORCHESTRATION_ENDPOINT)
    
    local TestWorkerData = {
        master_user_id = 123456789,
        master_server_id = "test-job-id-" .. tostring(os.time()),
        transfer_threshold = 1000000,
        autofarm_settings = {
            enabled = true,
            target_money = 5000000,
        },
        priority = 1,
        registered_at = os.time(),
    }
    
    local Payload = {
        userId = workerUserId,
        key = PrivateKey,
        data = TestWorkerData,
        license = licenseKey,
    }
    
    local Success, Response = pcall(function()
        return SecureRequest.request({
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
            },
            Body = HttpService:JSONEncode(Payload),
            Url = Url
        })
    end)
    
    if not Success then
        print("[TEST] FAILED to register:", Response)
        return false
    end
    
    if not Response.Success then
        print("[TEST] Server returned error status:", Response.StatusCode, Response.StatusMessage)
        return false
    end
    
    local Data
    Success, Data = pcall(function()
        return HttpService:JSONDecode(Response.Body)
    end)
    
    if not Success then
        print("[TEST] FAILED to decode response:", Data)
        return false
    end
    
    if Data.error then
        print("[TEST] Server returned error:", Data.error)
        return false
    end
    
    print("[TEST] Successfully registered worker data!")
    print("[TEST] Response:", HttpService:JSONEncode(Data))
    return true, PrivateKey
end

-- Test retrieving worker data (as a worker would)
function OrchestratorTest:TestGetWorkerData(licenseKey: string, workerUserId: number)
    print("[TEST] Retrieving worker data...")
    
    local PrivateKey = self:GeneratePrivateKey(licenseKey, workerUserId)
    print("[TEST] Generated private key:", string.sub(PrivateKey, 1, 16) .. "...")
    
    local Url = string.format("%s/getWorkerData?userId=%d&key=%s", ORCHESTRATION_ENDPOINT, workerUserId, PrivateKey)
    
    local Success, Response = pcall(function()
        return SecureRequest.request({
            Method = "GET",
            Url = Url,
            Timeout = 5, -- Don't retry forever on expected failures
        })
    end)
    
    if not Success then
        -- Timeout or network error - this is expected for step 1
        print("[TEST] Request failed (expected for missing data):", tostring(Response):sub(1, 100))
        return nil
    end
    
    if not Response.Success then
        print("[TEST] Server returned error status:", Response.StatusCode, Response.StatusMessage)
        return nil
    end
    
    local Data
    Success, Data = pcall(function()
        return HttpService:JSONDecode(Response.Body)
    end)
    
    if not Success then
        print("[TEST] FAILED to decode response:", Data)
        return nil
    end
    
    if Data.error then
        print("[TEST] Server returned error:", Data.error)
        return nil
    end
    
    print("[TEST] Successfully retrieved worker data!")
    print("[TEST] Data:", HttpService:JSONEncode(Data))
    return Data
end

-- Run full test cycle
function OrchestratorTest:RunFullTest(licenseKey: string, testWorkerUserId: number?)
    print("=== ORCHESTRATOR TEST SUITE ===")
    print("")
    
    -- Use a test worker user ID if not provided
    local WorkerUserId = testWorkerUserId or 987654321
    
    print("[TEST] License Key:", string.sub(licenseKey, 1, 8) .. "...")
    print("[TEST] Worker UserId:", WorkerUserId)
    print("")
    
    -- Step 1: Try to get data before registration (should fail)
    print("--- Step 1: Get data before registration (expect failure) ---")
    local PreData = self:TestGetWorkerData(licenseKey, WorkerUserId)
    if PreData then
        print("[TEST] WARNING: Data already exists, might be from previous test")
    else
        print("[TEST] OK: No data found (expected)")
    end
    print("")
    
    -- Step 2: Register worker data
    print("--- Step 2: Register worker data ---")
    local RegisterSuccess = self:TestRegisterWorkerData(licenseKey, WorkerUserId)
    if not RegisterSuccess then
        print("[TEST] FAILED: Could not register worker data")
        return false
    end
    print("")
    
    -- Step 3: Retrieve worker data (should succeed now)
    print("--- Step 3: Get data after registration (expect success) ---")
    local PostData = self:TestGetWorkerData(licenseKey, WorkerUserId)
    if not PostData then
        print("[TEST] FAILED: Could not retrieve registered data")
        return false
    end
    print("")
    
    -- Verify data integrity
    print("--- Step 4: Verify data integrity ---")
    if PostData.master_user_id == 123456789 and PostData.transfer_threshold == 1000000 then
        print("[TEST] OK: Data integrity verified!")
    else
        print("[TEST] WARNING: Data mismatch!")
    end
    print("")
    
    print("=== TEST COMPLETE ===")
    return true
end

return OrchestratorTest

--[[
USAGE:
    local OrchestratorTest = require(path.to.OrchestratorTest)
    
    -- Run with your actual license key
    OrchestratorTest:RunFullTest("YOUR_LICENSE_KEY_HERE")
    
    -- Or with a specific worker user ID
    OrchestratorTest:RunFullTest("YOUR_LICENSE_KEY_HERE", 12345678)
    
    -- Or test individual functions
    OrchestratorTest:TestRegisterWorkerData("YOUR_LICENSE_KEY", 12345678)
    OrchestratorTest:TestGetWorkerData("YOUR_LICENSE_KEY", 12345678)
]]