local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local effective_visibility = require(ReplicatedStorage.Shared.effective_visibility).effective_visibility
local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)

type Entity = types.Entity
type HexGrid = types.HexGrid
type TeamId = types.TeamId
type HexCell = types.HexCell
type PartialHexGrid = types.PartialHexGrid
type TeamData = types.TeamData
type EntityId = types.EntityId

function buildable_for_team(grid: HexGrid, cell: HexCell, team: TeamId): boolean
	local result = false
	for _, coordinate in hex_grid_mod.neighbors_eq(cell.coordinate, 1) do
		local neighbor_cell = grid:get_cell(coordinate)
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
function serialize_team(grid: HexGrid, team: TeamData): TeamData
	local copy = {}
	for k, v in team do
		if k ~= "server_data" then
			copy[k] = v
		end
	end
	return copy :: TeamData
end
function serialize_entity_for_team(grid: HexGrid, entity: Entity, team: TeamId): Entity?
	local cell = grid:get_cell(entity.primary_coordinate)
	local visible_for_team = effective_visibility(cell.server_data.visibility[team])
		or entity.server_data.always_visible
	if visible_for_team and (entity.owner == team or entity.status ~= "blueprint") then
		local copy = {}
		for k, v in entity do
			if k == "server_data" then
			elseif k == "queued_decisions" and cell.owner ~= team then
				copy[k] = {}
			else
				copy[k] = v
			end
		end
		return copy :: Entity
	end
	return nil
end

function serialize_cell_for_team(grid: HexGrid, cell: HexCell, team: TeamId): HexCell | nil
	local visible_for_team = effective_visibility(cell.server_data.visibility[team])
	if visible_for_team then
		local influences = {}
		for entity_id in cell.server_data.influences do
			local entity = grid.entities[entity_id]
			if entity.owner == team then
				influences[entity_id] = true
			end
		end
		return {
			entities = util.table_filter(cell.entities, function(_, entity_id)
				local entity = grid.entities[entity_id]
				return entity.owner == team or entity.status ~= "blueprint"
			end),
			coordinate = cell.coordinate,
			owner = cell.owner,
			type = cell.type,
			visible_for_team = visible_for_team,
			buildable_for_team = buildable_for_team(grid, cell, team),
			influences = influences,
			server_data = nil :: any,
		}
	else
		return {
			entities = util.table_filter(cell.entities, function(_, entity_id)
				local entity = grid.entities[entity_id]
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
function serialize_grid_for_team(grid: HexGrid, team: TeamId): PartialHexGrid
	local entities: { [EntityId]: Entity } = {}
	for entity_id, entity in grid.entities do
		local serialized = serialize_entity_for_team(grid, entity, team)
		if serialized then
			entities[entity_id] = serialized
		end
	end

	local partial_grid: PartialHexGrid = {
		cells = util.table_map(grid.cells, function(cell)
			return serialize_cell_for_team(grid, cell, team)
		end),
		coalitions = grid.coalitions,
		teams = util.table_map(grid.teams, function(other_team)
			return serialize_team(grid, other_team)
		end),
		quests = util.table_map(grid.quests, function(quest)
			return {
				id = quest.id,
				current_stage = quest.current_stage,
				details = quest.details,
				stages_data = quest.stages_data,
				title = quest.title,
			}
		end),
		turn = grid.turn,
		current_skips = grid.current_skips,
		needed_skips = grid.needed_skips,
		highest_turn = grid.highest_turn,
		turn_schedule = grid.turn_schedule,
		entities = entities,
		entity_configurations = grid.entity_configurations,
		global_configuration = grid.global_configuration,
		neutral_team = grid.neutral_team,
		spectator_team = grid.spectator_team,
	}
	return partial_grid
end

return {
	serialize_grid_for_team = serialize_grid_for_team,
	serialize_cell_for_team = serialize_cell_for_team,
	serialize_entity_for_team = serialize_entity_for_team,
	buildable_for_team = buildable_for_team,
	serialize_team = serialize_team,
}
