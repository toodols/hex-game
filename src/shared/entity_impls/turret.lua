local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.turret = entity_mod.with_defaults {
	type = "turret",
	name = "Dagger",
	description = "Deals {entity.turret.abilities.turret_attack.damage} damage to enemies in a {entity.turret.abilities.turret_attack.range} tile radius. "
		.. "Costs {entity.turret.abilities.turret_attack.cost} to shoot.",
	max_health = 7,
	build_time = 2,
	cost = {
		bar = 3,
		rad = 1,
		pow = 1,
	},
	required_research = { "turret" },
	layer = entity_mod.LAYER.building,
	abilities = {
		turret_attack = {
			range = 3,
			damage = 3,
			cost = {
				pow = 1,
			},
		},
	},
}

return {}
