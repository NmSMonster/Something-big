--!strict
--[[
	Hud
	---
	Builds the in-game HUD tree and returns typed references so
	HudController can update it without searching the hierarchy.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local ResourceDefinitions = require(ReplicatedStorage.Shared.Config.ResourceDefinitions)
local Theme = require(script.Parent.Theme)
local UIBuilder = require(script.Parent.UIBuilder)

local Hud = {}

export type StatBar = {
	frame: Frame,
	track: Frame,
	fill: Frame,
	value: TextLabel,
	tile: Frame,
}

export type PouchRow = {
	frame: Frame,
	count: TextLabel,
}

export type Hud = {
	gui: ScreenGui,
	root: Frame,
	scale: UIScale,
	vitals: Frame,
	health: StatBar,
	stamina: StatBar,
	pouch: Frame,
	pouchList: Frame,
	pouchCapacity: TextLabel,
	pouchEmpty: TextLabel,
	pouchRows: { [string]: PouchRow },
	objective: Frame,
	objectiveTitle: TextLabel,
	objectiveDescription: TextLabel,
	objectiveProgress: TextLabel,
	objectiveFill: Frame,
	objectiveHint: TextLabel,
	objectiveBadge: TextLabel,
	controlsHint: Frame,
	crosshair: Frame,
	damageFlash: Frame,
	notifications: Frame,
}

local function buildStatBar(parent: Instance, glyph: string, color: Color3, colorDark: Color3, order: number): StatBar
	local frame = UIBuilder.frame({
		Size = UDim2.new(1, 0, 0, 30),
		LayoutOrder = order,
		Parent = parent,
	})
	local tile = UIBuilder.iconTile(frame, glyph, color, 28)
	tile.Position = UDim2.fromOffset(0, 1)

	local barHolder = UIBuilder.frame({
		Position = UDim2.fromOffset(38, 9),
		Size = UDim2.new(1, -84, 0, 12),
		Parent = frame,
	})
	local track, fill = UIBuilder.bar(barHolder, 12, color, colorDark)

	local value = UIBuilder.label({
		Text = "100",
		Font = Theme.Fonts.Heading,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(1, -40, 0, 0),
		Size = UDim2.new(0, 40, 0, 30),
		Parent = frame,
	})

	return {
		frame = frame,
		track = track,
		fill = fill,
		value = value,
		tile = tile,
	}
end

local function buildVitals(root: Instance): (Frame, StatBar, StatBar)
	local panel = UIBuilder.panel({
		Name = "Vitals",
		Position = UDim2.fromOffset(20, 20),
		Size = UDim2.fromOffset(290, 98),
		Parent = root,
	})
	UIBuilder.padding(panel, 12, 10)
	UIBuilder.list(panel, Enum.FillDirection.Vertical, 8)
	local health = buildStatBar(panel, "❤", Theme.Colors.Health, Theme.Colors.HealthDark, 1)
	local stamina = buildStatBar(panel, "⚡", Theme.Colors.Stamina, Theme.Colors.StaminaDark, 2)
	return panel, health, stamina
end

local function buildPouch(root: Instance): (Frame, Frame, TextLabel, TextLabel)
	local panel = UIBuilder.panel({
		Name = "Pouch",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -20, 0, 20),
		Size = UDim2.fromOffset(236, 60),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = root,
	})
	UIBuilder.padding(panel, 12, 10)
	UIBuilder.list(panel, Enum.FillDirection.Vertical, 6)

	local header = UIBuilder.frame({
		Size = UDim2.new(1, 0, 0, 22),
		LayoutOrder = 1,
		Parent = panel,
	})
	UIBuilder.label({
		Text = "POUCH",
		Font = Theme.Fonts.Heading,
		TextSize = 13,
		TextColor3 = Theme.Colors.TextMuted,
		Size = UDim2.new(0.5, 0, 1, 0),
		Parent = header,
	})
	local capacity = UIBuilder.label({
		Text = ("0 / %d"):format(GameConfig.Inventory.Capacity),
		Font = Theme.Fonts.Heading,
		TextSize = 13,
		TextColor3 = Theme.Colors.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.new(0.5, 0, 1, 0),
		Parent = header,
	})

	local empty = UIBuilder.label({
		Text = "Nothing yet. Look for sparkles.",
		Font = Theme.Fonts.Body,
		TextSize = 14,
		TextColor3 = Theme.Colors.TextMuted,
		Size = UDim2.new(1, 0, 0, 20),
		LayoutOrder = 2,
		Parent = panel,
	})

	local list = UIBuilder.frame({
		Name = "List",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 3,
		Parent = panel,
	})
	UIBuilder.list(list, Enum.FillDirection.Vertical, 4)

	return panel, list, capacity, empty
end

function Hud.buildPouchRow(list: Frame, resourceId: string): PouchRow
	local definition = ResourceDefinitions.get(resourceId)
	local name = if definition then definition.name else resourceId
	local glyph = if definition then definition.icon else "?"
	local color = if definition then definition.color else Theme.Colors.PanelLight

	local frame = UIBuilder.frame({
		Name = resourceId,
		Size = UDim2.new(1, 0, 0, 30),
		LayoutOrder = if definition then definition.sortOrder else 99,
		Parent = list,
	})
	local tile = UIBuilder.iconTile(frame, glyph, color, 26)
	tile.Position = UDim2.fromOffset(0, 2)
	UIBuilder.label({
		Text = name,
		Font = Theme.Fonts.BodyMedium,
		TextSize = 15,
		Position = UDim2.fromOffset(34, 0),
		Size = UDim2.new(1, -84, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = frame,
	})
	local count = UIBuilder.label({
		Text = "x0",
		Font = Theme.Fonts.Heading,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(1, -48, 0, 0),
		Size = UDim2.new(0, 48, 1, 0),
		Parent = frame,
	})
	return { frame = frame, count = count }
end

local function buildObjective(root: Instance): (Frame, TextLabel, TextLabel, TextLabel, Frame, TextLabel, TextLabel)
	local panel = UIBuilder.panel({
		Name = "Objective",
		Position = UDim2.fromOffset(20, 132),
		Size = UDim2.fromOffset(290, 60),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = root,
	})
	UIBuilder.padding(panel, 12, 10)
	UIBuilder.list(panel, Enum.FillDirection.Vertical, 5)

	local header = UIBuilder.frame({
		Size = UDim2.new(1, 0, 0, 18),
		LayoutOrder = 1,
		Parent = panel,
	})
	UIBuilder.label({
		Text = "OBJECTIVE",
		Font = Theme.Fonts.Heading,
		TextSize = 13,
		TextColor3 = Theme.Colors.Objective,
		Size = UDim2.new(0.6, 0, 1, 0),
		Parent = header,
	})
	local badge = UIBuilder.label({
		Text = "",
		Font = Theme.Fonts.Heading,
		TextSize = 13,
		TextColor3 = Theme.Colors.Success,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.fromScale(0.6, 0),
		Size = UDim2.new(0.4, 0, 1, 0),
		Parent = header,
	})

	local title = UIBuilder.label({
		Text = "",
		Font = Theme.Fonts.Heading,
		TextSize = 17,
		TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 22),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
		Parent = panel,
	})
	local description = UIBuilder.label({
		Text = "",
		Font = Theme.Fonts.Body,
		TextSize = 14,
		TextWrapped = true,
		TextColor3 = Theme.Colors.TextMuted,
		Size = UDim2.new(1, 0, 0, 18),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 3,
		Parent = panel,
	})

	local progressRow = UIBuilder.frame({
		Size = UDim2.new(1, 0, 0, 16),
		LayoutOrder = 4,
		Parent = panel,
	})
	local barHolder = UIBuilder.frame({
		Position = UDim2.fromOffset(0, 3),
		Size = UDim2.new(1, -56, 0, 10),
		Parent = progressRow,
	})
	local _, fill =
		UIBuilder.bar(barHolder, 10, Theme.Colors.Objective, Theme.Colors.Objective:Lerp(Color3.new(0, 0, 0), 0.3))
	local progress = UIBuilder.label({
		Text = "0 / 0",
		Font = Theme.Fonts.Heading,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(1, -50, 0, 0),
		Size = UDim2.new(0, 50, 1, 0),
		Parent = progressRow,
	})

	local hint = UIBuilder.label({
		Text = "",
		Font = Theme.Fonts.Body,
		TextSize = 13,
		TextWrapped = true,
		TextColor3 = Theme.Colors.TextMuted:Lerp(Theme.Colors.Objective, 0.4),
		Size = UDim2.new(1, 0, 0, 16),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 5,
		Parent = panel,
	})

	return panel, title, description, progress, fill, hint, badge
end

local function buildControlsHint(root: Instance): Frame
	local panel = UIBuilder.panel({
		Name = "ControlsHint",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 20, 1, -20),
		Size = UDim2.fromOffset(250, 10),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = root,
	})
	UIBuilder.padding(panel, 12, 10)
	UIBuilder.list(panel, Enum.FillDirection.Vertical, 4)
	UIBuilder.label({
		Text = "CONTROLS",
		Font = Theme.Fonts.Heading,
		TextSize = 13,
		TextColor3 = Theme.Colors.TextMuted,
		Size = UDim2.new(1, 0, 0, 16),
		LayoutOrder = 1,
		Parent = panel,
	})
	local rows = {
		{ "WASD", "Move" },
		{ "Shift", "Sprint" },
		{ "Space", "Jump" },
		{ "Ctrl / C", "Crouch" },
		{ "E (hold)", "Collect" },
		{ "Alt", "Free cursor" },
		{ "M", "Menu" },
	}
	for index, row in rows do
		local line = UIBuilder.frame({
			Size = UDim2.new(1, 0, 0, 18),
			LayoutOrder = index + 1,
			Parent = panel,
		})
		UIBuilder.label({
			Text = row[1],
			Font = Theme.Fonts.Heading,
			TextSize = 14,
			TextColor3 = Theme.Colors.Accent,
			Size = UDim2.new(0, 92, 1, 0),
			Parent = line,
		})
		UIBuilder.label({
			Text = row[2],
			Font = Theme.Fonts.Body,
			TextSize = 14,
			Position = UDim2.fromOffset(96, 0),
			Size = UDim2.new(1, -96, 1, 0),
			Parent = line,
		})
	end
	return panel
