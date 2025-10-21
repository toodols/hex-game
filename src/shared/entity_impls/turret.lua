local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.turret = entity_mod.with_defaults {
	type = "turret",
	name = "Dagger",
	description = "Attacks for {entity.turret.abilities.attack.damage.amount} damage to enemies in a {entity.turret.abilities.attack.range} tile radius. "
		.. "Costs {entity.turret.abilities.attack.cost} to shoot. On kill, gain +1 max hp.",
	short_description = "Deals {entity.turret.abilities.attack.damage.amount} damage with {entity.turret.abilities.attack.cost} but can't see very far",
	max_health = 4,
	build_time = 2,
	cost = {
		bar = 3,
		rad = 2,
		pow = 1,
	},
	entity_group = {
		["@weapon"] = true,
	},
	layer = entity_mod.LAYER.building,
	can_revive = true,
	construction_condition = {
		nearby = { "factory" },
	},
	abilities = {
		attack = {
			type = "cannon",
			range = 3,
			damage = {
				amount = 3,
			},
			cost = {
				pow = 1,
			},
		} :: any,
	},
}

return {}
