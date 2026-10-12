--!strict
--[[
	Furniture
	---------
	Large kitchen furniture: counter run with sink and stove, fridge, upper
	cabinets, dining table, chairs, step stool, pendant lamp, trash can,
	potted plant, pet bowls, rug and wall decorations.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Scale = require(ReplicatedStorage.Shared.Scale)
local Tags = require(ReplicatedStorage.Shared.Tags)
local PartBuilder = require(script.Parent.Parent.PartBuilder)
local Layout = require(script.Parent.Layout)

local cm = Scale.cm
local vec = Scale.vec

local Furniture = {}

local Palette = {
	Cabinet = Color3.fromRGB(150, 178, 160),
	CabinetDark = Color3.fromRGB(118, 146, 128),
	Kick = Color3.fromRGB(70, 72, 70),
	Counter = Color3.fromRGB(200, 156, 104),
	Backsplash = Color3.fromRGB(236, 240, 238),
	Steel = Color3.fromRGB(196, 200, 204),
	Brass = Color3.fromRGB(214, 178, 96),
	Appliance = Color3.fromRGB(238, 238, 234),
	Dark = Color3.fromRGB(44, 44, 50),
	Water = Color3.fromRGB(120, 170, 215),
	Oak = Color3.fromRGB(196, 150, 98),
	Walnut = Color3.fromRGB(120, 82, 54),
	Cloth = Color3.fromRGB(248, 240, 224),
	ClothStripe = Color3.fromRGB(200, 70, 70),
	Cushion = Color3.fromRGB(200, 90, 80),
	Stool = Color3.fromRGB(230, 230, 225),
	Terracotta = Color3.fromRGB(190, 110, 80),
	Soil = Color3.fromRGB(65, 50, 40),
	Leaf = Color3.fromRGB(70, 150, 70),
	LeafLight = Color3.fromRGB(110, 190, 90),
	Rug = Color3.fromRGB(138, 54, 60),
	RugStripe = Color3.fromRGB(230, 214, 190),
	BowlBlue = Color3.fromRGB(90, 140, 230),
	BowlRed = Color3.fromRGB(226, 96, 86),
	Kibble = Color3.fromRGB(140, 92, 56),
	Lamp = Color3.fromRGB(70, 110, 90),
	Paper = Color3.fromRGB(252, 250, 240),
}

local Materials = {
	Wood = Enum.Material.Wood,
	Planks = Enum.Material.WoodPlanks,
	Metal = Enum.Material.Metal,
	Glass = Enum.Material.Glass,
	Fabric = Enum.Material.Fabric,
	Plastic = Enum.Material.SmoothPlastic,
	Tiles = PartBuilder.safeMaterial("CeramicTiles", Enum.Material.SmoothPlastic),
	Ground = Enum.Material.Ground,
	LeafyGrass = PartBuilder.safeMaterial("LeafyGrass", Enum.Material.Grass),
	Rubber = PartBuilder.safeMaterial("Rubber", Enum.Material.SmoothPlastic),
	Carpet = PartBuilder.safeMaterial("Carpet", Enum.Material.Fabric),
}

--[[
	Builds a ring out of `segments` boxes (used for bowls and rims).
]]
local function ring(
	parent: Instance,
	centerCm: Vector3,
	radiusCm: number,
	heightCm: number,
	thicknessCm: number,
	segments: number,
	props: PartBuilder.PartProps
)
	local segmentLength = 2 * radiusCm * math.sin(math.pi / segments) + thicknessCm * 0.6
	for index = 0, segments - 1 do
		local angle = (index / segments) * math.pi * 2
		local x = centerCm.X + math.cos(angle) * radiusCm
		local z = centerCm.Z + math.sin(angle) * radiusCm
		local merged = table.clone(props)
		merged.Size = vec(thicknessCm, heightCm, segmentLength)
		merged.CFrame = CFrame.new(vec(x, centerCm.Y + heightCm / 2, z)) * CFrame.Angles(0, -angle, 0)
		merged.Parent = parent
		PartBuilder.part(merged)
	end
end

local function knob(parent: Instance, positionCm: Vector3, radiusCm: number)
	PartBuilder.ball({
		Name = "Knob",
		Size = vec(radiusCm * 2, radiusCm * 2, radiusCm * 2),
		Position = vec(positionCm.X, positionCm.Y, positionCm.Z),
		Color = Palette.Brass,
		Material = Materials.Metal,
		Reflectance = 0.3,
		CanCollide = false,
		CastShadow = false,
		Parent = parent,
	})
end

local function barHandle(parent: Instance, centerCm: Vector3, lengthCm: number, axis: Vector3)
	PartBuilder.cylinderAlong(cm(0.8), cm(lengthCm), vec(centerCm.X, centerCm.Y, centerCm.Z), axis, {
		Name = "Handle",
		Color = Palette.Brass,
		Material = Materials.Metal,
		Reflectance = 0.3,
		CanCollide = false,
		CastShadow = false,
		Parent = parent,
	})
end

local function buildCounterRun(parent: Instance)
	local C = Layout.Counter
	local S = Layout.Sink
	local cabinetXMin = Layout.Stove.XMax
	local cabinetWidth = C.XMax - cabinetXMin
	local cabinetCenterX = (cabinetXMin + C.XMax) / 2
	local depth = C.ZMax - C.ZMin
	local centerZ = (C.ZMin + C.ZMax) / 2
	local frontZ = C.ZMax

	-- Carcass and toe kick.
	PartBuilder.box(
		vec(cabinetWidth, C.CabinetHeight - C.KickHeight, depth - 2),
		vec(cabinetCenterX, C.KickHeight, centerZ - 1),
		{
			Name = "CabinetCarcass",
			Color = Palette.Cabinet,
			Material = Materials.Plastic,
			Parent = parent,
		}
	)
	PartBuilder.box(vec(cabinetWidth, C.KickHeight, depth - 8), vec(cabinetCenterX, 0, centerZ - 4), {
		Name = "ToeKick",
		Color = Palette.Kick,
		Material = Materials.Plastic,
		Parent = parent,
	})

	-- Drawer unit (X -120..-60).
	local drawerX = (cabinetXMin + (cabinetXMin + 60)) / 2
	local drawers = { { 12, 30 }, { 32, 56 }, { 58, 80 } }
	for index, range in drawers do
		local height = range[2] - range[1]
		PartBuilder.box(vec(58, height, 2), vec(drawerX, range[1], frontZ - 1), {
			Name = ("DrawerFront%d"):format(index),
			Color = Palette.Cabinet,
			Material = Materials.Plastic,
			Parent = parent,
		})
		barHandle(parent, Vector3.new(drawerX, (range[1] + range[2]) / 2, frontZ + 1.2), 20, Vector3.xAxis)
	end

	-- Sink base doors (X -60..0).
	for _, doorX in { -45, -15 } do
		PartBuilder.box(vec(28, 68, 2), vec(doorX, 12, frontZ - 1), {
			Name = "SinkDoor",
			Color = Palette.Cabinet,
			Material = Materials.Plastic,
			Parent = parent,
		})
	end
	knob(parent, Vector3.new(-34, 46, frontZ + 1.2), 1.4)
	knob(parent, Vector3.new(-26, 46, frontZ + 1.2), 1.4)

	-- End cabinet (X 0..40).
	PartBuilder.box(vec(38, 68, 2), vec(20, 12, frontZ - 1), {
		Name = "EndDoor",
		Color = Palette.Cabinet,
		Material = Materials.Plastic,
		Parent = parent,
	})
	knob(parent, Vector3.new(5, 46, frontZ + 1.2), 1.4)

	-- Countertop (four slabs around the sink opening).
	local topY = C.CabinetHeight
	local slabs = {
		{ xMin = cabinetXMin, xMax = S.XMin, zMin = C.ZMin, zMax = C.TopZMax, name = "CounterWest" },
		{ xMin = S.XMax, xMax = C.XMax, zMin = C.ZMin, zMax = C.TopZMax, name = "CounterEast" },
		{ xMin = S.XMin, xMax = S.XMax, zMin = C.ZMin, zMax = S.ZMin, name = "CounterBack" },
		{ xMin = S.XMin, xMax = S.XMax, zMin = S.ZMax, zMax = C.TopZMax, name = "CounterFront" },
	}
	for _, slab in slabs do
		PartBuilder.box(
			vec(slab.xMax - slab.xMin, C.TopThickness, slab.zMax - slab.zMin),
			vec((slab.xMin + slab.xMax) / 2, topY, (slab.zMin + slab.zMax) / 2),
			{
				Name = slab.name,
				Color = Palette.Counter,
				Material = Materials.Planks,
				Parent = parent,
				Tags = { Tags.Kitchen },
			}
		)
	end
	-- Backsplash tiles.
	PartBuilder.box(
		vec(C.XMax - C.XMin, C.BacksplashHeight - C.Height, 1),
		vec((C.XMin + C.XMax) / 2, C.Height, C.ZMin + 0.5),
		{
			Name = "Backsplash",
			Color = Palette.Backsplash,
			Material = Materials.Tiles,
			Reflectance = 0.05,
			Parent = parent,
		}
	)
end

local function buildSink(parent: Instance)
	local C = Layout.Counter
	local S = Layout.Sink
	local wall = 1.5
	local bottomY = C.Height - S.Depth
	local centerX = (S.XMin + S.XMax) / 2
	local centerZ = (S.ZMin + S.ZMax) / 2
	local width = S.XMax - S.XMin
	local depth = S.ZMax - S.ZMin
	local steel = { Color = Palette.Steel, Material = Materials.Metal, Reflectance = 0.25, Parent = parent }

	local function steelBox(name: string, size: Vector3, bottom: Vector3)
		local props = table.clone(steel)
		props.Name = name
		PartBuilder.box(size, bottom, props)
	end

	steelBox("SinkBottom", vec(width, wall, depth), vec(centerX, bottomY, centerZ))
	steelBox("SinkWallWest", vec(wall, S.Depth, depth), vec(S.XMin + wall / 2, bottomY, centerZ))
	steelBox("SinkWallEast", vec(wall, S.Depth, depth), vec(S.XMax - wall / 2, bottomY, centerZ))
	steelBox("SinkWallNorth", vec(width, S.Depth, wall), vec(centerX, bottomY, S.ZMin + wall / 2))
	steelBox("SinkWallSouth", vec(width, S.Depth, wall), vec(centerX, bottomY, S.ZMax - wall / 2))

	-- Standing water.
	PartBuilder.box(vec(width - wall * 2, S.WaterDepth, depth - wall * 2), vec(centerX, bottomY + wall, centerZ), {
		Name = "SinkWater",
		Color = Palette.Water,
		Material = Materials.Glass,
		Transparency = 0.45,
		Reflectance = 0.1,
		CanCollide = false,
		CastShadow = false,
		Parent = parent,
		Tags = { Tags.Water, Tags.CameraIgnore },
	})
	PartBuilder.cylinderY(cm(2.5), cm(0.4), vec(centerX, bottomY + wall, centerZ), {
		Name = "Drain",
		Color = Palette.Dark,
		Material = Materials.Metal,
		CanCollide = false,
		Parent = parent,
	})

	-- Faucet.
	local faucetZ = C.ZMin + 5
	PartBuilder.cylinderY(cm(2.2), cm(18), vec(centerX, C.Height, faucetZ), {
		Name = "FaucetBase",
		Color = Palette.Steel,
		Material = Materials.Metal,
		Reflectance = 0.35,
		Parent = parent,
	})
	local neckLength = 27
	PartBuilder.cylinderAlong(
		cm(1.6),
		cm(neckLength),
		vec(centerX, C.Height + 18, faucetZ + neckLength / 2),
		Vector3.zAxis,
		{
			Name = "FaucetNeck",
			Color = Palette.Steel,
			Material = Materials.Metal,
			Reflectance = 0.35,
			Parent = parent,
		}
	)
	local spoutZ = faucetZ + neckLength
	local spout = PartBuilder.cylinderY(cm(1.6), cm(5), vec(centerX, C.Height + 13, spoutZ), {
		Name = "FaucetSpout",
		Color = Palette.Steel,
		Material = Materials.Metal,
		Reflectance = 0.35,
		Parent = parent,
	})
	for _, tapX in { centerX - 8, centerX + 8 } do
		PartBuilder.cylinderY(cm(1.8), cm(3), vec(tapX, C.Height, faucetZ), {
			Name = "Tap",
			Color = Palette.Steel,
			Material = Materials.Metal,
			Reflectance = 0.35,
			Parent = parent,
		})
		PartBuilder.box(vec(1.2, 1.2, 6), vec(tapX, C.Height + 3, faucetZ - 2), {
			Name = "TapLever",
			Color = Palette.Steel,
			Material = Materials.Metal,
			CanCollide = false,
			Parent = parent,
		})
	end

	-- Dripping tap.
	local attachment = Instance.new("Attachment")
	attachment.Name = "DripAttachment"
	-- cylinderY rotates local +X to world +Y, so the bottom of the spout is at local -X.
	attachment.Position = Vector3.new(-cm(2.5), 0, 0)
	attachment.Parent = spout
	local drip = Instance.new("ParticleEmitter")
	drip.Name = "Drip"
	drip.Color = ColorSequence.new(Color3.fromRGB(170, 210, 245))
	drip.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 0.35) })
	drip.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.5) })
	drip.Lifetime = NumberRange.new(0.9, 1.1)
	drip.Rate = 0.7
	drip.Speed = NumberRange.new(0, 0)
	drip.Acceleration = Vector3.new(0, -40, 0)
	drip.LightEmission = 0.3
	drip.EmissionDirection = Enum.NormalId.Bottom
	drip.Parent = attachment
