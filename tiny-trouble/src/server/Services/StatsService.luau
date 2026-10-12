--!strict
--[[
	StatsService
	------------
	Server authority for stamina, sprinting, crouching, health regeneration
	and fall damage. Runs one 10 Hz tick for every living character instead
	of per-frame work.

	Replication:
	* Stamina -> Player attribute "Stamina" (integer, only written on change)
	* Speed / jump / hip height -> Humanoid properties (replicate to all)
	* Sprint refusals -> SprintDenied RemoteEvent so the client stops predicting
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Log = require(ReplicatedStorage.Shared.Util.Log)
local RateLimiter = require(ReplicatedStorage.Shared.Util.RateLimiter)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local Trove = require(ReplicatedStorage.Shared.Util.Trove)
local Validate = require(ReplicatedStorage.Shared.Util.Validate)
local PlayerService = require(script.Parent.PlayerService)

local TAG = "StatsService"
local TICK_INTERVAL = 0.1

local StatsService = {}

type CharacterStats = {
	player: Player,
	character: Model,
	humanoid: Humanoid,
	root: BasePart,
	trove: Trove.Trove,
	stamina: number,
	lastSentStamina: number,
	sprinting: boolean,
	crouching: boolean,
	baseHipHeight: number?,
	regenBlockedUntil: number,
	healthRegenBlockedUntil: number,
	lastHealth: number,
	falling: boolean,
	fallPeakY: number,
	lastState: Enum.HumanoidStateType,
}

local statsByPlayer: { [Player]: CharacterStats } = {}
local stateLimiter = RateLimiter.new(GameConfig.Net.StateBurst, GameConfig.Net.StatePerSecond)
local accumulator = 0

local function sendStamina(stats: CharacterStats, force: boolean?)
	local rounded = math.floor(stats.stamina + 0.5)
	if force or rounded ~= stats.lastSentStamina then
		stats.lastSentStamina = rounded
		stats.player:SetAttribute("Stamina", rounded)
	end
end

local function applyMovement(stats: CharacterStats)
	local humanoid = stats.humanoid
	local movement = GameConfig.Movement
	if stats.crouching then
		humanoid.WalkSpeed = movement.CrouchSpeed
		humanoid.JumpPower = 0
	elseif stats.sprinting then
		humanoid.WalkSpeed = movement.SprintSpeed
		humanoid.JumpPower = movement.JumpPower
	else
		humanoid.WalkSpeed = movement.WalkSpeed
		humanoid.JumpPower = movement.JumpPower
	end

	-- Crouch pose: lower the hips (R15 only; R6 has no hip height).
	if humanoid.RigType == Enum.HumanoidRigType.R15 then
		if stats.crouching then
			if stats.baseHipHeight == nil then
				stats.baseHipHeight = humanoid.HipHeight
			end
			humanoid.HipHeight = math.max(0.2, (stats.baseHipHeight :: number) - movement.CrouchHipHeightOffset)
		elseif stats.baseHipHeight ~= nil then
			humanoid.HipHeight = stats.baseHipHeight :: number
			stats.baseHipHeight = nil
		end
	end
end

local function setSprinting(stats: CharacterStats, wantsSprint: boolean, fromRequest: boolean)
	local staminaConfig = GameConfig.Stamina
	local allowed = wantsSprint
	if allowed and (stats.crouching or stats.humanoid.Health <= 0) then
		allowed = false
	end
	if allowed and not stats.sprinting and stats.stamina < staminaConfig.MinToStartSprint then
		allowed = false
	end

	if stats.sprinting == allowed then
		if wantsSprint and not allowed and fromRequest then
			Remotes.getEvent(Remotes.Events.SprintDenied):FireClient(stats.player)
		end
		return
	end

	stats.sprinting = allowed
	applyMovement(stats)
	if wantsSprint and not allowed then
		Remotes.getEvent(Remotes.Events.SprintDenied):FireClient(stats.player)
	end
end

local function applyFallDamage(stats: CharacterStats, drop: number)
	local config = GameConfig.FallDamage
	if drop <= config.SafeDistanceStuds then
		return
	end
	local damage = math.min(config.MaxDamage, (drop - config.SafeDistanceStuds) * config.DamagePerStud)
	if damage < 1 then
		return
	end
	local humanoid = stats.humanoid
	if damage >= humanoid.Health then
		stats.player:SetAttribute("LastDeathCause", "You fell from a great height.")
	end
	humanoid:TakeDamage(damage)
	stats.healthRegenBlockedUntil = os.clock() + GameConfig.Health.RegenDelay
	Log.debug(TAG, "%s fell %.0f studs for %.0f damage", stats.player.Name, drop, damage)
end

local function tickStats(stats: CharacterStats, dt: number)
	local humanoid = stats.humanoid
	if humanoid.Health <= 0 then
		return
	end
	local now = os.clock()
	local staminaConfig = GameConfig.Stamina
	local root = stats.root

	-- Stamina drain / regen.
	local velocity = root.AssemblyLinearVelocity
	local horizontalSpeed = Vector2.new(velocity.X, velocity.Z).Magnitude
	if stats.sprinting then
		if horizontalSpeed > staminaConfig.MovingVelocityThreshold then
			stats.stamina -= staminaConfig.SprintDrainPerSecond * dt
			stats.regenBlockedUntil = now + staminaConfig.RegenDelay
		end
		if stats.stamina <= 0 then
			stats.stamina = 0
			setSprinting(stats, false, false)
			Remotes.getEvent(Remotes.Events.SprintDenied):FireClient(stats.player)
		end
	elseif now >= stats.regenBlockedUntil and stats.stamina < staminaConfig.Max then
		stats.stamina = math.min(staminaConfig.Max, stats.stamina + staminaConfig.RegenPerSecond * dt)
	end

	-- Jump cost (state transitions replicate from the owning client).
	local state = humanoid:GetState()
	if state == Enum.HumanoidStateType.Jumping and stats.lastState ~= Enum.HumanoidStateType.Jumping then
		stats.stamina = math.max(0, stats.stamina - staminaConfig.JumpCost)
		stats.regenBlockedUntil = math.max(stats.regenBlockedUntil, now + staminaConfig.RegenDelay * 0.5)
	end

	-- Fall tracking: remember the highest point of a free fall and damage on landing.
	if state == Enum.HumanoidStateType.Freefall then
		if stats.falling then
			stats.fallPeakY = math.max(stats.fallPeakY, root.Position.Y)
		else
			stats.falling = true
			stats.fallPeakY = root.Position.Y
		end
	elseif stats.falling then
		stats.falling = false
		if state ~= Enum.HumanoidStateType.Swimming and state ~= Enum.HumanoidStateType.Dead then
			applyFallDamage(stats, stats.fallPeakY - root.Position.Y)
		end
	end
	stats.lastState = state

	-- Health regeneration after a quiet period.
	local healthConfig = GameConfig.Health
	if humanoid.Health < humanoid.MaxHealth and now >= stats.healthRegenBlockedUntil then
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + healthConfig.RegenPerSecond * dt)
		stats.lastHealth = humanoid.Health
	end

	sendStamina(stats)
end

local function onHeartbeat(dt: number)
	accumulator += dt
	if accumulator < TICK_INTERVAL then
		return
	end
	local step = accumulator
	accumulator = 0
	for _, stats in statsByPlayer do
		local ok, err = pcall(tickStats :: any, stats, step)
		if not ok then
			Log.error(TAG, "tick failed for %s: %s", stats.player.Name, tostring(err))
		end
	end
end

local function onCharacterAdded(player: Player, character: Model, humanoid: Humanoid)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end

	local existing = statsByPlayer[player]
	if existing then
		existing.trove:Destroy()
	end

	local trove = Trove.new()
	local stats: CharacterStats = {
		player = player,
		character = character,
		humanoid = humanoid,
		root = root,
		trove = trove,
		stamina = GameConfig.Stamina.Max,
		lastSentStamina = -1,
		sprinting = false,
		crouching = false,
		baseHipHeight = nil,
		regenBlockedUntil = 0,
		healthRegenBlockedUntil = 0,
		lastHealth = humanoid.Health,
		falling = false,
		fallPeakY = root.Position.Y,
		lastState = humanoid:GetState(),
	}
	statsByPlayer[player] = stats

	trove:Connect(humanoid.HealthChanged, function(health)
		if health < stats.lastHealth then
			stats.healthRegenBlockedUntil = os.clock() + GameConfig.Health.RegenDelay
		end
		stats.lastHealth = health
	end)
	trove:Connect(humanoid.Died, function()
		stats.sprinting = false
		stats.crouching = false
	end)

	applyMovement(stats)
	sendStamina(stats, true)
end

local function removeStats(player: Player)
	local stats = statsByPlayer[player]
	if stats then
		statsByPlayer[player] = nil
		stats.trove:Destroy()
	end
end

function StatsService.Init()
	PlayerService.PlayerAdded:Connect(function(player)
		player:SetAttribute("MaxStamina", GameConfig.Stamina.Max)
		player:SetAttribute("Stamina", GameConfig.Stamina.Max)
	end)
	PlayerService.CharacterAdded:Connect(onCharacterAdded)
	PlayerService.CharacterRemoving:Connect(function(player)
		removeStats(player)
	end)
	PlayerService.PlayerRemoving:Connect(function(player)
		removeStats(player)
		stateLimiter:Forget(player)
	end)
end

function StatsService.Start()
	RunService.Heartbeat:Connect(onHeartbeat)

	Remotes.getEvent(Remotes.Events.SprintState).OnServerEvent:Connect(function(player, wantsSprint)
		if not Validate.isBoolean(wantsSprint) or not stateLimiter:Allow(player) then
			return
		end
		local stats = statsByPlayer[player]
		if not stats then
			return
		end
		setSprinting(stats, wantsSprint :: boolean, true)
	end)

	Remotes.getEvent(Remotes.Events.CrouchState).OnServerEvent:Connect(function(player, isCrouching)
		if not Validate.isBoolean(isCrouching) or not stateLimiter:Allow(player) then
			return
		end
		local stats = statsByPlayer[player]
		if not stats or stats.humanoid.Health <= 0 then
			return
		end
		stats.crouching = isCrouching :: boolean
		if stats.crouching and stats.sprinting then
			stats.sprinting = false
			Remotes.getEvent(Remotes.Events.SprintDenied):FireClient(player)
		end
		applyMovement(stats)
	end)
end

function StatsService.getStamina(player: Player): number
	local stats = statsByPlayer[player]
	return if stats then stats.stamina else 0
end

return StatsService
