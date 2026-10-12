--!strict
--[[
	ObjectiveDefinitions
	--------------------
	The Milestone 1 "foundation" objective chain. Objectives are completed in
	order and give players a clear goal from the first second. Milestone 2
	replaces this chain with the full introductory quest line and persistence,
	using the same data shape.
]]

export type ObjectiveReward = {
	resourceId: string,
	amount: number,
}

export type ObjectiveDefinition = {
	id: string,
	title: string,
	description: string,
	hint: string,
	kind: "collect" | "reach",
	resourceId: string?, -- for "collect"
	zoneId: string?, -- for "reach"
	target: number,
	rewards: { ObjectiveReward },
	completionMessage: string?,
}

local ObjectiveDefinitions = {}

local list: { ObjectiveDefinition } = {
	{
		id = "wake_up",
		title = "A very small breakfast",
		description = "Collect 5 bread crumbs from around the dining table.",
		hint = "Crumbs sparkle faintly. Check beneath the chairs.",
		kind = "collect",
		resourceId = "FoodCrumb",
		target = 5,
		rewards = { { resourceId = "Thread", amount = 2 } },
	},
	{
		id = "tooling_up",
		title = "Tooling up",
		description = "Gather 3 toothpicks. They make excellent spears.",
		hint = "A few fell from the holder on the table and rolled under it.",
		kind = "collect",
		resourceId = "Toothpick",
		target = 3,
		rewards = { { resourceId = "WoodSplinter", amount = 2 } },
	},
	{
		id = "table_summit",
		title = "The tablecloth climb",
		description = "Reach the top of the dining table.",
		hint = "Chair rungs are climbable, and the tablecloth hangs down to the floor on the east side.",
		kind = "reach",
		zoneId = "TableTop",
		target = 1,
		rewards = { { resourceId = "FoodCrumb", amount = 3 } },
	},
	{
		id = "counter_top",
		title = "Over the counter",
		description = "Climb up onto the kitchen counter.",
		hint = "A dish towel hangs over the counter edge, and a charger cable dangles down to the step stool.",
		kind = "reach",
		zoneId = "CounterTop",
		target = 1,
		rewards = { { resourceId = "BottleCap", amount = 1 }, { resourceId = "MetalScrap", amount = 1 } },
	},
	{
		id = "fridge_gap",
		title = "Something behind the fridge",
		description = "Squeeze into the gap behind the refrigerator.",
		hint = "The refrigerator doesn't quite touch the wall...",
		kind = "reach",
		zoneId = "BehindFridge",
		target = 1,
		rewards = { { resourceId = "PlasticFragment", amount = 2 } },
		completionMessage = "A faint purple glow seeps through a vent in the wall. Someone has been here before you... (to be continued)",
	},
}

ObjectiveDefinitions.List = list
ObjectiveDefinitions.ById = {} :: { [string]: ObjectiveDefinition }
for _, definition in list do
	ObjectiveDefinitions.ById[definition.id] = definition
end

function ObjectiveDefinitions.get(index: number): ObjectiveDefinition?
	return ObjectiveDefinitions.List[index]
end

return ObjectiveDefinitions
