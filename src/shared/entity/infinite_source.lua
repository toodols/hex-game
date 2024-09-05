local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults

registry["infinite_source"] = with_defaults {
	type = "infinite_source",
	name = "Infinite Source",
	description = "Debug item that gives unlimited items",
	max_health = math.huge,
	layer = registry_mod.layer.building,
}

return {}
