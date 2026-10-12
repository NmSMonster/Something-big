--!strict
--[[
	ObjectiveService
	----------------
	Tracks each player's progress through the foundation objective chain,
	grants rewards and keeps the client's tracker in sync.

	"collect" objectives listen to InventoryService.ResourceAdded.
	"reach" objectives poll zone membership twice per second (cheap: one
	PointToObjectSpace per player).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ObjectiveDefinitions = require(ReplicatedStorage.Shared.Config.ObjectiveDefinitions)
local ResourceDefinitions = require(ReplicatedStorage.Shared.Config.ResourceDefinitions)
local Log = require(ReplicatedStorage.Shared.Util.Log)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)
local InventoryService = require(script.Parent.InventoryService)
local NotificationService = require(script.Parent.NotificationService)
local PlayerService = require(script.Parent.PlayerService)
local WorldService = require(script.Parent.WorldService)

local TAG = "ObjectiveService"
local ZONE_POLL_INTERVAL = 0.5

local ObjectiveService = {}

type Progress = {
	index: number,
	progress: number,
}

local progressByPlayer: { [Player]: Progress } = {}
local zonesById: { [string]: Types.Zone } = {}
local running = false

local function getOrCreate(player: Player): Progress
	local progress = progressByPlayer[player]
	if not progress then
		progress = { index = 1, progress = 0 }
		progressByPlayer[player] = progress
	end
	return progress
end

local function buildState(progress: Progress, completedId: string?): Types.ObjectiveState
	local definition = ObjectiveDefinitions.get(progress.index)
	return {
		index = progress.index,
		progress = progress.progress,
		target = if definition then definition.target else 0,
		completedId = completedId,
		allComplete = definition == nil,
	}
end

local function sendState(player: Player, progress: Progress, completedId: string?)
	Remotes.getEvent(Remotes.Events.ObjectiveUpdate):FireClient(player, buildState(progress, completedId))
end

local function describeRewards(rewards: { ObjectiveDefinitions.ObjectiveReward }): string
	local parts = {}
	for _, reward in rewards do
		local definition = ResourceDefinitions.get(reward.resourceId)
		local name = if definition
			then (if reward.amount > 1 then definition.plural else definition.name)
			else reward.resourceId
		table.insert(parts, ("%d %s"):format(reward.amount, name))
	end
	return table.concat(parts, ", ")
end

local function completeCurrent(player: Player, progress: Progress)
	local definition = ObjectiveDefinitions.get(progress.index)
	if not definition then
		return
	end

	for _, reward in definition.rewards do
		InventoryService.add(player, reward.resourceId, reward.amount)
	end

	NotificationService.send(player, {
		title = "Objective complete",
		body = if #definition.rewards > 0
			then ("%s  •  Reward: %s"):format(definition.title, describeRewards(definition.rewards))
			else definition.title,
		kind = "objective",
		duration = 5,
	})
	if definition.completionMessage then
		NotificationService.send(player, {
			title = "Discovery",
			body = definition.completionMessage,
			kind = "info",
			duration = 9,
		})
	end

	progress.index += 1
	progress.progress = 0
	sendState(player, progress, definition.id)
	Log.info(TAG, "%s completed objective '%s'", player.Name, definition.id)

	if not ObjectiveDefinitions.get(progress.index) then
		NotificationService.send(player, {
			title = "Foundation complete",
			body = "You have mastered the kitchen. Crafting, quests and the cat arrive in the next update.",
			kind = "success",
			duration = 8,
		})
	end
end

local function onResourceAdded(player: Player, resourceId: string, amount: number)
	local progress = getOrCreate(player)
	local definition = ObjectiveDefinitions.get(progress.index)
	if not definition or definition.kind ~= "collect" or definition.resourceId ~= resourceId then
		return
	end
	progress.progress = math.min(definition.target, progress.progress + amount)
	if progress.progress >= definition.target then
		completeCurrent(player, progress)
	else
		sendState(player, progress, nil)
	end
end

local function isInsideZone(zone: Types.Zone, position: Vector3): boolean
	local localPosition = zone.cframe:PointToObjectSpace(position)
	local half = zone.size / 2
	return math.abs(localPosition.X) <= half.X
		and math.abs(localPosition.Y) <= half.Y
		and math.abs(localPosition.Z) <= half.Z
end

local function pollZones()
	for player, progress in progressByPlayer do
		local definition = ObjectiveDefinitions.get(progress.index)
		if not definition or definition.kind ~= "reach" or not definition.zoneId then
			continue
		end
		local zone = zonesById[definition.zoneId :: string]
		if not zone then
			continue
		end
		local _, humanoid, root = PlayerService.getCharacterParts(player)
		if not humanoid or not root or humanoid.Health <= 0 then
			continue
		end
		if isInsideZone(zone, root.Position) then
			progress.progress = definition.target
			completeCurrent(player, progress)
		end
	end
end

local function zoneLoop()
	while running do
		task.wait(ZONE_POLL_INTERVAL)
		local ok, err = pcall(pollZones :: any)
		if not ok then
			Log.error(TAG, "zone poll failed: %s", tostring(err))
		end
	end
end

function ObjectiveService.Init()
	PlayerService.PlayerAdded:Connect(function(player)
		getOrCreate(player)
	end)
	PlayerService.PlayerRemoving:Connect(function(player)
		progressByPlayer[player] = nil
	end)
	InventoryService.ResourceAdded:Connect(onResourceAdded)
end

function ObjectiveService.Start()
	for _, zone in WorldService.getBuildResult().zones do
		zonesById[zone.id] = zone
	end
	running = true
	task.spawn(zoneLoop)
end

function ObjectiveService.getState(player: Player): Types.ObjectiveState
	return buildState(getOrCreate(player), nil)
end

return ObjectiveService
