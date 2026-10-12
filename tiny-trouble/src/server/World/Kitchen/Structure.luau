--!strict
--[[
	Structure
	---------
	Builds the shell of the kitchen: floor tiles, walls with window and door
	openings, ceiling, baseboards, windows, the closed living-room door, the
	mysterious vent behind the fridge and the garden seen through the windows.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Scale = require(ReplicatedStorage.Shared.Scale)
local Tags = require(ReplicatedStorage.Shared.Tags)
local PartBuilder = require(script.Parent.Parent.PartBuilder)
local Layout = require(script.Parent.Layout)

local cm = Scale.cm
local vec = Scale.vec

local Structure = {}

local Palette = {
	Wall = Color3.fromRGB(247, 234, 208),
	WallTrim = Color3.fromRGB(252, 250, 244),
	Ceiling = Color3.fromRGB(250, 248, 242),
	TileA = Color3.fromRGB(238, 230, 214),
	TileB = Color3.fromRGB(206, 188, 162),
	Grout = Color3.fromRGB(150, 138, 122),
	Glass = Color3.fromRGB(200, 226, 240),
	Frame = Color3.fromRGB(252, 250, 244),
	Door = Color3.fromRGB(214, 176, 128),
	DoorDark = Color3.fromRGB(188, 150, 104),
	Lawn = Color3.fromRGB(96, 156, 72),
	Hedge = Color3.fromRGB(62, 118, 58),
	Trunk = Color3.fromRGB(110, 82, 56),
	Canopy = Color3.fromRGB(74, 140, 70),
	VentDark = Color3.fromRGB(38, 36, 44),
	VentGlow = Color3.fromRGB(168, 96, 255),
}

local Materials = {
	Plaster = PartBuilder.safeMaterial("Plaster", Enum.Material.SmoothPlastic),
	Tile = Enum.Material.Marble,
	Grout = Enum.Material.Concrete,
	Wood = Enum.Material.Wood,
	Glass = Enum.Material.Glass,
	Grass = Enum.Material.Grass,
	LeafyGrass = PartBuilder.safeMaterial("LeafyGrass", Enum.Material.Grass),
	Metal = Enum.Material.Metal,
	DiamondPlate = Enum.Material.DiamondPlate,
}

type Opening = { from: number, to: number, bottom: number, top: number }

--[[
	Builds a wall as several boxes so rectangular openings (windows/doors) can
	be cut out. `axis` is the axis the wall runs along ("X" for north/south,
	"Z" for east/west). `across` is the wall's centre on the other axis.
]]
local function buildWall(
	parent: Instance,
	name: string,
	axis: "X" | "Z",
	from: number,
	to: number,
	across: number,
	height: number,
	thickness: number,
	openings: { Opening }
)
	table.sort(openings, function(a, b)
		return a.from < b.from
	end)

	local function piece(a: number, b: number, bottom: number, top: number, suffix: string)
		if b - a <= 0.01 or top - bottom <= 0.01 then
			return
		end
		local length = b - a
		local centerAlong = (a + b) / 2
		local size = if axis == "X" then vec(length, top - bottom, thickness) else vec(thickness, top - bottom, length)
		local bottomCenter = if axis == "X" then vec(centerAlong, bottom, across) else vec(across, bottom, centerAlong)
		PartBuilder.box(size, bottomCenter, {
			Name = name .. suffix,
			Color = Palette.Wall,
			Material = Materials.Plaster,
			Parent = parent,
		})
	end

	local cursor = from
	for index, opening in openings do
		piece(cursor, opening.from, 0, height, ("_%d"):format(index))
		piece(opening.from, opening.to, 0, opening.bottom, ("_Below%d"):format(index))
		piece(opening.from, opening.to, opening.top, height, ("_Above%d"):format(index))
		cursor = opening.to
	end
	piece(cursor, to, 0, height, "_End")
end

local function buildFloor(parent: Instance)
	local room = Layout.Room
	local halfW = room.Width / 2
	local halfD = room.Depth / 2
	local tile = room.TileSize
	local gap = 0.6

	-- Grout base sits slightly below the tile tops so the grout lines read as tiny grooves.
	PartBuilder.box(
		vec(room.Width + room.WallThickness * 2, 1.2, room.Depth + room.WallThickness * 2),
		vec(0, -1.5, 0),
		{
			Name = "Grout",
			Color = Palette.Grout,
			Material = Materials.Grout,
			Parent = parent,
		}
	)

	local tilesX = math.floor(room.Width / tile)
	local tilesZ = math.floor(room.Depth / tile)
	for ix = 0, tilesX - 1 do
		for iz = 0, tilesZ - 1 do
			local x = -halfW + tile * (ix + 0.5)
			local z = -halfD + tile * (iz + 0.5)
			local isA = (ix + iz) % 2 == 0
			PartBuilder.box(vec(tile - gap, 1.5, tile - gap), vec(x, -1.5, z), {
				Name = ("Tile_%d_%d"):format(ix, iz),
				Color = if isA then Palette.TileA else Palette.TileB,
				Material = Materials.Tile,
				Reflectance = 0.04,
				CastShadow = false,
				Parent = parent,
			})
		end
	end
end

local function buildWalls(parent: Instance)
	local room = Layout.Room
	local halfW = room.Width / 2
	local halfD = room.Depth / 2
	local t = room.WallThickness
	local windows = Layout.Windows
	local door = Layout.Door

	-- North wall (Z = -halfD) with the window above the sink.
	buildWall(parent, "WallNorth", "X", -halfW - t, halfW + t, -halfD - t / 2, room.Height, t, {
		{ from = windows.North.xMin, to = windows.North.xMax, bottom = windows.North.yMin, top = windows.North.yMax },
	})
	-- South wall with the second window.
	buildWall(parent, "WallSouth", "X", -halfW - t, halfW + t, halfD + t / 2, room.Height, t, {
		{ from = windows.South.xMin, to = windows.South.xMax, bottom = windows.South.yMin, top = windows.South.yMax },
	})
	-- West wall with the door opening.
	buildWall(parent, "WallWest", "Z", -halfD, halfD, -halfW - t / 2, room.Height, t, {
		{ from = door.ZMin, to = door.ZMax, bottom = 0, top = door.Height },
	})
	-- East wall, solid.
	buildWall(parent, "WallEast", "Z", -halfD, halfD, halfW + t / 2, room.Height, t, {})

	-- Ceiling.
	PartBuilder.box(vec(room.Width + t * 2, t, room.Depth + t * 2), vec(0, room.Height, 0), {
		Name = "Ceiling",
		Color = Palette.Ceiling,
		Material = Materials.Plaster,
		Parent = parent,
	})

	-- Baseboards along the interior faces.
	local bb = room.BaseboardHeight
	local bt = 1.2
	PartBuilder.box(vec(room.Width, bb, bt), vec(0, 0, -halfD + bt / 2), {
		Name = "BaseboardNorth",
		Color = Palette.WallTrim,
		Parent = parent,
	})
	PartBuilder.box(vec(room.Width, bb, bt), vec(0, 0, halfD - bt / 2), {
		Name = "BaseboardSouth",
		Color = Palette.WallTrim,
		Parent = parent,
	})
	PartBuilder.box(vec(bt, bb, room.Depth), vec(halfW - bt / 2, 0, 0), {
		Name = "BaseboardEast",
		Color = Palette.WallTrim,
		Parent = parent,
	})
	-- West baseboard is split around the door.
	local westSegments = { { -halfD, door.ZMin }, { door.ZMax, halfD } }
	for index, segment in westSegments do
		local length = segment[2] - segment[1]
		PartBuilder.box(vec(bt, bb, length), vec(-halfW + bt / 2, 0, (segment[1] + segment[2]) / 2), {
			Name = ("BaseboardWest%d"):format(index),
			Color = Palette.WallTrim,
			Parent = parent,
		})
	end
end

local function buildWindow(parent: Instance, name: string, wallZ: number, inwardSign: number, opening: Opening)
	local t = Layout.Room.WallThickness
	local width = opening.to - opening.from
	local height = opening.top - opening.bottom
	local centerX = (opening.from + opening.to) / 2
	local frameWidth = 5
	local frameDepth = t

	-- Frame: two jambs, head and sill-frame.
	for _, side in { opening.from + frameWidth / 2, opening.to - frameWidth / 2 } do
		PartBuilder.box(vec(frameWidth, height, frameDepth), vec(side, opening.bottom, wallZ), {
			Name = name .. "Jamb",
			Color = Palette.Frame,
			Parent = parent,
		})
	end
	PartBuilder.box(vec(width, frameWidth, frameDepth), vec(centerX, opening.top - frameWidth, wallZ), {
		Name = name .. "Head",
		Color = Palette.Frame,
		Parent = parent,
	})
	PartBuilder.box(vec(width, frameWidth, frameDepth), vec(centerX, opening.bottom, wallZ), {
		Name = name .. "SillFrame",
		Color = Palette.Frame,
		Parent = parent,
	})
	-- Centre mullion and a horizontal bar.
	PartBuilder.box(vec(3, height - frameWidth * 2, 3), vec(centerX, opening.bottom + frameWidth, wallZ), {
		Name = name .. "Mullion",
		Color = Palette.Frame,
		Parent = parent,
	})
	PartBuilder.box(vec(width - frameWidth * 2, 3, 3), vec(centerX, opening.bottom + height * 0.55, wallZ), {
		Name = name .. "Bar",
		Color = Palette.Frame,
		Parent = parent,
	})

	-- Glass pane: see-through, lets real sunlight in (no shadow casting).
	PartBuilder.box(
		vec(width - frameWidth * 2, height - frameWidth * 2, 0.8),
		vec(centerX, opening.bottom + frameWidth, wallZ),
		{
			Name = name .. "Glass",
			Color = Palette.Glass,
			Material = Materials.Glass,
			Transparency = 0.6,
			Reflectance = 0.12,
			CastShadow = false,
			Parent = parent,
			Tags = { Tags.CameraIgnore },
		}
	)

	-- Interior sill ledge.
	local sillDepth = 10
	local sillZ = wallZ + inwardSign * (t / 2 + sillDepth / 2 - 0.5)
	PartBuilder.box(vec(width + 12, 3, sillDepth), vec(centerX, opening.bottom - 3, sillZ), {
		Name = name .. "Sill",
		Color = Palette.Frame,
		Material = Materials.Wood,
		Parent = parent,
	})
end

local function buildDoor(parent: Instance)
	local room = Layout.Room
	local door = Layout.Door
	local t = room.WallThickness
	local wallX = -room.Width / 2 - t / 2
	local centerZ = (door.ZMin + door.ZMax) / 2
	local width = door.ZMax - door.ZMin

	-- Frame.
	local jambWidth = 6
	for _, z in { door.ZMin - jambWidth / 2, door.ZMax + jambWidth / 2 } do
		PartBuilder.box(vec(t + 2, door.Height + jambWidth, jambWidth), vec(wallX, 0, z), {
			Name = "DoorJamb",
			Color = Palette.Frame,
			Parent = parent,
		})
	end
	PartBuilder.box(vec(t + 2, jambWidth, width), vec(wallX, door.Height, centerZ), {
		Name = "DoorHead",
		Color = Palette.Frame,
		Parent = parent,
	})

	-- Door panel with a gap at the bottom that lets light through.
	local panelHeight = door.Height - door.FloorGap - 0.5
	local panel = PartBuilder.box(vec(door.Thickness, panelHeight, width - 1), vec(wallX, door.FloorGap, centerZ), {
		Name = "DoorPanel",
		Color = Palette.Door,
		Material = Materials.Wood,
		Parent = parent,
	})
	-- Decorative inset panels on the kitchen-facing side.
	local faceX = wallX + door.Thickness / 2 + 0.3
	for _, insetY in { 30, 115 } do
		PartBuilder.box(vec(0.6, 60, width - 24), vec(faceX, insetY, centerZ), {
			Name = "DoorInset",
			Color = Palette.DoorDark,
			Material = Materials.Wood,
			CanCollide = false,
			Parent = parent,
		})
	end
	-- Knob.
	PartBuilder.ball({
		Name = "DoorKnob",
		Size = vec(5, 5, 5),
		Position = vec(wallX + door.Thickness / 2 + 2.5, 95, door.ZMax - 10),
		Color = Color3.fromRGB(214, 178, 96),
		Material = Materials.Metal,
		Reflectance = 0.3,
		Parent = parent,
	})
	-- Warm light leaking under the door from the living room.
	PartBuilder.box(vec(1.2, door.FloorGap - 0.4, width - 6), vec(wallX - 1, 0.2, centerZ), {
		Name = "DoorLightLeak",
		Color = Color3.fromRGB(255, 222, 160),
		Material = Enum.Material.Neon,
		CanCollide = false,
		CastShadow = false,
		Parent = parent,
	})
	-- Dark block behind the door so the void is never visible through the gap.
	PartBuilder.box(vec(140, room.Height + 20, 180), vec(wallX - t / 2 - 71, -10, centerZ), {
		Name = "HallwayBlocker",
		Color = Color3.fromRGB(28, 24, 30),
		Material = Materials.Plaster,
		Parent = parent,
	})
	return panel
end

local function buildVent(parent: Instance)
	local fridge = Layout.Fridge
	local wallZ = -Layout.Room.Depth / 2
	local centerX = (fridge.XMin + fridge.XMax) / 2
	local ventWidth = 30
	local ventBottom = 2
	local ventHeight = 14

	-- Purple glow behind the slats.
	local glow = PartBuilder.box(vec(ventWidth, ventHeight - 2, 0.4), vec(centerX, ventBottom + 1, wallZ + 0.2), {
		Name = "VentGlow",
		Color = Palette.VentGlow,
		Material = Enum.Material.Neon,
		CanCollide = false,
		CastShadow = false,
		Parent = parent,
	})
	PartBuilder.pointLight(glow, Palette.VentGlow, 1.6, 60)

	-- Slatted grille.
	local slatCount = 5
	local slatHeight = ventHeight / slatCount * 0.55
	for index = 0, slatCount - 1 do
		local y = ventBottom + (ventHeight / slatCount) * index
		PartBuilder.box(vec(ventWidth, slatHeight, 1), vec(centerX, y, wallZ + 0.9), {
			Name = "VentSlat",
			Color = Palette.VentDark,
			Material = Materials.DiamondPlate,
			Parent = parent,
		})
	end
	for _, side in { centerX - ventWidth / 2 - 1, centerX + ventWidth / 2 + 1 } do
		PartBuilder.box(vec(2, ventHeight + 2, 1.2), vec(side, ventBottom - 1, wallZ + 1), {
			Name = "VentFrame",
			Color = Palette.VentDark,
			Material = Materials.Metal,
			Parent = parent,
		})
	end
	PartBuilder.box(vec(ventWidth + 4, 1.5, 1.2), vec(centerX, ventBottom + ventHeight + 0.5, wallZ + 1), {
		Name = "VentFrameTop",
		Color = Palette.VentDark,
		Material = Materials.Metal,
		Parent = parent,
	})
end

local function buildTree(parent: Instance, x: number, z: number, scale: number)
	local trunkHeight = 180 * scale
	PartBuilder.cylinderY(cm(14 * scale), cm(trunkHeight), vec(x, -15, z), {
		Name = "TreeTrunk",
		Color = Palette.Trunk,
		Material = Materials.Wood,
		Parent = parent,
	})
	local canopyRadius = 110 * scale
	PartBuilder.ellipsoid(
		vec(canopyRadius * 2, canopyRadius * 1.6, canopyRadius * 2),
		vec(x, -15 + trunkHeight + canopyRadius * 0.5, z),
		{
			Name = "TreeCanopy",
			Color = Palette.Canopy,
			Material = Materials.LeafyGrass,
			CanCollide = false,
			Parent = parent,
		}
	)
	PartBuilder.ellipsoid(
		vec(canopyRadius * 1.4, canopyRadius * 1.2, canopyRadius * 1.4),
		vec(x + canopyRadius * 0.5, -15 + trunkHeight + canopyRadius * 0.9, z - canopyRadius * 0.3),
		{
			Name = "TreeCanopy2",
			Color = Color3.fromRGB(92, 160, 82),
			Material = Materials.LeafyGrass,
			CanCollide = false,
			Parent = parent,
		}
	)
end

local function buildExterior(parent: Instance)
	local room = Layout.Room
	local halfD = room.Depth / 2
	local t = room.WallThickness

	for _, sign in { -1, 1 } do
		local depth = 760
		local centerZ = sign * (halfD + t + depth / 2 + 2)
		PartBuilder.box(vec(1800, 10, depth), vec(0, -25, centerZ), {
			Name = if sign < 0 then "LawnNorth" else "LawnSouth",
			Color = Palette.Lawn,
			Material = Materials.Grass,
			Parent = parent,
		})
		-- Hedge line parallel to the house.
		PartBuilder.box(vec(900, 80, 40), vec(sign * 60, -15, sign * (halfD + t + 160)), {
			Name = "Hedge",
			Color = Palette.Hedge,
			Material = Materials.LeafyGrass,
			Parent = parent,
		})
	end
	-- Side lawns so the ground never ends abruptly.
	for _, sign in { -1, 1 } do
		PartBuilder.box(vec(700, 10, room.Depth + t * 2 + 4), vec(sign * (room.Width / 2 + t + 352), -25, 0), {
			Name = "LawnSide",
			Color = Palette.Lawn,
			Material = Materials.Grass,
			Parent = parent,
		})
	end

	buildTree(parent, -260, -440, 1.0)
	buildTree(parent, 140, -560, 1.25)
	buildTree(parent, 430, -400, 0.9)
	buildTree(parent, 300, 470, 1.1)
	buildTree(parent, -150, 560, 1.3)
	buildTree(parent, -520, 300, 1.0)
end

function Structure.build(parent: Instance)
	local structure = PartBuilder.folder("Structure", parent)
	buildFloor(PartBuilder.folder("Floor", structure))
	buildWalls(PartBuilder.folder("Walls", structure))

	local windows = PartBuilder.folder("Windows", structure)
	local halfD = Layout.Room.Depth / 2
	local t = Layout.Room.WallThickness
	local north = Layout.Windows.North
	local south = Layout.Windows.South
	buildWindow(
		windows,
		"WindowNorth",
		-halfD - t / 2,
		1,
		{ from = north.xMin, to = north.xMax, bottom = north.yMin, top = north.yMax }
	)
	buildWindow(
		windows,
		"WindowSouth",
		halfD + t / 2,
		-1,
		{ from = south.xMin, to = south.xMax, bottom = south.yMin, top = south.yMax }
	)

	buildDoor(PartBuilder.folder("Door", structure))
	buildVent(PartBuilder.folder("Vent", structure))
	buildExterior(PartBuilder.folder("Exterior", structure))
end

return Structure
