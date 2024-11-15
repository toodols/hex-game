local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults
registry.wires = with_defaults {
	type = "wires",
	name = "Vertex",
	description = "Allows transfer of power and items between building",
	max_health = 0,
	build_time = 0, -- builds immediately in the next action phase
	cost = {
		bar = 1,
	},
	abilities = {},
	layer = registry_mod.layer.wires,
}

return {}
