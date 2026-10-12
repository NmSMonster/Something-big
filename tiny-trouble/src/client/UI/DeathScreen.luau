--!strict
--[[
	DeathScreen
	-----------
	Dark overlay with the cause of death and a respawn countdown.
]]

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)
local UIBuilder = require(script.Parent.UIBuilder)

local DeathScreen = {}

local gui: ScreenGui? = nil
local overlay: Frame? = nil
local causeLabel: TextLabel? = nil
local countdownLabel: TextLabel? = nil
local tipLabel: TextLabel? = nil
local countdownThread: thread? = nil

local TIPS = {
	"Chair rungs and hanging cloth are climbable.",
	"Falls over five body-heights hurt. Look for ramps.",
	"Sprinting drains stamina; it refills when you slow down.",
	"Crouch to squeeze into low gaps.",
	"Resource nodes sparkle. They respawn after a while.",
}

function DeathScreen.init(parent: Instance)
	local screen = UIBuilder.screenGui("TinyTroubleDeath", 40)
	screen.Enabled = false

	local frame = UIBuilder.create("Frame", {
		Name = "Overlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(14, 10, 20),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = screen,
	}) :: Frame

	local center = UIBuilder.frame({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(520, 220),
		Parent = frame,
	})
	UIBuilder.list(
		center,
		Enum.FillDirection.Vertical,
		10,
		Enum.HorizontalAlignment.Center,
		Enum.VerticalAlignment.Center
	)

	UIBuilder.label({
		Text = "SQUISHED",
		Font = Theme.Fonts.Title,
		TextSize = 64,
		TextColor3 = Theme.Colors.Health,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 72),
		LayoutOrder = 1,
		Parent = center,
	})
	local cause = UIBuilder.label({
		Text = "",
		Font = Theme.Fonts.BodyMedium,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 26),
		LayoutOrder = 2,
		Parent = center,
	})
	local countdown = UIBuilder.label({
		Text = "",
		Font = Theme.Fonts.Heading,
		TextSize = 18,
		TextColor3 = Theme.Colors.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 24),
		LayoutOrder = 3,
		Parent = center,
	})
	local tip = UIBuilder.label({
		Text = "",
		Font = Theme.Fonts.Body,
		TextSize = 15,
		TextColor3 = Theme.Colors.Accent,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 40),
		LayoutOrder = 4,
		Parent = center,
	})

	screen.Parent = parent
	gui = screen
	overlay = frame
	causeLabel = cause
	countdownLabel = countdown
	tipLabel = tip
end

function DeathScreen.show(cause: string, respawnSeconds: number)
	local screen = gui
	local frame = overlay
	if not screen or not frame or not causeLabel or not countdownLabel or not tipLabel then
		return
	end
	if countdownThread then
		task.cancel(countdownThread :: thread)
		countdownThread = nil
	end

	causeLabel.Text = if cause ~= "" then cause else "You died."
	tipLabel.Text = "Tip: " .. TIPS[math.random(1, #TIPS)]
	screen.Enabled = true
	frame.BackgroundTransparency = 1
	TweenService:Create(frame, Theme.Tween.Slow, { BackgroundTransparency = 0.35 }):Play()

	countdownThread = task.spawn(function()
		local remaining = math.max(1, math.ceil(respawnSeconds))
		while remaining > 0 do
			(countdownLabel :: TextLabel).Text = ("Respawning in %d..."):format(remaining)
			task.wait(1)
			remaining -= 1
		end
		(countdownLabel :: TextLabel).Text = "Respawning..."
	end)
end

function DeathScreen.hide()
	local screen = gui
	local frame = overlay
	if not screen or not frame then
		return
	end
	if countdownThread then
		task.cancel(countdownThread :: thread)
		countdownThread = nil
	end
	local tween = TweenService:Create(frame, Theme.Tween.Normal, { BackgroundTransparency = 1 })
	tween.Completed:Connect(function()
		if frame.BackgroundTransparency >= 0.99 then
			screen.Enabled = false
		end
	end)
	tween:Play()
end

return DeathScreen
