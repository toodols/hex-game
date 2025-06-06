local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local new_signal = require(ReplicatedStorage.Shared.signal).new_signal
local shared_entity_mod = require(ReplicatedStorage.Shared.entity)
local line_of_sight = require(script.line_of_sight).line_of_sight

local coords_mod = require(script.Parent.coords)
local encode_coord = coords_mod.encode_coord

type CubicCoordinate = types.CubicCoordinate
type Extents = types.Extents
type World = types.World
type HexCell = types.HexCell
type PartialWorld = types.PartialWorld
type Entity = types.Entity
type EntityId = types.EntityId
type EncodedCoordinate = types.EncodedCoordinate
type TeamId = types.TeamId
type TeamColor = types.TeamColor
type TeamData = types.TeamData
type EntityConfiguration = types.EntityConfiguration
type GlobalConfiguration = types.GlobalConfiguration
type WorldUpdate = types.WorldUpdate

-- Filters all values that are inside the world
function coords_filter(world: World, values: { CubicCoordinate }): { CubicCoordinate }
	local results = {}
	for _, v in values do
		local key = encode_coord(v)
		if world.cells[key] then
			table.insert(results, v)
		end
	end
	return results
end

function into_cells(world: World, coords: { CubicCoordinate }): { HexCell }
	local results = {}
	for _, coord in coords do
		local cell = world:get_cell(coord)
		if cell then
			table.insert(results, cell)
		end
	end
	return results
end

function new_team(self: World, players: { Player }?, color: TeamColor?, name: string?)
	table.insert(self.teams, {
		id = #self.teams + 1,
		name = name or "Unnamed Team",
		color = color or { type = "color3", color = Color3.new() },
		players = players or {},
		is_player_team = true,
		is_spectator_team = false,
		server_data = {
			creative = false,
			visibility = "normal",
		},
	})
	table.insert(self.coalitions, {
		name = "Solo Coalition",
		id = #self.coalitions + 1,
		teams = { #self.teams },
	})
	return self.teams[#self.teams]
end

-- Remove entities that are is_destroyed from world.entities to reclaim memory
function purge_destroyed_entities(world: World)
	for entity_id, entity in world.entities do
		if entity.is_destroyed then
			for _, coord in entity.coordinates do
				local cell = world:get_cell(coord)
				cell.entities[entity_id] = nil
			end
			world.entities[entity.id] = nil
			local instance = world.entity_instance_map[entity.id]
			if instance then
				world.instance_entity_map[instance] = nil
			end
			world.entity_instance_map[entity.id] = nil
		end
	end
end

-- Gets a table of entities that fit props
-- Special prop "coordinate" will query only entities that are at the given coordinate.
function world_query_entity(world: World, props: any): { Entity }
	if props.primary_coordinate then
		warn "use of `primary_coordinate` in query_entity! use `coordinate` instead"
	end
	local results = {}
	local function pred(entity: Entity)
		props.is_destroyed = false
		if entity.server_data and entity.active == false or entity.active == false then
			return false
		end
		for k, v in props do
			if k == "coordinate" or k == "query_global" then
				continue
			end
			if not util.deep_equal(entity[k], v) then
				return false
			end
		end
		return true
	end
	if props.coordinate then
		local cell = world:get_cell(props.coordinate)
		if cell == nil then
			return {}
		end
		local entities = cell.entities
		for entity_id in entities do
			if not world.entities[entity_id] then
				error(`{entity_id} not found for {encode_coord(cell.coordinate)}`)
			end
			if pred(world.entities[entity_id]) then
				table.insert(results, world.entities[entity_id])
			end
		end
	else
		if props.query_global then
			for _, entity in world.entities do
				if pred(entity) then
					table.insert(results, entity)
				end
			end
		else
			error "query_entity without coordinate requires explicit .query_global prop"
		end
	end
	return results
end

function world_add_update(self: World, update: WorldUpdate)
	if update.type == "entity_update" then
		if update.entity == nil then
			error "event.entity is nil"
		end
	end
	table.insert(self.updates_buffer, update)
end

function world_get_cell(self: World, coord: CubicCoordinate): HexCell?
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

function world_active_entities(self: World): { [EntityId]: Entity }
	return util.table_filter(self.entities, function(entity)
		if entity.is_destroyed then
			return false
		end
		return entity.active
	end)
	-- return (
	-- 	setmetatable({}, {
	-- 		__iter = function()
	-- 			return next_active_entity, self.entities
	-- 		end,
	-- 	}) :: any
	-- ) :: { [EntityId]: Entity }
end

function new_world_empty(entity_config: { [string]: EntityConfiguration }?, global_config: GlobalConfiguration?): World
	local world: World
	world = {
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
		world_update_signal = new_signal(),
		speed_multiplier = 0.15,
		speed_base = 10,
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
		player_data = {},
		quests = {},
		systems = {},
		active_entities = world_active_entities,
		query_entity = world_query_entity,
		add_update = world_add_update,
		get_cell = world_get_cell,
	}
	-- neutral team
	-- does not impose presence on its neighbors
	-- certain units can be captured by building a vertex on top of it
	world.neutral_team = new_team(world, {}, {
		type = "color3",
		color = Color3.fromRGB(80, 80, 80),
	}, "Neutral").id
	world.teams[world.neutral_team].is_player_team = false
	-- spectator team
	world.spectator_team = new_team(world, {}, {
		type = "color3",
		color = Color3.fromRGB(255, 255, 255),
	}, "Spectator").id
	world.teams[world.spectator_team].is_spectator_team = true
	world.teams[world.spectator_team].server_data.visibility = "perfect"
	world.teams[world.spectator_team].is_player_team = false
	return world
end

function apply_world_data(world: World, data: PartialWorld)
	world.coalitions = data.coalitions
	world.teams = data.teams
	world.conclusion = data.conclusion
	world.turn = data.turn
	world.turn_schedule = data.turn_schedule
	world.highest_turn = data.highest_turn
	world.entities = data.entities
	world.neutral_team = data.neutral_team
	world.spectator_team = data.spectator_team
	world.quests = data.quests
	world.needed_skips = data.needed_skips
	world.current_skips = data.current_skips
	world.cells = data.cells
end

-- creates a complete world from serialized world
function new_world_from_data(data: PartialWorld): World
	local world = new_world_empty(data.entity_configurations, data.global_configuration)
	apply_world_data(world, data)
	return world
end

function empty_cell(coord: CubicCoordinate): HexCell
	return {
		entities = {},
		coordinate = coord,
		type = "basic",
		influences = {},
		server_data = {
			presence = {},
			visibility = {},
		},
	}
end

-- Creates a headless world from extents.
function new_world_from_extents(extents: Extents): World
	local world = new_world_empty()
	for x = extents[1].min, extents[1].max do
		for y = extents[2].min, extents[2].max do
			for z = extents[3].min, extents[3].max do
				if x + y + z == 0 then
					local coord = { x, y, z }
					world.cells[encode_coord(coord)] = empty_cell(coord)
				end
			end
		end
	end
	return world
end

return {
	coords_filter = coords_filter,
	into_cells = into_cells,
	empty_cell = empty_cell,
	new_world_from_extents = new_world_from_extents,
	new_world_from_data = new_world_from_data,
	new_world_empty = new_world_empty,
	apply_world_data = apply_world_data,
	line_of_sight = line_of_sight,
	new_team = new_team,
	purge_destroyed_entities = purge_destroyed_entities,
}
