--!strict
--[[
	KitchenGenerator
	----------------
	Orchestrates the procedural kitchen: structure, furniture, props,
	climbing routes, spawn points and objective zones. Returns a build result
	that gameplay services consume (resource spawn points, zones, spawns).

	Everything is anchored primitive geometry, so the whole kitchen is built
	synchronously at server start in well under a second.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Log = require(ReplicatedStorage.Shared.Util.Log)
local Tags = require(ReplicatedStorage.Shared.Tags)
local Types = require(ReplicatedStorage.Shared.Types)
local PartBuilder = require(script.Parent.PartBuilder)
local Layout = require(script.Parent.Kitchen.Layout)
local Structure = require(script.Parent.Kitchen.Structure)
local Furniture = require(script.Parent.Kitchen.Furniture)
local Props = require(script.Parent.Kitchen.Props)
local Climbables = require(script.Parent.Kitchen.Climbables)

local TAG = "KitchenGenerator"

local KitchenGenerator = {}

local function buildSpawns(parent: Instance, spawnCFrames: { CFrame })
	local folder = PartBuilder.folder("Spawns", parent)
	for index, cframe in spawnCFrames do
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = ("Spawn%d"):format(index)
		spawn.Size = Vector3.new(6, 1, 6)
		spawn.CFrame = cframe
		spawn.Anchored = true
		spawn.CanCollide = false
		spawn.CanQuery = false
		spawn.Transparency = 1
		spawn.Neutral = true
		spawn.AllowTeamChangeOnTouch = false
		spawn.Duration = 0 -- no spawn forcefield; it looks wrong at miniature scale
		spawn.Enabled = true
		spawn.Parent = folder
	end
end

local function buildZones(parent: Instance, zones: { Types.Zone })
	-- Invisible, non-colliding volumes. Useful for debugging in Studio (toggle Transparency).
	local folder = PartBuilder.folder("Zones", parent)
	for _, zone in zones do
		PartBuilder.part({
			Name = zone.id,
			Size = zone.size,
			CFrame = zone.cframe,
			Transparency = 1,
			CanCollide = false,
			CanQuery = false,
			CastShadow = false,
			Parent = folder,
			Tags = { Tags.Zone },
			Attributes = { ZoneId = zone.id },
		})
	end
end

function KitchenGenerator.build(parent: Instance): Types.KitchenBuildResult
	local started = os.clock()

	local existing = parent:FindFirstChild("Kitchen")
	if existing then
		existing:Destroy()
	end

	local kitchen = PartBuilder.model("Kitchen", nil)
	CollectionService:AddTag(kitchen, Tags.Kitchen)

	Structure.build(kitchen)
	Furniture.build(kitchen)
	Props.build(kitchen)
	Climbables.build(kitchen)

	local spawnCFrames = Layout.getSpawnCFrames()
	local zones = Layout.getZones()
	buildSpawns(kitchen, spawnCFrames)
	buildZones(kitchen, zones)
	PartBuilder.folder("Resources", kitchen)

	kitchen.Parent = parent

	local partCount = 0
	for _, descendant in kitchen:GetDescendants() do
		if descendant:IsA("BasePart") then
			partCount += 1
		end
	end
	Log.info(TAG, "Kitchen built: %d parts in %.0f ms", partCount, (os.clock() - started) * 1000)

	return {
		model = kitchen,
		spawnCFrames = spawnCFrames,
		resourceSpawns = Layout.getResourceSpawns(),
		zones = zones,
	}
end

return KitchenGenerator
