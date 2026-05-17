local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.extractor = entity_mod.with_defaults {
	type = "extractor",
	name = "Spout",
	description = "{lang.desc.extractor}",
	short_description = "Produces items based on the deposit it is on",
	max_health = 2,
	build_time = 1,
	cycles_to_output = 2,
	cost = {
		bar = 4,
	},
	construction_condition = {
		built_on = { "deposit" },
	},
	can_disable = true,
	can_revive = true,
	layer = entity_mod.LAYER.building,
}

return {}
