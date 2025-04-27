local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local visibility_mod = require(script.Parent.visibility)
local coords = require(ReplicatedStorage.Shared.coords)
local questing = require(script.Parent.questing)
local team_mod = require(ReplicatedStorage.Shared.team)
local compute_systems = require(script.Parent.systems.compute_systems).compute_systems
local serialize_entity_for_team = require(script.serialize_entity).serialize_entity_for_team

type Entity = types.Entity
type World = types.World
type TeamId = types.TeamId
type HexCell = types.HexCell
type PartialWorld = types.PartialWorld
type TeamData = types.TeamData
type EntityId = types.EntityId
type System = types.System

function buildable_for_team(world: World, cell: HexCell, team: TeamId): boolean
	local result = false
	for _, coordinate in coords.neighbors_eq(cell.coordinate, 1) do
		local neighbor_cell = world:get_cell(coordinate)
		if neighbor_cell and neighbor_cell.owner == team then
			result = true
		end
	end
	for other_team, value in cell.server_data.presence do
		if value and team ~= other_team then
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

function serialize_cell_for_team(world: World, cell: HexCell, team: TeamId): HexCell | nil
	local team_data = world.teams[team]
	local visible_for_team = visibility_mod.cell_visibility(cell.server_data.visibility[team])
	local influences = {}

	for entity_id in cell.influences do
		local entity = world.entities[entity_id]
		-- if this entity is visible, replicate the influence
		if visibility_mod.entity_visibility(world, entity, team) then
			influences[entity_id] = true
		end
	end

	if visible_for_team then
		local entities = {}
		for entity_id in cell.entities do
			local entity = world.entities[entity_id]
			if team_mod.is_allied(world, entity.owner, team) or entity.status ~= "blueprint" then
				if entity.disguise then
					if
						team_data.server_data.visibility == "perfect" or team_mod.is_allied(world, team, entity.owner)
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
			buildable_for_team = buildable_for_team(world, cell, team),
			influences = influences,
			server_data = nil :: any,
		}
	else
		return {
			entities = util.table_filter(cell.entities, function(_, entity_id)
				local entity = world.entities[entity_id]
				-- if one of its coordinates is visible or it is .server_data.always_visible
				return entity.server_data.always_visible
			end),
			coordinate = cell.coordinate,
			type = cell.type,
			visible_for_team = visible_for_team,
			influences = influences,
			server_data = nil :: any,
		}
	end
end

function serialize_system_for_team(world: World, system: System, team: TeamId): System?
	return nil
end

function serialize_world_for_team(world: World, team: TeamId): PartialWorld
	world.systems = compute_systems(world)
	local entities: { [EntityId]: Entity } = {}
	for entity_id, entity in world.entities do
		local serialized = serialize_entity_for_team(world, entity, team)
		if serialized then
			entities[entity_id] = serialized
		end
	end

	local partial_world: PartialWorld = {
		cells = util.table_map(world.cells, function(cell)
			return serialize_cell_for_team(world, cell, team)
		end),
		coalitions = world.coalitions,
		teams = util.table_map(world.teams, function(other_team)
			return serialize_team(world, other_team)
		end),
		quests = util.table_map(world.quests, function(quest)
			return questing.quest_serialize(quest, world)
		end),
		systems = util.table_filter_map(world.systems, function(system)
			return serialize_system_for_team(world, system, team)
		end),
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
	}
	return partial_world
end

return {
	serialize_world_for_team = serialize_world_for_team,
	serialize_cell_for_team = serialize_cell_for_team,
	serialize_entity_for_team = serialize_entity_for_team,
	buildable_for_team = buildable_for_team,
	serialize_team = serialize_team,
}
