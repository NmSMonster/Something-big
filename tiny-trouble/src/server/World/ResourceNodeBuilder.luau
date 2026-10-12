--!strict
--[[
	ResourceNodeBuilder
	-------------------
	Builds the physical representation of a gatherable resource: a model with
	an invisible hitbox (PrimaryPart) that carries the ProximityPrompt, a soft
	sparkle so nodes are discoverable, and per-resource primitive visuals.

	The server owns these models; ResourceService destroys and rebuilds them
	on collection/respawn so state never leaks between cycles.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local ResourceDefinitions = require(ReplicatedStorage.Shared.Config.ResourceDefinitions)
local Scale = require(ReplicatedStorage.Shared.Scale)
local Tags = require(ReplicatedStorage.Shared.Tags)
local Types = require(ReplicatedStorage.Shared.Types)
local PartBuilder = require(script.Parent.PartBuilder)

local cm = Scale.cm
local vec = Scale.vec

local ResourceNodeBuilder = {}

local HITBOX_SIZE = Vector3.new(4.5, 3.5, 4.5)

type VisualBuilder = (model: Model, base: CFrame, random: Random) -> ()

local function visual(model: Model, props: PartBuilder.PartProps): Part
	local merged = table.clone(props)
	merged.Parent = model
	merged.CanCollide = false
	merged.CanQuery = false
	merged.CastShadow = if merged.CastShadow == nil then false else merged.CastShadow
	return PartBuilder.part(merged)
end

local visualBuilders: { [string]: VisualBuilder } = {
	FoodCrumb = function(model, base, random)
		local crust = Color3.fromRGB(190, 130, 60)
		local crumb = Color3.fromRGB(226, 178, 104)
		visual(model, {
			Name = "Crumb",
			Size = vec(2.0, 1.2, 1.6),
			CFrame = base * CFrame.new(0, cm(0.6), 0) * CFrame.Angles(0, random:NextNumber(0, 1), math.rad(6)),
			Color = crumb,
			Material = Enum.Material.Sand,
		})
		visual(model, {
			Name = "CrumbCrust",
			Size = vec(2.1, 0.4, 1.7),
			CFrame = base * CFrame.new(0, cm(1.3), 0) * CFrame.Angles(0, random:NextNumber(0, 1), math.rad(6)),
			Color = crust,
			Material = Enum.Material.Sand,
		})
		visual(model, {
			Name = "CrumbChunk",
			Size = vec(0.9, 0.7, 0.8),
			CFrame = base * CFrame.new(cm(1.5), cm(0.35), cm(0.6)) * CFrame.Angles(0, random:NextNumber(0, 3), 0),
			Color = crumb,
			Material = Enum.Material.Sand,
		})
		visual(model, {
			Name = "CrumbChunk",
			Size = vec(0.6, 0.5, 0.6),
			CFrame = base * CFrame.new(-cm(1.3), cm(0.25), -cm(0.8)) * CFrame.Angles(0, random:NextNumber(0, 3), 0),
			Color = crust,
			Material = Enum.Material.Sand,
		})
	end,

	Toothpick = function(model, base, _random)
		local part = Instance.new("Part")
		part.Shape = Enum.PartType.Cylinder
		part.Name = "Toothpick"
		part.Size = Vector3.new(cm(6.5), 0.5, 0.5)
		part.CFrame = base * CFrame.new(0, 0.25, 0)
		part.Color = Color3.fromRGB(214, 180, 122)
		part.Material = Enum.Material.Wood
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Parent = model
		-- Pointed tips.
		for _, side in { -1, 1 } do
			local tip = Instance.new("Part")
			tip.Shape = Enum.PartType.Cylinder
			tip.Name = "ToothpickTip"
			tip.Size = Vector3.new(cm(0.8), 0.3, 0.3)
			tip.CFrame = base * CFrame.new(side * cm(3.6), 0.25, 0)
			tip.Color = Color3.fromRGB(214, 180, 122)
			tip.Material = Enum.Material.Wood
			tip.Anchored = true
			tip.CanCollide = false
			tip.CanQuery = false
			tip.CanTouch = false
			tip.CastShadow = false
			tip.Parent = model
		end
	end,

	Thread = function(model, base, random)
		local palette = {
			Color3.fromRGB(214, 86, 112),
			Color3.fromRGB(70, 110, 190),
			Color3.fromRGB(240, 200, 60),
		}
		local color = palette[random:NextInteger(1, #palette)]
		for index = 0, 3 do
			local angle = index * 1.4 + random:NextNumber(-0.3, 0.3)
			local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
			local center = base:PointToWorldSpace(
				Vector3.new(cm(math.cos(angle * 1.7) * 0.9), 0.2, cm(math.sin(angle * 1.7) * 0.9))
			)
			PartBuilder.cylinderAlong(0.16, cm(2.6), center, direction, {
				Name = "ThreadStrand",
				Color = color,
				Material = Enum.Material.Fabric,
				CanCollide = false,
				CanQuery = false,
				CastShadow = false,
				Parent = model,
			})
		end
	end,

	WoodSplinter = function(model, base, random)
		visual(model, {
			Name = "Splinter",
			Size = vec(4.2, 0.5, 0.7),
			CFrame = base * CFrame.new(0, cm(0.25), 0) * CFrame.Angles(0, random:NextNumber(0, 0.5), 0),
			Color = Color3.fromRGB(164, 112, 64),
			Material = Enum.Material.Wood,
		})
		visual(model, {
			Name = "SplinterSmall",
			Size = vec(2.2, 0.4, 0.5),
			CFrame = base * CFrame.new(cm(0.8), cm(0.2), cm(1.0)) * CFrame.Angles(0, random:NextNumber(0.6, 1.2), 0),
			Color = Color3.fromRGB(184, 132, 80),
			Material = Enum.Material.Wood,
		})
	end,

	PlasticFragment = function(model, base, random)
		local palette = {
			Color3.fromRGB(86, 196, 232),
			Color3.fromRGB(240, 240, 240),
			Color3.fromRGB(120, 220, 140),
		}
		local color = palette[random:NextInteger(1, #palette)]
		local wedge = Instance.new("WedgePart")
		wedge.Name = "Shard"
		wedge.Size = vec(2.6, 0.35, 1.9)
		wedge.CFrame = base * CFrame.new(0, cm(0.18), 0) * CFrame.Angles(0, random:NextNumber(0, 3), 0)
		wedge.Color = color
		wedge.Material = Enum.Material.SmoothPlastic
		wedge.Transparency = 0.15
		wedge.Reflectance = 0.1
		wedge.Anchored = true
		wedge.CanCollide = false
		wedge.CanQuery = false
		wedge.CanTouch = false
		wedge.CastShadow = false
		wedge.Parent = model
		visual(model, {
			Name = "ShardSmall",
			Size = vec(1.2, 0.3, 0.9),
			CFrame = base * CFrame.new(cm(1.4), cm(0.15), -cm(0.9)) * CFrame.Angles(0, random:NextNumber(0, 3), 0),
			Color = color,
			Material = Enum.Material.SmoothPlastic,
			Transparency = 0.15,
		})
	end,

	MetalScrap = function(model, base, random)
		local color = Color3.fromRGB(176, 182, 196)
		if random:NextInteger(0, 1) == 0 then
			-- Paperclip: three bars forming a U.
			local length = cm(3.4)
			local gap = cm(0.9)
			PartBuilder.cylinderAlong(
				0.16,
				length,
				base:PointToWorldSpace(Vector3.new(0, 0.16, -gap / 2)),
				base.RightVector,
				{
					Name = "ClipBar",
					Color = color,
					Material = Enum.Material.Metal,
					Reflectance = 0.4,
					CanCollide = false,
					CanQuery = false,
					CastShadow = false,
					Parent = model,
				}
			)
			PartBuilder.cylinderAlong(
				0.16,
				length * 0.8,
				base:PointToWorldSpace(Vector3.new(length * 0.1, 0.16, gap / 2)),
				base.RightVector,
				{
					Name = "ClipBar",
					Color = color,
					Material = Enum.Material.Metal,
					Reflectance = 0.4,
					CanCollide = false,
					CanQuery = false,
					CastShadow = false,
					Parent = model,
				}
			)
			PartBuilder.cylinderAlong(
				0.16,
				gap,
				base:PointToWorldSpace(Vector3.new(-length / 2, 0.16, 0)),
				base.LookVector,
				{
					Name = "ClipBend",
					Color = color,
					Material = Enum.Material.Metal,
					Reflectance = 0.4,
					CanCollide = false,
					CanQuery = false,
					CastShadow = false,
					Parent = model,
				}
			)
		else
			-- Screw lying on its side.
			PartBuilder.cylinderAlong(
				cm(0.3),
				cm(2.2),
				base:PointToWorldSpace(Vector3.new(0, cm(0.3), 0)),
				base.RightVector,
				{
					Name = "ScrewShaft",
					Color = color,
					Material = Enum.Material.Metal,
					Reflectance = 0.35,
					CanCollide = false,
					CanQuery = false,
					CastShadow = false,
					Parent = model,
				}
			)
			PartBuilder.cylinderAlong(
				cm(0.6),
				cm(0.4),
				base:PointToWorldSpace(Vector3.new(cm(1.3), cm(0.6), 0)),
				base.RightVector,
				{
					Name = "ScrewHead",
					Color = color,
					Material = Enum.Material.Metal,
					Reflectance = 0.35,
					CanCollide = false,
					CanQuery = false,
					CastShadow = false,
					Parent = model,
				}
			)
		end
	end,

	BottleCap = function(model, base, random)
		local palette = {
			Color3.fromRGB(232, 72, 72),
			Color3.fromRGB(60, 120, 220),
			Color3.fromRGB(240, 190, 40),
		}
		local color = palette[random:NextInteger(1, #palette)]
		local cap = Instance.new("Part")
		cap.Shape = Enum.PartType.Cylinder
		cap.Name = "CapBody"
		cap.Size = Vector3.new(cm(0.6), cm(3), cm(3))
		cap.CFrame = base * CFrame.new(0, cm(0.3), 0) * CFrame.Angles(0, 0, math.rad(90))
		cap.Color = Color3.fromRGB(190, 194, 200)
		cap.Material = Enum.Material.Metal
		cap.Reflectance = 0.3
		cap.Anchored = true
		cap.CanCollide = false
		cap.CanQuery = false
		cap.CanTouch = false
		cap.CastShadow = false
		cap.Parent = model
		local top = Instance.new("Part")
		top.Shape = Enum.PartType.Cylinder
		top.Name = "CapTop"
		top.Size = Vector3.new(cm(0.15), cm(2.6), cm(2.6))
		top.CFrame = base * CFrame.new(0, cm(0.67), 0) * CFrame.Angles(0, 0, math.rad(90))
		top.Color = color
		top.Material = Enum.Material.SmoothPlastic
		top.Anchored = true
		top.CanCollide = false
		top.CanQuery = false
		top.CanTouch = false
		top.CastShadow = false
		top.Parent = model
	end,

	PlantFiber = function(model, base, random)
		for index = 0, 3 do
			local angle = index * 0.55 - 0.8 + random:NextNumber(-0.15, 0.15)
			local direction = Vector3.new(math.cos(angle), 0.08, math.sin(angle))
			local center = base:PointToWorldSpace(
				Vector3.new(cm(math.cos(angle) * 1.4), 0.2 + index * 0.08, cm(math.sin(angle) * 1.4))
			)
			PartBuilder.cylinderAlong(0.15, cm(3.2), center, direction, {
				Name = "Fiber",
				Color = if index % 2 == 0 then Color3.fromRGB(116, 188, 98) else Color3.fromRGB(150, 160, 80),
				Material = Enum.Material.Grass,
				CanCollide = false,
				CanQuery = false,
				CastShadow = false,
				Parent = model,
			})
		end
	end,
}

local function buildSparkle(hitbox: BasePart, color: Color3)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Sparkle"
	emitter.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.5))
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	emitter.Lifetime = NumberRange.new(0.8, 1.4)
	emitter.Rate = 2.5
	emitter.Speed = NumberRange.new(0.4, 1)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.LightEmission = 0.8
	emitter.LightInfluence = 0.2
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Parent = hitbox
end

local function buildPrompt(
	hitbox: BasePart,
	definition: ResourceDefinitions.ResourceDefinition,
	amount: number
): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "CollectPrompt"
	prompt.ActionText = "Collect"
	prompt.ObjectText = if amount > 1 then ("%s x%d"):format(definition.name, amount) else definition.name
	prompt.HoldDuration = GameConfig.Interaction.HoldDuration
	prompt.MaxActivationDistance = GameConfig.Interaction.MaxDistance
	prompt.RequiresLineOfSight = false
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.KeyboardKeyCode = GameConfig.Input.InteractKey
	prompt.GamepadKeyCode = GameConfig.Input.InteractGamepad
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
	prompt.ClickablePrompt = true
	prompt.Parent = hitbox
	return prompt
end

--[[
	Builds a node model. Returns the model and its prompt.
]]
function ResourceNodeBuilder.build(
	nodeId: number,
	spawn: Types.ResourceSpawn,
	amount: number,
	parent: Instance
): (Model, ProximityPrompt)
	local definition = ResourceDefinitions.get(spawn.resourceId)
	assert(definition, ("Unknown resource id '%s'"):format(spawn.resourceId))

	local model = Instance.new("Model")
	model.Name = ("Node_%s_%d"):format(spawn.resourceId, nodeId)

	local base = CFrame.new(spawn.position) * CFrame.Angles(0, spawn.rotation or 0, 0)
	local random = Random.new(nodeId * 7919 + os.time() % 1000)

	local hitbox = Instance.new("Part")
	hitbox.Name = "Hitbox"
	hitbox.Size = HITBOX_SIZE
	hitbox.CFrame = base * CFrame.new(0, HITBOX_SIZE.Y / 2 - 0.5, 0)
	hitbox.Transparency = 1
	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox.CanQuery = true
	hitbox.CanTouch = false
	hitbox.CastShadow = false
	hitbox.Parent = model
	model.PrimaryPart = hitbox

	local builder = visualBuilders[spawn.resourceId]
	if builder then
		builder(model, base, random)
	end

	buildSparkle(hitbox, (definition :: ResourceDefinitions.ResourceDefinition).color)
	local prompt = buildPrompt(hitbox, definition :: ResourceDefinitions.ResourceDefinition, amount)

	model:SetAttribute("NodeId", nodeId)
	model:SetAttribute("ResourceId", spawn.resourceId)
	model:SetAttribute("Amount", amount)
	CollectionService:AddTag(model, Tags.ResourceNode)
	model.Parent = parent

	return model, prompt
end

return ResourceNodeBuilder
