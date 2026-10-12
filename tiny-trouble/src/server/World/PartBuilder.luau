--!strict
--[[
	PartBuilder
	-----------
	Thin, typed helpers for building the world out of primitive parts.
	Every function works in STUDS. World layout code converts from
	centimetres through Shared.Scale before calling in here.

	Conventions used by the generator:
	* `bottomCenter` positions place a part so it rests on that point
	  (its bottom face is at that Y) - the natural way to describe furniture.
	* Cylinders are built with their axis along world Y unless noted; Roblox
	  cylinder parts have their axis along local X, so we rotate them.
	* WedgeParts slope down toward the part's Front (-Z / LookVector).
]]

local CollectionService = game:GetService("CollectionService")

local PartBuilder = {}

--[[
	Roblox WedgeParts slope down toward their Front face (-Z). If a future
	engine change ever flips this, set the flag to false and every ramp in the
	kitchen re-orients itself.
]]
PartBuilder.WEDGE_SLOPE_FACES_FRONT = true

export type PartProps = {
	Name: string?,
	Size: Vector3?,
	CFrame: CFrame?,
	Position: Vector3?,
	Color: Color3?,
	Material: Enum.Material?,
	Transparency: number?,
	Reflectance: number?,
	CanCollide: boolean?,
	CanQuery: boolean?,
	CanTouch: boolean?,
	CastShadow: boolean?,
	Anchored: boolean?,
	Parent: Instance?,
	Tags: { string }?,
	Attributes: { [string]: any }?,
}

--[[
	Some newer materials are not available on every Studio build. Resolve by
	name with a fallback so the generator never errors on an unknown enum.
]]
function PartBuilder.safeMaterial(name: string, fallback: Enum.Material): Enum.Material
	local ok, material = pcall(function()
		return (Enum.Material :: any)[name]
	end)
	if ok and typeof(material) == "EnumItem" then
		return material :: Enum.Material
	end
	return fallback
end

local function applyCommon(part: BasePart, props: PartProps)
	part.Anchored = if props.Anchored == nil then true else props.Anchored :: boolean
	part.Name = props.Name or part.ClassName
	if props.Size then
		part.Size = props.Size :: Vector3
	end
	if props.CFrame then
		part.CFrame = props.CFrame :: CFrame
	elseif props.Position then
		part.Position = props.Position :: Vector3
	end
	part.Color = props.Color or Color3.fromRGB(200, 200, 200)
	part.Material = props.Material or Enum.Material.SmoothPlastic
	part.Transparency = props.Transparency or 0
	part.Reflectance = props.Reflectance or 0
	part.CanCollide = if props.CanCollide == nil then true else props.CanCollide :: boolean
	part.CanQuery = if props.CanQuery == nil then true else props.CanQuery :: boolean
	part.CanTouch = if props.CanTouch == nil then false else props.CanTouch :: boolean
	part.CastShadow = if props.CastShadow == nil then true else props.CastShadow :: boolean
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth

	if props.Tags then
		for _, tag in props.Tags :: { string } do
			CollectionService:AddTag(part, tag)
		end
	end
	if props.Attributes then
		for key, value in props.Attributes :: { [string]: any } do
			part:SetAttribute(key, value)
		end
	end

	-- Parent last so property replication happens in one batch.
	part.Parent = props.Parent
end

function PartBuilder.part(props: PartProps): Part
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Block
	applyCommon(part, props)
	return part
end

function PartBuilder.ball(props: PartProps): Part
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Ball
	applyCommon(part, props)
	return part
end

function PartBuilder.wedge(props: PartProps): WedgePart
	local part = Instance.new("WedgePart")
	applyCommon(part, props)
	return part
end

function PartBuilder.cornerWedge(props: PartProps): CornerWedgePart
	local part = Instance.new("CornerWedgePart")
	applyCommon(part, props)
	return part
end

--[[
	A climbable truss. Truss dimensions must be multiples of 2 studs; sizes are
	rounded up so the generator can pass arbitrary lengths.
]]
function PartBuilder.truss(props: PartProps): TrussPart
	local part = Instance.new("TrussPart")
	local size = props.Size or Vector3.new(2, 2, 2)
	local rounded = Vector3.new(
		math.max(2, math.ceil(size.X / 2) * 2),
		math.max(2, math.ceil(size.Y / 2) * 2),
		math.max(2, math.ceil(size.Z / 2) * 2)
	)
	local merged = table.clone(props)
	merged.Size = rounded
	applyCommon(part, merged)
	part.Style = Enum.Style.AlternatingSupports
	return part
end