end

local function buildStove(parent: Instance)
	local ST = Layout.Stove
	local C = Layout.Counter
	local width = ST.XMax - ST.XMin
	local centerX = (ST.XMin + ST.XMax) / 2
	local depth = C.ZMax - C.ZMin
	local centerZ = (C.ZMin + C.ZMax) / 2

	PartBuilder.box(vec(width, C.Height - 8, depth), vec(centerX, 8, centerZ), {
		Name = "StoveBody",
		Color = Palette.Appliance,
		Material = Materials.Plastic,
		Reflectance = 0.05,
		Parent = parent,
	})
	PartBuilder.box(vec(width, 8, depth - 6), vec(centerX, 0, centerZ - 3), {
		Name = "StoveKick",
		Color = Palette.Kick,
		Material = Materials.Plastic,
		Parent = parent,
	})
	-- Oven door with glass window.
	PartBuilder.box(vec(width - 6, 46, 2), vec(centerX, 14, C.ZMax - 1 + 0.1), {
		Name = "OvenDoor",
		Color = Color3.fromRGB(60, 60, 66),
		Material = Materials.Metal,
		Parent = parent,
	})
	PartBuilder.box(vec(width - 20, 22, 0.6), vec(centerX, 26, C.ZMax + 0.3), {
		Name = "OvenWindow",
		Color = Color3.fromRGB(30, 30, 36),
		Material = Materials.Glass,
		Reflectance = 0.2,
		CanCollide = false,
		Parent = parent,
	})
	-- Storage drawer below the oven.
	PartBuilder.box(vec(width - 6, 10, 2), vec(centerX, 2, C.ZMax - 1 + 0.1), {
		Name = "OvenDrawer",
		Color = Color3.fromRGB(60, 60, 66),
		Material = Materials.Metal,
		Parent = parent,
	})
	-- Oven handle on stand-offs.
	PartBuilder.cylinderAlong(cm(1.3), cm(width - 8), vec(centerX, ST.HandleY, ST.HandleZ), Vector3.xAxis, {
		Name = "OvenHandle",
		Color = Palette.Steel,
		Material = Materials.Metal,
		Reflectance = 0.3,
		Parent = parent,
	})
	for _, x in { ST.XMin + 7, ST.XMax - 7 } do
		PartBuilder.box(vec(2, 2, 3.5), vec(x, ST.HandleY - 1, C.ZMax + 0.5), {
			Name = "HandleStandoff",
			Color = Palette.Steel,
			Material = Materials.Metal,
			CanCollide = false,
			Parent = parent,
		})
	end
	-- Glass cooktop and burners.
	PartBuilder.box(vec(width, 2, depth), vec(centerX, C.Height, centerZ), {
		Name = "Cooktop",
		Color = Color3.fromRGB(34, 34, 40),
		Material = Materials.Plastic,
		Reflectance = 0.15,
		Parent = parent,
		Tags = { Tags.Kitchen },
	})
	for _, burner in { { -165, -135 }, { -135, -135 }, { -165, -105 }, { -135, -105 } } do
		PartBuilder.cylinderY(cm(9), cm(0.8), vec(burner[1], C.Height + 2, burner[2]), {
			Name = "Burner",
			Color = Color3.fromRGB(46, 46, 52),
			Material = Materials.Metal,
			Parent = parent,
		})
		PartBuilder.cylinderY(cm(5.5), cm(0.4), vec(burner[1], C.Height + 2.8, burner[2]), {
			Name = "BurnerRing",
			Color = Color3.fromRGB(80, 80, 86),
			Material = Materials.Metal,
			CanCollide = false,
			Parent = parent,
		})
	end
	-- Control knobs on the front top edge.
	for _, x in { -170, -158, -142, -130 } do
		PartBuilder.cylinderAlong(cm(2), cm(2), vec(x, C.Height - 3, C.ZMax + 1), Vector3.zAxis, {
			Name = "StoveKnob",
			Color = Palette.Dark,
			Material = Materials.Plastic,
			CanCollide = false,
			Parent = parent,
		})
	end
	-- Back panel with a glowing clock.
	PartBuilder.box(vec(width, 14, 8), vec(centerX, C.Height, C.ZMin + 4), {
		Name = "StovePanel",
		Color = Palette.Appliance,
		Material = Materials.Plastic,
		Parent = parent,
	})
	local clock = PartBuilder.box(vec(14, 6, 0.4), vec(centerX, C.Height + 4, C.ZMin + 8.2), {
		Name = "StoveClock",
		Color = Color3.fromRGB(20, 20, 24),
		Material = Materials.Plastic,
		CanCollide = false,
		Parent = parent,
	})
	PartBuilder.surfaceText(clock, Enum.NormalId.Back, "3:07", Color3.fromRGB(120, 255, 140), Enum.Font.Code)
