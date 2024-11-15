local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults

registry.stockpile = with_defaults {
	type = "stockpile",
	name = "Cache",
	description = "Stores up to <b>{entity.stockpile.inventory_capacity}</b> items",
	max_health = 2,
	build_time = 0,
	inventory_capacity = 5,
	cost = {
		bar = 4,
	},
	can_capture = true,
	layer = registry_mod.layer.building,
}

return {}
