--!strict
--[[
	Scale
	-----
	The single source of truth for the miniature world scale.

	A standard Roblox R15 character is ~5 studs tall. Tiny Trouble treats that
	character as a ~2.5 cm tall shrunken human, so every real-world centimetre
	becomes STUDS_PER_CM studs. World generation code works in centimetres and
	converts through this module so the kitchen stays physically coherent.

		Scale.cm(75)  -> 150 studs (a 75 cm tall dining table)
		Scale.vec(30, 0.5, 30) -> Vector3 size of a 30x0.5x30 cm floor tile
]]

local Scale = {}

Scale.STUDS_PER_CM = 2
Scale.CHARACTER_HEIGHT_STUDS = 5
Scale.CHARACTER_HEIGHT_CM = Scale.CHARACTER_HEIGHT_STUDS / Scale.STUDS_PER_CM

function Scale.cm(centimetres: number): number
	return centimetres * Scale.STUDS_PER_CM
end

function Scale.m(metres: number): number
	return metres * 100 * Scale.STUDS_PER_CM
end

function Scale.vec(xCm: number, yCm: number, zCm: number): Vector3
	return Vector3.new(xCm * Scale.STUDS_PER_CM, yCm * Scale.STUDS_PER_CM, zCm * Scale.STUDS_PER_CM)
end

function Scale.toCm(studs: number): number
	return studs / Scale.STUDS_PER_CM
end

return Scale
