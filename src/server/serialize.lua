local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local visibility_mod = require(script.Parent.visibility)
local coords = require(ReplicatedStorage.Shared.coords)
local quest_methods = require(script.Parent.questing.quest)
local team_mod = require(ReplicatedStorage.Shared.team)

local cell_visibility = visibility_mod.cell_visibility
local entity_visibility = visibility_mod.entity_visibility

type Entity = types.Entity
type World = types.World
type TeamId = types.TeamId
type HexCell = types.HexCell
type PartialWorld = types.PartialWorld
type TeamData = types.TeamData
type EntityId = types.EntityId

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

function serialize_entity_for_team(world: World, entity: Entity, team: TeamId): Entity?
	local team_data = world.teams[team]
	assert(team_data, "no team")
	if entity_visibility(world, entity, team) then
		local to_copy = entity
		local copy = {}
		for k, v in to_copy do
			if k == "server_data" then
			elseif k == "queued_decisions" then
				if team_mod.is_allied(world, entity.owner, team) then
					copy[k] = v
				else
					copy[k] = {}
				end
			else
				copy[k] = v
			end
		end
		if entity.server_data.is_disguise_of then
			local host = world.entities[entity.server_data.is_disguise_of]
			if not team_mod.is_allied(world, host.owner, team) then
				copy.active = true
			end
		end
		return copy :: Entity
	end
	return nil
end

function serialize_cell_for_team(world: World, cell: HexCell, team: TeamId): HexCell | nil
	local team_data = world.teams[team]
	local visible_for_team = cell_visibility(cell.server_data.visibility[team])
	if visible_for_team then
		local influences = {}
		for entity_id in cell.server_data.influences do
			local entity = world.entities[entity_id]
			if entity.owner == team then
				influences[entity_id] = true
			end
		end
		local entities = {}
		for entity_id in cell.entities do
			local entity = world.entities[entity_id]
			if entity.owner == team or entity.status ~= "blueprint" then
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
			influences = {},
			server_data = nil :: any,
		}
	end
end
function serialize_world_for_team(world: World, team: TeamId): PartialWorld
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
			return quest_methods.quest_serialize(quest, world)
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