end

function Hud.build(parent: Instance): Hud
	local gui = UIBuilder.screenGui("TinyTroubleHUD", 10)

	local root = UIBuilder.frame({
		Name = "Root",
		Parent = gui,
	})
	local scale = UIBuilder.create("UIScale", { Scale = 1, Parent = root }) :: UIScale

	local vitals, health, stamina = buildVitals(root)
	local pouch, pouchList, pouchCapacity, pouchEmpty = buildPouch(root)
	local objective, objectiveTitle, objectiveDescription, objectiveProgress, objectiveFill, objectiveHint, objectiveBadge =
		buildObjective(root)
	local controlsHint = buildControlsHint(root)

	local crosshair = UIBuilder.create("Frame", {
		Name = "Crosshair",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(6, 6),
		BackgroundColor3 = Theme.Colors.Text,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Visible = false,
		Parent = root,
	}) :: Frame
	UIBuilder.corner(crosshair, 3)

	local damageFlash = UIBuilder.create("Frame", {
		Name = "DamageFlash",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Colors.Danger,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = root,
	}) :: Frame

	local notifications = UIBuilder.frame({
		Name = "Notifications",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -20, 1, -20),
		Size = UDim2.fromOffset(320, 400),
		Parent = root,
	})
	UIBuilder.list(
		notifications,
		Enum.FillDirection.Vertical,
		8,
		Enum.HorizontalAlignment.Right,
		Enum.VerticalAlignment.Bottom
	)

	gui.Parent = parent

	return {
		gui = gui,
		root = root,
		scale = scale,
		vitals = vitals,
		health = health,
		stamina = stamina,
		pouch = pouch,
		pouchList = pouchList,
		pouchCapacity = pouchCapacity,
		pouchEmpty = pouchEmpty,
		pouchRows = {},
		objective = objective,
		objectiveTitle = objectiveTitle,
		objectiveDescription = objectiveDescription,
		objectiveProgress = objectiveProgress,
		objectiveFill = objectiveFill,
		objectiveHint = objectiveHint,
		objectiveBadge = objectiveBadge,
		controlsHint = controlsHint,
		crosshair = crosshair,
		damageFlash = damageFlash,
		notifications = notifications,
	}
end

return Hud
