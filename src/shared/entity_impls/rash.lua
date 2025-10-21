local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.rash = entity_mod.with_defaults {
	type = "rash",
	name = "Rash",
	description = "Attacks for {entity.rash.abilities.attack.initial_damage.amount} damage, then spawn a {entity.burn} on that tile. The next time a building on that tile is damaged, ignite that {entity.burn} and connected {entity.burn}s.",
	entity_group = {
		["@weapon"] = true,
	},
	max_health = 2,
	build_time = 0,
	inventory_capacity = 5,
	cost = {
		rad = 1,
		bar = 2,
	},
	abilities = {
		attack = {
			type = "rash",
			initial_damage = { amount = 1 },
			damage_per_turn = { amount = 1 },
			duration = 2,
		},
	},
	construction_condition = {},
	can_revive = true,
	layer = entity_mod.LAYER.building,
}

return {}
