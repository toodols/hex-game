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
type GlobalConfiguration = types.GlobalConfiguration

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

-- Remove entities that are is_destroyed from grid.entities to reclaim memory
function grid_purge_dead_entities(grid: HexGrid)
	for entity_id, entity in grid.entities do
		if entity.is_destroyed then
			grid.entities[entity.id] = nil
			local instance = grid.entity_instance_map[entity.id]
			if instance then
				grid.instance_entity_map[instance] = nil
				grid.entity_instance_map[entity.id] = nil
			end
		end
	end
end

-- Gets a table of entities that fit props
-- Special prop "coordinate" will query only entities that are at the given coordinate.
function grid_query_entity(grid: HexGrid, props: any): { Entity }
	if props.primary_coordinate then
		warn "use of `primary_coordinate` in query_entity! use `coordinate` instead"
	end
	local results = {}
	local function pred(entity: Entity)
		props.is_destroyed = false
		if entity.server_data and entity.server_data.active == false or entity.active == false then
			return false
		end
		for k, v in props do
			if k == "coordinate" then
				continue
			end
			if not util.deep_equal(entity[k], v) then
				return false
			end
		end
		return true
	end
	if props.coordinate then
		local cell = grid:get_cell(props.coordinate)
		if not cell then
			return {}
		end
		local entities = cell.entities
		for entity_id in entities do
			if not grid.entities[entity_id] then
				error(`{entity_id} not found for {encode_coord(cell.coordinate)}`)
			end
			if pred(grid.entities[entity_id]) then
				table.insert(results, grid.entities[entity_id])
			end
		end
	else
		warn "query_entity without coordinate is bad"
		warn(debug.traceback())
		for _, entity in grid.entities do
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

-- Turns out using luau's iterators is actually like 50% slower than creating a new table even for 100k elements
-- Very sad
-- function next_active_entity(entities: { [EntityId]: Entity }, k: EntityId?)
-- 	local v
-- 	k, v = next(entities, k)
-- 	while k do
-- 		if v.active then
-- 			return k, v
-- 		end
-- 		k, v = next(entities, k)
-- 	end
-- 	return nil
-- end

function grid_active_entities(self: HexGrid): { [EntityId]: Entity }
	return util.table_filter(self.entities, function(entity)
		if entity.server_data then
			return entity.server_data.active
		else
			return entity.active ~= false
		end
	end)
	-- return (
	-- 	setmetatable({}, {
	-- 		__iter = function()
	-- 			return next_active_entity, self.entities
	-- 		end,
	-- 	}) :: any
	-- ) :: { [EntityId]: Entity }
end

function new_grid_empty(entity_config: { [string]: EntityConfiguration }?, global_config: GlobalConfiguration?): HexGrid
	local grid: HexGrid
	grid = {
		cells = {},
		coalitions = {},
		teams = {},
		cell_instance_map = {},
		turn = 1,
		highest_turn = 1,
		entities = {},
		instance_cell_map = {},
		instance_entity_map = {},
		entity_instance_map = {},
		grid_update_signal = new_signal(),
		speed_multiplier = 0.15,
		speed_base = 5,
		spectator_visibilities = {},
		updates_buffer = {},
		action_queue = {},
		skipped = {},
		current_skips = 0,
		needed_skips = 0,
		neutral_team = nil :: any,
		spectator_team = nil :: any,
		entity_configurations = entity_config or shared_entity_mod.create_configuration(),
		global_configuration = global_config or {
			decaying_enabled = true,
		},
		quests = {},
		active_entities = grid_active_entities,
		new_team = grid_new_team,
		purge_dead_entities = grid_purge_dead_entities,
		query_entity = grid_query_entity,
		get_cell = grid_get_cell,
	}
	-- neutral team
	-- does not impose presence on its neighbors
	-- certain units can be captured by building a vertex on top of it
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
	local grid = new_grid_empty(data.entity_configurations, data.global_configuration)
	grid.coalitions = data.coalitions
	grid.teams = data.teams
	grid.turn = data.turn
	grid.turn_schedule = data.turn_schedule
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

return {
	neighbors_eq = coords_mod.neighbors_eq,
	neighbors_leq = coords_mod.neighbors_leq,
	neighbors_many_leq = coords_mod.neighbors_many_leq,
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
	rotation_to_direction = coords_mod.rotation_to_direction,
	coords_dist = coords_mod.coords_dist,
	line_of_sight = line_of_sight,
}
