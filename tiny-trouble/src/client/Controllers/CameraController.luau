--!strict
--[[
	CameraController
	----------------
	Custom third-person camera tuned for miniature scale.

	* Over-the-shoulder framing with a configurable shoulder side.
	* Spherecast occlusion so furniture never hides the character; the
	  camera snaps closer instantly and eases back out.
	* Mouse-lock ("shift-lock") control while playing: the character faces
	  the camera yaw. Alt frees the cursor; menus free it automatically.
	* Cinematic orbit of the kitchen while the main menu is open, with a
	  smooth blend into gameplay when Play is pressed.
	* Gamepad right stick and touch-drag look are supported out of the box.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local MathUtil = require(ReplicatedStorage.Shared.Util.MathUtil)
local Scale = require(ReplicatedStorage.Shared.Scale)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local Tags = require(ReplicatedStorage.Shared.Tags)
local ClientState = require(script.Parent.Parent.State.ClientState)
local InputController = require(script.Parent.InputController)

local CameraController = {}

CameraController.CursorLockChanged = Signal.new() :: Signal.Signal<boolean>

type Mode = "Menu" | "Play"

local player = Players.LocalPlayer
local config = GameConfig.Camera

local mode: Mode = "Menu"
local yaw = 0
local pitch = math.rad(-16)
local zoomTarget = config.DefaultDistance
local zoomCurrent = config.DefaultDistance
local fovCurrent = config.MenuFov
local menuAngle = 0
local lastCursorLocked = false
local freeCursorReasons: { [string]: boolean } = {}
local transition: { from: CFrame, start: number, duration: number }? = nil

local rightMouseDown = false
local lookTouch: InputObject? = nil
local gamepadLook = Vector2.zero

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.RespectCanCollide = true
raycastParams.IgnoreWater = true

local hasSpherecast = false

-- Orbit stays inside the room: radius 85 cm around the table keeps the camera clear of
-- the south wall (Z = 150 cm) and the pendant lamp above the table centre.
local MENU_ORBIT_CENTER = Scale.vec(-40, 45, 60)
local MENU_ORBIT_RADIUS = Scale.cm(85)
local MENU_ORBIT_HEIGHT = Scale.cm(125)
local MENU_ORBIT_SPEED = 0.07

local function getCamera(): Camera
	return workspace.CurrentCamera :: Camera
end

local function rebuildIgnoreList()
	local list: { Instance } = {}
	local character = player.Character
	if character then
		table.insert(list, character)
	end
	for _, instance in CollectionService:GetTagged(Tags.CameraIgnore) do
		table.insert(list, instance)
	end
	raycastParams.FilterDescendantsInstances = list
end

local function shouldLockCursor(): boolean
	if mode ~= "Play" or not ClientState.isPlaying then
		return false
	end
	if next(freeCursorReasons) ~= nil then
		return false
	end
	return UserInputService.MouseEnabled
end

local function updateCursorLock()
	local locked = shouldLockCursor()
	if locked then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
	elseif rightMouseDown then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
		UserInputService.MouseIconEnabled = false
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end
	if locked ~= lastCursorLocked then
		lastCursorLocked = locked
		CameraController.CursorLockChanged:Fire(locked)
	end
end

local function applyLookDelta(deltaX: number, deltaY: number, multiplier: number)
	local sensitivity = config.BaseSensitivity * ClientState.settings.sensitivity * multiplier
	yaw -= deltaX * sensitivity
	local invert = if ClientState.settings.invertY then -1 else 1
	pitch =
		math.clamp(pitch - deltaY * sensitivity * invert, math.rad(config.MinPitchDeg), math.rad(config.MaxPitchDeg))
end

local function castBack(origin: Vector3, direction: Vector3): RaycastResult?
	if hasSpherecast then
		local ok, result = pcall(function()
			return workspace:Spherecast(origin, 0.6, direction, raycastParams)
		end)
		if ok then
			return result
		end
		hasSpherecast = false
	end
	return workspace:Raycast(origin, direction, raycastParams)
end

local function updateMenuCamera(dt: number)
	local camera = getCamera()
	menuAngle += dt * MENU_ORBIT_SPEED
	local position = Vector3.new(
		MENU_ORBIT_CENTER.X + math.cos(menuAngle) * MENU_ORBIT_RADIUS,
		MENU_ORBIT_HEIGHT,
		MENU_ORBIT_CENTER.Z + math.sin(menuAngle) * MENU_ORBIT_RADIUS
	)
	camera.CFrame = CFrame.lookAt(position, MENU_ORBIT_CENTER)
	camera.Focus = CFrame.new(MENU_ORBIT_CENTER)
	fovCurrent = MathUtil.smooth(fovCurrent, config.MenuFov, config.FovSmoothSpeed, dt)
	camera.FieldOfView = fovCurrent
end

local function updatePlayCamera(dt: number)
	local camera = getCamera()
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if not root or not root:IsA("BasePart") then
		return
	end

	-- Gamepad look is continuous while the stick is deflected.
	if gamepadLook.Magnitude > 0.15 then
		applyLookDelta(gamepadLook.X * 900 * dt, -gamepadLook.Y * 700 * dt, 1)
	end

	local locked = shouldLockCursor()
	local heightOffset = if ClientState.isCrouching then config.CrouchHeightOffset else config.HeightOffset
	local rotation = CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)
	local focus = root.Position
		+ Vector3.new(0, heightOffset, 0)
		+ rotation.RightVector * (config.ShoulderOffset * ClientState.settings.shoulderSide)

	-- Occlusion: pull the camera in front of anything between the focus and the desired position.
	local back = -rotation.LookVector
	local allowed = zoomTarget
	local hit = castBack(focus, back * zoomTarget)
	if hit then
		allowed = math.max(config.MinDistance, hit.Distance - config.CollisionPadding)
	end
	if allowed < zoomCurrent then
		zoomCurrent = allowed
	else
		zoomCurrent = MathUtil.smooth(zoomCurrent, allowed, config.ZoomSmoothSpeed, dt)
	end

	local target = CFrame.new(focus + back * zoomCurrent) * rotation
	local active = transition
	if active then
		local alpha = math.clamp((os.clock() - active.start) / active.duration, 0, 1)
		local eased = 1 - (1 - alpha) ^ 3
		camera.CFrame = active.from:Lerp(target, eased)
		if alpha >= 1 then
			transition = nil
		end
	else
		camera.CFrame = target
	end
	camera.Focus = CFrame.new(focus)

	local targetFov = ClientState.settings.fov
		+ (if ClientState.isSprinting then (config.SprintFov - config.DefaultFov) else 0)
	fovCurrent = MathUtil.smooth(fovCurrent, targetFov, config.FovSmoothSpeed, dt)
	camera.FieldOfView = fovCurrent

	-- Shift-lock style facing: the character turns with the camera while the cursor is locked.
	if humanoid and humanoid:IsA("Humanoid") then
		local state = humanoid:GetState()
		local canFace = locked
			and humanoid.Health > 0
			and state ~= Enum.HumanoidStateType.Climbing
			and state ~= Enum.HumanoidStateType.Seated
			and state ~= Enum.HumanoidStateType.Dead
		if humanoid.AutoRotate == canFace then
			humanoid.AutoRotate = not canFace
		end
		if canFace then
			root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, yaw, 0)
		end
	end
