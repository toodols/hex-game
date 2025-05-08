local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.taunt = entity_mod.with_defaults {
	type = "taunt",
	name = "Taunt",
	description = "While visible, neighboring cells in a range of {entity.taunt.range} may not be targeted. On death, deal 2 damage in a range of 1",
	max_health = 4,
	build_time = 2,
	cost = {
		pow = 1,
		bar = 4,
	},
	range = 3,
	required_research = {
		"taunt",
	},
	layer = entity_mod.LAYER.building,
}

return {}
