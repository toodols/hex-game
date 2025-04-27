local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.altar = entity_mod.with_defaults {
	type = "altar",
	name = "Taunt",
	description = "While visible, neighboring cells in a range of {entity.altar.range} may not be targeted.",
	max_health = 3,
	build_time = 1,
	cost = {
		pow = 2,
		bar = 2,
	},
	range = 2,
	required_research = {
		"altar",
	},
	layer = entity_mod.LAYER.modifier,
}

return {}
