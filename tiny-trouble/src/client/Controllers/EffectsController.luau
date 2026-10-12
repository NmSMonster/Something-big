--!strict
--[[
	EffectsController
	-----------------
	Visual/audio feedback for world events: a particle burst where a resource
	was collected, floating "+N" text for the collector and a pickup sound.
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ResourceDefinitions = require(ReplicatedStorage.Shared.Config.ResourceDefinitions)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)
local Theme = require(script.Parent.Parent.UI.Theme)
local UIBuilder = require(script.Parent.Parent.UI.UIBuilder)
local AudioController = require(script.Parent.AudioController)

local EffectsController = {}

local player = Players.LocalPlayer
local effectsFolder: Folder? = nil

local function getFolder(): Folder
	local cached = effectsFolder
	if cached and cached.Parent then
		return cached
	end
	local folder = Instance.new("Folder")
	folder.Name = "TinyTroubleEffects"
	folder.Parent = workspace
	effectsFolder = folder
	return folder
end

local function spawnAnchor(position: Vector3): Part
	local anchor = Instance.new("Part")
	anchor.Name = "EffectAnchor"
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.CastShadow = false
	anchor.Position = position
	anchor.Parent = getFolder()
	return anchor
end

local function burst(anchor: Part, color: Color3)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color, color:Lerp(Color3.new(1, 1, 1), 0.6))
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	emitter.Lifetime = NumberRange.new(0.45, 0.9)
	emitter.Speed = NumberRange.new(6, 13)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Acceleration = Vector3.new(0, -18, 0)
	emitter.LightEmission = 0.7
	emitter.Rate = 0
	emitter.Enabled = false
	emitter.Parent = anchor
	emitter:Emit(22)
end

local function floatingText(anchor: Part, text: string, color: Color3)
	local gui = UIBuilder.create("BillboardGui", {
		Size = UDim2.fromOffset(220, 40),
		StudsOffset = Vector3.new(0, 2, 0),
		AlwaysOnTop = true,
		LightInfluence = 0,
		Parent = anchor,
	}) :: BillboardGui
	local label = UIBuilder.label({
		Text = text,
		Font = Theme.Fonts.Title,
		TextSize = 24,
		TextColor3 = color,
		TextStrokeTransparency = 0.4,
		TextStrokeColor3 = Theme.Colors.TextDark,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 1),
		Parent = gui,
	})
	TweenService:Create(gui, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffset = Vector3.new(0, 5.5, 0),
	}):Play()
	TweenService:Create(label, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
end

local function onResourceCollected(payload: Types.ResourceCollectedPayload)
	if
		typeof(payload) ~= "table"
		or typeof(payload.position) ~= "Vector3"
		or typeof(payload.resourceId) ~= "string"
	then
		return
	end
	local definition = ResourceDefinitions.get(payload.resourceId)
	local color = if definition then definition.color else Theme.Colors.Accent
	local anchor = spawnAnchor(payload.position)
	Debris:AddItem(anchor, 2.5)
	burst(anchor, color)

	if payload.collectorUserId == player.UserId then
		local amount = if typeof(payload.amount) == "number" then payload.amount else 1
		local name = if definition
			then (if amount > 1 then definition.plural else definition.name)
			else payload.resourceId
		floatingText(anchor, ("+%d %s"):format(amount, name), color)
		AudioController.play("Pickup")
	else
		AudioController.playAt("Pickup", payload.position)
	end
end

function EffectsController.Init()
	Remotes.getEvent(Remotes.Events.ResourceCollected).OnClientEvent:Connect(onResourceCollected)
end

return EffectsController
