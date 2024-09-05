local registry_mod = require(script.Parent.registry)

registry_mod.registry["barrier"] = registry_mod.with_defaults {
	type = "barrier",
	name = "Barrier",
	description = "Obstacle that prevents building",
	max_health = math.huge,
	layer = registry_mod.layer.building,
}

return {}
