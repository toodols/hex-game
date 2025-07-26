local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local coords = require(ReplicatedStorage.Shared.coords)
local team_mod = require(ReplicatedStorage.Shared.team)

local server_types = require(script.Parent.types)
local visibility_mod = require(script.Parent.visibility)
local questing = require(script.Parent.questing)
local compute_systems = require(script.Parent.systems.compute_systems).compute_systems
local serialize_entity = require(script.serialize_entity).serialize_entity
local get_cache = require(script.get_cache).get_cache

type Entity = types.Entity
type World = types.World
type TeamId = types.TeamId
type HexCell = types.HexCell
type PartialWorld = types.PartialWorld
type TeamData = types.TeamData
type EntityId = types.EntityId
type System = types.System
type EncodedCoordinate = types.EncodedCoordinate
type Quest = types.Quest

type SerializeFor = server_types.SerializeFor
type SerializationContext = server_types.SerializationContext

-- se_ctx is not used but included for consistency
function buildable_for_team(
	world: World,
	se_ctx: SerializationContext,
	serialize_for: SerializeFor,
	cell: HexCell
): boolean
	local result = false
	for _, coordinate in coords.neighbors_eq(cell.coordinate, 1) do
		local neighbor_cell = world:get_cell(coordinate)
		if neighbor_cell and neighbor_cell.owner == serialize_for.team then
			result = true
		end
	end
	for other_team, value in cell.server_data.presence do
		if value and serialize_for.team ~= other_team then
			result = false
		end
	end
	return result
end

function serialize_team(world: World, team: TeamData): TeamData
	local copy = {}
	for k, v in team do
		if k ~= "server_data" then
			copy[k] = v
		end
	end
	return copy :: TeamData
end

function serialize_cell(
	world: World,
	se_ctx: SerializationContext,
	serialize_for: SerializeFor,
	coord: EncodedCoordinate
): HexCell | nil
	local team_data = if serialize_for.team ~= nil then world.teams[serialize_for.team] else nil

	local cell = world.cells[coord]
	local visible_for_team = if serialize_for.team ~= nil
		then visibility_mod.cell_visibility(cell.server_data.visibility[serialize_for.team])
		else true
	local influences = {}

	for entity_id in cell.influences do
		local entity = world.entities[entity_id]
		-- if this entity is visible, replicate the influence
		if serialize_for.team == nil or visibility_mod.entity_visibility(world, serialize_for, entity) then
			influences[entity_id] = true
		end
	end

	if visible_for_team then
		local entities = {}
		for entity_id in cell.entities do
			local entity = world.entities[entity_id]
			if serialize_for.team == nil or visibility_mod.entity_visibility(world, serialize_for, entity) then
				-- organically add a disguised entity to a serialized cell
				if entity.disguise then
					if
						serialize_for.team == nil
						or team_data.server_data.visibility == "perfect"
						or team_mod.is_allied(world, serialize_for.team, entity.owner)
					then
						entities[entity_id] = true
					else
						entities[entity.disguise] = true
					end
				else
					entities[entity_id] = true
				end
			end
		end
		-- table.sort(entities, function(a, b)
		-- 	return world.entity_configurations[a.type].layer > world.entity_configurations[b.type].layer
		-- end)
		return {
			entities = entities,
			coordinate = cell.coordinate,
			owner = cell.owner,
			type = cell.type,
			visible_for_team = visible_for_team,
			buildable_for_team = buildable_for_team(world, se_ctx, serialize_for, cell),
			influences = influences,
			server_data = nil :: any,
		}
	else
		return {
			entities = util.table_filter(cell.entities, function(_, entity_id)
				local entity = world.entities[entity_id]
				-- if one of its coordinates is visible or it is .server_data.always_visible
				return serialize_for.team == nil
					or entity.server_data.always_visible
					or team_mod.is_allied(world, serialize_for.team, entity.owner)
			end),
			coordinate = cell.coordinate,
			type = cell.type,
			visible_for_team = visible_for_team,
			influences = influences,
			server_data = nil :: any,
		}
	end
end

function serialize_system(
	world: World,
	se_ctx: SerializationContext,
	serialize_for: SerializeFor,
	system: System
): System?
	if serialize_for.team == nil or team_mod.is_allied(world, system.team, serialize_for.team) then
		return system
	end
	return nil
end

function serialize_world(world: World, se_ctx: SerializationContext, serialize_for: SerializeFor): PartialWorld
	local global_cache = get_cache(se_ctx, {})
	if global_cache.systems == nil then
		compute_systems(world)
		global_cache.systems = world.systems
	end

	local entities: { [EntityId]: Entity } = {}
	for entity_id, entity in world.entities do
		local serialized = serialize_entity(world, se_ctx, serialize_for, entity)
		if serialized then
			entities[entity_id] = serialized
		end
	end

	local cache = get_cache(se_ctx, { team = serialize_for.team })
	if cache.systems == nil then
		cache.systems = util.table_filter_map(world.systems, function(system)
			return serialize_system(world, se_ctx, serialize_for, system)
		end)
	end

	if cache.quests == nil then
		cache.quests = util.table_filter_map(world.quests, function(quest)
			return questing.quest_serialize(quest, world)
		end)
	end

	if cache.teams == nil then
		cache.teams = util.table_map(world.teams, function(other_team)
			return serialize_team(world, other_team)
		end)
	end

	if cache.cells == nil then
		cache.cells = util.table_map(world.cells, function(cell, coord)
			return serialize_cell(world, se_ctx, serialize_for, coord)
		end)
	end

	local partial_world: PartialWorld = {
		cells = cache.cells,
		coalitions = world.coalitions,
		teams = cache.teams,
		quests = cache.quests,
		systems = cache.systems,
		turn = world.turn,
		current_skips = world.current_skips,
		needed_skips = world.needed_skips,
		highest_turn = world.highest_turn,
		turn_schedule = world.turn_schedule,
		entities = entities,
		entity_configurations = world.entity_configurations,
		global_configuration = world.global_configuration,
		neutral_team = world.neutral_team,
		spectator_team = world.spectator_team,
		conclusion = world.conclusion,
	}
	return partial_world
end

return {
	serialize_world = serialize_world,
	serialize_cell = serialize_cell,
	serialize_entity = serialize_entity,
	serialize_system = serialize_system,
	buildable_for_team = buildable_for_team,
	serialize_team = serialize_team,
}
