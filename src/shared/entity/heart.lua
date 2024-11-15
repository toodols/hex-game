local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults

registry.heart = with_defaults {
	type = "heart",
	name = "Monarch",
	description = "Generates {entity.heart.output_power} power and 1 bar per turn. Buildings not connected to a {entity.heart} will decay in 3 turns.",
	max_health = 7,
	build_time = 2,
	output_power = 2,

	required_research = {
		"heart",
	},
	cost = {
		bar = 10,
		rad = 5,
		vit = 3,
	},
	layer = registry_mod.layer.building,
}

return {}