end

local function buildFridge(parent: Instance)
	local F = Layout.Fridge
	local width = F.XMax - F.XMin
	local depth = F.ZMax - F.ZMin
	local centerX = (F.XMin + F.XMax) / 2
	local centerZ = (F.ZMin + F.ZMax) / 2
	local frontZ = F.ZMax

	PartBuilder.box(vec(width, F.Height, depth), vec(centerX, 0, centerZ), {
		Name = "FridgeBody",
		Color = Palette.Appliance,
		Material = Materials.Plastic,
		Reflectance = 0.06,
		Parent = parent,
	})
	-- Door split groove and side groove.
	PartBuilder.box(vec(width, 1.2, 0.6), vec(centerX, F.FreezerSplitY - 0.6, frontZ - 0.3 + 0.35), {
		Name = "FridgeGroove",
		Color = Color3.fromRGB(150, 152, 156),
		Material = Materials.Plastic,
		CanCollide = false,
		Parent = parent,
	})
	-- Handles on the left edge.
	for _, range in { { 60, 110 }, { 125, 160 } } do
		local height = range[2] - range[1]
		PartBuilder.cylinderY(cm(1.3), cm(height), vec(F.XMin + 5, range[1], frontZ + 3), {
			Name = "FridgeHandle",
			Color = Palette.Steel,
			Material = Materials.Metal,
			Reflectance = 0.3,
			Parent = parent,
		})
		for _, y in { range[1] + 3, range[2] - 3 } do
			PartBuilder.box(vec(2, 2, 3), vec(F.XMin + 5, y - 1, frontZ + 0.2), {
				Name = "HandleStandoff",
				Color = Palette.Steel,
				Material = Materials.Metal,
				CanCollide = false,
				Parent = parent,
			})
		end
	end
	-- Bottom vent grille.
	PartBuilder.box(vec(width - 8, 6, 1), vec(centerX, 2, frontZ + 0.3), {
		Name = "FridgeVent",
		Color = Color3.fromRGB(60, 60, 66),
		Material = Enum.Material.DiamondPlate,
		CanCollide = false,
		Parent = parent,
	})
	-- Fridge magnets.
	local magnets = {
		{ x = 92, y = 150, color = Color3.fromRGB(230, 70, 70) },
		{ x = 126, y = 142, color = Color3.fromRGB(250, 200, 60) },
		{ x = 100, y = 96, color = Color3.fromRGB(70, 130, 230) },
		{ x = 132, y = 80, color = Color3.fromRGB(90, 200, 120) },
	}
	for _, magnet in magnets do
		PartBuilder.cylinderAlong(cm(2), cm(0.6), vec(magnet.x, magnet.y, frontZ + 0.3), Vector3.zAxis, {
			Name = "Magnet",
			Color = magnet.color,
			Material = Materials.Plastic,
			CanCollide = false,
			CastShadow = false,
			Parent = parent,
		})
	end
	-- A note held by a magnet: environmental storytelling.
	local note = PartBuilder.box(vec(12, 15, 0.3), vec(115, 128, frontZ + 0.15), {
		Name = "FridgeNote",
		Color = Palette.Paper,
		Material = Materials.Plastic,
		CanCollide = false,
		CastShadow = false,
		Parent = parent,
	})
	PartBuilder.surfaceText(
		note,
		Enum.NormalId.Back,
		"Fix the gap behind the fridge!\nSomething keeps glowing back there...\n- M.",
		Color3.fromRGB(60, 50, 120),
		Enum.Font.Gotham
	)
	PartBuilder.cylinderAlong(cm(1.6), cm(0.6), vec(115, 141, frontZ + 0.5), Vector3.zAxis, {
		Name = "NoteMagnet",
		Color = Color3.fromRGB(240, 120, 60),
		Material = Materials.Plastic,
		CanCollide = false,
		CastShadow = false,
		Parent = parent,
	})
