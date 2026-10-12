--!strict
--[[
	UIBuilder
	---------
	Declarative helpers for building GUI trees from code. Rojo projects keep
	UI in scripts so it is diffable, reviewable and themeable.

		local panel = UIBuilder.panel({ Size = UDim2.fromOffset(280, 96), Parent = root })
		UIBuilder.label({ Text = "Health", Parent = panel })
]]

local Theme = require(script.Parent.Theme)

local UIBuilder = {}

export type Props = { [string]: any }

local function applyProps(instance: Instance, props: Props?)
	if not props then
		return
	end
	local parent: Instance? = nil
	for key, value in props do
		if key == "Parent" then
			parent = value
		elseif key == "Children" then
			for _, child in value :: { Instance } do
				child.Parent = instance
			end
		else
			(instance :: any)[key] = value
		end
	end
	if parent then
		instance.Parent = parent
	end
end

function UIBuilder.create(className: string, props: Props?): Instance
	local instance = Instance.new(className)
	applyProps(instance, props)
	return instance
end

function UIBuilder.corner(parent: Instance, radius: number?): UICorner
	return UIBuilder.create("UICorner", {
		CornerRadius = UDim.new(0, radius or Theme.Metrics.Radius),
		Parent = parent,
	}) :: UICorner
end

function UIBuilder.stroke(parent: Instance, color: Color3?, thickness: number?, transparency: number?): UIStroke
	return UIBuilder.create("UIStroke", {
		Color = color or Theme.Colors.PanelStroke,
		Thickness = thickness or 1,
		Transparency = if transparency == nil then Theme.Metrics.StrokeTransparency else transparency,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	}) :: UIStroke
end

function UIBuilder.padding(parent: Instance, all: number, vertical: number?): UIPadding
	local v = if vertical == nil then all else vertical
	return UIBuilder.create("UIPadding", {
		PaddingLeft = UDim.new(0, all),
		PaddingRight = UDim.new(0, all),
		PaddingTop = UDim.new(0, v),
		PaddingBottom = UDim.new(0, v),
		Parent = parent,
	}) :: UIPadding
end

function UIBuilder.gradient(parent: Instance, from: Color3, to: Color3, rotation: number?): UIGradient
	return UIBuilder.create("UIGradient", {
		Color = ColorSequence.new(from, to),
		Rotation = rotation or 0,
		Parent = parent,
	}) :: UIGradient
end

function UIBuilder.list(
	parent: Instance,
	direction: Enum.FillDirection?,
	gap: number?,
	horizontal: Enum.HorizontalAlignment?,
	vertical: Enum.VerticalAlignment?
): UIListLayout
	return UIBuilder.create("UIListLayout", {
		FillDirection = direction or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, gap or Theme.Metrics.Gap),
		HorizontalAlignment = horizontal or Enum.HorizontalAlignment.Left,
		VerticalAlignment = vertical or Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = parent,
	}) :: UIListLayout
end

function UIBuilder.frame(props: Props?): Frame
	local merged: Props = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}
	if props then
		for key, value in props do
			merged[key] = value
		end
	end
	return UIBuilder.create("Frame", merged) :: Frame
end

--[[
	Rounded, stroked, semi-transparent panel.
]]
function UIBuilder.panel(props: Props?, radius: number?): Frame
	local merged: Props = {
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = Theme.Metrics.PanelTransparency,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(200, 100),
	}
	if props then
		for key, value in props do
			merged[key] = value
		end
	end
	local frame = UIBuilder.create("Frame", merged) :: Frame
	UIBuilder.corner(frame, radius)
	UIBuilder.stroke(frame)
	return frame
end

function UIBuilder.label(props: Props?): TextLabel
	local merged: Props = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = Theme.Fonts.Body,
		TextColor3 = Theme.Colors.Text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Size = UDim2.new(1, 0, 0, 20),
		Text = "",
		RichText = false,
	}
	if props then
		for key, value in props do
			merged[key] = value
		end
	end
	return UIBuilder.create("TextLabel", merged) :: TextLabel
end

function UIBuilder.button(props: Props?): TextButton
	local merged: Props = {
		BackgroundColor3 = Theme.Colors.PanelLight,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Theme.Fonts.Heading,
		TextColor3 = Theme.Colors.Text,
		TextSize = 18,
		Size = UDim2.fromOffset(180, 46),
		Text = "Button",
	}
	if props then
		for key, value in props do
			merged[key] = value
		end
	end
	local button = UIBuilder.create("TextButton", merged) :: TextButton
	UIBuilder.corner(button, Theme.Metrics.Radius)
	UIBuilder.stroke(button, Theme.Colors.PanelStroke, 1, 0.8)
	return button
end

--[[
	Adds hover/press feedback to a button by scaling its background colour.
]]
function UIBuilder.bindButtonFeedback(button: TextButton, baseColor: Color3, hoverColor: Color3?)
	local TweenService = game:GetService("TweenService")
	local hover = hoverColor or baseColor:Lerp(Color3.new(1, 1, 1), 0.12)
	local press = baseColor:Lerp(Color3.new(0, 0, 0), 0.12)
	button.BackgroundColor3 = baseColor
	button.MouseEnter:Connect(function()
		TweenService:Create(button, Theme.Tween.Fast, { BackgroundColor3 = hover }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, Theme.Tween.Fast, { BackgroundColor3 = baseColor }):Play()
	end)
	button.MouseButton1Down:Connect(function()
		TweenService:Create(button, Theme.Tween.Fast, { BackgroundColor3 = press }):Play()
	end)
	button.MouseButton1Up:Connect(function()
		TweenService:Create(button, Theme.Tween.Fast, { BackgroundColor3 = hover }):Play()
	end)
end

--[[
	A horizontal progress bar: returns the track frame and the fill frame.
]]
function UIBuilder.bar(parent: Instance, height: number, fillColor: Color3, fillColorDark: Color3?): (Frame, Frame)
	local track = UIBuilder.create("Frame", {
		BackgroundColor3 = Theme.Colors.BarTrack,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, height),
		Parent = parent,
	}) :: Frame
	UIBuilder.corner(track, height / 2)
	local fill = UIBuilder.create("Frame", {
		BackgroundColor3 = fillColor,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Parent = track,
	}) :: Frame
	UIBuilder.corner(fill, height / 2)
	UIBuilder.gradient(fill, fillColor, fillColorDark or fillColor:Lerp(Color3.new(0, 0, 0), 0.25), 90)
	return track, fill
end

--[[
	Small rounded tile containing an emoji/glyph, used as an icon.
]]
function UIBuilder.iconTile(parent: Instance, glyph: string, color: Color3, size: number): Frame
	local tile = UIBuilder.create("Frame", {
		BackgroundColor3 = color,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(size, size),
		Parent = parent,
	}) :: Frame
	UIBuilder.corner(tile, math.floor(size * 0.3))
	UIBuilder.label({
		Text = glyph,
		Font = Theme.Fonts.Heading,
		TextSize = math.floor(size * 0.6),
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 1),
		Parent = tile,
	})
	return tile
end

function UIBuilder.screenGui(name: string, displayOrder: number): ScreenGui
	return UIBuilder.create("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = displayOrder,
	}) :: ScreenGui
end

return UIBuilder
