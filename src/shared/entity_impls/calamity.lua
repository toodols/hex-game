local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.calamity = entity_mod.with_defaults {
	type = "calamity",
	name = "Calamity",
	description = "8 range. ignores line of sight. costs nothing to fire",
	short_description = "kill them all",
	max_health = 30,
	build_time = 5,
	entity_group = {
		["@weapon"] = true,
	},
	cost = {
		pow = 20,
	},
	abilities = {
		attack = {
			type = "cannon",
			ignore_los = true,
			range = 10,
			damage = {
				amount = 1,
			},
			cost = {},
		},
		attack2 = {
			type = "cannon",
			ignore_los = true,
			range = 8,
			damage = {
				amount = 1,
			},
			cost = {},
		},
	},
	construction_condition = {
		nearby = { "turret" },
	},
	can_revive = true,
	layer = entity_mod.LAYER.building,
}

return {}
