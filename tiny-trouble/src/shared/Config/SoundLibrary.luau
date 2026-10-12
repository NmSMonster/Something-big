--!strict
--[[
	SoundLibrary
	------------
	Named sounds used by the client. Every entry defaults to a sound that ships
	inside the Roblox client (rbxasset://sounds/...), so the game never depends
	on a marketplace asset being available. Replace `id` with your own
	rbxassetid:// values when you have final audio; an empty id is skipped
	silently.
]]

export type SoundDefinition = {
	id: string,
	volume: number,
	pitchMin: number?,
	pitchMax: number?,
	looped: boolean?,
}

local SoundLibrary: { [string]: SoundDefinition } = {
	Pickup = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.45, pitchMin = 0.95, pitchMax = 1.15 },
	PouchFull = { id = "rbxasset://sounds/clickfast.wav", volume = 0.5, pitchMin = 0.7, pitchMax = 0.75 },
	ObjectiveComplete = { id = "rbxasset://sounds/victory.wav", volume = 0.5 },
	ObjectiveProgress = { id = "rbxasset://sounds/snap.mp3", volume = 0.3, pitchMin = 1.1, pitchMax = 1.3 },
	Notification = { id = "rbxasset://sounds/clickfast.wav", volume = 0.35, pitchMin = 1.0, pitchMax = 1.05 },
	UIClick = { id = "rbxasset://sounds/button.wav", volume = 0.5 },
	UIOpen = { id = "rbxasset://sounds/swoosh.wav", volume = 0.35, pitchMin = 1.1, pitchMax = 1.2 },
	Hurt = { id = "rbxasset://sounds/collide.wav", volume = 0.6, pitchMin = 0.8, pitchMax = 0.9 },
	Death = { id = "rbxasset://sounds/uuhhh.mp3", volume = 0.7 },
	-- Household ambience: provide your own looping asset id here (left empty on purpose).
	Ambience = { id = "", volume = 0.25, looped = true },
}

return SoundLibrary