--[[
	Cylinder with its axis along world Y (standing up), positioned by the
	centre of its bottom face.
]]
function PartBuilder.cylinderY(radius: number, height: number, bottomCenter: Vector3, props: PartProps): Part
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Cylinder
	local merged = table.clone(props)
	merged.Size = Vector3.new(height, radius * 2, radius * 2)
	merged.CFrame = CFrame.new(bottomCenter + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	merged.Position = nil
	applyCommon(part, merged)
	return part
end

--[[
	Cylinder lying along an arbitrary direction, positioned by its centre.
]]
function PartBuilder.cylinderAlong(
	radius: number,
	length: number,
	center: Vector3,
	direction: Vector3,
	props: PartProps
): Part
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Cylinder
	local merged = table.clone(props)
	merged.Size = Vector3.new(length, radius * 2, radius * 2)
	local dir = if direction.Magnitude > 0 then direction.Unit else Vector3.xAxis
	-- Cylinder axis is local X; build a frame whose X axis is `dir`.
	local up = if math.abs(dir:Dot(Vector3.yAxis)) > 0.99 then Vector3.zAxis else Vector3.yAxis
	local zAxis = dir:Cross(up).Unit
	local yAxis = zAxis:Cross(dir).Unit
	merged.CFrame = CFrame.fromMatrix(center, dir, yAxis, zAxis)
	merged.Position = nil
	applyCommon(part, merged)
	return part
end

--[[
	Box positioned by the centre of its bottom face (rests on `bottomCenter`).
]]
function PartBuilder.box(size: Vector3, bottomCenter: Vector3, props: PartProps): Part
	local merged = table.clone(props)
	merged.Size = size
	if not merged.CFrame then
		merged.CFrame = CFrame.new(bottomCenter + Vector3.new(0, size.Y / 2, 0))
	end
	merged.Position = nil
	return PartBuilder.part(merged)
end

--[[
	Box positioned by its bottom centre and rotated by `yaw` radians around Y.
]]
function PartBuilder.boxYaw(size: Vector3, bottomCenter: Vector3, yaw: number, props: PartProps): Part
	local merged = table.clone(props)
	merged.Size = size
	merged.CFrame = CFrame.new(bottomCenter + Vector3.new(0, size.Y / 2, 0)) * CFrame.Angles(0, yaw, 0)
	merged.Position = nil
	return PartBuilder.part(merged)
end

--[[
	Walkable ramp (WedgePart) whose top edge is centred on `highPoint` and whose
	bottom edge is centred on `lowPoint`. The slope descends from high to low.
	Roblox wedges slope toward their Front face (-Z), so the wedge is oriented
	with its LookVector pointing horizontally from the high point to the low point.
]]
function PartBuilder.ramp(highPoint: Vector3, lowPoint: Vector3, width: number, props: PartProps): WedgePart
	local horizontal = Vector3.new(lowPoint.X - highPoint.X, 0, lowPoint.Z - highPoint.Z)
	local run = horizontal.Magnitude
	local rise = highPoint.Y - lowPoint.Y
	assert(run > 0.01 and rise > 0.01, "PartBuilder.ramp needs a positive run and rise")

	local center = Vector3.new((highPoint.X + lowPoint.X) / 2, lowPoint.Y + rise / 2, (highPoint.Z + lowPoint.Z) / 2)
	local merged = table.clone(props)
	merged.Size = Vector3.new(width, rise, run)
	local facing = if PartBuilder.WEDGE_SLOPE_FACES_FRONT then horizontal.Unit else -horizontal.Unit
	merged.CFrame = CFrame.lookAt(center, center + facing)
	merged.Position = nil
	return PartBuilder.wedge(merged)
end

--[[
	Ellipsoid: a part with a SpecialMesh sphere that fills the part's Size.
	Used for fruit, leaves, bushes and tree canopies. Collision stays a box, so
	callers normally pass CanCollide = false for decorative shapes.
]]
function PartBuilder.ellipsoid(size: Vector3, center: Vector3, props: PartProps): Part
	local merged = table.clone(props)
	merged.Size = size
	merged.CFrame = merged.CFrame or CFrame.new(center)
	merged.Position = nil
	local part = PartBuilder.part(merged)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = part
	return part
end

function PartBuilder.model(name: string, parent: Instance?): Model
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	return model
end

function PartBuilder.folder(name: string, parent: Instance?): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

function PartBuilder.pointLight(
	parent: BasePart,
	color: Color3,
	brightness: number,
	range: number,
	shadows: boolean?
): PointLight
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness
	light.Range = math.clamp(range, 0, 60)
	light.Shadows = shadows == true
	light.Parent = parent
	return light
end

--[[
	Adds a simple text SurfaceGui to a face of a part (labels, notes, boxes).
]]
function PartBuilder.surfaceText(
	part: BasePart,
	face: Enum.NormalId,
	text: string,
	textColor: Color3,
	font: Enum.Font?,
	backgroundColor: Color3?
): SurfaceGui
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 12
	gui.LightInfluence = 1
	gui.AlwaysOnTop = false

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = if backgroundColor then 0 else 1
	label.BackgroundColor3 = backgroundColor or Color3.new(1, 1, 1)
	label.BorderSizePixel = 0
	label.Font = font or Enum.Font.GothamBold
	label.TextScaled = true
	label.TextWrapped = true
	label.TextColor3 = textColor
	label.Text = text
	label.Parent = gui

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.08, 0)
	padding.PaddingRight = UDim.new(0.08, 0)
	padding.PaddingTop = UDim.new(0.08, 0)
	padding.PaddingBottom = UDim.new(0.08, 0)
	padding.Parent = label

	gui.Parent = part
	return gui
end

return PartBuilder
