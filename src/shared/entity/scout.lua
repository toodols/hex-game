local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults

registry.scout = with_defaults {
	type = "scout",
	name = "Sentry",
	description = "Illuminates r=3 tiles. For {entity.scout.abilities.scout_attack.cost}, does {entity.scout.abilities.scout_attack.damage} damage.",
	max_health = 3,
	build_time = 1,
	cost = {
		bar = 4,
	},
	abilities = {
		scout_attack = {
			range = 3,
			damage = 2,
			cost = {
				rad = 1,
			},
		},
	},
	can_capture = true,
	layer = registry_mod.layer.building,
}

return {}
