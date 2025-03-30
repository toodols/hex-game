local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults

registry.altar = with_defaults {
	type = "altar",
	name = "Taunt",
	description = "While visible, neighboring cells in a range of {entity.altar.range} may not be targeted.",
	max_health = 3,
	build_time = 1,
	cost = {
		pow = 2,
		bar = 2,
	},
	range = 2,
	required_research = {
		"altar",
	},
	layer = registry_mod.layer.modifier,
}

return {}