end

local function buildUpperCabinets(parent: Instance)
	local C = Layout.Counter
	local depth = 35
	local zMin = C.ZMin
	local centerZ = zMin + depth / 2
	local frontZ = zMin + depth

	-- Left block.
	local leftXMin, leftXMax = -180, -78
	PartBuilder.box(vec(leftXMax - leftXMin, 70, depth), vec((leftXMin + leftXMax) / 2, 145, centerZ), {
		Name = "UpperCabinetLeft",
		Color = Palette.Cabinet,
		Material = Materials.Plastic,
		Parent = parent,
	})
	local doorWidth = (leftXMax - leftXMin) / 3
	for index = 0, 2 do
		local x = leftXMin + doorWidth * (index + 0.5)
		PartBuilder.box(vec(doorWidth - 2, 66, 1.5), vec(x, 147, frontZ - 0.5), {
			Name = "UpperDoor",
			Color = Palette.CabinetDark,
			Material = Materials.Plastic,
			CanCollide = false,
			Parent = parent,
		})
		knob(parent, Vector3.new(x + doorWidth / 2 - 5, 180, frontZ + 1.2), 1.3)
	end

	-- Block above the fridge.
	local F = Layout.Fridge
	PartBuilder.box(vec(F.XMax - F.XMin, 35, depth), vec((F.XMin + F.XMax) / 2, 180, centerZ), {
		Name = "UpperCabinetFridge",
		Color = Palette.Cabinet,
		Material = Materials.Plastic,
		Parent = parent,
	})
	for _, x in { F.XMin + 17.5, F.XMax - 17.5 } do
		PartBuilder.box(vec(33, 31, 1.5), vec(x, 182, frontZ - 0.5), {
			Name = "UpperDoor",
			Color = Palette.CabinetDark,
			Material = Materials.Plastic,
			CanCollide = false,
			Parent = parent,
		})
	end

	-- Open shelves right of the window with jars.
	local shelfXMin, shelfXMax = 18, 60
	local shelfDepth = 25
	for _, y in { 150, 180 } do
		PartBuilder.box(
			vec(shelfXMax - shelfXMin, 2, shelfDepth),
			vec((shelfXMin + shelfXMax) / 2, y, zMin + shelfDepth / 2),
			{
				Name = "Shelf",
				Color = Palette.Counter,
				Material = Materials.Planks,
				Parent = parent,
			}
		)
	end
	local jars = {
		{ x = 26, fill = Color3.fromRGB(222, 190, 120), fillHeight = 9 },
		{ x = 39, fill = Color3.fromRGB(170, 60, 60), fillHeight = 7 },
		{ x = 52, fill = Color3.fromRGB(240, 236, 224), fillHeight = 10 },
	}
	for _, jar in jars do
		local jarZ = zMin + 12
		PartBuilder.cylinderY(cm(5), cm(14), vec(jar.x, 152, jarZ), {
			Name = "Jar",
			Color = Color3.fromRGB(230, 240, 245),
			Material = Materials.Glass,
			Transparency = 0.5,
			Parent = parent,
		})
		PartBuilder.cylinderY(cm(4.4), cm(jar.fillHeight), vec(jar.x, 152.5, jarZ), {
			Name = "JarContents",
			Color = jar.fill,
			Material = Materials.Plastic,
			CanCollide = false,
			Parent = parent,
		})
		PartBuilder.cylinderY(cm(5.2), cm(1.5), vec(jar.x, 166, jarZ), {
			Name = "JarLid",
			Color = Palette.Steel,
			Material = Materials.Metal,
			CanCollide = false,
			Parent = parent,
		})
	end
