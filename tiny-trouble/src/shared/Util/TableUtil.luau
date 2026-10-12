--!strict
--[[
	TableUtil
	---------
	Table helpers used for state snapshots and config handling.
]]

local TableUtil = {}

function TableUtil.shallowCopy<T>(source: T & {}): T
	return table.clone(source :: any) :: any
end

function TableUtil.deepCopy<T>(source: T): T
	if typeof(source) ~= "table" then
		return source
	end
	local copy = {}
	for key, value in pairs(source :: any) do
		copy[key] = TableUtil.deepCopy(value)
	end
	return copy :: any
end

function TableUtil.count(source: { [any]: any }): number
	local total = 0
	for _ in pairs(source) do
		total += 1
	end
	return total
end

function TableUtil.isEmpty(source: { [any]: any }): boolean
	return next(source) == nil
end

function TableUtil.keys<K, V>(source: { [K]: V }): { K }
	local result = {}
	for key in pairs(source) do
		table.insert(result, key)
	end
	return result
end

--[[
	Returns a new table with `overrides` merged on top of `defaults` (one level deep).
]]
function TableUtil.merge<T>(defaults: T & {}, overrides: { [any]: any }?): T
	local result = table.clone(defaults :: any)
	if overrides then
		for key, value in pairs(overrides) do
			result[key] = value
		end
	end
	return result :: any
end

return TableUtil
