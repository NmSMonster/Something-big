--!strict
--[[
	MainMenu
	--------
	Title screen (first join) and pause menu (later). Shows over the
	cinematic menu camera. Contains the settings panel.
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local ClientState = require(script.Parent.Parent.State.ClientState)
local Theme = require(script.Parent.Theme)
local UIBuilder = require(script.Parent.UIBuilder)

local MainMenu = {}

export type MenuUI = {
	gui: ScreenGui,
	PlayPressed: Signal.Signal<>,
	show: (self: MenuUI, mode: "Main" | "Pause") -> (),
	hide: (self: MenuUI) -> (),
	isVisible: (self: MenuUI) -> boolean,
}

local function addStepperRow(
	parent: Instance,
	order: number,
	labelText: string,
	getValueText: () -> string,
	onStep: (direction: number) -> ()
)
	local row = UIBuilder.frame({
		Size = UDim2.new(1, 0, 0, 40),
		LayoutOrder = order,
		Parent = parent,
	})
	UIBuilder.label({
		Text = labelText,
		Font = Theme.Fonts.BodyMedium,
		TextSize = 16,
		Size = UDim2.new(1, -150, 1, 0),
		Parent = row,
	})
	local value = UIBuilder.label({
		Text = getValueText(),
		Font = Theme.Fonts.Heading,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.new(1, -108, 0, 0),
		Size = UDim2.fromOffset(66, 40),
		Parent = row,
	})
	local function makeButton(text: string, x: number, direction: number)
		local button = UIBuilder.button({
			Text = text,
			TextSize = 20,
			Size = UDim2.fromOffset(36, 36),
			Position = UDim2.new(1, x, 0, 2),
			Parent = row,
		})
		UIBuilder.bindButtonFeedback(button, Theme.Colors.PanelLight)
		button.Activated:Connect(function()
			onStep(direction)
			value.Text = getValueText()
		end)
	end
	makeButton("−", -146, -1)
	makeButton("+", -40, 1)
end

local function addToggleRow(
	parent: Instance,
	order: number,
	labelText: string,
	getValueText: () -> string,
	onToggle: () -> ()
)
	local row = UIBuilder.frame({
		Size = UDim2.new(1, 0, 0, 40),
		LayoutOrder = order,
		Parent = parent,
	})
	UIBuilder.label({
		Text = labelText,
		Font = Theme.Fonts.BodyMedium,
		TextSize = 16,
		Size = UDim2.new(1, -150, 1, 0),
		Parent = row,
	})
	local button = UIBuilder.button({
		Text = getValueText(),
		TextSize = 15,
		Size = UDim2.fromOffset(142, 36),
		Position = UDim2.new(1, -146, 0, 2),
		Parent = row,
	})
	UIBuilder.bindButtonFeedback(button, Theme.Colors.PanelLight)
	button.Activated:Connect(function()
		onToggle()
		button.Text = getValueText()
	end)
end

local function buildSettingsPanel(parent: Instance): Frame
	local panel = UIBuilder.panel({
		Name = "Settings",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -80, 0.5, 0),
		Size = UDim2.fromOffset(440, 100),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0.08,
		Visible = false,
		Parent = parent,
	})
	UIBuilder.padding(panel, 20, 18)
	UIBuilder.list(panel, Enum.FillDirection.Vertical, 6)

	UIBuilder.label({
		Text = "SETTINGS",
		Font = Theme.Fonts.Title,
		TextSize = 30,
		TextColor3 = Theme.Colors.Accent,
		Size = UDim2.new(1, 0, 0, 36),
		LayoutOrder = 1,
		Parent = panel,
	})

	addStepperRow(panel, 2, "Mouse sensitivity", function()
		return ("%.1f"):format(ClientState.settings.sensitivity)
	end, function(direction)
		local next = math.clamp(ClientState.settings.sensitivity + direction * 0.1, 0.2, 3)
		ClientState.updateSettings({ sensitivity = math.floor(next * 10 + 0.5) / 10 })
	end)
	addStepperRow(panel, 3, "Field of view", function()
		return ("%d°"):format(ClientState.settings.fov)
	end, function(direction)
		ClientState.updateSettings({ fov = math.clamp(ClientState.settings.fov + direction * 5, 60, 100) })
	end)
	addToggleRow(panel, 4, "Invert vertical look", function()
		return if ClientState.settings.invertY then "Inverted" else "Normal"
	end, function()
		ClientState.updateSettings({ invertY = not ClientState.settings.invertY })
	end)
	addToggleRow(panel, 5, "Camera shoulder", function()
		return if ClientState.settings.shoulderSide > 0 then "Right" else "Left"
	end, function()
		ClientState.updateSettings({ shoulderSide = -ClientState.settings.shoulderSide })
	end)
	addToggleRow(panel, 6, "Controls hint", function()
		return if ClientState.settings.showControlsHint then "Shown" else "Hidden"
	end, function()
		ClientState.updateSettings({ showControlsHint = not ClientState.settings.showControlsHint })
	end)

	local back = UIBuilder.button({
		Text = "BACK",
		Size = UDim2.fromOffset(140, 42),
		LayoutOrder = 7,
		Parent = panel,
	})
	UIBuilder.bindButtonFeedback(back, Theme.Colors.PanelLight)
	back.Activated:Connect(function()
		panel.Visible = false
	end)

	return panel
end

function MainMenu.create(parent: Instance): MenuUI
	local gui = UIBuilder.screenGui("TinyTroubleMenu", 30)
	gui.Enabled = false

	local backdrop = UIBuilder.create("Frame", {
		Name = "Backdrop",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Colors.Backdrop,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Parent = gui,
	}) :: Frame
	UIBuilder.create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.55, 0.35),
			NumberSequenceKeypoint.new(1, 0.75),
		}),
		Parent = backdrop,
	})

	local column = UIBuilder.frame({
		Name = "Column",
		Position = UDim2.new(0, 80, 0.5, -200),
		Size = UDim2.fromOffset(520, 420),
		Parent = backdrop,
	})
	UIBuilder.list(column, Enum.FillDirection.Vertical, 10)

	-- Title with a soft drop shadow (two stacked labels).
	local titleHolder = UIBuilder.frame({
		Size = UDim2.new(1, 0, 0, 180),
		LayoutOrder = 1,
		Parent = column,
	})
	UIBuilder.label({
		Text = "TINY\nTROUBLE",
		Font = Theme.Fonts.Title,
		TextSize = 84,
		TextColor3 = Theme.Colors.TextDark,
		TextTransparency = 0.4,
		Position = UDim2.fromOffset(4, 6),
		Size = UDim2.fromScale(1, 1),
		TextYAlignment = Enum.TextYAlignment.Top,
		LineHeight = 0.9,
		Parent = titleHolder,
	})
	UIBuilder.label({
		Text = "TINY\nTROUBLE",
		Font = Theme.Fonts.Title,
		TextSize = 84,
		TextColor3 = Theme.Colors.Accent,
		Size = UDim2.fromScale(1, 1),
		TextYAlignment = Enum.TextYAlignment.Top,
		LineHeight = 0.9,
		Parent = titleHolder,
	})

	UIBuilder.label({
		Text = "A miniature survival adventure",
		Font = Theme.Fonts.BodyMedium,
		TextSize = 20,
		TextColor3 = Theme.Colors.Text,
		Size = UDim2.new(1, 0, 0, 26),
		LayoutOrder = 2,
		Parent = column,
	})
	local modeLabel = UIBuilder.label({
		Text = "",
		Font = Theme.Fonts.Body,
		TextSize = 15,
		TextColor3 = Theme.Colors.TextMuted,
		Size = UDim2.new(1, 0, 0, 20),
		LayoutOrder = 3,
		Parent = column,
	})

	local playButton = UIBuilder.button({
		Text = "PLAY",
		TextSize = 22,
		TextColor3 = Theme.Colors.TextDark,
		Size = UDim2.fromOffset(240, 54),
		LayoutOrder = 4,
		Parent = column,
	})
	UIBuilder.bindButtonFeedback(playButton, Theme.Colors.Accent, Theme.Colors.Accent:Lerp(Color3.new(1, 1, 1), 0.18))

	local settingsButton = UIBuilder.button({
		Text = "SETTINGS",
		TextSize = 18,
		Size = UDim2.fromOffset(240, 48),
		LayoutOrder = 5,
		Parent = column,
	})
	UIBuilder.bindButtonFeedback(settingsButton, Theme.Colors.PanelLight)

	UIBuilder.label({
		Text = ("%s  •  Milestone 1: Playable Foundation  •  v%s"):format(GameConfig.GameName, GameConfig.Version),
		Font = Theme.Fonts.Body,
		TextSize = 13,
		TextColor3 = Theme.Colors.TextMuted,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 80, 1, -24),
		Size = UDim2.fromOffset(600, 18),
		Parent = backdrop,
	})

	local settingsPanel = buildSettingsPanel(backdrop)
	settingsButton.Activated:Connect(function()
		settingsPanel.Visible = not settingsPanel.Visible
	end)

	local playPressed = Signal.new() :: Signal.Signal<>
	playButton.Activated:Connect(function()
		playPressed:Fire()
	end)

	gui.Parent = parent

	local menu: MenuUI
	menu = {
		gui = gui,
		PlayPressed = playPressed,
		show = function(_, mode)
			if mode == "Main" then
				playButton.Text = "PLAY"
				modeLabel.Text = "You have shrunk to 2 cm. The kitchen is now a wilderness."
			else
				playButton.Text = "RESUME"
				modeLabel.Text = "Paused. Your character is still in the world."
			end
			settingsPanel.Visible = false
			gui.Enabled = true
			backdrop.BackgroundTransparency = 1
			TweenService:Create(backdrop, Theme.Tween.Normal, { BackgroundTransparency = 0.25 }):Play()
		end,
		hide = function(_)
			if not gui.Enabled then
				return
			end
			local tween = TweenService:Create(backdrop, Theme.Tween.Normal, { BackgroundTransparency = 1 })
			tween.Completed:Connect(function()
				if backdrop.BackgroundTransparency >= 0.99 then
					gui.Enabled = false
				end
			end)
			tween:Play()
		end,
		isVisible = function(_)
			return gui.Enabled
		end,
	}
	return menu
end

return MainMenu