end

local function onRenderStep(dt: number)
	local camera = getCamera()
	if camera.CameraType ~= Enum.CameraType.Scriptable then
		camera.CameraType = Enum.CameraType.Scriptable
	end
	updateCursorLock()
	if mode == "Menu" then
		updateMenuCamera(dt)
	else
		updatePlayCamera(dt)
	end
end

local function onInputBegan(input: InputObject, gameProcessed: boolean)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rightMouseDown = true
	elseif input.UserInputType == Enum.UserInputType.Touch and not gameProcessed and mode == "Play" then
		local viewport = getCamera().ViewportSize
		if lookTouch == nil and input.Position.X > viewport.X * 0.45 then
			lookTouch = input
		end
	end
end

local function onInputEnded(input: InputObject)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rightMouseDown = false
	elseif input == lookTouch then
		lookTouch = nil
	elseif input.KeyCode == Enum.KeyCode.Thumbstick2 then
		gamepadLook = Vector2.zero
	end
end

local function onInputChanged(input: InputObject, gameProcessed: boolean)
	if mode ~= "Play" then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		if shouldLockCursor() or rightMouseDown then
			applyLookDelta(input.Delta.X, input.Delta.Y, 1)
		end
	elseif input.UserInputType == Enum.UserInputType.MouseWheel then
		if not gameProcessed then
			zoomTarget =
				math.clamp(zoomTarget - input.Position.Z * config.ZoomStep, config.MinDistance, config.MaxDistance)
		end
	elseif input.UserInputType == Enum.UserInputType.Touch then
		if input == lookTouch then
			applyLookDelta(input.Delta.X, input.Delta.Y, 1.6)
		end
	elseif input.KeyCode == Enum.KeyCode.Thumbstick2 then
		gamepadLook = Vector2.new(input.Position.X, input.Position.Y)
	end
