--!strict
--[[
	Client bootstrap
	----------------
	Loads the client state store, then every controller in dependency order
	(Init on all, then Start on all), requests the initial state from the
	server and reports ClientReady. Runs from StarterPlayerScripts.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Log = require(ReplicatedStorage.Shared.Util.Log)

local TAG = "Bootstrap"

type Controller = {
	Init: (() -> ())?,
	Start: (() -> ())?,
}

local CONTROLLER_ORDER = {
	"AudioController",
	"InputController",
	"CameraController",
	"MovementController",
	"InteractionController",
	"HudController",
	"MenuController",
	"EffectsController",
}

local player = Players.LocalPlayer
local startedAt = os.clock()

Log.setVerbose(GameConfig.Debug.VerboseLogging)

local ClientState = require(script.State.ClientState)
local controllersFolder = script:WaitForChild("Controllers")

local controllers: { { name: string, controller: Controller } } = {}
for _, name in CONTROLLER_ORDER do
	local module = controllersFolder:FindFirstChild(name)
	if not module or not module:IsA("ModuleScript") then
		Log.error(TAG, "Controller '%s' is missing", name)
		continue
	end
	local ok, result = pcall(require, module)
	if ok and typeof(result) == "table" then
		table.insert(controllers, { name = name, controller = result :: Controller })
	else
		task.spawn(error, ("[TinyTrouble] Failed to load controller %s: %s"):format(name, tostring(result)))
	end
end

local function runPhase(phase: "Init" | "Start")
	for _, entry in controllers do
		local callback = entry.controller[phase]
		if typeof(callback) ~= "function" then
			continue
		end
		local ok, err = pcall(callback)
		if not ok then
			task.spawn(error, ("[TinyTrouble] %s.%s failed: %s"):format(entry.name, phase, tostring(err)))
		end
	end
end

ClientState.Init()
runPhase("Init")
ClientState.Start()
runPhase("Start")

-- Local-only attribute (set on the client) that the loading screen waits for.
-- ClientReady is sent by MenuController the first time the player presses Play.
player:SetAttribute("TT_ClientLoaded", true)

Log.info(TAG, "Client ready in %.0f ms (%d controllers)", (os.clock() - startedAt) * 1000, #controllers)
