local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults

registry["generator"] = with_defaults {
	type = "generator",
	name = "Catalyst",
	description = "Generates {entity.generator.output_power} power per turn",
	max_health = 3,
	build_time = 1,
	output_power = 5,
	cost = {
		bar = 3,
		rad = 1,
	},
	abilities = {},
	layer = registry_mod.layer.building,
}

return {}
