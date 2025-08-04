local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local entity_mod = require(ServerScriptService.Server.entity)
local types = require(ReplicatedStorage.Shared.types)

type Entity = types.Entity
type World = types.World
type EntityEvent = types.EntityEvent

entity_mod.registry.terminal = entity_mod.with_defaults {
	autogenerates_vertex = true,
	on_event = function(self: Entity, world: World, event: EntityEvent)
		if event.entity_id == self.id and event.event_type == "destroy" and event.death_type == "killed" then
			-- todo: desstroy all other terminals
		end
	end,
}

return {}
