local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local types = require(ReplicatedStorage.Shared.types)
local server_types = require(ServerScriptService.Server.types)
local entity_mod = require(ServerScriptService.Server.entity)

type Entity = types.Entity
type World = types.World
type EntityEvent = types.EntityEvent
type ActionState = server_types.ActionState

entity_mod.registry.witness = entity_mod.with_defaults {
	autogenerates_vertex = true,
	init = function(self: Entity, world: World)
		self.charges = 0
	end,
	on_completed = function(self: Entity, world: World) end,
	on_event = function(self: Entity, world: World, event: EntityEvent, action_state: ActionState)
		if event.event_type ~= "dealt_damage" then
			return
		end
		local entity = world.entities[event.entity_id]
		if entity.owner ~= self.owner then
			return
		end
		assert(self.charges, "self.charges is nil")
		self.charges += 1
		if self.charges == 3 then
			self.charges = 0
			table.insert(world.action_queue, {
				entity_id = self.id,
				type = "exchange",
				output_items = { "tek" },
			})
		end
	end,
}

return {}