end

local function buildTable(parent: Instance)
	local T = Layout.Table
	local halfW = T.Width / 2
	local halfD = T.Depth / 2
	local topBottom = T.Height - T.TopThickness

	PartBuilder.box(vec(T.Width, T.TopThickness, T.Depth), vec(T.CenterX, topBottom, T.CenterZ), {
		Name = "TableTop",
		Color = Palette.Oak,
		Material = Materials.Wood,
		Parent = parent,
		Tags = { Tags.Kitchen },
	})
	-- Apron.
	local apronInset = 6
	local apronHeight = 8
	PartBuilder.box(
		vec(T.Width - apronInset * 2, apronHeight, 2),
		vec(T.CenterX, topBottom - apronHeight, T.CenterZ - halfD + apronInset),
		{
			Name = "ApronNorth",
			Color = Palette.Oak,
			Material = Materials.Wood,
			Parent = parent,
		}
	)
	PartBuilder.box(
		vec(T.Width - apronInset * 2, apronHeight, 2),
		vec(T.CenterX, topBottom - apronHeight, T.CenterZ + halfD - apronInset),
		{
			Name = "ApronSouth",
			Color = Palette.Oak,
			Material = Materials.Wood,
			Parent = parent,
		}
	)
	PartBuilder.box(
		vec(2, apronHeight, T.Depth - apronInset * 2),
		vec(T.CenterX - halfW + apronInset, topBottom - apronHeight, T.CenterZ),
		{
			Name = "ApronWest",
			Color = Palette.Oak,
			Material = Materials.Wood,
			Parent = parent,
		}
	)
	PartBuilder.box(
		vec(2, apronHeight, T.Depth - apronInset * 2),
		vec(T.CenterX + halfW - apronInset, topBottom - apronHeight, T.CenterZ),
		{
			Name = "ApronEast",
			Color = Palette.Oak,
			Material = Materials.Wood,
			Parent = parent,
		}
	)
	-- Legs.
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local x = T.CenterX + sx * (halfW - T.LegInset)
			local z = T.CenterZ + sz * (halfD - T.LegInset)
			PartBuilder.box(vec(T.LegSize, topBottom, T.LegSize), vec(x, 0, z), {
				Name = "TableLeg",
				Color = Palette.Oak,
				Material = Materials.Wood,
				Parent = parent,
			})
		end
	end
	-- Tablecloth with two red stripes.
	PartBuilder.box(vec(T.Width, T.ClothThickness, T.Depth), vec(T.CenterX, T.Height, T.CenterZ), {
		Name = "Tablecloth",
		Color = Palette.Cloth,
		Material = Materials.Fabric,
		Parent = parent,
		Tags = { Tags.Kitchen },
	})
	for _, dz in { -30, 30 } do
		PartBuilder.box(vec(T.Width, T.ClothThickness + 0.1, 2.5), vec(T.CenterX, T.Height, T.CenterZ + dz), {
			Name = "ClothStripe",
			Color = Palette.ClothStripe,
			Material = Materials.Fabric,
			CanCollide = false,
			CastShadow = false,
			Parent = parent,
		})
	end
end

