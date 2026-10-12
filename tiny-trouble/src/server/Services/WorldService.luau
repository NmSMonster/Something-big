--!strict
--[[
	WorldService
	------------
	Owns the world: applies lighting and builds the procedural kitchen at
	server start. Other services read the build result (spawn points,
	resource spawns, zones) from here.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Log = require(ReplicatedStorage.Shared.Util.Log)
local Types = require(ReplicatedStorage.Shared.Types)
local KitchenGenerator = require(script.Parent.Parent.World.KitchenGenerator)
local LightingSetup = require(script.Parent.Parent.World.LightingSetup)

local TAG = "WorldService"

local WorldService = {}

local buildResult: Types.KitchenBuildResult? = nil

--[[
	The Studio "Baseplate" template ships a Baseplate and a SpawnLocation.
	Remove them so players always spawn under the kitchen table.
]]
local function removeTemplateLeftovers(kitchen: Model)
	for _, child in workspace:GetChildren() do
		if child == kitchen then
			continue
		end
		if child.Name == "Baseplate" and child:IsA("BasePart") then
			child:Destroy()
		elseif child:IsA("SpawnLocation") then
			child:Destroy()
		end
	end
end

function WorldService.Init()
	LightingSetup.apply()
	local result = KitchenGenerator.build(workspace)
	removeTemplateLeftovers(result.model)
	buildResult = result
	Log.info(
		TAG,
		"World ready: %d spawn points, %d resource spawns, %d zones",
		#result.spawnCFrames,
		#result.resourceSpawns,
		#result.zones
	)
end

function WorldService.getBuildResult(): Types.KitchenBuildResult
	local result = buildResult
	assert(result, "WorldService has not built the world yet")
	return result
end

return WorldService
