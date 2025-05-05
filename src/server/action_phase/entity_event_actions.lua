local ServerScriptService = game:GetService "ServerScriptService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local server_types = require(ServerScriptService.Server.types)
local server_entity_mod = require(ServerScriptService.Server.entity)
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)

type World = types.World
type ActionState = server_types.ActionState
type EntityId = types.EntityId

--- Sends entity_events in action_queue to relevant entities (entities with influence + self)
--- Then adds it to updates
function handle_entity_event_actions(world: World, action_state: ActionState)
	for _, event in
		util.table_extract(world.action_queue, function(action)
			return action.type == "entity_event"
		end)
	do
		local source_entity = world.entities[event.entity_id]
		assert(source_entity ~= nil, "no source entity of event")
		local entities: { [EntityId]: true } = {}
		entities[source_entity.id] = true
		for _, coord in source_entity.coordinates do
			local cell = world:get_cell(coord)
			assert(cell, "cell not found")
			for influence in cell.influences do
				entities[influence] = true
			end
		end
		for entity_id in entities do
			local entity = world.entities[entity_id]
			local behavior = server_entity_mod.registry[entity.type]
			if behavior.on_event then
				behavior.on_event(entity, world, event, action_state)
			end
		end
	end
end

return {
	handle_entity_event_actions = handle_entity_event_actions,
}
