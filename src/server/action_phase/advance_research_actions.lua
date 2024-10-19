local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)
local updates_mod = require(ServerScriptService.Server.updates)

local util = require(ReplicatedStorage.Shared.util)
local systems_mod = require(ServerScriptService.Server.systems)

type HexGrid = types.HexGrid
type System = server_types.System
type ActionState = server_types.ActionState
type EntityAction = types.EntityAction

function handle_advance_research_actions(grid: HexGrid, action_state: ActionState)
	local advance_research_actions: { EntityAction } = util.table_extract(grid.action_queue, function(action)
		return action.type == "advance_research"
	end)
	for _, action in advance_research_actions do
		local entity = grid.entities[action.entity_id]
		local system = action_state.system_by_entity_id[action.entity_id]
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

				table.insert(grid.action_queue, {
					type = "entity_event",
					event_type = "consumed_items",
					items = research_state.cost,
					entity_id = entity.id,
				})

				research_state.cost_is_paid = true
				updates_mod.add_update(grid, {
					type = "entity_update",
					entity = entity,
				})
			else
				research_state.progress += 1
				updates_mod.add_update(grid, {
					type = "entity_update",
					entity = entity,
				})
			end

			if research_state.progress == research_state.time then
				research_state.status = "complete"
				updates_mod.add_update(grid, {
					type = "entity_update",
					entity = entity,
				})
				table.insert(grid.action_queue, {
					type = "entity_event",
					event_type = "research_completed",
					entity_id = entity.id,
					research_id = research_id,
				})
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
