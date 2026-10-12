--!strict
--[[
	MovementController
	------------------
	Sprint and crouch on top of Roblox's default character controller.

	The client predicts WalkSpeed changes immediately for responsiveness and
	tells the server, which applies the authoritative speed/jump/hip values
	and can refuse (SprintDenied) when stamina is empty. Evaluation is
	event-driven (input, MoveDirection, Stamina attribute) - no per-frame loop.
	While the menu is open, the default controls are disabled through the
	PlayerModule so the character stays put.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Log = require(ReplicatedStorage.Shared.Util.Log)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local Trove = require(ReplicatedStorage.Shared.Util.Trove)
local ClientState = require(script.Parent.Parent.State.ClientState)
local InputController = require(script.Parent.InputController)

local TAG = "Movement"

local MovementController = {}

local player = Players.LocalPlayer
local movement = GameConfig.Movement
local staminaConfig = GameConfig.Stamina

local humanoid: Humanoid? = nil
local characterTrove = Trove.new()
local wantsSprint = false
local sprinting = false
local crouching = false
local sprintRetryAt = 0
local controls: any = nil

local function getControls(): any
	if controls then
		return controls
	end
	local ok, result = pcall(function()
		local playerScripts = player:WaitForChild("PlayerScripts", 10)
		local playerModule = playerScripts and playerScripts:WaitForChild("PlayerModule", 10)
		if not playerModule or not playerModule:IsA("ModuleScript") then
			return nil
		end
		return (require(playerModule) :: any):GetControls()
	end)
	if ok and result then
		controls = result
	end
	return controls
end

local function setControlsEnabled(enabled: boolean)
	local resolved = getControls()
	if resolved then
		if enabled then
			resolved:Enable()
		else
			resolved:Disable()
		end
	end
end

local function applyLocalSpeed()
	local current = humanoid
	if not current then
		return
	end
	if crouching then
		current.WalkSpeed = movement.CrouchSpeed
	elseif sprinting then
		current.WalkSpeed = movement.SprintSpeed
	else
		current.WalkSpeed = movement.WalkSpeed
	end
end

local function getStamina(): number
	local value = player:GetAttribute("Stamina")
	return if typeof(value) == "number" then value :: number else staminaConfig.Max
end

local function setSprinting(enabled: boolean)
	if sprinting == enabled then
		return
	end
	sprinting = enabled
	applyLocalSpeed()
	ClientState.setMovement(sprinting, crouching)
	Remotes.getEvent(Remotes.Events.SprintState):FireServer(enabled)
end

local function evaluate()
	local current = humanoid
	if not current or current.Health <= 0 then
		setSprinting(false)
		return
	end
	local moving = current.MoveDirection.Magnitude > 0.05
	local stamina = getStamina()
	local threshold = if sprinting then 0 else staminaConfig.MinToStartSprint
	local shouldSprint = wantsSprint
		and moving
		and not crouching
		and ClientState.isPlaying
		and stamina > threshold
		and os.clock() >= sprintRetryAt
	setSprinting(shouldSprint)
end

local function setCrouching(enabled: boolean)
	if crouching == enabled then
		return
	end
	crouching = enabled
	if crouching and sprinting then
		sprinting = false
		Remotes.getEvent(Remotes.Events.SprintState):FireServer(false)
	end
	applyLocalSpeed()
	ClientState.setMovement(sprinting, crouching)
	Remotes.getEvent(Remotes.Events.CrouchState):FireServer(enabled)
end

local function onCharacterAdded(character: Model)
	characterTrove:Clean()
	local foundHumanoid = character:WaitForChild("Humanoid", 10)
	if not foundHumanoid or not foundHumanoid:IsA("Humanoid") then
		Log.warn(TAG, "Character has no Humanoid")
		return
	end
	humanoid = foundHumanoid
	sprinting = false
	crouching = false
	wantsSprint = InputController.isHeld("Sprint")
	ClientState.setMovement(false, false)

	characterTrove:Connect(foundHumanoid:GetPropertyChangedSignal("MoveDirection"), evaluate)
	characterTrove:Connect(foundHumanoid.Died, function()
		sprinting = false
		crouching = false
		ClientState.setMovement(false, false)
	end)
	characterTrove:Add(function()
		if humanoid == foundHumanoid then
			humanoid = nil
		end
	end)

	setControlsEnabled(ClientState.isPlaying)
	evaluate()
end

function MovementController.Init()
	InputController.ActionBegan:Connect(function(action)
		if action == "Sprint" then
			wantsSprint = true
			evaluate()
		elseif action == "Crouch" and ClientState.isPlaying then
			setCrouching(not crouching)
			evaluate()
		end
	end)
	InputController.ActionEnded:Connect(function(action)
		if action == "Sprint" then
			wantsSprint = false
			evaluate()
		end
	end)

	player:GetAttributeChangedSignal("Stamina"):Connect(evaluate)

	Remotes.getEvent(Remotes.Events.SprintDenied).OnClientEvent:Connect(function()
		if sprinting then
			sprinting = false
			applyLocalSpeed()
			ClientState.setMovement(false, crouching)
		end
		sprintRetryAt = os.clock() + 0.6
		task.delay(0.65, evaluate)
	end)

	ClientState.PlayingChanged:Connect(function(playing)
		setControlsEnabled(playing)
		if not playing then
			wantsSprint = false
		end
		evaluate()
	end)
end

function MovementController.Start()
	player.CharacterAdded:Connect(onCharacterAdded)
	local character = player.Character
	if character then
		task.spawn(onCharacterAdded, character)
	end
end

function MovementController.isSprinting(): boolean
	return sprinting
end

function MovementController.isCrouching(): boolean
	return crouching
end

return MovementController
