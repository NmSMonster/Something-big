--!strict
--[[
	ResourceDefinitions
	-------------------
	Every raw material a player can gather. `icon` is a Unicode glyph used by
	the HUD until custom icon images are added (set `imageId` to use one).
]]

export type ResourceDefinition = {
	id: string,
	name: string,
	plural: string,
	description: string,
	icon: string,
	imageId: string?,
	color: Color3,
	stackSize: number,
	category: "material" | "food" | "water",
	sortOrder: number,
}

local ResourceDefinitions = {}

local list: { ResourceDefinition } = {
	{
		id = "FoodCrumb",
		name = "Bread Crumb",
		plural = "Bread Crumbs",
		description = "A golden chunk of toast crust. Bigger than your head and twice as tasty.",
		icon = "🍞",
		color = Color3.fromRGB(222, 170, 92),
		stackSize = 50,
		category = "food",
		sortOrder = 1,
	},
	{
		id = "Toothpick",
		name = "Toothpick",
		plural = "Toothpicks",
		description = "A sturdy wooden spike. In your hands it is a spear-sized beam.",
		icon = "🥢",
		color = Color3.fromRGB(214, 180, 122),
		stackSize = 20,
		category = "material",
		sortOrder = 2,
	},
	{
		id = "Thread",
		name = "Thread",
		plural = "Thread",
		description = "A loose strand of cotton. Strong enough to be rope at this size.",
		icon = "🧵",
		color = Color3.fromRGB(214, 86, 112),
		stackSize = 40,
		category = "material",
		sortOrder = 3,
	},
	{
		id = "WoodSplinter",
		name = "Wood Splinter",
		plural = "Wood Splinters",
		description = "Splintered off a chair leg. Perfect building material.",
		icon = "🪵",
		color = Color3.fromRGB(164, 112, 64),
		stackSize = 40,
		category = "material",
		sortOrder = 4,
	},
	{
		id = "PlasticFragment",
		name = "Plastic Fragment",
		plural = "Plastic Fragments",
		description = "A shard of a broken fork. Light, bright and surprisingly sharp.",
		icon = "🧩",
		color = Color3.fromRGB(86, 196, 232),
		stackSize = 40,
		category = "material",
		sortOrder = 5,
	},
	{
		id = "MetalScrap",
		name = "Metal Scrap",
		plural = "Metal Scraps",
		description = "A bent paperclip or stray screw. Heavy, but it makes real tools.",
		icon = "🔩",
		color = Color3.fromRGB(170, 176, 190),
		stackSize = 30,
		category = "material",
		sortOrder = 6,
	},
	{
		id = "BottleCap",
		name = "Bottle Cap",
		plural = "Bottle Caps",
		description = "A ridged metal cap. Could become a shield, a bowl or a boat.",
		icon = "🪙",
		color = Color3.fromRGB(232, 72, 72),
		stackSize = 10,
		category = "material",
		sortOrder = 7,
	},
	{
		id = "PlantFiber",
		name = "Plant Fiber",
		plural = "Plant Fibers",
		description = "Dry fibrous strands from the potted plant. Weave them into cord.",
		icon = "🌿",
		color = Color3.fromRGB(116, 188, 98),
		stackSize = 40,
		category = "material",
		sortOrder = 8,
	},
}

ResourceDefinitions.List = list
ResourceDefinitions.ById = {} :: { [string]: ResourceDefinition }
for _, definition in list do
	ResourceDefinitions.ById[definition.id] = definition
end

function ResourceDefinitions.get(id: string): ResourceDefinition?
	return ResourceDefinitions.ById[id]
end

function ResourceDefinitions.isValidId(id: unknown): boolean
	return typeof(id) == "string" and ResourceDefinitions.ById[id :: string] ~= nil
end

return ResourceDefinitions
