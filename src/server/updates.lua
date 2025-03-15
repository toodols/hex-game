local ReplicatedStorage = game:GetService "ReplicatedStorage"
local util = require(ReplicatedStorage.Shared.util)
local types = require(ReplicatedStorage.Shared.types)
local serialize_mod = require(script.Parent.serialize)
local remotes_mod = require(script.Parent.remotes)

type HexGrid = types.HexGrid
type GridUpdate = types.GridUpdate
type EntityId = types.EntityId
type TeamId = types.TeamId

-- Removes all but the last "entity_update" for each entity_id from a list of updates.
function filter_duplicate_entity_updates(updates)
	local last_occurrences: { [EntityId]: number } = {}
	local result = {}
	for i, update in updates do
		if update.type == "entity_update" then
			last_occurrences[update.entity.id] = i
		end
	end

	for i, update in updates do
		if update.type ~= "entity_update" or last_occurrences[update.entity.id] == i then
			table.insert(result, update)
		end
	end

	return result
end

function flush_updates(grid: HexGrid)
	local buffer = grid.updates_buffer
	if #buffer > 0 then
		for _, team in grid.teams do
			if #team.players == 0 then
				continue
			end
			local mapped = filter_duplicate_entity_updates(util.table_filter_map(buffer, function(update: GridUpdate)
				local target = (update :: any).target or "everyone"
				if
					team.server_data.visibility ~= "perfect"
					and target ~= "everyone"
					and table.find(target, team.id) == nil
				then
					return
				end
				if update.type == "entity_update" then
					local serialized = serialize_mod.serialize_entity_for_team(grid, update.entity, team.id)
					return serialized and {
						type = update.type,
						entity = serialized,
					}
				elseif update.type == "cell_update" then
					local serialized = serialize_mod.serialize_cell_for_team(grid, update.cell, team.id)
					return serialized and {
						type = update.type,
						entity = serialized,
					}
				elseif update.type == "ability" then
					local hit_cell = grid:get_cell(update.coordinate)
					local entity = grid.entities[update.entity_id]
					if hit_cell.owner == team.id or entity.owner == team.id then
						return {
							type = update.type,
							entity_id = update.entity_id,
							ability_type = update.ability_type,
							coordinate = update.coordinate,
						}
					end
					return nil
				elseif update.type == "cells" then
					return {
						type = update.type,
						cells = util.table_map(update.cells, function(cell)
							return serialize_mod.serialize_cell_for_team(grid, cell, team.id)
						end),
					}
				else
					return update
				end
			end))
			if #mapped > 0 then
				for _, player in team.players do
					remotes_mod.grid_updates_remote:FireClient(player, mapped)
				end
			end
		end
	end
	grid.updates_buffer = {}
end

function add_update(grid: HexGrid, event: GridUpdate)
	if event.type == "entity_update" then
		if event.entity == nil then
			error "event.entity is nil"
		end
	end
	table.insert(grid.updates_buffer, event)
end

return {
	flush_updates = flush_updates,
	add_update = add_update,
}
