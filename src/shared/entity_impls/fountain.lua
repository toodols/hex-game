local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.fountain = entity_mod.with_defaults {
	type = "fountain",
	name = "Fountain",
	description = "On complete, fill every owned inventory in r={entity.fountain.range} with the item corresponding to this tile, then set this tile's type to basic.",
	short_description = "Produces a large amount of items when inventory is nearby",
	max_health = 3,
	build_time = 3,
	cost = {
		bar = 3,
		tar = 3,
	},
	range = 2,
	construction_condition = { built_on = { "deposit" }, nearby = { "vault", "stockpile" } },
	layer = entity_mod.LAYER.building,
}

return {}
