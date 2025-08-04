local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.stockpile = entity_mod.with_defaults {
	type = "stockpile",
	name = "Cache",
	description = "Stores up to <b>{entity.stockpile.inventory_capacity}</b> items",
	entity_group = {
		["@storage"] = true,
	},
	max_health = 2,
	build_time = 0,
	inventory_capacity = 5,
	cost = {
		rad = 1,
		bar = 2,
	},
	construction_condition = {},
	can_revive = true,
	layer = entity_mod.LAYER.building,
}

return {}
