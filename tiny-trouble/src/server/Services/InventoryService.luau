--!strict
--[[
	InventoryService
	----------------
	Server-authoritative resource pouch. Milestone 1 tracks stack counts and a
	total capacity; Milestone 2 layers slots, equipment and crafting on top of
	the same API. Every change is pushed to the owning client as a snapshot.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local ResourceDefinitions = require(ReplicatedStorage.Shared.Config.ResourceDefinitions)
local Log = require(ReplicatedStorage.Shared.Util.Log)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local Types = require(ReplicatedStorage.Shared.Types)
local PlayerService = require(script.Parent.PlayerService)

local TAG = "InventoryService"

local InventoryService = {}

InventoryService.ResourceAdded = Signal.new() :: Signal.Signal<Player, string, number>
InventoryService.Changed = Signal.new() :: Signal.Signal<Player, Types.InventorySnapshot>

type Inventory = {
	counts: { [string]: number },
	total: number,
	capacity: number,
}

local inventories: { [Player]: Inventory } = {}

local function getOrCreate(player: Player): Inventory
	local inventory = inventories[player]
	if not inventory then
		inventory = {
			counts = {},
			total = 0,
			capacity = GameConfig.Inventory.Capacity,
		}
		inventories[player] = inventory
	end
	return inventory
end

local function snapshot(inventory: Inventory): Types.InventorySnapshot
	return {
		counts = table.clone(inventory.counts),
		total = inventory.total,
		capacity = inventory.capacity,
	}
end

local function pushUpdate(player: Player, inventory: Inventory)
	local state = snapshot(inventory)
	Remotes.getEvent(Remotes.Events.InventoryUpdate):FireClient(player, state)
	InventoryService.Changed:Fire(player, state)
end

function InventoryService.Init()
	PlayerService.PlayerAdded:Connect(function(player)
		getOrCreate(player)
	end)
	PlayerService.PlayerRemoving:Connect(function(player)
		inventories[player] = nil
	end)
end

function InventoryService.getSnapshot(player: Player): Types.InventorySnapshot
	return snapshot(getOrCreate(player))
end

function InventoryService.getCount(player: Player, resourceId: string): number
	return getOrCreate(player).counts[resourceId] or 0
end

function InventoryService.getFreeSpace(player: Player): number
	local inventory = getOrCreate(player)
	return math.max(0, inventory.capacity - inventory.total)
end

--[[
	Adds up to `amount` of a resource. Returns how many were actually accepted
	(0 when the pouch is full or the id is invalid).
]]
function InventoryService.add(player: Player, resourceId: string, amount: number): number
	if not ResourceDefinitions.isValidId(resourceId) then
		Log.warn(TAG, "Rejected unknown resource '%s' for %s", tostring(resourceId), player.Name)
		return 0
	end
	if amount <= 0 or amount ~= amount then
		return 0
	end
	amount = math.floor(amount)

	local inventory = getOrCreate(player)
	local accepted = math.min(amount, inventory.capacity - inventory.total)
	if accepted <= 0 then
		return 0
	end

	inventory.counts[resourceId] = (inventory.counts[resourceId] or 0) + accepted
	inventory.total += accepted
	pushUpdate(player, inventory)
	InventoryService.ResourceAdded:Fire(player, resourceId, accepted)
	Log.debug(TAG, "%s +%d %s (total %d/%d)", player.Name, accepted, resourceId, inventory.total, inventory.capacity)
	return accepted
end

--[[
	Removes `amount` of a resource if the player has enough. Returns success.
	(Used by crafting in Milestone 2.)
]]
function InventoryService.remove(player: Player, resourceId: string, amount: number): boolean
	local inventory = getOrCreate(player)
	local current = inventory.counts[resourceId] or 0
	if amount <= 0 or current < amount then
		return false
	end
	local remaining = current - amount
	if remaining > 0 then
		inventory.counts[resourceId] = remaining
	else
		inventory.counts[resourceId] = nil
	end
	inventory.total -= amount
	pushUpdate(player, inventory)
	return true
end

return InventoryService
