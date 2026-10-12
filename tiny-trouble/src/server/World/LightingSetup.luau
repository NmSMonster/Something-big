--!strict
--[[
	LightingSetup
	-------------
	Configures Lighting for a warm, sunlit kitchen afternoon and aligns the sun
	so it actually shines in through the north window above the sink.

	Point lights in Roblox are capped at 60 studs of range (30 cm at our scale),
	so the look relies on sunlight, ambient colour and post-processing rather
	than on lamp fixtures.
]]

local Lighting = game:GetService("Lighting")

local Log = require(game:GetService("ReplicatedStorage").Shared.Util.Log)

local TAG = "Lighting"

local LightingSetup = {}

local function clearEffects()
	for _, child in Lighting:GetChildren() do
		if
			child:IsA("Atmosphere")
			or child:IsA("Sky")
			or child:IsA("BloomEffect")
			or child:IsA("ColorCorrectionEffect")
			or child:IsA("SunRaysEffect")
			or child:IsA("DepthOfFieldEffect")
			or child:IsA("BlurEffect")
		then
			child:Destroy()
		end
	end
end

--[[
	Searches clock time / latitude combinations for the sun direction closest to
	`desiredSunDirection` (a unit vector pointing from the room toward the sun).
	Restricted to daytime hours so the sky keeps its warm afternoon colours.
]]
local function alignSun(desiredSunDirection: Vector3)
	local best = -math.huge
	local bestClock = 14.5
	local bestLatitude = 30

	local target = desiredSunDirection.Unit
	for latitude = -70, 70, 5 do
		Lighting.GeographicLatitude = latitude
		for clock = 9, 16.5, 0.25 do
			Lighting.ClockTime = clock
			local score = Lighting:GetSunDirection():Dot(target)
			if score > best then
				best = score
				bestClock = clock
				bestLatitude = latitude
			end
		end
	end

	Lighting.GeographicLatitude = bestLatitude
	Lighting.ClockTime = bestClock
	Log.debug(TAG, "Sun aligned: clock %.2f latitude %d (dot %.3f)", bestClock, bestLatitude, best)
end

function LightingSetup.apply()
	clearEffects()

	Lighting.Brightness = 2.6
	Lighting.Ambient = Color3.fromRGB(128, 120, 112)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 142, 132)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 236, 210)
	Lighting.ColorShift_Bottom = Color3.fromRGB(255, 226, 196)
	Lighting.EnvironmentDiffuseScale = 0.55
	Lighting.EnvironmentSpecularScale = 0.6
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.28
	Lighting.ExposureCompensation = 0.15
	Lighting.FogEnd = 100000
	Lighting.FogStart = 0

	-- Light should pour in through the north window (toward +Z) and fall onto the floor.
	alignSun(Vector3.new(-0.32, 0.5, -0.8))

	local sky = Instance.new("Sky")
	sky.Name = "Sky"
	sky.SunAngularSize = 14
	sky.MoonAngularSize = 8
	sky.StarCount = 1500
	sky.Parent = Lighting

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.24
	atmosphere.Offset = 0.2
	atmosphere.Color = Color3.fromRGB(214, 206, 196)
	atmosphere.Decay = Color3.fromRGB(120, 108, 100)
	atmosphere.Glare = 0.25
	atmosphere.Haze = 1.2
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.35
	bloom.Size = 24
	bloom.Threshold = 1.15
	bloom.Parent = Lighting

	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Brightness = 0.02
	colorCorrection.Contrast = 0.08
	colorCorrection.Saturation = 0.14
	colorCorrection.TintColor = Color3.fromRGB(255, 248, 238)
	colorCorrection.Parent = Lighting

	local sunRays = Instance.new("SunRaysEffect")
	sunRays.Intensity = 0.12
	sunRays.Spread = 0.6
	sunRays.Parent = Lighting

	Log.info(TAG, "Lighting configured (clock %.2f, latitude %d)", Lighting.ClockTime, Lighting.GeographicLatitude)
end

return LightingSetup
