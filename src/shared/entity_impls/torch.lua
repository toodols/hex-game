local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.torch = entity_mod.with_defaults {
	type = "torch",
	name = "Torch",
	description = "Illuminates a 120-degree cone in the direction it is facing with radius equal to its hitpoints + 1. Rotates by 60 degrees every turn.",
	short_description = "Sees very far in a limited angle",
	max_health = 4,
	cost = {
		bar = 3,
		rad = 3,
	},
	can_revive = true,
	construction_condition = {
		nearby = { "scout" },
	},
	layer = entity_mod.LAYER.building,
}

return {}
