local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults

registry["impression"] = with_defaults {
	type = "impression",
	name = "Impression",
	description = [[When an enemy is within r=1 of this building, it explodes, applying Infected on all r=2 buildings.
	Buildings that are infected take 3 nonlethal damage and apply Infected on friendly r=1 buildings in the next turn.]],
	max_health = 0,
	build_time = 1,
	cost = {
		pow = 2,
	},
	layer = registry_mod.layer.building,
}

return {}
