local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.turret = entity_mod.with_defaults {
	type = "turret",
	name = "Dagger",
	description = "Attacks for {entity.turret.abilities.turret_attack.damage.amount} damage to enemies in a {entity.turret.abilities.turret_attack.range} tile radius. "
		.. "Costs {entity.turret.abilities.turret_attack.cost} to shoot.",
	max_health = 7,
	build_time = 2,
	cost = {
		bar = 3,
		rad = 1,
		pow = 1,
	},
	required_research = {},
	layer = entity_mod.LAYER.building,
	abilities = {
		turret_attack = {
			range = 3,
			damage = {
				type = "flat",
				amount = 3,
				lethal = true,
				friendly_fire = false,
			},
			cost = {
				pow = 1,
			},
		},
	},
}

return {}
