--!strict
--[[
	InteractionPrompt
	-----------------
	Custom world-space UI for ProximityPrompts: key glyph, resource icon,
	name and a hold progress bar. Also works as a click/touch target by
	forwarding holds to the prompt (prompt:InputHoldBegin/End).
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ResourceDefinitions = require(ReplicatedStorage.Shared.Config.ResourceDefinitions)
local Theme = require(script.Parent.Theme)
local UIBuilder = require(script.Parent.UIBuilder)

local InteractionPrompt = {}

export type PromptUI = {
	gui: BillboardGui,
	setHolding: (self: PromptUI, holding: boolean) -> (),
	setKeyGlyph: (self: PromptUI, glyph: string) -> (),
	destroy: (self: PromptUI) -> (),
}

function InteractionPrompt.create(prompt: ProximityPrompt, keyGlyph: string, parent: Instance): PromptUI
	local adornee = prompt.Parent
	local model = prompt:FindFirstAncestorOfClass("Model")
	local resourceId = if model then model:GetAttribute("ResourceId") else nil
	local amount = if model then model:GetAttribute("Amount") else nil
	local definition = if typeof(resourceId) == "string" then ResourceDefinitions.get(resourceId :: string) else nil

	local glyph = if definition then definition.icon else "✦"
	local color = if definition then definition.color else Theme.Colors.Accent
	local objectText = prompt.ObjectText
	if objectText == "" then
		objectText = if definition then definition.name else "Item"
	end
	if definition and typeof(amount) == "number" and (amount :: number) > 1 then
		objectText = ("%s  x%d"):format(definition.name, amount :: number)
	end

	local gui = UIBuilder.create("BillboardGui", {
		Name = "InteractionPrompt",
		Adornee = adornee,
		Size = UDim2.fromOffset(236, 64),
		StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0),
		AlwaysOnTop = true,
		MaxDistance = 60,
		ResetOnSpawn = false,
		LightInfluence = 0,
		Parent = parent,
	}) :: BillboardGui

	local panel = UIBuilder.create("TextButton", {
		Name = "Panel",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Parent = gui,
	}) :: TextButton
	UIBuilder.corner(panel, 12)
	UIBuilder.stroke(panel, color, 1.5, 0.35)

	local keyBox = UIBuilder.create("Frame", {
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.fromOffset(34, 34),
		BackgroundColor3 = Theme.Colors.Text,
		BorderSizePixel = 0,
		Parent = panel,
	}) :: Frame
	UIBuilder.corner(keyBox, 8)
	local keyLabel = UIBuilder.label({
		Text = keyGlyph,
		Font = Theme.Fonts.Heading,
		TextSize = 16,
		TextColor3 = Theme.Colors.TextDark,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 1),
		Parent = keyBox,
	})

	local tile = UIBuilder.iconTile(panel, glyph, color, 30)
	tile.Position = UDim2.fromOffset(52, 12)

	UIBuilder.label({
		Text = objectText,
		Font = Theme.Fonts.Heading,
		TextSize = 15,
		Position = UDim2.fromOffset(90, 9),
		Size = UDim2.new(1, -100, 0, 20),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = panel,
	})
	UIBuilder.label({
		Text = "Hold to " .. string.lower(prompt.ActionText),
		Font = Theme.Fonts.Body,
		TextSize = 13,
		TextColor3 = Theme.Colors.TextMuted,
		Position = UDim2.fromOffset(90, 29),
		Size = UDim2.new(1, -100, 0, 16),
		Parent = panel,
	})

	local track = UIBuilder.create("Frame", {
		Position = UDim2.new(0, 10, 1, -8),
		Size = UDim2.new(1, -20, 0, 4),
		BackgroundColor3 = Theme.Colors.BarTrack,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		Parent = panel,
	}) :: Frame
	UIBuilder.corner(track, 2)
	local fill = UIBuilder.create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = track,
	}) :: Frame
	UIBuilder.corner(fill, 2)

	-- Pop-in animation.
	panel.Size = UDim2.fromScale(0.85, 0.85)
	panel.Position = UDim2.fromScale(0.075, 0.075)
	TweenService:Create(panel, Theme.Tween.Bounce, { Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(0, 0) })
		:Play()

	local holdTween: Tween? = nil
	local connections: { RBXScriptConnection } = {}

	local function setHolding(_: PromptUI, holding: boolean)
		if holdTween then
			(holdTween :: Tween):Cancel()
			holdTween = nil
		end
		if holding then
			local duration = math.max(0.05, prompt.HoldDuration)
			local tween = TweenService:Create(
				fill,
				TweenInfo.new(duration, Enum.EasingStyle.Linear),
				{ Size = UDim2.fromScale(1, 1) }
			)
			holdTween = tween
			tween:Play()
		else
			local tween = TweenService:Create(fill, Theme.Tween.Fast, { Size = UDim2.fromScale(0, 1) })
			holdTween = tween
			tween:Play()
		end
	end

	-- Click / touch support: forward presses on the panel to the prompt.
	table.insert(
		connections,
		panel.InputBegan:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				prompt:InputHoldBegin()
			end
		end)
	)
	table.insert(
		connections,
		panel.InputEnded:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				prompt:InputHoldEnd()
			end
		end)
	)

	local ui: PromptUI
	ui = {
		gui = gui,
		setHolding = setHolding,
		setKeyGlyph = function(_, newGlyph: string)
			keyLabel.Text = newGlyph
		end,
		destroy = function(_)
			for _, connection in connections do
				connection:Disconnect()
			end
			table.clear(connections)
			if holdTween then
				(holdTween :: Tween):Cancel()
			end
			gui:Destroy()
		end,
	}
	return ui
end

return InteractionPrompt
