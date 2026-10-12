--!strict
--[[
	Validate
	--------
	Type guards for data that crosses the network. Server code must never trust
	a remote payload without running it through one of these.
]]

local Validate = {}

function Validate.isBoolean(value: unknown): boolean
	return typeof(value) == "boolean"
end

function Validate.isFiniteNumber(value: unknown): boolean
	if typeof(value) ~= "number" then
		return false
	end
	local number = value :: number
	return number == number and number ~= math.huge and number ~= -math.huge
end

function Validate.isNumberInRange(value: unknown, min: number, max: number): boolean
	if not Validate.isFiniteNumber(value) then
		return false
	end
	local number = value :: number
	return number >= min and number <= max
end

function Validate.isInteger(value: unknown, min: number?, max: number?): boolean
	if not Validate.isFiniteNumber(value) then
		return false
	end
	local number = value :: number
	if number % 1 ~= 0 then
		return false
	end
	if min and number < min then
		return false
	end
	if max and number > max then
		return false
	end
	return true
end

function Validate.isString(value: unknown, maxLength: number?): boolean
	if typeof(value) ~= "string" then
		return false
	end
	if maxLength and #(value :: string) > maxLength then
		return false
	end
	return true
end

function Validate.isVector3(value: unknown): boolean
	if typeof(value) ~= "Vector3" then
		return false
	end
	local vector = value :: Vector3
	return Validate.isFiniteNumber(vector.X) and Validate.isFiniteNumber(vector.Y) and Validate.isFiniteNumber(vector.Z)
end

function Validate.isTable(value: unknown): boolean
	return typeof(value) == "table"
end

return Validate
