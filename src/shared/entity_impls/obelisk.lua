local ReplicatedStorage = game:GetService "ReplicatedStorage"
local entity_mod = require(ReplicatedStorage.Shared.entity)

entity_mod.registry.obelisk = entity_mod.with_defaults {
	type = "obelisk",
	name = "Obelisk",
	description = "Yes",
	max_health = 5,
	build_time = 0,
	cost = {
		bar = 3,
	},
	layer = entity_mod.LAYER.building,
}

return {}
