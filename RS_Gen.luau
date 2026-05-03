--!nolint

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

	local Kalman = {}
	local RunService = game:GetService("RunService")
	local Players = game:GetService("Players")

	local Config = {
		-- How much you trust the measured velocity vs the filter's predicted velocity.
		-- Higher = more responsive, but can be jittery. Lower = smoother, but can lag on turns.
		VelocitySmoothingFactor = 1.0,

		ProcessNoise = {
			-- How much you expect the part's position to deviate from the physics model.
			-- Usually best to keep this low.
			Position = 0.1,

			-- How much you expect the part to suddenly accelerate or change direction.
			Acceleration = 0.9,
		},

		MeasurementNoise = {
			-- How much you trust the part's '.Position' property.
			-- Increase this if the predicted path seems noisy even with a slow-moving object.
			Position = 0.5,
		},
	}

	local TrackedParts = setmetatable({}, { __mode = "k" })
	local isUpdating = false

	local Matrix = {}
	function Matrix.Multiply(a, b)
		local aRows, aCols = #a, #a[1]
		local bRows, bCols = #b, #b[1]
		assert(aCols == bRows, "Matrix dimensions are incompatible for multiplication.")
		local result = {}
		for i = 1, aRows do
			result[i] = {}
			for j = 1, bCols do
				local sum = 0
				for k = 1, aCols do
					sum = sum + a[i][k] * b[k][j]
				end
				result[i][j] = sum
			end
		end
		return result
	end
	function Matrix.Add(a, b)
		local rows, cols = #a, #a[1]
		local result = {}
		for i = 1, rows do
			result[i] = {}
			for j = 1, cols do
				result[i][j] = a[i][j] + b[i][j]
			end
		end
		return result
	end
	function Matrix.Subtract(a, b)
		local rows, cols = #a, #a[1]
		local result = {}
		for i = 1, rows do
			result[i] = {}
			for j = 1, cols do
				result[i][j] = a[i][j] - b[i][j]
			end
		end
		return result
	end
	function Matrix.Transpose(m)
		local rows, cols = #m, #m[1]
		local result = {}
		for j = 1, cols do
			result[j] = {}
			for i = 1, rows do
				result[j][i] = m[i][j]
			end
		end
		return result
	end
	function Matrix.Invert3x3(m)
		local det = m[1][1] * (m[2][2] * m[3][3] - m[3][2] * m[2][3])
			- m[1][2] * (m[2][1] * m[3][3] - m[2][3] * m[3][1])
			+ m[1][3] * (m[2][1] * m[3][2] - m[2][2] * m[3][1])
		if det == 0 then
			return nil
		end
		local invDet = 1 / det
		local result = {
			{
				(m[2][2] * m[3][3] - m[3][2] * m[2][3]) * invDet,
				(m[1][3] * m[3][2] - m[1][2] * m[3][3]) * invDet,
				(m[1][2] * m[2][3] - m[1][3] * m[2][2]) * invDet,
			},
			{
				(m[2][3] * m[3][1] - m[2][1] * m[3][3]) * invDet,
				(m[1][1] * m[3][3] - m[1][3] * m[3][1]) * invDet,
				(m[2][1] * m[1][3] - m[1][1] * m[2][3]) * invDet,
			},
			{
				(m[2][1] * m[3][2] - m[3][1] * m[2][2]) * invDet,
				(m[3][1] * m[1][2] - m[1][1] * m[3][2]) * invDet,
				(m[1][1] * m[2][2] - m[2][1] * m[1][2]) * invDet,
			},
		}
		return result
	end

	local pNoisePos = Config.ProcessNoise.Position
	local pNoiseAcc = Config.ProcessNoise.Acceleration
	local mNoisePos = Config.MeasurementNoise.Position

	local Q = {
		{ pNoisePos, 0, 0, 0, 0, 0 },
		{ 0, pNoisePos, 0, 0, 0, 0 },
		{ 0, 0, pNoisePos, 0, 0, 0 },
		{ 0, 0, 0, pNoiseAcc, 0, 0 },
		{ 0, 0, 0, 0, pNoiseAcc, 0 },
		{ 0, 0, 0, 0, 0, pNoiseAcc },
	}
	local R = {
		{ mNoisePos, 0, 0 },
		{ 0, mNoisePos, 0 },
		{ 0, 0, mNoisePos },
	}
	local H = {
		{ 1, 0, 0, 0, 0, 0 },
		{ 0, 1, 0, 0, 0, 0 },
		{ 0, 0, 1, 0, 0, 0 },
	}
	local HT = Matrix.Transpose(H)
	local I6 = {
		{ 1, 0, 0, 0, 0, 0 },
		{ 0, 1, 0, 0, 0, 0 },
		{ 0, 0, 1, 0, 0, 0 },
		{ 0, 0, 0, 1, 0, 0 },
		{ 0, 0, 0, 0, 1, 0 },
		{ 0, 0, 0, 0, 0, 1 },
	}

	local function getTrackablePart(part: BasePart): BasePart
		-- if not part or not part.Parent then
		-- 	return part
		-- end
		-- local humanoid = part.Parent:FindFirstChildOfClass("Humanoid")
		-- if humanoid then
		-- 	if humanoid.Sit and humanoid.SeatPart then
		-- 		return humanoid.SeatPart
		-- 	end
		-- 	return part.Parent:FindFirstChild("HumanoidRootPart") or part
		-- end
		return part
	end

	local function updatePart(partData, dt, currentVelocity)
		local A = {
			{ 1, 0, 0, dt, 0, 0 },
			{ 0, 1, 0, 0, dt, 0 },
			{ 0, 0, 1, 0, 0, dt },
			{ 0, 0, 0, 1, 0, 0 },
			{ 0, 0, 0, 0, 1, 0 },
			{ 0, 0, 0, 0, 0, 1 },
		}
		local AT = Matrix.Transpose(A)

		partData.State = Matrix.Multiply(A, partData.State)
		partData.Covariance = Matrix.Add(Matrix.Multiply(Matrix.Multiply(A, partData.Covariance), AT), Q)

		local state = partData.State
		local alpha = Config.VelocitySmoothingFactor
		state[4][1] = (1 - alpha) * state[4][1] + alpha * currentVelocity.X
		state[5][1] = (1 - alpha) * state[5][1] + alpha * currentVelocity.Y
		state[6][1] = (1 - alpha) * state[6][1] + alpha * currentVelocity.Z

		local P_minus_HT = Matrix.Multiply(partData.Covariance, HT)
		local H_P_minus_HT = Matrix.Multiply(H, P_minus_HT)
		local H_P_minus_HT_plus_R = Matrix.Add(H_P_minus_HT, R)
		local inv_H_P_minus_HT_plus_R = Matrix.Invert3x3(H_P_minus_HT_plus_R)

		if not inv_H_P_minus_HT_plus_R then
			return
		end

		local K = Matrix.Multiply(P_minus_HT, inv_H_P_minus_HT_plus_R)

		local z = { { partData.Part.Position.X }, { partData.Part.Position.Y }, { partData.Part.Position.Z } }
		local H_x_hat = Matrix.Multiply(H, partData.State)
		local innovation = Matrix.Subtract(z, H_x_hat)
		partData.State = Matrix.Add(partData.State, Matrix.Multiply(K, innovation))

		local KH = Matrix.Multiply(K, H)
		local I_minus_KH = Matrix.Subtract(I6, KH)
		partData.Covariance = Matrix.Multiply(I_minus_KH, partData.Covariance)
	end

	local function onHeartbeat(dt: number)
		if dt == 0 then
			return
		end
		for part, data in pairs(TrackedParts) do
			if part.Parent then
				updatePart(data, dt, part.AssemblyLinearVelocity)
			else
				TrackedParts[part] = nil
			end
		end
	end

	local function startUpdater()
		if not isUpdating then
			RunService.Heartbeat:Connect(onHeartbeat)
			isUpdating = true
		end
	end

	function Kalman.RegisterPart(part: BasePart)
		local trackablePart = getTrackablePart(part)
		if TrackedParts[trackablePart] then
			return
		end
		startUpdater()
		local pos = trackablePart.Position
		local vel = trackablePart.AssemblyLinearVelocity
		TrackedParts[trackablePart] = {
			Part = trackablePart,
			State = { { pos.X }, { pos.Y }, { pos.Z }, { vel.X }, { vel.Y }, { vel.Z } },
			Covariance = {
				{ 500, 0, 0, 0, 0, 0 },
				{ 0, 500, 0, 0, 0, 0 },
				{ 0, 0, 500, 0, 0, 0 },
				{ 0, 0, 0, 500, 0, 0 },
				{ 0, 0, 0, 0, 500, 0 },
				{ 0, 0, 0, 0, 0, 500 },
			},
		}
	end

	function Kalman.GetPredictedPosition(part: BasePart): Vector3
		local trackablePart = getTrackablePart(part)
		local data = TrackedParts[trackablePart]

		if not data then
			warn("GetPredictedPosition called on a part not registered. Returning current position.")
			return trackablePart and trackablePart.Position or Vector3.new()
		end

		local localPlayer = Players.LocalPlayer
		if not localPlayer then
			warn("Cannot get LocalPlayer. Are you on the server?")
			return Vector3.new(data.State[1][1], data.State[2][1], data.State[3][1])
		end

		local ping = localPlayer:GetNetworkPing()
		local predictionTime = ping * 1.3

		local state = data.State
		local predictedX = state[1][1] + state[4][1] * predictionTime
		local predictedY = state[2][1] + state[5][1] * predictionTime
		local predictedZ = state[3][1] + state[6][1] * predictionTime

		local predictedPosition = Vector3.new(predictedX, predictedY, predictedZ)

		if trackablePart:IsA("Seat") or trackablePart:IsA("VehicleSeat") then
			if part.Parent and part:IsA("BasePart") then
				local offset = part.Position - trackablePart.Position
				predictedPosition = predictedPosition + offset
			end
		end

		return predictedPosition
	end

	return Kalman
end)()