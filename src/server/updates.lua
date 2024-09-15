local ReplicatedStorage = game:GetService "ReplicatedStorage"
local util = require(ReplicatedStorage.Shared.util)
local types = require(ReplicatedStorage.Shared.types)
local serialize_mod = require(script.Parent.serialize)
local remotes_mod = require(script.Parent.remotes)

type HexGrid = types.HexGrid
type GridUpdate = types.GridUpdate

function flush_updates(grid: HexGrid)
	local buffer = grid.updates_buffer[#grid.updates_buffer]
	if #buffer > 0 then
		for _, team in grid.teams do
			if #team.players == 0 then
				continue
			end
			local mapped = util.table_filter_map(buffer, function(update: GridUpdate)
				local target = (update :: any).target or "everyone"
				if
					team.server_data.visibility ~= "full"
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
			end)

			if #mapped > 0 then
				for _, player in team.players do
					remotes_mod.grid_updates_remote:FireClient(player, mapped)
				end
			end
		end
	end
	grid.updates_buffer[#grid.updates_buffer] = {}
end

-- allows unwanted events to be discarded
function push_buffer(grid: HexGrid)
	table.insert(grid.updates_buffer, {})
end
function pop_buffer(grid: HexGrid)
	grid.updates_buffer[#grid.updates_buffer] = nil
end

return {
	flush_updates = flush_updates,
	push_buffer = push_buffer,
	pop_buffer = pop_buffer,
}
