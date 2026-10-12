--!strict
--[[
	ResourceService
	---------------
	Spawns gatherable resource nodes at the layout's spawn points, validates
	every collection attempt and respawns nodes after a cooldown.

	Validation per attempt: node active, rate limit, living character, server
	side distance check, inventory capacity. Clients only ever trigger a
	ProximityPrompt; amounts and ids come from the server's own records.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local ResourceDefinitions = require(ReplicatedStorage.Shared.Config.ResourceDefinitions)
local Log = require(ReplicatedStorage.Shared.Util.Log)
local RateLimiter = require(ReplicatedStorage.Shared.Util.RateLimiter)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)
local ResourceNodeBuilder = require(script.Parent.Parent.World.ResourceNodeBuilder)
local InventoryService = require(script.Parent.InventoryService)
local NotificationService = require(script.Parent.NotificationService)
local PlayerService = require(script.Parent.PlayerService)
local WorldService = require(script.Parent.WorldService)

local TAG = "ResourceService"

local ResourceService = {}

type NodeRecord = {
	id: number,
	spawn: Types.ResourceSpawn,
	model: Model?,
	prompt: ProximityPrompt?,
	connection: RBXScriptConnection?,
	amount: number,
	active: boolean,
	respawnAt: number,
}

local nodes: { NodeRecord } = {}
local container: Folder? = nil
local random = Random.new()
local collectLimiter = RateLimiter.new(GameConfig.Net.CollectBurst, GameConfig.Net.CollectPerSecond)
local running = false

local function getContainer(): Folder
	local cached = container
	if cached then
		return cached
	end
	local kitchen = WorldService.getBuildResult().model
	local existing = kitchen:FindFirstChild("Resources")
	local resolved: Folder
	if existing and existing:IsA("Folder") then
		resolved = existing
	else
		resolved = Instance.new("Folder")
		resolved.Name = "Resources"
		resolved.Parent = kitchen
	end
	container = resolved
	return resolved
end

local onPromptTriggered: (Player, NodeRecord) -> ()

local function despawnNode(record: NodeRecord)
	if record.connection then
		record.connection:Disconnect()
		record.connection = nil
	end
	if record.model then
		record.model:Destroy()
		record.model = nil
	end
	record.prompt = nil
	record.active = false
	record.respawnAt = os.clock() + random:NextNumber(GameConfig.Resources.RespawnMin, GameConfig.Resources.RespawnMax)
end

local function spawnNode(record: NodeRecord)
	if record.active then
		return
	end
	record.amount = random:NextInteger(record.spawn.amountMin, record.spawn.amountMax)
	local model, prompt = ResourceNodeBuilder.build(record.id, record.spawn, record.amount, getContainer())
	record.model = model
	record.prompt = prompt
	record.active = true
	record.connection = prompt.Triggered:Connect(function(player)
		onPromptTriggered(player, record)
	end)
end

local function updatePromptText(record: NodeRecord)
	local prompt = record.prompt
	local definition = ResourceDefinitions.get(record.spawn.resourceId)
	if prompt and definition then
		prompt.ObjectText = if record.amount > 1
			then ("%s x%d"):format(definition.name, record.amount)
			else definition.name
	end
	if record.model then
		record.model:SetAttribute("Amount", record.amount)
	end
end

onPromptTriggered = function(player: Player, record: NodeRecord)
	if not record.active or not record.model then
		return
	end
	if not collectLimiter:Allow(player) then
		Log.debug(TAG, "Rate limited collect from %s", player.Name)
		return
	end

	local _, humanoid, root = PlayerService.getCharacterParts(player)
	if not humanoid or not root or humanoid.Health <= 0 then
		return
	end

	local hitbox = record.model.PrimaryPart
	if not hitbox then
		return
	end
	local maxDistance = GameConfig.Interaction.MaxDistance + GameConfig.Interaction.ServerDistanceTolerance
	if (root.Position - hitbox.Position).Magnitude > maxDistance then
		Log.debug(TAG, "Rejected out-of-range collect from %s", player.Name)
		return
	end

	local accepted = InventoryService.add(player, record.spawn.resourceId, record.amount)
	if accepted <= 0 then
		NotificationService.send(player, {
			title = "Pouch full",
			body = "You can't carry any more. (Backpack upgrades arrive with crafting.)",
			kind = "warning",
			duration = 3,
		})
		return
	end

	local payload: Types.ResourceCollectedPayload = {
		resourceId = record.spawn.resourceId,
		amount = accepted,
		position = hitbox.Position,
		nodeId = record.id,
		collectorUserId = player.UserId,
	}
	Remotes.getEvent(Remotes.Events.ResourceCollected):FireAllClients(payload)

	if accepted >= record.amount then
		despawnNode(record)
	else
		record.amount -= accepted
		updatePromptText(record)
	end
end

local function respawnLoop()
	while running do
		task.wait(GameConfig.Resources.RespawnTickInterval)
		local now = os.clock()
		for _, record in nodes do
			if not record.active and now >= record.respawnAt then
				local ok, err = pcall(spawnNode :: any, record)
				if not ok then
					Log.error(TAG, "Failed to respawn node %d: %s", record.id, tostring(err))
					record.respawnAt = now + 10
				end
			end
		end
	end
end

function ResourceService.Init()
	PlayerService.PlayerRemoving:Connect(function(player)
		collectLimiter:Forget(player)
	end)
end

function ResourceService.Start()
	local build = WorldService.getBuildResult()
	for index, spawn in build.resourceSpawns do
		local record: NodeRecord = {
			id = index,
			spawn = spawn,
			model = nil,
			prompt = nil,
			connection = nil,
			amount = 0,
			active = false,
			respawnAt = 0,
		}
		nodes[index] = record
		spawnNode(record)
	end
	running = true
	task.spawn(respawnLoop)
	Log.info(TAG, "Spawned %d resource nodes", #nodes)
end

function ResourceService.getActiveNodeCount(): number
	local count = 0
	for _, record in nodes do
		if record.active then
			count += 1
		end
	end
	return count
end

return ResourceService
