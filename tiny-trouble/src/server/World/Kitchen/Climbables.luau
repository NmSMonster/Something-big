--!strict
--[[
	Climbables
	----------
	Traversal routes for a 2.5 cm explorer. Humanoids climb TrussParts
	natively, so every vertical route is a truss disguised as a household
	object (cloth folds, a charger cable, a towel) and every slope is a wedge.

	Routes built here:
	  1. Chair leg cloth -> seat -> tablecloth fold -> table top (two chairs)
	  2. Tablecloth draped off the east edge of the table (walkable ramp)
	  3. Dish towel over the counter edge -> counter top
	  4. Dish cloth on the step stool -> stool top -> charger cable -> counter top
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Scale = require(ReplicatedStorage.Shared.Scale)
local Tags = require(ReplicatedStorage.Shared.Tags)
local PartBuilder = require(script.Parent.Parent.PartBuilder)
local Layout = require(script.Parent.Layout)

local cm = Scale.cm
local vec = Scale.vec

local Climbables = {}

local Palette = {
	Cloth = Color3.fromRGB(248, 240, 224),
	Towel = Color3.fromRGB(236, 232, 220),
	TowelStripe = Color3.fromRGB(200, 70, 70),
	Cable = Color3.fromRGB(40, 40, 44),
	DishCloth = Color3.fromRGB(120, 170, 200),
}

--[[
	Vertical truss from `bottomY` to `topY` at (x, z). Width is one centimetre
	(2 studs). `color` tints the truss to match the object it pretends to be.
]]
local function climbTruss(
	parent: Instance,
	name: string,
	x: number,
	z: number,
	bottomY: number,
	topY: number,
	color: Color3
)
	local height = topY - bottomY
	return PartBuilder.truss({
		Name = name,
		Size = vec(1, height, 1),
		CFrame = CFrame.new(vec(x, bottomY + height / 2, z)),
		Color = color,
		Material = Enum.Material.Fabric,
		Parent = parent,
		Tags = { Tags.Climbable },
	})
end

local function fabricStrip(parent: Instance, name: string, size: Vector3, bottomCenter: Vector3, color: Color3)
	return PartBuilder.box(size, bottomCenter, {
		Name = name,
		Color = color,
		Material = Enum.Material.Fabric,
		CanCollide = false,
		Parent = parent,
	})
end

local function buildChairRoutes(parent: Instance)
	local CH = Layout.Chair
	local T = Layout.Table
	local half = CH.SeatSize / 2
	local routeIndex = 0

	for _, chair in Layout.Chairs do
		if not chair.climbRoute then
			continue
		end
		routeIndex += 1
		local side = if routeIndex % 2 == 1 then -1 else 1
		local legZ = chair.z + chair.facing * CH.LegInset
		local trussX = chair.x + side * (half + 1)

		-- Cloth draped down the chair leg (seat edge -> floor), climbable.
		fabricStrip(
			parent,
			"ChairCloth",
			vec(7, CH.SeatHeight + 2, 1),
			vec(trussX - side * 0.2, 0, legZ),
			Palette.Cloth
		)
		climbTruss(parent, "ChairClimb", trussX + side * 0.5, legZ, 0, CH.SeatHeight + 8, Palette.Cloth)

		-- Tablecloth fold hanging over the table edge above the seat.
		local tableEdgeZ = T.CenterZ - chair.facing * (T.Depth / 2)
		local stripZ = tableEdgeZ - chair.facing * 0.9
		local foldTop = T.Height + T.ClothThickness
		fabricStrip(
			parent,
			"ClothFold",
			vec(7, foldTop - (CH.SeatHeight + CH.SeatThickness), 0.8),
			vec(chair.x, CH.SeatHeight + CH.SeatThickness, stripZ),
			Palette.Cloth
		)
		PartBuilder.box(vec(7, 0.7, 5), vec(chair.x, foldTop, tableEdgeZ + chair.facing * 2.5), {
			Name = "ClothFoldTop",
			Color = Palette.Cloth,
			Material = Enum.Material.Fabric,
			CanCollide = false,
			Parent = parent,
		})
		climbTruss(
			parent,
			"TableClimb",
			chair.x,
			stripZ - chair.facing * 1.1,
			CH.SeatHeight + CH.SeatThickness,
			foldTop + 5,
			Palette.Cloth
		)
	end
end

local function buildTableDrape(parent: Instance)
	local T = Layout.Table
	local edgeX = T.CenterX + T.Width / 2
	local top = T.Height + T.ClothThickness
	local high = vec(edgeX, top, T.CenterZ)
	local low = vec(edgeX + 75, 0, T.CenterZ)
	PartBuilder.ramp(high, low, cm(40), {
		Name = "TableclothDrape",
		Color = Palette.Cloth,
		Material = Enum.Material.Fabric,
		Parent = parent,
		Tags = { Tags.Climbable },
	})
	-- Red stripe continuing down the drape (visual only).
	local stripeHigh = vec(edgeX + 0.2, top + 0.2, T.CenterZ)
	local stripeLow = vec(edgeX + 75.2, 0.2, T.CenterZ)
	PartBuilder.ramp(stripeHigh, stripeLow, cm(2.5), {
		Name = "DrapeStripe",
		Color = Color3.fromRGB(200, 70, 70),
		Material = Enum.Material.Fabric,
		CanCollide = false,
		CastShadow = false,
		Parent = parent,
	})
end

local function buildTowelRoute(parent: Instance)
	local C = Layout.Counter
	local towelX = -90
	local edgeZ = C.TopZMax
	local hangZ = edgeZ + 0.8

	fabricStrip(parent, "DishTowel", vec(28, C.Height - 0.5, 1.2), vec(towelX, 0.5, hangZ), Palette.Towel)
	for _, y in { 20, 38, 56 } do
		fabricStrip(parent, "TowelStripe", vec(28, 4, 1.4), vec(towelX, y, hangZ), Palette.TowelStripe)
	end
	-- The towel's top lies flat on the counter.
	PartBuilder.box(vec(28, 1, 14), vec(towelX, C.Height, edgeZ - 7), {
		Name = "DishTowelTop",
		Color = Palette.Towel,
		Material = Enum.Material.Fabric,
		Parent = parent,
	})
	climbTruss(parent, "TowelClimb", towelX, hangZ + 1.1, 0, C.Height + 3, Palette.Towel)
end

local function buildStoolRoute(parent: Instance)
	local SS = Layout.StepStool
	local C = Layout.Counter
	local topStep = SS.StepHeights[2]
	local eastX = SS.CenterX + SS.Width / 2
	local upperZ = SS.CenterZ - SS.Depth / 4

	-- Dish cloth hanging off the east side of the stool.
	fabricStrip(parent, "StoolCloth", vec(1, topStep + 1, 9), vec(eastX + 0.6, 0, upperZ), Palette.DishCloth)
	PartBuilder.box(vec(8, 0.8, 9), vec(eastX - 3.5, topStep, upperZ), {
		Name = "StoolClothTop",
		Color = Palette.DishCloth,
		Material = Enum.Material.Fabric,
		CanCollide = false,
		Parent = parent,
	})
	climbTruss(parent, "StoolClimb", eastX + 1.7, upperZ, 0, topStep + 4, Palette.DishCloth)

	-- Charger cable from the phone on the counter down to the stool. The truss hugs the
	-- countertop edge so topping out steps straight onto the counter.
	local cableX = SS.CenterX
	local cableZ = C.TopZMax + 0.5
	climbTruss(parent, "CableClimb", cableX, cableZ, topStep - 2, C.Height + 3, Palette.Cable)
	PartBuilder.cylinderAlong(
		cm(0.4),
		cm(20),
		vec(cableX + 6, C.Height + 0.4, C.TopZMax - 9),
		Vector3.new(1, 0, -0.9),
		{
			Name = "CableOnCounter",
			Color = Palette.Cable,
			Material = Enum.Material.SmoothPlastic,
			CanCollide = false,
			CastShadow = false,
			Parent = parent,
		}
	)
	PartBuilder.box(vec(2, 0.8, 1.2), vec(cableX, C.Height, C.TopZMax - 1), {
		Name = "CablePlug",
		Color = Palette.Cable,
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
		Parent = parent,
	})
	-- Cable slack coiled on the stool's top step.
	PartBuilder.cylinderAlong(cm(0.4), cm(12), vec(cableX - 4, topStep + 0.4, upperZ), Vector3.new(1, 0, 0.3), {
		Name = "CableOnStool",
		Color = Palette.Cable,
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
		CastShadow = false,
		Parent = parent,
	})
end

function Climbables.build(parent: Instance)
	local folder = PartBuilder.folder("Climbables", parent)
	buildChairRoutes(folder)
	buildTableDrape(folder)
	buildTowelRoute(folder)
	buildStoolRoute(folder)
end

return Climbables
