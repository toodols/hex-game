local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults

registry["extractor"] = with_defaults {
	type = "extractor",
	name = "Spout",
	description = "Produces an item every {entity.extractor.cycles_to_output} turns",
	max_health = 2,
	build_time = 1,
	cycles_to_output = 2,
	cost = {
		bar = 3,
	},
	can_disable = true,
	layer = registry_mod.layer.building,
	abilities = {},
}

return {}
