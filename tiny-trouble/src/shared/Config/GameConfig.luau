--!strict
--[[
	GameConfig
	----------
	Tunable gameplay constants. Server and client both read this module; the
	server is always the authority for anything that affects other players.
]]

local GameConfig = {
	Version = "0.1.0-m1",
	GameName = "Tiny Trouble",

	Debug = {
		VerboseLogging = false,
	},

	Movement = {
		WalkSpeed = 18,
		SprintSpeed = 28,
		CrouchSpeed = 9,
		JumpPower = 50,
		CrouchHipHeightOffset = 0.85, -- studs the hips drop while crouching (R15)
		MaxSlopeAngle = 70,
	},

	Stamina = {
		Max = 100,
		SprintDrainPerSecond = 13,
		RegenPerSecond = 17,
		RegenDelay = 1.1, -- seconds after sprinting/jumping before regen starts
		JumpCost = 6,
		MinToStartSprint = 12,
		MovingVelocityThreshold = 2, -- studs/s before sprint actually drains stamina
	},

	Health = {
		Max = 100,
		RegenPerSecond = 1.5,
		RegenDelay = 6,
	},

	FallDamage = {
		SafeDistanceStuds = 26, -- ~13 cm: roughly five body heights, no damage below this
		DamagePerStud = 1.1, -- chair seat (~92 studs) hurts badly, table/counter height is lethal
		MaxDamage = 400,
	},

	Camera = {
		DefaultDistance = 14,
		MinDistance = 4,
		MaxDistance = 42,
		ZoomStep = 2,
		DefaultFov = 70,
		SprintFov = 78,
		MenuFov = 60,
		MinPitchDeg = -78,
		MaxPitchDeg = 68,
		ShoulderOffset = 1.7,
		HeightOffset = 1.9,
		CrouchHeightOffset = 1.1,
		BaseSensitivity = 0.0024, -- radians per pixel at sensitivity 1.0
		CollisionPadding = 0.9,
		ZoomSmoothSpeed = 9,
		FovSmoothSpeed = 6,
	},

	Interaction = {
		MaxDistance = 13, -- prompt activation distance (studs)
		HoldDuration = 0.35,
		ServerDistanceTolerance = 8, -- extra studs the server allows for latency
	},

	Inventory = {
		Capacity = 150, -- total items the starting pouch can hold (upgradable later)
	},

	Resources = {
		RespawnMin = 45,
		RespawnMax = 100,
		RespawnTickInterval = 1,
	},

	Net = {
		CollectBurst = 6,
		CollectPerSecond = 3,
		StateBurst = 12,
		StatePerSecond = 8,
		InitialStateBurst = 3,
		InitialStatePerSecond = 0.2,
	},

	Players = {
		RespawnTime = 4,
		PlayerCollisions = false, -- players walk through each other so nobody blocks narrow passages
		NameDisplayDistance = 160,
	},

	Input = {
		Sprint = { Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3 },
		Crouch = { Enum.KeyCode.LeftControl, Enum.KeyCode.C, Enum.KeyCode.ButtonB },
		ToggleCursor = { Enum.KeyCode.LeftAlt },
		Menu = { Enum.KeyCode.M, Enum.KeyCode.ButtonSelect },
		InteractKey = Enum.KeyCode.E,
		InteractGamepad = Enum.KeyCode.ButtonX,
	},

	UI = {
		ControlsHintSeconds = 18,
		NotificationSeconds = 4.5,
	},
}

export type GameConfig = typeof(GameConfig)

return GameConfig
