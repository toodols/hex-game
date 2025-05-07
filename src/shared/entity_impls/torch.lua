local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.torch = entity_mod.with_defaults {
	type = "torch",
	name = "Torch",
	description = "Illuminates a 120-degree cone in the direction it is facing with radius equal to its hitpoints + 1. Rotates by 60 degrees every turn.",
	max_health = 4,
	cost = {
		bar = 4,
		rad = 3,
	},
	layer = entity_mod.LAYER.building,
}

return {}
