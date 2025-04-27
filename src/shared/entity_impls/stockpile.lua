local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.stockpile = entity_mod.with_defaults {
	type = "stockpile",
	name = "Cache",
	description = "Stores up to <b>{entity.stockpile.inventory_capacity}</b> items",
	max_health = 2,
	build_time = 0,
	inventory_capacity = 5,
	cost = {
		bar = 4,
	},
	can_capture = true,
	layer = entity_mod.LAYER.building,
}

return {}
