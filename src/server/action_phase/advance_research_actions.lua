local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)
local publish_event = require(ServerScriptService.Server.event).publish_event
local server_util = require(ServerScriptService.Server.util)

local util = require(ReplicatedStorage.Shared.util)
local systems_mod = require(ServerScriptService.Server.systems)
local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)

type HexGrid = types.HexGrid
type System = server_types.System
type ActionState = server_types.ActionState
type EntityAction = server_types.EntityAction

function handle_advance_research_actions(grid: HexGrid, action_state: ActionState, system: System)
	local advance_research_actions: { EntityAction } = util.table_extract(action_state.queue, function(action)
		return action.type == "advance_research"
			and table.find(util.table_keys(system.entities), action.entity_id) ~= nil
	end)
	for _, action in advance_research_actions do
		local entity = grid.entities[action.entity_id]
		if not entity or entity.is_destroyed then
			error "advance_research error"
		end

		for _, research_id in entity.researches.queue do
			local research_state = entity.researches.states[research_id]
			if not research_state.cost_is_paid then
				if not systems_mod.system_has_items(grid, action_state, system, research_state.cost) then
					break
				end

				for item_type, amount in research_state.cost do
					systems_mod.system_consume_item_type(grid, action_state, system, item_type, amount)
				end

				publish_event(grid, {
					type = "consumed_items",
					items = research_state.cost,
					entity_id = entity.id,
				}, hex_grid_mod.neighbors_leq(entity.primary_coordinate, 1))

				research_state.cost_is_paid = true
				server_util.mark_dirty_for_everyone(action_state, entity.id)
			else
				research_state.progress += 1
				server_util.mark_dirty_for_everyone(action_state, entity.id)
			end

			if research_state.progress == research_state.time then
				research_state.status = "complete"
				server_util.mark_dirty_for_everyone(action_state, entity.id)
				publish_event(grid, {
					type = "research_completed",
					entity_id = entity.id,
					research_id = research_id,
				}, hex_grid_mod.neighbors_leq(entity.primary_coordinate, 1))
			else
				break
			end
		end
		local _finished = util.table_extract(entity.researches.queue, function(research_id)
			return entity.researches.states[research_id].status == "complete"
		end)
	end
end

return {
	handle_advance_research_actions = handle_advance_research_actions,
}
