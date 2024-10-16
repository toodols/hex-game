local registry_mod = require(script.Parent.registry)
local registry = registry_mod.registry
local with_defaults = registry_mod.with_defaults

registry["witness"] = with_defaults {
	type = "witness",
	name = "Witness",
	description = [[Gains 1 charge each turn a neighbor {entity.extractor} produces an item or friendly building deals damage.
	When this building has {entity.scribe.charges_needed} charges, reset charges and produce 1 {items.tek} ]],
	max_health = 3,
	build_time = 1,
	charges_needed = 3,
	cost = {
		bar = 4,
	},
	can_capture = true,
	layer = registry_mod.layer.building,
}

return {}
