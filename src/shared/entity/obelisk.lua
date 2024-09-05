local registry_mod = require(script.Parent.registry)

registry_mod.registry["obelisk"] = registry_mod.with_defaults {
	type = "obelisk",
	name = "Obelisk",
	description = "Worthless trophy",
	max_health = 20,
	build_time = 1,
	cost = {
		bar = 20,
	},
	layer = registry_mod.layer.building,
}

return {}
