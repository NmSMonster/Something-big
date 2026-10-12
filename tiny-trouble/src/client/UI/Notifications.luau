--!strict
--[[
	Notifications
	-------------
	Toast stack. Cards slide in from the right, stay for their duration and
	fade out. At most MAX_VISIBLE cards are shown; older ones are dropped.
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Types = require(ReplicatedStorage.Shared.Types)
local Theme = require(script.Parent.Theme)
local UIBuilder = require(script.Parent.UIBuilder)

local MAX_VISIBLE = 5

local Notifications = {}

local container: Frame? = nil
local active: { Frame } = {}

function Notifications.init(parent: Frame)
	container = parent
end

local function removeCard(card: Frame)
	for index, existing in active do
		if existing == card then
			table.remove(active, index)
			break
		end
	end
	local tween = TweenService:Create(card, Theme.Tween.Normal, { BackgroundTransparency = 1 })
	for _, descendant in card:GetDescendants() do
		if descendant:IsA("TextLabel") then
			TweenService:Create(descendant, Theme.Tween.Normal, { TextTransparency = 1 }):Play()
		elseif descendant:IsA("UIStroke") then
			TweenService:Create(descendant, Theme.Tween.Normal, { Transparency = 1 }):Play()
		elseif descendant:IsA("Frame") then
			TweenService:Create(descendant, Theme.Tween.Normal, { BackgroundTransparency = 1 }):Play()
		end
	end
	tween.Completed:Connect(function()
		card:Destroy()
	end)
	tween:Play()
end

function Notifications.push(payload: Types.NotificationPayload)
	local parent = container
	if not parent then
		return
	end

	while #active >= MAX_VISIBLE do
		removeCard(active[1])
	end

	local color = Theme.kindColor(payload.kind)
	local card = UIBuilder.panel({
		Name = "Toast",
		Size = UDim2.fromOffset(320, 40),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = os.clock() * 1000 // 1,
		Parent = parent,
	}, Theme.Metrics.RadiusSmall + 4)
	UIBuilder.padding(card, 14, 10)

	local accent = UIBuilder.create("Frame", {
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(-14, -10),
		Size = UDim2.new(0, 4, 1, 20),
		Parent = card,
	}) :: Frame
	UIBuilder.corner(accent, 2)

	local title = UIBuilder.label({
		Text = payload.title,
		Font = Theme.Fonts.Heading,
		TextSize = 15,
		TextColor3 = color,
		TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 18),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextTransparency = 1,
		Parent = card,
	})
	local body: TextLabel? = nil
	if payload.body and payload.body ~= "" then
		body = UIBuilder.label({
			Text = payload.body,
			Font = Theme.Fonts.Body,
			TextSize = 14,
			TextWrapped = true,
			Position = UDim2.fromOffset(0, 20),
			Size = UDim2.new(1, 0, 0, 16),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextTransparency = 1,
			Parent = card,
		})
	end

	table.insert(active, card)

	TweenService:Create(card, Theme.Tween.Normal, { BackgroundTransparency = Theme.Metrics.PanelTransparency }):Play()
	TweenService:Create(title, Theme.Tween.Normal, { TextTransparency = 0 }):Play()
	if body then
		TweenService:Create(body, Theme.Tween.Normal, { TextTransparency = 0 }):Play()
	end

	local duration = payload.duration or GameConfig.UI.NotificationSeconds
	task.delay(duration, function()
		if card.Parent then
			removeCard(card)
		end
	end)
end

return Notifications
