local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local new_signal = require(ReplicatedStorage.Shared.signal).new_signal
local shared_entity_mod = require(ReplicatedStorage.Shared.entity)
local line_of_sight = require(script.line_of_sight).line_of_sight
local coords_mod = require(script.coords)

local encode_coord = coords_mod.encode_coord
local decode_coord = coords_mod.decode_coord

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
type TeamData = types.TeamData
type EntityConfiguration = types.EntityConfiguration

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

function grid_new_team(self: HexGrid, players: { Player }?, color: TeamColor?, name: string?)
	table.insert(self.teams, {
		id = #self.teams + 1,
		name = name or "Unnamed Team",
		color = color or { type = "color3", color = Color3.new() },
		players = players or {},
		is_player_team = true,
		server_data = {
			creative = false,
			visibility = "normal",
		},
	})
	return self.teams[#self.teams]
end

function grid_purge_dead_entities(self: HexGrid)
	for entity_id, entity in self.entities do
		if entity.is_destroyed then
			self.entities[entity.id] = nil
			local instance = self.entity_instance_map[entity.id]
			if instance then
				self.instance_entity_map[instance] = nil
				self.entity_instance_map[entity.id] = nil
			end
		end
	end
end

function grid_get_allies(self: HexGrid, team: TeamId): { TeamId }
	for _, coalition in self.coalitions do
		if table.find(coalition.teams, team) then
			return coalition.teams
		end
	end
	-- no coalition found, ally is itself
	return { team }
end

function grid_get_player_team(self: HexGrid, player: Player): TeamData
	for _, team in self.teams do
		if table.find(team.players, player) then
			return team
		end
	end
	return self.teams[0]
end

function grid_query_entity(self: HexGrid, props: any): { Entity }
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
		local cell = self:get_cell(props.primary_coordinate)
		if not cell then
			return {}
		end
		local entities = cell.entities
		for entity_id in entities do
			if not self.entities[entity_id] then
				error(`{entity_id} not found for {encode_coord(cell.coordinate)}`)
			end
			if pred(self.entities[entity_id]) then
				table.insert(results, self.entities[entity_id])
			end
		end
	else
		for _, entity in self.entities do
			if pred(entity) then
				table.insert(results, entity)
			end
		end
	end
	return results
end

function grid_get_cell(self: HexGrid, coord: CubicCoordinate): HexCell?
	return self.cells[encode_coord(coord)]
end

function new_grid_empty(config: { [string]: EntityConfiguration }?): HexGrid
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
		grid_update_signal = new_signal(),
		speed_multiplier = 0.15,
		speed_base = 5,
		spectator_visibilities = {},
		updates_buffer = { {} },
		skipped = {},
		current_skips = 0,
		needed_skips = 0,
		neutral_team = nil :: any,
		spectator_team = nil :: any,
		entity_configurations = config or shared_entity_mod.create_configuration(),
		quests = {},
		new_team = grid_new_team,
		purge_dead_entities = grid_purge_dead_entities,
		get_player_team = grid_get_player_team,
		get_allies = grid_get_allies,
		query_entity = grid_query_entity,
		get_cell = grid_get_cell,
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
	}, "Spectator").id
	grid.teams[grid.spectator_team].is_spectator_team = true
	grid.teams[grid.spectator_team].is_player_team = false
	return grid
end

-- hydrates a grid from a serialized grid
function new_grid_from_data(data: PartialHexGrid): HexGrid
	local grid = new_grid_empty(data.entity_configurations)
	grid.coalitions = data.coalitions
	grid.teams = data.teams
	grid.turn = data.turn
	grid.turn_end_time = data.turn_end_time
	grid.turn_start_time = data.turn_start_time
	grid.highest_turn = data.highest_turn
	grid.entities = data.entities
	grid.neutral_team = data.neutral_team
	grid.spectator_team = data.spectator_team
	grid.quests = data.quests
	grid.needed_skips = data.needed_skips
	grid.current_skips = data.current_skips
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
	neighbors_eq = coords_mod.neighbors_eq,
	neighbors_leq = coords_mod.neighbors_leq,
	coords_filter = coords_filter,
	into_cframe = coords_mod.into_cframe,
	empty_cell = empty_cell,
	new_grid_from_extents = new_grid_from_extents,
	new_grid_from_data = new_grid_from_data,
	new_grid_empty = new_grid_empty,
	into_vec3 = coords_mod.into_vec3,
	from_vec3 = coords_mod.from_vec3,
	coords_eq = coords_mod.coords_eq,
	coords_sub = coords_mod.coords_sub,
	coords_add = coords_mod.coords_add,
	encode_coord = encode_coord,
	decode_coord = decode_coord,
	rotation_to_direction = rotation_to_direction,
	coords_dist = coords_mod.coords_dist,
	line_of_sight = line_of_sight,
}
