local ServerScriptService = game:GetService "ServerScriptService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ServerScriptService.Server.entity)
local types = require(ReplicatedStorage.Shared.types)
type Entity = types.Entity
type World = types.World
type EntityEvent = types.EntityEvent
entity_mod.registry.turret = entity_mod.with_defaults {
	autogenerates_vertex = true,
	on_event = function(self: Entity, world: World, event: EntityEvent)
		if
			event.event_type == "destroy"
			and event.death_type == "killed"
			and event.damage
			and event.damage.from == self.id
		then
			local victim = world.entities[event.entity_id]
			-- don't count vertex cause they're too easy to kill
			if victim.type == "vertex" then
				return
			end
			self.max_health += 1
		end
	end,
}

return {}
