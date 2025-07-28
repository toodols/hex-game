local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.vault = entity_mod.with_defaults {
	type = "vault",
	name = "Vault",
	description = "Stores up to <b>{entity.vault.inventory_capacity}</b> of the same item",
	max_health = 4,
	build_time = 0,
	inventory_capacity = 10,
	cost = {
		bar = 6,
		rad = 1,
	},
	required_unlockable = {
		"vault",
	},
	construction_condition = {
		nearby = { "stockpile" },
	},
	can_revive = true,
	layer = entity_mod.LAYER.building,
}

return {}
