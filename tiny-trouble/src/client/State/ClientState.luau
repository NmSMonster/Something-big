--!strict
--[[
	ClientState
	-----------
	The client's single source of truth for replicated gameplay state
	(inventory, objective), local settings and session flags. Controllers
	subscribe to its signals instead of talking to each other directly.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local ObjectiveDefinitions = require(ReplicatedStorage.Shared.Config.ObjectiveDefinitions)
local Log = require(ReplicatedStorage.Shared.Util.Log)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local Types = require(ReplicatedStorage.Shared.Types)

local TAG = "ClientState"

local ClientState = {}

export type Settings = {
	sensitivity: number,
	fov: number,
	invertY: boolean,
	shoulderSide: number, -- 1 = right shoulder, -1 = left shoulder
	showControlsHint: boolean,
}

ClientState.settings = {
	sensitivity = 1,
	fov = GameConfig.Camera.DefaultFov,
	invertY = false,
	shoulderSide = 1,
	showControlsHint = true,
} :: Settings

ClientState.inventory = {
	counts = {},
	total = 0,
	capacity = GameConfig.Inventory.Capacity,
} :: Types.InventorySnapshot

ClientState.objective = {
	index = 1,
	progress = 0,
	target = if ObjectiveDefinitions.List[1] then ObjectiveDefinitions.List[1].target else 0,
	completedId = nil,
	allComplete = false,
} :: Types.ObjectiveState

ClientState.isPlaying = false
ClientState.hasPlayed = false
ClientState.isSprinting = false
ClientState.isCrouching = false
ClientState.serverVersion = "?"

ClientState.InventoryChanged = Signal.new() :: Signal.Signal<Types.InventorySnapshot>
ClientState.ObjectiveChanged = Signal.new() :: Signal.Signal<Types.ObjectiveState>
ClientState.SettingsChanged = Signal.new() :: Signal.Signal<Settings>
ClientState.PlayingChanged = Signal.new() :: Signal.Signal<boolean>
ClientState.MovementChanged = Signal.new() :: Signal.Signal<boolean, boolean>
ClientState.InitialStateLoaded = Signal.new() :: Signal.Signal<>

local function isInventorySnapshot(value: unknown): boolean
	if typeof(value) ~= "table" then
		return false
	end
	local snapshot = value :: any
	return typeof(snapshot.counts) == "table"
		and typeof(snapshot.total) == "number"
		and typeof(snapshot.capacity) == "number"
end

local function isObjectiveState(value: unknown): boolean
	if typeof(value) ~= "table" then
		return false
	end
	local state = value :: any
	return typeof(state.index) == "number" and typeof(state.progress) == "number" and typeof(state.target) == "number"
end

function ClientState.setInventory(snapshot: Types.InventorySnapshot)
	if not isInventorySnapshot(snapshot) then
		Log.warn(TAG, "Ignored malformed inventory snapshot")
		return
	end
	ClientState.inventory = snapshot
	ClientState.InventoryChanged:Fire(snapshot)
end

function ClientState.setObjective(state: Types.ObjectiveState)
	if not isObjectiveState(state) then
		Log.warn(TAG, "Ignored malformed objective state")
		return
	end
	ClientState.objective = state
	ClientState.ObjectiveChanged:Fire(state)
end

function ClientState.updateSettings(partial: { [string]: any })
	local settings = ClientState.settings :: any
	for key, value in partial do
		settings[key] = value
	end
	ClientState.SettingsChanged:Fire(ClientState.settings)
end

function ClientState.setPlaying(playing: boolean)
	if ClientState.isPlaying == playing then
		return
	end
	ClientState.isPlaying = playing
	if playing then
		ClientState.hasPlayed = true
	end
	ClientState.PlayingChanged:Fire(playing)
end

function ClientState.setMovement(sprinting: boolean, crouching: boolean)
	if ClientState.isSprinting == sprinting and ClientState.isCrouching == crouching then
		return
	end
	ClientState.isSprinting = sprinting
	ClientState.isCrouching = crouching
	ClientState.MovementChanged:Fire(sprinting, crouching)
end

function ClientState.getInventoryCount(resourceId: string): number
	return ClientState.inventory.counts[resourceId] or 0
end

local function requestInitialState()
	local remote = Remotes.getFunction(Remotes.Functions.GetInitialState)
	for attempt = 1, 4 do
		local ok, result = pcall(function()
			return remote:InvokeServer()
		end)
		if ok and typeof(result) == "table" then
			local state = result :: Types.InitialState
			if isInventorySnapshot(state.inventory) then
				ClientState.setInventory(state.inventory)
			end
			if isObjectiveState(state.objective) then
				ClientState.setObjective(state.objective)
			end
			if typeof(state.serverVersion) == "string" then
				ClientState.serverVersion = state.serverVersion
			end
			ClientState.InitialStateLoaded:Fire()
			Log.debug(TAG, "Initial state loaded (server %s)", ClientState.serverVersion)
			return
		end
		Log.warn(TAG, "Initial state request failed (attempt %d): %s", attempt, tostring(result))
		task.wait(attempt * 1.5)
	end
end

function ClientState.Init()
	Remotes.getEvent(Remotes.Events.InventoryUpdate).OnClientEvent:Connect(function(snapshot)
		ClientState.setInventory(snapshot)
	end)
	Remotes.getEvent(Remotes.Events.ObjectiveUpdate).OnClientEvent:Connect(function(state)
		ClientState.setObjective(state)
	end)
end

function ClientState.Start()
	task.spawn(requestInitialState)
end

return ClientState
