local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.fountain = entity_mod.with_defaults {
	type = "fountain",
	name = "Fountain",
	description = "On complete, fill every owned inventory in r=2 with the item corresponding to this tile, then set this tile's type to basic.",
	max_health = 3,
	build_time = 3,
	cost = {
		bar = 3,
		tar = 3,
	},
	required_research = { "fountain" },
	abilities = {},
	layer = entity_mod.LAYER.building,
}

return {}