end

function CameraController.setMode(newMode: Mode)
	if mode == newMode then
		return
	end
	mode = newMode
	if newMode == "Play" then
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if root and root:IsA("BasePart") then
			local _, rootYaw = root.CFrame:ToEulerAnglesYXZ()
			yaw = rootYaw
		end
		pitch = math.rad(-16)
		zoomTarget = config.DefaultDistance
		zoomCurrent = config.DefaultDistance
		transition = { from = getCamera().CFrame, start = os.clock(), duration = 0.9 }
	end
	updateCursorLock()
end

function CameraController.getMode(): Mode
	return mode
end

--[[
	Cursor-free reasons stack: menus, dialogs and the user toggle each add a
	reason; the cursor locks again only when every reason is cleared.
]]
function CameraController.setCursorFree(reason: string, free: boolean)
	if free then
		freeCursorReasons[reason] = true
	else
		freeCursorReasons[reason] = nil
	end
	updateCursorLock()
end

function CameraController.isCursorLocked(): boolean
	return lastCursorLocked
end

function CameraController.getYaw(): number
	return yaw
end

function CameraController.Init()
	local ok = pcall(function()
		return typeof((workspace :: any).Spherecast) == "function"
	end)
	hasSpherecast = ok

	rebuildIgnoreList()
	player.CharacterAdded:Connect(function()
		task.defer(rebuildIgnoreList)
	end)
	player.CharacterRemoving:Connect(function()
		task.defer(rebuildIgnoreList)
	end)
	CollectionService:GetInstanceAddedSignal(Tags.CameraIgnore):Connect(rebuildIgnoreList)
	CollectionService:GetInstanceRemovedSignal(Tags.CameraIgnore):Connect(rebuildIgnoreList)

	UserInputService.InputBegan:Connect(onInputBegan)
	UserInputService.InputEnded:Connect(onInputEnded)
	UserInputService.InputChanged:Connect(onInputChanged)

	InputController.ActionBegan:Connect(function(action)
		if action == "ToggleCursor" and mode == "Play" then
			CameraController.setCursorFree("UserToggle", freeCursorReasons["UserToggle"] == nil)
		end
	end)

	ClientState.PlayingChanged:Connect(function(playing)
		CameraController.setMode(if playing then "Play" else "Menu")
	end)
end

function CameraController.Start()
	local camera = getCamera()
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = config.MenuFov
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		local current = workspace.CurrentCamera
		if current then
			current.CameraType = Enum.CameraType.Scriptable
		end
	end)
	RunService:BindToRenderStep("TinyTroubleCamera", Enum.RenderPriority.Camera.Value, onRenderStep)
end

return CameraController
