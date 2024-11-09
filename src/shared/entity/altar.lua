local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults

registry["altar"] = with_defaults {
	type = "altar",
	name = "altar",
	description = "If there is a building on this tile, redirects incoming damage in r=2 to that building. Range may be extended by proxy.",
	max_health = 3,
	build_time = 1,
	cost = {
		pow = 1,
		bar = 3,
	},
	required_research = {
		"altar",
	},
	layer = registry_mod.layer.modifier,
}

return {}
