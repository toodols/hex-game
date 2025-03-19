local ReplicatedStorage = game:GetService "ReplicatedStorage"
local registry_mod = require(script.Parent.registry)
local types = require(ReplicatedStorage.Shared.types)
type Entity = types.Entity
type World = types.World
registry_mod.registry.barrier = registry_mod.with_defaults {
	init = function(self: Entity, world: World)
		self.decayable = false
	end,
}

return {}
