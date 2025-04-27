local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.extractor = entity_mod.with_defaults {
	type = "extractor",
	name = "Spout",
	description = "Produces an item every {entity.extractor.cycles_to_output} turns. <br> On death, creates a deposit of what it was last extracting where it died.",
	max_health = 2,
	build_time = 1,
	cycles_to_output = 2,
	cost = {
		bar = 3,
	},
	can_disable = true,
	layer = entity_mod.LAYER.building,
	abilities = {},
}

return {}
