local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.heart = entity_mod.with_defaults {
	type = "heart",
	name = "Soma",
	description = "Outputs bar per turn. Buildings not connected to a {entity.heart} will decay in 3 turns.",
	max_health = 7,
	build_time = 2,

	construction_condition = {
		nearby = { "scout" },
	},
	can_revive = true,
	cost = {
		bar = 3,
		rad = 2,
		vit = 2,
	},
	layer = entity_mod.LAYER.building,
}

return {}
