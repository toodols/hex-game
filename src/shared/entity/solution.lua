local registry_mod = require(script.Parent.registry)

registry_mod.registry["solution"] = registry_mod.with_defaults {
	type = "solution",
	name = "Solution",
	description = "When used: Heal all neighbor buildings for up to 3 health. Give 'Shield' effect to all neighbor entities.",
	max_health = 0,
	build_time = 1,
	cost = {
		vit = 3,
	},
	abilities = {
		solution_use = {
			shield_health = 2,
			shield_duration = 3,
			heal_amount = 3,
		},
	},
	layer = registry_mod.layer.building,
}

return {}
