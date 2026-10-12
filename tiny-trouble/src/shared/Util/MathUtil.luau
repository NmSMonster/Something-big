--!strict
--[[
	MathUtil
	--------
	Small numeric helpers shared by camera, HUD and gameplay code.
]]

local MathUtil = {}

function MathUtil.lerp(a: number, b: number, alpha: number): number
	return a + (b - a) * alpha
end

--[[
	Frame-rate independent exponential smoothing.
	`speed` is roughly "how many times per second we close the remaining gap".
]]
function MathUtil.smooth(current: number, target: number, speed: number, dt: number): number
	local alpha = 1 - math.exp(-speed * dt)
	return current + (target - current) * alpha
end

function MathUtil.smoothVector(current: Vector3, target: Vector3, speed: number, dt: number): Vector3
	local alpha = 1 - math.exp(-speed * dt)
	return current:Lerp(target, alpha)
end

function MathUtil.clamp01(value: number): number
	return math.clamp(value, 0, 1)
end

function MathUtil.round(value: number, decimals: number?): number
	local factor = 10 ^ (decimals or 0)
	return math.floor(value * factor + 0.5) / factor
end

function MathUtil.approximately(a: number, b: number, epsilon: number?): boolean
	return math.abs(a - b) <= (epsilon or 1e-4)
end

function MathUtil.isFinite(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

--[[
	Maps a value from one range to another, clamped to the target range.
]]
function MathUtil.map(value: number, inMin: number, inMax: number, outMin: number, outMax: number): number
	if inMax == inMin then
		return outMin
	end
	local alpha = math.clamp((value - inMin) / (inMax - inMin), 0, 1)
	return outMin + (outMax - outMin) * alpha
end

return MathUtil
