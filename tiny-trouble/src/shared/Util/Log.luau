--!strict
--[[
	Log
	---
	Tiny structured logger. Every line is prefixed with the game name, the
	realm (Server/Client) and a module tag so output in the Studio console is
	easy to filter. Debug lines are only printed when verbose logging is on.
]]

local RunService = game:GetService("RunService")

local Log = {}

local realm = if RunService:IsServer() then "Server" else "Client"
local verbose = false

local function format(tag: string, message: string, ...: any): string
	local text = message
	if select("#", ...) > 0 then
		local ok, formatted = pcall(string.format, message, ...)
		text = if ok then formatted else message .. " " .. table.concat({ ... } :: any, " ")
	end
	return ("[TinyTrouble][%s][%s] %s"):format(realm, tag, text)
end

function Log.setVerbose(enabled: boolean)
	verbose = enabled
end

function Log.info(tag: string, message: string, ...: any)
	print(format(tag, message, ...))
end

function Log.debug(tag: string, message: string, ...: any)
	if verbose then
		print(format(tag, "(debug) " .. message, ...))
	end
end

function Log.warn(tag: string, message: string, ...: any)
	warn(format(tag, message, ...))
end

function Log.error(tag: string, message: string, ...: any)
	-- Reported as a warning with a traceback so a single bad call never kills a service loop.
	warn(format(tag, "ERROR " .. message, ...) .. "\n" .. debug.traceback("", 2))
end

return Log
