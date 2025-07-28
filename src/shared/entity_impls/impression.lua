local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.impression = entity_mod.with_defaults {
	type = "impression",
	name = "Impression",
	description = [[Applies 'infected' effect to all r=1 enemies, taking 2 nonlethal damage. 'infected' spreads to neighboring allies each turn.]],
	short_description = "Spreads damage across an enemy system",
	max_health = 0,
	build_time = 1,
	cost = {
		pow = 2,
	},
	abilities = {
		activate = {},
	},
	construction_condition = {
		nearby = { "factory" },
	},
	layer = entity_mod.LAYER.building,
}

return {}
