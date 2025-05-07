local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)
local updates_mod = require(ServerScriptService.Server.updates)

local util = require(ReplicatedStorage.Shared.util)
local systems_mod = require(ServerScriptService.Server.systems)

type World = types.World
type ActionState = server_types.ActionState
type EntityAction = types.EntityAction

function handle_advance_research_actions(world: World, action_state: ActionState)
	local advance_research_actions: { EntityAction } = util.table_extract(world.action_queue, function(action)
		return action.type == "advance_research"
	end)
	for _, action in advance_research_actions do
		local succeeded = false
		local entity = world.entities[action.entity_id]
		local system = action_state.system_by_entity_id[action.entity_id]
		if not entity or entity.is_destroyed then
			error "advance_research error"
		end

		for _, research_id in entity.researches.queue do
			local research_state = entity.researches.states[research_id]
			if not research_state.cost_is_paid then
				if not systems_mod.system_has_items(world, action_state, system, research_state.cost) then
					break
				end
				succeeded = true
				for item_type, amount in research_state.cost do
					systems_mod.system_consume_item_type(world, action_state, system, item_type, amount)
				end

				local event = {
					type = "entity_event",
					event_type = "consumed_items",
					entity_id = entity.id,
					items = research_state.cost,
				}
				table.insert(world.action_queue, event)
				world:add_update(event)

				research_state.cost_is_paid = true
				world:add_update {
					type = "entity_update",
					entity = entity,
				}
			else
				research_state.progress += 1
				world:add_update {
					type = "entity_update",
					entity = entity,
				}
				succeeded = true
			end

			if research_state.progress == research_state.time then
				research_state.status = "complete"
				world:add_update {
					type = "entity_update",
					entity = entity,
				}
				local event = {
					type = "entity_event",
					event_type = "research_completed",
					entity_id = entity.id,
					research_id = research_id,
				}
				world:add_update(event)
			else
				break
			end
		end
		local _finished = util.table_extract(entity.researches.queue, function(research_id)
			return entity.researches.states[research_id].status == "complete"
		end)
		-- push unfinished research back into queue
		if not succeeded then
			table.insert(world.action_queue, action)
		end
	end
end

return {
	handle_advance_research_actions = handle_advance_research_actions,
}
