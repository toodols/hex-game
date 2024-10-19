local ServerScriptService = game:GetService "ServerScriptService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local server_types = require(ServerScriptService.Server.types)
local server_entity_mod = require(ServerScriptService.Server.entity)
local updates_mod = require(ServerScriptService.Server.updates)

local types = require(ReplicatedStorage.Shared.types)
local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)
local util = require(ReplicatedStorage.Shared.util)

type HexGrid = types.HexGrid
type ActionState = server_types.ActionState

function handle_entity_event_actions(grid: HexGrid, action_state: ActionState)
	for _, event in
		util.table_extract(grid.action_queue, function(action)
			return action.type == "entity_event"
		end)
	do
		local source_entity = grid.entities[event.entity_id]
		assert(source_entity ~= nil, "no source entity")
		local coords = hex_grid_mod.neighbors_many_leq(source_entity.coordinates, 1)
		for _, coord in coords do
			local cell = grid:get_cell(coord)
			if not cell then
				continue
			end
			for entity_id in cell.entities do
				-- don't send event to self
				if entity_id == event.entity_id then
					continue
				end
				local entity = grid.entities[entity_id]
				local behavior = server_entity_mod.registry[entity.type]
				if behavior.on_event then
					behavior.on_event(entity, grid, event, action_state)
				end
			end
		end
		updates_mod.add_update(grid, {
			type = "entity_event",
			event = event,
		})
	end
end

return {
	handle_entity_event_actions = handle_entity_event_actions,
}
