--!strict
--[[
	Props
	-----
	Small decorative objects that sell the scale: plates, cookies, bottles,
	a cereal box, fruit, a toaster, a kettle, bread on a cutting board, a
	dropped fork, a thread spool, a cat toy and assorted kitchen clutter.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Scale = require(ReplicatedStorage.Shared.Scale)
local Tags = require(ReplicatedStorage.Shared.Tags)
local PartBuilder = require(script.Parent.Parent.PartBuilder)
local Layout = require(script.Parent.Layout)

local cm = Scale.cm
local vec = Scale.vec

local Props = {}

local Materials = {
	Plastic = Enum.Material.SmoothPlastic,
	Metal = Enum.Material.Metal,
	Glass = Enum.Material.Glass,
	Wood = Enum.Material.Wood,
	Fabric = Enum.Material.Fabric,
	Sand = Enum.Material.Sand,
	Cardboard = PartBuilder.safeMaterial("Cardboard", Enum.Material.SmoothPlastic),
}

local TABLE_TOP = Layout.Table.Height + Layout.Table.ClothThickness
local COUNTER_TOP = Layout.Counter.Height

local function buildTableProps(parent: Instance)
	local TY = TABLE_TOP

	-- Plate with a cookie.
	PartBuilder.cylinderY(cm(12), cm(1.2), vec(-72, TY, 55), {
		Name = "Plate",
		Color = Color3.fromRGB(250, 250, 248),
		Material = Materials.Plastic,
		Reflectance = 0.08,
		Parent = parent,
	})
	PartBuilder.cylinderY(cm(9), cm(0.2), vec(-72, TY + 1.2, 55), {
		Name = "PlatePattern",
		Color = Color3.fromRGB(170, 200, 230),
		Material = Materials.Plastic,
		CanCollide = false,
		CastShadow = false,
		Parent = parent,
	})
	local cookie = PartBuilder.cylinderY(cm(5), cm(1.2), vec(-74, TY + 1.4, 52), {
		Name = "Cookie",
		Color = Color3.fromRGB(205, 150, 90),
		Material = Materials.Sand,
		Parent = parent,
	})
	local random = Random.new(11)
	for _ = 1, 5 do
		local angle = random:NextNumber(0, math.pi * 2)
		local distance = random:NextNumber(0.5, 3.6)
		PartBuilder.ball({
			Name = "ChocolateChip",
			Size = vec(1.4, 1.4, 1.4),
			Position = cookie.Position
				+ Vector3.new(cm(math.cos(angle) * distance), cm(0.6), cm(math.sin(angle) * distance)),
			Color = Color3.fromRGB(60, 36, 24),
			Material = Materials.Plastic,
			CanCollide = false,
			CastShadow = false,
			Parent = parent,
		})
	end

	-- Glass of water.
	PartBuilder.cylinderY(cm(3.5), cm(12), vec(-15, TY, 45), {
		Name = "DrinkingGlass",
		Color = Color3.fromRGB(220, 235, 245),
		Material = Materials.Glass,
		Transparency = 0.55,
		Reflectance = 0.15,
		Parent = parent,
		Tags = { Tags.CameraIgnore },
	})
	PartBuilder.cylinderY(cm(3.1), cm(7), vec(-15, TY + 0.5, 45), {
		Name = "GlassWater",
		Color = Color3.fromRGB(150, 200, 235),
		Material = Materials.Glass,
		Transparency = 0.4,
		CanCollide = false,
		CastShadow = false,
		Parent = parent,
		Tags = { Tags.Water },
	})

	-- Ketchup bottle.
	PartBuilder.cylinderY(cm(3.5), cm(16), vec(5, TY, 70), {
		Name = "KetchupBottle",
		Color = Color3.fromRGB(200, 40, 40),
		Material = Materials.Plastic,
		Reflectance = 0.05,
		Parent = parent,
	})
	PartBuilder.cylinderY(cm(3.65), cm(6), vec(5, TY + 5, 70), {
		Name = "KetchupLabel",
		Color = Color3.fromRGB(248, 244, 230),
		Material = Materials.Plastic,
		CanCollide = false,
		CastShadow = false,
		Parent = parent,
	})
	PartBuilder.cylinderY(cm(2.2), cm(2), vec(5, TY + 16, 70), {
		Name = "KetchupNeck",
		Color = Color3.fromRGB(200, 40, 40),
		Material = Materials.Plastic,
		Parent = parent,
	})
	PartBuilder.cylinderY(cm(2.4), cm(3), vec(5, TY + 18, 70), {
		Name = "KetchupCap",
		Color = Color3.fromRGB(250, 250, 250),
		Material = Materials.Plastic,
		Parent = parent,
	})

	-- Cereal box.
	local cereal = PartBuilder.boxYaw(vec(20, 30, 7), vec(-90, TY, 84), 0.15, {
		Name = "CerealBox",
		Color = Color3.fromRGB(255, 196, 48),
		Material = Materials.Cardboard,
		Parent = parent,
	})
	PartBuilder.surfaceText(
		cereal,
		Enum.NormalId.Front,
		"CRUNCH-O's",
		Color3.fromRGB(40, 60, 160),
		Enum.Font.FredokaOne
	)
	PartBuilder.surfaceText(cereal, Enum.NormalId.Back, "CRUNCH-O's", Color3.fromRGB(40, 60, 160), Enum.Font.FredokaOne)

	-- Fruit bowl with apples.
	local bowlX, bowlZ = -40, 72
	PartBuilder.cylinderY(cm(12), cm(1.2), vec(bowlX, TY, bowlZ), {
		Name = "FruitBowlBase",
		Color = Color3.fromRGB(70, 150, 150),
		Material = Materials.Plastic,
		Parent = parent,
	})
	local segments = 14
	for index = 0, segments - 1 do
		local angle = (index / segments) * math.pi * 2
		PartBuilder.part({
			Name = "FruitBowlRim",
			Size = vec(1.5, 6, 2 * 12 * math.sin(math.pi / segments) + 1),
			CFrame = CFrame.new(vec(bowlX + math.cos(angle) * 12, TY + 3, bowlZ + math.sin(angle) * 12))
				* CFrame.Angles(0, -angle, 0),
			Color = Color3.fromRGB(70, 150, 150),
			Material = Materials.Plastic,
			Parent = parent,
		})
	end
	local apples = {
		{ x = bowlX - 4, y = TY + 1.2 + 4, z = bowlZ - 2, color = Color3.fromRGB(210, 50, 50) },
		{ x = bowlX + 4, y = TY + 1.2 + 4, z = bowlZ + 3, color = Color3.fromRGB(150, 200, 70) },
		{ x = bowlX, y = TY + 1.2 + 9.5, z = bowlZ + 1, color = Color3.fromRGB(220, 70, 60) },
	}
	for _, apple in apples do
		PartBuilder.ball({
			Name = "Apple",
			Size = vec(8, 8, 8),
			Position = vec(apple.x, apple.y, apple.z),
			Color = apple.color,
			Material = Materials.Plastic,
			Reflectance = 0.05,
			CanCollide = false,
			Parent = parent,
		})
		PartBuilder.cylinderY(cm(0.3), cm(2), vec(apple.x, apple.y + 3.6, apple.z), {
			Name = "AppleStem",
			Color = Color3.fromRGB(90, 60, 40),
			Material = Materials.Wood,
			CanCollide = false,
			CastShadow = false,
			Parent = parent,
		})
	end

	-- Toothpick holder with toothpicks sticking out.
	PartBuilder.cylinderY(cm(2.5), cm(5), vec(-20, TY, 85), {
		Name = "ToothpickHolder",
		Color = Color3.fromRGB(90, 62, 40),
		Material = Materials.Wood,
		Parent = parent,
	})
	for index = 1, 6 do
		local yaw = index * 1.05
		local tilt = math.rad(14)
		local direction = Vector3.new(math.sin(yaw) * math.sin(tilt), math.cos(tilt), math.cos(yaw) * math.sin(tilt))
		local base = vec(-20 + math.sin(yaw) * 1.2, TY + 1.5, 85 + math.cos(yaw) * 1.2)
		PartBuilder.cylinderAlong(cm(0.12), cm(6.5), base + direction * cm(3.25), direction, {
			Name = "HolderToothpick",
			Color = Color3.fromRGB(214, 180, 122),
			Material = Materials.Wood,
			CanCollide = false,
			CastShadow = false,
			Parent = parent,
		})
	end

	-- Salt shaker.
	PartBuilder.cylinderY(cm(2), cm(6), vec(0, TY, 88), {
		Name = "SaltShaker",
		Color = Color3.fromRGB(245, 245, 245),
		Material = Materials.Glass,
		Transparency = 0.3,
		Parent = parent,
	})
	PartBuilder.cylinderY(cm(2.1), cm(1.5), vec(0, TY + 6, 88), {
		Name = "SaltCap",
		Color = Color3.fromRGB(196, 200, 204),
		Material = Materials.Metal,
		Parent = parent,
	})

	-- Napkin.
	PartBuilder.boxYaw(vec(12, 0.4, 12), vec(-55, TY, 42), 0.3, {
		Name = "Napkin",
		Color = Color3.fromRGB(250, 248, 240),
		Material = Materials.Fabric,
		CanCollide = false,
		CastShadow = false,
		Parent = parent,
	})
end

local function buildCounterProps(parent: Instance)
	local CY = COUNTER_TOP

	-- Toaster.
	local toasterX, toasterZ = -100, -125
	PartBuilder.box(vec(28, 18, 18), vec(toasterX, CY, toasterZ), {
		Name = "Toaster",
		Color = Color3.fromRGB(200, 204, 210),
		Material = Materials.Metal,
		Reflectance = 0.35,
		Parent = parent,
	})
	for _, dz in { -3, 3 } do
		PartBuilder.box(vec(20, 0.6, 2), vec(toasterX, CY + 18, toasterZ + dz), {
			Name = "ToasterSlot",
			Color = Color3.fromRGB(30, 30, 34),
			Material = Materials.Plastic,
			CanCollide = false,
			Parent = parent,
		})
	end
	PartBuilder.box(vec(2, 1.2, 3), vec(toasterX - 10, CY + 8, toasterZ + 9), {
		Name = "ToasterLever",
		Color = Color3.fromRGB(40, 40, 44),
		Material = Materials.Plastic,
		CanCollide = false,
		Parent = parent,
	})
	-- Power cord to the backsplash socket.
	local cordStart = vec(toasterX, CY + 2, toasterZ - 9)
	local cordEnd = vec(toasterX, CY + 14, Layout.Counter.ZMin + 1.5)
	PartBuilder.cylinderAlong(
		cm(0.5),
		(cordEnd - cordStart).Magnitude,
		(cordStart + cordEnd) / 2,
		cordEnd - cordStart,
		{
			Name = "ToasterCord",
			Color = Color3.fromRGB(30, 30, 34),
			Material = Materials.Plastic,
			CanCollide = false,
			CastShadow = false,
			Parent = parent,
		}
	)
	PartBuilder.box(vec(7, 7, 0.8), vec(toasterX, CY + 10.5, Layout.Counter.ZMin + 1.1), {
		Name = "Socket",
		Color = Color3.fromRGB(250, 250, 248),
		Material = Materials.Plastic,
		CanCollide = false,
		Parent = parent,
	})

	-- Kettle on the back-left burner.
	local kettleX, kettleZ = -165, -135
	local kettleBase = CY + 2.8
	PartBuilder.cylinderY(cm(9), cm(14), vec(kettleX, kettleBase, kettleZ), {
		Name = "Kettle",
		Color = Color3.fromRGB(210, 212, 216),
		Material = Materials.Metal,
		Reflectance = 0.35,
		Parent = parent,
	})
	PartBuilder.cylinderY(cm(5), cm(2), vec(kettleX, kettleBase + 14, kettleZ), {
		Name = "KettleLid",
		Color = Color3.fromRGB(190, 192, 196),
		Material = Materials.Metal,
		Parent = parent,
	})
	PartBuilder.ball({
		Name = "KettleKnob",
		Size = vec(3, 3, 3),
		Position = vec(kettleX, kettleBase + 17, kettleZ),
		Color = Color3.fromRGB(40, 40, 44),
		Material = Materials.Plastic,
		CanCollide = false,
		Parent = parent,
	})
	local spoutDirection = Vector3.new(1, 0.9, 0).Unit
	PartBuilder.cylinderAlong(
		cm(1.4),
		cm(10),
		vec(kettleX + 9, kettleBase + 9, kettleZ) + spoutDirection * cm(4),
		spoutDirection,
		{
			Name = "KettleSpout",
			Color = Color3.fromRGB(210, 212, 216),
			Material = Materials.Metal,
			CanCollide = false,
			Parent = parent,
		}
	)
	-- Arched handle.
	PartBuilder.box(vec(1.5, 8, 1.5), vec(kettleX - 7, kettleBase + 14, kettleZ), {
		Name = "KettleHandle",
		Color = Color3.fromRGB(40, 40, 44),
		Material = Materials.Plastic,
		CanCollide = false,
		Parent = parent,
	})
	PartBuilder.box(vec(1.5, 8, 1.5), vec(kettleX + 7, kettleBase + 14, kettleZ), {
		Name = "KettleHandle",
		Color = Color3.fromRGB(40, 40, 44),
		Material = Materials.Plastic,
		CanCollide = false,
		Parent = parent,
	})
	PartBuilder.box(vec(15.5, 1.5, 1.5), vec(kettleX, kettleBase + 22, kettleZ), {
		Name = "KettleHandleTop",
		Color = Color3.fromRGB(40, 40, 44),
		Material = Materials.Plastic,
		CanCollide = false,
		Parent = parent,
	})

	-- Cutting board, bread and knife.
	local boardX, boardZ = 20, -125
	PartBuilder.box(vec(30, 2, 20), vec(boardX, CY, boardZ), {
		Name = "CuttingBoard",
		Color = Color3.fromRGB(190, 150, 100),
		Material = Materials.Wood,
		Parent = parent,
	})
	local loafX, loafZ = 14, -122
	PartBuilder.box(vec(16, 6, 9), vec(loafX, CY + 2, loafZ), {
		Name = "BreadLoaf",
		Color = Color3.fromRGB(196, 140, 84),
		Material = Materials.Sand,
		Parent = parent,
	})
	PartBuilder.cylinderAlong(cm(4.5), cm(16), vec(loafX, CY + 8, loafZ), Vector3.xAxis, {
		Name = "BreadCrust",
		Color = Color3.fromRGB(186, 128, 72),
		Material = Materials.Sand,
		CanCollide = false,
		Parent = parent,
	})
	for _, sliceX in { 24.5, 26.5 } do
		PartBuilder.box(vec(1.4, 7, 8.5), vec(sliceX, CY + 2, loafZ), {
			Name = "BreadSlice",
			Color = Color3.fromRGB(240, 228, 200),
			Material = Materials.Sand,
			Parent = parent,
		})
	end
	PartBuilder.boxYaw(vec(14, 0.3, 2.5), vec(26, CY + 2, -131), 0.2, {
		Name = "KnifeBlade",
		Color = Color3.fromRGB(210, 214, 220),
		Material = Materials.Metal,
		Reflectance = 0.4,
		CanCollide = false,
		Parent = parent,
	})
	PartBuilder.boxYaw(vec(7, 1.8, 2.2), vec(36, CY + 2, -133), 0.2, {
		Name = "KnifeHandle",
		Color = Color3.fromRGB(40, 36, 36),
		Material = Materials.Plastic,
		Parent = parent,
	})

	-- Sponge and dish soap by the sink.
	PartBuilder.box(vec(10, 3, 7), vec(-30, CY, -94), {
		Name = "Sponge",
		Color = Color3.fromRGB(240, 210, 60),
		Material = Materials.Fabric,
		Parent = parent,
	})
	PartBuilder.box(vec(10, 0.8, 7), vec(-30, CY + 3, -94), {
		Name = "SpongeScrub",
		Color = Color3.fromRGB(70, 150, 70),
		Material = Materials.Fabric,
		CanCollide = false,
		Parent = parent,
	})
	PartBuilder.cylinderY(cm(3), cm(18), vec(-60, CY, -94), {
		Name = "DishSoap",
		Color = Color3.fromRGB(120, 200, 90),
		Material = Materials.Plastic,
		Transparency = 0.15,
		Parent = parent,
	})
	PartBuilder.cylinderY(cm(1), cm(4), vec(-60, CY + 18, -94), {
		Name = "DishSoapPump",
		Color = Color3.fromRGB(250, 250, 250),
		Material = Materials.Plastic,
		CanCollide = false,
		Parent = parent,
	})

	-- Cookie jar.
	PartBuilder.cylinderY(cm(8), cm(20), vec(30, CY, -140), {
		Name = "CookieJar",
		Color = Color3.fromRGB(235, 240, 245),
		Material = Materials.Glass,
		Transparency = 0.5,
		Reflectance = 0.1,
		Parent = parent,
		Tags = { Tags.CameraIgnore },
	})
	for index = 0, 3 do
		PartBuilder.cylinderY(cm(5), cm(1.2), vec(30 + (index % 2) * 1.5, CY + 0.6 + index * 1.4, -140), {
			Name = "JarCookie",
			Color = Color3.fromRGB(205, 150, 90),
			Material = Materials.Sand,
			CanCollide = false,
			CastShadow = false,
			Parent = parent,
		})
	end
	PartBuilder.cylinderY(cm(8.5), cm(3), vec(30, CY + 20, -140), {
		Name = "CookieJarLid",
		Color = Color3.fromRGB(190, 150, 100),
		Material = Materials.Wood,
		Parent = parent,
	})

	-- Mug with a C-shaped handle.
	local mugX, mugZ = -78, -108
	PartBuilder.cylinderY(cm(4.5), cm(9), vec(mugX, CY, mugZ), {
		Name = "Mug",
		Color = Color3.fromRGB(70, 110, 190),
		Material = Materials.Plastic,
		Reflectance = 0.08,
		Parent = parent,
	})
	PartBuilder.box(vec(1.4, 5, 1.4), vec(mugX + 7, CY + 2, mugZ), {
		Name = "MugHandle",
		Color = Color3.fromRGB(70, 110, 190),
		Material = Materials.Plastic,
		CanCollide = false,
		Parent = parent,
	})
	for _, y in { CY + 2, CY + 6.5 } do
		PartBuilder.box(vec(3.5, 1.4, 1.4), vec(mugX + 5.5, y, mugZ), {
			Name = "MugHandleBar",
			Color = Color3.fromRGB(70, 110, 190),
			Material = Materials.Plastic,
			CanCollide = false,
			Parent = parent,
		})
	end
	-- Spilled sugar near the mug.
	local random = Random.new(23)
	for _ = 1, 10 do
		PartBuilder.ball({
			Name = "SugarGrain",
			Size = vec(0.5, 0.5, 0.5),
			Position = vec(mugX + random:NextNumber(5, 14), CY + 0.25, mugZ + random:NextNumber(-6, 6)),
			Color = Color3.fromRGB(252, 252, 250),
			Material = Materials.Plastic,
			CanCollide = false,
			CastShadow = false,
			Parent = parent,
		})
	end

	-- Phone charging on the counter (its cable is the climbing route by the stool).
	PartBuilder.box(vec(7, 0.8, 14), vec(38, CY, -108), {
		Name = "Phone",
		Color = Color3.fromRGB(30, 30, 34),
		Material = Materials.Glass,
		Reflectance = 0.2,
		Parent = parent,
	})
end

local function buildFloorProps(parent: Instance)
	-- Dropped fork south of the table.
	local forkX, forkZ = -35, 140
	local yaw = 0.4
	local base = CFrame.new(vec(forkX, 0, forkZ)) * CFrame.Angles(0, yaw, 0)
	PartBuilder.part({
		Name = "ForkHandle",
		Size = vec(11, 0.5, 2.2),
		CFrame = base * CFrame.new(-cm(3), cm(0.25), 0),
		Color = Color3.fromRGB(205, 210, 216),
		Material = Materials.Metal,
		Reflectance = 0.4,
		Parent = parent,
	})
	PartBuilder.part({
		Name = "ForkNeck",
		Size = vec(3, 0.5, 3),
		CFrame = base * CFrame.new(cm(4), cm(0.25), 0),
		Color = Color3.fromRGB(205, 210, 216),
		Material = Materials.Metal,
		Reflectance = 0.4,
		Parent = parent,
	})
	for index = 0, 3 do
		PartBuilder.part({
			Name = "ForkTine",
			Size = vec(4.5, 0.4, 0.4),
			CFrame = base * CFrame.new(cm(7.5), cm(0.2), cm(-1.2 + index * 0.8)),
			Color = Color3.fromRGB(205, 210, 216),
			Material = Materials.Metal,
			Reflectance = 0.4,
			Parent = parent,
		})
	end

	-- Thread spool near the west chair.
	local spoolX, spoolZ = -125, 30
	PartBuilder.cylinderY(cm(2.5), cm(4.5), vec(spoolX, 0, spoolZ), {
		Name = "Spool",
		Color = Color3.fromRGB(190, 150, 100),
		Material = Materials.Wood,
		Parent = parent,
	})
	PartBuilder.cylinderY(cm(2.9), cm(3.2), vec(spoolX, 0.65, spoolZ), {
		Name = "SpoolThread",
		Color = Color3.fromRGB(214, 86, 112),
		Material = Materials.Fabric,
		Parent = parent,
	})
	PartBuilder.cylinderAlong(cm(0.15), cm(14), vec(spoolX + 7, 0.15, spoolZ + 3), Vector3.new(1, 0, 0.4), {
		Name = "LooseThread",
		Color = Color3.fromRGB(214, 86, 112),
		Material = Materials.Fabric,
		CanCollide = false,
		CastShadow = false,
		Parent = parent,
	})

	-- Broken wooden spoon near the trash.
	local spoonX, spoonZ = 150, -84
	PartBuilder.cylinderAlong(cm(1.1), cm(12), vec(spoonX - 7, 1.1, spoonZ), Vector3.new(1, 0, 0.2), {
		Name = "SpoonHandle",
		Color = Color3.fromRGB(180, 130, 80),
		Material = Materials.Wood,
		Parent = parent,
	})
	PartBuilder.ellipsoid(vec(7, 1.4, 4.5), vec(spoonX + 4, 0.7, spoonZ + 2), {
		Name = "SpoonBowl",
		Color = Color3.fromRGB(180, 130, 80),
		Material = Materials.Wood,
		CanCollide = false,
		Parent = parent,
	})

	-- Crumpled paper and a plastic fork by the trash can.
	PartBuilder.ball({
		Name = "CrumpledPaper",
		Size = vec(9, 9, 9),
		Position = vec(172, 4.5, -98),
		Color = Color3.fromRGB(240, 236, 228),
		Material = Materials.Plastic,
		Parent = parent,
	})
	local forkBase = CFrame.new(vec(144, 0, -88)) * CFrame.Angles(0, 0.6, 0)
	PartBuilder.part({
		Name = "PlasticForkHandle",
		Size = vec(10, 0.6, 1.8),
		CFrame = forkBase * CFrame.new(0, cm(0.3), 0),
		Color = Color3.fromRGB(240, 240, 240),
		Material = Materials.Plastic,
		Parent = parent,
	})
	for index = 0, 2 do
		PartBuilder.part({
			Name = "PlasticForkTine",
			Size = vec(3, 0.5, 0.4),
			CFrame = forkBase * CFrame.new(cm(6.5), cm(0.25), cm(-0.6 + index * 0.6)),
			Color = Color3.fromRGB(240, 240, 240),
			Material = Materials.Plastic,
			CanCollide = false,
			Parent = parent,
		})
	end

	-- Felt cat toy under the table: a reminder of who else lives here.
	local mouseX, mouseZ = -95, 55
	PartBuilder.ellipsoid(vec(6, 4, 9), vec(mouseX, 2, mouseZ), {
		Name = "ToyMouse",
		Color = Color3.fromRGB(150, 150, 160),
		Material = Materials.Fabric,
		CFrame = CFrame.new(vec(mouseX, 2, mouseZ)) * CFrame.Angles(0, 0.8, 0),
		Parent = parent,
	})
	for _, side in { -1, 1 } do
		PartBuilder.ball({
			Name = "ToyMouseEar",
			Size = vec(2.2, 2.2, 2.2),
			Position = vec(mouseX + side * 1.6 * math.cos(0.8), 4.2, mouseZ - 3.2 - side * 1.6 * math.sin(0.8)),
			Color = Color3.fromRGB(230, 150, 170),
			Material = Materials.Fabric,
			CanCollide = false,
			CastShadow = false,
			Parent = parent,
		})
	end
	PartBuilder.cylinderAlong(cm(0.3), cm(8), vec(mouseX - 3, 0.5, mouseZ + 6), Vector3.new(-0.5, 0, 1), {
		Name = "ToyMouseTail",
		Color = Color3.fromRGB(230, 150, 170),
		Material = Materials.Fabric,
		CanCollide = false,
		CastShadow = false,
		Parent = parent,
	})

	-- Dust bunnies in the gap behind the fridge.
	for index = 0, 2 do
		local x = 85 + index * 22
		PartBuilder.ellipsoid(vec(5, 2, 4), vec(x, 1, -148), {
			Name = "DustBunny",
			Color = Color3.fromRGB(120, 116, 110),
			Material = Materials.Fabric,
			CanCollide = false,
			CastShadow = false,
			Parent = parent,
		})
	end
end

function Props.build(parent: Instance)
	local props = PartBuilder.folder("Props", parent)
	buildTableProps(PartBuilder.model("TableProps", props))
	buildCounterProps(PartBuilder.model("CounterProps", props))
	buildFloorProps(PartBuilder.model("FloorProps", props))
end

return Props
