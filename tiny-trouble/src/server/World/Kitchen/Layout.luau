--!strict
--[[
	Layout
	------
	The kitchen floor plan in CENTIMETRES. Everything else in the generator
	reads positions from here, so moving a piece of furniture is a one-line
	change. The room is centred on the world origin with the floor at Y = 0.

	Axis conventions (top-down view):
	  -Z = north wall (counter, sink, window, fridge)
	  +Z = south wall (second window)
	  -X = west wall (door to the living room)
	  +X = east wall (trash can, pet bowls, potted plant)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Scale = require(ReplicatedStorage.Shared.Scale)
local Types = require(ReplicatedStorage.Shared.Types)

local Layout = {}

Layout.Room = {
	Width = 360, -- X
	Depth = 300, -- Z
	Height = 250, -- Y
	WallThickness = 12,
	TileSize = 30,
	BaseboardHeight = 8,
}

Layout.Counter = {
	XMin = -180,
	XMax = 40,
	ZMin = -150, -- wall
	ZMax = -90, -- cabinet front
	TopZMax = -88, -- countertop overhangs the front by 2 cm
	CabinetHeight = 82,
	TopThickness = 4,
	Height = 86, -- top surface
	KickHeight = 10,
	BacksplashHeight = 110,
}

Layout.Stove = {
	XMin = -180,
	XMax = -120,
	HandleY = 70,
	HandleZ = -87,
}

Layout.Sink = {
	XMin = -52.5,
	XMax = -7.5,
	ZMin = -140,
	ZMax = -100,
	Depth = 18,
	WaterDepth = 6.5,
}

Layout.Fridge = {
	XMin = 75,
	XMax = 145,
	ZMin = -146,
	ZMax = -80,
	Height = 175,
	FreezerSplitY = 120,
	WallGap = 4, -- hidden passage behind the fridge
}

Layout.Table = {
	CenterX = -40,
	CenterZ = 60,
	Width = 120, -- X
	Depth = 80, -- Z
	Height = 75, -- top surface
	TopThickness = 4,
	LegSize = 5,
	LegInset = 8,
	ClothThickness = 0.6,
}

Layout.Chairs = {
	-- yaw: direction the seated person faces (chair back is opposite)
	{ x = -70, z = 2, facing = 1, climbRoute = true }, -- north-west, faces +Z
	{ x = -10, z = 2, facing = 1, climbRoute = false }, -- north-east
	{ x = -70, z = 118, facing = -1, climbRoute = false }, -- south-west, faces -Z
	{ x = -10, z = 118, facing = -1, climbRoute = true }, -- south-east
}

Layout.Chair = {
	SeatSize = 40,
	SeatHeight = 42,
	SeatThickness = 4,
	LegSize = 4,
	LegInset = 16,
	BackHeight = 92,
}

Layout.StepStool = {
	CenterX = 25,
	CenterZ = -72, -- its back edge touches the countertop overhang (Z = -88)
	Width = 40,
	Depth = 30,
	StepHeights = { 22, 45 },
}

Layout.Windows = {
	North = { xMin = -70, xMax = 10, yMin = 110, yMax = 200 },
	South = { xMin = 60, xMax = 160, yMin = 100, yMax = 200 },
}

Layout.Door = {
	ZMin = 20,
	ZMax = 110,
	Height = 200,
	Thickness = 4,
	FloorGap = 1.5,
}

Layout.Rug = { XMin = -110, XMax = 0, ZMin = -85, ZMax = -35, Thickness = 0.8 }

Layout.Trash = { x = 162, z = -118, radius = 14, height = 55 }
Layout.Plant = { x = 160, z = 125, potRadius = 14, potHeight = 24 }
Layout.WaterBowl = { x = 150, z = 40, radius = 12, rimHeight = 3, waterDepth = 2 }
Layout.FoodBowl = { x = 150, z = 70, radius = 10, rimHeight = 3 }

Layout.Spawn = {
	x = -40,
	z = 60,
	radius = 18,
	count = 6,
}

--[[
	Zones are axis-aligned boxes (cm) used by objectives. Converted to studs by getZones().
]]
local zoneDefinitions = {
	{ id = "TableTop", center = Vector3.new(-40, 85, 60), size = Vector3.new(124, 26, 84) },
	{ id = "CounterTop", center = Vector3.new(-70, 100, -119), size = Vector3.new(222, 32, 64) },
	{ id = "BehindFridge", center = Vector3.new(110, 10, -148), size = Vector3.new(72, 32, 5) },
}

function Layout.getZones(): { Types.Zone }
	local zones: { Types.Zone } = {}
	for _, zone in zoneDefinitions do
		table.insert(zones, {
			id = zone.id,
			cframe = CFrame.new(Scale.vec(zone.center.X, zone.center.Y, zone.center.Z)),
			size = Scale.vec(zone.size.X, zone.size.Y, zone.size.Z),
		})
	end
	return zones
end

--[[
	Resource spawn points. `y` is the surface the item rests on (floor = 0,
	rug = 0.8, table top = 75.6, counter = 86). Amounts are rolled per respawn.
]]
type SpawnEntry = { x: number, y: number, z: number, min: number, max: number }

local resourceSpawnTable: { [string]: { SpawnEntry } } = {
	FoodCrumb = {
		{ x = -60, y = 0, z = 30, min = 1, max = 3 },
		{ x = -25, y = 0, z = 95, min = 1, max = 3 },
		{ x = -95, y = 0, z = 70, min = 1, max = 2 },
		{ x = 5, y = 0, z = 50, min = 1, max = 3 },
		{ x = -45, y = 0, z = 125, min = 1, max = 2 },
		{ x = -110, y = 0, z = 10, min = 1, max = 2 },
		{ x = -78, y = 75.6, z = 64, min = 2, max = 4 },
		{ x = -60, y = 75.6, z = 46, min = 2, max = 4 },
		{ x = -80, y = 86, z = -130, min = 2, max = 4 },
		{ x = -118, y = 86, z = -100, min = 2, max = 3 },
		{ x = 50, y = 0, z = -60, min = 1, max = 2 },
		{ x = -150, y = 0, z = -70, min = 1, max = 2 },
	},
	Toothpick = {
		{ x = -80, y = 0, z = 45, min = 1, max = 1 },
		{ x = -30, y = 0, z = 70, min = 1, max = 1 },
		{ x = -5, y = 0, z = 35, min = 1, max = 1 },
		{ x = -28, y = 75.6, z = 94, min = 1, max = 2 },
		{ x = -12, y = 75.6, z = 78, min = 1, max = 1 },
		{ x = -120, y = 0, z = 95, min = 1, max = 1 },
	},
	Thread = {
		{ x = -95, y = 0.8, z = -60, min = 1, max = 2 },
		{ x = -70, y = 0.8, z = -40, min = 1, max = 2 },
		{ x = -60, y = 0, z = 110, min = 1, max = 2 },
		{ x = 18, y = 0, z = -45, min = 1, max = 2 },
		{ x = -125, y = 0, z = 20, min = 1, max = 2 },
	},
	WoodSplinter = {
		{ x = -105, y = 0, z = 18, min = 1, max = 2 },
		{ x = -20, y = 0, z = 128, min = 1, max = 2 },
		{ x = 150, y = 0, z = -95, min = 1, max = 2 },
		{ x = -150, y = 0, z = -40, min = 1, max = 2 },
		{ x = -80, y = 0, z = 108, min = 1, max = 2 },
	},
	PlasticFragment = {
		{ x = 150, y = 0, z = -100, min = 1, max = 2 },
		{ x = 168, y = 0, z = -90, min = 1, max = 2 },
		{ x = 140, y = 0, z = -75, min = 1, max = 1 },
		{ x = 120, y = 0, z = -100, min = 1, max = 2 },
		{ x = 60, y = 0, z = -70, min = 1, max = 1 },
	},
	MetalScrap = {
		{ x = 60, y = 0, z = -120, min = 1, max = 1 },
		{ x = 120, y = 0, z = -60, min = 1, max = 1 },
		{ x = 155, y = 0, z = -140, min = 1, max = 1 },
		{ x = -170, y = 0, z = -70, min = 1, max = 1 },
	},
	BottleCap = {
		{ x = 65, y = 0, z = -140, min = 1, max = 1 },
		{ x = 135, y = 0, z = -70, min = 1, max = 1 },
		{ x = -20, y = 0.8, z = -70, min = 1, max = 1 },
	},
	PlantFiber = {
		{ x = 135, y = 0, z = 130, min = 1, max = 2 },
		{ x = 160, y = 0, z = 100, min = 1, max = 2 },
		{ x = 150, y = 0, z = 142, min = 1, max = 2 },
		{ x = 120, y = 0, z = 115, min = 1, max = 2 },
		{ x = 170, y = 0, z = 80, min = 1, max = 2 },
	},
}

function Layout.getResourceSpawns(): { Types.ResourceSpawn }
	local spawns: { Types.ResourceSpawn } = {}
	local random = Random.new(1337)
	-- Deterministic ordering so node ids are stable between server starts.
	local ids = {}
	for id in resourceSpawnTable do
		table.insert(ids, id)
	end
	table.sort(ids)

	for _, resourceId in ids do
		for _, entry in resourceSpawnTable[resourceId] do
			table.insert(spawns, {
				resourceId = resourceId,
				position = Scale.vec(entry.x, entry.y, entry.z),
				amountMin = entry.min,
				amountMax = entry.max,
				rotation = random:NextNumber(0, math.pi * 2),
			})
		end
	end
	return spawns
end

function Layout.getSpawnCFrames(): { CFrame }
	local result = {}
	local spawn = Layout.Spawn
	for index = 1, spawn.count do
		local angle = (index - 1) / spawn.count * math.pi * 2
		local x = spawn.x + math.cos(angle) * spawn.radius
		local z = spawn.z + math.sin(angle) * spawn.radius
		-- Face the east side of the table where the tablecloth ramp is.
		table.insert(result, CFrame.new(Scale.vec(x, 0.5, z)) * CFrame.Angles(0, math.rad(-90), 0))
	end
	return result
end

return Layout