local function buildChair(parent: Instance, spec: { x: number, z: number, facing: number })
	local CH = Layout.Chair
	local x, z, facing = spec.x, spec.z, spec.facing
	local half = CH.SeatSize / 2
	local legOffset = CH.LegInset
	local model = PartBuilder.model("Chair", parent)

	PartBuilder.box(vec(CH.SeatSize, CH.SeatThickness, CH.SeatSize), vec(x, CH.SeatHeight, z), {
		Name = "Seat",
		Color = Palette.Walnut,
		Material = Materials.Wood,
		Parent = model,
	})
	PartBuilder.box(vec(CH.SeatSize - 6, 3, CH.SeatSize - 6), vec(x, CH.SeatHeight + CH.SeatThickness, z), {
		Name = "Cushion",
		Color = Palette.Cushion,
		Material = Materials.Fabric,
		Parent = model,
	})
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			PartBuilder.box(
				vec(CH.LegSize, CH.SeatHeight, CH.LegSize),
				vec(x + sx * legOffset, 0, z + sz * legOffset),
				{
					Name = "Leg",
					Color = Palette.Walnut,
					Material = Materials.Wood,
					Parent = model,
				}
			)
		end
	end
	-- Rungs between the legs (a toddler-height ledge for a 2 cm explorer).
	local rungY = 18
	PartBuilder.box(vec(legOffset * 2 - CH.LegSize, 3, 3), vec(x, rungY, z + facing * legOffset), {
		Name = "RungFront",
		Color = Palette.Walnut,
		Material = Materials.Wood,
		Parent = model,
	})
	for _, sx in { -1, 1 } do
		PartBuilder.box(vec(3, 3, legOffset * 2 - CH.LegSize), vec(x + sx * legOffset, rungY, z), {
			Name = "RungSide",
			Color = Palette.Walnut,
			Material = Materials.Wood,
			Parent = model,
		})
	end
	-- Back posts and slats (behind the seated person).
	local backZ = z - facing * (half - 2)
	for _, sx in { -1, 1 } do
		PartBuilder.box(
			vec(CH.LegSize, CH.BackHeight - CH.SeatHeight, CH.LegSize),
			vec(x + sx * legOffset, CH.SeatHeight, backZ),
			{
				Name = "BackPost",
				Color = Palette.Walnut,
				Material = Materials.Wood,
				Parent = model,
			}
		)
	end
	for _, slatY in { 58, 70, 82 } do
		PartBuilder.box(vec(legOffset * 2 - CH.LegSize, 6, 2), vec(x, slatY, backZ), {
			Name = "BackSlat",
			Color = Palette.Walnut,
			Material = Materials.Wood,
			Parent = model,
		})
	end
	return model
end

local function buildStepStool(parent: Instance)
	local SS = Layout.StepStool
	local model = PartBuilder.model("StepStool", parent)
	local stepDepth = SS.Depth / 2
	local lowerZ = SS.CenterZ + stepDepth / 2
	local upperZ = SS.CenterZ - stepDepth / 2
	local lowerY = SS.StepHeights[1]
	local upperY = SS.StepHeights[2]

	PartBuilder.box(vec(SS.Width, 3, stepDepth), vec(SS.CenterX, lowerY - 3, lowerZ), {
		Name = "LowerStep",
		Color = Palette.Stool,
		Material = Materials.Plastic,
		Parent = model,
	})
	PartBuilder.box(vec(SS.Width, 3, stepDepth), vec(SS.CenterX, upperY - 3, upperZ), {
		Name = "UpperStep",
		Color = Palette.Stool,
		Material = Materials.Plastic,
		Parent = model,
	})
	-- Grip strips.
	for _, stepY in { lowerY, upperY } do
		local zz = if stepY == lowerY then lowerZ else upperZ
		PartBuilder.box(vec(SS.Width - 6, 0.4, 3), vec(SS.CenterX, stepY, zz), {
			Name = "GripStrip",
			Color = Color3.fromRGB(60, 60, 68),
			Material = Materials.Rubber,
			CanCollide = false,
			Parent = model,
		})
	end
	-- Legs.
	local legs = {
		{ x = SS.CenterX - SS.Width / 2 + 2, z = SS.CenterZ + SS.Depth / 2 - 2, h = lowerY - 3 },
		{ x = SS.CenterX + SS.Width / 2 - 2, z = SS.CenterZ + SS.Depth / 2 - 2, h = lowerY - 3 },
		{ x = SS.CenterX - SS.Width / 2 + 2, z = SS.CenterZ - SS.Depth / 2 + 2, h = upperY - 3 },
		{ x = SS.CenterX + SS.Width / 2 - 2, z = SS.CenterZ - SS.Depth / 2 + 2, h = upperY - 3 },
		{ x = SS.CenterX - SS.Width / 2 + 2, z = SS.CenterZ, h = upperY - 3 },
		{ x = SS.CenterX + SS.Width / 2 - 2, z = SS.CenterZ, h = upperY - 3 },
	}
	for _, leg in legs do
		PartBuilder.box(vec(3, leg.h, 3), vec(leg.x, 0, leg.z), {
			Name = "StoolLeg",
			Color = Palette.Stool,
			Material = Materials.Plastic,
			Parent = model,
		})
		PartBuilder.box(vec(3.4, 1, 3.4), vec(leg.x, 0, leg.z), {
			Name = "StoolFoot",
			Color = Color3.fromRGB(60, 60, 68),
			Material = Materials.Rubber,
			CanCollide = false,
			Parent = model,
		})
	end
	return model
end

