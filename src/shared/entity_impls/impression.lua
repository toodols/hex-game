local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.impression = entity_mod.with_defaults {
	type = "impression",
	name = "Impression",
	description = [[Activates and destroys itself when an enemy is in r=1. Applies 'infected' effect to all r=2 enemies, taking 2 nonlethal damage. 'infected' spreads to neighboring allies each turn.]],
	max_health = 0,
	build_time = 1,
	cost = {
		pow = 2,
	},
	abilities = {
		activate = {},
	},
	layer = entity_mod.LAYER.building,
}

return {}
