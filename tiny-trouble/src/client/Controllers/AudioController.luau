--!strict
--[[
	AudioController
	---------------
	Plays named sounds from Shared.Config.SoundLibrary. Missing or empty ids
	are skipped silently, so audio can never break the game. UI sounds play
	in SoundService (2D); world sounds are parented to a short-lived part.
]]

local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Log = require(ReplicatedStorage.Shared.Util.Log)
local SoundLibrary = require(ReplicatedStorage.Shared.Config.SoundLibrary)

local TAG = "Audio"

local AudioController = {}

local random = Random.new()
local ambience: Sound? = nil
local worldFolder: Folder? = nil

local function getWorldFolder(): Folder
	local cached = worldFolder
	if cached and cached.Parent then
		return cached
	end
	local folder = Instance.new("Folder")
	folder.Name = "TinyTroubleSounds"
	folder.Parent = workspace
	worldFolder = folder
	return folder
end

local function buildSound(name: string): Sound?
	local definition = SoundLibrary[name]
	if not definition then
		Log.warn(TAG, "Unknown sound '%s'", name)
		return nil
	end
	if definition.id == "" then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = definition.id
	sound.Volume = definition.volume
	sound.Looped = definition.looped == true
	local pitchMin = definition.pitchMin or 1
	local pitchMax = definition.pitchMax or pitchMin
	sound.PlaybackSpeed = random:NextNumber(pitchMin, pitchMax)
	return sound
end

--[[
	Plays a 2D (UI) sound.
]]
function AudioController.play(name: string)
	local sound = buildSound(name)
	if not sound then
		return
	end
	sound.Parent = SoundService
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	Debris:AddItem(sound, 12)
	sound:Play()
end

--[[
	Plays a positional sound in the world.
]]
function AudioController.playAt(name: string, position: Vector3)
	local sound = buildSound(name)
	if not sound then
		return
	end
	local emitter = Instance.new("Part")
	emitter.Name = "SoundEmitter"
	emitter.Size = Vector3.new(0.2, 0.2, 0.2)
	emitter.Transparency = 1
	emitter.Anchored = true
	emitter.CanCollide = false
	emitter.CanQuery = false
	emitter.CanTouch = false
	emitter.Position = position
	emitter.Parent = getWorldFolder()
	sound.RollOffMaxDistance = 120
	sound.RollOffMinDistance = 8
	sound.Parent = emitter
	Debris:AddItem(emitter, 12)
	sound:Play()
end

function AudioController.startAmbience()
	if ambience then
		return
	end
	local sound = buildSound("Ambience")
	if not sound then
		return
	end
	sound.Looped = true
	sound.Parent = SoundService
	sound:Play()
	ambience = sound
end

function AudioController.Init()
	-- Preload in the background; failures are harmless.
	task.spawn(function()
		local assets = {}
		for _, definition in SoundLibrary do
			if definition.id ~= "" then
				local sound = Instance.new("Sound")
				sound.SoundId = definition.id
				table.insert(assets, sound)
			end
		end
		if #assets > 0 then
			pcall(function()
				ContentProvider:PreloadAsync(assets)
			end)
		end
		for _, sound in assets do
			sound:Destroy()
		end
	end)
end

function AudioController.Start()
	AudioController.startAmbience()
end

return AudioController
