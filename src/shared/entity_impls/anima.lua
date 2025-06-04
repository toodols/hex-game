local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.anima = entity_mod.with_defaults {
	type = "anima",
	name = "Anima",
	description = [[In systems exclusively supported by {entity.anima}:
- {entity.extractor} produces items every turn.
- Newly built buildings have 1 less max hp.]],
	max_health = 3,
	build_time = 2,
	cost = {
		bar = 3,
		vit = 2,
	},
	layer = entity_mod.LAYER.building,
}

return {}
