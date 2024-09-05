local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local new_signal = require(ReplicatedStorage.Shared.signal).new_signal
local line_of_sight = require(script.line_of_sight).line_of_sight
local coords_mod = require(script.coords)
local encode_coord = coords_mod.encode_coord
local decode_coord = coords_mod.decode_coord
local coords_sub = coords_mod.coords_sub
local coords_eq = coords_mod.coords_eq
local neighbors_leq = coords_mod.neighbors_leq
local neighbors_eq = coords_mod.neighbors_eq
local coords_add = coords_mod.coords_add
local coords_dist = coords_mod.coords_dist

type CubicCoordinate = types.CubicCoordinate
type Extents = types.Extents
type HexGrid = types.HexGrid
type HexCell = types.HexCell
type PartialHexGrid = types.PartialHexGrid
type Entity = types.Entity
type EntityId = types.EntityId
type EncodedCoordinate = types.EncodedCoordinate
type TeamId = types.TeamId
type TeamColor = types.TeamColor

-- Filters all values that are inside the grid
function coords_filter(grid: HexGrid, values: { CubicCoordinate }): { CubicCoordinate }
	local results = {}
	for _, v in values do
		local key = encode_coord(v)
		if grid.cells[key] then
			table.insert(results, v)
		end
	end
	return results
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
	return 0 :: CubicCoordinate
end

function new_grid_empty(): HexGrid
	local grid: HexGrid
	grid = {
		cells = {},
		coalitions = {},
		teams = {},
		cell_instance_map = {},
		turn = 1,
		highest_turn = 1,
		turn_start_time = 0,
		turn_end_time = 0,
		entities = {},
		instance_cell_map = {},
		instance_entity_map = {},
		systems = {},
		entity_instance_map = {},
		new_team = function(self, players, color, name)
			table.insert(grid.teams, {
				id = #grid.teams + 1,
				name = name or "Unnamed Team",
				color = color or { type = "color3", color = Color3.new() },
				players = players or {},
				is_player_team = true,
				server_data = {
					creative = false,
					visibility = "normal",
				},
			})
			return grid.teams[#grid.teams]
		end,
		purge_dead_entities = function(self)
			for entity_id, entity in self.entities do
				if entity.is_destroyed then
					grid.entities[entity.id] = nil
					local instance = grid.entity_instance_map[entity.id]
					if instance then
						grid.instance_entity_map[instance] = nil
						grid.entity_instance_map[entity.id] = nil
					end
				end
			end
		end,
		grid_update_signal = new_signal(),
		get_player_team = function(self, player: Player)
			for _, team in self.teams do
				if table.find(team.players, player) then
					return team
				end
			end
			return self.teams[0]
		end,
		get_allies = function(self, team: TeamId): { TeamId }
			for _, coalition in self.coalitions do
				if table.find(coalition.teams, team) then
					return coalition.teams
				end
			end
			-- no coalition found, ally is itself
			return { team }
		end,
		query_entity = function(self, props: table): { Entity }
			local results = {}
			local function pred(entity: Entity)
				props.is_destroyed = false
				for k, v in props do
					if not util.deep_equal(entity[k], v) then
						return false
					end
				end
				return true
			end
			if props.primary_coordinate then
				local cell = grid:get_cell(props.primary_coordinate)
				if not cell then
					return {}
				end
				local entities = cell.entities
				for _, entity_id in entities do
					if not grid.entities[entity_id] then
						error(`{entity_id} not found for {encode_coord(cell.coordinate)}`)
					end
					if pred(grid.entities[entity_id]) then
						table.insert(results, grid.entities[entity_id])
					end
				end
			else
				for _, entity in grid.entities do
					if pred(entity) then
						table.insert(results, entity)
					end
				end
			end
			return results
		end,
		get_cell = function(self, coordinate: CubicCoordinate): HexCell?
			return self.cells[encode_coord(coordinate)]
		end,
		speed_multiplier = 0.15,
		speed_base = 5,
		spectator_visibilities = {},
		updates_buffer = { {} },
		skipped = {},
		current_skips = 0,
		needed_skips = 0,
	}
	-- neutral team
	-- does not impose presence on its neighbors
	-- certain units can be captured by building a wire on top of it
	grid.neutral_team = grid:new_team({}, {
		type = "color3",
		color = Color3.fromRGB(150, 150, 150),
	}, "Neutral").id
	grid.teams[grid.neutral_team].is_player_team = false
	-- spectator team
	grid.spectator_team = grid:new_team({}, {
		type = "color3",
		color = Color3.fromRGB(255, 255, 255),
	}).id
	grid.teams[grid.spectator_team].name = "Spectator"
	grid.teams[grid.spectator_team].is_spectator_team = true
	grid.teams[grid.spectator_team].is_player_team = false
	return grid
end

-- hydrates a grid from a serialized grid
function new_grid_from_data(data: PartialHexGrid): HexGrid
	local grid = new_grid_empty()
	grid.coalitions = data.coalitions
	grid.teams = data.teams
	grid.turn = data.turn
	grid.turn_end_time = data.turn_end_time
	grid.turn_start_time = data.turn_start_time
	grid.highest_turn = data.highest_turn
	grid.entities = data.entities
	for cell_coords_encoded, cell in data.cells do
		grid.cells[cell_coords_encoded] = cell
	end
	return grid
end

function empty_cell(coord: CubicCoordinate): HexCell
	return {
		entities = {},
		coordinate = coord,
		type = "basic",
		server_data = {
			presence = {},
			visibility = {},
			influences = {},
		},
	}
end

-- Creates a headless grid from extents.
function new_grid_from_extents(extents: Extents): HexGrid
	local grid = new_grid_empty()
	for x = extents[1].min, extents[1].max do
		for y = extents[2].min, extents[2].max do
			for z = extents[3].min, extents[3].max do
				if x + y + z == 0 then
					local coord = { x, y, z }
					grid.cells[encode_coord(coord)] = empty_cell(coord)
				end
			end
		end
	end
	return grid
end

local rotation_to_direction = {
	[1] = { 0, 1, -1 },
	[2] = { 1, 0, -1 },
	[3] = { 1, -1, 0 },
	[4] = { 0, -1, 1 },
	[5] = { -1, 0, 1 },
	[0] = { -1, 1, 0 },
}
return {
	neighbors_eq = neighbors_eq,
	neighbors_leq = neighbors_leq,
	coords_filter = coords_filter,
	into_cframe = into_cframe,
	empty_cell = empty_cell,
	new_grid_from_extents = new_grid_from_extents,
	new_grid_from_data = new_grid_from_data,
	new_grid_empty = new_grid_empty,
	into_vec3 = into_vec3,
	from_vec3 = from_vec3,
	coords_eq = coords_eq,
	coords_sub = coords_sub,
	coords_add = coords_add,
	encode_coord = encode_coord,
	decode_coord = decode_coord,
	rotation_to_direction = rotation_to_direction,
	coords_dist = coords_dist,
	line_of_sight = line_of_sight,
}
