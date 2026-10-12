--!strict
--[[
	Theme
	-----
	Colours, fonts and metrics shared by every screen so the interface reads
	as one playful, rounded system.
]]

local Theme = {}

Theme.Colors = {
	Backdrop = Color3.fromRGB(24, 20, 36),
	Panel = Color3.fromRGB(36, 30, 54),
	PanelLight = Color3.fromRGB(52, 44, 76),
	PanelStroke = Color3.fromRGB(255, 255, 255),
	Accent = Color3.fromRGB(255, 178, 64),
	AccentDark = Color3.fromRGB(214, 134, 32),
	Mint = Color3.fromRGB(120, 222, 164),
	Sky = Color3.fromRGB(96, 190, 255),
	Health = Color3.fromRGB(244, 92, 108),
	HealthDark = Color3.fromRGB(178, 46, 66),
	Stamina = Color3.fromRGB(255, 208, 72),
	StaminaDark = Color3.fromRGB(214, 150, 24),
	Hunger = Color3.fromRGB(255, 150, 60),
	Thirst = Color3.fromRGB(80, 180, 255),
	Text = Color3.fromRGB(255, 250, 240),
	TextMuted = Color3.fromRGB(196, 190, 212),
	TextDark = Color3.fromRGB(32, 26, 44),
	Success = Color3.fromRGB(110, 220, 140),
	Warning = Color3.fromRGB(255, 190, 70),
	Danger = Color3.fromRGB(244, 92, 108),
	Objective = Color3.fromRGB(190, 150, 255),
	BarTrack = Color3.fromRGB(20, 16, 30),
}

Theme.Fonts = {
	Title = Enum.Font.FredokaOne,
	Heading = Enum.Font.GothamBold,
	Body = Enum.Font.Gotham,
	BodyMedium = Enum.Font.GothamMedium,
	Mono = Enum.Font.Code,
}

Theme.Metrics = {
	Radius = 14,
	RadiusSmall = 8,
	Padding = 12,
	Gap = 8,
	StrokeTransparency = 0.82,
	PanelTransparency = 0.18,
}

Theme.Tween = {
	Fast = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Normal = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Slow = TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	Bounce = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
}

--[[
	Colour for a notification kind.
]]
function Theme.kindColor(kind: string?): Color3
	if kind == "success" then
		return Theme.Colors.Success
	elseif kind == "warning" then
		return Theme.Colors.Warning
	elseif kind == "danger" then
		return Theme.Colors.Danger
	elseif kind == "objective" then
		return Theme.Colors.Objective
	end
	return Theme.Colors.Sky
end

return Theme
