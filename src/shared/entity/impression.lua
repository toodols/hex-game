local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults

registry.impression = with_defaults {
	type = "impression",
	name = "Impression",
	description = [[Activates and destroys itself when an enemy is in r=1. Applies 'infected' effect to all r=2 enemies, taking 3 nonlethal damage. 'infected' spreads to neighboring allies each turn.]],
	max_health = 0,
	build_time = 1,
	cost = {
		pow = 2,
	},
	layer = registry_mod.layer.building,
}

return {}
