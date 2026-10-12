--!strict
--[[
	PlayerService
	-------------
	Single owner of the player/character lifecycle. Other services subscribe
	to its signals instead of connecting to Players.PlayerAdded themselves,
	which keeps ordering deterministic and cleanup centralised.
]]

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Log = require(ReplicatedStorage.Shared.Util.Log)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local Trove = require(ReplicatedStorage.Shared.Util.Trove)

local TAG = "PlayerService"
local PLAYER_COLLISION_GROUP = "TT_Players"

local PlayerService = {}

PlayerService.PlayerAdded = Signal.new() :: Signal.Signal<Player>
PlayerService.PlayerRemoving = Signal.new() :: Signal.Signal<Player>
PlayerService.CharacterAdded = Signal.new() :: Signal.Signal<Player, Model, Humanoid>
PlayerService.CharacterRemoving = Signal.new() :: Signal.Signal<Player, Model>
PlayerService.CharacterDied = Signal.new() :: Signal.Signal<Player, Model>

local playerTroves: { [Player]: Trove.Trove } = {}
local characterTroves: { [Player]: Trove.Trove } = {}
local collisionGroupReady = false

local function setupCollisionGroup()
	if GameConfig.Players.PlayerCollisions then
		return
	end
	local ok, err = pcall(function()
		PhysicsService:RegisterCollisionGroup(PLAYER_COLLISION_GROUP)
		PhysicsService:CollisionGroupSetCollidable(PLAYER_COLLISION_GROUP, PLAYER_COLLISION_GROUP, false)
	end)
	if ok then
		collisionGroupReady = true
	else
		Log.warn(TAG, "Could not configure player collision group: %s", tostring(err))
	end
end

local function assignCollisionGroup(instance: Instance)
	if collisionGroupReady and instance:IsA("BasePart") then
		instance.CollisionGroup = PLAYER_COLLISION_GROUP
	end
end

local function cleanupCharacter(player: Player)
	local trove = characterTroves[player]
	if trove then
		characterTroves[player] = nil
		trove:Destroy()
	end
end

local function onCharacterAdded(player: Player, character: Model)
	cleanupCharacter(player)
	local trove = Trove.new()
	characterTroves[player] = trove

	local humanoid = character:WaitForChild("Humanoid", 10)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not humanoid:IsA("Humanoid") or not root then
		Log.warn(TAG, "Character for %s did not load a Humanoid/root in time", player.Name)
		return
	end
	if characterTroves[player] ~= trove then
		return -- a newer character replaced this one while we were waiting
	end

	humanoid.WalkSpeed = GameConfig.Movement.WalkSpeed
	humanoid.UseJumpPower = true
	humanoid.JumpPower = GameConfig.Movement.JumpPower
	humanoid.MaxHealth = GameConfig.Health.Max
	humanoid.Health = GameConfig.Health.Max
	humanoid.MaxSlopeAngle = GameConfig.Movement.MaxSlopeAngle
	humanoid.NameDisplayDistance = GameConfig.Players.NameDisplayDistance
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer

	for _, descendant in character:GetDescendants() do
		assignCollisionGroup(descendant)
	end
	trove:Connect(character.DescendantAdded, assignCollisionGroup)

	trove:Connect(humanoid.Died, function()
		PlayerService.CharacterDied:Fire(player, character)
	end)

	PlayerService.CharacterAdded:Fire(player, character, humanoid)
	Log.debug(TAG, "Character ready for %s", player.Name)
end

local function onPlayerAdded(player: Player)
	if playerTroves[player] then
		return
	end
	local trove = Trove.new()
	playerTroves[player] = trove

	player:SetAttribute("LastDeathCause", "")
	player:SetAttribute("ClientReady", false)

	trove:Connect(player.CharacterAdded, function(character)
		onCharacterAdded(player, character)
	end)
	trove:Connect(player.CharacterRemoving, function(character)
		PlayerService.CharacterRemoving:Fire(player, character)
		cleanupCharacter(player)
	end)

	PlayerService.PlayerAdded:Fire(player)
	Log.info(TAG, "%s joined (%d online)", player.Name, #Players:GetPlayers())

	local character = player.Character
	if character then
		task.spawn(onCharacterAdded, player, character)
	end
end

local function onPlayerRemoving(player: Player)
	PlayerService.PlayerRemoving:Fire(player)
	cleanupCharacter(player)
	local trove = playerTroves[player]
	if trove then
		playerTroves[player] = nil
		trove:Destroy()
	end
	Log.info(TAG, "%s left", player.Name)
end

function PlayerService.Init()
	setupCollisionGroup()
end

function PlayerService.Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

function PlayerService.getCharacterParts(player: Player): (Model?, Humanoid?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and not root:IsA("BasePart") then
		root = nil
	end
	return character, humanoid, root :: BasePart?
end

function PlayerService.isAlive(player: Player): boolean
	local _, humanoid = PlayerService.getCharacterParts(player)
	return humanoid ~= nil and (humanoid :: Humanoid).Health > 0
end

return PlayerService
