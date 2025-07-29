local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local types = require(ReplicatedStorage.Shared.types)
local entity_mod = require(ServerScriptService.Server.entity)
local abilities = require(ServerScriptService.Server.abilities).abilities

type Entity = types.Entity
type World = types.World
type EntityEvent = types.EntityEvent

entity_mod.registry.solution = entity_mod.with_defaults {
	init = function(self: Entity, world: World)
		self.decayable = false
	end,

	on_event = function(self: Entity, world: World, event: EntityEvent)
		if event.entity_id == self.id and event.event_type == "destroy" and event.death_type == "killed" then
			local config = world.entity_configurations[self.type]
			abilities.solution_activate(world, self, config.abilities.activate, nil)
		end
	end,
}

return {}
