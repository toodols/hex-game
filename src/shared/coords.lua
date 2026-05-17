local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)

type CubicCoordinate = types.CubicCoordinate
type EncodedCoordinate = types.EncodedCoordinate

local rotation_to_direction = {
	[1] = { 0, 1, -1 },
	[2] = { 1, 0, -1 },
	[3] = { 1, -1, 0 },
	[4] = { 0, -1, 1 },
	[5] = { -1, 0, 1 },
	[0] = { -1, 1, 0 },
}

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

function sector(origin: CubicCoordinate, rotation: number, radius: number): { CubicCoordinate }
	local d1 = rotation_to_direction[rotation % 6]
	local d2 = rotation_to_direction[(rotation + 1) % 6]
	local results = {}

	for i = 0, radius do
		for j = 0, radius - i do
			local x = origin[1] + d1[1] * i + d2[1] * j
			local y = origin[2] + d1[2] * i + d2[2] * j
			local z = origin[3] + d1[3] * i + d2[3] * j
			table.insert(results, { x, y, z })
		end
	end

	return results
end

--- Rotates a CubicCoordinate around the origin counterclockwise 60 degrees `rotation` times
function rotate_coord(coord: CubicCoordinate, rotation: number): CubicCoordinate
	local x, y, z = coord[1], coord[2], coord[3]
	local rot = rotation % 6
	if rot == 0 then
		return coord
	elseif rot == 1 then
		return { -z, -x, -y }
	elseif rot == 2 then
		return { y, z, x }
	elseif rot == 3 then
		return { -x, -y, -z }
	elseif rot == 4 then
		return { z, x, y }
	else
		return { -y, -z, -x }
	end
end

--- Encodes a CubicCoordinate into a string
--- Makes no guarantees on the output format, only that
--- - `forall coord: CubicCoordinate. coord == decode_coord(encode_coord(coord))`
---

local BITS_PER_COMPONENT = 21
local UNSIGNED_MAX = 2 ^ BITS_PER_COMPONENT
local SIGNED_MAX = UNSIGNED_MAX / 2
function encode_coord(coord: CubicCoordinate): EncodedCoordinate
	return (coord[1] + SIGNED_MAX) * UNSIGNED_MAX + coord[2] + SIGNED_MAX
end

--  Decodes a string back into a CubicCoordinate
function decode_coord(s: EncodedCoordinate): CubicCoordinate
	local decode_y = (s % UNSIGNED_MAX) - SIGNED_MAX
	local decode_x = math.floor(s / UNSIGNED_MAX) - SIGNED_MAX
	return { decode_x, decode_y, -decode_x - decode_y }
end

function display_coord(coord: CubicCoordinate): string
	return string.format("(%d, %d, %d)", coord[1], coord[2], coord[3])
end

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

function into_set(coords: { CubicCoordinate }): { [EncodedCoordinate]: boolean }
	local set = {}
	for _, coord in coords do
		set[encode_coord(coord)] = true
	end
	return set
end

function from_set(set: { [EncodedCoordinate]: boolean }): { CubicCoordinate }
	local result = {}
	for coord in set do
		table.insert(result, decode_coord(coord))
	end
	return result
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

function fit(src: { CubicCoordinate }, target: { CubicCoordinate }): { [number]: CubicCoordinate }
	local results = {}

	local target_set = into_set(target)
	for rot = 1, 6 do
		local rotated = util.table_map(src, rotate_coord)
		-- choose the first coordinate in rotated to be the 'origin'
		local src_origin = rotated[1]

		for _, target_origin in target do
			for _, coord in rotated do
				-- (target_origin - src_origin) + coord = target_coord
				local translation = coords_sub(target_origin, src_origin)
				local target_coord = coords_add(translation, coord)
				if target_set[encode_coord(target_coord)] then
					results[rot] = translation
				end
			end
		end
	end

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
	sector = sector,
	into_set = into_set,
	from_set = from_set,
	rotation_to_direction = rotation_to_direction,
}
