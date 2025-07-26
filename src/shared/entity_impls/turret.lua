local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.turret = entity_mod.with_defaults {
	type = "turret",
	name = "Dagger",
	description = "Attacks for {entity.turret.abilities.attack.damage.amount} damage to enemies in a {entity.turret.abilities.attack.range} tile radius. "
		.. "Costs {entity.turret.abilities.attack.cost} to shoot. On kill, gain +1 max hp.",
	max_health = 4,
	build_time = 2,
	cost = {
		bar = 3,
		rad = 2,
		pow = 1,
	},
	required_research = {},
	layer = entity_mod.LAYER.building,
	can_revive = true,
	abilities = {
		attack = {
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