local function buildPendantLamp(parent: Instance)
	local T = Layout.Table
	local x, z = T.CenterX, T.CenterZ
	local ceiling = Layout.Room.Height
	PartBuilder.cylinderY(cm(0.5), cm(ceiling - 190), vec(x, 190, z), {
		Name = "LampCord",
		Color = Palette.Dark,
		Material = Materials.Plastic,
		CanCollide = false,
		Parent = parent,
	})
	PartBuilder.ellipsoid(vec(44, 20, 44), vec(x, 184, z), {
		Name = "LampShade",
		Color = Palette.Lamp,
		Material = Materials.Metal,
		Reflectance = 0.1,
		CanCollide = false,
		Parent = parent,
	})
	local bulb = PartBuilder.ball({
		Name = "LampBulb",
		Size = vec(7, 7, 7),
		Position = vec(x, 177, z),
		Color = Color3.fromRGB(255, 232, 180),
		Material = Enum.Material.Neon,
		CanCollide = false,
		CastShadow = false,
		Parent = parent,
	})
	PartBuilder.pointLight(bulb, Color3.fromRGB(255, 225, 170), 1.2, 60)
end

local function buildTrashCan(parent: Instance)
	local TR = Layout.Trash
	PartBuilder.cylinderY(cm(TR.radius), cm(TR.height), vec(TR.x, 0, TR.z), {
		Name = "TrashCan",
		Color = Color3.fromRGB(160, 164, 170),
		Material = Materials.Metal,
		Reflectance = 0.2,
		Parent = parent,
	})
	PartBuilder.cylinderY(cm(TR.radius + 1), cm(2), vec(TR.x, TR.height - 2, TR.z), {
		Name = "TrashRim",
		Color = Color3.fromRGB(140, 144, 150),
		Material = Materials.Metal,
		Parent = parent,
	})
	PartBuilder.cylinderY(cm(TR.radius + 1.5), cm(3), vec(TR.x, TR.height, TR.z), {
		Name = "TrashLid",
		Color = Color3.fromRGB(150, 154, 160),
		Material = Materials.Metal,
		Reflectance = 0.2,
		Parent = parent,
	})
	PartBuilder.cylinderY(cm(2.5), cm(2.5), vec(TR.x, TR.height + 3, TR.z), {
		Name = "TrashLidKnob",
		Color = Palette.Dark,
		Material = Materials.Plastic,
		CanCollide = false,
		Parent = parent,
	})
	-- Foot pedal.
	PartBuilder.box(vec(8, 2, 5), vec(TR.x - 6, 0, TR.z + TR.radius + 1), {
		Name = "TrashPedal",
		Color = Palette.Dark,
		Material = Materials.Metal,
		Parent = parent,
	})
end

local function buildPlant(parent: Instance)
	local P = Layout.Plant
	local model = PartBuilder.model("PottedPlant", parent)
	PartBuilder.cylinderY(cm(P.potRadius), cm(P.potHeight), vec(P.x, 0, P.z), {
		Name = "Pot",
		Color = Palette.Terracotta,
		Material = Materials.Plastic,
		Parent = model,
	})
	PartBuilder.cylinderY(cm(P.potRadius + 1.2), cm(3), vec(P.x, P.potHeight - 3, P.z), {
		Name = "PotRim",
		Color = Palette.Terracotta,
		Material = Materials.Plastic,
		Parent = model,
	})
	PartBuilder.cylinderY(cm(P.potRadius - 1), cm(1.5), vec(P.x, P.potHeight - 1, P.z), {
		Name = "Soil",
		Color = Palette.Soil,
		Material = Materials.Ground,
		Parent = model,
	})
	-- Stems and leaves.
	local random = Random.new(42)
	for index = 1, 3 do
		local yaw = (index / 3) * math.pi * 2
		local tilt = math.rad(18)
		local direction = Vector3.new(math.sin(yaw) * math.sin(tilt), math.cos(tilt), math.cos(yaw) * math.sin(tilt))
		local length = 52
		local base = vec(P.x, P.potHeight, P.z)
		PartBuilder.cylinderAlong(cm(1.2), cm(length), base + direction * cm(length / 2), direction, {
			Name = "Stem",
			Color = Color3.fromRGB(80, 130, 60),
			Material = Materials.Plastic,
			CanCollide = false,
			Parent = model,
		})
	end
	for index = 1, 10 do
		local yaw = (index / 10) * math.pi * 2 + random:NextNumber(-0.3, 0.3)
		local height = P.potHeight + 30 + random:NextNumber(0, 24)
		local reach = 14 + random:NextNumber(0, 10)
		local centerX = P.x + math.sin(yaw) * reach
		local centerZ = P.z + math.cos(yaw) * reach
		local droop = math.rad(random:NextNumber(10, 35))
		PartBuilder.ellipsoid(vec(12, 1.2, 30), vec(centerX, height, centerZ), {
			Name = "Leaf",
			Color = if index % 2 == 0 then Palette.Leaf else Palette.LeafLight,
			Material = Materials.LeafyGrass,
			CFrame = CFrame.new(vec(centerX, height, centerZ)) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(droop, 0, 0),
			CanCollide = false,
			Parent = model,
		})
	end
	-- Fallen dry leaves on the floor.
	for index = 1, 3 do
		local yaw = index * 2.1
		local dx = math.sin(yaw) * 22
		local dz = math.cos(yaw) * 22
		PartBuilder.ellipsoid(vec(6, 0.4, 10), vec(P.x + dx, 0.2, P.z + dz), {
			Name = "DryLeaf",
			Color = Color3.fromRGB(150, 110, 60),
			Material = Materials.Plastic,
			CFrame = CFrame.new(vec(P.x + dx, 0.2, P.z + dz)) * CFrame.Angles(0, yaw, 0),
			CanCollide = false,
			CastShadow = false,
			Parent = model,
		})
	end
	return model
end

