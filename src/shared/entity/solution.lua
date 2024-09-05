local registry_mod = require(script.Parent.registry)

registry_mod.registry["solution"] = registry_mod.with_defaults {
	type = "solution",
	name = "Solution",
	description = "Heal all nearby units up to 5 health each when activated by death or action.",
	max_health = 0,
	build_time = 1,
	cost = {
		vit = 3,
	},
	abilities = {
		solution_use = {},
	},
	layer = registry_mod.layer.building,
}

return {}
