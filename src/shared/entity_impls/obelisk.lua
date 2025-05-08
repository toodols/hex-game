local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.obelisk = entity_mod.with_defaults {
	type = "obelisk",
	name = "Obelisk",
	description = "4 hp",
	max_health = 3,
	build_time = 0,
	cost = {
		bar = 2,
	},
	layer = entity_mod.LAYER.building,
}

return {}
