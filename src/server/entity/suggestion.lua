local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults

type Entity = types.Entity
type World = types.World

registry.suggestion = with_defaults {
	init = function(self: Entity, world: World)
		self.decayable = false
	end,
	on_completed = function(self: Entity, world: World) end,
}

return {}
