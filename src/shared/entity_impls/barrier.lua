local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.barrier = entity_mod.with_defaults {
	type = "barrier",
	name = "Barrier",
	description = "Obstacle that prevents building",
	max_health = 5,
	layer = entity_mod.LAYER.building,
}

return {}
