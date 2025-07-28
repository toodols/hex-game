local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.terminal = entity_mod.with_defaults {
	type = "terminal",
	name = "Terminal",
	description = "Stores buildings equal to the number of owned {entity.terminal}. Stored buildings can be deployed anywhere. On death, kill all other {entity.terminal}",
	short_description = "Transports buildings around",
	max_health = 4,
	build_time = 2,
	cost = {
		bar = 4,
	},
	can_revive = true,
	construction_condition = {
		nearby = { "vault" },
	},
	layer = entity_mod.LAYER.building,
}

return {}
