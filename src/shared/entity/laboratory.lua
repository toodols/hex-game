local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults

registry["laboratory"] = with_defaults {
	type = "laboratory",
	name = "Visionary",
	description = "Allows the research of advanced technology. Has a range of {entity.laboratory.range} tiles",
	range = 4,
	max_health = 3,
	build_time = 1,
	cost = {
		bar = 2,
		rad = 2,
	},
	abilities = {},
	layer = registry_mod.layer.building,
}

return {}
