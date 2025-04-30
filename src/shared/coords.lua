local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)

type CubicCoordinate = types.CubicCoordinate
type EncodedCoordinate = types.EncodedCoordinate

function coords_eq(c1: CubicCoordinate, c2: CubicCoordinate): boolean
	return c1[1] == c2[1] and c1[2] == c2[2] and c1[3] == c2[3]
end

function coords_add(c1: CubicCoordinate, c2: CubicCoordinate): CubicCoordinate
	return {
		c1[1] + c2[1],
		c1[2] + c2[2],
		c1[3] + c2[3],
	}
end
function coords_sub(c1: CubicCoordinate, c2: CubicCoordinate): CubicCoordinate
	return {
		c1[1] - c2[1],
		c1[2] - c2[2],
		c1[3] - c2[3],
	}
end

--- Rotates a CubicCoordinate around the origin counterclockwise 60 degrees `rotation` times
function rotate_coord(coord: CubicCoordinate, rotation: number): CubicCoordinate
	local x, y, z = coord[1], coord[2], coord[3]
	for i = 1, rotation do
		local temp = x
		x = -z
		y = -x
		z = -temp
	end
	return { x, y, z }
end

--- Encodes a CubicCoordinate into a string
--- Makes no guarantees on the output format, only that
--- - `forall coord: CubicCoordinate. coord == decode_coord(encode_coord(coord))`
function encode_coord(coord: CubicCoordinate): EncodedCoordinate
	return string.format("%d %d", coord[1], coord[2])
end

--  Decodes a string back into a CubicCoordinate
function decode_coord(s: EncodedCoordinate): CubicCoordinate
	local res = string.split(s, " ")
	local x = tonumber(res[1])
	local y = tonumber(res[2])
	local z = -x - y
	return { x, y, z }
end

function display_coord(coord: CubicCoordinate): string
	return string.format("(%d, %d, %d)", coord[1], coord[2], coord[3])
end

local rotation_to_direction = {
	[1] = { 0, 1, -1 },
	[2] = { 1, 0, -1 },
	[3] = { 1, -1, 0 },
	[4] = { 0, -1, 1 },
	[5] = { -1, 0, 1 },
	[0] = { -1, 1, 0 },
}

-- i am pretty certain neighbors_eq is broken
-- returns neighbors at a radius. can give neighbors that are out of bounds
function neighbors_eq(center: CubicCoordinate, radius: number)
	local result = {}
	if radius == 0 then
		table.insert(result, center)
	else
		for _, dir in rotation_to_direction do
			for i = 1, radius do
				local neighbor = {
					center[1] + dir[1] * i,
					center[2] + dir[2] * i,
					center[3] + dir[3] * i,
				}
				table.insert(result, neighbor)
			end
		end
	end
	return result
end
function coords_lerp(a, b, t): CubicCoordinate
	return {
		a[1] + (b[1] - a[1]) * t,
		a[2] + (b[2] - a[2]) * t,
		a[3] + (b[3] - a[3]) * t,
	}
end

-- All coordinates *within or equal to* a radius
function neighbors_leq(origin: CubicCoordinate, radius: number): { CubicCoordinate }
	local results = {}
	for x = -radius, radius do
		for y = math.max(-radius, -x - radius), math.min(radius, -x + radius) do
			local z = -x - y
			table.insert(results, { origin[1] + x, origin[2] + y, origin[3] + z })
		end
	end
	return results
end

-- All coordinates within or equal to a radius from any of the input coordinates
function neighbors_many_leq(coords: { CubicCoordinate }, radius: number): { CubicCoordinate }
	local set = {}
	for _, coord in coords do
		for _, neighbor in neighbors_leq(coord, radius) do
			set[encode_coord(neighbor)] = neighbor
		end
	end
	local result = {}
	for _, coord in set do
		table.insert(result, coord)
	end
	return result
end

function coords_dist(c1: CubicCoordinate, c2: CubicCoordinate): number
	return math.max(math.abs(c1[1] - c2[1]), math.abs(c1[2] - c2[2]), math.abs(c1[3] - c2[3]))
end

-- Converts position into vec3 at y=0
function into_vec3(coord: CubicCoordinate): Vector3
	local x, z = coord[1], coord[3]
	-- Pointy top hex calculations
	local fx = (3 ^ 0.5) * x + ((3 ^ 0.5) / 2) * z
	local fz = 1.5 * z
	return Vector3.new(fz, 0, fx)
end

function into_cframe(coord: CubicCoordinate): CFrame
	return CFrame.new(into_vec3(coord))
end

function from_vec3(_vec: Vector3): CubicCoordinate
	error "todo"
	return 0 :: any
end

function coords_round(coord: { number }): { CubicCoordinate }
	local q = math.floor(coord[1] + 0.5)
	local r = math.floor(coord[2] + 0.5)
	local s = math.floor(coord[3] + 0.5)

	local q_diff = math.abs(q - coord[1])
	local r_diff = math.abs(r - coord[2])
	local s_diff = math.abs(s - coord[3])

	local results = {}

	-- Check for boundaries and add the neighboring cells it falls between
	if q_diff == 0.5 then
		table.insert(results, { q + (q > coord[1] and -1 or 1), r, s })
	end
	if r_diff == 0.5 then
		table.insert(results, { q, r + (r > coord[2] and -1 or 1), s })
	end
	if s_diff == 0.5 then
		table.insert(results, { q, r, s + (s > coord[3] and -1 or 1) })
	end

	if q_diff > r_diff and q_diff > s_diff then
		q = -r - s
	elseif r_diff > s_diff then
		r = -q - s
	else
		s = -q - r
	end

	table.insert(results, { q == -0 and 0 or q, r == -0 and 0 or r, s == -0 and 0 or s })

	return results
end

return {
	coords_eq = coords_eq,
	coords_sub = coords_sub,
	coords_add = coords_add,
	decode_coord = decode_coord,
	encode_coord = encode_coord,
	neighbors_eq = neighbors_eq,
	neighbors_leq = neighbors_leq,
	neighbors_many_leq = neighbors_many_leq,
	coords_dist = coords_dist,
	into_vec3 = into_vec3,
	into_cframe = into_cframe,
	from_vec3 = from_vec3,
	coords_lerp = coords_lerp,
	coords_round = coords_round,
	display_coord = display_coord,
	rotate_coord = rotate_coord,
	rotation_to_direction = rotation_to_direction,
}
