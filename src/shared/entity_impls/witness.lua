local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.witness = entity_mod.with_defaults {
	type = "witness",
	name = "Witness",
	description = [[Gains 1 charge each turn a neighbor {entity.extractor} produces an item or friendly building deals damage.
	When this building has {entity.witness.charges_needed} charges, reset charges and produce 1 {item.tek} ]],
	short_description = "Produces {item.tek}",
	max_health = 3,
	build_time = 1,
	charges_needed = 3,
	cost = {
		bar = 3,
		vit = 1,
	},
	can_revive = true,
	layer = entity_mod.LAYER.building,
}

return {}
