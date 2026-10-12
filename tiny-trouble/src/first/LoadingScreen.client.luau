--!strict
--[[
	LoadingScreen (ReplicatedFirst)
	-------------------------------
	Branded loading screen shown from the first frame until the client
	bootstrap reports it is ready (or a safety timeout elapses). This script
	runs before the rest of the game replicates, so it depends on nothing.
]]

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TweenService = game:GetService("TweenService")

local TIMEOUT_SECONDS = 30

ReplicatedFirst:RemoveDefaultLoadingScreen()

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "TinyTroubleLoading"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 1000

local background = Instance.new("Frame")
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = Color3.fromRGB(24, 20, 36)
background.BorderSizePixel = 0
background.Parent = gui

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new(Color3.fromRGB(36, 28, 56), Color3.fromRGB(18, 14, 28))
gradient.Rotation = 90
gradient.Parent = background

local title = Instance.new("TextLabel")
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.42)
title.Size = UDim2.fromOffset(700, 120)
title.BackgroundTransparency = 1
title.Font = Enum.Font.FredokaOne
title.TextSize = 92
title.TextColor3 = Color3.fromRGB(255, 178, 64)
title.Text = "TINY TROUBLE"
title.Parent = background

local subtitle = Instance.new("TextLabel")
subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
subtitle.Position = UDim2.fromScale(0.5, 0.52)
subtitle.Size = UDim2.fromOffset(600, 30)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 20
subtitle.TextColor3 = Color3.fromRGB(196, 190, 212)
subtitle.Text = "Shrinking you down"
subtitle.Parent = background

local track = Instance.new("Frame")
track.AnchorPoint = Vector2.new(0.5, 0.5)
track.Position = UDim2.fromScale(0.5, 0.6)
track.Size = UDim2.fromOffset(320, 8)
track.BackgroundColor3 = Color3.fromRGB(20, 16, 30)
track.BorderSizePixel = 0
track.Parent = background
local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(0, 4)
trackCorner.Parent = track

local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = Color3.fromRGB(255, 178, 64)
fill.BorderSizePixel = 0
fill.Parent = track
local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 4)
fillCorner.Parent = fill

gui.Parent = playerGui

-- Animated dots + a progress bar that creeps toward 90% until we are really ready.
local finished = false
task.spawn(function()
	local dots = 0
	local progress = 0
	while not finished do
		dots = (dots + 1) % 4
		subtitle.Text = "Shrinking you down" .. string.rep(".", dots)
		progress = math.min(0.9, progress + (0.9 - progress) * 0.12)
		fill.Size = UDim2.fromScale(progress, 1)
		task.wait(0.3)
	end
end)

local startedAt = os.clock()
while os.clock() - startedAt < TIMEOUT_SECONDS do
	if game:IsLoaded() and player:GetAttribute("TT_ClientLoaded") == true then
		break
	end
	task.wait(0.1)
end

finished = true
fill.Size = UDim2.fromScale(1, 1)
task.wait(0.25)

local fade = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
TweenService:Create(background, fade, { BackgroundTransparency = 1 }):Play()
for _, label in { title, subtitle } do
	TweenService:Create(label, fade, { TextTransparency = 1 }):Play()
end
TweenService:Create(track, fade, { BackgroundTransparency = 1 }):Play()
TweenService:Create(fill, fade, { BackgroundTransparency = 1 }):Play()
task.wait(0.65)
gui:Destroy()