local function buildPetBowls(parent: Instance)
	local W = Layout.WaterBowl
	local model = PartBuilder.model("PetBowls", parent)
	ring(model, Vector3.new(W.x, 0, W.z), W.radius, W.rimHeight, 1.5, 14, {
		Name = "WaterBowlRim",
		Color = Palette.BowlBlue,
		Material = Materials.Plastic,
	})
	PartBuilder.cylinderY(cm(W.radius - 0.6), cm(0.8), vec(W.x, 0, W.z), {
		Name = "WaterBowlFloor",
		Color = Palette.BowlBlue,
		Material = Materials.Plastic,
		Parent = model,
	})
	PartBuilder.cylinderY(cm(W.radius - 1.5), cm(W.waterDepth), vec(W.x, 0.8, W.z), {
		Name = "BowlWater",
		Color = Palette.Water,
		Material = Materials.Glass,
		Transparency = 0.4,
		Reflectance = 0.1,
		CanCollide = false,
		CastShadow = false,
		Parent = model,
		Tags = { Tags.Water, Tags.CameraIgnore },
	})

	local Fb = Layout.FoodBowl
	ring(model, Vector3.new(Fb.x, 0, Fb.z), Fb.radius, Fb.rimHeight, 1.5, 12, {
		Name = "FoodBowlRim",
		Color = Palette.BowlRed,
		Material = Materials.Plastic,
	})
	PartBuilder.cylinderY(cm(Fb.radius - 0.6), cm(0.8), vec(Fb.x, 0, Fb.z), {
		Name = "FoodBowlFloor",
		Color = Palette.BowlRed,
		Material = Materials.Plastic,
		Parent = model,
	})
	local random = Random.new(7)
	for _ = 1, 9 do
		local angle = random:NextNumber(0, math.pi * 2)
		local distance = random:NextNumber(0, Fb.radius - 3.5)
		PartBuilder.ball({
			Name = "Kibble",
			Size = vec(2.4, 2.4, 2.4),
			Position = vec(Fb.x + math.cos(angle) * distance, 2, Fb.z + math.sin(angle) * distance),
			Color = Palette.Kibble,
			Material = Materials.Plastic,
			CanCollide = false,
			CastShadow = false,
			Parent = model,
		})
	end
	return model
end

local function buildRug(parent: Instance)
	local R = Layout.Rug
	local width = R.XMax - R.XMin
	local depth = R.ZMax - R.ZMin
	local centerX = (R.XMin + R.XMax) / 2
	local centerZ = (R.ZMin + R.ZMax) / 2
	PartBuilder.box(vec(width, R.Thickness, depth), vec(centerX, 0, centerZ), {
		Name = "Rug",
		Color = Palette.Rug,
		Material = Materials.Carpet,
		Parent = parent,
	})
	for _, z in { -78, -68, -52, -42 } do
		PartBuilder.box(vec(width, R.Thickness + 0.1, 4), vec(centerX, 0, z), {
			Name = "RugStripe",
			Color = Palette.RugStripe,
			Material = Materials.Carpet,
			CanCollide = false,
			CastShadow = false,
			Parent = parent,
		})
	end
end

local function buildWallDecor(parent: Instance)
	local wallX = Layout.Room.Width / 2
	-- Wall clock on the east wall.
	local clockX = wallX - 1
	PartBuilder.cylinderAlong(cm(16), cm(2), vec(clockX, 200, 0), Vector3.xAxis, {
		Name = "ClockRim",
		Color = Palette.Dark,
		Material = Materials.Plastic,
		CanCollide = false,
		Parent = parent,
	})
	PartBuilder.cylinderAlong(cm(14.5), cm(0.6), vec(clockX - 1.3, 200, 0), Vector3.xAxis, {
		Name = "ClockFace",
		Color = Palette.Paper,
		Material = Materials.Plastic,
		CanCollide = false,
		Parent = parent,
	})
	PartBuilder.box(vec(0.4, 10, 1.2), vec(clockX - 1.9, 200, 0), {
		Name = "ClockHourHand",
		Color = Palette.Dark,
		Material = Materials.Plastic,
		CanCollide = false,
		Parent = parent,
	})
	PartBuilder.part({
		Name = "ClockMinuteHand",
		Size = vec(0.4, 1.2, 12),
		CFrame = CFrame.new(vec(clockX - 1.9, 200, 0)) * CFrame.Angles(math.rad(50), 0, 0) * CFrame.new(0, 0, -cm(5)),
		Color = Palette.Dark,
		Material = Materials.Plastic,
		CanCollide = false,
		Parent = parent,
	})

	-- Calendar near the plant.
	local calendar = PartBuilder.box(vec(0.6, 40, 30), vec(clockX, 150, 100), {
		Name = "Calendar",
		Color = Palette.Paper,
		Material = Materials.Plastic,
		CanCollide = false,
		Parent = parent,
	})
	PartBuilder.surfaceText(
		calendar,
		Enum.NormalId.Left,
		"OCTOBER\n\nDay 3 of the experiment.\nDO NOT open the basement door.",
		Color3.fromRGB(40, 40, 60),
		Enum.Font.Gotham
	)
end

function Furniture.build(parent: Instance)
	local furniture = PartBuilder.folder("Furniture", parent)
	buildCounterRun(PartBuilder.model("CounterRun", furniture))
	buildSink(PartBuilder.model("Sink", furniture))
	buildStove(PartBuilder.model("Stove", furniture))
	buildFridge(PartBuilder.model("Fridge", furniture))
	buildUpperCabinets(PartBuilder.model("UpperCabinets", furniture))
	buildTable(PartBuilder.model("DiningTable", furniture))
	for _, chair in Layout.Chairs do
		buildChair(furniture, chair)
	end
	buildStepStool(furniture)
	buildPendantLamp(PartBuilder.model("PendantLamp", furniture))
	buildTrashCan(PartBuilder.model("TrashCan", furniture))
	buildPlant(furniture)
	buildPetBowls(furniture)
	buildRug(PartBuilder.model("Rug", furniture))
	buildWallDecor(PartBuilder.model("WallDecor", furniture))
end

return Furniture
