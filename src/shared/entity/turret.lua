local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults

registry.turret = with_defaults {
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
	layer = registry_mod.layer.building,
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
