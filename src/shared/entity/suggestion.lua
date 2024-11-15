local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults

registry.suggestion = with_defaults {
	type = "suggestion",
	name = "Suggestion",
	description = "Activate to convert enemies on this tile to this team.",
	max_health = 1,
	build_time = 1,
	cost = {
		pow = 2,
		vit = 2,
	},
	layer = registry_mod.layer.building,
}

return {}
