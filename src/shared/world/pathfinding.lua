local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local coords = require(ReplicatedStorage.Shared.coords)
local util = require(ReplicatedStorage.Shared.util)
local entity_mod = require(ReplicatedStorage.Shared.entity)
local team_mod = require(ReplicatedStorage.Shared.team)

type World = types.World
type CubicCoordinate = types.CubicCoordinate
type EncodedCoordinate = types.EncodedCoordinate
type TeamId = types.TeamId
type HexCell = types.HexCell

function cell_is_open(world: World, cell: HexCell?, team: TeamId): boolean
	if not cell then
		return false
	end
	if cell.server_data then
		for presence_team in cell.server_data.presence do
			if not team_mod.is_allied(world, team, presence_team) then
				return false
			end
		end
	end

	for entity_id in cell.entities do
		local entity = world.entities[entity_id]
		local config = world.entity_configurations[entity.type]
		if not team_mod.is_allied(world, team, entity.owner) and config.layer == entity_mod.LAYER.building then
			return false
		end
	end
	return true
end

function astar(world: World, start: CubicCoordinate, goal: CubicCoordinate, team: TeamId): { CubicCoordinate }?
	local encode_coord = coords.encode_coord
	local open: { CubicCoordinate } = { start }
	local open_set: { [EncodedCoordinate]: true } = { [encode_coord(start)] = true }
	local from: { [EncodedCoordinate]: CubicCoordinate } = {}

	local gscore_map: { [EncodedCoordinate]: number } = { [encode_coord(start)] = 0 }
	local fscore_map: { [EncodedCoordinate]: number } = {}
	while #open > 0 do
		local current
		local current_i
		for i, v in open do
			if
				not current
				or (fscore_map[encode_coord(v)] or math.huge) < (fscore_map[encode_coord(current)] or math.huge)
			then
				current = v
				current_i = i
			end
		end
		table.remove(open, current_i)
		open_set[current] = nil
		local current_key = encode_coord(current)

		if coords.coords_eq(current, goal) then
			local path = {}
			while current do
				table.insert(path, current)
				current = from[encode_coord(current)]
			end
			return util.table_reverse(path)
		end

		for _, neighbor in coords.neighbors_eq(current, 1) do
			local cell = world:get_cell(neighbor)
			if not cell_is_open(world, cell, team) then
				continue
			end

			local gscore = gscore_map[current_key] + 1
			local neighbor_key = encode_coord(neighbor)
			if gscore < (gscore_map[neighbor_key] or math.huge) then
				gscore_map[neighbor_key] = gscore
				from[neighbor_key] = current
				fscore_map[neighbor_key] = gscore + coords.coords_dist(neighbor, goal)
				if not open_set[neighbor_key] then
					table.insert(open, neighbor)
					open_set[neighbor_key] = true
				end
			end
		end
	end
	return nil
end

-- Performs a bfs flood search limited by depth for open cells for a given team
function bfs(world: World, start: CubicCoordinate, max_depth: number, team: TeamId): { CubicCoordinate }
	local encode_coord = coords.encode_coord
	local visited = { [encode_coord(start)] = true }
	local stack = { start }
	local depth = 0
	local result = {}

	while #stack > 0 and depth <= max_depth do
		local new_stack = {}
		for _, current in stack do
			table.insert(result, current)
			for _, neighbor in coords.neighbors_eq(current, 1) do
				local cell = world:get_cell(neighbor)

				if cell_is_open(world, cell, team) and not visited[encode_coord(neighbor)] then
					table.insert(new_stack, neighbor)
					visited[encode_coord(current)] = true
				end
			end
		end
		stack = new_stack
		depth += 1
	end
	return result
end

return { astar = astar, bfs = bfs }
