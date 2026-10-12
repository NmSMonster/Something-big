--!strict
--[[
	SessionService
	--------------
	Handles the client/server handshake: the client asks for its initial
	state once its controllers are ready, then reports ClientReady so the
	server can welcome it. Rate limited and validated like every remote.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Log = require(ReplicatedStorage.Shared.Util.Log)
local RateLimiter = require(ReplicatedStorage.Shared.Util.RateLimiter)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)
local InventoryService = require(script.Parent.InventoryService)
local NotificationService = require(script.Parent.NotificationService)
local ObjectiveService = require(script.Parent.ObjectiveService)
local PlayerService = require(script.Parent.PlayerService)

local TAG = "SessionService"

local SessionService = {}

local initialStateLimiter = RateLimiter.new(GameConfig.Net.InitialStateBurst, GameConfig.Net.InitialStatePerSecond)
local readyPlayers: { [Player]: boolean } = {}

local function buildInitialState(player: Player): Types.InitialState
	return {
		inventory = InventoryService.getSnapshot(player),
		objective = ObjectiveService.getState(player),
		serverVersion = GameConfig.Version,
	}
end

function SessionService.Init()
	PlayerService.PlayerRemoving:Connect(function(player)
		readyPlayers[player] = nil
		initialStateLimiter:Forget(player)
	end)
end

function SessionService.Start()
	Remotes.getFunction(Remotes.Functions.GetInitialState).OnServerInvoke = function(player: Player)
		if not initialStateLimiter:Allow(player) then
			Log.warn(TAG, "%s requested initial state too often", player.Name)
			return nil
		end
		return buildInitialState(player)
	end

	Remotes.getEvent(Remotes.Events.ClientReady).OnServerEvent:Connect(function(player)
		if readyPlayers[player] then
			return
		end
		readyPlayers[player] = true
		player:SetAttribute("ClientReady", true)
		Log.info(TAG, "%s client ready", player.Name)
		NotificationService.send(player, {
			title = "Welcome to the kitchen",
			body = "You are 2 cm tall. Explore, gather what you can carry and find a way up.",
			kind = "info",
			duration = 7,
		})
	end)
end

return SessionService
