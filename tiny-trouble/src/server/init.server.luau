--!strict
--[[
	Server bootstrap
	----------------
	Creates the remotes, then loads every service in dependency order and runs
	Init() on all of them before Start() on all of them. A service that fails
	is reported loudly (red error in the output) without stopping the others.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Log = require(ReplicatedStorage.Shared.Util.Log)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)

local TAG = "Bootstrap"

type Service = {
	Init: (() -> ())?,
	Start: (() -> ())?,
}

local SERVICE_ORDER = {
	"WorldService",
	"PlayerService",
	"NotificationService",
	"InventoryService",
	"StatsService",
	"ResourceService",
	"ObjectiveService",
	"SessionService",
}

local startedAt = os.clock()

Log.setVerbose(GameConfig.Debug.VerboseLogging)
Log.info(TAG, "Starting %s server %s", GameConfig.GameName, GameConfig.Version)

Remotes.initServer()

local servicesFolder = script:WaitForChild("Services")
local services: { { name: string, service: Service } } = {}

for _, name in SERVICE_ORDER do
	local module = servicesFolder:FindFirstChild(name)
	if not module or not module:IsA("ModuleScript") then
		Log.error(TAG, "Service module '%s' is missing", name)
		continue
	end

	local ok, result = pcall(require, module)
	if ok and typeof(result) == "table" then
		table.insert(services, { name = name, service = result :: Service })
	else
		task.spawn(error, ("[TinyTrouble] Failed to load service %s: %s"):format(name, tostring(result)))
	end
end

local function runPhase(phase: "Init" | "Start")
	for _, entry in services do
		local callback = entry.service[phase]
		if typeof(callback) ~= "function" then
			continue
		end
		local phaseStart = os.clock()
		local ok, err = pcall(callback)
		if ok then
			Log.debug(TAG, "%s.%s done in %.1f ms", entry.name, phase, (os.clock() - phaseStart) * 1000)
		else
			task.spawn(error, ("[TinyTrouble] %s.%s failed: %s"):format(entry.name, phase, tostring(err)))
		end
	end
end

runPhase("Init")
runPhase("Start")

Log.info(TAG, "Server ready in %.0f ms (%d services)", (os.clock() - startedAt) * 1000, #services)
