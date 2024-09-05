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

function encode_coord(coord: CubicCoordinate): EncodedCoordinate
	return table.concat(coord, ",")
end

-- Helper function: Decodes a string back into a CubicCoordinate
function decode_coord(s: EncodedCoordinate): CubicCoordinate
	return util.table_map(s:split ",", tonumber :: any)
end

-- returns neighbors at a radius. can give neighbors that are out of bounds
function neighbors_eq(center: CubicCoordinate, radius: number)
	local directions = {
		{ 1, -1, 0 },
		{ 1, 0, -1 },
		{ 0, 1, -1 },
		{ -1, 1, 0 },
		{ -1, 0, 1 },
		{ 0, -1, 1 },
	}
	local result = {}
	if radius == 0 then
		table.insert(result, center)
	else
		for _, dir in directions do
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

function coords_dist(c1: CubicCoordinate, c2: CubicCoordinate): number
	return math.max(math.abs(c1[1] - c2[1]), math.abs(c1[2] - c2[2]), math.abs(c1[3] - c2[3]))
end

return {
	coords_eq = coords_eq,
	coords_sub = coords_sub,
	coords_add = coords_add,
	decode_coord = decode_coord,
	encode_coord = encode_coord,
	neighbors_eq = neighbors_eq,
	neighbors_leq = neighbors_leq,
	coords_dist = coords_dist,
}
