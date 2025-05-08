local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.scout = entity_mod.with_defaults {
	type = "scout",
	name = "Sentry",
	description = "Illuminates r=3 tiles. For {entity.scout.abilities.scout_attack.cost}, does {entity.scout.abilities.scout_attack.damage.amount} damage.",
	max_health = 3,
	build_time = 2,
	cost = {
		bar = 4,
		rad = 1,
	},
	abilities = {
		scout_attack = {
			range = 3,
			damage = {
				type = "flat",
				amount = 1,
				lethal = true,
				friendly_fire = false,
			},
			cost = {
				bar = 1,
			},
		},
	},
	layer = entity_mod.LAYER.building,
}

return {}
