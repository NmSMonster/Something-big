--!strict
--[[
	HudController
	-------------
	Keeps the HUD in sync with replicated state: health, stamina, pouch,
	objective tracker, notifications, crosshair, controls hint and the
	death/respawn screen. All updates are event-driven and tweened.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local ObjectiveDefinitions = require(ReplicatedStorage.Shared.Config.ObjectiveDefinitions)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local Trove = require(ReplicatedStorage.Shared.Util.Trove)
local Types = require(ReplicatedStorage.Shared.Types)
local ClientState = require(script.Parent.Parent.State.ClientState)
local DeathScreen = require(script.Parent.Parent.UI.DeathScreen)
local Hud = require(script.Parent.Parent.UI.Hud)
local Notifications = require(script.Parent.Parent.UI.Notifications)
local Theme = require(script.Parent.Parent.UI.Theme)
local AudioController = require(script.Parent.AudioController)
local CameraController = require(script.Parent.CameraController)

local HudController = {}

local player = Players.LocalPlayer
local hud: Hud.Hud? = nil
local characterTrove = Trove.new()
local lastHealth = GameConfig.Health.Max
local lastObjectiveProgress = 0
local controlsHintToken = 0

local function getHud(): Hud.Hud
	local current = hud
	assert(current, "HUD not built")
	return current
end

local function updateScale()
	local camera = workspace.CurrentCamera
	if not camera or not hud then
		return
	end
	local viewport = camera.ViewportSize
	local scale = math.clamp(math.min(viewport.X / 1500, viewport.Y / 880), 0.72, 1.15)
	getHud().scale.Scale = scale
end

local function updateHealth(health: number, maxHealth: number)
	local ui = getHud()
	local alpha = if maxHealth > 0 then math.clamp(health / maxHealth, 0, 1) else 0
	TweenService:Create(ui.health.fill, Theme.Tween.Normal, { Size = UDim2.fromScale(alpha, 1) }):Play()
	ui.health.value.Text = tostring(math.floor(health + 0.5))
	ui.health.value.TextColor3 = if alpha < 0.3 then Theme.Colors.Danger else Theme.Colors.Text

	if health < lastHealth - 0.5 then
		ui.damageFlash.BackgroundTransparency = 0.55
		TweenService:Create(ui.damageFlash, Theme.Tween.Slow, { BackgroundTransparency = 1 }):Play()
		AudioController.play("Hurt")
	end
	lastHealth = health
end

local function updateStamina()
	local ui = getHud()
	local value = player:GetAttribute("Stamina")
	local maxValue = player:GetAttribute("MaxStamina")
	local stamina = if typeof(value) == "number" then value :: number else GameConfig.Stamina.Max
	local maxStamina = if typeof(maxValue) == "number" then maxValue :: number else GameConfig.Stamina.Max
	local alpha = if maxStamina > 0 then math.clamp(stamina / maxStamina, 0, 1) else 0
	TweenService
		:Create(ui.stamina.fill, TweenInfo.new(0.12, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(alpha, 1) })
		:Play()
	ui.stamina.value.Text = tostring(math.floor(stamina + 0.5))
	local exhausted = stamina < GameConfig.Stamina.MinToStartSprint
	ui.stamina.fill.BackgroundColor3 = if exhausted then Theme.Colors.StaminaDark else Theme.Colors.Stamina
end

local function updatePouch(snapshot: Types.InventorySnapshot)
	local ui = getHud()
	local seen: { [string]: boolean } = {}
	for resourceId, count in snapshot.counts do
		if count <= 0 then
			continue
		end
		seen[resourceId] = true
		local row = ui.pouchRows[resourceId]
		if not row then
			row = Hud.buildPouchRow(ui.pouchList, resourceId)
			ui.pouchRows[resourceId] = row
		end
		local text = ("x%d"):format(count)
		if row.count.Text ~= text then
			row.count.Text = text
			row.count.TextSize = 20
			TweenService:Create(row.count, Theme.Tween.Bounce, { TextSize = 16 }):Play()
		end
	end
	for resourceId, row in ui.pouchRows do
		if not seen[resourceId] then
			ui.pouchRows[resourceId] = nil
			row.frame:Destroy()
		end
	end
	ui.pouchEmpty.Visible = snapshot.total <= 0
	ui.pouchCapacity.Text = ("%d / %d"):format(snapshot.total, snapshot.capacity)
	ui.pouchCapacity.TextColor3 = if snapshot.total >= snapshot.capacity * 0.9
		then Theme.Colors.Warning
		else Theme.Colors.TextMuted
end

local function updateObjective(state: Types.ObjectiveState)
	local ui = getHud()
	local definition = ObjectiveDefinitions.get(state.index)

	if state.completedId then
		AudioController.play("ObjectiveComplete")
		ui.objective.BackgroundColor3 = Theme.Colors.Success:Lerp(Theme.Colors.Panel, 0.5)
		TweenService:Create(ui.objective, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = Theme.Colors.Panel,
		}):Play()
		lastObjectiveProgress = 0
	elseif state.progress > lastObjectiveProgress then
		AudioController.play("ObjectiveProgress")
	end
	lastObjectiveProgress = state.progress

	if state.allComplete or not definition then
		ui.objectiveTitle.Text = "Kitchen explored"
		ui.objectiveDescription.Text =
			"You completed every foundation objective. Keep gathering - crafting arrives next."
		ui.objectiveHint.Text = ""
		ui.objectiveProgress.Text = "✓"
		ui.objectiveBadge.Text = "COMPLETE"
		TweenService:Create(ui.objectiveFill, Theme.Tween.Normal, { Size = UDim2.fromScale(1, 1) }):Play()
		return
	end

	ui.objectiveTitle.Text = definition.title
	ui.objectiveDescription.Text = definition.description
	ui.objectiveHint.Text = "Hint: " .. definition.hint
	ui.objectiveBadge.Text = ("%d / %d"):format(state.index, #ObjectiveDefinitions.List)
	if definition.kind == "collect" then
		ui.objectiveProgress.Text = ("%d / %d"):format(state.progress, state.target)
	else
		ui.objectiveProgress.Text = "GO"
	end
	local alpha = if state.target > 0 then math.clamp(state.progress / state.target, 0, 1) else 0
	TweenService:Create(ui.objectiveFill, Theme.Tween.Normal, { Size = UDim2.fromScale(alpha, 1) }):Play()
end

local function showControlsHint()
	local ui = getHud()
	controlsHintToken += 1
	local token = controlsHintToken
	ui.controlsHint.Visible = ClientState.settings.showControlsHint
	task.delay(GameConfig.UI.ControlsHintSeconds, function()
		if token == controlsHintToken then
			ui.controlsHint.Visible = false
		end
	end)
end

local function onCharacterAdded(character: Model)
	characterTrove:Clean()
	DeathScreen.hide()
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end
	lastHealth = humanoid.Health
	updateHealth(humanoid.Health, humanoid.MaxHealth)
	characterTrove:Connect(humanoid.HealthChanged, function(health)
		updateHealth(health, humanoid.MaxHealth)
	end)
	characterTrove:Connect(humanoid.Died, function()
		local cause = player:GetAttribute("LastDeathCause")
		DeathScreen.show(if typeof(cause) == "string" then cause :: string else "", Players.RespawnTime)
		AudioController.play("Death")
	end)
end

function HudController.Init()
	local playerGui = player:WaitForChild("PlayerGui")
	local built = Hud.build(playerGui)
	hud = built
	built.gui.Enabled = false
	Notifications.init(built.notifications)
	DeathScreen.init(playerGui)

	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	end)

	updatePouch(ClientState.inventory)
	updateObjective(ClientState.objective)
	updateStamina()

	ClientState.InventoryChanged:Connect(updatePouch)
	ClientState.ObjectiveChanged:Connect(updateObjective)
	ClientState.SettingsChanged:Connect(function(settings)
		if not settings.showControlsHint then
			built.controlsHint.Visible = false
		end
	end)
	ClientState.PlayingChanged:Connect(function(playing)
		built.gui.Enabled = playing
		if playing then
			showControlsHint()
		end
	end)
	CameraController.CursorLockChanged:Connect(function(locked)
		built.crosshair.Visible = locked
	end)
	player:GetAttributeChangedSignal("Stamina"):Connect(updateStamina)
	player:GetAttributeChangedSignal("MaxStamina"):Connect(updateStamina)

	Remotes.getEvent(Remotes.Events.Notification).OnClientEvent:Connect(function(payload)
		if typeof(payload) ~= "table" or typeof(payload.title) ~= "string" then
			return
		end
		Notifications.push(payload)
		AudioController.play("Notification")
	end)

	local camera = workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
	end
	updateScale()
end

function HudController.Start()
	player.CharacterAdded:Connect(onCharacterAdded)
	local character = player.Character
	if character then
		task.spawn(onCharacterAdded, character)
	end
end

return HudController
