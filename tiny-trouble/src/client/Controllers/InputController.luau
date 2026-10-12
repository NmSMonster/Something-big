--!strict
--[[
	InputController
	---------------
	Maps raw input to named gameplay actions through ContextActionService.
	Keyboard/gamepad bindings live in GameConfig.Input; on touch devices the
	same actions get on-screen buttons for free, so mobile controls can be
	added without touching gameplay code.
]]

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)

local InputController = {}

export type ActionName = "Sprint" | "Crouch" | "ToggleCursor" | "Menu"
-- One of "Keyboard", "Gamepad" or "Touch" (kept as a string alias: Luau's current solver widens
-- literal unions across assignments).
export type InputKind = string

InputController.ActionBegan = Signal.new() :: Signal.Signal<ActionName>
InputController.ActionEnded = Signal.new() :: Signal.Signal<ActionName>
InputController.InputKindChanged = Signal.new() :: Signal.Signal<InputKind>

local held: { [string]: boolean } = {}
local currentKind: InputKind = "Keyboard"

local TOUCH_BUTTONS: { [string]: { title: string, position: UDim2 } } = {
	Sprint = { title = "Sprint", position = UDim2.new(1, -170, 1, -150) },
	Crouch = { title = "Crouch", position = UDim2.new(1, -90, 1, -220) },
	Menu = { title = "Menu", position = UDim2.new(1, -250, 1, -220) },
}

local function bindAction(name: ActionName, keys: { Enum.KeyCode })
	local function handler(
		_actionName: string,
		state: Enum.UserInputState,
		_input: InputObject
	): Enum.ContextActionResult
		if state == Enum.UserInputState.Begin then
			held[name] = true
			InputController.ActionBegan:Fire(name)
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
			if held[name] then
				held[name] = false
				InputController.ActionEnded:Fire(name)
			end
		end
		return Enum.ContextActionResult.Pass
	end

	local touchButton = UserInputService.TouchEnabled and TOUCH_BUTTONS[name] ~= nil
	ContextActionService:BindAction("TT_" .. name, handler, touchButton, table.unpack(keys))

	if touchButton then
		local spec = TOUCH_BUTTONS[name]
		ContextActionService:SetTitle("TT_" .. name, spec.title)
		ContextActionService:SetPosition("TT_" .. name, spec.position)
	end
end

local function kindFromInputType(inputType: Enum.UserInputType): InputKind?
	if
		inputType == Enum.UserInputType.Keyboard
		or inputType == Enum.UserInputType.MouseMovement
		or inputType == Enum.UserInputType.MouseButton1
		or inputType == Enum.UserInputType.MouseButton2
		or inputType == Enum.UserInputType.MouseWheel
	then
		return "Keyboard"
	elseif inputType == Enum.UserInputType.Touch then
		return "Touch"
	elseif inputType.Name:sub(1, 7) == "Gamepad" then
		return "Gamepad"
	end
	return nil
end

local function updateKind(inputType: Enum.UserInputType)
	local kind = kindFromInputType(inputType)
	if kind ~= nil and kind ~= currentKind then
		currentKind = kind
		InputController.InputKindChanged:Fire(kind)
	end
end

function InputController.Init()
	local input = GameConfig.Input
	bindAction("Sprint", input.Sprint)
	bindAction("Crouch", input.Crouch)
	bindAction("ToggleCursor", input.ToggleCursor)
	bindAction("Menu", input.Menu)

	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		currentKind = "Touch"
	elseif UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled then
		currentKind = "Gamepad"
	end
	UserInputService.LastInputTypeChanged:Connect(updateKind)
end

function InputController.isHeld(name: ActionName): boolean
	return held[name] == true
end

function InputController.getInputKind(): InputKind
	return currentKind
end

--[[
	Glyph shown on interaction prompts for the current input device.
]]
function InputController.getInteractGlyph(): string
	if currentKind == "Gamepad" then
		return "X"
	elseif currentKind == "Touch" then
		return "TAP"
	end
	return GameConfig.Input.InteractKey.Name
end

return InputController
